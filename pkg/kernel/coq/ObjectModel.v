(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import Common.
Require Import Syntax.
Import Common.OptionMonad.
Require Import Coq.Strings.String.
Require Import CpdtTactics.

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
    apply
      (dart_type_ind_mutual trans_at
         (fun i => trans_at (DT_Interface_Type i))
         (fun f => trans_at (DT_Function_Type f))).
    crush.
    crush.
    apply interface_type_trans.
    apply function_type_trans.
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

Fixpoint class_type (CE : class_env) (c : class) : option class_env :=
  let (nn_data, _, procedures) := c in
  let (ref) := nn_data in
  let (class_id) := ref in
  let class_interface := mk_interface (map procedure_dissect procedures) in
  let CE' := NatMap.add class_id class_interface CE in
  if forallb (procedure_type CE') procedures then Some CE' else None

with procedure_type (CE : class_env) (p : procedure) : bool :=
  let (_, _, fn) := p in
  let (param, ret_type, body) := fn in
  let (param_var, param_type, _) := param in
  let TE := NatMap.add param_var param_type (NatMap.empty _) in
  match statement_type CE TE body with
  | Some (_, Some t) => type_equiv t ret_type
  | _ => false
  end

with statement_type (CE : class_env) (TE : type_env) (s : statement) :
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

with expression_type (CE : class_env) (TE : type_env) (e : expression) :
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
    let (method_name) := method in
    match rec_type with
    | DT_Function_Type fn_type =>
      if string_dec "call" method_name then [rec_type] else None
    | DT_Interface_Type (Interface_Type class) =>
      interface <- NatMap.find class CE;
      proc_desc <- List.find (fun P =>
        if string_dec (pr_name P) method_name then true else false)
        (procedures interface);
      [DT_Function_Type (pr_type proc_desc)]
    end
  end
.

Section Typing_Equivalence_Homomorphism.

  Definition type_equiv_at_expr (e : expression) :=
    forall CE TE v s t et,
                 expression_type CE (NatMap.add v s TE) e = [et] /\ s ≡ t ->
      exists es, expression_type CE (NatMap.add v t TE) e = [es] /\ et ≡ es.

  Hint Resolve NatMap.add_1.
  Hint Resolve NatMap.add_2.
  Hint Resolve NatMap.find_1.
  Hint Resolve type_equiv_refl.
  Lemma type_equiv_at_variable_get :
    forall v, type_equiv_at_expr (E_Variable_Get (Variable_Get v)).
  Proof.
    unfold type_equiv_at_expr.
    intros.
    destruct (N.eq_dec v v0).
    rewrite e in *.
    exists t.
    assert (et = s).
    unfold expression_type in H.
    assert (NatMap.find v0 (NatMap.add v0 s TE) = Some s).
    crush.
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
    assert (NatMap.MapsTo v et (NatMap.add v0 t TE)); unfold expression_type in *.
    pose proof (@NatMap.add_3 dart_type TE v0 v et s (not_eq_sym n) H).
    crush.
    crush.
  Qed.

  Theorem type_equiv_homo :
    forall CE TE e v s t et,
                 expression_type CE (NatMap.add v s TE) e = [et] /\ s ≡ t ->
      exists es, expression_type CE (NatMap.add v t TE) e = [es] /\ et ≡ es.
  Admitted.

End Typing_Equivalence_Homomorphism.
