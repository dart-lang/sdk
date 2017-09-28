(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)


Require Import Coq.Lists.SetoidList.

Require Import Common.
Require Import Syntax.
Require Import ObjectModel.
Require Import OperationalSemantics.

Import Common.NatMapFacts.
Import Common.MoreNatMapFacts.

Section OperationalSemanticsSpec.


Variable CE : class_env.

Variable FE : func_env.


(** Placeholder for the well-formedness properties of the program. *)

(** Predicate for [class_env] [CE] being well-formed w.r.t. [func_env] [FE]. *)
Hypothesis program_wf:
  forall class_id intf proc_desc,
  NatMap.MapsTo class_id intf CE ->
  List.In proc_desc (procedures intf) ->
  NatMap.In (pr_ref proc_desc) FE.


Lemma runtime_value_interface_wf :
  forall val intf type proc_desc,
  value_of_type CE FE val intf type ->
  List.In proc_desc (procedures intf) ->
  NatMap.In (pr_ref proc_desc) FE.
Proof.
  intros. destruct H.

  (* Case 1. Value of Interface Type. *)
  apply program_wf with (class_id := class_id) (intf := intf).
  apply NatMapFacts.find_mapsto_iff. auto.
  auto.

  (* Case 2. Value of Function Type. *)
  rewrite H1 in H0.
  pose proof (List.in_inv H0).
  destruct H6.
    rewrite <- H6. auto.
    pose proof (List.in_nil H6). contradiction.

  (* Case 3. Null Value. *)
  rewrite H in H0. pose proof (List.in_nil H0). contradiction.
Qed.


Theorem step_configuration_wf :
  forall conf1, configuration_wf CE FE conf1 ->
  exists conf2, step CE FE conf1 conf2.
Proof.
  intros.

  (* Construct the second configuration from the preconditions of
    well-formedness of the first configuration. *)
  destruct H.

  (* Case 1. Eval Variable Get. *)
  unfold env_in in H.
  destruct (
    List.find
      (fun entry : environment_entry => Nat.eqb var_id (variable_id entry))
      env
  ) eqn:?; try contradiction.
  exists (Value_Passing_Configuration cont (value e)).
  constructor.
  unfold env_get. auto.

  (* Case 2. Eval Method Invocation. *)
  exists (Eval_Configuration rcvr env
    (Method_Invocation_Ek name arg env cont)).
  constructor.

  (* Case 3. Eval Property Get. *)
  exists (Eval_Configuration rcvr env (Property_Get_Ek name cont)).
  constructor.

  (* Case 4. Eval Constructor Invocation. *)
  pose proof (maps_in_mapsto interface CE class_id H).
  destruct H0 as (intf & H1).
  set (type := DT_Interface_Type (Interface_Type class_id)).
  set (new_val := mk_runtime_value (Some type)).
  exists (Value_Passing_Configuration cont new_val).
  constructor 14 with (intf := intf) (type := Some type); try auto.
  constructor 1 with (class_id := class_id); try (simpl; auto).
  apply NatMapFacts.find_mapsto_iff. auto.

  (* Case 5. Exec. *)
  destruct stmt.

    (* Case 5.1. Exec Expression Statement. *)
    destruct e.
    exists (Eval_Configuration e env (Expression_Ek env ret_cont next_cont)).
    constructor.

    (* Case 5.2. Exec Block. *)
    destruct b. destruct l.

      (* Case 5.2.1. Exec Empty Block. *)
      exists (Forward_Configuration next_cont env).
      constructor.

      (* Case 5.2.2. Exec Non-Empty Block. *)
      exists (Exec_Configuration s env ret_cont
        (Block_Sk l env ret_cont next_cont)).
      constructor.

    (* Case 5.3. Exec Return Statement. *)
    destruct r.
    exists (Eval_Configuration e env ret_cont).
    constructor.

    (* Case 5.4. Exec Variable Declaration. *)
    destruct v. destruct o.

      (* Case 5.4.1. Exec Variable Declaration with Initializer. *)
      exists (Eval_Configuration e env (Var_Declaration_Ek n env next_cont)).
      constructor.

      (* Case 5.4.2. Exec Variable Declaration without Initializer. *)
      set (null_val := mk_runtime_value None).
      set (env' := env_extend n null_val env).
      exists (Forward_Configuration next_cont env').
      constructor 15 with (null_val := null_val).
        constructor 3. simpl. congruence.
        simpl. congruence.
        trivial.

  (* Case 6. Pass Value to MethodInvocationEK. *)
  exists (Eval_Configuration arg env (Invocation_Ek val name env cont)).
  constructor.

  (* Case 7. Pass Value to InvocationEK. *)
  pose proof (runtime_value_interface_wf rcvr_val intf type proc_desc H).
  pose proof (H2 H0).
  apply maps_in_mapsto in H3. destruct H3 as (el & H4).
  destruct el eqn:?. destruct v eqn:?.
  set (env' := env_extend n arg_val empty_env).
  set (null_val := mk_runtime_value None).
  set (next_cont := Exit_Sk ret_cont null_val).
  exists (Exec_Configuration s env' ret_cont next_cont).
  constructor 10 with (intf := intf) (type := type) (proc_desc := proc_desc)
      (func_node := el) (var_id := n) (var_type := d0) (var_init := o)
      (ret_type := d) (null_val := null_val).
    auto.
    auto.
    rewrite Heqf; auto.
    rewrite Heqf; auto.
    trivial.
    trivial.
    constructor. simpl. congruence.
    simpl. congruence.

  (* Case 8. Pass Value to PropertyGetEK. *)
  set (func_type := pr_type proc_desc).
  set (func_proc_desc :=
    mk_procedure_desc "call" (pr_ref proc_desc) func_type).
  set (func_val := mk_runtime_value (Some (DT_Function_Type func_type))).
  exists (Value_Passing_Configuration cont func_val).
  constructor 12 with (rcvr_intf := intf) (rcvr_type := type)
    (rcvr_proc_desc := proc_desc) (func_proc_desc := func_proc_desc); try auto.
  destruct func_type eqn:?.
  constructor 2 with
    (par_type := d)
    (ret_type := d0)
    (proc := func_proc_desc); (try (simpl; congruence)).
  simpl. apply runtime_value_interface_wf with
    (val := rcvr_val) (intf := intf) (type := type); auto.

  (* Case 9. Forward. *)
  destruct cont.

    (* Case 9.1. Forward to Exit. *)
    exists (Value_Passing_Configuration e r).
    constructor.

    (* Case 9.2. Forward to the Next Statement in Block. *)
    destruct l.

      (* Case 9.2.1. Block is Empty. *)
      exists (Forward_Configuration cont e).
      constructor.

      (* Case 9.2.2. Block is Non-Empty. *)
      exists (Exec_Configuration s env e0 (Block_Sk l e e0 cont)).
      constructor.
Qed.


End OperationalSemanticsSpec.
