(* Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import List.
Require Import Coq.FSets.FMapWeakList.
Require Import Coq.Structures.DecidableTypeEx.
Require Import Coq.Structures.Equalities.
Require Import Coq.Strings.String.


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


(** * Type Store. *)

(** Type variables are encoded with natural numbers. *)
Definition type_variable : Set := nat.

(** Locations of type variables in type Store are encoded with natural numbers.
  Locations are typed.  It allows to have less preconditions on parts of types.
  For example, a [function_type_location] may be used for methods instead of
  more general [type_location].  One downside of this decision is that it adds
  one layer of indirection, and type locations should be constructed using two
  constructors, for example

      TL_Dynamic_Location (Dynamic_Type_Location X). *)
Inductive type_location : Set :=
  | TL_Dynamic_Location : dynamic_type_location -> type_location
  | TL_Function_Type_Location : function_type_location -> type_location
  | TL_Interface_Type_Location : interface_type_location -> type_location
  | TL_Void_Location : void_type_location -> type_location
  | TL_Bottom_Location : bottom_type_location -> type_location
  | TL_Vector_Location : vector_type_location -> type_location
  | TL_Type_Parameter_Type_Location : type_parameter_type_location -> type_location
with dynamic_type_location : Set :=
  | Dynamic_Type_Location : nat -> dynamic_type_location
with function_type_location : Set :=
  | Function_Type_Location : nat -> function_type_location
with interface_type_location : Set :=
  | Interface_Type_Location : nat -> interface_type_location
with void_type_location : Set :=
  | Void_Type_Location : nat -> void_type_location
with bottom_type_location : Set :=
  | Bottom_Type_Location : nat -> bottom_type_location
with vector_type_location : Set :=
  | Vector_Type_Location : nat -> vector_type_location
with type_parameter_type_location : Set :=
  | Type_Parameter_Type_Location : nat -> type_parameter_type_location.

(** Type envronment maps type variables to type locations. *)
Definition type_environment : Type := NatMap.t type_location.

(** Type values represent semantic types of Kernel.

  TODO(dmitryas): Include detailed description of type representation.

  TODO(dmitryas): Include an explanation about shadowing of type parameters,
  and why it is not something one needs to consider in either static semantics
  or operational semantics. *)
Inductive type_value : Type :=
  | TV_Dynamic : type_value
  | TV_Function_Type :
      list type_parameter_type_location (* Type parameters. *)
      -> list type_location (* Types of the positional parameters. *)
      -> nat (* The number of required positional parameters. *)
      -> StringMap.t type_location (* Types of the named parameters. *)
      -> type_location (* Type of the return value. *)
      -> type_value
  | TV_Interface_Type :
      list type_parameter_type_location (* Type parameters. *)
      -> option type_location (* Supertype. *)
      -> list type_location (* Interfaces. *)
      -> StringMap.t type_location (* Getters. *)
      -> StringMap.t type_location (* Setters. *)
      -> StringMap.t function_type_location (* Methods. *)
      -> type_value
  | TV_Void : type_value
  | TV_Bottom : type_value
  | TV_Vector :
      nat (* Vector types include their size. *)
      -> type_value
  | TV_Type_Parameter_Type :
      type_variable (* Type parameter types include their ID. *)
      -> option type_location (* The bound of the type parameter type. *)
      -> type_value
  | TV_Interface_Type_Instantiation :
      interface_type_location (* Generic class. *)
      -> list type_location (* Type arguments. *)
      -> type_value.

(** Type Store maps type locations to type values. *)
Definition type_store : Type := NatMap.t type_value.
