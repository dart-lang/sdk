Require Export SyntaxRaw.
Require Import Common.

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

(* Since blocks contain lists of statements, we can't just use Scheme to
   generate a good induction prinicple. *)
Section Statement_Mutual_Induction.
  Variable P : statement -> Prop.
  Hypothesis Return : forall r, P (S_Return_Statement r).
  Hypothesis VarDecl : forall vd, P (S_Variable_Declaration vd).
  Hypothesis Expr : forall e, P (S_Expression_Statement e).
  Hypothesis Blk : forall ss, Forall P ss -> P (S_Block (Block ss)).

  Fixpoint statement_induction s : P s :=
    match s with
    | S_Return_Statement r => Return r
    | S_Expression_Statement e => Expr e
    | S_Variable_Declaration vd => VarDecl vd
    | S_Block (Block ss) =>
      let ss_all := (fix rec (ss : list statement) : Forall P ss :=
                     match ss with
                     | nil => Forall_nil _
                     | (s::ss) => Forall_cons _ (statement_induction s) (rec ss)
                     end) ss in
      Blk ss ss_all
    end.
End Statement_Mutual_Induction.
