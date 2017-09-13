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
