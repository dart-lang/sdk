// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// When debugging, these tags are written in resolution information to
/// mark positions where we expect resolution for specific kinds of nodes.
/// This might help us to be more confident that we are reading resolution
/// data that corresponds to AST, and find places where they start
/// diverging.
enum MarkerTag {
  AnnotatedNode_metadata,
  AnnotatedNode_end,
  Annotation_name,
  Annotation_constructorName,
  Annotation_arguments,
  Annotation_element,
  ArgumentList_arguments,
  ArgumentList_end,
  AsExpression_expression,
  AsExpression_type,
  AsExpression_expression2,
  AsExpression_end,
  Expression_staticType,
  AssertInitializer_condition,
  AssertInitializer_message,
  AssertInitializer_end,
  AssignmentExpression_leftHandSide,
  AssignmentExpression_rightHandSide,
  AssignmentExpression_staticElement,
  AssignmentExpression_readElement,
  AssignmentExpression_readType,
  AssignmentExpression_writeElement,
  AssignmentExpression_writeType,
  AssignmentExpression_expression,
  AssignmentExpression_end,
  BinaryExpression_leftOperand,
  BinaryExpression_rightOperand,
  BinaryExpression_staticElement,
  BinaryExpression_expression,
  BinaryExpression_end,
  CascadeExpression_target,
  CascadeExpression_cascadeSections,
  CascadeExpression_end,
  ClassDeclaration_typeParameters,
  ClassDeclaration_extendsClause,
  ClassDeclaration_withClause,
  ClassDeclaration_implementsClause,
  ClassDeclaration_nativeClause,
  ClassDeclaration_namedCompilationUnitMember,
  ClassDeclaration_end,
  ClassMember_declaration,
  ClassMember_end,
  ClassTypeAlias_typeParameters,
  ClassTypeAlias_superclass,
  ClassTypeAlias_withClause,
  ClassTypeAlias_implementsClause,
  ClassTypeAlias_typeAlias,
  ClassTypeAlias_end,
  ConditionalExpression_condition,
  ConditionalExpression_thenExpression,
  ConditionalExpression_elseExpression,
  Configuration_name,
  Configuration_value,
  Configuration_uri,
  Configuration_end,
  ConstructorDeclaration_returnType,
  ConstructorDeclaration_parameters,
  ConstructorDeclaration_initializers,
  ConstructorDeclaration_redirectedConstructor,
  ConstructorDeclaration_classMember,
  ConstructorDeclaration_end,
  ConstructorFieldInitializer_fieldName,
  ConstructorFieldInitializer_expression,
  ConstructorFieldInitializer_end,
  ConstructorName_type,
  ConstructorName_name,
  ConstructorName_staticElement,
  ConstructorName_end,
  DeclaredIdentifier_type,
  DeclaredIdentifier_identifier,
  DeclaredIdentifier_declaration,
  DeclaredIdentifier_end,
  DefaultFormalParameter_parameter,
  DefaultFormalParameter_defaultValue,
  DefaultFormalParameter_end,
  EnumConstantDeclaration_name,
  EnumConstantDeclaration_declaration,
  EnumConstantDeclaration_end,
  EnumDeclaration_constants,
  EnumDeclaration_namedCompilationUnitMember,
  EnumDeclaration_end,
  ExportDirective_namespaceDirective,
  ExportDirective_exportedLibrary,
  ExportDirective_end,
  ExtendsClause_superclass,
  ExtendsClause_end,
  ExtensionDeclaration_typeParameters,
  ExtensionDeclaration_extendedType,
  ExtensionDeclaration_compilationUnitMember,
  ExtensionDeclaration_end,
  ExtensionOverride_extensionName,
  ExtensionOverride_typeArguments,
  ExtensionOverride_argumentList,
  ExtensionOverride_extendedType,
  ExtensionOverride_end,
  FieldDeclaration_fields,
  FieldDeclaration_classMember,
  FieldDeclaration_end,
  FieldFormalParameter_typeParameters,
  FieldFormalParameter_type,
  FieldFormalParameter_parameters,
  FieldFormalParameter_normalFormalParameter,
  FieldFormalParameter_end,
  ForEachParts_iterable,
  ForEachParts_forLoopParts,
  ForEachParts_end,
  ForEachPartsWithDeclaration_loopVariable,
  ForEachPartsWithDeclaration_forEachParts,
  ForEachPartsWithDeclaration_end,
  ForElement_body,
  ForElement_forMixin,
  ForElement_end,
  FormalParameter_type,
  ForMixin_forLoopParts,
  ForParts_condition,
  ForParts_updaters,
  ForParts_forLoopParts,
  ForParts_end,
  FormalParameterList_parameters,
  FormalParameterList_end,
  ForPartsWithDeclarations_variables,
  ForPartsWithDeclarations_forParts,
  ForPartsWithDeclarations_end,
  FunctionDeclaration_functionExpression,
  FunctionDeclaration_returnType,
  FunctionDeclaration_namedCompilationUnitMember,
  FunctionDeclaration_returnTypeType,
  FunctionDeclaration_end,
  FunctionExpression_typeParameters,
  FunctionExpression_parameters,
  FunctionExpression_end,
  FunctionExpressionInvocation_function,
  FunctionExpressionInvocation_invocationExpression,
  FunctionExpressionInvocation_end,
  FunctionTypeAlias_typeParameters,
  FunctionTypeAlias_returnType,
  FunctionTypeAlias_parameters,
  FunctionTypeAlias_typeAlias,
  FunctionTypeAlias_returnTypeType,
  FunctionTypeAlias_flags,
  FunctionTypeAlias_end,
  FunctionTypedFormalParameter_typeParameters,
  FunctionTypedFormalParameter_returnType,
  FunctionTypedFormalParameter_parameters,
  FunctionTypedFormalParameter_normalFormalParameter,
  FunctionTypedFormalParameter_end,
  GenericFunctionType_typeParameters,
  GenericFunctionType_returnType,
  GenericFunctionType_parameters,
  GenericFunctionType_type,
  GenericFunctionType_end,
  GenericTypeAlias_typeParameters,
  GenericTypeAlias_type,
  GenericTypeAlias_typeAlias,
  GenericTypeAlias_flags,
  GenericTypeAlias_end,
  IfElement_condition,
  IfElement_thenElement,
  IfElement_elseElement,
  IfElement_end,
  ImplementsClause_interfaces,
  ImplementsClause_end,
  ImportDirective_namespaceDirective,
  ImportDirective_importedLibrary,
  ImportDirective_end,
  IndexExpression_target,
  IndexExpression_index,
  IndexExpression_staticElement,
  IndexExpression_expression,
  IndexExpression_end,
  InstanceCreationExpression_constructorName,
  InstanceCreationExpression_argumentList,
  InstanceCreationExpression_expression,
  InstanceCreationExpression_end,
  IsExpression_expression,
  IsExpression_type,
  IsExpression_expression2,
  IsExpression_end,
  InvocationExpression_typeArguments,
  InvocationExpression_argumentList,
  InvocationExpression_expression,
  InvocationExpression_end,
  ListLiteral_typeArguments,
  ListLiteral_elements,
  ListLiteral_expression,
  ListLiteral_end,
  MapLiteralEntry_key,
  MapLiteralEntry_value,
  MethodDeclaration_typeParameters,
  MethodDeclaration_returnType,
  MethodDeclaration_parameters,
  MethodDeclaration_classMember,
  MethodDeclaration_returnTypeType,
  MethodDeclaration_inferenceError,
  MethodDeclaration_flags,
  MethodDeclaration_end,
  MethodInvocation_target,
  MethodInvocation_methodName,
  MethodInvocation_invocationExpression,
  MethodInvocation_end,
  MixinDeclaration_typeParameters,
  MixinDeclaration_onClause,
  MixinDeclaration_implementsClause,
  MixinDeclaration_namedCompilationUnitMember,
  MixinDeclaration_end,
  NamedExpression_expression,
  NamedExpression_end,
  NamespaceDirective_combinators,
  NamespaceDirective_configurations,
  NamespaceDirective_uriBasedDirective,
  NamespaceDirective_end,
  NativeClause_name,
  NativeClause_end,
  NormalFormalParameter_metadata,
  NormalFormalParameter_formalParameter,
  NormalFormalParameter_end,
  OnClause_superclassConstraints,
  OnClause_end,
  ParenthesizedExpression_expression,
  ParenthesizedExpression_expression2,
  ParenthesizedExpression_end,
  PartOfDirective_libraryName,
  PartOfDirective_uri,
  PartOfDirective_directive,
  PartOfDirective_end,
  PostfixExpression_operand,
  PostfixExpression_staticElement,
  PostfixExpression_readElement,
  PostfixExpression_readType,
  PostfixExpression_writeElement,
  PostfixExpression_writeType,
  PostfixExpression_expression,
  PostfixExpression_end,
  PrefixedIdentifier_prefix,
  PrefixedIdentifier_identifier,
  PrefixedIdentifier_expression,
  PrefixedIdentifier_end,
  PrefixExpression_operand,
  PrefixExpression_staticElement,
  PrefixExpression_readElement,
  PrefixExpression_readType,
  PrefixExpression_writeElement,
  PrefixExpression_writeType,
  PrefixExpression_expression,
  PrefixExpression_end,
  PropertyAccess_target,
  PropertyAccess_propertyName,
  PropertyAccess_expression,
  PropertyAccess_end,
  RedirectingConstructorInvocation_constructorName,
  RedirectingConstructorInvocation_argumentList,
  RedirectingConstructorInvocation_staticElement,
  RedirectingConstructorInvocation_end,
  SetOrMapLiteral_flags,
  SetOrMapLiteral_typeArguments,
  SetOrMapLiteral_elements,
  SetOrMapLiteral_expression,
  SetOrMapLiteral_end,
  SimpleFormalParameter_type,
  SimpleFormalParameter_normalFormalParameter,
  SimpleFormalParameter_flags,
  SimpleFormalParameter_end,
  SimpleIdentifier_staticElement,
  SimpleIdentifier_expression,
  SimpleIdentifier_end,
  SpreadElement_expression,
  SpreadElement_end,
  StringInterpolation_elements,
  StringInterpolation_end,
  SuperConstructorInvocation_constructorName,
  SuperConstructorInvocation_argumentList,
  SuperConstructorInvocation_staticElement,
  SuperConstructorInvocation_end,
  SuperExpression_expression,
  SuperExpression_end,
  ThisExpression_expression,
  ThisExpression_end,
  ThrowExpression_expression,
  ThrowExpression_expression2,
  ThrowExpression_end,
  TopLevelVariableDeclaration_variables,
  TopLevelVariableDeclaration_compilationUnitMember,
  TopLevelVariableDeclaration_end,
  TypeArgumentList_arguments,
  TypeArgumentList_end,
  TypeName_name,
  TypeName_typeArguments,
  TypeName_type,
  TypeName_end,
  TypeParameter_bound,
  TypeParameter_declaration,
  TypeParameter_variance,
  TypeParameter_defaultType,
  TypeParameter_end,
  TypeParameterList_typeParameters,
  TypeParameterList_end,
  UriBasedDirective_uri,
  UriBasedDirective_directive,
  UriBasedDirective_end,
  VariableDeclaration_type,
  VariableDeclaration_inferenceError,
  VariableDeclaration_inheritsCovariant,
  VariableDeclaration_initializer,
  VariableDeclaration_end,
  VariableDeclarationList_type,
  VariableDeclarationList_variables,
  VariableDeclarationList_annotatedNode,
  VariableDeclarationList_end,
  WithClause_mixinTypes,
  WithClause_end,
}

/// A `MethodInvocation` in unresolved AST might be rewritten later as
/// another kinds of AST node. We store this rewrite with resolution data.
class MethodInvocationRewriteTag {
  static const int extensionOverride = 1;
  static const int functionExpressionInvocation = 2;
  static const int instanceCreationExpression_withName = 3;
  static const int instanceCreationExpression_withoutName = 4;
  static const int none = 5;
}

class Tag {
  static const int Nothing = 0;
  static const int Something = 1;

  static const int AdjacentStrings = 75;
  static const int Annotation = 2;
  static const int ArgumentList = 3;
  static const int AsExpression = 84;
  static const int AssertInitializer = 82;
  static const int AssignmentExpression = 96;
  static const int BinaryExpression = 52;
  static const int BooleanLiteral = 4;
  static const int CascadeExpression = 95;
  static const int Class = 5;
  static const int ClassTypeAlias = 44;
  static const int ConditionalExpression = 51;
  static const int Configuration = 46;
  static const int ConstructorDeclaration = 6;
  static const int ConstructorFieldInitializer = 50;
  static const int ConstructorName = 7;
  static const int DeclaredIdentifier = 90;
  static const int DefaultFormalParameter = 8;
  static const int DottedName = 47;
  static const int DoubleLiteral = 9;
  static const int EnumConstantDeclaration = 10;
  static const int EnumDeclaration = 11;
  static const int ExportDirective = 12;
  static const int ExtendsClause = 13;
  static const int ExtensionDeclaration = 14;
  static const int ExtensionOverride = 87;
  static const int FieldDeclaration = 15;
  static const int FieldFormalParameter = 16;
  static const int ForEachPartsWithDeclaration = 89;
  static const int ForElement = 88;
  static const int ForPartsWithDeclarations = 91;
  static const int FormalParameterList = 17;
  static const int FunctionDeclaration = 18;
  static const int FunctionDeclaration_getter = 57;
  static const int FunctionDeclaration_setter = 58;
  static const int FunctionExpression = 19;
  static const int FunctionExpressionInvocation = 93;
  static const int FunctionTypeAlias = 55;
  static const int FunctionTypedFormalParameter = 20;
  static const int GenericFunctionType = 21;
  static const int GenericTypeAlias = 22;
  static const int HideCombinator = 48;
  static const int IfElement = 63;
  static const int ImplementsClause = 23;
  static const int ImportDirective = 24;
  static const int IndexExpression = 98;
  static const int InstanceCreationExpression = 25;
  static const int IntegerLiteralNegative = 73;
  static const int IntegerLiteralNegative1 = 71;
  static const int IntegerLiteralNull = 97;
  static const int IntegerLiteralPositive = 72;
  static const int IntegerLiteralPositive1 = 26;
  static const int InterpolationExpression = 77;
  static const int InterpolationString = 78;
  static const int IsExpression = 83;
  static const int Label = 61;
  static const int LibraryDirective = 27;
  static const int LibraryIdentifier = 28;
  static const int ListLiteral = 56;
  static const int MapLiteralEntry = 66;
  static const int MethodDeclaration = 29;
  static const int MethodDeclaration_getter = 85;
  static const int MethodDeclaration_setter = 86;
  static const int MethodInvocation = 59;
  static const int MixinDeclaration = 67;
  static const int NamedExpression = 60;
  static const int NativeClause = 92;
  static const int OnClause = 68;
  static const int NullLiteral = 49;
  static const int ParenthesizedExpression = 53;
  static const int PartDirective = 30;
  static const int PartOfDirective = 31;
  static const int PostfixExpression = 94;
  static const int PrefixExpression = 79;
  static const int PrefixedIdentifier = 32;
  static const int PropertyAccess = 62;
  static const int RedirectingConstructorInvocation = 54;
  static const int SetOrMapLiteral = 65;
  static const int ShowCombinator = 33;
  static const int SimpleFormalParameter = 34;
  static const int SimpleIdentifier = 35;
  static const int SimpleStringLiteral = 36;
  static const int SpreadElement = 64;
  static const int StringInterpolation = 76;
  static const int SuperConstructorInvocation = 69;
  static const int SuperExpression = 80;
  static const int SymbolLiteral = 74;
  static const int ThisExpression = 70;
  static const int ThrowExpression = 81;
  static const int TopLevelVariableDeclaration = 37;
  static const int TypeArgumentList = 38;
  static const int TypeName = 39;
  static const int TypeParameter = 40;
  static const int TypeParameterList = 41;
  static const int VariableDeclaration = 42;
  static const int VariableDeclarationList = 43;
  static const int WithClause = 45;

  static const int RawElement = 0;
  static const int MemberLegacyWithoutTypeArguments = 1;
  static const int MemberLegacyWithTypeArguments = 2;
  static const int MemberWithTypeArguments = 3;

  static const int ParameterKindRequiredPositional = 1;
  static const int ParameterKindOptionalPositional = 2;
  static const int ParameterKindRequiredNamed = 3;
  static const int ParameterKindOptionalNamed = 4;

  static const int NullType = 2;
  static const int DynamicType = 3;
  static const int FunctionType = 4;
  static const int NeverType = 5;
  static const int InterfaceType = 6;
  static const int InterfaceType_noTypeArguments_none = 7;
  static const int InterfaceType_noTypeArguments_question = 8;
  static const int InterfaceType_noTypeArguments_star = 9;
  static const int TypeParameterType = 10;
  static const int VoidType = 11;
}
