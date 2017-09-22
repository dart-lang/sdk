(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Export List.
Require Export Coq.FSets.FMapWeakList.
Require Export Coq.FSets.FMapFacts.
Require Export Coq.Structures.DecidableTypeEx.
Require Export Coq.Structures.Equalities.
Require Export Coq.Strings.String.
Require Import CpdtTactics.

(** * Auxiliary definitions. *)

(** Strings are used as keys in maps of getters, setters, and methods of
  interface types.  For maps we use the list-based unordered representation,
  because it only requires decidability on the domain of keys.  [String_as_MDT]
  and [String_as_UDT] below are auxiliary modules to define [StringMap]. *)

Module String_as_MDT.
  Definition t := string.
  Definition eq_dec := string_dec.
End String_as_MDT.

Module String_as_UDT := Equalities.Make_UDT(String_as_MDT).

(** [NatMap] is used to map type variables to type locations and to map type
  locations to type values. *)
Module NatMap := FMapWeakList.Make(Nat_as_DT).
Module NatMapFacts := FMapFacts.Facts NatMap.

(** [StringMap] is used to map identifiers to getters, setters, and methods. *)
Module StringMap := FMapWeakList.Make(String_as_UDT).

(* A "comp A" denotes a partial function that may not terminate on some inputs
   or terminate without an answer on others. *)
Module ComputationMonad.

  Definition comp (A : Type) := nat -> option A.

  Definition comp_return {A : Type} (a : A) : comp A := fun _ => Some a.
  Definition abort {A : Type} : comp A := fun _ => None.

  Definition comp_bind {A : Type} {B : Type} (x : comp A) (y : A -> comp B) : comp B :=
    fun n => match x n with None => None | Some a => y a n end.
  Definition comp_unsome {A : Type} (v : option A) : comp A := fun _ => v.

  Notation "[ x ]" := (comp_return x) (at level 0, x at level 200).
  Notation "[[ x ]]" := (comp_unsome x) (at level 0, x at level 99).
  Notation "x <- m1 ; m2" := (comp_bind m1 (fun x => m2)) (at level 70, right associativity).

  Fixpoint comp_fix' (A : Type) (B : Type) (f : (A -> comp B) -> (A -> comp B)) (a : A) (n : nat) {struct n} : option B :=
    match n with
    | O => None
    | (S n) => let rec := fun (a : A) => comp_unsome (comp_fix' _ _ f a n) in f rec a n
    end.

  Definition Fix {A : Type} {B : Type} (f : (A -> comp B) -> (A -> comp B)) : A -> comp B :=
    fun a => fun n => comp_fix' _ _ f a n.

  Module Continuity.

    Definition continuous {A: Type} (f: comp A) : Prop :=
      forall n k v, n <= k -> f n = Some v -> f k = Some v.

    Lemma return_cont {A: Type} : forall a : A, continuous (comp_return a).
      intros.
      unfold comp_return.
      unfold continuous.
      auto.
    Qed.

    Lemma abort_cont {A : Type} : continuous (@abort A).
      unfold abort.
      unfold continuous.
      auto.
    Qed.

  End Continuity.

End ComputationMonad.

Module OptionMonad.

  Notation "[ x ]" := (Some x) (at level 0, x at level 200).

  Definition opt_bind {A B} (x : option A) (f : A -> option B) : option B :=
    match x with
    | None => None
    | Some v => f v
    end.

  Notation "x <- m1 ; m2" := (opt_bind m1 (fun x => m2)) (at level 70, right associativity).

End OptionMonad.

Module ListExtensions.
  Import ComputationMonad.

  Fixpoint mmap {A B} (f : A -> comp B) (l : list A) : comp (list B) :=
    match l with
    | nil => [nil]
    | (x::xs) => (x' <- f x; xs' <- mmap f xs; [x' :: xs'])
    end.

  Lemma foldr_mono {A} {B} :
    forall (P : A -> A -> Prop) (l : list B) (a0 : A) (f : B -> A -> A),
      (forall x, P x x) ->
      (forall x y z, P x y -> P y z -> P x z) ->
      (forall a b, P a (f b a)) ->
      P a0 (List.fold_right f a0 l).
  Proof.
    induction l; crush.
    pose proof (IHl a0 f H H0 H1).
    pose proof (H1 (fold_right f a0 l) a).
    pose proof (H0 _ _ _ H2 H3).
    crush.
  Qed.

  Lemma foldr_preserve {A} {B} :
    forall (P : A -> Prop) (l : list B) (a0 : A) (f : B -> A -> A),
      (forall a b, P a -> P (f b a)) ->
      P a0 -> P (List.fold_right f a0 l).
  Proof.
    induction l; crush.
  Qed.

End ListExtensions.
