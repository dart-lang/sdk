Require Import Common.

Inductive named_node_data : Set :=
  | Named_Node : 
      nat (* reference *)
      -> named_node_data

with named_node : Set :=
  | NN_Library : library -> named_node
  | NN_Class : class -> named_node
  | NN_Member : member -> named_node


with reference : Set :=
  | Reference : 
      named_node (* node *)
      -> reference

with library : Set :=
  | Library : 
      named_node_data
      -> string (* name *)
      -> library_dependency_list (* dependencies *)
      -> reference_list (* additionalExports *)
      -> class_list (* classes *)
      -> procedure_list (* procedures *)
      -> field_list (* fields *)
      -> library

with library_dependency : Set :=
  | Library_Dependency : 
      nat (* importedLibraryReference *)
      -> string (* name *)
      -> combinator_list (* combinators *)
      -> library_dependency

with combinator : Set :=
  | Combinator : 
      bool (* isShow *)
      -> list string (* names *)
      -> combinator

with class : Set :=
  | Class : 
      named_node_data
      -> string (* name *)
      -> bool (* isAbstract *)
      -> type_parameter_list (* typeParameters *)
      -> supertype_option (* supertype *)
      -> supertype_option (* mixedInType *)
      -> supertype_list (* implementedTypes *)
      -> field_list (* fields *)
      -> constructor_list (* constructors *)
      -> procedure_list (* procedures *)
      -> interface_type (* _rawType *)
      -> interface_type (* _thisType *)
      -> interface_type (* _bottomType *)
      -> class

with member_data : Set :=
  | Member : 
      named_node_data
      -> name (* name *)
      -> member_data

with member : Set :=
  | M_Field : field -> member
  | M_Constructor : constructor -> member
  | M_Procedure : procedure -> member


with field : Set :=
  | Field : 
      member_data
      -> named_node_data
      -> dart_type (* type *)
      -> expression_option (* initializer *)
      -> field

with constructor : Set :=
  | Constructor : 
      member_data
      -> named_node_data
      -> function_node (* function *)
      -> initializer_list (* initializers *)
      -> constructor

with procedure : Set :=
  | Procedure : 
      member_data
      -> named_node_data
      -> procedure_kind (* kind *)
      -> function_node (* function *)
      -> procedure

with procedure_kind : Set := Method | Getter | Setter | Operator | Factory

with initializer : Set :=
  | I_Field_Initializer : field_initializer -> initializer
  | I_Super_Initializer : super_initializer -> initializer
  | I_Redirecting_Initializer : redirecting_initializer -> initializer
  | I_Local_Initializer : local_initializer -> initializer


with field_initializer : Set :=
  | Field_Initializer : 
      nat (* fieldReference *)
      -> expression (* value *)
      -> field_initializer

with super_initializer : Set :=
  | Super_Initializer : 
      nat (* targetReference *)
      -> arguments (* arguments *)
      -> super_initializer

with redirecting_initializer : Set :=
  | Redirecting_Initializer : 
      nat (* targetReference *)
      -> arguments (* arguments *)
      -> redirecting_initializer

with local_initializer : Set :=
  | Local_Initializer : 
      nat (* variable *)
      -> local_initializer

with function_node : Set :=
  | Function_Node : 
      async_marker (* asyncMarker *)
      -> type_parameter_list (* typeParameters *)
      -> nat (* requiredParameterCount *)
      -> variable_declaration_list (* positionalParameters *)
      -> variable_declaration_list (* namedParameters *)
      -> dart_type (* returnType *)
      -> statement (* body *)
      -> function_node

with async_marker : Set := Sync | Sync_Star | Async | Async_Star | Sync_Yielding

with expression : Set :=
  | E_Variable_Get : variable_get -> expression
  | E_Variable_Set : variable_set -> expression
  | E_Property_Get : property_get -> expression
  | E_Property_Set : property_set -> expression
  | E_Direct_Property_Get : direct_property_get -> expression
  | E_Direct_Property_Set : direct_property_set -> expression
  | E_Super_Property_Get : super_property_get -> expression
  | E_Super_Property_Set : super_property_set -> expression
  | E_Static_Get : static_get -> expression
  | E_Static_Set : static_set -> expression
  | E_Invocation_Expression : invocation_expression -> expression
  | E_Not : not -> expression
  | E_Logical_Expression : logical_expression -> expression
  | E_Conditional_Expression : conditional_expression -> expression
  | E_Is_Expression : is_expression -> expression
  | E_As_Expression : as_expression -> expression
  | E_Basic_Literal : basic_literal -> expression
  | E_Type_Literal : type_literal -> expression
  | E_This_Expression : this_expression -> expression
  | E_Rethrow : rethrow -> expression
  | E_Throw : throw -> expression
  | E_Function_Expression : function_expression -> expression
  | E_Let : dart_let -> expression
  | E_Vector_Creation : vector_creation -> expression
  | E_Vector_Get : vector_get -> expression
  | E_Vector_Set : vector_set -> expression
  | E_Vector_Copy : vector_copy -> expression
  | E_Closure_Creation : closure_creation -> expression


with variable_get : Set :=
  | Variable_Get : 
      nat (* variable *)
      -> dart_type_option (* promotedType *)
      -> variable_get

with variable_set : Set :=
  | Variable_Set : 
      nat (* variable *)
      -> expression (* value *)
      -> variable_set

with property_get : Set :=
  | Property_Get : 
      expression (* receiver *)
      -> name (* name *)
      -> property_get

with property_set : Set :=
  | Property_Set : 
      expression (* receiver *)
      -> name (* name *)
      -> expression (* value *)
      -> property_set

with direct_property_get : Set :=
  | Direct_Property_Get : 
      expression (* receiver *)
      -> nat (* targetReference *)
      -> direct_property_get

with direct_property_set : Set :=
  | Direct_Property_Set : 
      expression (* receiver *)
      -> nat (* targetReference *)
      -> expression (* value *)
      -> direct_property_set

with direct_method_invocation : Set :=
  | Direct_Method_Invocation : 
      expression (* receiver *)
      -> nat (* targetReference *)
      -> arguments (* arguments *)
      -> direct_method_invocation

with super_property_get : Set :=
  | Super_Property_Get : 
      name (* name *)
      -> super_property_get

with super_property_set : Set :=
  | Super_Property_Set : 
      name (* name *)
      -> expression (* value *)
      -> super_property_set

with static_get : Set :=
  | Static_Get : 
      nat (* targetReference *)
      -> static_get

with static_set : Set :=
  | Static_Set : 
      nat (* targetReference *)
      -> expression (* value *)
      -> static_set

with arguments : Set :=
  | Arguments : 
      dart_type_list (* types *)
      -> expression_list (* positional *)
      -> named_expression_list (* named *)
      -> arguments

with named_expression : Set :=
  | Named_Expression : 
      string (* name *)
      -> expression (* value *)
      -> named_expression

with invocation_expression : Set :=
  | IE_Direct_Method_Invocation : direct_method_invocation -> invocation_expression
  | IE_Method_Invocation : method_invocation -> invocation_expression
  | IE_Super_Method_Invocation : super_method_invocation -> invocation_expression
  | IE_Static_Invocation : static_invocation -> invocation_expression
  | IE_Constructor_Invocation : constructor_invocation -> invocation_expression


with method_invocation : Set :=
  | Method_Invocation : 
      expression (* receiver *)
      -> name (* name *)
      -> arguments (* arguments *)
      -> method_invocation

with super_method_invocation : Set :=
  | Super_Method_Invocation : 
      name (* name *)
      -> arguments (* arguments *)
      -> super_method_invocation

with static_invocation : Set :=
  | Static_Invocation : 
      nat (* targetReference *)
      -> arguments (* arguments *)
      -> bool (* isConst *)
      -> static_invocation

with constructor_invocation : Set :=
  | Constructor_Invocation : 
      nat (* targetReference *)
      -> arguments (* arguments *)
      -> bool (* isConst *)
      -> constructor_invocation

with not : Set :=
  | Not : 
      expression (* operand *)
      -> not

with logical_expression : Set :=
  | Logical_Expression : 
      expression (* left *)
      -> string (* operator *)
      -> expression (* right *)
      -> logical_expression

with conditional_expression : Set :=
  | Conditional_Expression : 
      expression (* condition *)
      -> expression (* then *)
      -> expression (* otherwise *)
      -> dart_type (* staticType *)
      -> conditional_expression

with is_expression : Set :=
  | Is_Expression : 
      expression (* operand *)
      -> dart_type (* type *)
      -> is_expression

with as_expression : Set :=
  | As_Expression : 
      expression (* operand *)
      -> dart_type (* type *)
      -> as_expression

with basic_literal : Set :=
  | BL_Bool_Literal : bool_literal -> basic_literal
  | BL_Null_Literal : null_literal -> basic_literal


with bool_literal : Set :=
  | Bool_Literal : 
      bool (* value *)
      -> bool_literal

with null_literal : Set :=
  | Null_Literal : 
      null_literal

with type_literal : Set :=
  | Type_Literal : 
      dart_type (* type *)
      -> type_literal

with this_expression : Set :=
  | This_Expression : 
      this_expression

with rethrow : Set :=
  | Rethrow : 
      rethrow

with throw : Set :=
  | Throw : 
      expression (* expression *)
      -> throw

with function_expression : Set :=
  | Function_Expression : 
      function_node (* function *)
      -> function_expression

with dart_let : Set :=
  | Let : 
      nat (* variable *)
      -> expression (* body *)
      -> dart_let

with vector_creation : Set :=
  | Vector_Creation : 
      nat (* length *)
      -> vector_creation

with vector_get : Set :=
  | Vector_Get : 
      expression (* vectorExpression *)
      -> nat (* index *)
      -> vector_get

with vector_set : Set :=
  | Vector_Set : 
      expression (* vectorExpression *)
      -> nat (* index *)
      -> expression (* value *)
      -> vector_set

with vector_copy : Set :=
  | Vector_Copy : 
      expression (* vectorExpression *)
      -> vector_copy

with closure_creation : Set :=
  | Closure_Creation : 
      nat (* topLevelFunctionReference *)
      -> expression (* contextVector *)
      -> function_type (* functionType *)
      -> dart_type_list (* typeArguments *)
      -> closure_creation

with statement : Set :=
  | S_Expression_Statement : expression_statement -> statement
  | S_Block : block -> statement
  | S_Empty_Statement : empty_statement -> statement
  | S_Labeled_Statement : labeled_statement -> statement
  | S_Break_Statement : break_statement -> statement
  | S_While_Statement : while_statement -> statement
  | S_Do_Statement : do_statement -> statement
  | S_For_Statement : for_statement -> statement
  | S_If_Statement : if_statement -> statement
  | S_Return_Statement : return_statement -> statement
  | S_Try_Catch : try_catch -> statement
  | S_Try_Finally : try_finally -> statement
  | S_Variable_Declaration : variable_declaration -> statement
  | S_Function_Declaration : function_declaration -> statement


with expression_statement : Set :=
  | Expression_Statement : 
      expression (* expression *)
      -> expression_statement

with block : Set :=
  | Block : 
      statement_list (* statements *)
      -> block

with empty_statement : Set :=
  | Empty_Statement : 
      empty_statement

with labeled_statement : Set :=
  | Labeled_Statement : 
      statement (* body *)
      -> labeled_statement

with break_statement : Set :=
  | Break_Statement : 
      nat (* target *)
      -> break_statement

with while_statement : Set :=
  | While_Statement : 
      expression (* condition *)
      -> statement (* body *)
      -> while_statement

with do_statement : Set :=
  | Do_Statement : 
      statement (* body *)
      -> expression (* condition *)
      -> do_statement

with for_statement : Set :=
  | For_Statement : 
      variable_declaration_list (* variables *)
      -> expression (* condition *)
      -> expression_list (* updates *)
      -> statement (* body *)
      -> for_statement

with if_statement : Set :=
  | If_Statement : 
      expression (* condition *)
      -> statement (* then *)
      -> statement (* otherwise *)
      -> if_statement

with return_statement : Set :=
  | Return_Statement : 
      expression (* expression *)
      -> return_statement

with try_catch : Set :=
  | Try_Catch : 
      statement (* body *)
      -> catch_list (* catches *)
      -> try_catch

with catch : Set :=
  | Catch : 
      dart_type (* guard *)
      -> nat (* exception *)
      -> statement (* body *)
      -> catch

with try_finally : Set :=
  | Try_Finally : 
      statement (* body *)
      -> statement (* finalizer *)
      -> try_finally

with variable_declaration : Set :=
  | Variable_Declaration : 
      string (* name *)
      -> dart_type (* type *)
      -> expression_option (* initializer *)
      -> variable_declaration

with function_declaration : Set :=
  | Function_Declaration : 
      nat (* variable *)
      -> function_node (* function *)
      -> function_declaration

with name_data : Set :=
  | Name : 
      string (* name *)
      -> name_data

with name : Set :=
  | N__Private_Name : _private_name -> name
  | N__Public_Name : _public_name -> name


with _private_name : Set :=
  | _Private_Name : 
      name_data
      -> nat (* libraryName *)
      -> _private_name

with _public_name : Set :=
  | _Public_Name : 
      name_data
      -> _public_name

with dart_type : Set :=
  | DT_Dynamic_Type : dynamic_type -> dart_type
  | DT_Void_Type : void_type -> dart_type
  | DT_Bottom_Type : bottom_type -> dart_type
  | DT_Interface_Type : interface_type -> dart_type
  | DT_Vector_Type : vector_type -> dart_type
  | DT_Function_Type : function_type -> dart_type
  | DT_Type_Parameter_Type : type_parameter_type -> dart_type


with dynamic_type : Set :=
  | Dynamic_Type : 
      dynamic_type

with void_type : Set :=
  | Void_Type : 
      void_type

with bottom_type : Set :=
  | Bottom_Type : 
      bottom_type

with interface_type : Set :=
  | Interface_Type : 
      nat (* className *)
      -> dart_type_list (* typeArguments *)
      -> interface_type

with vector_type : Set :=
  | Vector_Type : 
      vector_type

with function_type : Set :=
  | Function_Type : 
      type_parameter_list (* typeParameters *)
      -> dart_type_list (* positionalParameters *)
      -> named_type_list (* namedParameters *)
      -> dart_type (* returnType *)
      -> function_type

with named_type : Set :=
  | Named_Type : 
      string (* name *)
      -> dart_type (* type *)
      -> named_type

with type_parameter_type : Set :=
  | Type_Parameter_Type : 
      nat (* parameter *)
      -> dart_type_option (* promotedBound *)
      -> type_parameter_type

with type_parameter : Set :=
  | Type_Parameter : 
      string (* name *)
      -> dart_type (* bound *)
      -> type_parameter

with supertype : Set :=
  | Supertype : 
      nat (* className *)
      -> dart_type_list (* typeArguments *)
      -> supertype

with program : Set :=
  | Program : 
      library_list (* libraries *)
      -> nat (* mainMethodName *)
      -> program

with reference_list : Set :=
  | reference_nil : reference_list
  | reference_cons : nat -> reference_list -> reference_list

with library_list : Set :=
  | library_nil : library_list
  | library_cons : library -> library_list -> library_list

with library_dependency_list : Set :=
  | library_dependency_nil : library_dependency_list
  | library_dependency_cons : library_dependency -> library_dependency_list -> library_dependency_list

with combinator_list : Set :=
  | combinator_nil : combinator_list
  | combinator_cons : combinator -> combinator_list -> combinator_list

with class_list : Set :=
  | class_nil : class_list
  | class_cons : class -> class_list -> class_list

with field_list : Set :=
  | field_nil : field_list
  | field_cons : field -> field_list -> field_list

with constructor_list : Set :=
  | constructor_nil : constructor_list
  | constructor_cons : constructor -> constructor_list -> constructor_list

with procedure_list : Set :=
  | procedure_nil : procedure_list
  | procedure_cons : procedure -> procedure_list -> procedure_list

with procedure_kind_list : Set :=
  | procedure_kind_nil : procedure_kind_list
  | procedure_kind_cons : procedure_kind -> procedure_kind_list -> procedure_kind_list

with initializer_list : Set :=
  | initializer_nil : initializer_list
  | initializer_cons : initializer -> initializer_list -> initializer_list

with async_marker_list : Set :=
  | async_marker_nil : async_marker_list
  | async_marker_cons : async_marker -> async_marker_list -> async_marker_list

with expression_list : Set :=
  | expression_nil : expression_list
  | expression_cons : expression -> expression_list -> expression_list

with expression_option : Set :=
  | expression_none : expression_option
  | expression_some : expression -> expression_option

with named_expression_list : Set :=
  | named_expression_nil : named_expression_list
  | named_expression_cons : named_expression -> named_expression_list -> named_expression_list

with statement_list : Set :=
  | statement_nil : statement_list
  | statement_cons : statement -> statement_list -> statement_list

with catch_list : Set :=
  | catch_nil : catch_list
  | catch_cons : catch -> catch_list -> catch_list

with variable_declaration_list : Set :=
  | variable_declaration_nil : variable_declaration_list
  | variable_declaration_cons : nat -> variable_declaration_list -> variable_declaration_list

with dart_type_list : Set :=
  | dart_type_nil : dart_type_list
  | dart_type_cons : dart_type -> dart_type_list -> dart_type_list

with dart_type_option : Set :=
  | dart_type_none : dart_type_option
  | dart_type_some : dart_type -> dart_type_option

with named_type_list : Set :=
  | named_type_nil : named_type_list
  | named_type_cons : named_type -> named_type_list -> named_type_list

with type_parameter_list : Set :=
  | type_parameter_nil : type_parameter_list
  | type_parameter_cons : nat -> type_parameter_list -> type_parameter_list

with supertype_list : Set :=
  | supertype_nil : supertype_list
  | supertype_cons : supertype -> supertype_list -> supertype_list

with supertype_option : Set :=
  | supertype_none : supertype_option
  | supertype_some : supertype -> supertype_option

.

Record ast_store : Type := Ast_Store {
  r_refs : NatMap.t reference;
  ls_refs : NatMap.t labeled_statement;
  vd_refs : NatMap.t variable_declaration;
  tp_refs : NatMap.t type_parameter;
}.

Module SyntacticValidity.
Fixpoint named_node_validity (ast : ast_store) (T : named_node) {struct T} : Prop :=
  match T with
    | NN_Library ST => library_validity ast ST
    | NN_Class ST => class_validity ast ST
    | NN_Member ST => member_validity ast ST
end
with named_node_data_validity (ast : ast_store) (T : named_node_data) {struct T}: Prop :=
  match T with
    | Named_Node f0 =>
        NatMap.In f0 (r_refs ast)
  end
with reference_validity (ast : ast_store) (T : reference) {struct T} : Prop :=
  match T with
    | Reference f0 =>
        named_node_validity ast f0
  end
with library_validity (ast : ast_store) (T : library) {struct T} : Prop :=
  match T with
    | Library f0 _ f1 f2 f3 f4 f5 =>
        named_node_data_validity ast f0 /\
        library_dependency_list_validity ast f1 /\
        reference_list_validity ast f2 /\
        class_list_validity ast f3 /\
        procedure_list_validity ast f4 /\
        field_list_validity ast f5
  end
with library_dependency_validity (ast : ast_store) (T : library_dependency) {struct T} : Prop :=
  match T with
    | Library_Dependency f0 _ f1 =>
        NatMap.In f0 (r_refs ast) /\
        combinator_list_validity ast f1
  end
with combinator_validity (ast : ast_store) (T : combinator) {struct T} : Prop :=
  match T with
    | Combinator _ _ =>
        True
  end
with class_validity (ast : ast_store) (T : class) {struct T} : Prop :=
  match T with
    | Class f0 _ _ f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 =>
        named_node_data_validity ast f0 /\
        type_parameter_list_validity ast f1 /\
        supertype_option_validity ast f2 /\
        supertype_option_validity ast f3 /\
        supertype_list_validity ast f4 /\
        field_list_validity ast f5 /\
        constructor_list_validity ast f6 /\
        procedure_list_validity ast f7 /\
        interface_type_validity ast f8 /\
        interface_type_validity ast f9 /\
        interface_type_validity ast f10
  end
with member_validity (ast : ast_store) (T : member) {struct T} : Prop :=
  match T with
    | M_Field ST => field_validity ast ST
    | M_Constructor ST => constructor_validity ast ST
    | M_Procedure ST => procedure_validity ast ST
end
with member_data_validity (ast : ast_store) (T : member_data) {struct T}: Prop :=
  match T with
    | Member f0 f1 =>
        named_node_data_validity ast f0 /\
        name_validity ast f1
  end
with field_validity (ast : ast_store) (T : field) {struct T} : Prop :=
  match T with
    | Field f0 f1 f2 f3 =>
        member_data_validity ast f0 /\
        named_node_data_validity ast f1 /\
        dart_type_validity ast f2 /\
        expression_option_validity ast f3
  end
with constructor_validity (ast : ast_store) (T : constructor) {struct T} : Prop :=
  match T with
    | Constructor f0 f1 f2 f3 =>
        member_data_validity ast f0 /\
        named_node_data_validity ast f1 /\
        function_node_validity ast f2 /\
        initializer_list_validity ast f3
  end
with procedure_validity (ast : ast_store) (T : procedure) {struct T} : Prop :=
  match T with
    | Procedure f0 f1 f2 f3 =>
        member_data_validity ast f0 /\
        named_node_data_validity ast f1 /\
        procedure_kind_validity ast f2 /\
        function_node_validity ast f3
  end
with procedure_kind_validity (ast : ast_store) (T : procedure_kind) {struct T} : Prop := True
with initializer_validity (ast : ast_store) (T : initializer) {struct T} : Prop :=
  match T with
    | I_Field_Initializer ST => field_initializer_validity ast ST
    | I_Super_Initializer ST => super_initializer_validity ast ST
    | I_Redirecting_Initializer ST => redirecting_initializer_validity ast ST
    | I_Local_Initializer ST => local_initializer_validity ast ST
end
with field_initializer_validity (ast : ast_store) (T : field_initializer) {struct T} : Prop :=
  match T with
    | Field_Initializer f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        expression_validity ast f1
  end
with super_initializer_validity (ast : ast_store) (T : super_initializer) {struct T} : Prop :=
  match T with
    | Super_Initializer f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        arguments_validity ast f1
  end
with redirecting_initializer_validity (ast : ast_store) (T : redirecting_initializer) {struct T} : Prop :=
  match T with
    | Redirecting_Initializer f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        arguments_validity ast f1
  end
with local_initializer_validity (ast : ast_store) (T : local_initializer) {struct T} : Prop :=
  match T with
    | Local_Initializer f0 =>
        NatMap.In f0 (vd_refs ast)
  end
with function_node_validity (ast : ast_store) (T : function_node) {struct T} : Prop :=
  match T with
    | Function_Node f0 f1 _ f2 f3 f4 f5 =>
        async_marker_validity ast f0 /\
        type_parameter_list_validity ast f1 /\
        variable_declaration_list_validity ast f2 /\
        variable_declaration_list_validity ast f3 /\
        dart_type_validity ast f4 /\
        statement_validity ast f5
  end
with async_marker_validity (ast : ast_store) (T : async_marker) {struct T} : Prop := True
with expression_validity (ast : ast_store) (T : expression) {struct T} : Prop :=
  match T with
    | E_Variable_Get ST => variable_get_validity ast ST
    | E_Variable_Set ST => variable_set_validity ast ST
    | E_Property_Get ST => property_get_validity ast ST
    | E_Property_Set ST => property_set_validity ast ST
    | E_Direct_Property_Get ST => direct_property_get_validity ast ST
    | E_Direct_Property_Set ST => direct_property_set_validity ast ST
    | E_Super_Property_Get ST => super_property_get_validity ast ST
    | E_Super_Property_Set ST => super_property_set_validity ast ST
    | E_Static_Get ST => static_get_validity ast ST
    | E_Static_Set ST => static_set_validity ast ST
    | E_Invocation_Expression ST => invocation_expression_validity ast ST
    | E_Not ST => not_validity ast ST
    | E_Logical_Expression ST => logical_expression_validity ast ST
    | E_Conditional_Expression ST => conditional_expression_validity ast ST
    | E_Is_Expression ST => is_expression_validity ast ST
    | E_As_Expression ST => as_expression_validity ast ST
    | E_Basic_Literal ST => basic_literal_validity ast ST
    | E_Type_Literal ST => type_literal_validity ast ST
    | E_This_Expression ST => this_expression_validity ast ST
    | E_Rethrow ST => rethrow_validity ast ST
    | E_Throw ST => throw_validity ast ST
    | E_Function_Expression ST => function_expression_validity ast ST
    | E_Let ST => dart_let_validity ast ST
    | E_Vector_Creation ST => vector_creation_validity ast ST
    | E_Vector_Get ST => vector_get_validity ast ST
    | E_Vector_Set ST => vector_set_validity ast ST
    | E_Vector_Copy ST => vector_copy_validity ast ST
    | E_Closure_Creation ST => closure_creation_validity ast ST
end
with variable_get_validity (ast : ast_store) (T : variable_get) {struct T} : Prop :=
  match T with
    | Variable_Get f0 f1 =>
        NatMap.In f0 (vd_refs ast) /\
        dart_type_option_validity ast f1
  end
with variable_set_validity (ast : ast_store) (T : variable_set) {struct T} : Prop :=
  match T with
    | Variable_Set f0 f1 =>
        NatMap.In f0 (vd_refs ast) /\
        expression_validity ast f1
  end
with property_get_validity (ast : ast_store) (T : property_get) {struct T} : Prop :=
  match T with
    | Property_Get f0 f1 =>
        expression_validity ast f0 /\
        name_validity ast f1
  end
with property_set_validity (ast : ast_store) (T : property_set) {struct T} : Prop :=
  match T with
    | Property_Set f0 f1 f2 =>
        expression_validity ast f0 /\
        name_validity ast f1 /\
        expression_validity ast f2
  end
with direct_property_get_validity (ast : ast_store) (T : direct_property_get) {struct T} : Prop :=
  match T with
    | Direct_Property_Get f0 f1 =>
        expression_validity ast f0 /\
        NatMap.In f1 (r_refs ast)
  end
with direct_property_set_validity (ast : ast_store) (T : direct_property_set) {struct T} : Prop :=
  match T with
    | Direct_Property_Set f0 f1 f2 =>
        expression_validity ast f0 /\
        NatMap.In f1 (r_refs ast) /\
        expression_validity ast f2
  end
with direct_method_invocation_validity (ast : ast_store) (T : direct_method_invocation) {struct T} : Prop :=
  match T with
    | Direct_Method_Invocation f0 f1 f2 =>
        expression_validity ast f0 /\
        NatMap.In f1 (r_refs ast) /\
        arguments_validity ast f2
  end
with super_property_get_validity (ast : ast_store) (T : super_property_get) {struct T} : Prop :=
  match T with
    | Super_Property_Get f0 =>
        name_validity ast f0
  end
with super_property_set_validity (ast : ast_store) (T : super_property_set) {struct T} : Prop :=
  match T with
    | Super_Property_Set f0 f1 =>
        name_validity ast f0 /\
        expression_validity ast f1
  end
with static_get_validity (ast : ast_store) (T : static_get) {struct T} : Prop :=
  match T with
    | Static_Get f0 =>
        NatMap.In f0 (r_refs ast)
  end
with static_set_validity (ast : ast_store) (T : static_set) {struct T} : Prop :=
  match T with
    | Static_Set f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        expression_validity ast f1
  end
with arguments_validity (ast : ast_store) (T : arguments) {struct T} : Prop :=
  match T with
    | Arguments f0 f1 f2 =>
        dart_type_list_validity ast f0 /\
        expression_list_validity ast f1 /\
        named_expression_list_validity ast f2
  end
with named_expression_validity (ast : ast_store) (T : named_expression) {struct T} : Prop :=
  match T with
    | Named_Expression _ f0 =>
        expression_validity ast f0
  end
with invocation_expression_validity (ast : ast_store) (T : invocation_expression) {struct T} : Prop :=
  match T with
    | IE_Direct_Method_Invocation ST => direct_method_invocation_validity ast ST
    | IE_Method_Invocation ST => method_invocation_validity ast ST
    | IE_Super_Method_Invocation ST => super_method_invocation_validity ast ST
    | IE_Static_Invocation ST => static_invocation_validity ast ST
    | IE_Constructor_Invocation ST => constructor_invocation_validity ast ST
end
with method_invocation_validity (ast : ast_store) (T : method_invocation) {struct T} : Prop :=
  match T with
    | Method_Invocation f0 f1 f2 =>
        expression_validity ast f0 /\
        name_validity ast f1 /\
        arguments_validity ast f2
  end
with super_method_invocation_validity (ast : ast_store) (T : super_method_invocation) {struct T} : Prop :=
  match T with
    | Super_Method_Invocation f0 f1 =>
        name_validity ast f0 /\
        arguments_validity ast f1
  end
with static_invocation_validity (ast : ast_store) (T : static_invocation) {struct T} : Prop :=
  match T with
    | Static_Invocation f0 f1 _ =>
        NatMap.In f0 (r_refs ast) /\
        arguments_validity ast f1
  end
with constructor_invocation_validity (ast : ast_store) (T : constructor_invocation) {struct T} : Prop :=
  match T with
    | Constructor_Invocation f0 f1 _ =>
        NatMap.In f0 (r_refs ast) /\
        arguments_validity ast f1
  end
with not_validity (ast : ast_store) (T : not) {struct T} : Prop :=
  match T with
    | Not f0 =>
        expression_validity ast f0
  end
with logical_expression_validity (ast : ast_store) (T : logical_expression) {struct T} : Prop :=
  match T with
    | Logical_Expression f0 _ f1 =>
        expression_validity ast f0 /\
        expression_validity ast f1
  end
with conditional_expression_validity (ast : ast_store) (T : conditional_expression) {struct T} : Prop :=
  match T with
    | Conditional_Expression f0 f1 f2 f3 =>
        expression_validity ast f0 /\
        expression_validity ast f1 /\
        expression_validity ast f2 /\
        dart_type_validity ast f3
  end
with is_expression_validity (ast : ast_store) (T : is_expression) {struct T} : Prop :=
  match T with
    | Is_Expression f0 f1 =>
        expression_validity ast f0 /\
        dart_type_validity ast f1
  end
with as_expression_validity (ast : ast_store) (T : as_expression) {struct T} : Prop :=
  match T with
    | As_Expression f0 f1 =>
        expression_validity ast f0 /\
        dart_type_validity ast f1
  end
with basic_literal_validity (ast : ast_store) (T : basic_literal) {struct T} : Prop :=
  match T with
    | BL_Bool_Literal ST => bool_literal_validity ast ST
    | BL_Null_Literal ST => null_literal_validity ast ST
end
with bool_literal_validity (ast : ast_store) (T : bool_literal) {struct T} : Prop :=
  match T with
    | Bool_Literal _ =>
        True
  end
with null_literal_validity (ast : ast_store) (T : null_literal) {struct T} : Prop :=
  match T with
    | Null_Literal  =>
        True
  end
with type_literal_validity (ast : ast_store) (T : type_literal) {struct T} : Prop :=
  match T with
    | Type_Literal f0 =>
        dart_type_validity ast f0
  end
with this_expression_validity (ast : ast_store) (T : this_expression) {struct T} : Prop :=
  match T with
    | This_Expression  =>
        True
  end
with rethrow_validity (ast : ast_store) (T : rethrow) {struct T} : Prop :=
  match T with
    | Rethrow  =>
        True
  end
with throw_validity (ast : ast_store) (T : throw) {struct T} : Prop :=
  match T with
    | Throw f0 =>
        expression_validity ast f0
  end
with function_expression_validity (ast : ast_store) (T : function_expression) {struct T} : Prop :=
  match T with
    | Function_Expression f0 =>
        function_node_validity ast f0
  end
with dart_let_validity (ast : ast_store) (T : dart_let) {struct T} : Prop :=
  match T with
    | Let f0 f1 =>
        NatMap.In f0 (vd_refs ast) /\
        expression_validity ast f1
  end
with vector_creation_validity (ast : ast_store) (T : vector_creation) {struct T} : Prop :=
  match T with
    | Vector_Creation _ =>
        True
  end
with vector_get_validity (ast : ast_store) (T : vector_get) {struct T} : Prop :=
  match T with
    | Vector_Get f0 _ =>
        expression_validity ast f0
  end
with vector_set_validity (ast : ast_store) (T : vector_set) {struct T} : Prop :=
  match T with
    | Vector_Set f0 _ f1 =>
        expression_validity ast f0 /\
        expression_validity ast f1
  end
with vector_copy_validity (ast : ast_store) (T : vector_copy) {struct T} : Prop :=
  match T with
    | Vector_Copy f0 =>
        expression_validity ast f0
  end
with closure_creation_validity (ast : ast_store) (T : closure_creation) {struct T} : Prop :=
  match T with
    | Closure_Creation f0 f1 f2 f3 =>
        NatMap.In f0 (r_refs ast) /\
        expression_validity ast f1 /\
        function_type_validity ast f2 /\
        dart_type_list_validity ast f3
  end
with statement_validity (ast : ast_store) (T : statement) {struct T} : Prop :=
  match T with
    | S_Expression_Statement ST => expression_statement_validity ast ST
    | S_Block ST => block_validity ast ST
    | S_Empty_Statement ST => empty_statement_validity ast ST
    | S_Labeled_Statement ST => labeled_statement_validity ast ST
    | S_Break_Statement ST => break_statement_validity ast ST
    | S_While_Statement ST => while_statement_validity ast ST
    | S_Do_Statement ST => do_statement_validity ast ST
    | S_For_Statement ST => for_statement_validity ast ST
    | S_If_Statement ST => if_statement_validity ast ST
    | S_Return_Statement ST => return_statement_validity ast ST
    | S_Try_Catch ST => try_catch_validity ast ST
    | S_Try_Finally ST => try_finally_validity ast ST
    | S_Variable_Declaration ST => variable_declaration_validity ast ST
    | S_Function_Declaration ST => function_declaration_validity ast ST
end
with expression_statement_validity (ast : ast_store) (T : expression_statement) {struct T} : Prop :=
  match T with
    | Expression_Statement f0 =>
        expression_validity ast f0
  end
with block_validity (ast : ast_store) (T : block) {struct T} : Prop :=
  match T with
    | Block f0 =>
        statement_list_validity ast f0
  end
with empty_statement_validity (ast : ast_store) (T : empty_statement) {struct T} : Prop :=
  match T with
    | Empty_Statement  =>
        True
  end
with labeled_statement_validity (ast : ast_store) (T : labeled_statement) {struct T} : Prop :=
  match T with
    | Labeled_Statement f0 =>
        statement_validity ast f0
  end
with break_statement_validity (ast : ast_store) (T : break_statement) {struct T} : Prop :=
  match T with
    | Break_Statement f0 =>
        NatMap.In f0 (ls_refs ast)
  end
with while_statement_validity (ast : ast_store) (T : while_statement) {struct T} : Prop :=
  match T with
    | While_Statement f0 f1 =>
        expression_validity ast f0 /\
        statement_validity ast f1
  end
with do_statement_validity (ast : ast_store) (T : do_statement) {struct T} : Prop :=
  match T with
    | Do_Statement f0 f1 =>
        statement_validity ast f0 /\
        expression_validity ast f1
  end
with for_statement_validity (ast : ast_store) (T : for_statement) {struct T} : Prop :=
  match T with
    | For_Statement f0 f1 f2 f3 =>
        variable_declaration_list_validity ast f0 /\
        expression_validity ast f1 /\
        expression_list_validity ast f2 /\
        statement_validity ast f3
  end
with if_statement_validity (ast : ast_store) (T : if_statement) {struct T} : Prop :=
  match T with
    | If_Statement f0 f1 f2 =>
        expression_validity ast f0 /\
        statement_validity ast f1 /\
        statement_validity ast f2
  end
with return_statement_validity (ast : ast_store) (T : return_statement) {struct T} : Prop :=
  match T with
    | Return_Statement f0 =>
        expression_validity ast f0
  end
with try_catch_validity (ast : ast_store) (T : try_catch) {struct T} : Prop :=
  match T with
    | Try_Catch f0 f1 =>
        statement_validity ast f0 /\
        catch_list_validity ast f1
  end
with catch_validity (ast : ast_store) (T : catch) {struct T} : Prop :=
  match T with
    | Catch f0 f1 f2 =>
        dart_type_validity ast f0 /\
        NatMap.In f1 (vd_refs ast) /\
        statement_validity ast f2
  end
with try_finally_validity (ast : ast_store) (T : try_finally) {struct T} : Prop :=
  match T with
    | Try_Finally f0 f1 =>
        statement_validity ast f0 /\
        statement_validity ast f1
  end
with variable_declaration_validity (ast : ast_store) (T : variable_declaration) {struct T} : Prop :=
  match T with
    | Variable_Declaration _ f0 f1 =>
        dart_type_validity ast f0 /\
        expression_option_validity ast f1
  end
with function_declaration_validity (ast : ast_store) (T : function_declaration) {struct T} : Prop :=
  match T with
    | Function_Declaration f0 f1 =>
        NatMap.In f0 (vd_refs ast) /\
        function_node_validity ast f1
  end
with name_validity (ast : ast_store) (T : name) {struct T} : Prop :=
  match T with
    | N__Private_Name ST => _private_name_validity ast ST
    | N__Public_Name ST => _public_name_validity ast ST
end
with name_data_validity (ast : ast_store) (T : name_data) {struct T}: Prop :=
  match T with
    | Name _ =>
        True
  end
with _private_name_validity (ast : ast_store) (T : _private_name) {struct T} : Prop :=
  match T with
    | _Private_Name f0 f1 =>
        name_data_validity ast f0 /\
        NatMap.In f1 (r_refs ast)
  end
with _public_name_validity (ast : ast_store) (T : _public_name) {struct T} : Prop :=
  match T with
    | _Public_Name f0 =>
        name_data_validity ast f0
  end
with dart_type_validity (ast : ast_store) (T : dart_type) {struct T} : Prop :=
  match T with
    | DT_Dynamic_Type ST => dynamic_type_validity ast ST
    | DT_Void_Type ST => void_type_validity ast ST
    | DT_Bottom_Type ST => bottom_type_validity ast ST
    | DT_Interface_Type ST => interface_type_validity ast ST
    | DT_Vector_Type ST => vector_type_validity ast ST
    | DT_Function_Type ST => function_type_validity ast ST
    | DT_Type_Parameter_Type ST => type_parameter_type_validity ast ST
end
with dynamic_type_validity (ast : ast_store) (T : dynamic_type) {struct T} : Prop :=
  match T with
    | Dynamic_Type  =>
        True
  end
with void_type_validity (ast : ast_store) (T : void_type) {struct T} : Prop :=
  match T with
    | Void_Type  =>
        True
  end
with bottom_type_validity (ast : ast_store) (T : bottom_type) {struct T} : Prop :=
  match T with
    | Bottom_Type  =>
        True
  end
with interface_type_validity (ast : ast_store) (T : interface_type) {struct T} : Prop :=
  match T with
    | Interface_Type f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        dart_type_list_validity ast f1
  end
with vector_type_validity (ast : ast_store) (T : vector_type) {struct T} : Prop :=
  match T with
    | Vector_Type  =>
        True
  end
with function_type_validity (ast : ast_store) (T : function_type) {struct T} : Prop :=
  match T with
    | Function_Type f0 f1 f2 f3 =>
        type_parameter_list_validity ast f0 /\
        dart_type_list_validity ast f1 /\
        named_type_list_validity ast f2 /\
        dart_type_validity ast f3
  end
with named_type_validity (ast : ast_store) (T : named_type) {struct T} : Prop :=
  match T with
    | Named_Type _ f0 =>
        dart_type_validity ast f0
  end
with type_parameter_type_validity (ast : ast_store) (T : type_parameter_type) {struct T} : Prop :=
  match T with
    | Type_Parameter_Type f0 f1 =>
        NatMap.In f0 (tp_refs ast) /\
        dart_type_option_validity ast f1
  end
with type_parameter_validity (ast : ast_store) (T : type_parameter) {struct T} : Prop :=
  match T with
    | Type_Parameter _ f0 =>
        dart_type_validity ast f0
  end
with supertype_validity (ast : ast_store) (T : supertype) {struct T} : Prop :=
  match T with
    | Supertype f0 f1 =>
        NatMap.In f0 (r_refs ast) /\
        dart_type_list_validity ast f1
  end
with program_validity (ast : ast_store) (T : program) {struct T} : Prop :=
  match T with
    | Program f0 f1 =>
        library_list_validity ast f0 /\
        NatMap.In f1 (r_refs ast)
  end
with reference_list_validity (ast : ast_store) (L : reference_list) {struct L} : Prop :=
  match L with
    | reference_nil => True
    | reference_cons X XS => NatMap.In X (r_refs ast) /\ reference_list_validity ast XS
  end
with library_list_validity (ast : ast_store) (L : library_list) {struct L} : Prop :=
  match L with
    | library_nil => True
    | library_cons X XS => library_validity ast X /\ library_list_validity ast XS
  end
with library_dependency_list_validity (ast : ast_store) (L : library_dependency_list) {struct L} : Prop :=
  match L with
    | library_dependency_nil => True
    | library_dependency_cons X XS => library_dependency_validity ast X /\ library_dependency_list_validity ast XS
  end
with combinator_list_validity (ast : ast_store) (L : combinator_list) {struct L} : Prop :=
  match L with
    | combinator_nil => True
    | combinator_cons X XS => combinator_validity ast X /\ combinator_list_validity ast XS
  end
with class_list_validity (ast : ast_store) (L : class_list) {struct L} : Prop :=
  match L with
    | class_nil => True
    | class_cons X XS => class_validity ast X /\ class_list_validity ast XS
  end
with field_list_validity (ast : ast_store) (L : field_list) {struct L} : Prop :=
  match L with
    | field_nil => True
    | field_cons X XS => field_validity ast X /\ field_list_validity ast XS
  end
with constructor_list_validity (ast : ast_store) (L : constructor_list) {struct L} : Prop :=
  match L with
    | constructor_nil => True
    | constructor_cons X XS => constructor_validity ast X /\ constructor_list_validity ast XS
  end
with procedure_list_validity (ast : ast_store) (L : procedure_list) {struct L} : Prop :=
  match L with
    | procedure_nil => True
    | procedure_cons X XS => procedure_validity ast X /\ procedure_list_validity ast XS
  end
with procedure_kind_list_validity (ast : ast_store) (L : procedure_kind_list) {struct L} : Prop :=
  match L with
    | procedure_kind_nil => True
    | procedure_kind_cons X XS => procedure_kind_validity ast X /\ procedure_kind_list_validity ast XS
  end
with initializer_list_validity (ast : ast_store) (L : initializer_list) {struct L} : Prop :=
  match L with
    | initializer_nil => True
    | initializer_cons X XS => initializer_validity ast X /\ initializer_list_validity ast XS
  end
with async_marker_list_validity (ast : ast_store) (L : async_marker_list) {struct L} : Prop :=
  match L with
    | async_marker_nil => True
    | async_marker_cons X XS => async_marker_validity ast X /\ async_marker_list_validity ast XS
  end
with expression_list_validity (ast : ast_store) (L : expression_list) {struct L} : Prop :=
  match L with
    | expression_nil => True
    | expression_cons X XS => expression_validity ast X /\ expression_list_validity ast XS
  end
with expression_option_validity (ast : ast_store) (O : expression_option) {struct O} : Prop :=
  match O with
    | expression_none => True
    | expression_some X => expression_validity ast X
  end
with named_expression_list_validity (ast : ast_store) (L : named_expression_list) {struct L} : Prop :=
  match L with
    | named_expression_nil => True
    | named_expression_cons X XS => named_expression_validity ast X /\ named_expression_list_validity ast XS
  end
with statement_list_validity (ast : ast_store) (L : statement_list) {struct L} : Prop :=
  match L with
    | statement_nil => True
    | statement_cons X XS => statement_validity ast X /\ statement_list_validity ast XS
  end
with catch_list_validity (ast : ast_store) (L : catch_list) {struct L} : Prop :=
  match L with
    | catch_nil => True
    | catch_cons X XS => catch_validity ast X /\ catch_list_validity ast XS
  end
with variable_declaration_list_validity (ast : ast_store) (L : variable_declaration_list) {struct L} : Prop :=
  match L with
    | variable_declaration_nil => True
    | variable_declaration_cons X XS => NatMap.In X (vd_refs ast) /\ variable_declaration_list_validity ast XS
  end
with dart_type_list_validity (ast : ast_store) (L : dart_type_list) {struct L} : Prop :=
  match L with
    | dart_type_nil => True
    | dart_type_cons X XS => dart_type_validity ast X /\ dart_type_list_validity ast XS
  end
with dart_type_option_validity (ast : ast_store) (O : dart_type_option) {struct O} : Prop :=
  match O with
    | dart_type_none => True
    | dart_type_some X => dart_type_validity ast X
  end
with named_type_list_validity (ast : ast_store) (L : named_type_list) {struct L} : Prop :=
  match L with
    | named_type_nil => True
    | named_type_cons X XS => named_type_validity ast X /\ named_type_list_validity ast XS
  end
with type_parameter_list_validity (ast : ast_store) (L : type_parameter_list) {struct L} : Prop :=
  match L with
    | type_parameter_nil => True
    | type_parameter_cons X XS => NatMap.In X (tp_refs ast) /\ type_parameter_list_validity ast XS
  end
with supertype_list_validity (ast : ast_store) (L : supertype_list) {struct L} : Prop :=
  match L with
    | supertype_nil => True
    | supertype_cons X XS => supertype_validity ast X /\ supertype_list_validity ast XS
  end
with supertype_option_validity (ast : ast_store) (O : supertype_option) {struct O} : Prop :=
  match O with
    | supertype_none => True
    | supertype_some X => supertype_validity ast X
  end
.

Definition ast_store_validity (ast : ast_store) : Prop := 
  forall (n : nat), forall (X : reference), NatMap.MapsTo n X (r_refs ast) -> reference_validity ast X /\
  forall (n : nat), forall (X : labeled_statement), NatMap.MapsTo n X (ls_refs ast) -> labeled_statement_validity ast X /\
  forall (n : nat), forall (X : variable_declaration), NatMap.MapsTo n X (vd_refs ast) -> variable_declaration_validity ast X /\
  forall (n : nat), forall (X : type_parameter), NatMap.MapsTo n X (tp_refs ast) -> type_parameter_validity ast X
.
End SyntacticValidity.
