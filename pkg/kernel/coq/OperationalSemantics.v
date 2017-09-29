(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)


Require Import Coq.Lists.List.
Require Import Common.
Require Import Syntax.
Require Import ObjectModel.


Section OperationalSemantics.


(** The well-formedness hypothesis is that the environments are built via
  [lib_to_env] function from the object model module.  [program_wf] theorem
  defined there provides the rest of the well-formedness properties.  In
  [OperationalSemantics] sections we don't need the hypothesis itself, just the
  environments. *)
Variable CE : class_env.
Variable ME : member_env.


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
    forall (val : runtime_value) (intf : interface) (ftype : function_type)
        (memb_id : nat) (proc : procedure),
    (procedures intf) =
      (mk_procedure_desc "call" memb_id ftype) :: nil ->
    (getters intf) =
      (mk_getter_desc "call" memb_id (DT_Function_Type ftype)) :: nil ->
    NatMap.MapsTo memb_id (M_Procedure proc) ME ->
    (syntactic_type val) = Some (DT_Function_Type ftype) ->
    value_of_type val intf (Some (DT_Function_Type ftype))

  (** Null values are currently represented as runtime values that have [None]
    in place of their syntactic type.  In future, for example when the bottom
    type or explicit null type are added to the syntax of dart types, the
    representation may change. *)
  | RFS_Null_Type :
    forall (val : runtime_value) (intf : interface),
    (procedures intf) = nil ->
    (getters intf) = nil ->
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

Definition env_in : nat -> environment -> Prop :=
  fun var_id env =>
    match List.find (fun entry => Nat.eqb var_id (variable_id entry)) env with
    | None => False
    | Some _ => True
    end.

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

  (** The constructor receives the following parameters:

    - a [nat]
    - an [environment]
    - a [statement_continuation] *)
  | Var_Declaration_Ek :
    nat
    -> environment
    -> statement_continuation
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
    forall rcvr_val rcvr_intf rcvr_type_opt
      proc_desc memb_data named_data func_node
      var_id var_type var_init ret_type body
      name arg_val env env' ret_cont next_cont null_val,
    (* TODO(dmitryas): Add the mapping: this -> rcvr_val to env'. *)
    value_of_type rcvr_val rcvr_intf rcvr_type_opt ->
    List.In proc_desc (procedures rcvr_intf) ->
    NatMap.MapsTo
      (pr_ref proc_desc)
      (M_Procedure (Procedure memb_data named_data func_node))
      ME ->
    func_node =
      Function_Node
        (Variable_Declaration var_id var_type var_init)
        ret_type
        body ->
    env' = env_extend var_id arg_val empty_env ->
    next_cont = Exit_Sk ret_cont null_val ->
    value_of_type null_val (mk_interface nil nil) None ->
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
    forall rcvr_val rcvr_intf rcvr_type_opt
        name memb_id ret_type
        ret_val ret_intf
        cont,
    value_of_type rcvr_val rcvr_intf rcvr_type_opt ->
    List.In (mk_getter_desc name memb_id ret_type) (getters rcvr_intf) ->
    value_of_type ret_val ret_intf (Some ret_type) ->
    step (Value_Passing_Configuration (Property_Get_Ek name cont) rcvr_val)
         (Value_Passing_Configuration cont ret_val)

  (** <ExitSK(κE, val), ρ>forward ==> <κE, val>pass *)
  | Forward_Exit_Sk :
    forall cont val env,
    step (Forward_Configuration (Exit_Sk cont val) env)
         (Value_Passing_Configuration cont val)

  (** <ConstructorInvocation(cls), ρ, κE>eval ==> <κE, newVal>pass,
      where newVal = new runtime value of syntactic type cls *)
  | Eval_Constructor_Invocation :
    forall env cont new_val intf type_opt class_id,
    NatMap.MapsTo class_id intf CE ->
    value_of_type new_val intf type_opt ->
    step (Eval_Configuration
            (E_Invocation_Expression (IE_Constructor_Invocation
              (Constructor_Invocation class_id)))
            env cont)
         (Value_Passing_Configuration cont new_val)

  (** <VariableDeclaration(var, type, NONE), ρ, κE, κS>exec ==>
        <κS, ρ'>forward,
      where ρ' = ρ#[#var = nullVal#]# *)
  | Exec_Variable_Declaration_Non_Init :
    forall var_id type env ret_cont next_cont null_val env',
    value_of_type null_val (mk_interface nil nil) None ->
    env' = env_extend var_id null_val env ->
    step (Exec_Configuration
            (S_Variable_Declaration (Variable_Declaration var_id type None))
            env ret_cont next_cont)
         (Forward_Configuration next_cont env')

  (** <VariableDeclaration(var, type, expr), ρ, κE, κS>exec ==>
        <expr, ρ, VarDeclarationEK(var, ρ, κS)>eval *)
  | Exec_Variable_Declaration_Init :
    forall var_id type expr env ret_cont next_cont,
    step (Exec_Configuration
            (S_Variable_Declaration
              (Variable_Declaration var_id type (Some expr)))
            env ret_cont next_cont)
         (Eval_Configuration expr env
            (Var_Declaration_Ek var_id env next_cont))

  (** <VarDeclarationEK(var, ρ, κS), val>pass ==> <κS, ρ'>forward,
      where ρ' = ρ#[#var = val#]# *)
  | Pass_Var_Declaration_Ek :
    forall var_id env cont val env',
    env' = env_extend var_id val env ->
    step (Value_Passing_Configuration (Var_Declaration_Ek var_id env cont) val)
         (Forward_Configuration cont env').


(** Well-formedness property over configurations is understood as the property
  of being a valid l.h.s. to the [step] relation.  The abstract machine may or
  may not end up in a well-formed configuration several steps after its
  configuration was well-formed. *)
Inductive configuration_wf : configuration -> Prop :=

  (** Well-formed variable-gets should have the variable in the environment. *)
  | Eval_Variable_Get_Configuration_Wf :
    forall var_id env cont,
    env_in var_id env ->
    configuration_wf (Eval_Configuration
      (E_Variable_Get (Variable_Get var_id))
      env cont)

  (** Configurations that are the beginning of a method-invocation evaluation
    are always well-formed, because the machine always proceed to evaluation of
    the receiver. *)
  | Eval_Method_Invocation_Configuration_Wf :
    forall rcvr name arg ref env cont,
    configuration_wf (Eval_Configuration
      (E_Invocation_Expression (IE_Method_Invocation
        (Method_Invocation rcvr (Name name) (Arguments arg) ref)))
      env cont)

  (** Configurations that are the beginning of a property-get evaluation are
    always well-formed, because the machine always proceed to evaluation of the
    receiver. *)
  | Eval_Property_Get_Configuration_Wf :
    forall rcvr name env cont,
    configuration_wf (Eval_Configuration
      (E_Property_Get (Property_Get rcvr (Name name)))
      env cont)

  (** A constructor invocation is well-formed if the referred class exists in
    the class environment. *)
  | Eval_Constructor_Invocation_Configuration_Wf :
    forall class_id env cont,
    NatMap.In class_id CE ->
    configuration_wf (Eval_Configuration
      (E_Invocation_Expression (IE_Constructor_Invocation
        (Constructor_Invocation class_id)))
      env cont)

  (** In the current subset of Kernel all exec configurations are
    well-formed.  The machine either procedes to evaluation of an expression
    that is a part of the statement or procedes to the next continuation. *)
  | Exec_Configuration_Wf :
    forall stmt env ret_cont next_cont,
    configuration_wf (Exec_Configuration stmt env ret_cont next_cont)

  (** These configurations pass the receiver to the continuation that is the
    the rest of the method invocation.  These configurations are always
    well-formed, because the machine always procedes to the evaluation of the
    argument. *)
  | Pass_Method_Invocation_Ek_Configuration_Wf :
    forall name arg env cont val,
    configuration_wf (Value_Passing_Configuration
      (Method_Invocation_Ek name arg env cont)
      val)

  (** These configurations pass the evaluated argument to the rest of the
    method invocation.  The execution of the method begins, and many conditions
    should be met. *)
  | Pass_Invocation_Ek_Configuration_Wf :
    forall rcvr_val rcvr_intf rcvr_type_opt
        proc_desc name
        ret_cont arg_val env,
    value_of_type rcvr_val rcvr_intf rcvr_type_opt ->
    List.In proc_desc (procedures rcvr_intf) ->
    (pr_name proc_desc) = name ->
    configuration_wf (Value_Passing_Configuration
      (Invocation_Ek rcvr_val name env ret_cont)
      arg_val)

  (** These configurations pass the evaluated receiver to the rest of the
    property get.  The preconditions state that the property with such name
    should exist. *)
  | Pass_Property_Get_Ek_Configuration_Wf :
    forall name cont rcvr_val rcvr_intf rcvr_type_opt get_desc,
    value_of_type rcvr_val rcvr_intf rcvr_type_opt ->
    List.In get_desc (getters rcvr_intf) ->
    (gt_name get_desc) = name ->
    configuration_wf (Value_Passing_Configuration
      (Property_Get_Ek name cont)
      rcvr_val)

  (** In the currently formalized subset of Kernel all forward configurations
    are well-formed.  The machine either proceeds to the execution of a
    a statement or proceeds to the next continuation. *)
  | Forward_Configuration_Wf :
    forall cont env,
    configuration_wf (Forward_Configuration cont env).


End OperationalSemantics.
