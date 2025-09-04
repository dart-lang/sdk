// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/syntactic_errors.dart";

final fastaAnalyzerErrorCodes = <DiagnosticCode?>[
  null,
  ParserErrorCode.equalityCannotBeEqualityOperand,
  ParserErrorCode.continueOutsideOfLoop,
  ParserErrorCode.externalClass,
  ParserErrorCode.staticConstructor,
  ParserErrorCode.externalEnum,
  ParserErrorCode.prefixAfterCombinator,
  ParserErrorCode.typedefInClass,
  ParserErrorCode.expectedClassBody,
  ParserErrorCode.invalidAwaitInFor,
  ParserErrorCode.importDirectiveAfterPartDirective,
  ParserErrorCode.withBeforeExtends,
  ParserErrorCode.varReturnType,
  ParserErrorCode.typeArgumentsOnTypeVariable,
  ParserErrorCode.topLevelOperator,
  ParserErrorCode.switchHasMultipleDefaultCases,
  ParserErrorCode.switchHasCaseAfterDefaultCase,
  ParserErrorCode.staticOperator,
  ParserErrorCode.invalidOperatorQuestionmarkPeriodForSuper,
  ParserErrorCode.stackOverflow,
  ParserErrorCode.missingCatchOrFinally,
  ParserErrorCode.redirectionInNonFactoryConstructor,
  ParserErrorCode.redirectingConstructorWithBody,
  ParserErrorCode.nativeClauseShouldBeAnnotation,
  ParserErrorCode.multipleWithClauses,
  ParserErrorCode.multiplePartOfDirectives,
  ParserErrorCode.multipleOnClauses,
  ParserErrorCode.multipleLibraryDirectives,
  ParserErrorCode.multipleExtendsClauses,
  ParserErrorCode.missingStatement,
  ParserErrorCode.missingPrefixInDeferredImport,
  ParserErrorCode.missingKeywordOperator,
  ParserErrorCode.missingExpressionInThrow,
  ParserErrorCode.missingConstFinalVarOrType,
  ParserErrorCode.missingAssignmentInInitializer,
  ParserErrorCode.missingAssignableSelector,
  ParserErrorCode.missingInitializer,
  ParserErrorCode.libraryDirectiveNotFirst,
  ParserErrorCode.invalidUnicodeEscapeUStarted,
  ParserErrorCode.invalidOperator,
  ParserErrorCode.invalidHexEscape,
  ParserErrorCode.expectedInstead,
  ParserErrorCode.implementsBeforeWith,
  ParserErrorCode.implementsBeforeOn,
  ParserErrorCode.implementsBeforeExtends,
  ParserErrorCode.illegalAssignmentToNonAssignable,
  ParserErrorCode.expectedElseOrComma,
  ParserErrorCode.invalidSuperInInitializer,
  ParserErrorCode.experimentNotEnabled,
  ParserErrorCode.externalMethodWithBody,
  ParserErrorCode.abstractFinalInterfaceClass,
  ParserErrorCode.abstractClassMember,
  ParserErrorCode.breakOutsideOfLoop,
  ParserErrorCode.classInClass,
  ParserErrorCode.colonInPlaceOfIn,
  ParserErrorCode.constructorWithReturnType,
  ParserErrorCode.modifierOutOfOrder,
  ParserErrorCode.typeBeforeFactory,
  ParserErrorCode.constAndFinal,
  ParserErrorCode.conflictingModifiers,
  ParserErrorCode.constClass,
  ParserErrorCode.varAsTypeName,
  ParserErrorCode.constFactory,
  ParserErrorCode.constMethod,
  ParserErrorCode.continueWithoutLabelInCase,
  ParserErrorCode.invalidThisInInitializer,
  ParserErrorCode.covariantAndStatic,
  ParserErrorCode.covariantMember,
  ParserErrorCode.deferredAfterPrefix,
  ParserErrorCode.directiveAfterDeclaration,
  ParserErrorCode.duplicatedModifier,
  ParserErrorCode.duplicateDeferred,
  ParserErrorCode.duplicateLabelInSwitchStatement,
  ParserErrorCode.duplicatePrefix,
  ParserErrorCode.enumInClass,
  ParserErrorCode.exportDirectiveAfterPartDirective,
  ParserErrorCode.externalTypedef,
  ParserErrorCode.extraneousModifier,
  ParserErrorCode.factoryTopLevelDeclaration,
  ParserErrorCode.fieldInitializerOutsideConstructor,
  ParserErrorCode.finalAndCovariant,
  ParserErrorCode.finalAndVar,
  ParserErrorCode.initializedVariableInForEach,
  ParserErrorCode.catchSyntaxExtraParameters,
  ParserErrorCode.catchSyntax,
  ParserErrorCode.externalFactoryRedirection,
  ParserErrorCode.externalFactoryWithBody,
  ParserErrorCode.externalConstructorWithFieldInitializers,
  ParserErrorCode.fieldInitializedOutsideDeclaringClass,
  ParserErrorCode.varAndType,
  ParserErrorCode.invalidInitializer,
  ParserErrorCode.annotationWithTypeArguments,
  ParserErrorCode.extensionDeclaresConstructor,
  ParserErrorCode.extensionAugmentationHasOnClause,
  ParserErrorCode.extensionDeclaresAbstractMember,
  ParserErrorCode.mixinDeclaresConstructor,
  ParserErrorCode.nullAwareCascadeOutOfOrder,
  ParserErrorCode.multipleVarianceModifiers,
  ParserErrorCode.invalidUseOfCovariantInExtension,
  ParserErrorCode.typeParameterOnConstructor,
  ParserErrorCode.voidWithTypeArguments,
  ParserErrorCode.finalAndCovariantLateWithInitializer,
  ParserErrorCode.invalidConstructorName,
  ParserErrorCode.getterConstructor,
  ParserErrorCode.setterConstructor,
  ParserErrorCode.memberWithClassName,
  ParserErrorCode.externalConstructorWithInitializer,
  ParserErrorCode.abstractStaticField,
  ParserErrorCode.abstractLateField,
  ParserErrorCode.externalLateField,
  ParserErrorCode.abstractExternalField,
  ParserErrorCode.annotationOnTypeArgument,
  ParserErrorCode.binaryOperatorWrittenOut,
  ParserErrorCode.expectedIdentifierButGotKeyword,
  ParserErrorCode.annotationWithTypeArgumentsUninstantiated,
  ParserErrorCode.literalWithClassAndNew,
  ParserErrorCode.literalWithClass,
  ParserErrorCode.literalWithNew,
  ParserErrorCode.constructorWithTypeArguments,
  ParserErrorCode.functionTypedParameterVar,
  ParserErrorCode.typeParameterOnOperator,
  ParserErrorCode.multipleClauses,
  ParserErrorCode.outOfOrderClauses,
  ParserErrorCode.unexpectedTokens,
  ParserErrorCode.invalidUnicodeEscapeUNoBracket,
  ParserErrorCode.invalidUnicodeEscapeUBracket,
  ParserErrorCode.invalidUnicodeEscapeStarted,
  ParserErrorCode.recordLiteralOnePositionalNoTrailingComma,
  ParserErrorCode.emptyRecordLiteralWithComma,
  ParserErrorCode.emptyRecordTypeNamedFieldsList,
  ParserErrorCode.emptyRecordTypeWithComma,
  ParserErrorCode.recordTypeOnePositionalNoTrailingComma,
  ParserErrorCode.abstractSealedClass,
  ParserErrorCode.experimentNotEnabledOffByDefault,
  ParserErrorCode.annotationSpaceBeforeParenthesis,
  ParserErrorCode.invalidConstantPatternNegation,
  ParserErrorCode.invalidConstantPatternUnary,
  ParserErrorCode.invalidConstantPatternDuplicateConst,
  ParserErrorCode.invalidConstantPatternEmptyRecordLiteral,
  ParserErrorCode.invalidConstantPatternGeneric,
  ParserErrorCode.invalidConstantConstPrefix,
  ParserErrorCode.invalidConstantPatternBinary,
  ParserErrorCode.finalMixinClass,
  ParserErrorCode.interfaceMixinClass,
  ParserErrorCode.sealedMixinClass,
  ParserErrorCode.patternAssignmentDeclaresVariable,
  ParserErrorCode.finalMixin,
  ParserErrorCode.interfaceMixin,
  ParserErrorCode.sealedMixin,
  ParserErrorCode.variablePatternKeywordInDeclarationContext,
  ParserErrorCode.invalidInsideUnaryPattern,
  ParserErrorCode.latePatternVariableDeclaration,
  ParserErrorCode.patternVariableDeclarationOutsideFunctionOrMethod,
  ParserErrorCode.defaultInSwitchExpression,
  ParserErrorCode.mixinWithClause,
  ParserErrorCode.baseEnum,
  ParserErrorCode.finalEnum,
  ParserErrorCode.interfaceEnum,
  ParserErrorCode.sealedEnum,
  ParserErrorCode.illegalPatternVariableName,
  ParserErrorCode.illegalPatternAssignmentVariableName,
  ParserErrorCode.illegalPatternIdentifierName,
  ParserErrorCode.missingPrimaryConstructor,
  ParserErrorCode.missingPrimaryConstructorParameters,
  ParserErrorCode.extensionTypeExtends,
  ParserErrorCode.extensionTypeWith,
  ParserErrorCode.expectedMixinBody,
  ParserErrorCode.expectedExtensionTypeBody,
  ParserErrorCode.expectedTryStatementBody,
  ParserErrorCode.expectedCatchClauseBody,
  ParserErrorCode.expectedFinallyClauseBody,
  ParserErrorCode.expectedSwitchExpressionBody,
  ParserErrorCode.expectedSwitchStatementBody,
  ParserErrorCode.expectedExtensionBody,
  ParserErrorCode.extraneousModifierInExtensionType,
  ParserErrorCode.extraneousModifierInPrimaryConstructor,
  ParserErrorCode.abstractFinalBaseClass,
];

class ParserErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const ParserErrorWithoutArguments abstractClassMember =
      ParserErrorWithoutArguments(
        'ABSTRACT_CLASS_MEMBER',
        "Members of classes can't be declared to be 'abstract'.",
        correctionMessage:
            "Try removing the 'abstract' keyword. You can add the 'abstract' "
            "keyword before the class declaration.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractExternalField =
      ParserErrorWithoutArguments(
        'ABSTRACT_EXTERNAL_FIELD',
        "Fields can't be declared both 'abstract' and 'external'.",
        correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractFinalBaseClass =
      ParserErrorWithoutArguments(
        'ABSTRACT_FINAL_BASE_CLASS',
        "An 'abstract' class can't be declared as both 'final' and 'base'.",
        correctionMessage: "Try removing either the 'final' or 'base' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  abstractFinalInterfaceClass = ParserErrorWithoutArguments(
    'ABSTRACT_FINAL_INTERFACE_CLASS',
    "An 'abstract' class can't be declared as both 'final' and 'interface'.",
    correctionMessage:
        "Try removing either the 'final' or 'interface' keyword.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractLateField =
      ParserErrorWithoutArguments(
        'ABSTRACT_LATE_FIELD',
        "Abstract fields cannot be late.",
        correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractSealedClass =
      ParserErrorWithoutArguments(
        'ABSTRACT_SEALED_CLASS',
        "A 'sealed' class can't be marked 'abstract' because it's already "
            "implicitly abstract.",
        correctionMessage: "Try removing the 'abstract' keyword.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractStaticField =
      ParserErrorWithoutArguments(
        'ABSTRACT_STATIC_FIELD',
        "Static fields can't be declared 'abstract'.",
        correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractStaticMethod =
      ParserErrorWithoutArguments(
        'ABSTRACT_STATIC_METHOD',
        "Static methods can't be declared to be 'abstract'.",
        correctionMessage: "Try removing the keyword 'abstract'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  annotationOnTypeArgument = ParserErrorWithoutArguments(
    'ANNOTATION_ON_TYPE_ARGUMENT',
    "Type arguments can't have annotations because they aren't declarations.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments annotationSpaceBeforeParenthesis =
      ParserErrorWithoutArguments(
        'ANNOTATION_SPACE_BEFORE_PARENTHESIS',
        "Annotations can't have spaces or comments before the parenthesis.",
        correctionMessage:
            "Remove any spaces or comments before the parenthesis.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments annotationWithTypeArguments =
      ParserErrorWithoutArguments(
        'ANNOTATION_WITH_TYPE_ARGUMENTS',
        "An annotation can't use type arguments.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  annotationWithTypeArgumentsUninstantiated = ParserErrorWithoutArguments(
    'ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
    "An annotation with type arguments must be followed by an argument list.",
    expectedTypes: [],
  );

  /// 16.32 Identifier Reference: It is a compile-time error if any of the
  /// identifiers async, await, or yield is used as an identifier in a function
  /// body marked with either async, async, or sync.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments asyncKeywordUsedAsIdentifier =
      ParserErrorWithoutArguments(
        'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
        "The keywords 'await' and 'yield' can't be used as identifiers in an "
            "asynchronous or generator function.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments baseEnum =
      ParserErrorWithoutArguments(
        'BASE_ENUM',
        "Enums can't be declared to be 'base'.",
        correctionMessage: "Try removing the keyword 'base'.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  binaryOperatorWrittenOut = ParserErrorTemplate(
    'BINARY_OPERATOR_WRITTEN_OUT',
    "Binary operator '{0}' is written as '{1}' instead of the written out "
        "word.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    withArguments: _withArgumentsBinaryOperatorWrittenOut,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  breakOutsideOfLoop = ParserErrorWithoutArguments(
    'BREAK_OUTSIDE_OF_LOOP',
    "A break statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the break statement.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  catchSyntax = ParserErrorWithoutArguments(
    'CATCH_SYNTAX',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  catchSyntaxExtraParameters = ParserErrorWithoutArguments(
    'CATCH_SYNTAX_EXTRA_PARAMETERS',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments classInClass =
      ParserErrorWithoutArguments(
        'CLASS_IN_CLASS',
        "Classes can't be declared inside other classes.",
        correctionMessage: "Try moving the class to the top-level.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments colonInPlaceOfIn =
      ParserErrorWithoutArguments(
        'COLON_IN_PLACE_OF_IN',
        "For-in loops use 'in' rather than a colon.",
        correctionMessage: "Try replacing the colon with the keyword 'in'.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  conflictingModifiers = ParserErrorTemplate(
    'CONFLICTING_MODIFIERS',
    "Members can't be declared to be both '{0}' and '{1}'.",
    correctionMessage: "Try removing one of the keywords.",
    withArguments: _withArgumentsConflictingModifiers,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments constAndFinal =
      ParserErrorWithoutArguments(
        'CONST_AND_FINAL',
        "Members can't be declared to be both 'const' and 'final'.",
        correctionMessage:
            "Try removing either the 'const' or 'final' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  constClass = ParserErrorWithoutArguments(
    'CONST_CLASS',
    "Classes can't be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword. If you're trying to indicate that "
        "instances of the class can be constants, place the 'const' keyword on "
        " the class' constructor(s).",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments constConstructorWithBody =
      ParserErrorWithoutArguments(
        'CONST_CONSTRUCTOR_WITH_BODY',
        "Const constructors can't have a body.",
        correctionMessage:
            "Try removing either the 'const' keyword or the body.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments constFactory =
      ParserErrorWithoutArguments(
        'CONST_FACTORY',
        "Only redirecting factory constructors can be declared to be 'const'.",
        correctionMessage:
            "Try removing the 'const' keyword, or replacing the body with '=' "
            "followed by a valid target.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments constMethod =
      ParserErrorWithoutArguments(
        'CONST_METHOD',
        "Getters, setters and methods can't be declared to be 'const'.",
        correctionMessage: "Try removing the 'const' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments constructorWithReturnType =
      ParserErrorWithoutArguments(
        'CONSTRUCTOR_WITH_RETURN_TYPE',
        "Constructors can't have a return type.",
        correctionMessage: "Try removing the return type.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  constructorWithTypeArguments = ParserErrorWithoutArguments(
    'CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
    "A constructor invocation can't have type arguments after the constructor "
        "name.",
    correctionMessage:
        "Try removing the type arguments or placing them after the class name.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  continueOutsideOfLoop = ParserErrorWithoutArguments(
    'CONTINUE_OUTSIDE_OF_LOOP',
    "A continue statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the continue statement.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  continueWithoutLabelInCase = ParserErrorWithoutArguments(
    'CONTINUE_WITHOUT_LABEL_IN_CASE',
    "A continue statement in a switch statement must have a label as a target.",
    correctionMessage:
        "Try adding a label associated with one of the case clauses to the "
        "continue statement.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments covariantAndStatic =
      ParserErrorWithoutArguments(
        'COVARIANT_AND_STATIC',
        "Members can't be declared to be both 'covariant' and 'static'.",
        correctionMessage:
            "Try removing either the 'covariant' or 'static' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments covariantConstructor =
      ParserErrorWithoutArguments(
        'COVARIANT_CONSTRUCTOR',
        "A constructor can't be declared to be 'covariant'.",
        correctionMessage: "Try removing the keyword 'covariant'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments covariantMember =
      ParserErrorWithoutArguments(
        'COVARIANT_MEMBER',
        "Getters, setters and methods can't be declared to be 'covariant'.",
        correctionMessage: "Try removing the 'covariant' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments defaultInSwitchExpression =
      ParserErrorWithoutArguments(
        'DEFAULT_IN_SWITCH_EXPRESSION',
        "A switch expression may not use the `default` keyword.",
        correctionMessage: "Try replacing `default` with `_`.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments defaultValueInFunctionType =
      ParserErrorWithoutArguments(
        'DEFAULT_VALUE_IN_FUNCTION_TYPE',
        "Parameters in a function type can't have default values.",
        correctionMessage: "Try removing the default value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments deferredAfterPrefix =
      ParserErrorWithoutArguments(
        'DEFERRED_AFTER_PREFIX',
        "The deferred keyword should come immediately before the prefix ('as' "
            "clause).",
        correctionMessage: "Try moving the deferred keyword before the prefix.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments directiveAfterDeclaration =
      ParserErrorWithoutArguments(
        'DIRECTIVE_AFTER_DECLARATION',
        "Directives must appear before any declarations.",
        correctionMessage: "Try moving the directive before any declarations.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments duplicateDeferred =
      ParserErrorWithoutArguments(
        'DUPLICATE_DEFERRED',
        "An import directive can only have one 'deferred' keyword.",
        correctionMessage: "Try removing all but one 'deferred' keyword.",
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the modifier that was duplicated
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode duplicatedModifier = ParserErrorCode(
    'DUPLICATED_MODIFIER',
    "The modifier '{0}' was already specified.",
    correctionMessage: "Try removing all but one occurrence of the modifier.",
    expectedTypes: [ExpectedType.token],
  );

  /// Parameters:
  /// 0: the label that was duplicated
  ///
  /// Parameters:
  /// Name name: undocumented
  static const ParserErrorCode duplicateLabelInSwitchStatement =
      ParserErrorCode(
        'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
        "The label '{0}' was already used in this switch statement.",
        correctionMessage: "Try choosing a different name for this label.",
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments duplicatePrefix =
      ParserErrorWithoutArguments(
        'DUPLICATE_PREFIX',
        "An import directive can only have one prefix ('as' clause).",
        correctionMessage: "Try removing all but one prefix.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments emptyEnumBody =
      ParserErrorWithoutArguments(
        'EMPTY_ENUM_BODY',
        "An enum must declare at least one constant name.",
        correctionMessage: "Try declaring a constant.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments emptyRecordLiteralWithComma =
      ParserErrorWithoutArguments(
        'EMPTY_RECORD_LITERAL_WITH_COMMA',
        "A record literal without fields can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments emptyRecordTypeNamedFieldsList =
      ParserErrorWithoutArguments(
        'EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
        "The list of named fields in a record type can't be empty.",
        correctionMessage: "Try adding a named field to the list.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments emptyRecordTypeWithComma =
      ParserErrorWithoutArguments(
        'EMPTY_RECORD_TYPE_WITH_COMMA',
        "A record type without fields can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments enumInClass =
      ParserErrorWithoutArguments(
        'ENUM_IN_CLASS',
        "Enums can't be declared inside classes.",
        correctionMessage: "Try moving the enum to the top-level.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments equalityCannotBeEqualityOperand =
      ParserErrorWithoutArguments(
        'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
        "A comparison expression can't be an operand of another comparison "
            "expression.",
        correctionMessage:
            "Try putting parentheses around one of the comparisons.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedCaseOrDefault =
      ParserErrorWithoutArguments(
        'EXPECTED_CASE_OR_DEFAULT',
        "Expected 'case' or 'default'.",
        correctionMessage: "Try placing this code inside a case clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedCatchClauseBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A catch clause must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_CATCH_CLAUSE_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedClassBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A class declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_CLASS_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedClassMember =
      ParserErrorWithoutArguments(
        'EXPECTED_CLASS_MEMBER',
        "Expected a class member.",
        correctionMessage: "Try placing this code inside a class member.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedElseOrComma =
      ParserErrorWithoutArguments(
        'EXPECTED_ELSE_OR_COMMA',
        "Expected 'else' or comma.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  expectedExecutable = ParserErrorWithoutArguments(
    'EXPECTED_EXECUTABLE',
    "Expected a method, getter, setter or operator declaration.",
    correctionMessage:
        "This appears to be incomplete code. Try removing it or completing it.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedExtensionBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "An extension declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_EXTENSION_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedExtensionTypeBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "An extension type declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_EXTENSION_TYPE_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedFinallyClauseBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A finally clause must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_FINALLY_CLAUSE_BODY',
        expectedTypes: [],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode expectedIdentifierButGotKeyword =
      ParserErrorCode(
        'EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
        "'{0}' can't be used as an identifier because it's a keyword.",
        correctionMessage:
            "Try renaming this to be an identifier that isn't a keyword.",
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// String string: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required String string})
  >
  expectedInstead = ParserErrorTemplate(
    'EXPECTED_INSTEAD',
    "Expected '{0}' instead of this.",
    withArguments: _withArgumentsExpectedInstead,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  expectedListOrMapLiteral = ParserErrorWithoutArguments(
    'EXPECTED_LIST_OR_MAP_LITERAL',
    "Expected a list or map literal.",
    correctionMessage:
        "Try inserting a list or map literal, or remove the type arguments.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedMixinBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A mixin declaration must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_MIXIN_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeExtends =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected a class name.",
        correctionMessage:
            "Try using a class name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_EXTENDS',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeImplements =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_IMPLEMENTS',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeOn =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_ON',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeWith =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected a mixin name.",
        correctionMessage:
            "Try using a mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_WITH',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedRepresentationField =
      ParserErrorWithoutArguments(
        'EXPECTED_REPRESENTATION_FIELD',
        "Expected a representation field.",
        correctionMessage:
            "Try providing the representation field for this extension type.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedRepresentationType =
      ParserErrorWithoutArguments(
        'EXPECTED_REPRESENTATION_TYPE',
        "Expected a representation type.",
        correctionMessage:
            "Try providing the representation type for this extension type.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedStringLiteral =
      ParserErrorWithoutArguments(
        'EXPECTED_STRING_LITERAL',
        "Expected a string literal.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedSwitchExpressionBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A switch expression must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_SWITCH_EXPRESSION_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedSwitchStatementBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A switch statement must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_SWITCH_STATEMENT_BODY',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the token that was expected but not found
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  expectedToken = ParserErrorTemplate(
    'EXPECTED_TOKEN',
    "Expected to find '{0}'.",
    withArguments: _withArgumentsExpectedToken,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedTryStatementBody =
      ParserErrorWithoutArguments(
        'EXPECTED_BODY',
        "A try statement must have a body, even if it is empty.",
        correctionMessage: "Try adding an empty body.",
        uniqueName: 'EXPECTED_TRY_STATEMENT_BODY',
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedTypeName =
      ParserErrorWithoutArguments(
        'EXPECTED_TYPE_NAME',
        "Expected a type name.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  experimentNotEnabled = ParserErrorTemplate(
    'EXPERIMENT_NOT_ENABLED',
    "This requires the '{0}' language feature to be enabled.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to "
        "{1} or higher, and running 'pub get'.",
    withArguments: _withArgumentsExperimentNotEnabled,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String string: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required String string})
  >
  experimentNotEnabledOffByDefault = ParserErrorTemplate(
    'EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
    "This requires the experimental '{0}' language feature to be enabled.",
    correctionMessage:
        "Try passing the '--enable-experiment={0}' command line option.",
    withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments exportDirectiveAfterPartDirective =
      ParserErrorWithoutArguments(
        'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        "Export directives must precede part directives.",
        correctionMessage:
            "Try moving the export directives before the part directives.",
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments extensionAugmentationHasOnClause =
      ParserErrorWithoutArguments(
        'EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
        "Extension augmentations can't have 'on' clauses.",
        correctionMessage: "Try removing the 'on' clause.",
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments extensionDeclaresAbstractMember =
      ParserErrorWithoutArguments(
        'EXTENSION_DECLARES_ABSTRACT_MEMBER',
        "Extensions can't declare abstract members.",
        correctionMessage: "Try providing an implementation for the member.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments extensionDeclaresConstructor =
      ParserErrorWithoutArguments(
        'EXTENSION_DECLARES_CONSTRUCTOR',
        "Extensions can't declare constructors.",
        correctionMessage: "Try removing the constructor declaration.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments extensionTypeExtends =
      ParserErrorWithoutArguments(
        'EXTENSION_TYPE_EXTENDS',
        "An extension type declaration can't have an 'extends' clause.",
        correctionMessage:
            "Try removing the 'extends' clause or replacing the 'extends' with "
            "'implements'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments extensionTypeWith =
      ParserErrorWithoutArguments(
        'EXTENSION_TYPE_WITH',
        "An extension type declaration can't have a 'with' clause.",
        correctionMessage:
            "Try removing the 'with' clause or replacing the 'with' with "
            "'implements'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalClass =
      ParserErrorWithoutArguments(
        'EXTERNAL_CLASS',
        "Classes can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  externalConstructorWithFieldInitializers = ParserErrorWithoutArguments(
    'EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
    "An external constructor can't initialize fields.",
    correctionMessage:
        "Try removing the field initializers, or removing the keyword "
        "'external'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments externalConstructorWithInitializer =
      ParserErrorWithoutArguments(
        'EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
        "An external constructor can't have any initializers.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalEnum =
      ParserErrorWithoutArguments(
        'EXTERNAL_ENUM',
        "Enums can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalFactoryRedirection =
      ParserErrorWithoutArguments(
        'EXTERNAL_FACTORY_REDIRECTION',
        "A redirecting factory can't be external.",
        correctionMessage: "Try removing the 'external' modifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalFactoryWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_FACTORY_WITH_BODY',
        "External factories can't have a body.",
        correctionMessage:
            "Try removing the body of the factory, or removing the keyword "
            "'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalGetterWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_GETTER_WITH_BODY',
        "External getters can't have a body.",
        correctionMessage:
            "Try removing the body of the getter, or removing the keyword "
            "'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalLateField =
      ParserErrorWithoutArguments(
        'EXTERNAL_LATE_FIELD',
        "External fields cannot be late.",
        correctionMessage: "Try removing the 'external' or 'late' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalMethodWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_METHOD_WITH_BODY',
        "An external or native method can't have a body.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalOperatorWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_OPERATOR_WITH_BODY',
        "External operators can't have a body.",
        correctionMessage:
            "Try removing the body of the operator, or removing the keyword "
            "'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalSetterWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_SETTER_WITH_BODY',
        "External setters can't have a body.",
        correctionMessage:
            "Try removing the body of the setter, or removing the keyword "
            "'external'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalTypedef =
      ParserErrorWithoutArguments(
        'EXTERNAL_TYPEDEF',
        "Typedefs can't be declared to be 'external'.",
        correctionMessage: "Try removing the keyword 'external'.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode extraneousModifier = ParserErrorCode(
    'EXTRANEOUS_MODIFIER',
    "Can't have modifier '{0}' here.",
    correctionMessage: "Try removing '{0}'.",
    expectedTypes: [ExpectedType.token],
  );

  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode extraneousModifierInExtensionType =
      ParserErrorCode(
        'EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
        "Can't have modifier '{0}' in an extension type.",
        correctionMessage: "Try removing '{0}'.",
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode extraneousModifierInPrimaryConstructor =
      ParserErrorCode(
        'EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
        "Can't have modifier '{0}' in a primary constructor.",
        correctionMessage: "Try removing '{0}'.",
        expectedTypes: [ExpectedType.token],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments factoryTopLevelDeclaration =
      ParserErrorWithoutArguments(
        'FACTORY_TOP_LEVEL_DECLARATION',
        "Top-level declarations can't be declared to be 'factory'.",
        correctionMessage: "Try removing the keyword 'factory'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments factoryWithInitializers =
      ParserErrorWithoutArguments(
        'FACTORY_WITH_INITIALIZERS',
        "A 'factory' constructor can't have initializers.",
        correctionMessage:
            "Try removing the 'factory' keyword to make this a generative "
            "constructor, or removing the initializers.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments factoryWithoutBody =
      ParserErrorWithoutArguments(
        'FACTORY_WITHOUT_BODY',
        "A non-redirecting 'factory' constructor must have a body.",
        correctionMessage: "Try adding a body to the constructor.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  fieldInitializedOutsideDeclaringClass = ParserErrorWithoutArguments(
    'FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
    "A field can only be initialized in its declaring class",
    correctionMessage:
        "Try passing a value into the superclass constructor, or moving the "
        "initialization into the constructor body.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments fieldInitializerOutsideConstructor =
      ParserErrorWithoutArguments(
        'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
        "Field formal parameters can only be used in a constructor.",
        correctionMessage: "Try removing 'this.'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalAndCovariant =
      ParserErrorWithoutArguments(
        'FINAL_AND_COVARIANT',
        "Members can't be declared to be both 'final' and 'covariant'.",
        correctionMessage:
            "Try removing either the 'final' or 'covariant' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  finalAndCovariantLateWithInitializer = ParserErrorWithoutArguments(
    'FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
    "Members marked 'late' with an initializer can't be declared to be both "
        "'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword, or removing "
        "the initializer.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments finalAndVar =
      ParserErrorWithoutArguments(
        'FINAL_AND_VAR',
        "Members can't be declared to be both 'final' and 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalConstructor =
      ParserErrorWithoutArguments(
        'FINAL_CONSTRUCTOR',
        "A constructor can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalEnum =
      ParserErrorWithoutArguments(
        'FINAL_ENUM',
        "Enums can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalMethod =
      ParserErrorWithoutArguments(
        'FINAL_METHOD',
        "Getters, setters and methods can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalMixin =
      ParserErrorWithoutArguments(
        'FINAL_MIXIN',
        "A mixin can't be declared 'final'.",
        correctionMessage: "Try removing the 'final' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments finalMixinClass =
      ParserErrorWithoutArguments(
        'FINAL_MIXIN_CLASS',
        "A mixin class can't be declared 'final'.",
        correctionMessage: "Try removing the 'final' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments functionTypedParameterVar =
      ParserErrorWithoutArguments(
        'FUNCTION_TYPED_PARAMETER_VAR',
        "Function-typed parameters can't specify 'const', 'final' or 'var' in "
            "place of a return type.",
        correctionMessage: "Try replacing the keyword with a return type.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments getterConstructor =
      ParserErrorWithoutArguments(
        'GETTER_CONSTRUCTOR',
        "Constructors can't be a getter.",
        correctionMessage: "Try removing 'get'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  getterInFunction = ParserErrorWithoutArguments(
    'GETTER_IN_FUNCTION',
    "Getters can't be defined within methods or functions.",
    correctionMessage:
        "Try moving the getter outside the method or function, or converting "
        "the getter to a function.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments getterWithParameters =
      ParserErrorWithoutArguments(
        'GETTER_WITH_PARAMETERS',
        "Getters must be declared without a parameter list.",
        correctionMessage:
            "Try removing the parameter list, or removing the keyword 'get' to "
            "define a method rather than a getter.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments illegalAssignmentToNonAssignable =
      ParserErrorWithoutArguments(
        'ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
        "Illegal assignment to non-assignable expression.",
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode illegalPatternAssignmentVariableName =
      ParserErrorCode(
        'ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
        "A variable assigned by a pattern assignment can't be named '{0}'.",
        correctionMessage: "Choose a different name.",
        expectedTypes: [ExpectedType.token],
      );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode illegalPatternIdentifierName = ParserErrorCode(
    'ILLEGAL_PATTERN_IDENTIFIER_NAME',
    "A pattern can't refer to an identifier named '{0}'.",
    correctionMessage: "Match the identifier using '==",
    expectedTypes: [ExpectedType.token],
  );

  /// Parameters:
  /// 0: the illegal name
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode illegalPatternVariableName = ParserErrorCode(
    'ILLEGAL_PATTERN_VARIABLE_NAME',
    "The variable declared by a variable pattern can't be named '{0}'.",
    correctionMessage: "Choose a different name.",
    expectedTypes: [ExpectedType.token],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments implementsBeforeExtends =
      ParserErrorWithoutArguments(
        'IMPLEMENTS_BEFORE_EXTENDS',
        "The extends clause must be before the implements clause.",
        correctionMessage:
            "Try moving the extends clause before the implements clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments implementsBeforeOn =
      ParserErrorWithoutArguments(
        'IMPLEMENTS_BEFORE_ON',
        "The on clause must be before the implements clause.",
        correctionMessage:
            "Try moving the on clause before the implements clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments implementsBeforeWith =
      ParserErrorWithoutArguments(
        'IMPLEMENTS_BEFORE_WITH',
        "The with clause must be before the implements clause.",
        correctionMessage:
            "Try moving the with clause before the implements clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments importDirectiveAfterPartDirective =
      ParserErrorWithoutArguments(
        'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        "Import directives must precede part directives.",
        correctionMessage:
            "Try moving the import directives before the part directives.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments initializedVariableInForEach =
      ParserErrorWithoutArguments(
        'INITIALIZED_VARIABLE_IN_FOR_EACH',
        "The loop variable in a for-each loop can't be initialized.",
        correctionMessage:
            "Try removing the initializer, or using a different kind of loop.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments interfaceEnum =
      ParserErrorWithoutArguments(
        'INTERFACE_ENUM',
        "Enums can't be declared to be 'interface'.",
        correctionMessage: "Try removing the keyword 'interface'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments interfaceMixin =
      ParserErrorWithoutArguments(
        'INTERFACE_MIXIN',
        "A mixin can't be declared 'interface'.",
        correctionMessage: "Try removing the 'interface' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments interfaceMixinClass =
      ParserErrorWithoutArguments(
        'INTERFACE_MIXIN_CLASS',
        "A mixin class can't be declared 'interface'.",
        correctionMessage: "Try removing the 'interface' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidAwaitInFor =
      ParserErrorWithoutArguments(
        'INVALID_AWAIT_IN_FOR',
        "The keyword 'await' isn't allowed for a normal 'for' statement.",
        correctionMessage:
            "Try removing the keyword, or use a for-each statement.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the invalid escape sequence
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidCodePoint = ParserErrorTemplate(
    'INVALID_CODE_POINT',
    "The escape sequence '{0}' isn't a valid code point.",
    withArguments: _withArgumentsInvalidCodePoint,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidCommentReference = ParserErrorWithoutArguments(
    'INVALID_COMMENT_REFERENCE',
    "Comment references should contain a possibly prefixed identifier and can "
        "start with 'new', but shouldn't contain anything else.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidConstantConstPrefix = ParserErrorWithoutArguments(
    'INVALID_CONSTANT_CONST_PREFIX',
    "The expression can't be prefixed by 'const' to form a constant pattern.",
    correctionMessage:
        "Try wrapping the expression in 'const ( ... )' instead.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const ParserErrorCode invalidConstantPatternBinary = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_BINARY',
    "The binary operator {0} is not supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
    expectedTypes: [ExpectedType.name],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidConstantPatternDuplicateConst = ParserErrorWithoutArguments(
    'INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
    "Duplicate 'const' keyword in constant expression.",
    correctionMessage: "Try removing one of the 'const' keywords.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidConstantPatternEmptyRecordLiteral = ParserErrorWithoutArguments(
    'INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
    "The empty record literal is not supported as a constant pattern.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidConstantPatternGeneric =
      ParserErrorWithoutArguments(
        'INVALID_CONSTANT_PATTERN_GENERIC',
        "This expression is not supported as a constant pattern.",
        correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidConstantPatternNegation = ParserErrorWithoutArguments(
    'INVALID_CONSTANT_PATTERN_NEGATION',
    "Only negation of a numeric literal is supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const ParserErrorCode invalidConstantPatternUnary = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_UNARY',
    "The unary operator {0} is not supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
    expectedTypes: [ExpectedType.name],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidConstructorName =
      ParserErrorWithoutArguments(
        'INVALID_CONSTRUCTOR_NAME',
        "The name of a constructor must match the name of the enclosing class.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidGenericFunctionType = ParserErrorWithoutArguments(
    'INVALID_GENERIC_FUNCTION_TYPE',
    "Invalid generic function type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidHexEscape = ParserErrorWithoutArguments(
    'INVALID_HEX_ESCAPE',
    "An escape sequence starting with '\\x' must be followed by 2 hexadecimal "
        "digits.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidInitializer =
      ParserErrorWithoutArguments(
        'INVALID_INITIALIZER',
        "Not a valid initializer.",
        correctionMessage:
            "To initialize a field, use the syntax 'name = value'.",
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidInsideUnaryPattern = ParserErrorWithoutArguments(
    'INVALID_INSIDE_UNARY_PATTERN',
    "This pattern cannot appear inside a unary pattern (cast pattern, null "
        "check pattern, or null assert pattern) without parentheses.",
    correctionMessage:
        "Try combining into a single pattern if possible, or enclose the inner "
        "pattern in parentheses.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidLiteralInConfiguration =
      ParserErrorWithoutArguments(
        'INVALID_LITERAL_IN_CONFIGURATION',
        "The literal in a configuration can't contain interpolation.",
        correctionMessage: "Try removing the interpolation expressions.",
        expectedTypes: [],
      );

  /// Parameters:
  /// 0: the operator that is invalid
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode invalidOperator = ParserErrorCode(
    'INVALID_OPERATOR',
    "The string '{0}' isn't a user-definable operator.",
    expectedTypes: [ExpectedType.token],
  );

  /// Only generated by the old parser.
  /// Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
  ///
  /// Parameters:
  /// Object p0: the operator being applied to 'super'
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidOperatorForSuper = ParserErrorTemplate(
    'INVALID_OPERATOR_FOR_SUPER',
    "The operator '{0}' can't be used with 'super'.",
    withArguments: _withArgumentsInvalidOperatorForSuper,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidOperatorQuestionmarkPeriodForSuper = ParserErrorWithoutArguments(
    'INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
    "The operator '?.' cannot be used with 'super' because 'super' cannot be "
        "null.",
    correctionMessage: "Try replacing '?.' with '.'",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidStarAfterAsync =
      ParserErrorWithoutArguments(
        'INVALID_STAR_AFTER_ASYNC',
        "The modifier 'async*' isn't allowed for an expression function body.",
        correctionMessage: "Try converting the body to a block.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidSuperInInitializer =
      ParserErrorWithoutArguments(
        'INVALID_SUPER_IN_INITIALIZER',
        "Can only use 'super' in an initializer for calling the superclass "
            "constructor (e.g. 'super()' or 'super.namedConstructor()')",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidSync =
      ParserErrorWithoutArguments(
        'INVALID_SYNC',
        "The modifier 'sync' isn't allowed for an expression function body.",
        correctionMessage: "Try converting the body to a block.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidThisInInitializer = ParserErrorWithoutArguments(
    'INVALID_THIS_IN_INITIALIZER',
    "Can only use 'this' in an initializer for field initialization (e.g. "
        "'this.x = something') and constructor redirection (e.g. 'this()' or "
        "'this.namedConstructor())",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidUnicodeEscapeStarted =
      ParserErrorWithoutArguments(
        'INVALID_UNICODE_ESCAPE_STARTED',
        "The string '\\' can't stand alone.",
        correctionMessage:
            "Try adding another backslash (\\) to escape the '\\'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidUnicodeEscapeUBracket =
      ParserErrorWithoutArguments(
        'INVALID_UNICODE_ESCAPE_U_BRACKET',
        "An escape sequence starting with '\\u{' must be followed by 1 to 6 "
            "hexadecimal digits followed by a '}'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidUnicodeEscapeUNoBracket = ParserErrorWithoutArguments(
    'INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
    "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidUnicodeEscapeUStarted = ParserErrorWithoutArguments(
    'INVALID_UNICODE_ESCAPE_U_STARTED',
    "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits or from 1 to 6 digits between '{' and '}'.",
    expectedTypes: [],
  );

  /// No parameters.
  ///
  /// Parameters:
  /// Token lexeme: undocumented
  static const ParserErrorCode invalidUseOfCovariantInExtension =
      ParserErrorCode(
        'INVALID_USE_OF_COVARIANT_IN_EXTENSION',
        "Can't have modifier '{0}' in an extension.",
        correctionMessage: "Try removing '{0}'.",
        hasPublishedDocs: true,
        expectedTypes: [ExpectedType.token],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidUseOfIdentifierAugmented = ParserErrorWithoutArguments(
    'INVALID_USE_OF_IDENTIFIER_AUGMENTED',
    "The identifier 'augmented' can only be used to reference the augmented "
        "declaration inside an augmentation.",
    correctionMessage: "Try using a different identifier.",
    expectedTypes: [],
  );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments latePatternVariableDeclaration =
      ParserErrorWithoutArguments(
        'LATE_PATTERN_VARIABLE_DECLARATION',
        "A pattern variable declaration may not use the `late` keyword.",
        correctionMessage: "Try removing the keyword `late`.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments libraryDirectiveNotFirst =
      ParserErrorWithoutArguments(
        'LIBRARY_DIRECTIVE_NOT_FIRST',
        "The library directive must appear before all other directives.",
        correctionMessage:
            "Try moving the library directive before any other directives.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const ParserErrorCode literalWithClass = ParserErrorCode(
    'LITERAL_WITH_CLASS',
    "A {0} literal can't be prefixed by '{1}'.",
    correctionMessage: "Try removing '{1}'",
    expectedTypes: [ExpectedType.string, ExpectedType.token],
  );

  /// Parameters:
  /// String string: undocumented
  /// Token lexeme: undocumented
  static const ParserErrorCode literalWithClassAndNew = ParserErrorCode(
    'LITERAL_WITH_CLASS_AND_NEW',
    "A {0} literal can't be prefixed by 'new {1}'.",
    correctionMessage: "Try removing 'new' and '{1}'",
    expectedTypes: [ExpectedType.string, ExpectedType.token],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments literalWithNew =
      ParserErrorWithoutArguments(
        'LITERAL_WITH_NEW',
        "A literal can't be prefixed by 'new'.",
        correctionMessage: "Try removing 'new'",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments localFunctionDeclarationModifier =
      ParserErrorWithoutArguments(
        'LOCAL_FUNCTION_DECLARATION_MODIFIER',
        "Local function declarations can't specify any modifiers.",
        correctionMessage: "Try removing the modifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments memberWithClassName =
      ParserErrorWithoutArguments(
        'MEMBER_WITH_CLASS_NAME',
        "A class member can't have the same name as the enclosing class.",
        correctionMessage: "Try renaming the member.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingAssignableSelector =
      ParserErrorWithoutArguments(
        'MISSING_ASSIGNABLE_SELECTOR',
        "Missing selector such as '.identifier' or '[0]'.",
        correctionMessage: "Try adding a selector.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingAssignmentInInitializer =
      ParserErrorWithoutArguments(
        'MISSING_ASSIGNMENT_IN_INITIALIZER',
        "Expected an assignment after the field name.",
        correctionMessage:
            "To initialize a field, use the syntax 'name = value'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingCatchOrFinally = ParserErrorWithoutArguments(
    'MISSING_CATCH_OR_FINALLY',
    "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
    correctionMessage:
        "Try adding either a catch or finally clause, or remove the try "
        "statement.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingClosingParenthesis =
      ParserErrorWithoutArguments(
        'MISSING_CLOSING_PARENTHESIS',
        "The closing parenthesis is missing.",
        correctionMessage: "Try adding the closing parenthesis.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingConstFinalVarOrType = ParserErrorWithoutArguments(
    'MISSING_CONST_FINAL_VAR_OR_TYPE',
    "Variables must be declared using the keywords 'const', 'final', 'var' or "
        "a type name.",
    correctionMessage:
        "Try adding the name of the type of the variable or the keyword 'var'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingEnumBody =
      ParserErrorWithoutArguments(
        'MISSING_ENUM_BODY',
        "An enum definition must have a body with at least one constant name.",
        correctionMessage:
            "Try adding a body and defining at least one constant.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingExpressionInInitializer =
      ParserErrorWithoutArguments(
        'MISSING_EXPRESSION_IN_INITIALIZER',
        "Expected an expression after the assignment operator.",
        correctionMessage:
            "Try adding the value to be assigned, or remove the assignment "
            "operator.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingExpressionInThrow = ParserErrorWithoutArguments(
    'MISSING_EXPRESSION_IN_THROW',
    "Missing expression after 'throw'.",
    correctionMessage:
        "Add an expression after 'throw' or use 'rethrow' to throw a caught "
        "exception",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionBody =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_BODY',
        "A function body must be provided.",
        correctionMessage: "Try adding a function body.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionKeyword =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_KEYWORD',
        "Function types must have the keyword 'Function' before the parameter "
            "list.",
        correctionMessage: "Try adding the keyword 'Function'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionParameters =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_PARAMETERS',
        "Functions must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingGet =
      ParserErrorWithoutArguments(
        'MISSING_GET',
        "Getters must have the keyword 'get' before the getter name.",
        correctionMessage: "Try adding the keyword 'get'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingIdentifier =
      ParserErrorWithoutArguments(
        'MISSING_IDENTIFIER',
        "Expected an identifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingInitializer =
      ParserErrorWithoutArguments(
        'MISSING_INITIALIZER',
        "Expected an initializer.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingKeywordOperator =
      ParserErrorWithoutArguments(
        'MISSING_KEYWORD_OPERATOR',
        "Operator declarations must be preceded by the keyword 'operator'.",
        correctionMessage: "Try adding the keyword 'operator'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingMethodParameters =
      ParserErrorWithoutArguments(
        'MISSING_METHOD_PARAMETERS',
        "Methods must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingNameForNamedParameter = ParserErrorWithoutArguments(
    'MISSING_NAME_FOR_NAMED_PARAMETER',
    "Named parameters in a function type must have a name",
    correctionMessage:
        "Try providing a name for the parameter or removing the curly braces.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingNameInLibraryDirective = ParserErrorWithoutArguments(
    'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
    "Library directives must include a library name.",
    correctionMessage:
        "Try adding a library name after the keyword 'library', or remove the "
        "library directive if the library doesn't have any parts.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingNameInPartOfDirective =
      ParserErrorWithoutArguments(
        'MISSING_NAME_IN_PART_OF_DIRECTIVE',
        "Part-of directives must include a library name.",
        correctionMessage: "Try adding a library name after the 'of'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingPrefixInDeferredImport =
      ParserErrorWithoutArguments(
        'MISSING_PREFIX_IN_DEFERRED_IMPORT',
        "Deferred imports should have a prefix.",
        correctionMessage:
            "Try adding a prefix to the import by adding an 'as' clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingPrimaryConstructor = ParserErrorWithoutArguments(
    'MISSING_PRIMARY_CONSTRUCTOR',
    "An extension type declaration must have a primary constructor "
        "declaration.",
    correctionMessage:
        "Try adding a primary constructor to the extension type declaration.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingPrimaryConstructorParameters =
      ParserErrorWithoutArguments(
        'MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
        "A primary constructor declaration must have formal parameters.",
        correctionMessage:
            "Try adding formal parameters after the primary constructor name.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingStarAfterSync =
      ParserErrorWithoutArguments(
        'MISSING_STAR_AFTER_SYNC',
        "The modifier 'sync' must be followed by a star ('*').",
        correctionMessage: "Try removing the modifier, or add a star.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingStatement =
      ParserErrorWithoutArguments(
        'MISSING_STATEMENT',
        "Expected a statement.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the terminator that is missing
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingTerminatorForParameterGroup = ParserErrorTemplate(
    'MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
    "There is no '{0}' to close the parameter group.",
    correctionMessage: "Try inserting a '{0}' at the end of the group.",
    withArguments: _withArgumentsMissingTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingTypedefParameters =
      ParserErrorWithoutArguments(
        'MISSING_TYPEDEF_PARAMETERS',
        "Typedefs must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingVariableInForEach = ParserErrorWithoutArguments(
    'MISSING_VARIABLE_IN_FOR_EACH',
    "A loop variable must be declared in a for-each loop before the 'in', but "
        "none was found.",
    correctionMessage: "Try declaring a loop variable.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments mixedParameterGroups =
      ParserErrorWithoutArguments(
        'MIXED_PARAMETER_GROUPS',
        "Can't have both positional and named parameters in a single parameter "
            "list.",
        correctionMessage:
            "Try choosing a single style of optional parameters.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments mixinDeclaresConstructor =
      ParserErrorWithoutArguments(
        'MIXIN_DECLARES_CONSTRUCTOR',
        "Mixins can't declare constructors.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments mixinWithClause =
      ParserErrorWithoutArguments(
        'MIXIN_WITH_CLAUSE',
        "A mixin can't have a with clause.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  modifierOutOfOrder = ParserErrorTemplate(
    'MODIFIER_OUT_OF_ORDER',
    "The modifier '{0}' should be before the modifier '{1}'.",
    correctionMessage: "Try re-ordering the modifiers.",
    withArguments: _withArgumentsModifierOutOfOrder,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  multipleClauses = ParserErrorTemplate(
    'MULTIPLE_CLAUSES',
    "Each '{0}' definition can have at most one '{1}' clause.",
    correctionMessage:
        "Try combining all of the '{1}' clauses into a single clause.",
    withArguments: _withArgumentsMultipleClauses,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  multipleExtendsClauses = ParserErrorWithoutArguments(
    'MULTIPLE_EXTENDS_CLAUSES',
    "Each class definition can have at most one extends clause.",
    correctionMessage:
        "Try choosing one superclass and define your class to implement (or "
        "mix in) the others.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  multipleImplementsClauses = ParserErrorWithoutArguments(
    'MULTIPLE_IMPLEMENTS_CLAUSES',
    "Each class or mixin definition can have at most one implements clause.",
    correctionMessage:
        "Try combining all of the implements clauses into a single clause.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleLibraryDirectives =
      ParserErrorWithoutArguments(
        'MULTIPLE_LIBRARY_DIRECTIVES',
        "Only one library directive may be declared in a file.",
        correctionMessage:
            "Try removing all but one of the library directives.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleNamedParameterGroups =
      ParserErrorWithoutArguments(
        'MULTIPLE_NAMED_PARAMETER_GROUPS',
        "Can't have multiple groups of named parameters in a single parameter "
            "list.",
        correctionMessage:
            "Try combining all of the groups into a single group.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleOnClauses =
      ParserErrorWithoutArguments(
        'MULTIPLE_ON_CLAUSES',
        "Each mixin definition can have at most one on clause.",
        correctionMessage:
            "Try combining all of the on clauses into a single clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments multiplePartOfDirectives =
      ParserErrorWithoutArguments(
        'MULTIPLE_PART_OF_DIRECTIVES',
        "Only one part-of directive may be declared in a file.",
        correctionMessage:
            "Try removing all but one of the part-of directives.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  multiplePositionalParameterGroups = ParserErrorWithoutArguments(
    'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
    "Can't have multiple groups of positional parameters in a single parameter "
        "list.",
    correctionMessage: "Try combining all of the groups into a single group.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleRepresentationFields =
      ParserErrorWithoutArguments(
        'MULTIPLE_REPRESENTATION_FIELDS',
        "Each extension type should have exactly one representation field.",
        correctionMessage:
            "Try combining fields into a record, or removing extra fields.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the number of variables being declared
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  multipleVariablesInForEach = ParserErrorTemplate(
    'MULTIPLE_VARIABLES_IN_FOR_EACH',
    "A single loop variable must be declared in a for-each loop before the "
        "'in', but {0} were found.",
    correctionMessage:
        "Try moving all but one of the declarations inside the loop body.",
    withArguments: _withArgumentsMultipleVariablesInForEach,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleVarianceModifiers =
      ParserErrorWithoutArguments(
        'MULTIPLE_VARIANCE_MODIFIERS',
        "Each type parameter can have at most one variance modifier.",
        correctionMessage:
            "Use at most one of the 'in', 'out', or 'inout' modifiers.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleWithClauses =
      ParserErrorWithoutArguments(
        'MULTIPLE_WITH_CLAUSES',
        "Each class definition can have at most one with clause.",
        correctionMessage:
            "Try combining all of the with clauses into a single clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments namedFunctionExpression =
      ParserErrorWithoutArguments(
        'NAMED_FUNCTION_EXPRESSION',
        "Function expressions can't be named.",
        correctionMessage:
            "Try removing the name, or moving the function expression to a "
            "function declaration statement.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments namedFunctionType =
      ParserErrorWithoutArguments(
        'NAMED_FUNCTION_TYPE',
        "Function types can't be named.",
        correctionMessage:
            "Try replacing the name with the keyword 'Function'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments namedParameterOutsideGroup =
      ParserErrorWithoutArguments(
        'NAMED_PARAMETER_OUTSIDE_GROUP',
        "Named parameters must be enclosed in curly braces ('{' and '}').",
        correctionMessage:
            "Try surrounding the named parameters in curly braces.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nativeClauseInNonSdkCode = ParserErrorWithoutArguments(
    'NATIVE_CLAUSE_IN_NON_SDK_CODE',
    "Native clause can only be used in the SDK and code that is loaded through "
        "native extensions.",
    correctionMessage: "Try removing the native clause.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments nativeClauseShouldBeAnnotation =
      ParserErrorWithoutArguments(
        'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
        "Native clause in this form is deprecated.",
        correctionMessage:
            "Try removing this native clause and adding @native() or "
            "@native('native-name') before the declaration.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nativeFunctionBodyInNonSdkCode = ParserErrorWithoutArguments(
    'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
    "Native functions can only be declared in the SDK and code that is loaded "
        "through native extensions.",
    correctionMessage: "Try removing the word 'native'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments nonConstructorFactory =
      ParserErrorWithoutArguments(
        'NON_CONSTRUCTOR_FACTORY',
        "Only a constructor can be declared to be a factory.",
        correctionMessage: "Try removing the keyword 'factory'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments nonIdentifierLibraryName =
      ParserErrorWithoutArguments(
        'NON_IDENTIFIER_LIBRARY_NAME',
        "The name of a library must be an identifier.",
        correctionMessage:
            "Try using an identifier as the name of the library.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nonPartOfDirectiveInPart = ParserErrorWithoutArguments(
    'NON_PART_OF_DIRECTIVE_IN_PART',
    "The part-of directive must be the only directive in a part.",
    correctionMessage:
        "Try removing the other directives, or moving them to the library for "
        "which this is a part.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments nonStringLiteralAsUri =
      ParserErrorWithoutArguments(
        'NON_STRING_LITERAL_AS_URI',
        "The URI must be a string literal.",
        correctionMessage:
            "Try enclosing the URI in either single or double quotes.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the operator that the user is trying to define
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  nonUserDefinableOperator = ParserErrorTemplate(
    'NON_USER_DEFINABLE_OPERATOR',
    "The operator '{0}' isn't user definable.",
    withArguments: _withArgumentsNonUserDefinableOperator,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments normalBeforeOptionalParameters =
      ParserErrorWithoutArguments(
        'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
        "Normal parameters must occur before optional parameters.",
        correctionMessage:
            "Try moving all of the normal parameters before the optional "
            "parameters.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nullAwareCascadeOutOfOrder = ParserErrorWithoutArguments(
    'NULL_AWARE_CASCADE_OUT_OF_ORDER',
    "The '?..' cascade operator must be first in the cascade sequence.",
    correctionMessage:
        "Try moving the '?..' operator to be the first cascade operator in the "
        "sequence.",
    expectedTypes: [],
  );

  /// Parameters:
  /// String string: undocumented
  /// String string2: undocumented
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({
      required String string,
      required String string2,
    })
  >
  outOfOrderClauses = ParserErrorTemplate(
    'OUT_OF_ORDER_CLAUSES',
    "The '{0}' clause must come before the '{1}' clause.",
    correctionMessage: "Try moving the '{0}' clause before the '{1}' clause.",
    withArguments: _withArgumentsOutOfOrderClauses,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  partOfName = ParserErrorWithoutArguments(
    'PART_OF_NAME',
    "The 'part of' directive can't use a name with the enhanced-parts feature.",
    correctionMessage: "Try using 'part of' with a URI instead.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const ParserErrorCode patternAssignmentDeclaresVariable =
      ParserErrorCode(
        'PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
        "Variable '{0}' can't be declared in a pattern assignment.",
        correctionMessage:
            "Try using a preexisting variable or changing the assignment to a "
            "pattern variable declaration.",
        expectedTypes: [ExpectedType.name],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments
  patternVariableDeclarationOutsideFunctionOrMethod = ParserErrorWithoutArguments(
    'PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
    "A pattern variable declaration may not appear outside a function or "
        "method.",
    correctionMessage:
        "Try declaring ordinary variables and assigning from within a function "
        "or method.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments positionalAfterNamedArgument =
      ParserErrorWithoutArguments(
        'POSITIONAL_AFTER_NAMED_ARGUMENT',
        "Positional arguments must occur before named arguments.",
        correctionMessage:
            "Try moving all of the positional arguments before the named "
            "arguments.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  positionalParameterOutsideGroup = ParserErrorWithoutArguments(
    'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
    "Positional parameters must be enclosed in square brackets ('[' and ']').",
    correctionMessage:
        "Try surrounding the positional parameters in square brackets.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  prefixAfterCombinator = ParserErrorWithoutArguments(
    'PREFIX_AFTER_COMBINATOR',
    "The prefix ('as' clause) should come before any show/hide combinators.",
    correctionMessage: "Try moving the prefix before the combinators.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  recordLiteralOnePositionalNoTrailingComma = ParserErrorWithoutArguments(
    'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    "A record literal with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  recordTypeOnePositionalNoTrailingComma = ParserErrorWithoutArguments(
    'RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
    "A record type with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  redirectingConstructorWithBody = ParserErrorWithoutArguments(
    'REDIRECTING_CONSTRUCTOR_WITH_BODY',
    "Redirecting constructors can't have a body.",
    correctionMessage:
        "Try removing the body, or not making this a redirecting constructor.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments redirectionInNonFactoryConstructor =
      ParserErrorWithoutArguments(
        'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
        "Only factory constructor can specify '=' redirection.",
        correctionMessage:
            "Try making this a factory constructor, or remove the redirection.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments representationFieldModifier =
      ParserErrorWithoutArguments(
        'REPRESENTATION_FIELD_MODIFIER',
        "Representation fields can't have modifiers.",
        correctionMessage: "Try removing the modifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments representationFieldTrailingComma =
      ParserErrorWithoutArguments(
        'REPRESENTATION_FIELD_TRAILING_COMMA',
        "The representation field can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments sealedEnum =
      ParserErrorWithoutArguments(
        'SEALED_ENUM',
        "Enums can't be declared to be 'sealed'.",
        correctionMessage: "Try removing the keyword 'sealed'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments sealedMixin =
      ParserErrorWithoutArguments(
        'SEALED_MIXIN',
        "A mixin can't be declared 'sealed'.",
        correctionMessage: "Try removing the 'sealed' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments sealedMixinClass =
      ParserErrorWithoutArguments(
        'SEALED_MIXIN_CLASS',
        "A mixin class can't be declared 'sealed'.",
        correctionMessage: "Try removing the 'sealed' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments setterConstructor =
      ParserErrorWithoutArguments(
        'SETTER_CONSTRUCTOR',
        "Constructors can't be a setter.",
        correctionMessage: "Try removing 'set'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments setterInFunction =
      ParserErrorWithoutArguments(
        'SETTER_IN_FUNCTION',
        "Setters can't be defined within methods or functions.",
        correctionMessage:
            "Try moving the setter outside the method or function.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments stackOverflow =
      ParserErrorWithoutArguments(
        'STACK_OVERFLOW',
        "The file has too many nested expressions or statements.",
        correctionMessage: "Try simplifying the code.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments staticConstructor =
      ParserErrorWithoutArguments(
        'STATIC_CONSTRUCTOR',
        "Constructors can't be static.",
        correctionMessage: "Try removing the keyword 'static'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  staticGetterWithoutBody = ParserErrorWithoutArguments(
    'STATIC_GETTER_WITHOUT_BODY',
    "A 'static' getter must have a body.",
    correctionMessage:
        "Try adding a body to the getter, or removing the keyword 'static'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments staticOperator =
      ParserErrorWithoutArguments(
        'STATIC_OPERATOR',
        "Operators can't be static.",
        correctionMessage: "Try removing the keyword 'static'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  staticSetterWithoutBody = ParserErrorWithoutArguments(
    'STATIC_SETTER_WITHOUT_BODY',
    "A 'static' setter must have a body.",
    correctionMessage:
        "Try adding a body to the setter, or removing the keyword 'static'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments switchHasCaseAfterDefaultCase =
      ParserErrorWithoutArguments(
        'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
        "The default case should be the last case in a switch statement.",
        correctionMessage:
            "Try moving the default case after the other case clauses.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments switchHasMultipleDefaultCases =
      ParserErrorWithoutArguments(
        'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
        "The 'default' case can only be declared once.",
        correctionMessage: "Try removing all but one default case.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  topLevelOperator = ParserErrorWithoutArguments(
    'TOP_LEVEL_OPERATOR',
    "Operators must be declared within a class.",
    correctionMessage:
        "Try removing the operator, moving it to a class, or converting it to "
        "be a function.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Name name: undocumented
  static const ParserErrorCode typeArgumentsOnTypeVariable = ParserErrorCode(
    'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
    "Can't use type arguments with type variable '{0}'.",
    correctionMessage: "Try removing the type arguments.",
    expectedTypes: [ExpectedType.name],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments typeBeforeFactory =
      ParserErrorWithoutArguments(
        'TYPE_BEFORE_FACTORY',
        "Factory constructors cannot have a return type.",
        correctionMessage: "Try removing the type appearing before 'factory'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments typedefInClass =
      ParserErrorWithoutArguments(
        'TYPEDEF_IN_CLASS',
        "Typedefs can't be declared inside classes.",
        correctionMessage: "Try moving the typedef to the top-level.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments typeParameterOnConstructor =
      ParserErrorWithoutArguments(
        'TYPE_PARAMETER_ON_CONSTRUCTOR',
        "Constructors can't have type parameters.",
        correctionMessage: "Try removing the type parameters.",
        expectedTypes: [],
      );

  /// 7.1.1 Operators: Type parameters are not syntactically supported on an
  /// operator.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments typeParameterOnOperator =
      ParserErrorWithoutArguments(
        'TYPE_PARAMETER_ON_OPERATOR',
        "Types parameters aren't allowed when defining an operator.",
        correctionMessage: "Try removing the type parameters.",
        expectedTypes: [],
      );

  @Deprecated("Please use unexpectedToken")
  static const ParserErrorCode UNEXPECTED_TOKEN = unexpectedToken;

  /// Parameters:
  /// Object p0: the starting character that was missing
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unexpectedTerminatorForParameterGroup = ParserErrorTemplate(
    'UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
    "There is no '{0}' to open a parameter group.",
    correctionMessage: "Try inserting the '{0}' at the appropriate location.",
    withArguments: _withArgumentsUnexpectedTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the unexpected text that was found
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unexpectedToken = ParserErrorTemplate(
    'UNEXPECTED_TOKEN',
    "Unexpected text '{0}'.",
    correctionMessage: "Try removing the text.",
    withArguments: _withArgumentsUnexpectedToken,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments unexpectedTokens =
      ParserErrorWithoutArguments(
        'UNEXPECTED_TOKENS',
        "Unexpected tokens.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments varAndType =
      ParserErrorWithoutArguments(
        'VAR_AND_TYPE',
        "Variables can't be declared using both 'var' and a type name.",
        correctionMessage: "Try removing 'var.'",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments varAsTypeName =
      ParserErrorWithoutArguments(
        'VAR_AS_TYPE_NAME',
        "The keyword 'var' can't be used as a type name.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments varClass =
      ParserErrorWithoutArguments(
        'VAR_CLASS',
        "Classes can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments varEnum =
      ParserErrorWithoutArguments(
        'VAR_ENUM',
        "Enums can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
        expectedTypes: [],
      );

  /// No parameters.
  ///
  /// No parameters.
  static const ParserErrorWithoutArguments
  variablePatternKeywordInDeclarationContext = ParserErrorWithoutArguments(
    'VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
    "Variable patterns in declaration context can't specify 'var' or 'final' "
        "keyword.",
    correctionMessage: "Try removing the keyword.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  varReturnType = ParserErrorWithoutArguments(
    'VAR_RETURN_TYPE',
    "The return type can't be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  varTypedef = ParserErrorWithoutArguments(
    'VAR_TYPEDEF',
    "Typedefs can't be declared to be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ParserErrorWithoutArguments voidWithTypeArguments =
      ParserErrorWithoutArguments(
        'VOID_WITH_TYPE_ARGUMENTS',
        "Type 'void' can't have type arguments.",
        correctionMessage: "Try removing the type arguments.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments withBeforeExtends =
      ParserErrorWithoutArguments(
        'WITH_BEFORE_EXTENDS',
        "The extends clause must be before the with clause.",
        correctionMessage:
            "Try moving the extends clause before the with clause.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments wrongNumberOfParametersForSetter =
      ParserErrorWithoutArguments(
        'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
        "Setters must declare exactly one required positional parameter.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  wrongSeparatorForPositionalParameter = ParserErrorWithoutArguments(
    'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
    "The default value of a positional parameter should be preceded by '='.",
    correctionMessage: "Try replacing the ':' with '='.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the terminator that was expected
  /// Object p1: the terminator that was found
  static const ParserErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  wrongTerminatorForParameterGroup = ParserErrorTemplate(
    'WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
    "Expected '{0}' to close parameter group.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
    withArguments: _withArgumentsWrongTerminatorForParameterGroup,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Initialize a newly created error code to have the given [name].
  const ParserErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'ParserErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.ERROR;

  @override
  DiagnosticType get type => DiagnosticType.SYNTACTIC_ERROR;

  static LocatableDiagnostic _withArgumentsBinaryOperatorWrittenOut({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(binaryOperatorWrittenOut, [string, string2]);
  }

  static LocatableDiagnostic _withArgumentsConflictingModifiers({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(conflictingModifiers, [string, string2]);
  }

  static LocatableDiagnostic _withArgumentsExpectedInstead({
    required String string,
  }) {
    return LocatableDiagnosticImpl(expectedInstead, [string]);
  }

  static LocatableDiagnostic _withArgumentsExpectedToken({required String p0}) {
    return LocatableDiagnosticImpl(expectedToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExperimentNotEnabled({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(experimentNotEnabled, [string, string2]);
  }

  static LocatableDiagnostic _withArgumentsExperimentNotEnabledOffByDefault({
    required String string,
  }) {
    return LocatableDiagnosticImpl(experimentNotEnabledOffByDefault, [string]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCodePoint({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidCodePoint, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOperatorForSuper({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(invalidOperatorForSuper, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingTerminatorForParameterGroup({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(missingTerminatorForParameterGroup, [p0]);
  }

  static LocatableDiagnostic _withArgumentsModifierOutOfOrder({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(modifierOutOfOrder, [string, string2]);
  }

  static LocatableDiagnostic _withArgumentsMultipleClauses({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(multipleClauses, [string, string2]);
  }

  static LocatableDiagnostic _withArgumentsMultipleVariablesInForEach({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(multipleVariablesInForEach, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonUserDefinableOperator({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(nonUserDefinableOperator, [p0]);
  }

  static LocatableDiagnostic _withArgumentsOutOfOrderClauses({
    required String string,
    required String string2,
  }) {
    return LocatableDiagnosticImpl(outOfOrderClauses, [string, string2]);
  }

  static LocatableDiagnostic
  _withArgumentsUnexpectedTerminatorForParameterGroup({required Object p0}) {
    return LocatableDiagnosticImpl(unexpectedTerminatorForParameterGroup, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnexpectedToken({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unexpectedToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsWrongTerminatorForParameterGroup({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(wrongTerminatorForParameterGroup, [p0, p1]);
  }
}

final class ParserErrorTemplate<T extends Function> extends ParserErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const ParserErrorTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class ParserErrorWithoutArguments extends ParserErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const ParserErrorWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
