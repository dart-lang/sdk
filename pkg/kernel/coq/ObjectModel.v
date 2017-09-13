(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)

Require Import Common.
Require Import Syntax.
Import Common.OptionMonad.
Module L := Common.ListExtensions.
Require Import Coq.Strings.String.

Fixpoint type_equiv (s : dart_type) (t : dart_type) : bool :=
  match (s, t) with
  | (DT_Interface_Type (Interface_Type s_class),
     DT_Interface_Type (Interface_Type t_class)) =>
    Nat.eqb s_class t_class
  | (DT_Function_Type (Function_Type s_param s_ret),
     DT_Function_Type (Function_Type t_param t_ret)) =>
    type_equiv s_param t_param && type_equiv s_ret t_ret
  | _ => false
  end.

Notation "s ≡ t" := (type_equiv s t = true) (at level 70, no associativity).

Lemma type_equiv_trans : forall s t r, s ≡ t /\ t ≡ r -> s ≡ r.
Admitted.

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

with expression_type (CE : class_env) (TE : type_env) (e : expression) : option dart_type :=
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

Lemma type_equiv_sanity1 :
  forall CE TE e v s t et,
    expression_type CE (NatMap.add v s TE) e = Some et /\ s ≡ t ->
    exists es, expression_type CE (NatMap.add v t TE) e = Some es /\ et ≡ es.
Admitted.
