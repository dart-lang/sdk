Require Export List.
Require Export Coq.FSets.FMapWeakList.
Require Export Coq.Structures.DecidableTypeEx.
Require Export Coq.Structures.Equalities.
Require Export Coq.Strings.String.

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

  Notation "[ x ]" := (comp_return x) (at level 0, x at level 99).
  Notation "[[ x ]]" := (comp_unsome x) (at level 0, x at level 99).
  Notation "x <- m1 ; m2" := (comp_bind m1 (fun x => m2)) (at level 70, right associativity).

  Fixpoint comp_fix' (A : Type) (B : Type) (f : (A -> comp B) -> (A -> comp B)) (a : A) (n : nat) {struct n} : option B :=
    match n with
    | O => None
    | (S n) => let rec := fun (a : A) => comp_unsome (comp_fix' _ _ f a n) in f rec a n
    end.

  Definition Fix {A : Type} {B : Type} (f : (A -> comp B) -> (A -> comp B)) : A -> comp B :=
    fun a => fun n => comp_fix' _ _ f a n.

End ComputationMonad.

Module ListExtensions.
  Import ComputationMonad.

  Fixpoint mmap {A B} (f : A -> comp B) (l : list A) : comp (list B) :=
    match l with
    | nil => [nil]
    | (x::xs) => (x' <- f x; xs' <- mmap f xs; [x' :: xs'])
    end.

End ListExtensions.
