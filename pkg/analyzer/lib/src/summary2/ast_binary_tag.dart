// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AliasedElementTag {
  static const int nothing = 0;
  static const int genericFunctionElement = 1;
}

enum AstNodeTag {
  AdjacentStrings,
  Annotation,
  ArgumentList,
  AsExpression,
  AssertInitializer,
  AssignmentExpression,
  AwaitExpression,
  BinaryOperatorInvocation,
  BooleanLiteral,
  CascadeExpression,
  CascadeIndexAssignmentTarget,
  CascadeIndexExpression,
  CascadePropertyAssignmentTarget,
  CascadePropertyExtraction,
  CascadeSection,
  CompoundAssignment,
  ConditionalExpression,
  ConstructorFieldInitializer,
  ConstructorInvocation,
  ConstructorReference2,
  ConstructorSelector,
  ConstructorTearOff,
  ConstructorTypeReference,
  DeclaredIdentifier,
  DelimitedFormalParameters,
  DirectAssignment,
  DotShorthandConstructorInvocation,
  DotShorthandInvocation,
  DotShorthandPropertyAccess,
  DottedName,
  DoubleLiteral,
  ExtensionOverride,
  FieldFormalParameter,
  ForEachPartsWithDeclaration,
  ForElement,
  ForPartsWithDeclarations,
  ForPartsWithExpression,
  FormalParameterList,
  CallInvocation,
  FunctionReference,
  GenericFunctionType,
  IfElement,
  IfNull,
  IfNullAssignment,
  ImplicitCallReference,
  ImportPrefixReference,
  ReceiverIndexAssignmentTarget,
  IndexExpression,
  ReceiverIndexExpression,
  IntegerLiteralNegative,
  IntegerLiteralNegative1,
  IntegerLiteralNull,
  IntegerLiteralPositive,
  IntegerLiteralPositive1,
  InterpolationExpression,
  InterpolationString,
  InvalidExpressionAssignmentTarget,
  IsExpression,
  ListLiteral,
  LogicalAnd,
  LogicalNot,
  LogicalOr,
  MapLiteralEntry,
  MethodInvocation,
  NamedArgument,
  NamedType,
  NullAssertionExpression,
  NullAwareElement,
  NullLiteral,
  ParenthesizedExpression,
  PostfixDecrement,
  PostfixIncrement,
  PrefixDecrement,
  PrefixIncrement,
  PrefixedIdentifier,
  PropertyAccess,
  ReceiverPropertyAssignmentTarget,
  ReceiverPropertyExtraction,
  RecordLiteral,
  RecordLiteralNamedField,
  RecordTypeAnnotation,
  RecordTypeAnnotationNamedField,
  RecordTypeAnnotationNamedFields,
  RecordTypeAnnotationPositionalField,
  RedirectingConstructorInvocation,
  RegularFormalParameter,
  SetOrMapLiteral,
  SimpleIdentifier,
  SimpleStringLiteral,
  SpreadElement,
  StringInterpolation,
  SuperConstructorInvocation,
  SuperExpression,
  SuperFormalParameter,
  SymbolLiteral,
  ThisExpression,
  ThrowExpression,
  TypeArgumentList,
  TypeLiteral,
  TypeParameter,
  TypeParameterList,
  UnaryOperatorInvocation,
  UnqualifiedNameAssignmentTarget,
  VariableDeclaration,
  VariableDeclarationList,
  CascadeMethodInvocation,
  UnqualifiedFunctionInvocation,
  ImportPrefixedFunctionInvocation,
  ReceiverMethodInvocation,
}

enum DirectiveUriKind {
  withLibrary,
  withUnit,
  withSource,
  withRelativeUri,
  withRelativeUriString,
  withNothing,
}

enum ElementTag {
  null_,
  dynamic_,
  never_,
  multiplyDefined,
  memberWithTypeArguments,
  elementImpl,
  libraryImportPrefix,
  typeParameter,
  formalParameter,
}

enum FormalParameterKindTag {
  requiredPositional,
  optionalPositional,
  requiredNamed,
  optionalNamed,
}

enum ImportElementPrefixKind { isDeferred, isNotDeferred, isNull }

enum IndexReadResolutionTag { dynamic_, invalid, method }

enum IndexWriteResolutionTag { dynamic_, invalid, method }

enum InvocationResolutionTag {
  dynamic_,
  executable,
  functionCall,
  functionInterface,
  functionType,
  invalid,
}

enum NamedReadResolutionTag {
  getterInvocation,
  invalid,
  variableRead,
  dynamicPropertyRead,
  executableTearOff,
  recordFieldRead,
  functionCallTearOff,
  functionInterfaceCallTearOff,
}

enum NamedWriteResolutionTag {
  invalid,
  setterInvocation,
  variableWrite,
  dynamicPropertyWrite,
}

enum NamespaceCombinatorTag { hide, show }

enum TypeParameterVarianceTag {
  legacy,
  unrelated,
  covariant,
  contravariant,
  invariant,
}

enum TypeTag {
  NullType,
  DynamicType,
  FunctionType,
  InvalidType,
  NeverType,
  InterfaceType,
  InterfaceType_noTypeArguments_none,
  InterfaceType_noTypeArguments_question,
  RecordType,
  TypeParameterType,
  VoidType,
}
