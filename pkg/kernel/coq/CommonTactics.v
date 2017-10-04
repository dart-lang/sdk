(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import Common.
Require Export CpdtTactics.

Import OptionMonad.

Ltac extract E x y := set (x := E); assert (y : E = x); [auto|rewrite y in *].

Ltac force_expr E H :=
  let v1 := fresh in
  let v2 := fresh in
  extract E v1 v2; destruct v1; [idtac|simpl in H; contradict H; congruence].

Lemma bind_some : forall A B x f, @opt_bind A B (Some x) f = f x.
Proof.
  auto.
Qed.

Lemma simpl_if : forall A (e1 e2 : A), (if true then e1 else e2) = e1.
  auto.
Qed.

    (* remember (expression_type CE (NatMap.add v s TE) arg) as EXP. *)
(* destruct EXP; [rewrite bind_some in H1|simpl in H1; contradict H1; congruence]. *)
Ltac force_option :=
  match goal with
  | [ H : (opt_bind ?y (fun x => ?z)) = Some ?w |- _ ] =>
    force_expr y H; rewrite bind_some in H
  | [ H : (if ?cond then ?x else None) = Some ?w |- _ ] =>
    force_expr cond H; rewrite simpl_if in H
  | [ H : (match ?x with _ => _ end) = Some ?w |- _ ] =>
    force_expr x H
  end.

Ltac force_options := repeat force_option.

Inductive ltac_no_arg : Set :=
| Ltac_No_Arg : ltac_no_arg.

Ltac extract_head_2 term H varid eqid :=
  match type of H with
  | context[term ?X] => extract_head_2 (term X) H varid eqid
  | context[term] => remember term as varid eqn:eqid
  end.

Ltac extract_head_1 term H varid := let eqid := fresh varid "Eq" in extract_head_2 term H varid eqid.
Ltac extract_head_0 term H := let varid := fresh H in extract_head_1 term H varid.

Ltac extract_head_goal_2 term varid eqid :=
  match goal with
  | [ |- context[term ?X] ] => extract_head_goal_2 (term X) varid eqid
  | [ |- context[term] ] => remember term as varid eqn:eqid
  end.

Ltac extract_head_goal_1 term varid := let eqid := fresh varid "Eq" in extract_head_goal_2 term varid eqid.
Ltac extract_head_goal_0 term := let varid := fresh "G" in extract_head_goal_1 term varid.

Tactic Notation "extract_head" constr(term) "in" constr(H) := extract_head_0 term H.
Tactic Notation "extract_head" constr(term) "in" constr(H) "as" ident(name) := extract_head_1 term H name.
Tactic Notation "extract_head" constr(term) "in" constr(H) "as" ident(name) "," ident(name2) := extract_head_2 term H name name2.

Tactic Notation "extract_head" constr(term) := extract_head_goal_0 term.
Tactic Notation "extract_head" constr(term) "as" ident(name) := extract_head_goal_1 term name.
Tactic Notation "extract_head" constr(term) "as" ident(name) "," ident(name2) := extract_head_goal_2 term name name2.

Ltac continue_with H :=
  match type of H with
  | ?X -> ?Y =>
    let K := fresh H in
    let H' := fresh H in
    assert (X) as K; [idtac|pose proof (H K) as H']
  end.
