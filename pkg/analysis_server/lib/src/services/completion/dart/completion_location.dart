// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The names of the locations at which completions can be requested.
///
/// These are the keys of the relevance tables in `relevance_tables.g.dart`.
/// They are shared by the completion passes that select a location and by
/// `tool/code_completion/relevance_table_generator.dart` that generates the
/// tables, so that the two can't get out of sync.
abstract final class CompletionLocation {
  static const String annotationName = 'Annotation_name';
  static const String asExpressionType = 'AsExpression_type';
  static const String assertInitializerCondition =
      'AssertInitializer_condition';
  static const String assertInitializerMessage = 'AssertInitializer_message';
  static const String assertStatementCondition = 'AssertStatement_condition';
  static const String assertStatementMessage = 'AssertStatement_message';
  // TODO(dantup): This is only used in the table generator.
  static const String assignedVariablePatternIdentifier =
      'AssignedVariablePattern_identifier';
  static const String assignmentExpressionRightHandSide =
      'AssignmentExpression_rightHandSide';
  static const String awaitExpressionExpression = 'AwaitExpression_expression';
  static const String blockStatement = 'Block_statement';
  // TODO(dantup): This is only used in the table generator.
  static const String blockFunctionBodyStart = 'BlockFunctionBody_start';
  // TODO(dantup): This is only used in the table generator.
  static const String booleanLiteralStart = 'BooleanLiteral_start';
  static const String cascadeExpressionCascadeSection =
      'CascadeExpression_cascadeSection';
  static const String caseClausePattern = 'CaseClause_pattern';
  static const String castPatternType = 'CastPattern_type';
  static const String catchClauseExceptionType = 'CatchClause_exceptionType';
  // TODO(dantup): This is only used in the table generator.
  static const String classDeclarationExtends = 'ClassDeclaration_extends';
  static const String classDeclarationMember = 'ClassDeclaration_member';
  // TODO(dantup): This is only used in the table generator.
  static const String classDeclarationName = 'ClassDeclaration_name';
  // TODO(dantup): This is only used in the table generator.
  static const String classDeclarationWith = 'ClassDeclaration_with';
  // TODO(dantup): This is only used in the table generator.
  static const String classTypeAliasSuperclass = 'ClassTypeAlias_superclass';
  // TODO(dantup): This is only used in the table generator.
  static const String classTypeAliasWith = 'ClassTypeAlias_with';
  static const String commentReferenceIdentifier =
      'CommentReference_identifier';
  static const String compilationUnitDeclaration =
      'CompilationUnit_declaration';
  static const String compilationUnitDirective = 'CompilationUnit_directive';
  static const String conditionalExpressionElseExpression =
      'ConditionalExpression_elseExpression';
  static const String conditionalExpressionThenExpression =
      'ConditionalExpression_thenExpression';
  // TODO(dantup): This is only used in the table generator.
  static const String constantPatternExpression = 'ConstantPattern_expression';
  static const String constructorDeclarationInitializer =
      'ConstructorDeclaration_initializer';
  // TODO(dantup): This is only used in the table generator.
  static const String constructorDeclarationReturnType =
      'ConstructorDeclaration_returnType';
  static const String constructorFieldInitializerExpression =
      'ConstructorFieldInitializer_expression';
  // This is only used in the completion code (no relevance data).
  static const String constructorSelectorName = 'ConstructorSelector_name';
  static const String declaredVariablePatternType =
      'DeclaredVariablePattern_type';
  static const String defaultFormalParameterDefaultValue =
      'DefaultFormalParameter_defaultValue';
  // TODO(dantup): This is only used in the table generator.
  static const String doStatementBody = 'DoStatement_body';
  static const String doStatementCondition = 'DoStatement_condition';
  // TODO(dantup): This is only used in the table generator.
  static const String dotShorthandConstructorInvocationConstructorName =
      'DotShorthandConstructorInvocation_constructorName';
  // TODO(dantup): This is only used in the table generator.
  static const String dotShorthandInvocationMemberName =
      'DotShorthandInvocation_memberName';
  // TODO(dantup): This is only used in the table generator.
  static const String dotShorthandPropertyAccessPropertyName =
      'DotShorthandPropertyAccess_propertyName';
  static const String enumDeclarationMember = 'EnumDeclaration_member';
  // TODO(dantup): This is only used in the table generator.
  static const String enumDeclarationName = 'EnumDeclaration_name';
  static const String expressionFunctionBodyExpression =
      'ExpressionFunctionBody_expression';
  // TODO(dantup): This is only used in the table generator.
  static const String expressionFunctionBodyStart =
      'ExpressionFunctionBody_start';
  static const String expressionStatementExpression =
      'ExpressionStatement_expression';
  static const String extendsClauseSuperclass = 'ExtendsClause_superclass';
  static const String extensionDeclarationMember =
      'ExtensionDeclaration_member';
  static const String extensionDeclarationOnClause =
      'ExtensionDeclaration_onClause';
  static const String extensionOnClauseExtendedType =
      'ExtensionOnClause_extendedType';
  static const String extensionTypeDeclarationMember =
      'ExtensionTypeDeclaration_member';
  static const String fieldDeclarationFields = 'FieldDeclaration_fields';
  static const String forEachPartsIterable = 'ForEachParts_iterable';
  // TODO(dantup): This is only used in the table generator.
  static const String forEachPartsWithDeclarationLoopVariable =
      'ForEachPartsWithDeclaration_loopVariable';
  // TODO(dantup): This is only used in the table generator.
  static const String forEachPartsWithIdentifierIdentifier =
      'ForEachPartsWithIdentifier_identifier';
  static const String forEachPartsWithPatternIterable =
      'ForEachPartsWithPattern_iterable';
  // TODO(dantup): This is only used in the table generator.
  static const String forEachPartsWithPatternPattern =
      'ForEachPartsWithPattern_pattern';
  static const String forElementBody = 'ForElement_body';
  // TODO(dantup): This is only used in the table generator.
  static const String forElementForLoopParts = 'ForElement_forLoopParts';
  static const String formalParameterListParameter =
      'FormalParameterList_parameter';
  static const String forPartsCondition = 'ForParts_condition';
  static const String forPartsUpdater = 'ForParts_updater';
  static const String forStatementBody = 'ForStatement_body';
  static const String forStatementForLoopParts = 'ForStatement_forLoopParts';
  static const String functionDeclarationReturnType =
      'FunctionDeclaration_returnType';
  static const String genericTypeAliasType = 'GenericTypeAlias_type';
  static const String hideCombinatorHiddenName = 'HideCombinator_hiddenName';
  static const String ifElementCondition = 'IfElement_condition';
  static const String ifElementElseElement = 'IfElement_elseElement';
  static const String ifElementThenElement = 'IfElement_thenElement';
  static const String ifStatementCondition = 'IfStatement_condition';
  static const String ifStatementElseStatement = 'IfStatement_elseStatement';
  static const String ifStatementThenStatement = 'IfStatement_thenStatement';
  static const String implementsClauseInterface = 'ImplementsClause_interface';
  // TODO(dantup): This is only used in the table generator.
  static const String importDirectiveCombinator = 'ImportDirective_combinator';
  // TODO(dantup): This is only used in the table generator.
  static const String importDirectiveConfigurations =
      'ImportDirective_configurations';
  // TODO(dantup): This is only used in the table generator.
  static const String importDirectiveDeferred = 'ImportDirective_deferred';
  // TODO(dantup): This is only used in the table generator.
  static const String importDirectivePrefix = 'ImportDirective_prefix';
  // TODO(dantup): This is only used in the table generator.
  static const String importDirectiveUri = 'ImportDirective_uri';
  static const String indexExpressionIndex = 'IndexExpression_index';
  static const String instanceCreationExpressionConstructorName =
      'InstanceCreationExpression_constructorName';
  static const String interpolationExpressionExpression =
      'InterpolationExpression_expression';
  static const String isExpressionType = 'IsExpression_type';
  // TODO(dantup): This is only used in the table generator.
  static const String labeledStatementStatement = 'LabeledStatement_statement';
  static const String listLiteralElement = 'ListLiteral_element';
  static const String listPatternElement = 'ListPattern_element';
  static const String logicalAndPatternRightOperand =
      'LogicalAndPattern_rightOperand';
  static const String logicalOrPatternRightOperand =
      'LogicalOrPattern_rightOperand';
  static const String mapLiteralEntryValue = 'MapLiteralEntry_value';
  static const String mapPatternEntryKey = 'MapPatternEntry_key';
  static const String mapPatternEntryValue = 'MapPatternEntry_value';
  // TODO(dantup): This is only used in the table generator.
  static const String methodDeclarationReturnType =
      'MethodDeclaration_returnType';
  static const String mixinDeclarationMember = 'MixinDeclaration_member';
  // TODO(dantup): This is only used in the table generator.
  static const String mixinDeclarationName = 'MixinDeclaration_name';
  // TODO(dantup): This is only used in the table generator.
  static const String mixinDeclarationOn = 'MixinDeclaration_on';
  static const String nullAwareElementValue = 'NullAwareElement_value';
  // This is only used in the completion code (no relevance data).
  static const String objectPatternFieldName = 'ObjectPattern_fieldName';
  static const String objectPatternType = 'ObjectPattern_type';
  // TODO(dantup): This is only used in the table generator.
  static const String onClauseSuperclassConstraint =
      'OnClause_superclassConstraint';
  static const String parenthesizedExpressionExpression =
      'ParenthesizedExpression_expression';
  static const String parenthesizedPatternPattern =
      'ParenthesizedPattern_pattern';
  static const String patternAssignmentExpression =
      'PatternAssignment_expression';
  static const String patternFieldPattern = 'PatternField_pattern';
  static const String patternVariableDeclarationExpression =
      'PatternVariableDeclaration_expression';
  // TODO(dantup): This is only used in the table generator.
  static const String patternVariableDeclarationPattern =
      'PatternVariableDeclaration_pattern';
  // This is only used in the completion code (no relevance data).
  static const String primaryConstructorDeclarationFieldName =
      'PrimaryConstructorDeclaration_fieldName';
  static const String primaryConstructorDeclarationFieldType =
      'PrimaryConstructorDeclaration_fieldType';
  static const String propertyAccessPropertyName =
      'PropertyAccess_propertyName';
  static const String recordLiteralFields = 'RecordLiteral_fields';
  static const String recordTypeAnnotationFields =
      'RecordTypeAnnotation_fields';
  // This is only used in the completion code (no relevance data).
  static const String recordTypeAnnotationNamedFieldName =
      'RecordTypeAnnotationNamedField_name';
  static const String restPatternElementPattern = 'RestPatternElement_pattern';
  static const String returnStatementExpression = 'ReturnStatement_expression';
  static const String setOrMapLiteralElement = 'SetOrMapLiteral_element';
  static const String showCombinatorShownName = 'ShowCombinator_shownName';
  // TODO(dantup): This is only used in the table generator.
  static const String simpleFormalParameterType = 'SimpleFormalParameter_type';
  static const String spreadElementExpression = 'SpreadElement_expression';
  // TODO(dantup): This is only used in the table generator.
  static const String switchCaseExpression = 'SwitchCase_expression';
  static const String switchExpressionPattern = 'SwitchExpression_pattern';
  static const String switchExpressionExpression =
      'SwitchExpression_expression';
  static const String switchExpressionCaseExpression =
      'SwitchExpressionCase_expression';
  static const String switchMemberStatement = 'SwitchMember_statement';
  static const String switchPatternCasePattern = 'SwitchPatternCase_pattern';
  static const String switchStatementExpression = 'SwitchStatement_expression';
  static const String throwExpressionExpression = 'ThrowExpression_expression';
  // TODO(dantup): This is only used in the table generator.
  static const String tryStatementCatch = 'TryStatement_catch';
  // TODO(dantup): This is only used in the table generator.
  static const String tryStatementTry = 'TryStatement_try';
  static const String typeArgumentListArgument = 'TypeArgumentList_argument';
  static const String typeParameterBound = 'TypeParameter_bound';
  static const String variableDeclarationInitializer =
      'VariableDeclaration_initializer';
  static const String variableDeclarationListType =
      'VariableDeclarationList_type';
  static const String whenClauseExpression = 'WhenClause_expression';
  // TODO(dantup): This is only used in the table generator.
  static const String whileStatementBody = 'WhileStatement_body';
  static const String whileStatementCondition = 'WhileStatement_condition';
  static const String wildcardPatternType = 'WildcardPattern_type';
  static const String withClauseMixinType = 'WithClause_mixinType';
  static const String yieldStatementExpression = 'YieldStatement_expression';

  /// Returns the location of an argument in an argument list.
  ///
  /// The [context] is the kind of node that contains the argument list.
  static String argumentList(String context, {required bool isNamed}) =>
      'ArgumentList_${context}_${isNamed ? 'named' : 'unnamed'}';

  /// Returns the location of the right operand of a binary expression whose
  /// operator is [operator].
  static String binaryExpressionRightOperand(String operator) =>
      'BinaryExpression_${operator}_rightOperand';

  /// Returns the location of the operand of a prefix expression whose operator
  /// is [operator].
  static String prefixExpressionOperand(String operator) =>
      'PrefixExpression_${operator}_operand';

  /// Returns the location of the operand of a relational pattern whose operator
  /// is [operator].
  static String relationalPatternOperatorOperand(String operator) =>
      'RelationalPattern_${operator}_operand';
}
