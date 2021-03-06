/-
Copyright (c) 2017 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Leonardo de Moura, Sebastian Ullrich
-/
prelude
import init.function init.data.option.basic init.util
import init.category.combinators init.category.monad init.category.alternative init.category.monad_fail
import init.data.nat.div init.meta.exceptional init.meta.format init.meta.environment
import init.meta.pexpr init.data.to_string init.data.string.basic

universes u v

meta inductive interaction_monad.result (state : Type) (α : Type u)
| success      : α → state → interaction_monad.result
| exception {} : option (unit → format) → option pos → state → interaction_monad.result

open interaction_monad.result

section
variables {state : Type} {α : Type u}
variables [has_to_string α]

meta def interaction_monad.result_to_string : result state α → string
| (success a s)              := to_string a
| (exception (some t) ref s) := "Exception: " ++ to_string (t ())
| (exception none ref s)     := "[silent exception]"

meta instance interaction_monad.result_has_string : has_to_string (result state α) :=
⟨interaction_monad.result_to_string⟩
end

@[reducible] meta def interaction_monad (state : Type) (α : Type u) :=
state → result state α

section
parameter {state : Type}
variables {α : Type u} {β : Type v}
local notation `m` := interaction_monad state


@[inline] meta def interaction_monad_fmap (f : α → β) (t : m α) : m β :=
λ s, interaction_monad.result.cases_on (t s)
  (λ a s', success (f a) s')
  (λ e s', exception e s')

@[inline] meta def interaction_monad_bind (t₁ : m α) (t₂ : α → m β) : m β :=
λ s,  interaction_monad.result.cases_on (t₁ s)
  (λ a s', t₂ a s')
  (λ e s', exception e s')

@[inline] meta def interaction_monad_return (a : α) : m α :=
λ s, success a s

meta def interaction_monad_orelse {α : Type u} (t₁ t₂ : m α) : m α :=
λ s, interaction_monad.result.cases_on (t₁ s)
  success
  (λ e₁ ref₁ s', interaction_monad.result.cases_on (t₂ s)
     success
     exception)

@[inline] meta def interaction_monad_seq (t₁ : m α) (t₂ : m β) : m β :=
interaction_monad_bind t₁ (λ a, t₂)

meta instance interaction_monad.monad : monad m :=
{map := @interaction_monad_fmap, ret := @interaction_monad_return, bind := @interaction_monad_bind}

meta def interaction_monad.mk_exception {α : Type u} {β : Type v} [has_to_format β] (msg : β) (ref : option expr) (s : state) : result state α :=
exception (some (λ _, to_fmt msg)) none s

meta def interaction_monad.fail {α : Type u} {β : Type v} [has_to_format β] (msg : β) : m α :=
λ s, interaction_monad.mk_exception msg none s

meta def interaction_monad.silent_fail {α : Type u} : m α :=
λ s, exception none none s

meta def interaction_monad.failed {α : Type u} : m α :=
interaction_monad.fail "failed"

meta instance interaction_monad.monad_fail : monad_fail m :=
{ interaction_monad.monad with fail := λ α s, interaction_monad.fail (to_fmt s) }

-- TODO: unify `parser` and `tactic` behavior?
-- meta instance interaction_monad.alternative : alternative m :=
-- ⟨@interaction_monad_fmap, (λ α a s, success a s), (@fapp _ _), @interaction_monad.failed, @interaction_monad_orelse⟩
end
