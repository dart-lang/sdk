(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)


Require Import Coq.Lists.List.
Require Import Common.
Require Import Syntax.
Require Import ObjectModel.


(** Placeholder for a mapping from function node ids to function nodes.  At
  some point the mapping should be defined in the syntax module along with its
  well-formedness definitions. *)
Definition func_env : Type := NatMap.t function_node.


Section OperationalSemantics.


(** This instance of [class_env] is referred in many properties in the section
  for the operational semantics.  One may think about [CE] as a "global" class
  environment for the program. *)
Variable CE : class_env.


(** The "global" environment of function nodes for the program. *)
Variable FE : func_env.

(** Placeholder for one of the well-formedness properties of the program.  At
  some point a property like this one (or another property that will allow this
  property to be established) should be defined in the syntax module. *)
Hypothesis program_wf:
  forall class_id intf proc_desc,
  NatMap.MapsTo class_id intf CE ->
  List.In proc_desc (procedures intf) ->
  NatMap.In (pr_ref proc_desc) FE.


(** [runtime_value] represents the runtime values used in the abstract machine
  during program execution.  The values are typed and have some relation to
  syntactic types and internal representation of their interfaces. Currently a
  runtime value doesn't have a state, it only has a type.  It should have a
  state when a broader subset of Kernel is formalized. *)
Record runtime_value := mk_runtime_value {

  (** In the currently formalized subset of Kernel any runtime type can be
    represented by a syntactic description that is not necessarily defined
    in the program.  In all cases we assume how such type could be potentially
    given using the syntax of the current Kernel subset.

    Null is currently modelled using None as the value of [syntactic_type].
    It may change in future once [dart_type] includes a constructor for Null
    or Bottom. *)
  syntactic_type : option dart_type;
}.


(** [value_of_type] defines the meaning of statement "the runtime value has the
  given interface and the given syntactic type". *)
Inductive value_of_type :
    runtime_value -> interface -> option dart_type -> Prop :=

  (** If the syntactic type of the runtime value is an interface type, then the
    corresponding interface should be in the global class environment. *)
  | RFS_Interface_Type :
    forall (val : runtime_value) (intf : interface) (type : dart_type)
      (class_id : nat),
    type = DT_Interface_Type (Interface_Type class_id) ->
    NatMap.find class_id CE = Some intf ->
    (syntactic_type val) = Some type ->
    value_of_type val intf (Some type)

  (** If the syntactic type of the runtime value is a function type, then the
    corresponding interface may or may not be in the global class environment,
    but should have a particular shape. *)
  | RFS_Function_Type :
    forall (val : runtime_value) (intf : interface) (type : dart_type)
      (par_type ret_type : dart_type)
      (proc : procedure_desc) (proc_rest : list procedure_desc),
    type = DT_Function_Type (Function_Type par_type ret_type) ->
    List.length (procedures intf) = 1%nat ->
    (procedures intf) = List.cons proc proc_rest ->
    ((pr_name proc) = "call")%string ->
    (pr_type proc) = Function_Type par_type ret_type ->
    NatMap.In (pr_ref proc) FE ->
    (syntactic_type val) = Some type ->
    value_of_type val intf (Some type)

  | RFS_Null_Type :
    forall (val : runtime_value) (intf : interface),
    (procedures intf) = nil ->
    (syntactic_type val) = None ->
    value_of_type val intf None.


(** The environment that is used by the abstract machine to map the currently
  visible set of variables to their runtime values is represented as a list of
  pairs. *)
Record environment_entry := mk_environment_entry {
  variable_id : nat;
  value : runtime_value;
}.

Definition environment := list environment_entry.

Definition env_get : nat -> environment -> option environment_entry :=
  fun var_id env =>
    List.find (fun entry => Nat.eqb var_id (variable_id entry)) env.

Definition env_extend : nat -> runtime_value -> environment -> environment :=
  fun var_id val env => (mk_environment_entry var_id val) :: env.

Definition empty_env : environment := nil.

(* TODO(dmitryas): Add some hypotheses about well-formedness of an environment
  w.r.t. to other components. *)


(** TODO(dmitryas): Write descriptive comments. *)
Inductive expression_continuation : Set :=

  (** The constructor receives the following parameters:

    - an [environment]
    - an [expression_continuation]
    - a [statement_continuation] *)
  | Expression_Ek :
    environment
    -> expression_continuation
    -> statement_continuation
    -> expression_continuation

  (** The constructor receives the following parameters:

    - a [string]
    - an [expression]
    - an [environment]
    - an [expression_continuation] *)
  | Method_Invocation_Ek :
    string
    -> expression
    -> environment
    -> expression_continuation
    -> expression_continuation

  (** The constructor receives the following parameters:

    - a [runtime_value]
    - a [string]
    - an [environment]
    - an [expression_continuation] *)
  | Invocation_Ek :
    runtime_value
    -> string
    -> environment
    -> expression_continuation
    -> expression_continuation

  (** The constructor receives the following parameters:

    - a [string]
    - an [expression_continuation] *)
  | Property_Get_Ek :
    string
    -> expression_continuation
    -> expression_continuation

(** TODO(dmitryas): Write descriptive comments. *)
with statement_continuation : Set :=

  (** The constructor receives the following parameters:

    - an [expression_continuation]
    - a [runtime_value] *)
  | Exit_Sk :
    expression_continuation
    -> runtime_value
    -> statement_continuation

  (** The constructor receives the following parameters:

    - a list of [statement]s
    - an [environment]
    - an [expression_continuation]
    - a [statement_continuation] *)
  | Block_Sk :
    list statement
    -> environment
    -> expression_continuation
    -> statement_continuation
    -> statement_continuation.


(** [configuration] represents configurations of the CESK abstract machine that
  is used for defining the operational semantics.  A transition of the machine
  represents a small step of the small-step operational semantics.  There are
  the following types of configurations:

  - [Eval_Configuration] -- encapsulates a syntactic expression and an
    expression continuation.  After evaluation of the expression the resulting
    value is passed to the expression configuration.
  - [Exec_Configuration] -- encapsulates a syntactic statement.  Represents the
    execution of the statement.
  - [Value_Passing_Configuration] -- encapsulates a value and an expression
    continuation.  The value is passed to the expression continuation.
  - [Forward_Configuration] -- encapsulates a statement continuation.
    The execution of the program proceeds to the associated statement. *)
Inductive configuration : Set :=

  (** [Eval_Configuration] represents the beginning of an expression
    evaluation.  The constructor receives the following parameters:

    - an [expression] -- the expression to be evaluated;
    - an [environment] -- the mapping from variables to values that is to be
      used during the expression evaluation;
    - an [expression_continuation] -- the continuation that will receive the
      value of the expression after its evaluation. *)
  | Eval_Configuration :
    expression
    -> environment
    -> expression_continuation
    -> configuration

  (** [Exec_Configuration] represents the beginning of a statement execution.
    The constructor receives the following parameters:

    - a [statement] -- the statement to be executed;
    - an [environment] -- the mapping from variables to values that is to be
      used during the statement execution;
    - an [expression_continuation] -- in case the executed statement returns a
      value, this continuation will receive this value;
    - a [statement_continuation] -- in case the executed statement doesn't
      return a value, this continuation represents the rest of the program
      execution. *)
  | Exec_Configuration :
    statement
    -> environment
    -> expression_continuation
    -> statement_continuation
    -> configuration

  (** [Value_Passing_Configuration] represents the end of an expression
    evaluation.  The constructor receives the following parameters:

    - an [expression_continuation] -- the continuation that receives the value
      which is the result of the expression evaluation;
    - a [value] -- the result of the expression evaluation. *)
  | Value_Passing_Configuration :
    expression_continuation
    -> runtime_value
    -> configuration

  (** [Forward_Configuration] represents the rest of the program execution.
    The constructor receives the following parameters:

    - a [statement_continuation] -- represents the rest of the program
      execution;
    - an [environment] -- the mapping from variables to values that is to be
      used during the execution of the rest of the program. *)
  | Forward_Configuration :
    statement_continuation
    -> environment
    -> configuration.


(** Represents steps (a.k.a. transitions) of the abstract machine. *)
Inductive step : configuration -> configuration -> Prop :=

  (** <Block(stmt :: stmts), ρ, κE, κS>exec ==>
        <stmt, ρ, κE, BlockSK(stmts, ρ, κE, κS)>exec *)
  | Exec_Block :
    forall stmt stmts env ret_cont next_cont,
    step (Exec_Configuration
            (S_Block (Block (stmt :: stmts))) env ret_cont next_cont)
         (Exec_Configuration
            stmt env ret_cont (Block_Sk stmts env ret_cont next_cont))

  (** <Block(#[]#), ρ, κE, κS>exec ==> <κS, ρ>forward *)
  | Exec_Block_Empty :
    forall env ret_cont next_cont,
    step (Exec_Configuration (S_Block (Block nil)) env ret_cont next_cont)
         (Forward_Configuration next_cont env)

  (** <BlockSK(stmt :: stmts, ρ, κE, κS), ρ'>forward ==>
        <stmt, ρ', κE, BlockSK(stmts, ρ, κE, κS)>exec *)
  | Forward_Block_Sk :
    forall stmt stmts env ret_cont next_cont env',
    step (Forward_Configuration
            (Block_Sk (stmt :: stmts) env ret_cont next_cont) env')
         (Exec_Configuration
            stmt env' ret_cont (Block_Sk stmts env ret_cont next_cont))

  (** <BlockSK(#[]#, ρ, κE, κS), ρ'>forward ==> <κS, ρ>forward *)
  | Forward_Block_Sk_Empty :
    forall env ret_cont next_cont env',
    step (Forward_Configuration (Block_Sk nil env ret_cont next_cont) env')
         (Forward_Configuration next_cont env)

  (** <ExpressionStatement(expr), ρ, κE, κS>exec ==>
        <expr, ρ, ExpressionEK(ρ, κE, κS)>eval *)
  | Exec_Expression_Statement :
    forall expr env ret_cont next_cont,
    step (Exec_Configuration
            (S_Expression_Statement (Expression_Statement expr))
             env ret_cont next_cont)
         (Eval_Configuration expr env (Expression_Ek env ret_cont next_cont))

  (** <ReturnStatement(expr), ρ, κE, κS>exec ==> <expr, ρ, κE>eval *)
  | Exec_Return_Statement :
    forall expr env ret_cont next_cont,
    step (Exec_Configuration
            (S_Return_Statement (Return_Statement expr))
             env ret_cont next_cont)
         (Eval_Configuration expr env ret_cont)

  (** <VariableGet(var), ρ, κE>eval ==> <κE, ρ(var)>pass *)
  | Eval_Variable_Get :
    forall var_id env cont entry,
    env_get var_id env = Some entry ->
    step (Eval_Configuration (E_Variable_Get (Variable_Get var_id)) env cont)
         (Value_Passing_Configuration cont (value entry))

  (** <MethodInvocation(rcvr, name, arg), ρ, κE>eval ==>
        <rcvr, ρ, MethodInvocationEK(name, arg, ρ, κE)>eval *)
  | Eval_Method_Invocation :
    (* TODO(dmitryas): Remove [ref] after interfaceTargetReference is removed
      from constructor [Method_Invocation]. *)
    forall rcvr name arg env cont ref,
    step (Eval_Configuration
            (E_Invocation_Expression (IE_Method_Invocation
              (Method_Invocation rcvr (Name name) (Arguments arg) ref)))
            env cont)
         (Eval_Configuration rcvr env
            (Method_Invocation_Ek name arg env cont))

  (** <MethodInvocationEK(name, arg, ρ, κE), rcvrVal)pass ==>
        <arg, ρ, InvocationEK(rcvrVal, name, ρ, κE)>eval *)
  | Pass_Method_Invocation_Ek :
    forall name arg env cont val,
    step (Value_Passing_Configuration
            (Method_Invocation_Ek name arg env cont) val)
         (Eval_Configuration arg env (Invocation_Ek val name env cont))

  (** <InvocationEK(rcvrVal, name, ρ, κE), argVal>pass ==>
        <block, ρ', κE, κS>exec,
      where ρ' = ρ0#[#this = rcvrVal#][#arg(f) = argVal#]#,
        block = body(f),
        κS = ExitSK(κE, nullVal),
        f = methods(class(rcvrVal))(name),
        ρ0 -- empty environment *)
  | Pass_Invocation_Ek :
    forall rcvr_val name env ret_cont arg_val body env' next_cont
      intf type proc_desc proc var_id var_type var_init ret_type null_val,
    (* TODO(dmitryas): Add the mapping: this -> rcvr_val to env'. *)
    value_of_type rcvr_val intf type ->
    List.In proc_desc (procedures intf) ->
    NatMap.MapsTo (pr_ref proc_desc) proc FE ->
    proc = Function_Node (Variable_Declaration var_id var_type var_init)
      ret_type body ->
    env' = env_extend var_id arg_val empty_env ->
    next_cont = Exit_Sk ret_cont null_val ->
    value_of_type null_val (mk_interface nil) None ->
    step (Value_Passing_Configuration
            (Invocation_Ek rcvr_val name env ret_cont) arg_val)
         (Exec_Configuration body env' ret_cont next_cont)

  (** <PropertyGet(rcvr, name), ρ, κE>eval ==>
        <rcvr, ρ, PropertyGetEK(name, κE)>eval *)
  | Eval_Property_Get :
    forall rcvr name env cont,
    step (Eval_Configuration (E_Property_Get (Property_Get rcvr (Name name)))
            env cont)
         (Eval_Configuration rcvr env (Property_Get_Ek name cont))

  (** <PropertyGetEK(name, κE), rcvrVal)pass ==> <κE, f>pass,
      where f = methods(class(rcvrVal))(name) *)
  | Pass_Property_Get_Ek :
    forall name cont rcvr_val rcvr_intf rcvr_type func_val proc_desc,
    value_of_type rcvr_val rcvr_intf rcvr_type ->
    List.In proc_desc (procedures rcvr_intf) ->
    (pr_name proc_desc) = name ->
    value_of_type
      func_val
      (mk_interface (proc_desc :: nil))
      (Some (DT_Function_Type (pr_type proc_desc))) ->
    step (Value_Passing_Configuration (Property_Get_Ek name cont) rcvr_val)
         (Value_Passing_Configuration cont func_val)

  (** <ExitSK(κE, val), ρ>forward ==> <κE, val>pass *)
  | Forward_Exit_Sk :
    forall cont val env,
    step (Forward_Configuration (Exit_Sk cont val) env)
         (Value_Passing_Configuration cont val)

  (** <ConstructorInvocation(cls), ρ, κE>eval ==> <κE, newVal>pass,
      where newVal = new runtime value of syntactic type cls *)
  | Eval_Constructor_Invocation :
    forall env cont new_val intf type proc_desc,
    value_of_type new_val intf type ->
    List.In proc_desc (procedures intf) ->
    step (Eval_Configuration
            (E_Invocation_Expression (IE_Constructor_Invocation
              (Constructor_Invocation (pr_ref proc_desc))))
            env cont)
         (Value_Passing_Configuration cont new_val).


End OperationalSemantics.
