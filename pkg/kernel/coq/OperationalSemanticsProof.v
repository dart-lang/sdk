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


(** The well-formedness hypothesis is that the environments are built via
  [lib_to_env] function from the object model module.  [program_wf] theorem
  defined there provides the rest of the well-formedness properties. *)
Variable L  : library.
Variable CE : class_env.
Variable ME : member_env.

Hypothesis program_wf_hyp: lib_to_env L = (CE, ME).


(** Auxiliary well-formedness hypothesis that should be a corollary of
  [program_wf_hyp], but requires additional facts about the object model to be
  proven. *)
Inductive ref_in_dart_type : nat -> dart_type -> Prop :=

  | RDT_Interface_Type :
    forall ref,
    ref_in_dart_type ref (DT_Interface_Type (Interface_Type ref))

  | RDT_Function_Type :
    forall ref param_type ret_type,
    (ref_in_dart_type ref param_type \/
     ref_in_dart_type ref ret_type) ->
    ref_in_dart_type ref (DT_Function_Type
      (Function_Type param_type ret_type)).

Inductive ref_in_intf : nat -> interface -> Prop :=

  | RI_Method :
    forall ref proc_desc intf,
    List.In proc_desc (procedures intf) ->
    ref_in_dart_type ref (DT_Function_Type (pr_type proc_desc)) ->
    ref_in_intf ref intf

  | RI_Getter :
    forall ref get_desc intf,
    List.In get_desc (getters intf) ->
    ref_in_dart_type ref (gt_type get_desc) ->
    ref_in_intf ref intf.

Hypothesis intf_refs_wf:
  forall class_id intf ref,
  NatMap.MapsTo class_id intf CE ->
  ref_in_intf ref intf ->
  NatMap.In ref CE.


(** Yet another hypothesis about well-formedness of getters. *)
Hypothesis program_getters_wf:
  forall class_id intf get_desc,
  NatMap.MapsTo class_id intf CE ->
  List.In get_desc (getters intf) ->
  NatMap.In (gt_ref get_desc) ME.


Lemma runtime_value_interface_procedures_wf :
  forall val intf type_opt proc_desc,
  value_of_type CE ME val intf type_opt ->
  List.In proc_desc (procedures intf) ->
  NatMap.In (pr_ref proc_desc) ME.
Proof.
  intros. destruct H.

  (* Case 1. Value of Interface Type. *)
  pose proof (program_wf L CE ME class_id intf proc_desc program_wf_hyp).
  apply H3.
  apply NatMapFacts.find_mapsto_iff. auto.
  auto.

  (* Case 2. Value of Function Type. *)
  rewrite H in H0.
  pose proof (List.in_inv H0).
  destruct H4.
    rewrite <- H4. simpl. apply MoreNatMapFacts.maps_in_mapsto.
      apply MoreNatMapFacts.maps_mapsto_in. exists (M_Procedure proc).
      auto.
    pose proof (List.in_nil H4). contradiction.

  (* Case 3. Null Value. *)
  rewrite H in H0. pose proof (List.in_nil H0). contradiction.
Qed.


Theorem step_configuration_wf :
  forall conf1, configuration_wf CE ME conf1 ->
  exists conf2, step CE ME conf1 conf2.
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
  pose proof (MoreNatMapFacts.maps_in_mapsto interface CE class_id H).
  destruct H0 as (intf & H1).
  set (type := DT_Interface_Type (Interface_Type class_id)).
  set (new_val := mk_runtime_value (Some type)).
  exists (Value_Passing_Configuration cont new_val).
  constructor 14 with (intf := intf) (type_opt := Some type); try auto.
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
        trivial. trivial.

  (* Case 6. Pass Value to MethodInvocationEK. *)
  exists (Eval_Configuration arg env (Invocation_Ek val name env cont)).
  constructor.

  (* Case 7. Pass Value to InvocationEK. *)
  pose proof (runtime_value_interface_procedures_wf
      rcvr_val rcvr_intf rcvr_type_opt proc_desc H).
  pose proof (H2 H0).
  apply MoreNatMapFacts.maps_in_mapsto in H3. destruct H3 as (el & H4).
  destruct el eqn:?. destruct p. destruct f eqn:?.
  destruct v eqn:?.
  set (env' := env_extend n0 arg_val empty_env).
  set (null_val := mk_runtime_value None).
  set (next_cont := Exit_Sk ret_cont null_val).
  exists (Exec_Configuration s env' ret_cont next_cont).
  constructor 10 with (rcvr_intf := rcvr_intf) (rcvr_type_opt := rcvr_type_opt)
      (proc_desc := proc_desc) (func_node := f) (var_id := n0) (var_type := d0)
      (var_init := o) (ret_type := d) (null_val := null_val)
      (memb_data := m) (named_data := n).
    auto.
    auto.
    rewrite Heqf0; auto.
    auto.
    trivial.
    trivial.
    constructor; simpl; congruence.

  (* Case 8. Pass Value to PropertyGetEK. *)
  destruct H eqn:?.
  destruct (gt_type get_desc) eqn:?.

    (* Case 8.1. Getting a Value of Interface Type from a Value of Interface
      Type. *)
    destruct i eqn:?.
    assert (NatMap.In n CE).
      apply intf_refs_wf with (class_id := class_id) (intf := intf) (ref := n).
      apply NatMapFacts.find_mapsto_iff. auto.
      constructor 2 with (get_desc := get_desc).
      auto.
      rewrite Heqd. constructor.
    pose proof (MoreNatMapFacts.maps_in_mapsto interface CE n H2).
    destruct H3 as (el & H4).
    set (ret_type := DT_Interface_Type (Interface_Type n)).
    set (ret_intf := el).
    set (ret_val := mk_runtime_value (Some ret_type)).
    exists (Value_Passing_Configuration cont ret_val).
    constructor 12 with (rcvr_intf := intf) (rcvr_type_opt := Some type)
        (memb_id := gt_ref get_desc)
        (ret_intf := ret_intf) (ret_type := ret_type).
      auto.
      set (get_desc_alt := mk_getter_desc name (gt_ref get_desc) ret_type).
      assert (get_desc = get_desc_alt).
        destruct get_desc. subst get_desc_alt. simpl.
        simpl in H1. rewrite H1.
        simpl in Heqd. rewrite Heqd. subst ret_type.
        congruence.
      rewrite <- H3.
      auto.
    constructor 1 with (class_id := n).
      auto.
      apply NatMapFacts.find_mapsto_iff. subst ret_intf. auto.
      simpl. congruence.

    (* Case 8.2. Getting a Value of Function Type from a Value of Interface
      Type. *)
    set (ret_type := DT_Function_Type f).
    set (ret_intf := mk_interface
      ((mk_procedure_desc "call" (gt_ref get_desc) f) :: nil)
      ((mk_getter_desc "call" (gt_ref get_desc) (DT_Function_Type f)) :: nil)).
    set (ret_val := mk_runtime_value (Some ret_type)).
    exists (Value_Passing_Configuration cont ret_val).
    constructor 12 with (rcvr_intf := intf) (rcvr_type_opt := Some type)
        (memb_id := gt_ref get_desc)
        (ret_intf := ret_intf) (ret_type := ret_type).
    constructor 1 with (class_id := class_id); auto.
    set (get_desc_alt := mk_getter_desc name (gt_ref get_desc) ret_type).
    assert (get_desc = get_desc_alt).
      destruct get_desc. subst get_desc_alt. simpl.
      simpl in H1. rewrite H1.
      simpl in Heqd. rewrite Heqd. subst ret_type.
      congruence.
    rewrite <- H2.
    auto.
    assert (NatMap.In (gt_ref get_desc) ME).
      apply program_getters_wf with (class_id := class_id) (intf := intf).
      apply NatMapFacts.find_mapsto_iff. auto. auto.
    assert (exists mbr, NatMap.MapsTo (gt_ref get_desc) mbr ME).
      apply MoreNatMapFacts.maps_in_mapsto. auto.
    destruct H3 as (mbr & H4).
    destruct mbr.
    constructor 2 with (memb_id := gt_ref get_desc) (proc := p).
    simpl. congruence.
    simpl. congruence.
    auto.
    simpl. subst ret_type. congruence.

    (* Case 8.3. Getting a Value from a Value of Function Type. *)
    exists (Value_Passing_Configuration cont val).
    set (type := DT_Function_Type ftype).
    constructor 12 with (rcvr_intf := intf) (rcvr_type_opt := Some type)
        (memb_id := memb_id)
        (ret_intf := intf) (ret_type := type).
    subst type; auto.
    pose proof H0.
    rewrite e0 in H0.
    pose proof (List.in_inv H0).
    destruct H3.
      rewrite <- H3 in H1. simpl in H1. rewrite <- H1. subst type.
        rewrite H3. auto.
      pose proof (List.in_nil H3). contradiction.
    subst type; auto.

    (* Case 8.4. Getting a Value from Null. *)
    rewrite e0 in H0.
    pose proof (List.in_nil H0).
    contradiction.

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
