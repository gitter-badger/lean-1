/-
Copyright (c) 2015 Microsoft Corporation. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Leonardo de Moura

Tuples are lists of a fixed size.
It is implemented as a subtype.
-/
import data.list

universes u v w

def vector (α : Type u) (n : ℕ) := { l : list α // l^.length = n }

namespace vector
variables {α : Type u} {β : Type v} {φ : Type w}
variable {n : ℕ}

instance [decidable_eq α] : decidable_eq (vector α n) :=
begin unfold vector, apply_instance end

@[pattern] def nil : vector α 0 := ⟨[],  rfl⟩

@[pattern] def cons : α → vector α n → vector α (nat.succ n)
| a ⟨ v, h ⟩ := ⟨ a::v, congr_arg nat.succ h ⟩

@[reducible] def length (v : vector α n) : ℕ := n

notation a :: b := cons a b
notation `[` l:(foldr `, ` (h t, cons h t) nil `]`) := l

open nat

def head : vector α (nat.succ n) → α
| ⟨ [],     h ⟩ := by contradiction
| ⟨ a :: v, h ⟩ := a

theorem head_cons (a : α) : Π (v : vector α n), head (a :: v) = a
| ⟨ l, h ⟩ := rfl

def tail : vector α (succ n) → vector α n
| ⟨ [],     h ⟩ := by contradiction
| ⟨ a :: v, h ⟩ := ⟨ v, congr_arg pred h ⟩

theorem tail_cons (a : α) : Π (v : vector α n), tail (a :: v) = v
| ⟨ l, h ⟩ := rfl

def to_list : vector α n → list α | ⟨ l, h ⟩ := l

def append {n m : nat} : vector α n → vector α m → vector α (n + m)
| ⟨ l₁, h₁ ⟩ ⟨ l₂, h₂ ⟩ := ⟨ l₁ ++ l₂, by simp_using_hs ⟩

/- map -/

def map (f : α → β) : vector α n → vector β n
| ⟨ l, h ⟩  := ⟨ list.map f l, by simp_using_hs ⟩

@[simp] lemma map_nil (f : α → β) : map f nil = nil := rfl

lemma map_cons (f : α → β) (a : α) : Π (v : vector α n), map f (a::v) = f a :: map f v
| ⟨l,h⟩ := rfl

def map₂ (f : α → β → φ) : vector α n → vector β n → vector φ n
| ⟨ x, _ ⟩ ⟨ y, _ ⟩ := ⟨ list.map₂ f x y, by simp_using_hs ⟩

def repeat (a : α) (n : ℕ) : vector α n :=
⟨ list.repeat a n, list.length_repeat a n ⟩

def dropn (i : ℕ) : vector α n → vector α (n - i)
| ⟨l, p⟩ := ⟨ list.dropn i l, by simp_using_hs ⟩

def taken (i : ℕ) : vector α n → vector α (min i n)
| ⟨l, p⟩ := ⟨ list.taken i l, by simp_using_hs ⟩

section accum
  open prod
  variable {σ : Type}

  def map_accumr (f : α → σ → σ × β) : vector α n → σ → σ × vector β n
  | ⟨ x, px ⟩ c :=
    let res := list.map_accumr f x c in
    ⟨ res.1, res.2, by simp_using_hs ⟩

  def map_accumr₂ {α β σ φ : Type} (f : α → β → σ → σ × φ)
   : vector α n → vector β n → σ → σ × vector φ n
  | ⟨ x, px ⟩ ⟨ y, py ⟩ c :=
    let res := list.map_accumr₂ f x y c in
    ⟨ res.1, res.2, by simp_using_hs ⟩

end accum

protected lemma eq {n : ℕ} : ∀ (a1 a2 : vector α n), to_list a1 = to_list a2 → a1 = a2
| ⟨x, h1⟩ ⟨.x, h2⟩ rfl := rfl

@[simp] lemma to_list_nil : to_list [] = @list.nil α :=
rfl

@[simp] lemma to_list_cons (a : α) (v : vector α n) : to_list (a :: v) = a :: to_list v :=
begin cases v, reflexivity end

@[simp] lemma to_list_append {n m : nat} (v : vector α n) (w : vector α m) : to_list (append v w) = to_list v ++ to_list w :=
begin cases v, cases w, reflexivity end

@[simp] lemma to_list_dropn {n m : ℕ} (v : vector α m) : to_list (dropn n v) = list.dropn n (to_list v) :=
begin cases v, reflexivity end

@[simp] lemma to_list_taken {n m : ℕ} (v : vector α m) : to_list (taken n v) = list.taken n (to_list v) :=
begin cases v, reflexivity end

end vector
