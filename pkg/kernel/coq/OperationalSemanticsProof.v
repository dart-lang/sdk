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
Import ObjectModel.Subtyping.


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


Lemma method_exists_desc :
  forall type name,
  method_exists CE ME type name ->
  (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
    together the interface and the type, avoiding the construction of the
    value. *)
  exists intf desc,
    (value_of_type CE ME (mk_runtime_value type) intf type /\
      List.In desc (procedures intf) /\
      ((pr_name desc) = name)%string).
Proof.
  intros. destruct H; (

    (* Cases of Interface Type and Function Type are analogous. *)
    exists intf, desc; split; auto

  ).
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
      (fun entry : env_entry => Nat.eqb var (var_ref entry))
      env
  ) eqn:?; try contradiction.
  exists (Value_Passing_Configuration ret_cont (value e)).
  constructor.
  unfold env_get. auto.

  (* Case 2. Eval Method Invocation. *)
  exists
    (Eval_Configuration rcvr_expr env
      (Expression_Continuation
        (Method_Invocation_Ek name arg_expr env ret_cont)
        rcvr_type)).
  constructor. auto.

  (* Case 3. Eval Property Get. *)
  exists
    (Eval_Configuration rcvr_expr env
      (Expression_Continuation
        (Property_Get_Ek name ret_cont)
        rcvr_type)).
  constructor. auto.

  (* Case 4. Eval Constructor Invocation. *)
  pose proof (MoreNatMapFacts.maps_in_mapsto interface CE class_id H).
  destruct H0 as (intf & H1).
  set (type := DT_Interface_Type (Interface_Type class_id)).
  set (new_val := mk_runtime_value (Some type)).
  exists (Value_Passing_Configuration ret_cont new_val).
  constructor 14 with (intf := intf) (type_opt := Some type); try auto.
  constructor 1 with (class_id := class_id); try (simpl; auto).
  apply NatMapFacts.find_mapsto_iff. auto.

  (* Case 6. Exec Variable Declaration with Initializer. *)
  exists
    (Eval_Configuration init_expr env
      (Expression_Continuation
        (Var_Declaration_Ek var var_type env next_cont)
        init_type)).
  constructor. auto.

  (* Case 7. Exec Variable Declaration without Initializer. *)
  set (null_val := mk_runtime_value None).
  set (env' := env_extend var var_type null_val env).
  exists (Forward_Configuration next_cont env').
  constructor 15 with (null_val := null_val).
    constructor 3. simpl. congruence.
    simpl. congruence.
    trivial. trivial.

  (* Case 8. Exec Return Statement. *)
  exists (Eval_Configuration expr env ret_cont).
  constructor.

  (* Case 9. Exec Expression Statement. *)
  exists
    (Eval_Configuration expr env
      (Expression_Continuation
        (Expression_Ek env ret_cont next_cont)
        expr_type)).
  constructor. auto.

  (* Case 10. Exec Block. *)
  destruct stmts eqn:?.

    (* Case 10.1. Exec Empty Block. *)
    exists (Forward_Configuration next_cont env).
    constructor.

    (* Case 10.2. Exec Non-Empty Block. *)
    exists (Exec_Configuration s env ret_cont
      (Block_Sk l env ret_cont next_cont)).
    constructor.

  (* Case 11. Pass Value to MethodInvocationEK. *)
  exists
    (Eval_Configuration arg_expr env
      (Expression_Continuation
        (Invocation_Ek rcvr_val name env ret_cont)
        arg_type)).
  constructor 9 with (rcvr_type := rcvr_type). auto. auto.

  (* Case 12. Pass Value to InvocationEK. *)
  pose proof (method_exists_desc (runtime_type rcvr_val) name H).
  destruct H0 as (intf & desc & H1). destruct H1. destruct H1.
  pose proof
    (runtime_value_interface_procedures_wf
      (mk_runtime_value (runtime_type rcvr_val))
      intf (runtime_type rcvr_val) desc H0).
  pose proof (H3 H1).
  apply MoreNatMapFacts.maps_in_mapsto in H4.
  destruct H4 as (mbr & H5). destruct mbr eqn:?. destruct p eqn:?.
    destruct f eqn:?. destruct v eqn:?.
  set (env' := env_extend n0 d0 arg_val empty_env).
  set (null_val := mk_runtime_value None).
  set (next_cont := Exit_Sk ret_cont null_val).
  exists (Exec_Configuration s env' ret_cont next_cont).
  constructor 10 with
      (rcvr_intf      := intf)
      (rcvr_type_opt  := (runtime_type rcvr_val))
      (proc_desc      := desc)
      (func_node      := f)
      (var_id         := n0)
      (var_type       := d0)
      (var_init       := o)
      (ret_type       := d)
      (null_val       := null_val)
      (memb_data      := m)
      (named_data     := n).
    destruct rcvr_val. simpl. simpl in H0. auto.
    auto.
    rewrite Heqf0; auto.
    auto.
    trivial.
    trivial.
    constructor; simpl; congruence.

  (* Case 13. Pass Value to PropertyGetEK. *)
  set (type := runtime_type rcvr_val).
  assert (mk_runtime_value type = rcvr_val).
    destruct rcvr_val. subst type. simpl. congruence.
  destruct H0.
  destruct (gt_type desc) eqn:?.

    (* Case 13.1. Getting a Value of Interface Type from a Value of Interface
      Type. *)
    assert (runtime_type rcvr_val = type).
      rewrite <- H1. simpl. auto.
    subst type. rewrite H1 in H2. rewrite H0 in H2.
      destruct H2 eqn:?;
      try (rewrite e1 in H5; rewrite H0 in H5; discriminate H5).
    assert (type0 = type).
      rewrite e1 in H5. injection H5. intros. auto.
    destruct i eqn:?.
    assert (NatMap.In n CE).
      apply intf_refs_wf with (class_id := class_id0) (intf := intf) (ref := n).
      apply NatMapFacts.find_mapsto_iff. auto.
      constructor 2 with (get_desc := desc).
      auto.
      rewrite Heqd. constructor.
    pose proof (MoreNatMapFacts.maps_in_mapsto interface CE n H7).
    destruct H8 as (el & H9).
    set (ret_type := DT_Interface_Type (Interface_Type n)).
    set (ret_intf := el).
    set (ret_val := mk_runtime_value (Some ret_type)).
    exists (Value_Passing_Configuration ret_cont ret_val).
    constructor 12 with
        (rcvr_intf      := intf)
        (rcvr_type_opt  := Some type)
        (memb_id        := gt_ref desc)
        (ret_intf       := ret_intf)
        (ret_type       := ret_type).
      auto.
      set (get_desc_alt := mk_getter_desc name (gt_ref desc) ret_type).
      assert (desc = get_desc_alt).
        destruct desc. subst get_desc_alt. simpl.
        simpl in H4. rewrite H4.
        simpl in Heqd. rewrite Heqd. subst ret_type.
        congruence.
      rewrite <- H8.
      auto.
    constructor 1 with (class_id := n).
      auto.
      apply NatMapFacts.find_mapsto_iff. subst ret_intf. auto.
      simpl. congruence.

    (* Case 13.2. Getting a Value of Function Type from a Value of Interface
      Type. *)
    set (ret_type := DT_Function_Type f).
    set (ret_intf := mk_interface
      ((mk_procedure_desc "call" (gt_ref desc) f) :: nil)
      ((mk_getter_desc "call" (gt_ref desc) (DT_Function_Type f)) :: nil)).
    set (ret_val := mk_runtime_value (Some ret_type)).

    assert (runtime_type rcvr_val = Some type0).
      subst type. rewrite <- H1. simpl. auto.
    subst type. rewrite H1 in H2. rewrite H0 in H2.
      destruct H2 eqn:?;
      try (rewrite e1 in H5; rewrite H0 in H5; discriminate H5).
    assert (type0 = type).
      rewrite e1 in H5. injection H5. intros. auto.
    assert (class_id0 = class_id).
      rewrite e in H6. rewrite H0 in H6.
      injection H6. intros. auto.

    exists (Value_Passing_Configuration ret_cont ret_val).
    constructor 12 with
        (rcvr_intf := intf)
        (rcvr_type_opt := Some type)
        (memb_id := gt_ref desc)
        (ret_intf := ret_intf)
        (ret_type := ret_type).
    constructor 1 with (class_id := class_id0); auto.

    set (get_desc_alt := mk_getter_desc name (gt_ref desc) ret_type).
    assert (desc = get_desc_alt).
      destruct desc. subst get_desc_alt. simpl.
      simpl in H4. rewrite H4.
      simpl in Heqd. rewrite Heqd. subst ret_type.
      congruence.
    rewrite <- H8. auto.

    clear Heqv.
      destruct H2;
      try (rewrite e1 in H5; rewrite H0 in H5; discriminate H5).
    apply NatMapFacts.find_mapsto_iff in e0.
    pose proof (program_getters_wf class_id0 intf desc e0).
    pose proof (H10 H3).
    apply MoreNatMapFacts.maps_in_mapsto in H11.
    destruct H11 as (mbr & H12).

    destruct mbr.
    constructor 2 with (memb_id := gt_ref desc) (proc := p).
    simpl. congruence.
    simpl. congruence.
    auto.
    simpl. subst ret_type. congruence.

    (* Case 13.3. Getting a Value from a Value of Function Type. *)
    subst type. rewrite H1 in H2. rewrite H in H2.
      destruct H2 eqn:?; try (
        clear Heqv;
        rewrite <- H1 in e1;
        simpl in e1;
        rewrite H0 in e1;
        rewrite e in e1;
        discriminate e1
    ).

    assert (ftype0 = ftype).
      rewrite H0 in H. injection H. intros. auto.

    exists (Value_Passing_Configuration ret_cont val).
    constructor 12 with
        (rcvr_intf := intf)
        (rcvr_type_opt := Some type0)
        (memb_id := gt_ref desc)
        (ret_intf := intf)
        (ret_type := type0).
    rewrite H. auto.

    pose proof H2.
    rewrite e0 in H3.
    pose proof (List.in_inv H3).
    destruct H7.
      clear Heqv. rewrite H7 in H3. rewrite H7 in e0. rewrite <- H7. simpl.
        rewrite <- e0 in  H3. rewrite H5 in H7. rewrite <- H0 in H7.
        rewrite H7. auto.
      pose proof (List.in_nil H7). contradiction.
    rewrite H0; rewrite <- H5; auto.

    (* Case 13.4. Getting a Value from Null. *)
    rewrite e0 in H3.
    pose proof (List.in_nil H3).
    contradiction.

  (* Case 9. Forward. *)
  destruct next_cont.

    (* Case 9.1. Forward to Exit. *)
    exists (Value_Passing_Configuration e r).
    constructor.

    (* Case 9.2. Forward to the Next Statement in Block. *)
    destruct l.

      (* Case 9.2.1. Block is Empty. *)
      exists (Forward_Configuration next_cont e).
      constructor.

      (* Case 9.2.2. Block is Non-Empty. *)
      exists (Exec_Configuration s env e0 (Block_Sk l e e0 next_cont)).
      constructor.

  (* Case 10. Pass Value to ExpressionEk. *)
  exists (Forward_Configuration next_cont env).
  constructor.

  (* Case 11. Pass Value to VarDeclarationEk. *)
  set (env' := env_extend var var_type val env).
  exists (Forward_Configuration next_cont env').
  constructor.
  auto.

  (* Case 12. Pass Value to MethodInvocationEK: No Such Method. *)
  exists
    (Value_Passing_Configuration
      (Expression_Continuation Halt_Ek rcvr_type)
      (mk_runtime_value None)).
  assert (rcvr_val = mk_runtime_value None).
    destruct rcvr_val. simpl in H. rewrite H. reflexivity.
  rewrite H0.
  constructor 19.

  (* Case 13. Pass Value to PropertyGetEK: No Such Getter. *)
  exists
    (Value_Passing_Configuration
      (Expression_Continuation Halt_Ek rcvr_type)
      (mk_runtime_value None)).
  assert (rcvr_val = mk_runtime_value None).
    destruct rcvr_val. simpl in H. rewrite H. reflexivity.
  rewrite H0.
  constructor 20.
Qed.


Lemma configuration_valid_wf :
  forall conf, configuration_valid CE ME conf -> configuration_wf CE ME conf.
Proof.
  admit.
Admitted.


Lemma configuration_valid_step :
  forall conf1 conf2,
  configuration_valid CE ME conf1 ->
  step CE ME conf1 conf2 ->
  configuration_valid CE ME conf2 \/ configuration_final conf2.
Proof.
  admit.
Admitted.


Theorem progress:
  forall conf1,
  configuration_valid CE ME conf1 ->
  exists conf2, step CE ME conf1 conf2 /\
    (configuration_valid CE ME conf2 \/ configuration_final conf2).
Proof.
  intros.
  admit.
Admitted.


Lemma preservation_eval:
  forall conf1 conf2 exp val env cont val_type exp_type,
  configuration_valid CE ME conf1 ->
  conf1 = Eval_Configuration exp env cont ->
  conf2 = Value_Passing_Configuration cont val ->
  steps CE ME conf1 conf2 ->
  expression_type CE (env_to_type_env env) exp = Some exp_type ->
  (runtime_type val) = Some val_type ->
  subtype (val_type, exp_type) = true.
Proof.
  admit.
Admitted.


End OperationalSemanticsSpec.
