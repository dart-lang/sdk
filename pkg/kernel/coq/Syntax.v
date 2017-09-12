Require Import Common.

Inductive named_node_data : Set :=
  | Named_Node : 
      reference (* reference *)
      -> named_node_data

with named_node : Set :=
  | NN_Library : library -> named_node
  | NN_Class : class -> named_node
  | NN_Member : member -> named_node


with reference : Set :=
  | Reference : 
      nat
      -> reference

with library : Set :=
  | Library : 
      named_node_data
      -> list class (* classes *)
      -> list procedure (* procedures *)
      -> library

with class : Set :=
  | Class : 
      named_node_data
      -> string (* name *)
      -> list procedure (* procedures *)
      -> class

with member_data : Set :=
  | Member : 
      named_node_data
      -> list expression (* annotations *)
      -> name (* name *)
      -> member_data

with member : Set :=
  | M_Procedure : procedure -> member


with procedure : Set :=
  | Procedure : 
      member_data
      -> named_node_data
      -> function_node (* function *)
      -> procedure

with function_node : Set :=
  | Function_Node : 
      variable_declaration (* positionalParameters *)
      -> dart_type (* returnType *)
      -> statement (* body *)
      -> function_node

with expression : Set :=
  | E_Variable_Get : variable_get -> expression
  | E_Property_Get : property_get -> expression
  | E_Invocation_Expression : invocation_expression -> expression


with variable_get : Set :=
  | Variable_Get : 
      nat (* variable *)
      -> variable_get

with property_get : Set :=
  | Property_Get : 
      expression (* receiver *)
      -> name (* name *)
      -> property_get

with arguments : Set :=
  | Arguments : 
      expression (* positional *)
      -> arguments

with invocation_expression : Set :=
  | IE_Method_Invocation : method_invocation -> invocation_expression
  | IE_Constructor_Invocation : constructor_invocation -> invocation_expression


with method_invocation : Set :=
  | Method_Invocation : 
      expression (* receiver *)
      -> name (* name *)
      -> arguments (* arguments *)
      -> nat (* interfaceTargetReference *)
      -> method_invocation

with constructor_invocation : Set :=
  | Constructor_Invocation : 
      nat (* targetReference *)
      -> arguments (* arguments *)
      -> constructor_invocation

with statement : Set :=
  | S_Expression_Statement : expression_statement -> statement
  | S_Block : block -> statement
  | S_Return_Statement : return_statement -> statement
  | S_Variable_Declaration : variable_declaration -> statement


with expression_statement : Set :=
  | Expression_Statement : 
      expression (* expression *)
      -> expression_statement

with block : Set :=
  | Block : 
      list statement (* statements *)
      -> block

with return_statement : Set :=
  | Return_Statement : 
      expression (* expression *)
      -> return_statement

with variable_declaration : Set :=
  | Variable_Declaration : 
      nat
      -> dart_type (* type *)
      -> option expression (* initializer *)
      -> variable_declaration

with name : Set :=
  | Name : 
      string (* name *)
      -> name

with dart_type : Set :=
  | DT_Interface_Type : interface_type -> dart_type
  | DT_Function_Type : function_type -> dart_type


with interface_type : Set :=
  | Interface_Type : 
      nat (* className *)
      -> interface_type

with function_type : Set :=
  | Function_Type : 
      dart_type (* positionalParameters *)
      -> dart_type (* returnType *)
      -> function_type

.

