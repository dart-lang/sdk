Require Export SyntaxRaw.

Scheme dart_type_ind_mutual := Induction for dart_type Sort Prop
  with interface_type_ind_mutual := Induction for interface_type Sort Prop
  with function_type_ind_mutual := Induction for function_type Sort Prop.

Scheme expression_ind_mutual := Induction for expression Sort Prop
  with variable_get_ind_mutual := Induction for variable_get Sort Prop
  with property_get_ind_mutual := Induction for property_get Sort Prop
  with invocation_expression_ind_mutual := Induction for invocation_expression Sort Prop
  with method_invocation_ind_mutual := Induction for method_invocation Sort Prop
  with constructor_invocation_ind_mutual := Induction for constructor_invocation Sort Prop
  with arguments_ind_mutual := Induction for arguments Sort Prop.

Scheme statement_ind_mutual := Induction for statement Sort Prop
  with expression_statement_ind_mutual := Induction for expression_statement Sort Prop
  with block_ind_mutual := Induction for block Sort Prop
  with return_ind_mutual := Induction for return_statement Sort Prop
  with variable_declaration_ind_mutual := Induction for variable_declaration Sort Prop
.

Definition dart_type_induction prop :=
  dart_type_ind_mutual
    prop
    (fun i => prop (DT_Interface_Type i))
    (fun f => prop (DT_Function_Type f)).

Definition expr_induction prop :=
  expression_ind_mutual
    (fun e => prop e)
    (fun v => prop (E_Variable_Get v))
    (fun p => prop (E_Property_Get p))
    (fun ie => prop (E_Invocation_Expression ie))
    (fun mi => prop (E_Invocation_Expression (IE_Method_Invocation mi)))
    (fun ci => prop (E_Invocation_Expression (IE_Constructor_Invocation ci)))
    (fun args => let (param) := args in prop param).
