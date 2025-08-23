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

class ParserErrorCode extends DiagnosticCode {
  static const ParserErrorCode abstractClassMember = ParserErrorCode(
    'ABSTRACT_CLASS_MEMBER',
    "Members of classes can't be declared to be 'abstract'.",
    correctionMessage:
        "Try removing the 'abstract' keyword. You can add the 'abstract' "
        "keyword before the class declaration.",
  );

  static const ParserErrorCode abstractExternalField = ParserErrorCode(
    'ABSTRACT_EXTERNAL_FIELD',
    "Fields can't be declared both 'abstract' and 'external'.",
    correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
  );

  static const ParserErrorCode abstractFinalBaseClass = ParserErrorCode(
    'ABSTRACT_FINAL_BASE_CLASS',
    "An 'abstract' class can't be declared as both 'final' and 'base'.",
    correctionMessage: "Try removing either the 'final' or 'base' keyword.",
  );

  static const ParserErrorCode abstractFinalInterfaceClass = ParserErrorCode(
    'ABSTRACT_FINAL_INTERFACE_CLASS',
    "An 'abstract' class can't be declared as both 'final' and 'interface'.",
    correctionMessage:
        "Try removing either the 'final' or 'interface' keyword.",
  );

  static const ParserErrorCode abstractLateField = ParserErrorCode(
    'ABSTRACT_LATE_FIELD',
    "Abstract fields cannot be late.",
    correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
  );

  static const ParserErrorCode abstractSealedClass = ParserErrorCode(
    'ABSTRACT_SEALED_CLASS',
    "A 'sealed' class can't be marked 'abstract' because it's already "
        "implicitly abstract.",
    correctionMessage: "Try removing the 'abstract' keyword.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode abstractStaticField = ParserErrorCode(
    'ABSTRACT_STATIC_FIELD',
    "Static fields can't be declared 'abstract'.",
    correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments abstractStaticMethod =
      ParserErrorWithoutArguments(
        'ABSTRACT_STATIC_METHOD',
        "Static methods can't be declared to be 'abstract'.",
        correctionMessage: "Try removing the keyword 'abstract'.",
      );

  static const ParserErrorCode annotationOnTypeArgument = ParserErrorCode(
    'ANNOTATION_ON_TYPE_ARGUMENT',
    "Type arguments can't have annotations because they aren't declarations.",
  );

  static const ParserErrorCode annotationSpaceBeforeParenthesis =
      ParserErrorCode(
        'ANNOTATION_SPACE_BEFORE_PARENTHESIS',
        "Annotations can't have spaces or comments before the parenthesis.",
        correctionMessage:
            "Remove any spaces or comments before the parenthesis.",
      );

  static const ParserErrorCode annotationWithTypeArguments = ParserErrorCode(
    'ANNOTATION_WITH_TYPE_ARGUMENTS',
    "An annotation can't use type arguments.",
  );

  static const ParserErrorCode
  annotationWithTypeArgumentsUninstantiated = ParserErrorCode(
    'ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
    "An annotation with type arguments must be followed by an argument list.",
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
      );

  static const ParserErrorCode baseEnum = ParserErrorCode(
    'BASE_ENUM',
    "Enums can't be declared to be 'base'.",
    correctionMessage: "Try removing the keyword 'base'.",
  );

  static const ParserErrorCode binaryOperatorWrittenOut = ParserErrorCode(
    'BINARY_OPERATOR_WRITTEN_OUT',
    "Binary operator '{0}' is written as '{1}' instead of the written out "
        "word.",
    correctionMessage: "Try replacing '{0}' with '{1}'.",
  );

  static const ParserErrorCode breakOutsideOfLoop = ParserErrorCode(
    'BREAK_OUTSIDE_OF_LOOP',
    "A break statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the break statement.",
  );

  static const ParserErrorCode catchSyntax = ParserErrorCode(
    'CATCH_SYNTAX',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
  );

  static const ParserErrorCode catchSyntaxExtraParameters = ParserErrorCode(
    'CATCH_SYNTAX_EXTRA_PARAMETERS',
    "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
    correctionMessage:
        "No types are needed, the first is given by 'on', the second is always "
        "'StackTrace'.",
  );

  static const ParserErrorCode classInClass = ParserErrorCode(
    'CLASS_IN_CLASS',
    "Classes can't be declared inside other classes.",
    correctionMessage: "Try moving the class to the top-level.",
  );

  static const ParserErrorCode colonInPlaceOfIn = ParserErrorCode(
    'COLON_IN_PLACE_OF_IN',
    "For-in loops use 'in' rather than a colon.",
    correctionMessage: "Try replacing the colon with the keyword 'in'.",
  );

  static const ParserErrorCode conflictingModifiers = ParserErrorCode(
    'CONFLICTING_MODIFIERS',
    "Members can't be declared to be both '{0}' and '{1}'.",
    correctionMessage: "Try removing one of the keywords.",
  );

  static const ParserErrorCode constAndFinal = ParserErrorCode(
    'CONST_AND_FINAL',
    "Members can't be declared to be both 'const' and 'final'.",
    correctionMessage: "Try removing either the 'const' or 'final' keyword.",
  );

  static const ParserErrorCode constClass = ParserErrorCode(
    'CONST_CLASS',
    "Classes can't be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword. If you're trying to indicate that "
        "instances of the class can be constants, place the 'const' keyword on "
        " the class' constructor(s).",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments constConstructorWithBody =
      ParserErrorWithoutArguments(
        'CONST_CONSTRUCTOR_WITH_BODY',
        "Const constructors can't have a body.",
        correctionMessage:
            "Try removing either the 'const' keyword or the body.",
      );

  static const ParserErrorCode constFactory = ParserErrorCode(
    'CONST_FACTORY',
    "Only redirecting factory constructors can be declared to be 'const'.",
    correctionMessage:
        "Try removing the 'const' keyword, or replacing the body with '=' "
        "followed by a valid target.",
  );

  static const ParserErrorCode constMethod = ParserErrorCode(
    'CONST_METHOD',
    "Getters, setters and methods can't be declared to be 'const'.",
    correctionMessage: "Try removing the 'const' keyword.",
  );

  static const ParserErrorCode constructorWithReturnType = ParserErrorCode(
    'CONSTRUCTOR_WITH_RETURN_TYPE',
    "Constructors can't have a return type.",
    correctionMessage: "Try removing the return type.",
  );

  static const ParserErrorCode constructorWithTypeArguments = ParserErrorCode(
    'CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
    "A constructor invocation can't have type arguments after the constructor "
        "name.",
    correctionMessage:
        "Try removing the type arguments or placing them after the class name.",
  );

  static const ParserErrorCode continueOutsideOfLoop = ParserErrorCode(
    'CONTINUE_OUTSIDE_OF_LOOP',
    "A continue statement can't be used outside of a loop or switch statement.",
    correctionMessage: "Try removing the continue statement.",
  );

  static const ParserErrorCode continueWithoutLabelInCase = ParserErrorCode(
    'CONTINUE_WITHOUT_LABEL_IN_CASE',
    "A continue statement in a switch statement must have a label as a target.",
    correctionMessage:
        "Try adding a label associated with one of the case clauses to the "
        "continue statement.",
  );

  static const ParserErrorCode covariantAndStatic = ParserErrorCode(
    'COVARIANT_AND_STATIC',
    "Members can't be declared to be both 'covariant' and 'static'.",
    correctionMessage:
        "Try removing either the 'covariant' or 'static' keyword.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments covariantConstructor =
      ParserErrorWithoutArguments(
        'COVARIANT_CONSTRUCTOR',
        "A constructor can't be declared to be 'covariant'.",
        correctionMessage: "Try removing the keyword 'covariant'.",
      );

  static const ParserErrorCode covariantMember = ParserErrorCode(
    'COVARIANT_MEMBER',
    "Getters, setters and methods can't be declared to be 'covariant'.",
    correctionMessage: "Try removing the 'covariant' keyword.",
  );

  /// No parameters.
  static const ParserErrorCode defaultInSwitchExpression = ParserErrorCode(
    'DEFAULT_IN_SWITCH_EXPRESSION',
    "A switch expression may not use the `default` keyword.",
    correctionMessage: "Try replacing `default` with `_`.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments defaultValueInFunctionType =
      ParserErrorWithoutArguments(
        'DEFAULT_VALUE_IN_FUNCTION_TYPE',
        "Parameters in a function type can't have default values.",
        correctionMessage: "Try removing the default value.",
        hasPublishedDocs: true,
      );

  static const ParserErrorCode deferredAfterPrefix = ParserErrorCode(
    'DEFERRED_AFTER_PREFIX',
    "The deferred keyword should come immediately before the prefix ('as' "
        "clause).",
    correctionMessage: "Try moving the deferred keyword before the prefix.",
  );

  static const ParserErrorCode directiveAfterDeclaration = ParserErrorCode(
    'DIRECTIVE_AFTER_DECLARATION',
    "Directives must appear before any declarations.",
    correctionMessage: "Try moving the directive before any declarations.",
  );

  static const ParserErrorCode duplicateDeferred = ParserErrorCode(
    'DUPLICATE_DEFERRED',
    "An import directive can only have one 'deferred' keyword.",
    correctionMessage: "Try removing all but one 'deferred' keyword.",
  );

  /// Parameters:
  /// 0: the modifier that was duplicated
  static const ParserErrorCode duplicatedModifier = ParserErrorCode(
    'DUPLICATED_MODIFIER',
    "The modifier '{0}' was already specified.",
    correctionMessage: "Try removing all but one occurrence of the modifier.",
  );

  /// Parameters:
  /// 0: the label that was duplicated
  static const ParserErrorCode duplicateLabelInSwitchStatement =
      ParserErrorCode(
        'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
        "The label '{0}' was already used in this switch statement.",
        correctionMessage: "Try choosing a different name for this label.",
      );

  static const ParserErrorCode duplicatePrefix = ParserErrorCode(
    'DUPLICATE_PREFIX',
    "An import directive can only have one prefix ('as' clause).",
    correctionMessage: "Try removing all but one prefix.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments emptyEnumBody =
      ParserErrorWithoutArguments(
        'EMPTY_ENUM_BODY',
        "An enum must declare at least one constant name.",
        correctionMessage: "Try declaring a constant.",
      );

  static const ParserErrorCode emptyRecordLiteralWithComma = ParserErrorCode(
    'EMPTY_RECORD_LITERAL_WITH_COMMA',
    "A record literal without fields can't have a trailing comma.",
    correctionMessage: "Try removing the trailing comma.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode emptyRecordTypeNamedFieldsList = ParserErrorCode(
    'EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
    "The list of named fields in a record type can't be empty.",
    correctionMessage: "Try adding a named field to the list.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode emptyRecordTypeWithComma = ParserErrorCode(
    'EMPTY_RECORD_TYPE_WITH_COMMA',
    "A record type without fields can't have a trailing comma.",
    correctionMessage: "Try removing the trailing comma.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode enumInClass = ParserErrorCode(
    'ENUM_IN_CLASS',
    "Enums can't be declared inside classes.",
    correctionMessage: "Try moving the enum to the top-level.",
  );

  static const ParserErrorCode equalityCannotBeEqualityOperand =
      ParserErrorCode(
        'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
        "A comparison expression can't be an operand of another comparison "
            "expression.",
        correctionMessage:
            "Try putting parentheses around one of the comparisons.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedCaseOrDefault =
      ParserErrorWithoutArguments(
        'EXPECTED_CASE_OR_DEFAULT',
        "Expected 'case' or 'default'.",
        correctionMessage: "Try placing this code inside a case clause.",
      );

  static const ParserErrorCode expectedCatchClauseBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A catch clause must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_CATCH_CLAUSE_BODY',
  );

  static const ParserErrorCode expectedClassBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A class declaration must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_CLASS_BODY',
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedClassMember =
      ParserErrorWithoutArguments(
        'EXPECTED_CLASS_MEMBER',
        "Expected a class member.",
        correctionMessage: "Try placing this code inside a class member.",
      );

  static const ParserErrorCode expectedElseOrComma = ParserErrorCode(
    'EXPECTED_ELSE_OR_COMMA',
    "Expected 'else' or comma.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  expectedExecutable = ParserErrorWithoutArguments(
    'EXPECTED_EXECUTABLE',
    "Expected a method, getter, setter or operator declaration.",
    correctionMessage:
        "This appears to be incomplete code. Try removing it or completing it.",
  );

  static const ParserErrorCode expectedExtensionBody = ParserErrorCode(
    'EXPECTED_BODY',
    "An extension declaration must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_EXTENSION_BODY',
  );

  static const ParserErrorCode expectedExtensionTypeBody = ParserErrorCode(
    'EXPECTED_BODY',
    "An extension type declaration must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_EXTENSION_TYPE_BODY',
  );

  static const ParserErrorCode expectedFinallyClauseBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A finally clause must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_FINALLY_CLAUSE_BODY',
  );

  static const ParserErrorCode expectedIdentifierButGotKeyword =
      ParserErrorCode(
        'EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
        "'{0}' can't be used as an identifier because it's a keyword.",
        correctionMessage:
            "Try renaming this to be an identifier that isn't a keyword.",
      );

  static const ParserErrorCode expectedInstead = ParserErrorCode(
    'EXPECTED_INSTEAD',
    "Expected '{0}' instead of this.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  expectedListOrMapLiteral = ParserErrorWithoutArguments(
    'EXPECTED_LIST_OR_MAP_LITERAL',
    "Expected a list or map literal.",
    correctionMessage:
        "Try inserting a list or map literal, or remove the type arguments.",
  );

  static const ParserErrorCode expectedMixinBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A mixin declaration must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_MIXIN_BODY',
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeExtends =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected a class name.",
        correctionMessage:
            "Try using a class name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_EXTENDS',
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeImplements =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_IMPLEMENTS',
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeOn =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected the name of a class or mixin.",
        correctionMessage:
            "Try using a class or mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_ON',
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedNamedTypeWith =
      ParserErrorWithoutArguments(
        'EXPECTED_NAMED_TYPE',
        "Expected a mixin name.",
        correctionMessage:
            "Try using a mixin name, possibly with type arguments.",
        uniqueName: 'EXPECTED_NAMED_TYPE_WITH',
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedRepresentationField =
      ParserErrorWithoutArguments(
        'EXPECTED_REPRESENTATION_FIELD',
        "Expected a representation field.",
        correctionMessage:
            "Try providing the representation field for this extension type.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedRepresentationType =
      ParserErrorWithoutArguments(
        'EXPECTED_REPRESENTATION_TYPE',
        "Expected a representation type.",
        correctionMessage:
            "Try providing the representation type for this extension type.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedStringLiteral =
      ParserErrorWithoutArguments(
        'EXPECTED_STRING_LITERAL',
        "Expected a string literal.",
      );

  static const ParserErrorCode expectedSwitchExpressionBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A switch expression must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_SWITCH_EXPRESSION_BODY',
  );

  static const ParserErrorCode expectedSwitchStatementBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A switch statement must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_SWITCH_STATEMENT_BODY',
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
  );

  static const ParserErrorCode expectedTryStatementBody = ParserErrorCode(
    'EXPECTED_BODY',
    "A try statement must have a body, even if it is empty.",
    correctionMessage: "Try adding an empty body.",
    uniqueName: 'EXPECTED_TRY_STATEMENT_BODY',
  );

  /// No parameters.
  static const ParserErrorWithoutArguments expectedTypeName =
      ParserErrorWithoutArguments(
        'EXPECTED_TYPE_NAME',
        "Expected a type name.",
      );

  static const ParserErrorCode experimentNotEnabled = ParserErrorCode(
    'EXPERIMENT_NOT_ENABLED',
    "This requires the '{0}' language feature to be enabled.",
    correctionMessage:
        "Try updating your pubspec.yaml to set the minimum SDK constraint to "
        "{1} or higher, and running 'pub get'.",
  );

  static const ParserErrorCode experimentNotEnabledOffByDefault =
      ParserErrorCode(
        'EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
        "This requires the experimental '{0}' language feature to be enabled.",
        correctionMessage:
            "Try passing the '--enable-experiment={0}' command line option.",
      );

  static const ParserErrorCode exportDirectiveAfterPartDirective =
      ParserErrorCode(
        'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        "Export directives must precede part directives.",
        correctionMessage:
            "Try moving the export directives before the part directives.",
      );

  /// No parameters.
  static const ParserErrorCode extensionAugmentationHasOnClause =
      ParserErrorCode(
        'EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
        "Extension augmentations can't have 'on' clauses.",
        correctionMessage: "Try removing the 'on' clause.",
      );

  /// No parameters.
  static const ParserErrorCode extensionDeclaresAbstractMember =
      ParserErrorCode(
        'EXTENSION_DECLARES_ABSTRACT_MEMBER',
        "Extensions can't declare abstract members.",
        correctionMessage: "Try providing an implementation for the member.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const ParserErrorCode extensionDeclaresConstructor = ParserErrorCode(
    'EXTENSION_DECLARES_CONSTRUCTOR',
    "Extensions can't declare constructors.",
    correctionMessage: "Try removing the constructor declaration.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode extensionTypeExtends = ParserErrorCode(
    'EXTENSION_TYPE_EXTENDS',
    "An extension type declaration can't have an 'extends' clause.",
    correctionMessage:
        "Try removing the 'extends' clause or replacing the 'extends' with "
        "'implements'.",
  );

  static const ParserErrorCode extensionTypeWith = ParserErrorCode(
    'EXTENSION_TYPE_WITH',
    "An extension type declaration can't have a 'with' clause.",
    correctionMessage:
        "Try removing the 'with' clause or replacing the 'with' with "
        "'implements'.",
  );

  static const ParserErrorCode externalClass = ParserErrorCode(
    'EXTERNAL_CLASS',
    "Classes can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode externalConstructorWithFieldInitializers =
      ParserErrorCode(
        'EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
        "An external constructor can't initialize fields.",
        correctionMessage:
            "Try removing the field initializers, or removing the keyword "
            "'external'.",
      );

  static const ParserErrorCode externalConstructorWithInitializer =
      ParserErrorCode(
        'EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
        "An external constructor can't have any initializers.",
      );

  static const ParserErrorCode externalEnum = ParserErrorCode(
    'EXTERNAL_ENUM',
    "Enums can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode externalFactoryRedirection = ParserErrorCode(
    'EXTERNAL_FACTORY_REDIRECTION',
    "A redirecting factory can't be external.",
    correctionMessage: "Try removing the 'external' modifier.",
  );

  static const ParserErrorCode externalFactoryWithBody = ParserErrorCode(
    'EXTERNAL_FACTORY_WITH_BODY',
    "External factories can't have a body.",
    correctionMessage:
        "Try removing the body of the factory, or removing the keyword "
        "'external'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments externalGetterWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_GETTER_WITH_BODY',
        "External getters can't have a body.",
        correctionMessage:
            "Try removing the body of the getter, or removing the keyword "
            "'external'.",
      );

  static const ParserErrorCode externalLateField = ParserErrorCode(
    'EXTERNAL_LATE_FIELD',
    "External fields cannot be late.",
    correctionMessage: "Try removing the 'external' or 'late' keyword.",
  );

  static const ParserErrorCode externalMethodWithBody = ParserErrorCode(
    'EXTERNAL_METHOD_WITH_BODY',
    "An external or native method can't have a body.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments externalOperatorWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_OPERATOR_WITH_BODY',
        "External operators can't have a body.",
        correctionMessage:
            "Try removing the body of the operator, or removing the keyword "
            "'external'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments externalSetterWithBody =
      ParserErrorWithoutArguments(
        'EXTERNAL_SETTER_WITH_BODY',
        "External setters can't have a body.",
        correctionMessage:
            "Try removing the body of the setter, or removing the keyword "
            "'external'.",
      );

  static const ParserErrorCode externalTypedef = ParserErrorCode(
    'EXTERNAL_TYPEDEF',
    "Typedefs can't be declared to be 'external'.",
    correctionMessage: "Try removing the keyword 'external'.",
  );

  static const ParserErrorCode extraneousModifier = ParserErrorCode(
    'EXTRANEOUS_MODIFIER',
    "Can't have modifier '{0}' here.",
    correctionMessage: "Try removing '{0}'.",
  );

  static const ParserErrorCode extraneousModifierInExtensionType =
      ParserErrorCode(
        'EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
        "Can't have modifier '{0}' in an extension type.",
        correctionMessage: "Try removing '{0}'.",
      );

  static const ParserErrorCode extraneousModifierInPrimaryConstructor =
      ParserErrorCode(
        'EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
        "Can't have modifier '{0}' in a primary constructor.",
        correctionMessage: "Try removing '{0}'.",
      );

  static const ParserErrorCode factoryTopLevelDeclaration = ParserErrorCode(
    'FACTORY_TOP_LEVEL_DECLARATION',
    "Top-level declarations can't be declared to be 'factory'.",
    correctionMessage: "Try removing the keyword 'factory'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments factoryWithInitializers =
      ParserErrorWithoutArguments(
        'FACTORY_WITH_INITIALIZERS',
        "A 'factory' constructor can't have initializers.",
        correctionMessage:
            "Try removing the 'factory' keyword to make this a generative "
            "constructor, or removing the initializers.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments factoryWithoutBody =
      ParserErrorWithoutArguments(
        'FACTORY_WITHOUT_BODY',
        "A non-redirecting 'factory' constructor must have a body.",
        correctionMessage: "Try adding a body to the constructor.",
      );

  static const ParserErrorCode
  fieldInitializedOutsideDeclaringClass = ParserErrorCode(
    'FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
    "A field can only be initialized in its declaring class",
    correctionMessage:
        "Try passing a value into the superclass constructor, or moving the "
        "initialization into the constructor body.",
  );

  static const ParserErrorCode fieldInitializerOutsideConstructor =
      ParserErrorCode(
        'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
        "Field formal parameters can only be used in a constructor.",
        correctionMessage: "Try removing 'this.'.",
        hasPublishedDocs: true,
      );

  static const ParserErrorCode finalAndCovariant = ParserErrorCode(
    'FINAL_AND_COVARIANT',
    "Members can't be declared to be both 'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword.",
  );

  static const ParserErrorCode
  finalAndCovariantLateWithInitializer = ParserErrorCode(
    'FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
    "Members marked 'late' with an initializer can't be declared to be both "
        "'final' and 'covariant'.",
    correctionMessage:
        "Try removing either the 'final' or 'covariant' keyword, or removing "
        "the initializer.",
  );

  static const ParserErrorCode finalAndVar = ParserErrorCode(
    'FINAL_AND_VAR',
    "Members can't be declared to be both 'final' and 'var'.",
    correctionMessage: "Try removing the keyword 'var'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments finalConstructor =
      ParserErrorWithoutArguments(
        'FINAL_CONSTRUCTOR',
        "A constructor can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
      );

  static const ParserErrorCode finalEnum = ParserErrorCode(
    'FINAL_ENUM',
    "Enums can't be declared to be 'final'.",
    correctionMessage: "Try removing the keyword 'final'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments finalMethod =
      ParserErrorWithoutArguments(
        'FINAL_METHOD',
        "Getters, setters and methods can't be declared to be 'final'.",
        correctionMessage: "Try removing the keyword 'final'.",
      );

  static const ParserErrorCode finalMixin = ParserErrorCode(
    'FINAL_MIXIN',
    "A mixin can't be declared 'final'.",
    correctionMessage: "Try removing the 'final' keyword.",
  );

  static const ParserErrorCode finalMixinClass = ParserErrorCode(
    'FINAL_MIXIN_CLASS',
    "A mixin class can't be declared 'final'.",
    correctionMessage: "Try removing the 'final' keyword.",
  );

  static const ParserErrorCode functionTypedParameterVar = ParserErrorCode(
    'FUNCTION_TYPED_PARAMETER_VAR',
    "Function-typed parameters can't specify 'const', 'final' or 'var' in "
        "place of a return type.",
    correctionMessage: "Try replacing the keyword with a return type.",
  );

  static const ParserErrorCode getterConstructor = ParserErrorCode(
    'GETTER_CONSTRUCTOR',
    "Constructors can't be a getter.",
    correctionMessage: "Try removing 'get'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  getterInFunction = ParserErrorWithoutArguments(
    'GETTER_IN_FUNCTION',
    "Getters can't be defined within methods or functions.",
    correctionMessage:
        "Try moving the getter outside the method or function, or converting "
        "the getter to a function.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments getterWithParameters =
      ParserErrorWithoutArguments(
        'GETTER_WITH_PARAMETERS',
        "Getters must be declared without a parameter list.",
        correctionMessage:
            "Try removing the parameter list, or removing the keyword 'get' to "
            "define a method rather than a getter.",
      );

  static const ParserErrorCode illegalAssignmentToNonAssignable =
      ParserErrorCode(
        'ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
        "Illegal assignment to non-assignable expression.",
      );

  /// Parameters:
  /// 0: the illegal name
  static const ParserErrorCode illegalPatternAssignmentVariableName =
      ParserErrorCode(
        'ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
        "A variable assigned by a pattern assignment can't be named '{0}'.",
        correctionMessage: "Choose a different name.",
      );

  /// Parameters:
  /// 0: the illegal name
  static const ParserErrorCode illegalPatternIdentifierName = ParserErrorCode(
    'ILLEGAL_PATTERN_IDENTIFIER_NAME',
    "A pattern can't refer to an identifier named '{0}'.",
    correctionMessage: "Match the identifier using '==",
  );

  /// Parameters:
  /// 0: the illegal name
  static const ParserErrorCode illegalPatternVariableName = ParserErrorCode(
    'ILLEGAL_PATTERN_VARIABLE_NAME',
    "The variable declared by a variable pattern can't be named '{0}'.",
    correctionMessage: "Choose a different name.",
  );

  static const ParserErrorCode implementsBeforeExtends = ParserErrorCode(
    'IMPLEMENTS_BEFORE_EXTENDS',
    "The extends clause must be before the implements clause.",
    correctionMessage:
        "Try moving the extends clause before the implements clause.",
  );

  static const ParserErrorCode implementsBeforeOn = ParserErrorCode(
    'IMPLEMENTS_BEFORE_ON',
    "The on clause must be before the implements clause.",
    correctionMessage: "Try moving the on clause before the implements clause.",
  );

  static const ParserErrorCode implementsBeforeWith = ParserErrorCode(
    'IMPLEMENTS_BEFORE_WITH',
    "The with clause must be before the implements clause.",
    correctionMessage:
        "Try moving the with clause before the implements clause.",
  );

  static const ParserErrorCode importDirectiveAfterPartDirective =
      ParserErrorCode(
        'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
        "Import directives must precede part directives.",
        correctionMessage:
            "Try moving the import directives before the part directives.",
      );

  static const ParserErrorCode initializedVariableInForEach = ParserErrorCode(
    'INITIALIZED_VARIABLE_IN_FOR_EACH',
    "The loop variable in a for-each loop can't be initialized.",
    correctionMessage:
        "Try removing the initializer, or using a different kind of loop.",
  );

  static const ParserErrorCode interfaceEnum = ParserErrorCode(
    'INTERFACE_ENUM',
    "Enums can't be declared to be 'interface'.",
    correctionMessage: "Try removing the keyword 'interface'.",
  );

  static const ParserErrorCode interfaceMixin = ParserErrorCode(
    'INTERFACE_MIXIN',
    "A mixin can't be declared 'interface'.",
    correctionMessage: "Try removing the 'interface' keyword.",
  );

  static const ParserErrorCode interfaceMixinClass = ParserErrorCode(
    'INTERFACE_MIXIN_CLASS',
    "A mixin class can't be declared 'interface'.",
    correctionMessage: "Try removing the 'interface' keyword.",
  );

  static const ParserErrorCode invalidAwaitInFor = ParserErrorCode(
    'INVALID_AWAIT_IN_FOR',
    "The keyword 'await' isn't allowed for a normal 'for' statement.",
    correctionMessage: "Try removing the keyword, or use a for-each statement.",
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
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidCommentReference = ParserErrorWithoutArguments(
    'INVALID_COMMENT_REFERENCE',
    "Comment references should contain a possibly prefixed identifier and can "
        "start with 'new', but shouldn't contain anything else.",
  );

  static const ParserErrorCode invalidConstantConstPrefix = ParserErrorCode(
    'INVALID_CONSTANT_CONST_PREFIX',
    "The expression can't be prefixed by 'const' to form a constant pattern.",
    correctionMessage:
        "Try wrapping the expression in 'const ( ... )' instead.",
  );

  static const ParserErrorCode invalidConstantPatternBinary = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_BINARY',
    "The binary operator {0} is not supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  );

  static const ParserErrorCode invalidConstantPatternDuplicateConst =
      ParserErrorCode(
        'INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
        "Duplicate 'const' keyword in constant expression.",
        correctionMessage: "Try removing one of the 'const' keywords.",
      );

  static const ParserErrorCode invalidConstantPatternEmptyRecordLiteral =
      ParserErrorCode(
        'INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
        "The empty record literal is not supported as a constant pattern.",
      );

  static const ParserErrorCode invalidConstantPatternGeneric = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_GENERIC',
    "This expression is not supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  );

  static const ParserErrorCode invalidConstantPatternNegation = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_NEGATION',
    "Only negation of a numeric literal is supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  );

  static const ParserErrorCode invalidConstantPatternUnary = ParserErrorCode(
    'INVALID_CONSTANT_PATTERN_UNARY',
    "The unary operator {0} is not supported as a constant pattern.",
    correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  );

  static const ParserErrorCode invalidConstructorName = ParserErrorCode(
    'INVALID_CONSTRUCTOR_NAME',
    "The name of a constructor must match the name of the enclosing class.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidGenericFunctionType = ParserErrorWithoutArguments(
    'INVALID_GENERIC_FUNCTION_TYPE',
    "Invalid generic function type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
  );

  static const ParserErrorCode invalidHexEscape = ParserErrorCode(
    'INVALID_HEX_ESCAPE',
    "An escape sequence starting with '\\x' must be followed by 2 hexadecimal "
        "digits.",
  );

  static const ParserErrorCode invalidInitializer = ParserErrorCode(
    'INVALID_INITIALIZER',
    "Not a valid initializer.",
    correctionMessage: "To initialize a field, use the syntax 'name = value'.",
  );

  /// No parameters.
  static const ParserErrorCode invalidInsideUnaryPattern = ParserErrorCode(
    'INVALID_INSIDE_UNARY_PATTERN',
    "This pattern cannot appear inside a unary pattern (cast pattern, null "
        "check pattern, or null assert pattern) without parentheses.",
    correctionMessage:
        "Try combining into a single pattern if possible, or enclose the inner "
        "pattern in parentheses.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidLiteralInConfiguration =
      ParserErrorWithoutArguments(
        'INVALID_LITERAL_IN_CONFIGURATION',
        "The literal in a configuration can't contain interpolation.",
        correctionMessage: "Try removing the interpolation expressions.",
      );

  /// Parameters:
  /// 0: the operator that is invalid
  static const ParserErrorCode invalidOperator = ParserErrorCode(
    'INVALID_OPERATOR',
    "The string '{0}' isn't a user-definable operator.",
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
  );

  static const ParserErrorCode
  invalidOperatorQuestionmarkPeriodForSuper = ParserErrorCode(
    'INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
    "The operator '?.' cannot be used with 'super' because 'super' cannot be "
        "null.",
    correctionMessage: "Try replacing '?.' with '.'",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidStarAfterAsync =
      ParserErrorWithoutArguments(
        'INVALID_STAR_AFTER_ASYNC',
        "The modifier 'async*' isn't allowed for an expression function body.",
        correctionMessage: "Try converting the body to a block.",
      );

  static const ParserErrorCode invalidSuperInInitializer = ParserErrorCode(
    'INVALID_SUPER_IN_INITIALIZER',
    "Can only use 'super' in an initializer for calling the superclass "
        "constructor (e.g. 'super()' or 'super.namedConstructor()')",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments invalidSync =
      ParserErrorWithoutArguments(
        'INVALID_SYNC',
        "The modifier 'sync' isn't allowed for an expression function body.",
        correctionMessage: "Try converting the body to a block.",
      );

  static const ParserErrorCode invalidThisInInitializer = ParserErrorCode(
    'INVALID_THIS_IN_INITIALIZER',
    "Can only use 'this' in an initializer for field initialization (e.g. "
        "'this.x = something') and constructor redirection (e.g. 'this()' or "
        "'this.namedConstructor())",
  );

  static const ParserErrorCode invalidUnicodeEscapeStarted = ParserErrorCode(
    'INVALID_UNICODE_ESCAPE_STARTED',
    "The string '\\' can't stand alone.",
    correctionMessage: "Try adding another backslash (\\) to escape the '\\'.",
  );

  static const ParserErrorCode invalidUnicodeEscapeUBracket = ParserErrorCode(
    'INVALID_UNICODE_ESCAPE_U_BRACKET',
    "An escape sequence starting with '\\u{' must be followed by 1 to 6 "
        "hexadecimal digits followed by a '}'.",
  );

  static const ParserErrorCode invalidUnicodeEscapeUNoBracket = ParserErrorCode(
    'INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
    "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits.",
  );

  static const ParserErrorCode invalidUnicodeEscapeUStarted = ParserErrorCode(
    'INVALID_UNICODE_ESCAPE_U_STARTED',
    "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
        "digits or from 1 to 6 digits between '{' and '}'.",
  );

  /// No parameters.
  static const ParserErrorCode invalidUseOfCovariantInExtension =
      ParserErrorCode(
        'INVALID_USE_OF_COVARIANT_IN_EXTENSION',
        "Can't have modifier '{0}' in an extension.",
        correctionMessage: "Try removing '{0}'.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  invalidUseOfIdentifierAugmented = ParserErrorWithoutArguments(
    'INVALID_USE_OF_IDENTIFIER_AUGMENTED',
    "The identifier 'augmented' can only be used to reference the augmented "
        "declaration inside an augmentation.",
    correctionMessage: "Try using a different identifier.",
  );

  /// No parameters.
  static const ParserErrorCode latePatternVariableDeclaration = ParserErrorCode(
    'LATE_PATTERN_VARIABLE_DECLARATION',
    "A pattern variable declaration may not use the `late` keyword.",
    correctionMessage: "Try removing the keyword `late`.",
  );

  static const ParserErrorCode libraryDirectiveNotFirst = ParserErrorCode(
    'LIBRARY_DIRECTIVE_NOT_FIRST',
    "The library directive must appear before all other directives.",
    correctionMessage:
        "Try moving the library directive before any other directives.",
  );

  static const ParserErrorCode literalWithClass = ParserErrorCode(
    'LITERAL_WITH_CLASS',
    "A {0} literal can't be prefixed by '{1}'.",
    correctionMessage: "Try removing '{1}'",
  );

  static const ParserErrorCode literalWithClassAndNew = ParserErrorCode(
    'LITERAL_WITH_CLASS_AND_NEW',
    "A {0} literal can't be prefixed by 'new {1}'.",
    correctionMessage: "Try removing 'new' and '{1}'",
  );

  static const ParserErrorCode literalWithNew = ParserErrorCode(
    'LITERAL_WITH_NEW',
    "A literal can't be prefixed by 'new'.",
    correctionMessage: "Try removing 'new'",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments localFunctionDeclarationModifier =
      ParserErrorWithoutArguments(
        'LOCAL_FUNCTION_DECLARATION_MODIFIER',
        "Local function declarations can't specify any modifiers.",
        correctionMessage: "Try removing the modifier.",
      );

  static const ParserErrorCode memberWithClassName = ParserErrorCode(
    'MEMBER_WITH_CLASS_NAME',
    "A class member can't have the same name as the enclosing class.",
    correctionMessage: "Try renaming the member.",
  );

  static const ParserErrorCode missingAssignableSelector = ParserErrorCode(
    'MISSING_ASSIGNABLE_SELECTOR',
    "Missing selector such as '.identifier' or '[0]'.",
    correctionMessage: "Try adding a selector.",
  );

  static const ParserErrorCode missingAssignmentInInitializer = ParserErrorCode(
    'MISSING_ASSIGNMENT_IN_INITIALIZER',
    "Expected an assignment after the field name.",
    correctionMessage: "To initialize a field, use the syntax 'name = value'.",
  );

  static const ParserErrorCode missingCatchOrFinally = ParserErrorCode(
    'MISSING_CATCH_OR_FINALLY',
    "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
    correctionMessage:
        "Try adding either a catch or finally clause, or remove the try "
        "statement.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingClosingParenthesis =
      ParserErrorWithoutArguments(
        'MISSING_CLOSING_PARENTHESIS',
        "The closing parenthesis is missing.",
        correctionMessage: "Try adding the closing parenthesis.",
      );

  static const ParserErrorCode missingConstFinalVarOrType = ParserErrorCode(
    'MISSING_CONST_FINAL_VAR_OR_TYPE',
    "Variables must be declared using the keywords 'const', 'final', 'var' or "
        "a type name.",
    correctionMessage:
        "Try adding the name of the type of the variable or the keyword 'var'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingEnumBody =
      ParserErrorWithoutArguments(
        'MISSING_ENUM_BODY',
        "An enum definition must have a body with at least one constant name.",
        correctionMessage:
            "Try adding a body and defining at least one constant.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingExpressionInInitializer =
      ParserErrorWithoutArguments(
        'MISSING_EXPRESSION_IN_INITIALIZER',
        "Expected an expression after the assignment operator.",
        correctionMessage:
            "Try adding the value to be assigned, or remove the assignment "
            "operator.",
      );

  static const ParserErrorCode missingExpressionInThrow = ParserErrorCode(
    'MISSING_EXPRESSION_IN_THROW',
    "Missing expression after 'throw'.",
    correctionMessage:
        "Add an expression after 'throw' or use 'rethrow' to throw a caught "
        "exception",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionBody =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_BODY',
        "A function body must be provided.",
        correctionMessage: "Try adding a function body.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionKeyword =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_KEYWORD',
        "Function types must have the keyword 'Function' before the parameter "
            "list.",
        correctionMessage: "Try adding the keyword 'Function'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingFunctionParameters =
      ParserErrorWithoutArguments(
        'MISSING_FUNCTION_PARAMETERS',
        "Functions must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingGet =
      ParserErrorWithoutArguments(
        'MISSING_GET',
        "Getters must have the keyword 'get' before the getter name.",
        correctionMessage: "Try adding the keyword 'get'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingIdentifier =
      ParserErrorWithoutArguments(
        'MISSING_IDENTIFIER',
        "Expected an identifier.",
      );

  static const ParserErrorCode missingInitializer = ParserErrorCode(
    'MISSING_INITIALIZER',
    "Expected an initializer.",
  );

  static const ParserErrorCode missingKeywordOperator = ParserErrorCode(
    'MISSING_KEYWORD_OPERATOR',
    "Operator declarations must be preceded by the keyword 'operator'.",
    correctionMessage: "Try adding the keyword 'operator'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingMethodParameters =
      ParserErrorWithoutArguments(
        'MISSING_METHOD_PARAMETERS',
        "Methods must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingNameForNamedParameter = ParserErrorWithoutArguments(
    'MISSING_NAME_FOR_NAMED_PARAMETER',
    "Named parameters in a function type must have a name",
    correctionMessage:
        "Try providing a name for the parameter or removing the curly braces.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingNameInLibraryDirective = ParserErrorWithoutArguments(
    'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
    "Library directives must include a library name.",
    correctionMessage:
        "Try adding a library name after the keyword 'library', or remove the "
        "library directive if the library doesn't have any parts.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingNameInPartOfDirective =
      ParserErrorWithoutArguments(
        'MISSING_NAME_IN_PART_OF_DIRECTIVE',
        "Part-of directives must include a library name.",
        correctionMessage: "Try adding a library name after the 'of'.",
      );

  static const ParserErrorCode missingPrefixInDeferredImport = ParserErrorCode(
    'MISSING_PREFIX_IN_DEFERRED_IMPORT',
    "Deferred imports should have a prefix.",
    correctionMessage:
        "Try adding a prefix to the import by adding an 'as' clause.",
  );

  static const ParserErrorCode missingPrimaryConstructor = ParserErrorCode(
    'MISSING_PRIMARY_CONSTRUCTOR',
    "An extension type declaration must have a primary constructor "
        "declaration.",
    correctionMessage:
        "Try adding a primary constructor to the extension type declaration.",
  );

  static const ParserErrorCode missingPrimaryConstructorParameters =
      ParserErrorCode(
        'MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
        "A primary constructor declaration must have formal parameters.",
        correctionMessage:
            "Try adding formal parameters after the primary constructor name.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments missingStarAfterSync =
      ParserErrorWithoutArguments(
        'MISSING_STAR_AFTER_SYNC',
        "The modifier 'sync' must be followed by a star ('*').",
        correctionMessage: "Try removing the modifier, or add a star.",
      );

  static const ParserErrorCode missingStatement = ParserErrorCode(
    'MISSING_STATEMENT',
    "Expected a statement.",
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
  );

  /// No parameters.
  static const ParserErrorWithoutArguments missingTypedefParameters =
      ParserErrorWithoutArguments(
        'MISSING_TYPEDEF_PARAMETERS',
        "Typedefs must have an explicit list of parameters.",
        correctionMessage: "Try adding a parameter list.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  missingVariableInForEach = ParserErrorWithoutArguments(
    'MISSING_VARIABLE_IN_FOR_EACH',
    "A loop variable must be declared in a for-each loop before the 'in', but "
        "none was found.",
    correctionMessage: "Try declaring a loop variable.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments mixedParameterGroups =
      ParserErrorWithoutArguments(
        'MIXED_PARAMETER_GROUPS',
        "Can't have both positional and named parameters in a single parameter "
            "list.",
        correctionMessage:
            "Try choosing a single style of optional parameters.",
      );

  static const ParserErrorCode mixinDeclaresConstructor = ParserErrorCode(
    'MIXIN_DECLARES_CONSTRUCTOR',
    "Mixins can't declare constructors.",
  );

  static const ParserErrorCode mixinWithClause = ParserErrorCode(
    'MIXIN_WITH_CLAUSE',
    "A mixin can't have a with clause.",
  );

  static const ParserErrorCode modifierOutOfOrder = ParserErrorCode(
    'MODIFIER_OUT_OF_ORDER',
    "The modifier '{0}' should be before the modifier '{1}'.",
    correctionMessage: "Try re-ordering the modifiers.",
  );

  static const ParserErrorCode multipleClauses = ParserErrorCode(
    'MULTIPLE_CLAUSES',
    "Each '{0}' definition can have at most one '{1}' clause.",
    correctionMessage:
        "Try combining all of the '{1}' clauses into a single clause.",
  );

  static const ParserErrorCode multipleExtendsClauses = ParserErrorCode(
    'MULTIPLE_EXTENDS_CLAUSES',
    "Each class definition can have at most one extends clause.",
    correctionMessage:
        "Try choosing one superclass and define your class to implement (or "
        "mix in) the others.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  multipleImplementsClauses = ParserErrorWithoutArguments(
    'MULTIPLE_IMPLEMENTS_CLAUSES',
    "Each class or mixin definition can have at most one implements clause.",
    correctionMessage:
        "Try combining all of the implements clauses into a single clause.",
  );

  static const ParserErrorCode multipleLibraryDirectives = ParserErrorCode(
    'MULTIPLE_LIBRARY_DIRECTIVES',
    "Only one library directive may be declared in a file.",
    correctionMessage: "Try removing all but one of the library directives.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleNamedParameterGroups =
      ParserErrorWithoutArguments(
        'MULTIPLE_NAMED_PARAMETER_GROUPS',
        "Can't have multiple groups of named parameters in a single parameter "
            "list.",
        correctionMessage:
            "Try combining all of the groups into a single group.",
      );

  static const ParserErrorCode multipleOnClauses = ParserErrorCode(
    'MULTIPLE_ON_CLAUSES',
    "Each mixin definition can have at most one on clause.",
    correctionMessage:
        "Try combining all of the on clauses into a single clause.",
  );

  static const ParserErrorCode multiplePartOfDirectives = ParserErrorCode(
    'MULTIPLE_PART_OF_DIRECTIVES',
    "Only one part-of directive may be declared in a file.",
    correctionMessage: "Try removing all but one of the part-of directives.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  multiplePositionalParameterGroups = ParserErrorWithoutArguments(
    'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
    "Can't have multiple groups of positional parameters in a single parameter "
        "list.",
    correctionMessage: "Try combining all of the groups into a single group.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments multipleRepresentationFields =
      ParserErrorWithoutArguments(
        'MULTIPLE_REPRESENTATION_FIELDS',
        "Each extension type should have exactly one representation field.",
        correctionMessage:
            "Try combining fields into a record, or removing extra fields.",
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
  );

  static const ParserErrorCode multipleVarianceModifiers = ParserErrorCode(
    'MULTIPLE_VARIANCE_MODIFIERS',
    "Each type parameter can have at most one variance modifier.",
    correctionMessage:
        "Use at most one of the 'in', 'out', or 'inout' modifiers.",
  );

  static const ParserErrorCode multipleWithClauses = ParserErrorCode(
    'MULTIPLE_WITH_CLAUSES',
    "Each class definition can have at most one with clause.",
    correctionMessage:
        "Try combining all of the with clauses into a single clause.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments namedFunctionExpression =
      ParserErrorWithoutArguments(
        'NAMED_FUNCTION_EXPRESSION',
        "Function expressions can't be named.",
        correctionMessage:
            "Try removing the name, or moving the function expression to a "
            "function declaration statement.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments namedFunctionType =
      ParserErrorWithoutArguments(
        'NAMED_FUNCTION_TYPE',
        "Function types can't be named.",
        correctionMessage:
            "Try replacing the name with the keyword 'Function'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments namedParameterOutsideGroup =
      ParserErrorWithoutArguments(
        'NAMED_PARAMETER_OUTSIDE_GROUP',
        "Named parameters must be enclosed in curly braces ('{' and '}').",
        correctionMessage:
            "Try surrounding the named parameters in curly braces.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nativeClauseInNonSdkCode = ParserErrorWithoutArguments(
    'NATIVE_CLAUSE_IN_NON_SDK_CODE',
    "Native clause can only be used in the SDK and code that is loaded through "
        "native extensions.",
    correctionMessage: "Try removing the native clause.",
  );

  static const ParserErrorCode nativeClauseShouldBeAnnotation = ParserErrorCode(
    'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
    "Native clause in this form is deprecated.",
    correctionMessage:
        "Try removing this native clause and adding @native() or "
        "@native('native-name') before the declaration.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nativeFunctionBodyInNonSdkCode = ParserErrorWithoutArguments(
    'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
    "Native functions can only be declared in the SDK and code that is loaded "
        "through native extensions.",
    correctionMessage: "Try removing the word 'native'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments nonConstructorFactory =
      ParserErrorWithoutArguments(
        'NON_CONSTRUCTOR_FACTORY',
        "Only a constructor can be declared to be a factory.",
        correctionMessage: "Try removing the keyword 'factory'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments nonIdentifierLibraryName =
      ParserErrorWithoutArguments(
        'NON_IDENTIFIER_LIBRARY_NAME',
        "The name of a library must be an identifier.",
        correctionMessage:
            "Try using an identifier as the name of the library.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  nonPartOfDirectiveInPart = ParserErrorWithoutArguments(
    'NON_PART_OF_DIRECTIVE_IN_PART',
    "The part-of directive must be the only directive in a part.",
    correctionMessage:
        "Try removing the other directives, or moving them to the library for "
        "which this is a part.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments nonStringLiteralAsUri =
      ParserErrorWithoutArguments(
        'NON_STRING_LITERAL_AS_URI',
        "The URI must be a string literal.",
        correctionMessage:
            "Try enclosing the URI in either single or double quotes.",
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
  );

  /// No parameters.
  static const ParserErrorWithoutArguments normalBeforeOptionalParameters =
      ParserErrorWithoutArguments(
        'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
        "Normal parameters must occur before optional parameters.",
        correctionMessage:
            "Try moving all of the normal parameters before the optional "
            "parameters.",
      );

  static const ParserErrorCode nullAwareCascadeOutOfOrder = ParserErrorCode(
    'NULL_AWARE_CASCADE_OUT_OF_ORDER',
    "The '?..' cascade operator must be first in the cascade sequence.",
    correctionMessage:
        "Try moving the '?..' operator to be the first cascade operator in the "
        "sequence.",
  );

  static const ParserErrorCode outOfOrderClauses = ParserErrorCode(
    'OUT_OF_ORDER_CLAUSES',
    "The '{0}' clause must come before the '{1}' clause.",
    correctionMessage: "Try moving the '{0}' clause before the '{1}' clause.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  partOfName = ParserErrorWithoutArguments(
    'PART_OF_NAME',
    "The 'part of' directive can't use a name with the enhanced-parts feature.",
    correctionMessage: "Try using 'part of' with a URI instead.",
  );

  static const ParserErrorCode patternAssignmentDeclaresVariable =
      ParserErrorCode(
        'PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
        "Variable '{0}' can't be declared in a pattern assignment.",
        correctionMessage:
            "Try using a preexisting variable or changing the assignment to a "
            "pattern variable declaration.",
      );

  /// No parameters.
  static const ParserErrorCode
  patternVariableDeclarationOutsideFunctionOrMethod = ParserErrorCode(
    'PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
    "A pattern variable declaration may not appear outside a function or "
        "method.",
    correctionMessage:
        "Try declaring ordinary variables and assigning from within a function "
        "or method.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments positionalAfterNamedArgument =
      ParserErrorWithoutArguments(
        'POSITIONAL_AFTER_NAMED_ARGUMENT',
        "Positional arguments must occur before named arguments.",
        correctionMessage:
            "Try moving all of the positional arguments before the named "
            "arguments.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  positionalParameterOutsideGroup = ParserErrorWithoutArguments(
    'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
    "Positional parameters must be enclosed in square brackets ('[' and ']').",
    correctionMessage:
        "Try surrounding the positional parameters in square brackets.",
  );

  static const ParserErrorCode prefixAfterCombinator = ParserErrorCode(
    'PREFIX_AFTER_COMBINATOR',
    "The prefix ('as' clause) should come before any show/hide combinators.",
    correctionMessage: "Try moving the prefix before the combinators.",
  );

  static const ParserErrorCode
  recordLiteralOnePositionalNoTrailingComma = ParserErrorCode(
    'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    "A record literal with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode recordTypeOnePositionalNoTrailingComma =
      ParserErrorCode(
        'RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
        "A record type with exactly one positional field requires a trailing "
            "comma.",
        correctionMessage: "Try adding a trailing comma.",
        hasPublishedDocs: true,
      );

  static const ParserErrorCode redirectingConstructorWithBody = ParserErrorCode(
    'REDIRECTING_CONSTRUCTOR_WITH_BODY',
    "Redirecting constructors can't have a body.",
    correctionMessage:
        "Try removing the body, or not making this a redirecting constructor.",
  );

  static const ParserErrorCode redirectionInNonFactoryConstructor =
      ParserErrorCode(
        'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
        "Only factory constructor can specify '=' redirection.",
        correctionMessage:
            "Try making this a factory constructor, or remove the redirection.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments representationFieldModifier =
      ParserErrorWithoutArguments(
        'REPRESENTATION_FIELD_MODIFIER',
        "Representation fields can't have modifiers.",
        correctionMessage: "Try removing the modifier.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments representationFieldTrailingComma =
      ParserErrorWithoutArguments(
        'REPRESENTATION_FIELD_TRAILING_COMMA',
        "The representation field can't have a trailing comma.",
        correctionMessage: "Try removing the trailing comma.",
      );

  static const ParserErrorCode sealedEnum = ParserErrorCode(
    'SEALED_ENUM',
    "Enums can't be declared to be 'sealed'.",
    correctionMessage: "Try removing the keyword 'sealed'.",
  );

  static const ParserErrorCode sealedMixin = ParserErrorCode(
    'SEALED_MIXIN',
    "A mixin can't be declared 'sealed'.",
    correctionMessage: "Try removing the 'sealed' keyword.",
  );

  static const ParserErrorCode sealedMixinClass = ParserErrorCode(
    'SEALED_MIXIN_CLASS',
    "A mixin class can't be declared 'sealed'.",
    correctionMessage: "Try removing the 'sealed' keyword.",
  );

  static const ParserErrorCode setterConstructor = ParserErrorCode(
    'SETTER_CONSTRUCTOR',
    "Constructors can't be a setter.",
    correctionMessage: "Try removing 'set'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments setterInFunction =
      ParserErrorWithoutArguments(
        'SETTER_IN_FUNCTION',
        "Setters can't be defined within methods or functions.",
        correctionMessage:
            "Try moving the setter outside the method or function.",
      );

  static const ParserErrorCode stackOverflow = ParserErrorCode(
    'STACK_OVERFLOW',
    "The file has too many nested expressions or statements.",
    correctionMessage: "Try simplifying the code.",
  );

  static const ParserErrorCode staticConstructor = ParserErrorCode(
    'STATIC_CONSTRUCTOR',
    "Constructors can't be static.",
    correctionMessage: "Try removing the keyword 'static'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  staticGetterWithoutBody = ParserErrorWithoutArguments(
    'STATIC_GETTER_WITHOUT_BODY',
    "A 'static' getter must have a body.",
    correctionMessage:
        "Try adding a body to the getter, or removing the keyword 'static'.",
  );

  static const ParserErrorCode staticOperator = ParserErrorCode(
    'STATIC_OPERATOR',
    "Operators can't be static.",
    correctionMessage: "Try removing the keyword 'static'.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  staticSetterWithoutBody = ParserErrorWithoutArguments(
    'STATIC_SETTER_WITHOUT_BODY',
    "A 'static' setter must have a body.",
    correctionMessage:
        "Try adding a body to the setter, or removing the keyword 'static'.",
  );

  static const ParserErrorCode switchHasCaseAfterDefaultCase = ParserErrorCode(
    'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
    "The default case should be the last case in a switch statement.",
    correctionMessage:
        "Try moving the default case after the other case clauses.",
  );

  static const ParserErrorCode switchHasMultipleDefaultCases = ParserErrorCode(
    'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
    "The 'default' case can only be declared once.",
    correctionMessage: "Try removing all but one default case.",
  );

  static const ParserErrorCode topLevelOperator = ParserErrorCode(
    'TOP_LEVEL_OPERATOR',
    "Operators must be declared within a class.",
    correctionMessage:
        "Try removing the operator, moving it to a class, or converting it to "
        "be a function.",
  );

  static const ParserErrorCode typeArgumentsOnTypeVariable = ParserErrorCode(
    'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
    "Can't use type arguments with type variable '{0}'.",
    correctionMessage: "Try removing the type arguments.",
  );

  static const ParserErrorCode typeBeforeFactory = ParserErrorCode(
    'TYPE_BEFORE_FACTORY',
    "Factory constructors cannot have a return type.",
    correctionMessage: "Try removing the type appearing before 'factory'.",
  );

  static const ParserErrorCode typedefInClass = ParserErrorCode(
    'TYPEDEF_IN_CLASS',
    "Typedefs can't be declared inside classes.",
    correctionMessage: "Try moving the typedef to the top-level.",
  );

  static const ParserErrorCode typeParameterOnConstructor = ParserErrorCode(
    'TYPE_PARAMETER_ON_CONSTRUCTOR',
    "Constructors can't have type parameters.",
    correctionMessage: "Try removing the type parameters.",
  );

  /// 7.1.1 Operators: Type parameters are not syntactically supported on an
  /// operator.
  static const ParserErrorCode typeParameterOnOperator = ParserErrorCode(
    'TYPE_PARAMETER_ON_OPERATOR',
    "Types parameters aren't allowed when defining an operator.",
    correctionMessage: "Try removing the type parameters.",
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
  );

  static const ParserErrorCode unexpectedTokens = ParserErrorCode(
    'UNEXPECTED_TOKENS',
    "Unexpected tokens.",
  );

  static const ParserErrorCode varAndType = ParserErrorCode(
    'VAR_AND_TYPE',
    "Variables can't be declared using both 'var' and a type name.",
    correctionMessage: "Try removing 'var.'",
  );

  static const ParserErrorCode varAsTypeName = ParserErrorCode(
    'VAR_AS_TYPE_NAME',
    "The keyword 'var' can't be used as a type name.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments varClass =
      ParserErrorWithoutArguments(
        'VAR_CLASS',
        "Classes can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
      );

  /// No parameters.
  static const ParserErrorWithoutArguments varEnum =
      ParserErrorWithoutArguments(
        'VAR_ENUM',
        "Enums can't be declared to be 'var'.",
        correctionMessage: "Try removing the keyword 'var'.",
      );

  /// No parameters.
  static const ParserErrorCode
  variablePatternKeywordInDeclarationContext = ParserErrorCode(
    'VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
    "Variable patterns in declaration context can't specify 'var' or 'final' "
        "keyword.",
    correctionMessage: "Try removing the keyword.",
    hasPublishedDocs: true,
  );

  static const ParserErrorCode varReturnType = ParserErrorCode(
    'VAR_RETURN_TYPE',
    "The return type can't be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments
  varTypedef = ParserErrorWithoutArguments(
    'VAR_TYPEDEF',
    "Typedefs can't be declared to be 'var'.",
    correctionMessage:
        "Try removing the keyword 'var', or replacing it with the name of the "
        "return type.",
  );

  static const ParserErrorCode voidWithTypeArguments = ParserErrorCode(
    'VOID_WITH_TYPE_ARGUMENTS',
    "Type 'void' can't have type arguments.",
    correctionMessage: "Try removing the type arguments.",
  );

  static const ParserErrorCode withBeforeExtends = ParserErrorCode(
    'WITH_BEFORE_EXTENDS',
    "The extends clause must be before the with clause.",
    correctionMessage: "Try moving the extends clause before the with clause.",
  );

  /// No parameters.
  static const ParserErrorWithoutArguments wrongNumberOfParametersForSetter =
      ParserErrorWithoutArguments(
        'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
        "Setters must declare exactly one required positional parameter.",
        hasPublishedDocs: true,
      );

  /// No parameters.
  static const ParserErrorWithoutArguments
  wrongSeparatorForPositionalParameter = ParserErrorWithoutArguments(
    'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
    "The default value of a positional parameter should be preceded by '='.",
    correctionMessage: "Try replacing the ':' with '='.",
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
  );

  /// Initialize a newly created error code to have the given [name].
  const ParserErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'ParserErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.ERROR;

  @override
  DiagnosticType get type => DiagnosticType.SYNTACTIC_ERROR;

  static LocatableDiagnostic _withArgumentsExpectedToken({required String p0}) {
    return LocatableDiagnosticImpl(expectedToken, [p0]);
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
  });
}
