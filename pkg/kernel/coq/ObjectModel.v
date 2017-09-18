(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import Common.
Require Import CommonTactics.
Require Import Syntax.
Require Import Coq.Strings.String.

Import Common.OptionMonad.

Module N := Coq.Arith.PeanoNat.Nat.

Fixpoint type_equiv (s : dart_type) (t : dart_type) : bool :=
  match (s, t) with
  | (DT_Interface_Type (Interface_Type s_class),
     DT_Interface_Type (Interface_Type t_class)) =>
    N.eqb s_class t_class
  | (DT_Function_Type (Function_Type s_param s_ret),
     DT_Function_Type (Function_Type t_param t_ret)) =>
    type_equiv s_param t_param && type_equiv s_ret t_ret
  | _ => false
  end.

Notation "s ≡ t" := (type_equiv s t = true) (at level 70, no associativity).

Section Type_Equivalence_Properties.

  Ltac destruct_types :=
    repeat match goal with
           | [H : interface_type |- _] => destruct H
           | [H : function_type |- _] => destruct H
           end.

  Hint Rewrite N.eqb_eq.
  Hint Unfold type_equiv.

  Lemma type_equiv_refl : forall s : dart_type, s ≡ s.
    apply
      (dart_type_ind_mutual
         (fun s => s ≡ s)
         (fun i => DT_Interface_Type i ≡ DT_Interface_Type i)
         (fun f => DT_Function_Type f ≡ DT_Function_Type f)); crush.
  Qed.

  Definition trans_at t := forall s r, s ≡ t /\ t ≡ r -> s ≡ r.

  Hint Unfold trans_at.

  Lemma interface_type_trans : forall (n : nat), trans_at (DT_Interface_Type (Interface_Type n)).
  Proof.
    intros; unfold trans_at; intros; destruct s; destruct r; destruct_types; crush.
  Qed.

  Lemma function_type_trans :
    forall d, trans_at d -> forall d', trans_at d' ->
    trans_at (DT_Function_Type (Function_Type d d')).
  Proof.
    intros; unfold trans_at in *; intros; destruct s; destruct r.
    crush.
    crush.
    crush.
    destruct_types.
    intuition.
    repeat match goal with
      | [ H : DT_Function_Type (Function_Type _ _) ≡ DT_Function_Type (Function_Type _ _) |- _ ] =>
        unfold type_equiv in H;
        apply Bool.andb_true_iff in H;
        fold type_equiv in H;
        destruct H
      end.
    assert (d3 ≡ d1 /\ d2 ≡ d0); crush.
  Qed.

  Lemma type_equiv_trans : forall t s r, s ≡ t /\ t ≡ r -> s ≡ r.
    apply (dart_type_induction trans_at).
    crush.
    crush.
    apply interface_type_trans.
    apply function_type_trans.
  Qed.

  Lemma type_equiv_sym : forall s t, s ≡ t -> t ≡ s.
    apply (dart_type_induction (fun x => forall y, x ≡ y -> y ≡ x)).
    crush.
    crush.
    intros.
    destruct y.
    destruct i.
    crush.
    destruct f.
    crush.
    destruct y.
    destruct i.
    crush.
    destruct f.
    crush.
    apply Bool.andb_true_iff in H1; destruct H1.
    pose proof (H0 d2 H2).
    crush.
  Qed.

End Type_Equivalence_Properties.

(* Semantic Types *)
Record procedure_desc : Type := mk_procedure_desc {
  pr_name : string;
  pr_ref : nat;
  pr_type : function_type;
}.

Definition procedure_dissect (p : procedure) : procedure_desc :=
  let (memb, _, fn) := p in
  let (nn, name) := memb in
  let (name_str) := name in
  let (ref) := nn in
  let (id) := ref in
  let (param, ret_type, _) := fn in
  let (_, param_type, _) := param in
  mk_procedure_desc name_str id (Function_Type param_type ret_type).

Record interface : Type := mk_interface {
  procedures : list procedure_desc;
}.

(** Type envronment maps class IDs to their interface type. *)
Definition class_env : Type := NatMap.t interface.
Definition type_env : Type := NatMap.t dart_type.

Fixpoint expression_type (CE : class_env) (TE : type_env) (e : expression) :
    option dart_type :=
  match e with
  | E_Variable_Get (Variable_Get v) => NatMap.find v TE
  | E_Property_Get (Property_Get rec prop) =>
    rec_type <- expression_type CE TE rec;
    let (prop_name) := prop in
    match rec_type with
    | DT_Function_Type _ =>
      if string_dec prop_name "call" then [rec_type] else None
    | DT_Interface_Type (Interface_Type class) =>
      interface <- NatMap.find class CE;
      proc_desc <- List.find (fun P =>
        if string_dec (pr_name P) prop_name then true else false)
        (procedures interface);
      [DT_Function_Type (pr_type proc_desc)]
    end
  | E_Invocation_Expression (IE_Constructor_Invocation (Constructor_Invocation class)) =>
    _ <- NatMap.find class CE;
    [DT_Interface_Type (Interface_Type class)]
  | E_Invocation_Expression (IE_Method_Invocation (Method_Invocation rec method args _)) =>
    rec_type <- expression_type CE TE rec;
    let (arg_exp) := args in
    arg_type <- expression_type CE TE arg_exp;
    let (method_name) := method in
    fun_type <-
      match rec_type with
      | DT_Function_Type fn_type =>
        if string_dec "call" method_name then [fn_type] else None
      | DT_Interface_Type (Interface_Type class) =>
        interface <- NatMap.find class CE;
        proc_desc <- List.find (fun P =>
          if string_dec (pr_name P) method_name then true else false)
          (procedures interface);
        [pr_type proc_desc]
      end;
    let (param_type, ret_type) := fun_type in
    if type_equiv param_type arg_type then [ret_type] else None
  end
.

Fixpoint statement_type (CE : class_env) (TE : type_env) (s : statement) :
    option (type_env * option dart_type) :=
  match s with
  | S_Expression_Statement (Expression_Statement e) =>
    _ <- expression_type CE TE e; [(TE, None)]
  | S_Return_Statement (Return_Statement re) =>
    rt <- expression_type CE TE re; [(TE, Some rt)]
  | S_Variable_Declaration (Variable_Declaration _ _ None) => None
  | S_Variable_Declaration (Variable_Declaration var type (Some init)) =>
    init_type <- expression_type CE TE init;
    if type_equiv init_type type then
      [(NatMap.add var type TE, None)]
    else
      None
  | S_Block (Block stmts) =>
    let process_statements := fix process_statements TE stmts :=
      match stmts with
      | nil => [(TE, None)]
      | (s::ss) =>
        st <- statement_type CE TE s;
        let (TE', s_rt) := st in
        sst <- process_statements TE' ss;
        let (TE'', ss_rt) := sst in
        match (s_rt, ss_rt) with
        | (None, ss_rt) => [(TE'', ss_rt)]
        | (Some rt, None) => [(TE'', Some rt)]
        | (Some rt, Some rt') =>
          if type_equiv rt rt' then [(TE'', Some rt)] else None
        end
      end in
    process_statements TE stmts
  end
.

Fixpoint procedure_type (CE : class_env) (p : procedure) : bool :=
  let (_, _, fn) := p in
  let (param, ret_type, body) := fn in
  let (param_var, param_type, _) := param in
  let TE := NatMap.add param_var param_type (NatMap.empty _) in
  match statement_type CE TE body with
  | Some (_, Some t) => type_equiv t ret_type
  | _ => false
  end
.

Fixpoint class_type (CE : class_env) (c : class) : option class_env :=
  let (nn_data, _, procedures) := c in
  let (ref) := nn_data in
  let (class_id) := ref in
  let class_interface := mk_interface (map procedure_dissect procedures) in
  let CE' := NatMap.add class_id class_interface CE in
  if forallb (procedure_type CE') procedures then Some CE' else None
.

Section Typing_Equivalence_Homomorphism.

  Definition equiv_at (e : expression) :=
    forall CE TE v s t et,
                 expression_type CE (NatMap.add v s TE) e = [et] /\ s ≡ t ->
      exists es, expression_type CE (NatMap.add v t TE) e = [es] /\ et ≡ es.

  Hint Resolve NatMap.add_1.
  Hint Resolve NatMap.add_2.
  Hint Resolve NatMap.find_1.
  Hint Resolve type_equiv_refl.
  Lemma type_equiv_at_variable_get :
    forall v, equiv_at (E_Variable_Get (Variable_Get v)).
  Proof.
    unfold equiv_at.
    intros.
    destruct (N.eq_dec v v0).
    rewrite e in *.
    exists t.
    assert (et = s).
    unfold expression_type in H.
    assert (NatMap.find v0 (NatMap.add v0 s TE) = Some s) by crush.
    rewrite H0 in H.
    crush.
    intuition.
    unfold expression_type.
    crush.
    crush.
    destruct H.
    unfold expression_type in H.
    apply NatMap.find_2 in H.
    exists et.
    unfold expression_type in *.
    pose proof (@NatMap.add_3 dart_type TE v0 v et s (not_eq_sym n) H).
    crush.
  Qed.
  Hint Immediate type_equiv_at_variable_get.

  Hint Rewrite N.eqb_eq.
  Lemma type_equiv_at_property_get :
    forall rec prop, equiv_at rec -> equiv_at (E_Property_Get (Property_Get rec prop)).
  Proof.
    unfold equiv_at.
    intros.
    intuition.
    destruct prop.
    unfold expression_type in H1.
    fold expression_type in H1.
    extract (expression_type CE (NatMap.add v s TE) rec) Orig H0.

    (* Go by cases on the original type of the receiver. *)
    destruct Orig; [idtac|crush].
    simpl in H1.
    destruct d.

    (* Case 1: receiver has interface type. *)
    destruct i.
    extract (NatMap.find n CE) iface H3.
    destruct iface; [idtac|crush].
    simpl in H1.
    pose proof (H CE TE v s t (DT_Interface_Type (Interface_Type n)) (conj H0 H2)).
    destruct H4 as [new_rec_type].
    destruct H4.
    unfold type_equiv in H5.
    destruct new_rec_type; [idtac|crush].
    exists et.
    destruct i0.
    crush.

    (* Case 2: receiver has function type. *)
    destruct f.
    force_options.
    pose proof (H CE TE v s t (DT_Function_Type (Function_Type d d0)) (conj H0 H2)).
    destruct H3 as [new_rec_type].
    destruct H3.
    exists new_rec_type.
    intuition; [idtac|crush].
    unfold expression_type.
    fold expression_type.
    rewrite H3.
    simpl.
    destruct new_rec_type; crush.
  Qed.
  Hint Immediate type_equiv_at_property_get.

  Lemma type_equiv_at_ctor_invo :
    forall c, equiv_at (E_Invocation_Expression (IE_Constructor_Invocation c)).
  Proof.
    unfold equiv_at; intros; exists et; crush.
  Qed.
  Hint Immediate type_equiv_at_ctor_invo.

  Lemma type_equiv_at_meth_invo :
    forall rec arg name n, equiv_at rec -> equiv_at arg ->
      equiv_at (E_Invocation_Expression (IE_Method_Invocation (Method_Invocation rec name (Arguments arg) n))).
  Proof.
    unfold equiv_at; intros.
    unfold expression_type in H.
    fold expression_type in H.
    destruct H1.
    unfold expression_type in H1.
    fold expression_type in H1.
    force_expr (expression_type CE (NatMap.add v s TE) rec).
    destruct d.

    (* Case 1: receiver has interface type. *)
    exists et.
    simpl in H1.
    force_options.
    destruct name.
    force_options.
    destruct f.
    force_options.
    destruct i.
    force_options.
    (* The receiver class must be the same. *)
    assert (expression_type CE (NatMap.add v t TE) rec = [DT_Interface_Type (Interface_Type n0)]).
    pose proof (H CE TE v s t (DT_Interface_Type (Interface_Type n0)) (conj H4 H2)) as IH_rec.
    destruct IH_rec.
    destruct H3.
    unfold type_equiv in H10.
    destruct x.
    crush.
    destruct i0.
    crush.
    crush.
    (* The function called must have the same type. *)
    unfold expression_type.
    fold expression_type.
    rewrite H3; simpl.
    (* The argument is still well typed. *)
    pose proof (H0 CE TE v s t d (conj H5 H2)) as IH_arg.
    destruct IH_arg.
    destruct H10.
    rewrite H10.
    simpl.
    intuition; crush.
    rewrite H6.
    assert (d0 ≡ x).
    pose proof (type_equiv_trans d d0 x (conj H7 H11)); crush.
    rewrite H1; crush.

    (* Case 2: The receiver has function type. *)
    rewrite bind_some in H1.
    force_options.
    destruct name.
    force_options.
    destruct f0.
    force_options.
    pose proof (H CE TE v s t (DT_Function_Type f) (conj H4 H2)).
    destruct H3.
    destruct H3.
    destruct x; [crush|idtac].
    destruct f; destruct f0.
    unfold type_equiv in H9.
    fold type_equiv in H9.
    rewrite Bool.andb_true_iff in H9; destruct H9.
    assert (et = d3) by crush.
    exists d5.
    intuition; [idtac|crush].
    unfold expression_type.
    fold expression_type.
    rewrite H3.
    rewrite bind_some.
    pose proof (H0 CE TE v s t d (conj H5 H2)).
    destruct H12.
    destruct H12.
    rewrite H12.
    rewrite bind_some.
    rewrite H7.
    rewrite bind_some.
    assert (d2 = d0) by crush.
    assert (d0 ≡ d4) by crush.
    assert (d0 ≡ x).
    apply (type_equiv_trans d d0 x (conj H8 H13)).
    pose proof (type_equiv_sym d0 d4 H15).
    pose proof (type_equiv_trans d0 d4 x (conj H17 H16)).
    rewrite H18.
    crush.
  Qed.
  Hint Immediate type_equiv_at_meth_invo.

  Hint Extern 1 =>
    match goal with
      [ x : arguments |- _ ] => destruct x
    end.
  Theorem type_equiv_homo : forall e, equiv_at e.
    apply (expr_induction equiv_at); crush.
  Qed.

End Typing_Equivalence_Homomorphism.
