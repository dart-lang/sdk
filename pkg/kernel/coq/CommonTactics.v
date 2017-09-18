(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import Common.
Require Export CpdtTactics.

Import OptionMonad.

Ltac extract E x y := set (x := E); assert (y : E = x); [auto|rewrite y in *].

Ltac force_expr E :=
  let v1 := fresh in
  let v2 := fresh in
  extract E v1 v2; destruct v1; [idtac|crush].

Lemma bind_some : forall A B x f, @opt_bind A B (Some x) f = f x.
Proof.
  crush.
Qed.

Ltac force_options :=
  repeat match goal with
         | [ H : (opt_bind ?y (fun x => ?z)) = Some ?w |- _ ] =>
           force_expr y; rewrite bind_some in H
         | [ H : (if ?cond then ?x else None) = Some ?w |- _ ] =>
           force_expr cond
         | [ H : (match ?x with _ => _ end) = Some ?w |- _ ] =>
           force_expr x
         end.

Inductive ltac_no_arg : Set :=
| Ltac_No_Arg : ltac_no_arg.
