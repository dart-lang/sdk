(* Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file. *)


Require Import Coq.Lists.List.
Require Import Common.
Require Import Syntax.
Require Import ObjectModel.


Import ObjectModel.Subtyping.

Notation "s <: t" := (subtype (s, t) = true) (at level 70, no associativity).


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

  (** Null is currently modelled using None as the value of [runtime_type].
    It may change in future once [dart_type] includes a constructor for Null
    or Bottom.  Also, in the current subset of Kernel type Null can't be
    expressed syntactically; therefore, it can't be a declared type of a method
    parameter, a declared type of a variable, etc.  The only use of Null in the
    current subset of Kernel is that of a runtime type of a runtime value.  In
    that case the declared type of the variable holding such value and the
    runtime type of the value do not match.  *)
  runtime_type : option dart_type;
}.


(** [value_of_type] defines the meaning of statement "the runtime value has the
  given interface and the given type". *)
Inductive value_of_type :
    runtime_value -> interface -> option dart_type -> Prop :=

  (** If the type of the runtime value is an interface type, then the
    corresponding interface should be in the global class environment. *)
  | RFS_Interface_Type :
    forall val intf type class_id,
    type = DT_Interface_Type (Interface_Type class_id) ->
    NatMap.find class_id CE = Some intf ->
    (runtime_type val) = Some type ->
    value_of_type val intf (Some type)

  (** If the type of the runtime value is a function type, then the
    corresponding interface may or may not be in the global class environment,
    but should have a particular shape. *)
  | RFS_Function_Type :
    forall val intf ftype memb_id proc,
    (procedures intf) = (mk_procedure_desc "call" memb_id ftype) :: nil ->
    (getters intf) =
      (mk_getter_desc "call" memb_id (DT_Function_Type ftype)) :: nil ->
    NatMap.MapsTo memb_id (M_Procedure proc) ME ->
    (runtime_type val) = Some (DT_Function_Type ftype) ->
    value_of_type val intf (Some (DT_Function_Type ftype))

  (** Null values are currently represented as runtime values that have [None]
    in place of their type.  In future, for example when the Bottom type or
    explicit Null type are added to the syntax of dart types, the
    representation may change. *)
  | RFS_Null_Type :
    forall val intf,
    (procedures intf) = nil ->
    (getters intf) = nil ->
    (runtime_type val) = None ->
    value_of_type val intf None.


(** Describes that the given dart type has a method with the given name.  The
  predicate can be applied to runtime types of values, so it should accept None
  as the first parameter to account for `null` values.

  Currently, values of function type only have "call" methods, and null doesn't
  have any methods. *)
Inductive method_exists : option dart_type -> string -> Prop :=

  | ME_Interface_Type :
    forall name intf desc class_id type,
    type = (DT_Interface_Type (Interface_Type class_id)) ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some type)) intf (Some type) ->
    List.In desc (procedures intf) ->
    ((pr_name desc) = name)%string ->
    method_exists (Some type) name

  | ME_Function_Type :
    forall type intf desc ftype,
    type = (DT_Function_Type ftype) ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some type)) intf (Some type) ->
    List.In desc (procedures intf) ->
    ((pr_name desc) = "call")%string ->
    method_exists (Some type) "call".


(** Describes that the method with the given name of the given dart type
  accepts arguments of the given type.  The predicate can be applied to runtime
  types of values, so it should accept None as the first parameter to account
  for `null` values.

  Currently, values of function type only have "call" methods, and null doesn't
  have any methods. *)
Inductive method_accepts :
    option dart_type -> string -> option dart_type -> Prop :=

  | MA_Non_Null :
    forall name intf desc rcvr_type arg_type par_type ret_type,
    method_exists (Some rcvr_type) name ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some rcvr_type)) intf (Some rcvr_type) ->
    List.In desc (procedures intf) ->
    ((pr_name desc) = name)%string ->
    (pr_type desc) = Function_Type par_type ret_type ->
    arg_type <: par_type ->
    method_accepts (Some rcvr_type) name (Some arg_type)

  | MA_Null :
    forall rcvr_type_opt name,
    method_exists rcvr_type_opt name ->
    method_accepts rcvr_type_opt name None.


(** Describes that the method with the given name of the given dart type
  returns a value of the given type.  The predicate can be applied to runtime
  types of values, so it should accept None as the first parameter to account
  for `null` values.

  Currently, values of function type only have "call" methods, and null doesn't
  have any methods. *)
Inductive method_returns :
    option dart_type -> string -> dart_type -> Prop :=

  | Method_Returns :
    forall name intf desc rcvr_type par_type ret_type,
    method_exists (Some rcvr_type) name ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some rcvr_type)) intf (Some rcvr_type) ->
    List.In desc (procedures intf) ->
    ((pr_name desc) = name)%string ->
    (pr_type desc) = Function_Type par_type ret_type ->
    method_returns (Some rcvr_type) name ret_type.


(** Describes that the given dart type has a getter with the given name.  The
  predicate can be applied to runtime types of values, so it should accept None
  as the first parameter to account for `null` values.

  Currently, values of function type only have "call" getters, and null doesn't
  have any getters. *)
Inductive getter_exists : option dart_type -> string -> Prop :=

  | GE_Interface_Type :
    forall name intf desc class_id type,
    type = (DT_Interface_Type (Interface_Type class_id)) ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some type)) intf (Some type) ->
    List.In desc (getters intf) ->
    ((gt_name desc) = name)%string ->
    getter_exists (Some type) name

  | GE_Function_Type :
    forall type intf desc ftype,
    type = (DT_Function_Type ftype) ->
    (* TODO(dmitryas): Replace `value_of_type` here with a relation that binds
      together the interface and the type, avoiding the construction of the
      value. *)
    value_of_type (mk_runtime_value (Some type)) intf (Some type) ->
    List.In desc (getters intf) ->
    ((gt_name desc) = "call")%string ->
    getter_exists (Some type) "call".


(** Describes that the getter with the given name of the given dart type
  returns a value of the given type.  The predicate can be applied to runtime
  types of values, so it should accept None as the first parameter to account
  for `null` values.

  Currently, values of function type only have "call" getters, and null doesn't
  have any getters. *)
Inductive getter_returns :
    option dart_type -> string -> dart_type -> Prop :=

  | Getter_Returns :
    forall name intf desc rcvr_type,
    getter_exists (Some rcvr_type) name ->
    value_of_type (mk_runtime_value (Some rcvr_type)) intf (Some rcvr_type) ->
    List.In desc (getters intf) ->
    ((gt_name desc) = name)%string ->
    getter_returns (Some rcvr_type) name (gt_type desc).


(** The environment that is used by the abstract machine to map the currently
  visible set of variables to their types and runtime values is represented as
  a list of records.

  [var_type] represents the declared type of the variable and may not match
  the runtime type of the [value] in case the latter is Null.  This is because
  in the current subset of Kernel Null can't be represented syntactically. *)
Record env_entry := mk_env_entry {
  var_ref   : nat;
  var_type  : dart_type;
  value     : runtime_value;
}.

Definition environment := list env_entry.

Definition env_get
      (var : nat)
      (env : environment)
    : option env_entry :=
  List.find (fun entry => Nat.eqb var (var_ref entry)) env.

Definition env_extend
      (var  : nat)
      (type : dart_type)
      (val  : runtime_value)
      (env  : environment)
    : environment :=
  (mk_env_entry var type val) :: env.

Definition env_in
      (var : nat)
      (env : environment)
    : Prop :=
  match List.find (fun entry => Nat.eqb var (var_ref entry)) env with
  | None    => False
  | Some _  => True
  end.

Definition empty_env : environment := nil.

Definition env_to_type_env : environment -> type_env :=
  fun env => List.fold_left
    (fun TE entry => NatMap.add (var_ref entry) (var_type entry) TE)
    env
    (NatMap.empty dart_type).


(** TODO(dmitryas): Write descriptive comments.

  First, [untyped_expression_continuation] is defined.  Its only difference
  from [expression_continuation] is that the value expected by the continuation
  is untyped; [expression_continuation] pairs an
  [untyped_expression_continuation] and a [dart_type], giving the expected
  value a type.  It is done to simplify the extraction of the type from an
  expression continuation in predicates. *)
Inductive untyped_expression_continuation : Set :=

  (** The constructor receives the following parameters:

    - an [environment]
    - a [expression_continuation]
    - a [statement_continuation] *)
  | Expression_Ek :
       environment
    -> expression_continuation
    -> statement_continuation
    -> untyped_expression_continuation

  (** The constructor receives the following parameters:

    - a [string]
    - an [expression]
    - an [environment]
    - a [expression_continuation] *)
  | Method_Invocation_Ek :
       string
    -> expression
    -> environment
    -> expression_continuation
    -> untyped_expression_continuation

  (** The constructor receives the following parameters:

    - a [runtime_value]
    - a [string]
    - an [environment]
    - a [expression_continuation] *)
  | Invocation_Ek :
       runtime_value
    -> string
    -> environment
    -> expression_continuation
    -> untyped_expression_continuation

  (** The constructor receives the following parameters:

    - a [string]
    - a [expression_continuation] *)
  | Property_Get_Ek :
       string
    -> expression_continuation
    -> untyped_expression_continuation

  (** The constructor receives the following parameters:

    - a [nat]
    - a [dart_type]
    - an [environment]
    - a [statement_continuation] *)
  | Var_Declaration_Ek :
       nat
    -> dart_type
    -> environment
    -> statement_continuation
    -> untyped_expression_continuation

  (** [Halt_Ek] represents the end of program execution.  The main procedure
    returns a value (or null) to this expression continuation.  The value is
    then ignored, and the program execution halts.  The constructor doesn't
    receive any parameters. *)
  | Halt_Ek :
    untyped_expression_continuation

(** TODO(dmitryas): Write descriptive comments. *)
with statement_continuation : Set :=

  (** The constructor receives the following parameters:

    - a [expression_continuation]
    - a [runtime_value] *)
  | Exit_Sk :
       expression_continuation
    -> runtime_value
    -> statement_continuation

  (** The constructor receives the following parameters:

    - a list of [statement]s
    - an [environment]
    - a [expression_continuation]
    - a [statement_continuation] *)
  | Block_Sk :
       list statement
    -> environment
    -> expression_continuation
    -> statement_continuation
    -> statement_continuation

(** A [expression_continuation] encapsulates a [dart_type] that signifies
  the type of the value expected by the expression continuation as the
  input.

  In the current subset of Kernel the Null type can't be described
  syntactically, so it can't be a type of a typed expression or statement.
  Therefore, the type of the value expected by the expression continuation
  can't be Null, and it's expressed as [dart_type], not [option dart_type]. *)
with expression_continuation : Set :=

  | Expression_Continuation :
       untyped_expression_continuation
    -> dart_type
    -> expression_continuation.


(** [configuration] represents configurations of the CESK abstract machine that
  is used for defining the operational semantics.  A transition of the machine
  represents a small step of the small-step operational semantics.  There are
  the following types of configurations:

  - [Eval_Configuration] — encapsulates a syntactic expression and an
    expression continuation.  After evaluation of the expression the resulting
    value is passed to the expression configuration.
  - [Exec_Configuration] — encapsulates a syntactic statement.  Represents the
    execution of the statement.
  - [Value_Passing_Configuration] — encapsulates a value and an expression
    continuation.  The value is passed to the expression continuation.
  - [Forward_Configuration] — encapsulates a statement continuation.
    The execution of the program proceeds to the associated statement. *)
Inductive configuration : Set :=

  (** [Eval_Configuration] represents the beginning of an expression
    evaluation.  The constructor receives the following parameters:

    - an [expression] — the expression to be evaluated;
    - an [environment] — the mapping from variables to values that is to be
      used during the expression evaluation;
    - a [expression_continuation] — the continuation that will receive
      the value of the expression after its evaluation. *)
  | Eval_Configuration :
       expression
    -> environment
    -> expression_continuation
    -> configuration

  (** [Exec_Configuration] represents the beginning of a statement execution.
    The constructor receives the following parameters:

    - a [statement] — the statement to be executed;
    - an [environment] — the mapping from variables to values that is to be
      used during the statement execution;
    - a [expression_continuation] — in case the executed statement
      returns a value, this continuation will receive this value;
    - a [statement_continuation] — in case the executed statement
      doesn't return a value, this continuation represents the rest of the
      program execution. *)
  | Exec_Configuration :
       statement
    -> environment
    -> expression_continuation
    -> statement_continuation
    -> configuration

  (** [Value_Passing_Configuration] represents the end of an expression
    evaluation.  The constructor receives the following parameters:

    - a [expression_continuation] — the continuation that receives the
      value which is the result of the expression evaluation;
    - a [value] — the result of the expression evaluation. *)
  | Value_Passing_Configuration :
       expression_continuation
    -> runtime_value
    -> configuration

  (** [Forward_Configuration] represents the rest of the program execution.
    The constructor receives the following parameters:

    - a [statement_continuation] — represents the rest of the program
      execution;
    - an [environment] — the mapping from variables to values that is to be
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
            (S_Block (Block (stmt :: stmts)))
            env ret_cont next_cont)
         (Exec_Configuration
            stmt env ret_cont
            (Block_Sk stmts env ret_cont next_cont))

  (** <Block(#[]#), ρ, κE, κS>exec ==> <κS, ρ>forward *)
  | Exec_Block_Empty :
    forall env ret_cont next_cont,
    step (Exec_Configuration
            (S_Block (Block nil)) env ret_cont next_cont)
         (Forward_Configuration next_cont env)

  (** <BlockSK(stmt :: stmts, ρ, κE, κS), ρ'>forward ==>
        <stmt, ρ', κE, BlockSK(stmts, ρ, κE, κS)>exec *)
  | Forward_Block_Sk :
    forall stmt stmts env ret_cont next_cont env',
    step (Forward_Configuration
            (Block_Sk (stmt :: stmts) env ret_cont next_cont)
            env')
         (Exec_Configuration
            stmt env' ret_cont
            (Block_Sk stmts env ret_cont next_cont))

  (** <BlockSK(#[]#, ρ, κE, κS), ρ'>forward ==> <κS, ρ>forward *)
  | Forward_Block_Sk_Empty :
    forall env ret_cont next_cont env',
    step (Forward_Configuration
            (Block_Sk nil env ret_cont next_cont)
            env')
         (Forward_Configuration next_cont env)

  (** <ExpressionStatement(expr), ρ, κE, κS>exec ==>
        <expr, ρ, ExpressionEK(ρ, κE, κS)>eval *)
  | Exec_Expression_Statement :
    forall expr env ret_cont next_cont ret_type,
    expression_type CE (env_to_type_env env) expr = Some ret_type ->
    step (Exec_Configuration
            (S_Expression_Statement (Expression_Statement expr))
            env ret_cont next_cont)
         (Eval_Configuration
            expr env
            (Expression_Continuation
              (Expression_Ek env ret_cont next_cont)
              ret_type))

  (** <ReturnStatement(expr), ρ, κE, κS>exec ==> <expr, ρ, κE>eval *)
  | Exec_Return_Statement :
    forall expr env ret_cont next_cont,
    step (Exec_Configuration
            (S_Return_Statement (Return_Statement expr))
             env ret_cont next_cont)
         (Eval_Configuration expr env ret_cont)

  (** <VariableGet(var), ρ, κE>eval ==> <κE, ρ(var)>pass *)
  | Eval_Variable_Get :
    forall var_id env ret_cont entry,
    env_get var_id env = Some entry ->
    step (Eval_Configuration
            (E_Variable_Get (Variable_Get var_id)) env ret_cont)
         (Value_Passing_Configuration
            ret_cont (value entry))

  (** <MethodInvocation(rcvr, name, arg), ρ, κE>eval ==>
        <rcvr, ρ, MethodInvocationEK(name, arg, ρ, κE)>eval *)
  | Eval_Method_Invocation :
    (* TODO(dmitryas): Remove [ref] after interfaceTargetReference is removed
      from constructor [Method_Invocation]. *)
    forall rcvr_expr rcvr_type name arg env ret_cont ref,
    expression_type CE (env_to_type_env env) rcvr_expr = Some rcvr_type ->
    step (Eval_Configuration
            (E_Invocation_Expression (IE_Method_Invocation
              (Method_Invocation rcvr_expr (Name name) (Arguments arg) ref)))
            env ret_cont)
         (Eval_Configuration rcvr_expr env
            (Expression_Continuation
              (Method_Invocation_Ek name arg env ret_cont)
              rcvr_type))

  (** <MethodInvocationEK(name, arg, ρ, κE), rcvrVal)pass ==>
        <arg, ρ, InvocationEK(rcvrVal, name, ρ, κE)>eval,
      rcvrVall != null *)
  | Pass_Method_Invocation_Ek_Non_Null :
    forall name arg_expr arg_type env ret_cont
        rcvr_val rcvr_type expected_rcvr_type,
    runtime_type rcvr_val = Some rcvr_type ->
    expression_type CE (env_to_type_env env) arg_expr = Some arg_type ->
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Method_Invocation_Ek name arg_expr env ret_cont)
              expected_rcvr_type)
            rcvr_val)
         (Eval_Configuration arg_expr env
            (Expression_Continuation
              (Invocation_Ek rcvr_val name env ret_cont)
              arg_type))

  (** <InvocationEK(rcvrVal, name, ρ, κE), argVal>pass ==>
        <block, ρ', κE, κS>exec,
      where ρ' = ρ0#[#this = rcvrVal#][#arg(f) = argVal#]#,
        block = body(f),
        κS = ExitSK(κE, nullVal),
        f = methods(class(rcvrVal))(name),
        ρ0 — empty environment *)
  | Pass_Invocation_Ek :
    forall rcvr_val rcvr_intf rcvr_type_opt
      proc_desc memb_data named_data func_node
      var_id var_type var_init ret_type body
      name arg_val arg_type env env'
      ret_cont next_cont null_val,
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
    env' = env_extend var_id var_type arg_val empty_env ->
    next_cont = Exit_Sk ret_cont null_val ->
    value_of_type null_val (mk_interface nil nil) None ->
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Invocation_Ek rcvr_val name env ret_cont)
              arg_type)
            arg_val)
         (Exec_Configuration body env' ret_cont next_cont)

  (** <PropertyGet(rcvr, name), ρ, κE>eval ==>
        <rcvr, ρ, PropertyGetEK(name, κE)>eval *)
  | Eval_Property_Get :
    forall rcvr_expr rcvr_type name env ret_cont,
    expression_type CE (env_to_type_env env) rcvr_expr = Some rcvr_type ->
    step (Eval_Configuration
            (E_Property_Get (Property_Get rcvr_expr (Name name)))
            env ret_cont)
         (Eval_Configuration
            rcvr_expr env
            (Expression_Continuation
              (Property_Get_Ek name ret_cont)
              rcvr_type))

  (** <PropertyGetEK(name, κE), rcvrVal)pass ==> <κE, f>pass,
      where f = methods(class(rcvrVal))(name) *)
  | Pass_Property_Get_Ek :
    forall rcvr_val rcvr_intf rcvr_type_opt expected_rcvr_type
        name memb_id ret_type
        ret_val ret_intf
        ret_cont,
    value_of_type rcvr_val rcvr_intf rcvr_type_opt ->
    List.In (mk_getter_desc name memb_id ret_type) (getters rcvr_intf) ->
    value_of_type ret_val ret_intf (Some ret_type) ->
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Property_Get_Ek name ret_cont)
              expected_rcvr_type)
            rcvr_val)
         (Value_Passing_Configuration
            ret_cont ret_val)

  (** <ExitSK(κE, val), ρ>forward ==> <κE, val>pass *)
  | Forward_Exit_Sk :
    forall ret_cont val env,
    step (Forward_Configuration (Exit_Sk ret_cont val) env)
         (Value_Passing_Configuration ret_cont val)

  (** <ConstructorInvocation(cls), ρ, κE>eval ==> <κE, newVal>pass,
      where newVal = new runtime value of syntactic type cls *)
  | Eval_Constructor_Invocation :
    forall env ret_cont new_val intf type_opt class_id,
    NatMap.MapsTo class_id intf CE ->
    value_of_type new_val intf type_opt ->
    step (Eval_Configuration
            (E_Invocation_Expression (IE_Constructor_Invocation
              (Constructor_Invocation class_id)))
            env ret_cont)
         (Value_Passing_Configuration ret_cont new_val)

  (** <VariableDeclaration(var, type, NONE), ρ, κE, κS>exec ==>
        <κS, ρ'>forward,
      where ρ' = ρ#[#var = nullVal#]# *)
  | Exec_Variable_Declaration_Non_Init :
    forall var type env ret_cont next_cont null_val env',
    value_of_type null_val (mk_interface nil nil) None ->
    env' = env_extend var type null_val env ->
    step (Exec_Configuration
            (S_Variable_Declaration (Variable_Declaration var type None))
            env ret_cont next_cont)
         (Forward_Configuration next_cont env')

  (** <VariableDeclaration(var, type, expr), ρ, κE, κS>exec ==>
        <expr, ρ, VarDeclarationEK(var, ρ, κS)>eval *)
  | Exec_Variable_Declaration_Init :
    forall var var_type init_type expr env ret_cont next_cont,
    expression_type CE (env_to_type_env env) expr = Some init_type ->
    step (Exec_Configuration
            (S_Variable_Declaration
              (Variable_Declaration var var_type (Some expr)))
            env ret_cont next_cont)
         (Eval_Configuration expr env
            (Expression_Continuation
              (Var_Declaration_Ek var var_type env next_cont)
              init_type))

  (** <VarDeclarationEK(var, ρ, κS), val>pass ==> <κS, ρ'>forward,
      where ρ' = ρ#[#var = val#]# *)
  | Pass_Var_Declaration_Ek :
    forall var var_type init_type env next_cont val env',
    env' = env_extend var var_type val env ->
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Var_Declaration_Ek var var_type env next_cont)
              init_type)
            val)
         (Forward_Configuration next_cont env')

  (** <ExpressionEK(ρ, κE, κS), val>pass ==> <κS, ρ>forward *)
  | Pass_Expression_Ek :
    forall env ret_cont next_cont val val_type,
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Expression_Ek env ret_cont next_cont)
              val_type)
            val)
         (Forward_Configuration next_cont env)

  (** <MethodInvocationEK(name, arg, ρ, κE), null)pass ==>
        <HaltEK, null>pass *)
  | Pass_Method_Invocation_Ek_Null :
    forall name arg_expr arg_type env ret_cont expected_rcvr_type,
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Method_Invocation_Ek name arg_expr env ret_cont)
              expected_rcvr_type)
            (mk_runtime_value None))
         (Value_Passing_Configuration
            (Expression_Continuation
              Halt_Ek
              arg_type)
            (mk_runtime_value None))

  (** <PropertyGetEK(name, κE), null)pass ==> <HaltEK, null>pass *)
  | Pass_Property_Get_Ek_Null :
    forall name ret_cont expected_rcvr_type,
    step (Value_Passing_Configuration
            (Expression_Continuation
              (Property_Get_Ek name ret_cont)
              expected_rcvr_type)
            (mk_runtime_value None))
         (Value_Passing_Configuration
            (Expression_Continuation
              Halt_Ek
              expected_rcvr_type)
            (mk_runtime_value None)).

(* TODO(dmitryas): Add transitions to final states. *)


(** Well-formedness property over configurations is understood as the property
  of being a valid l.h.s. to the [step] relation.  The abstract machine may or
  may not end up in a well-formed configuration several steps after its
  configuration was well-formed. *)
Inductive configuration_wf : configuration -> Prop :=

  (** Well-formed variable-gets should have the variable in the environment. *)
  | Eval_Variable_Get_Configuration_Wf :
    forall var env ret_cont,
    env_in var env ->
    configuration_wf
      (Eval_Configuration
        (E_Variable_Get (Variable_Get var))
        env ret_cont)

  (** Configurations that are the beginning of a method-invocation evaluation
    are well-formed if the expression that represents the receiver is
    well-typed, because the machine proceed to evaluation of the receiver, and
    the continuation that awaits for the receiver value should be typed. *)
  | Eval_Method_Invocation_Configuration_Wf :
    forall rcvr_expr rcvr_type name arg_expr ref env ret_cont,
    expression_type CE (env_to_type_env env) rcvr_expr = Some rcvr_type ->
    configuration_wf
      (Eval_Configuration
        (E_Invocation_Expression (IE_Method_Invocation
          (Method_Invocation rcvr_expr (Name name) (Arguments arg_expr) ref)))
        env ret_cont)

  (** Configurations that are the beginning of a property-get evaluation are
    well-formed if the receiver expression is well-typed, because the machine
    always proceed to evaluation of the receiver, and the continuation that
    awaits for the receiver value should be typed. *)
  | Eval_Property_Get_Configuration_Wf :
    forall rcvr_expr rcvr_type name env ret_cont,
    expression_type CE (env_to_type_env env) rcvr_expr = Some rcvr_type ->
    configuration_wf
      (Eval_Configuration
        (E_Property_Get (Property_Get rcvr_expr (Name name)))
        env ret_cont)

  (** A constructor invocation is well-formed if the referred class exists in
    the class environment. *)
  | Eval_Constructor_Invocation_Configuration_Wf :
    forall class_id env ret_cont,
    NatMap.In class_id CE ->
    configuration_wf
      (Eval_Configuration
        (E_Invocation_Expression (IE_Constructor_Invocation
          (Constructor_Invocation class_id)))
        env ret_cont)

  (** TODO(dmitryas): Write descriptive comment here. *)
  | Exec_Variable_Declaration_Init_Wf :
  forall var var_type init_expr init_type env ret_cont next_cont,
    expression_type CE (env_to_type_env env) init_expr = Some init_type ->
    configuration_wf
      (Exec_Configuration
        (S_Variable_Declaration
          (Variable_Declaration var var_type (Some init_expr)))
        env ret_cont next_cont)

  (** TODO(dmitryas): Write descriptive comment here. *)
  | Exec_Variable_Declaration_Non_Init_Wf :
    forall var var_type env ret_cont next_cont,
    configuration_wf
      (Exec_Configuration
        (S_Variable_Declaration
          (Variable_Declaration var var_type None))
        env ret_cont next_cont)

  (** TODO(dmitryas): Write descriptive comment here. *)
  | Exec_Return_Statement_Wf :
    forall expr env ret_cont next_cont,
    configuration_wf
      (Exec_Configuration
        (S_Return_Statement (Return_Statement expr))
        env ret_cont next_cont)

  (** TODO(dmitryas): Write descriptive comment here. *)
  | Exec_Expression_Statement_Wf :
    forall expr expr_type env ret_cont next_cont,
    expression_type CE (env_to_type_env env) expr = Some expr_type ->
    configuration_wf
      (Exec_Configuration
        (S_Expression_Statement (Expression_Statement expr))
        env ret_cont next_cont)

  (** TODO(dmitryas): Write descriptive comment here. *)
  | Exec_Block_Wf :
    forall stmts env ret_cont next_cont,
    configuration_wf
      (Exec_Configuration (S_Block (Block stmts)) env ret_cont next_cont)

  (** These configurations pass the receiver to the continuation that is the
    rest of the method invocation.  These configurations are well-formed if the
    argument expression is well-typed, because the machine procedes to the
    evaluation of the argument, and the expression continuation that awaits for
    the argument value needs to be typed. *)
  | Pass_Method_Invocation_Ek_Non_Null_Configuration_Wf :
    forall name arg_expr arg_type env ret_cont
        expected_rcvr_type rcvr_type rcvr_val,
    runtime_type rcvr_val = Some rcvr_type ->
    expression_type CE (env_to_type_env env) arg_expr = Some arg_type ->
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Method_Invocation_Ek name arg_expr env ret_cont)
          expected_rcvr_type)
        rcvr_val)

  (** These configurations pass the evaluated argument to the rest of the
    method invocation.  The precondition is that the method with such name
    exists. *)
  | Pass_Invocation_Ek_Configuration_Wf :
    forall rcvr_val name ret_cont arg_val arg_type env,
    method_exists (runtime_type rcvr_val) name ->
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Invocation_Ek rcvr_val name env ret_cont)
          arg_type)
        arg_val)

  (** These configurations pass the evaluated receiver to the rest of the
    property get.  The preconditions is that the getter with such name
    exists. *)
  | Pass_Property_Get_Ek_Non_Null_Configuration_Wf :
    forall name ret_cont expected_rcvr_type rcvr_type rcvr_val,
    runtime_type rcvr_val = Some rcvr_type ->
    getter_exists (runtime_type rcvr_val) name ->
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Property_Get_Ek name ret_cont)
          expected_rcvr_type)
        rcvr_val)

  (** In the currently formalized subset of Kernel all forward configurations
    are well-formed.  The machine either proceeds to the execution of a
    a statement or proceeds to the next continuation. *)
  | Forward_Configuration_Wf :
    forall next_cont env,
    configuration_wf (Forward_Configuration next_cont env)

  (** TODO(dmitryas): Write descriptive comments. *)
  | Pass_Expression_Ek_Configuration_Wf :
    forall env ret_cont next_cont val val_type,
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Expression_Ek env ret_cont next_cont)
          val_type)
        val)

  (** TODO(dmitryas): Write descriptive comments. *)
  | Pass_Var_Declaration_Ek_Configuration_Wf :
    forall var var_type env next_cont init_type val,
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Var_Declaration_Ek var var_type env next_cont)
          init_type)
        val)

  (** Invoking a method on `null` always puts the abstract machine in a final
    state, so passing `null` to MethodInvocationEK is always well-formed. *)
  | Pass_Method_Invocation_Ek_Null_Configuration_Wf :
    forall name arg_expr env ret_cont rcvr_type rcvr_val,
    runtime_type rcvr_val = None ->
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation
          (Method_Invocation_Ek name arg_expr env ret_cont)
          rcvr_type)
        rcvr_val)

  (** Getting a property of `null` always puts the abstract machine in a final
    state, so passing `null` to propertyGetEK is always well-formed. *)
  | Pass_Property_Get_Ek_Null_Configuration_Wf :
    forall name ret_cont rcvr_type rcvr_val,
    runtime_type rcvr_val = None ->
    configuration_wf
      (Value_Passing_Configuration
        (Expression_Continuation (Property_Get_Ek name ret_cont) rcvr_type)
        rcvr_val).


Inductive configuration_final : configuration -> Prop :=

  | Configuration_Final :
    forall val ret_type,
    configuration_final
      (Value_Passing_Configuration
        (Expression_Continuation Halt_Ek ret_type)
        val).


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


Inductive dart_type_valid : option dart_type -> Prop :=

  | DTV_Null :
    dart_type_valid None

  | DTV_Non_Null :
    forall class_id type,
    ref_in_dart_type class_id type ->
    NatMap.In class_id CE ->
    dart_type_valid (Some type).


Inductive runtime_value_valid (val : runtime_value) : Prop :=

  | RTV_Not_Null :
    forall intf type,
    (runtime_type val) = Some type ->
    dart_type_valid (Some type) ->
    value_of_type val intf (runtime_type val) ->
    runtime_value_valid val

  | RTV_Null :
    value_of_type val (mk_interface nil nil) None ->
    runtime_value_valid val.


(** [expression_wf] is a well-formedness condition for expression w.r.t. the
  class and member environments.  It requires that all class and member
  references in the expression are present in [CE] and [ME] respectively. *)
Inductive expression_wf : expression -> Prop :=

  | EXPWF_Variable_Get :
    forall var_get_expr,
    expression_wf (E_Variable_Get var_get_expr)

  | EXPWF_Property_Get :
    forall rcvr_expr name,
    expression_wf rcvr_expr ->
    expression_wf (E_Property_Get (Property_Get rcvr_expr name))

  | EXPWF_Method_Invocation :
    (* TODO(dmitryas): Remove [ref] when the corresponding element is removed
      from the AST. *)
    forall rcvr_expr name arg_expr ref,
    expression_wf rcvr_expr ->
    expression_wf arg_expr ->
    expression_wf (E_Invocation_Expression (IE_Method_Invocation
      (Method_Invocation rcvr_expr name (Arguments arg_expr) ref)))

  | EXPWF_Constructor_Invocation :
    forall ref,
    NatMap.In ref CE ->
    expression_wf (E_Invocation_Expression (IE_Constructor_Invocation
      (Constructor_Invocation ref))).


(** [statement_wf] is a property that is analogous to [expression_wf], but is
  defined for statements. *)
Inductive statement_wf : statement -> Prop :=

  | STWF_Expression_Statement :
    forall expr,
    expression_wf expr ->
    statement_wf (S_Expression_Statement (Expression_Statement expr))

  | STWF_Block_Empty :
    statement_wf (S_Block (Block nil))

  | STWF_Block_Non_Empty :
    forall stmt stmts,
    statement_wf stmt ->
    statement_wf (S_Block (Block stmts)) ->
    statement_wf (S_Block (Block (stmt :: stmts)))

  | STWF_Return_Statement :
    forall expr,
    expression_wf expr ->
    statement_wf (S_Return_Statement (Return_Statement expr))

  | STWF_Variable_Declaration_Non_Init :
    forall var_id type,
    (forall class_id,
      ref_in_dart_type class_id type -> NatMap.In class_id CE) ->
    statement_wf (S_Variable_Declaration
      (Variable_Declaration var_id type None))

  | STWF_Variable_Declaration_Init :
    forall var_id type init_expr,
    dart_type_valid (Some type) ->
    expression_wf init_expr ->
    statement_wf (S_Variable_Declaration
      (Variable_Declaration var_id type (Some init_expr))).


(** [environment_valid] is a property of environment validity with respect
  to the class and method environments.  For each variable in the environment
  there should be a valid interface, so that [value_of_type] predicate for the
  variable is true. *)
Inductive environment_valid : environment -> Prop :=

  | EV_Empty :
    environment_valid nil

  | EV_Non_Empty_Null :
    forall entry env,
    dart_type_valid (Some (var_type entry)) ->
    (runtime_type (value entry)) = None ->
    environment_valid env ->
    environment_valid (entry :: env)

  | EV_Non_Empty_Non_Null :
    forall entry env,
    dart_type_valid (Some (var_type entry)) ->
    (runtime_type (value entry)) = Some (var_type entry) ->
    environment_valid env ->
    environment_valid (entry :: env).


(** The given syntactic type is accepted by the given expression continuation.

  None is accepted as the second argument, because runtime type of values can
  be checkec agains the expression continuation. *)
Inductive econt_accepts :
    expression_continuation -> option dart_type -> Prop :=

  | EA_Null :
    forall econt,
    econt_accepts econt None

  | EA_Non_Null :
    forall cont expected_type type,
    type <: expected_type ->
    econt_accepts
      (Expression_Continuation cont expected_type)
      (Some type).


(** The syntactic type of the expression matches the syntactic type of the
  value expected by the expression continuation. *)
Inductive econt_accepts_expr :
    expression_continuation -> expression -> environment -> Prop :=

  | Econt_Accepts_Expr :
    forall econt expr env expr_type,
    expression_type CE (env_to_type_env env) expr = Some expr_type ->
    econt_accepts econt (Some expr_type) ->
    econt_accepts_expr econt expr env.


(** The syntactic type returned by the statement (if any) matches the syntactic
  type of the value expected by the expression continuation. *)
Inductive econt_accepts_stmt :
    expression_continuation -> statement -> environment -> Prop :=

  | Econt_Accepts_Stmt :
    forall econt stmt env ret_type te,
    statement_type CE (env_to_type_env env) stmt ret_type = Some te ->
    econt_accepts econt (Some ret_type) ->
    econt_accepts_stmt econt stmt env.


(** The syntactic type of the value matches the syntactic type of the value
  expected by the expression continuation. *)
Definition econt_accepts_val :
    expression_continuation -> runtime_value -> Prop :=
  fun econt val => econt_accepts econt (runtime_type val).


(** Each free variable referenced from the expression is present in the
  environment. *)
Inductive eval_environment_sufficient : environment -> expression -> Prop :=

  | EES_Variable_Get :
    forall var env,
    env_in var env ->
    eval_environment_sufficient env (E_Variable_Get (Variable_Get var))

  | EES_Property_Get :
    forall expr name env,
    eval_environment_sufficient env expr ->
    eval_environment_sufficient env (E_Property_Get (Property_Get expr name))

  | EES_Constructor_Invocation :
    forall class_id env,
    eval_environment_sufficient
      env
      (E_Invocation_Expression
        (IE_Constructor_Invocation
          (Constructor_Invocation class_id)))

  | EES_Method_Invocation :
    (* TODO(dmitryas): Remove ref when it's removed from the AST. *)
    forall rcvr_expr arg_expr name ref env,
    eval_environment_sufficient env rcvr_expr ->
    eval_environment_sufficient env arg_expr ->
    eval_environment_sufficient
      env
      (E_Invocation_Expression
        (IE_Method_Invocation
          (Method_Invocation rcvr_expr name (Arguments arg_expr) ref))).


(** [exec_environment_sufficient] represents the property of the environment
  w.r.t. the given statement.  The property shows if the given environment is
  sufficient to evaluate all expressions in the given statement. *)
Inductive exec_environment_sufficient : environment -> statement -> Prop :=

  | EES_Expression_Statement :
    forall env expr,
    eval_environment_sufficient env expr ->
    exec_environment_sufficient
      env
      (S_Expression_Statement (Expression_Statement expr))

  | EES_Block_Empty :
    forall env,
    exec_environment_sufficient env (S_Block (Block nil))

  | EES_Block_Non_Empty :
    forall env stmt stmts,
    exec_environment_sufficient env stmt ->
    exec_environment_sufficient env (S_Block (Block stmts)) ->
    exec_environment_sufficient env (S_Block (Block (stmt :: stmts)))

  | EES_Return_Statement :
    forall env expr,
    eval_environment_sufficient env expr ->
    exec_environment_sufficient
      env
      (S_Return_Statement (Return_Statement expr))

  | EES_Variable_Declaration_Non_Init :
    forall env var type,
    exec_environment_sufficient
      env
      (S_Variable_Declaration (Variable_Declaration var type None))

  | EES_Variable_Declaration_Init :
    forall env var type init_expr,
    eval_environment_sufficient env init_expr ->
    exec_environment_sufficient
      env
      (S_Variable_Declaration
        (Variable_Declaration var type (Some init_expr))).


(** Validity property for expression continuations [econt_valid] and statement
  continuations [scont_valid] is mutually inductive, because instances of one
  may refer to instances of the other. *)
Inductive econt_valid : expression_continuation -> Prop :=

  | CV_Expression_Ek :
    forall expr_type env ret_cont next_cont,
    environment_valid env ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    dart_type_valid (Some expr_type) ->
    econt_valid
      (Expression_Continuation
        (Expression_Ek env ret_cont next_cont)
        expr_type)

  | CV_Method_Invocation_Ek :
    forall rcvr_type name arg_exp arg_type ret_type env ret_cont,
    environment_valid env ->
    dart_type_valid (Some rcvr_type) ->
    method_accepts (Some rcvr_type) name (Some arg_type) ->
    method_returns (Some rcvr_type) name ret_type ->
    expression_wf arg_exp ->
    eval_environment_sufficient env arg_exp ->
    expression_type CE (env_to_type_env env) arg_exp = Some arg_type ->
    dart_type_valid (Some arg_type) ->
    econt_valid ret_cont ->
    dart_type_valid (Some ret_type) ->
    econt_accepts ret_cont (Some ret_type) ->
    econt_valid
      (Expression_Continuation
        (Method_Invocation_Ek name arg_exp env ret_cont)
        rcvr_type)

  | CV_Invocation_Ek :
    forall rcvr_val name env ret_cont arg_type ret_type,
    environment_valid env ->
    runtime_value_valid rcvr_val ->
    method_accepts (runtime_type rcvr_val) name (Some arg_type) ->
    method_returns (runtime_type rcvr_val) name ret_type ->
    dart_type_valid (Some arg_type) ->
    econt_valid ret_cont ->
    dart_type_valid (Some ret_type) ->
    econt_accepts ret_cont (Some ret_type) ->
    econt_valid
      (Expression_Continuation
        (Invocation_Ek rcvr_val name env ret_cont)
        arg_type)

  | CV_Property_Get_Ek :
    forall name ret_cont rcvr_type ret_type,
    dart_type_valid (Some rcvr_type) ->
    getter_returns (Some rcvr_type) name ret_type ->
    econt_valid ret_cont ->
    dart_type_valid (Some ret_type) ->
    econt_accepts ret_cont (Some ret_type) ->
    econt_valid
      (Expression_Continuation
        (Property_Get_Ek name ret_cont)
        rcvr_type)

  | CV_Var_Declaration_Ek :
    forall var var_type env next_cont init_type,
    environment_valid env ->
    dart_type_valid (Some var_type) ->
    dart_type_valid (Some init_type) ->
    init_type <: var_type ->
    scont_valid next_cont ->
    econt_valid
      (Expression_Continuation
        (Var_Declaration_Ek var var_type env next_cont)
        init_type)

with scont_valid : statement_continuation -> Prop :=

  | CV_Exit_Sk :
    forall ret_cont val,
    econt_valid ret_cont ->
    runtime_value_valid val ->
    econt_accepts_val ret_cont val ->
    scont_valid (Exit_Sk ret_cont val)

  | CV_Block_Sk_Empty :
    forall env ret_cont next_cont,
    environment_valid env ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    scont_valid (Block_Sk nil env ret_cont next_cont)

  | CV_Block_Sk_Expression_Statement :
    forall stmt expr expr_type stmts env ret_cont next_cont,
    environment_valid env ->
    stmt = S_Expression_Statement (Expression_Statement expr) ->
    statement_wf stmt ->
    expression_type CE (env_to_type_env env) expr = Some expr_type ->
    scont_valid (Block_Sk stmts env ret_cont next_cont) ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    scont_valid (Block_Sk (stmt :: stmts) env ret_cont next_cont)

  | CV_Block_Sk_Block :
    forall stmt block_stmts stmts env ret_cont next_cont,
    environment_valid env ->
    stmt = S_Block (Block block_stmts) ->
    statement_wf stmt ->
    scont_valid (Block_Sk stmts env ret_cont next_cont) ->
    scont_valid
      (Block_Sk block_stmts env ret_cont
        (Block_Sk stmts env ret_cont next_cont)) ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    scont_valid (Block_Sk (stmt :: stmts) env ret_cont next_cont)

  | CV_Block_Sk_Return_Statement :
    forall stmt expr expr_type stmts env ret_cont next_cont,
    environment_valid env ->
    stmt = S_Return_Statement (Return_Statement expr) ->
    statement_wf stmt ->
    expression_type CE (env_to_type_env env) expr = Some expr_type ->
    dart_type_valid (Some expr_type) ->
    econt_valid ret_cont ->
    econt_accepts ret_cont (Some expr_type) ->
    (* TODO(dmitryas): Do we really need the validity of the dead code? *)
    scont_valid (Block_Sk stmts env ret_cont next_cont) ->
    scont_valid next_cont ->
    scont_valid (Block_Sk (stmt :: stmts) env ret_cont next_cont)

  | CV_Block_Sk_Variable_Declaration_Init :
    forall stmt var var_type init_expr init_expr_type
        stmts env env' ret_cont next_cont,
    environment_valid env ->
    stmt = S_Variable_Declaration
      (Variable_Declaration var var_type (Some init_expr)) ->
    statement_wf stmt ->
    expression_type CE (env_to_type_env env) init_expr = Some init_expr_type ->
    init_expr_type <: var_type ->
    env' = env_extend var var_type (mk_runtime_value (Some var_type)) env ->
    scont_valid (Block_Sk stmts env' ret_cont next_cont) ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    scont_valid (Block_Sk (stmt :: stmts) env ret_cont next_cont)

  | CV_Block_Sk_Variable_Declaration_Non_Init :
    forall stmt var var_type stmts env env' ret_cont next_cont,
    environment_valid env ->
    stmt = S_Variable_Declaration
      (Variable_Declaration var var_type None) ->
    statement_wf stmt ->
    env' = env_extend var var_type (mk_runtime_value None) env ->
    scont_valid (Block_Sk stmts env' ret_cont next_cont) ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    scont_valid (Block_Sk (stmt :: stmts) env ret_cont next_cont).


Inductive configuration_valid : configuration -> Prop :=

  | Eval_Configuration_Valid :
    forall exp env cont,
    expression_wf exp ->
    environment_valid env ->
    econt_valid cont ->
    eval_environment_sufficient env exp ->
    econt_accepts_expr cont exp env ->
    configuration_valid (Eval_Configuration exp env cont)

  | Exec_Configuration_Valid :
    forall stmt env ret_cont next_cont,
    statement_wf stmt ->
    environment_valid env ->
    econt_valid ret_cont ->
    scont_valid next_cont ->
    exec_environment_sufficient env stmt ->
    econt_accepts_stmt ret_cont stmt env ->
    configuration_valid (Exec_Configuration stmt env ret_cont next_cont)

  | Value_Passing_Configuration_Valid :
    forall cont val,
    econt_valid cont ->
    runtime_value_valid val ->
    econt_accepts_val cont val ->
    configuration_valid (Value_Passing_Configuration cont val)

  | Forward_Configuration_Valid :
    forall cont env,
    scont_valid cont ->
    environment_valid env ->
    configuration_valid (Forward_Configuration cont env).


Inductive steps : configuration -> configuration -> Prop :=

  | steps_zero :
    forall conf,
    steps conf conf

  | steps_trans_right :
    forall conf1 conf2 conf3,
    steps conf1 conf2 ->
    step conf2 conf3 ->
    steps conf1 conf3.


End OperationalSemantics.
