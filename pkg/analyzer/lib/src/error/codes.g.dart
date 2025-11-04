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

part of "package:analyzer/src/error/codes.dart";

class CompileTimeErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  abstractFieldConstructorInitializer = CompileTimeErrorWithoutArguments(
    name: 'ABSTRACT_FIELD_INITIALIZER',
    problemMessage: "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'abstract' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
    uniqueNameCheck:
        'CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments abstractFieldInitializer =
      CompileTimeErrorWithoutArguments(
        name: 'ABSTRACT_FIELD_INITIALIZER',
        problemMessage: "Abstract fields can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'abstract' keyword.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER',
        expectedTypes: [],
      );

  /// Parameters:
  /// String memberKind: the display name for the kind of the found abstract
  ///                    member
  /// String name: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String memberKind,
      required String name,
    })
  >
  abstractSuperMemberReference = CompileTimeErrorTemplate(
    name: 'ABSTRACT_SUPER_MEMBER_REFERENCE',
    problemMessage: "The {0} '{1}' is always abstract in the supertype.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE',
    withArguments: _withArgumentsAbstractSuperMemberReference,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the ambiguous element
  /// Uri p1: the name of the first library in which the type is found
  /// Uri p2: the name of the second library in which the type is found
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required Uri p1,
      required Uri p2,
    })
  >
  ambiguousExport = CompileTimeErrorTemplate(
    name: 'AMBIGUOUS_EXPORT',
    problemMessage:
        "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
    correctionMessage:
        "Try removing the export of one of the libraries, or explicitly hiding "
        "the name in one of the export directives.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
    withArguments: _withArgumentsAmbiguousExport,
    expectedTypes: [ExpectedType.string, ExpectedType.uri, ExpectedType.uri],
  );

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the names of the declaring extensions
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  ambiguousExtensionMemberAccessThreeOrMore = CompileTimeErrorTemplate(
    name: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    problemMessage:
        "A member named '{0}' is defined in {1}, and none are more specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to "
        "be chosen.",
    hasPublishedDocs: true,
    uniqueName: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS_THREE_OR_MORE',
    uniqueNameCheck:
        'CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_THREE_OR_MORE',
    withArguments: _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  /// Element p1: the name of the first declaring extension
  /// Element p2: the names of the second declaring extension
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required Element p1,
      required Element p2,
    })
  >
  ambiguousExtensionMemberAccessTwo = CompileTimeErrorTemplate(
    name: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    problemMessage:
        "A member named '{0}' is defined in '{1}' and '{2}', and neither is more "
        "specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to "
        "be chosen.",
    hasPublishedDocs: true,
    uniqueName: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO',
    uniqueNameCheck:
        'CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO',
    withArguments: _withArgumentsAmbiguousExtensionMemberAccessTwo,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.element,
      ExpectedType.element,
    ],
  );

  /// Parameters:
  /// String p0: the name of the ambiguous type
  /// String p1: the names of the libraries that the type is found
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  ambiguousImport = CompileTimeErrorTemplate(
    name: 'AMBIGUOUS_IMPORT',
    problemMessage: "The name '{0}' is defined in the libraries {1}.",
    correctionMessage:
        "Try using 'as prefix' for one of the import directives, or hiding the "
        "name from all but one of the imports.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.AMBIGUOUS_IMPORT',
    withArguments: _withArgumentsAmbiguousImport,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  ambiguousSetOrMapLiteralBoth = CompileTimeErrorWithoutArguments(
    name: 'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
    problemMessage:
        "The literal can't be either a map or a set because it contains at least "
        "one literal map entry or a spread operator spreading a 'Map', and at "
        "least one element which is neither of these.",
    correctionMessage:
        "Try removing or changing some of the elements so that all of the "
        "elements are consistent.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  ambiguousSetOrMapLiteralEither = CompileTimeErrorWithoutArguments(
    name: 'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
    problemMessage:
        "This literal must be either a map or a set, but the elements don't have "
        "enough information for type inference to work.",
    correctionMessage:
        "Try adding type arguments to the literal (one for sets, two for "
        "maps).",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the actual argument type
  /// Type p1: the name of the expected type
  /// String p2: additional information, if any, when problem is associated with
  ///            records
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  argumentTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'ARGUMENT_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The argument type '{0}' can't be assigned to the parameter type '{1}'. "
        "{2}",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsArgumentTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assertInRedirectingConstructor =
      CompileTimeErrorWithoutArguments(
        name: 'ASSERT_IN_REDIRECTING_CONSTRUCTOR',
        problemMessage:
            "A redirecting constructor can't have an 'assert' initializer.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  assignmentToConst = CompileTimeErrorWithoutArguments(
    name: 'ASSIGNMENT_TO_CONST',
    problemMessage:
        "Constant variables can't be assigned a value after initialization.",
    correctionMessage:
        "Try removing the assignment, or remove the modifier 'const' from the "
        "variable.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_CONST',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinal = CompileTimeErrorTemplate(
    name: 'ASSIGNMENT_TO_FINAL',
    problemMessage: "'{0}' can't be used as a setter because it's final.",
    correctionMessage:
        "Try finding a different setter, or making '{0}' non-final.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL',
    withArguments: _withArgumentsAssignmentToFinal,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinalLocal = CompileTimeErrorTemplate(
    name: 'ASSIGNMENT_TO_FINAL_LOCAL',
    problemMessage: "The final variable '{0}' can only be set once.",
    correctionMessage: "Try making '{0}' non-final.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL',
    withArguments: _withArgumentsAssignmentToFinalLocal,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the reference
  /// String p1: the name of the class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  assignmentToFinalNoSetter = CompileTimeErrorTemplate(
    name: 'ASSIGNMENT_TO_FINAL_NO_SETTER',
    problemMessage: "There isn't a setter named '{0}' in class '{1}'.",
    correctionMessage:
        "Try correcting the name to reference an existing setter, or declare "
        "the setter.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER',
    withArguments: _withArgumentsAssignmentToFinalNoSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToFunction =
      CompileTimeErrorWithoutArguments(
        name: 'ASSIGNMENT_TO_FUNCTION',
        problemMessage: "Functions can't be assigned a value.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToMethod =
      CompileTimeErrorWithoutArguments(
        name: 'ASSIGNMENT_TO_METHOD',
        problemMessage: "Methods can't be assigned a value.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToType =
      CompileTimeErrorWithoutArguments(
        name: 'ASSIGNMENT_TO_TYPE',
        problemMessage: "Types can't be assigned a value.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ASSIGNMENT_TO_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments asyncForInWrongContext =
      CompileTimeErrorWithoutArguments(
        name: 'ASYNC_FOR_IN_WRONG_CONTEXT',
        problemMessage:
            "The async for-in loop can only be used in an async function.",
        correctionMessage:
            "Try marking the function body with either 'async' or 'async*', or "
            "removing the 'await' before the for-in loop.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentationExtendsClauseAlreadyPresent = CompileTimeErrorWithoutArguments(
    name: 'AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT',
    problemMessage:
        "The augmentation has an 'extends' clause, but an augmentation target "
        "already includes an 'extends' clause and it isn't allowed to be "
        "repeated or changed.",
    correctionMessage:
        "Try removing the 'extends' clause, either here or in the augmentation "
        "target.",
    uniqueNameCheck:
        'CompileTimeErrorCode.AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierExtra = CompileTimeErrorTemplate(
    name: 'AUGMENTATION_MODIFIER_EXTRA',
    problemMessage:
        "The augmentation has the '{0}' modifier that the declaration doesn't "
        "have.",
    correctionMessage:
        "Try removing the '{0}' modifier, or adding it to the declaration.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA',
    withArguments: _withArgumentsAugmentationModifierExtra,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierMissing = CompileTimeErrorTemplate(
    name: 'AUGMENTATION_MODIFIER_MISSING',
    problemMessage:
        "The augmentation is missing the '{0}' modifier that the declaration has.",
    correctionMessage:
        "Try adding the '{0}' modifier, or removing it from the declaration.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING',
    withArguments: _withArgumentsAugmentationModifierMissing,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the declaration kind.
  /// Object p1: the name of the augmentation kind.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  augmentationOfDifferentDeclarationKind = CompileTimeErrorTemplate(
    name: 'AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND',
    problemMessage: "Can't augment a {0} with a {1}.",
    correctionMessage:
        "Try changing the augmentation to match the declaration kind.",
    uniqueNameCheck:
        'CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND',
    withArguments: _withArgumentsAugmentationOfDifferentDeclarationKind,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationTypeParameterBound =
      CompileTimeErrorWithoutArguments(
        name: 'AUGMENTATION_TYPE_PARAMETER_BOUND',
        problemMessage:
            "The augmentation type parameter must have the same bound as the "
            "corresponding type parameter of the declaration.",
        correctionMessage:
            "Try changing the augmentation to match the declaration type "
            "parameters.",
        uniqueNameCheck:
            'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentationTypeParameterCount = CompileTimeErrorWithoutArguments(
    name: 'AUGMENTATION_TYPE_PARAMETER_COUNT',
    problemMessage:
        "The augmentation must have the same number of type parameters as the "
        "declaration.",
    correctionMessage:
        "Try changing the augmentation to match the declaration type "
        "parameters.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationTypeParameterName =
      CompileTimeErrorWithoutArguments(
        name: 'AUGMENTATION_TYPE_PARAMETER_NAME',
        problemMessage:
            "The augmentation type parameter must have the same name as the "
            "corresponding type parameter of the declaration.",
        correctionMessage:
            "Try changing the augmentation to match the declaration type "
            "parameters.",
        uniqueNameCheck:
            'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationWithoutDeclaration =
      CompileTimeErrorWithoutArguments(
        name: 'AUGMENTATION_WITHOUT_DECLARATION',
        problemMessage: "The declaration being augmented doesn't exist.",
        correctionMessage:
            "Try changing the augmentation to match an existing declaration.",
        uniqueNameCheck:
            'CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentedExpressionIsNotSetter = CompileTimeErrorWithoutArguments(
    name: 'AUGMENTED_EXPRESSION_IS_NOT_SETTER',
    problemMessage:
        "The augmented declaration is not a setter, it can't be used to write a "
        "value.",
    correctionMessage: "Try assigning a value to a setter.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_NOT_SETTER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentedExpressionIsSetter = CompileTimeErrorWithoutArguments(
    name: 'AUGMENTED_EXPRESSION_IS_SETTER',
    problemMessage:
        "The augmented declaration is a setter, it can't be used to read a value.",
    correctionMessage: "Try assigning a value to the augmented setter.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the lexeme of the operator.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentedExpressionNotOperator = CompileTimeErrorTemplate(
    name: 'AUGMENTED_EXPRESSION_NOT_OPERATOR',
    problemMessage:
        "The enclosing augmentation doesn't augment the operator '{0}'.",
    correctionMessage: "Try augmenting or invoking the correct operator.",
    uniqueNameCheck: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR',
    withArguments: _withArgumentsAugmentedExpressionNotOperator,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  awaitInLateLocalVariableInitializer = CompileTimeErrorWithoutArguments(
    name: 'AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
    problemMessage:
        "The 'await' expression can't be used in a 'late' local variable's "
        "initializer.",
    correctionMessage:
        "Try removing the 'late' modifier, or rewriting the initializer "
        "without using the 'await' expression.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
    expectedTypes: [],
  );

  /// 16.30 Await Expressions: It is a compile-time error if the function
  /// immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
  /// await expression.)
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments awaitInWrongContext =
      CompileTimeErrorWithoutArguments(
        name: 'AWAIT_IN_WRONG_CONTEXT',
        problemMessage:
            "The await expression can only be used in an async function.",
        correctionMessage:
            "Try marking the function body with either 'async' or 'async*'.",
        uniqueNameCheck: 'CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  awaitOfIncompatibleType = CompileTimeErrorWithoutArguments(
    name: 'AWAIT_OF_INCOMPATIBLE_TYPE',
    problemMessage:
        "The 'await' expression can't be used for an expression with an extension "
        "type that is not a subtype of 'Future'.",
    correctionMessage:
        "Try removing the `await`, or updating the extension type to implement "
        "'Future'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.AWAIT_OF_INCOMPATIBLE_TYPE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String implementedClassName: the name of the base class being implemented
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String implementedClassName})
  >
  baseClassImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be implemented outside of its library because it's "
        "a base class.",
    hasPublishedDocs: true,
    uniqueName: 'BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String implementedMixinName: the name of the base mixin being implemented
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String implementedMixinName})
  >
  baseMixinImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The mixin '{0}' can't be implemented outside of its library because it's "
        "a base mixin.",
    hasPublishedDocs: true,
    uniqueName: 'BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the name of the return type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormally = CompileTimeErrorTemplate(
    name: 'BODY_MIGHT_COMPLETE_NORMALLY',
    problemMessage:
        "The body might complete normally, causing 'null' to be returned, but the "
        "return type, '{0}', is a potentially non-nullable type.",
    correctionMessage:
        "Try adding either a return or a throw statement at the end.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY',
    withArguments: _withArgumentsBodyMightCompleteNormally,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments breakLabelOnSwitchMember =
      CompileTimeErrorWithoutArguments(
        name: 'BREAK_LABEL_ON_SWITCH_MEMBER',
        problemMessage:
            "A break label resolves to the 'case' or 'default' statement.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as an extension name.",
    correctionMessage: "Try choosing a different name for the extension.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
    uniqueNameCheck:
        'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsExtensionName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionTypeName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as an extension type name.",
    correctionMessage: "Try choosing a different name for the extension type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_TYPE_NAME',
    uniqueNameCheck:
        'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_TYPE_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsExtensionTypeName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsPrefixName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as a prefix name.",
    correctionMessage: "Try choosing a different name for the prefix.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
    uniqueNameCheck: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsPrefixName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsType = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_AS_TYPE',
    problemMessage: "The built-in identifier '{0}' can't be used as a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE',
    withArguments: _withArgumentsBuiltInIdentifierAsType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypedefName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as a typedef name.",
    correctionMessage: "Try choosing a different name for the typedef.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
    uniqueNameCheck: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypedefName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as a type name.",
    correctionMessage: "Try choosing a different name for the type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
    uniqueNameCheck: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypeName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeParameterName = CompileTimeErrorTemplate(
    name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    problemMessage:
        "The built-in identifier '{0}' can't be used as a type parameter name.",
    correctionMessage: "Try choosing a different name for the type parameter.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
    uniqueNameCheck:
        'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypeParameterName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the this of the switch case expression
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  caseExpressionTypeImplementsEquals = CompileTimeErrorTemplate(
    name: 'CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    problemMessage:
        "The switch case expression type '{0}' can't override the '==' operator.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    withArguments: _withArgumentsCaseExpressionTypeImplementsEquals,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the type of the case expression
  /// Type p1: the type of the switch expression
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  caseExpressionTypeIsNotSwitchExpressionSubtype = CompileTimeErrorTemplate(
    name: 'CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
    problemMessage:
        "The switch case expression type '{0}' must be a subtype of the switch "
        "expression type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
    withArguments: _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  castToNonType = CompileTimeErrorTemplate(
    name: 'CAST_TO_NON_TYPE',
    problemMessage:
        "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CAST_TO_NON_TYPE',
    withArguments: _withArgumentsCastToNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToInstanceMember = CompileTimeErrorTemplate(
    name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    problemMessage:
        "The instance member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try changing the member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
    uniqueNameCheck:
        'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
    withArguments: _withArgumentsClassInstantiationAccessToInstanceMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToStaticMember = CompileTimeErrorTemplate(
    name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    problemMessage:
        "The static member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try removing the type arguments from the class name, or changing the "
        "member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
    uniqueNameCheck:
        'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
    withArguments: _withArgumentsClassInstantiationAccessToStaticMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class
  /// String p1: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  classInstantiationAccessToUnknownMember = CompileTimeErrorTemplate(
    name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or defining a constructor named "
        "'{1}'.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
    uniqueNameCheck:
        'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
    withArguments: _withArgumentsClassInstantiationAccessToUnknownMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class being used as a mixin
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classUsedAsMixin = CompileTimeErrorTemplate(
    name: 'CLASS_USED_AS_MIXIN',
    problemMessage:
        "The class '{0}' can't be used as a mixin because it's neither a mixin "
        "class nor a mixin.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CLASS_USED_AS_MIXIN',
    withArguments: _withArgumentsClassUsedAsMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  concreteClassHasEnumSuperinterface = CompileTimeErrorWithoutArguments(
    name: 'CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
    problemMessage: "Concrete classes can't have 'Enum' as a superinterface.",
    correctionMessage:
        "Try specifying a different interface, or remove it from the list.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  concreteClassWithAbstractMember = CompileTimeErrorTemplate(
    name: 'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
    problemMessage:
        "'{0}' must have a method body because '{1}' isn't abstract.",
    correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
    withArguments: _withArgumentsConcreteClassWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticField = CompileTimeErrorTemplate(
    name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a constructor and a static field in this "
        "class.",
    correctionMessage: "Try renaming either the constructor or the field.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
    withArguments: _withArgumentsConflictingConstructorAndStaticField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and getter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticGetter = CompileTimeErrorTemplate(
    name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a constructor and a static getter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the getter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
    withArguments: _withArgumentsConflictingConstructorAndStaticGetter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticMethod = CompileTimeErrorTemplate(
    name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a constructor and a static method in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the method.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
    withArguments: _withArgumentsConflictingConstructorAndStaticMethod,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticSetter = CompileTimeErrorTemplate(
    name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a constructor and a static setter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the setter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
    withArguments: _withArgumentsConflictingConstructorAndStaticSetter,
    expectedTypes: [ExpectedType.string],
  );

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a getter or a setter with basename `n`, and has a
  /// method named `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting field
  /// String p1: the name of the conflicting field
  /// String p2: the name of the class defining the method with which the field
  ///            conflicts
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingFieldAndMethod = CompileTimeErrorTemplate(
    name: 'CONFLICTING_FIELD_AND_METHOD',
    problemMessage:
        "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the getter to a method, or renaming the field to a "
        "name that doesn't conflict.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD',
    withArguments: _withArgumentsConflictingFieldAndMethod,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the kind of the element implementing the
  ///            conflicting interface
  /// String p1: the name of the element implementing the conflicting interface
  /// String p2: the first conflicting type
  /// String p3: the second conflicting type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  conflictingGenericInterfaces = CompileTimeErrorTemplate(
    name: 'CONFLICTING_GENERIC_INTERFACES',
    problemMessage:
        "The {0} '{1}' can't implement both '{2}' and '{3}' because the type "
        "arguments are different.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES',
    withArguments: _withArgumentsConflictingGenericInterfaces,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if the interface of `C` has an instance method named `n` and an
  /// instance setter with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the enclosing element kind - class, extension type,
  ///            etc
  /// String p1: the name of the enclosing element
  /// String p2: the name of the conflicting method / setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingInheritedMethodAndSetter = CompileTimeErrorTemplate(
    name: 'CONFLICTING_INHERITED_METHOD_AND_SETTER',
    problemMessage:
        "The {0} '{1}' can't inherit both a method and a setter named '{2}'.",
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER',
    withArguments: _withArgumentsConflictingInheritedMethodAndSetter,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a method named `n`, and has a getter or a setter
  /// with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting method
  /// String p1: the name of the conflicting method
  /// String p2: the name of the class defining the field with which the method
  ///            conflicts
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingMethodAndField = CompileTimeErrorTemplate(
    name: 'CONFLICTING_METHOD_AND_FIELD',
    problemMessage:
        "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the method to a getter, or renaming the method to a "
        "name that doesn't conflict.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD',
    withArguments: _withArgumentsConflictingMethodAndField,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
  /// error if `C` declares a static member with basename `n`, and has an
  /// instance member with basename `n`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the conflicting member
  /// String p1: the name of the conflicting static member
  /// String p2: the name of the class defining the field with which the method
  ///            conflicts
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  conflictingStaticAndInstance = CompileTimeErrorTemplate(
    name: 'CONFLICTING_STATIC_AND_INSTANCE',
    problemMessage:
        "Class '{0}' can't define static member '{1}' and have instance member "
        "'{2}.{1}' with the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE',
    withArguments: _withArgumentsConflictingStaticAndInstance,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndClass = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and the class in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the class.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_CLASS',
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS',
    withArguments: _withArgumentsConflictingTypeVariableAndClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndEnum = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and the enum in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the enum.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_ENUM',
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_ENUM',
    withArguments: _withArgumentsConflictingTypeVariableAndEnum,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtension = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and the extension in "
        "which the type parameter is defined.",
    correctionMessage:
        "Try renaming either the type parameter or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
    withArguments: _withArgumentsConflictingTypeVariableAndExtension,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtensionType = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and the extension type "
        "in which the type parameter is defined.",
    correctionMessage:
        "Try renaming either the type parameter or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_TYPE',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_TYPE',
    withArguments: _withArgumentsConflictingTypeVariableAndExtensionType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberClass = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and a member in this "
        "class.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberEnum = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and a member in this "
        "enum.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberEnum,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtension = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and a member in this "
        "extension.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberExtension,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtensionType = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and a member in this "
        "extension type.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION_TYPE',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION_TYPE',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberExtensionType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberMixin = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and a member in this "
        "mixin.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMixin = CompileTimeErrorTemplate(
    name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    problemMessage:
        "'{0}' can't be used to name both a type parameter and the mixin in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the mixin.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
    uniqueNameCheck: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
    withArguments: _withArgumentsConflictingTypeVariableAndMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constantPatternWithNonConstantExpression = CompileTimeErrorWithoutArguments(
    name: 'CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION',
    problemMessage:
        "The expression of a constant pattern must be a valid constant.",
    correctionMessage: "Try making the expression a valid constant.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorConstantFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as values in a "
        "'const' constructor.",
    correctionMessage:
        "Try removing the keyword 'const' from the constructor or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// Parameters:
  /// Object p0: the type of the runtime value of the argument
  /// Object p1: the name of the field
  /// Object p2: the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  constConstructorFieldTypeMismatch = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
    problemMessage:
        "In a const constructor, a value of type '{0}' can't be assigned to the "
        "field '{1}', which has type '{2}'.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
    withArguments: _withArgumentsConstConstructorFieldTypeMismatch,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// Parameters:
  /// String p0: the type of the runtime value of the argument
  /// String p1: the static type of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  constConstructorParamTypeMismatch = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
    problemMessage:
        "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
    withArguments: _withArgumentsConstConstructorParamTypeMismatch,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorThrowsException = CompileTimeErrorWithoutArguments(
    name: 'CONST_CONSTRUCTOR_THROWS_EXCEPTION',
    problemMessage: "Const constructors can't throw exceptions.",
    correctionMessage:
        "Try removing the throw statement, or removing the keyword 'const'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithFieldInitializedByNonConst = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
    problemMessage:
        "Can't define the 'const' constructor because the field '{0}' is "
        "initialized with a non-constant value.",
    correctionMessage:
        "Try initializing the field to a constant value, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
    withArguments: _withArgumentsConstConstructorWithFieldInitializedByNonConst,
    expectedTypes: [ExpectedType.string],
  );

  /// 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  /// or implicitly, in the initializer list of a constant constructor must
  /// specify a constant constructor of the superclass of the immediately
  /// enclosing class or a compile-time error occurs.
  ///
  /// 12.1 Mixin Application: For each generative constructor named ... an
  /// implicitly declared constructor named ... is declared. If Sq is a
  /// generative const constructor, and M does not declare any fields, Cq is
  /// also a const constructor.
  ///
  /// Parameters:
  /// String p0: the name of the instance field.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithMixinWithField = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    problemMessage:
        "This constructor can't be declared 'const' because a mixin adds the "
        "instance field: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the field from the mixin class.",
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    withArguments: _withArgumentsConstConstructorWithMixinWithField,
    expectedTypes: [ExpectedType.string],
  );

  /// 7.6.3 Constant Constructors: The superinitializer that appears, explicitly
  /// or implicitly, in the initializer list of a constant constructor must
  /// specify a constant constructor of the superclass of the immediately
  /// enclosing class or a compile-time error occurs.
  ///
  /// 12.1 Mixin Application: For each generative constructor named ... an
  /// implicitly declared constructor named ... is declared. If Sq is a
  /// generative const constructor, and M does not declare any fields, Cq is
  /// also a const constructor.
  ///
  /// Parameters:
  /// String p0: the names of the instance fields.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithMixinWithFields = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    problemMessage:
        "This constructor can't be declared 'const' because the mixins add the "
        "instance fields: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the fields from the mixin classes.",
    uniqueName: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
    withArguments: _withArgumentsConstConstructorWithMixinWithFields,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithNonConstSuper = CompileTimeErrorTemplate(
    name: 'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
    problemMessage:
        "A constant constructor can't call a non-constant super constructor of "
        "'{0}'.",
    correctionMessage:
        "Try calling a constant constructor in the superclass, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
    withArguments: _withArgumentsConstConstructorWithNonConstSuper,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorWithNonFinalField = CompileTimeErrorWithoutArguments(
    name: 'CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
    problemMessage:
        "Can't define a const constructor for a class with non-final fields.",
    correctionMessage:
        "Try making all of the fields final, or removing the keyword 'const' "
        "from the constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constDeferredClass = CompileTimeErrorWithoutArguments(
    name: 'CONST_DEFERRED_CLASS',
    problemMessage: "Deferred classes can't be created with 'const'.",
    correctionMessage:
        "Try using 'new' to create the instance, or changing the import to not "
        "be deferred.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_DEFERRED_CLASS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalAssertionFailure =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_ASSERTION_FAILURE',
        problemMessage: "The assertion in this constant expression failed.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_ASSERTION_FAILURE',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the message of the assertion
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  constEvalAssertionFailureWithMessage = CompileTimeErrorTemplate(
    name: 'CONST_EVAL_ASSERTION_FAILURE_WITH_MESSAGE',
    problemMessage: "An assertion failed with message '{0}'.",
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_EVAL_ASSERTION_FAILURE_WITH_MESSAGE',
    withArguments: _withArgumentsConstEvalAssertionFailureWithMessage,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalExtensionMethod =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_EXTENSION_METHOD',
        problemMessage:
            "Extension methods can't be used in constant expressions.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalExtensionTypeMethod =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_EXTENSION_TYPE_METHOD',
        problemMessage:
            "Extension type methods can't be used in constant expressions.",
        uniqueNameCheck:
            'CompileTimeErrorCode.CONST_EVAL_EXTENSION_TYPE_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalForElement = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_FOR_ELEMENT',
    problemMessage: "Constant expressions don't support 'for' elements.",
    correctionMessage:
        "Try replacing the 'for' element with a spread, or removing 'const'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalMethodInvocation =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_METHOD_INVOCATION',
        problemMessage: "Methods can't be invoked in constant expressions.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION',
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 == e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalPrimitiveEquality = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_PRIMITIVE_EQUALITY',
    problemMessage:
        "In constant expressions, operands of the equality operator must have "
        "primitive equality.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_PRIMITIVE_EQUALITY',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the property being accessed
  /// String p1: the type with the property being accessed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  constEvalPropertyAccess = CompileTimeErrorTemplate(
    name: 'CONST_EVAL_PROPERTY_ACCESS',
    problemMessage:
        "The property '{0}' can't be accessed on the type '{1}' in a constant "
        "expression.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS',
    withArguments: _withArgumentsConstEvalPropertyAccess,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalThrowsException =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_THROWS_EXCEPTION',
        problemMessage:
            "Evaluation of this constant expression throws an exception.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION',
        expectedTypes: [],
      );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalThrowsIdbze =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_EVAL_THROWS_IDBZE',
        problemMessage:
            "Evaluation of this constant expression throws an "
            "IntegerDivisionByZeroException.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE',
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form !e1", "An expression of the form
  /// e1 && e2", and "An expression of the form e1 || e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeBool = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_BOOL',
    problemMessage:
        "In constant expressions, operands of this operator must be of type "
        "'bool'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL',
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 & e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeBoolInt = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_BOOL_INT',
    problemMessage:
        "In constant expressions, operands of this operator must be of type 'bool' "
        "or 'int'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT',
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "A literal string".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeBoolNumString = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_BOOL_NUM_STRING',
    problemMessage:
        "In constant expressions, operands of this operator must be of type "
        "'bool', 'num', 'String' or 'null'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING',
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form ~e1", "An expression of one of
  /// the forms e1 >> e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeInt = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_INT',
    problemMessage:
        "In constant expressions, operands of this operator must be of type 'int'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_INT',
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 - e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeNum = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_NUM',
    problemMessage:
        "In constant expressions, operands of this operator must be of type 'num'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_NUM',
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 + e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeNumString = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_NUM_STRING',
    problemMessage:
        "In constant expressions, operands of this operator must be of type 'num' "
        "or 'String'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_NUM_STRING',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeString = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_STRING',
    problemMessage:
        "In constant expressions, operands of this operator must be of type "
        "'String'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_STRING',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeType = CompileTimeErrorWithoutArguments(
    name: 'CONST_EVAL_TYPE_TYPE',
    problemMessage:
        "In constant expressions, operands of this operator must be of type "
        "'Type'.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_EVAL_TYPE_TYPE',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constFieldInitializerNotAssignable = CompileTimeErrorTemplate(
    name: 'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    problemMessage:
        "The initializer type '{0}' can't be assigned to the field type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
    uniqueName: 'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
    withArguments: _withArgumentsConstFieldInitializerNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constInitializedWithNonConstantValue = CompileTimeErrorWithoutArguments(
    name: 'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
    problemMessage:
        "Const variables must be initialized with a constant value.",
    correctionMessage:
        "Try changing the initializer to be a constant expression.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constInitializedWithNonConstantValueFromDeferredLibrary =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
        problemMessage:
            "Constant values from a deferred library can't be used to initialize a "
            "'const' variable.",
        correctionMessage:
            "Try initializing the variable without referencing members of the "
            "deferred library, or changing the import to not be deferred.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constInstanceField =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_INSTANCE_FIELD',
        problemMessage: "Only static fields can be declared as const.",
        correctionMessage:
            "Try declaring the field as final, or adding the keyword 'static'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_INSTANCE_FIELD',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type of the entry's key
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  constMapKeyNotPrimitiveEquality = CompileTimeErrorTemplate(
    name: 'CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY',
    problemMessage:
        "The type of a key in a constant map can't override the '==' operator, or "
        "'hashCode', but the class '{0}' does.",
    correctionMessage:
        "Try using a different value for the key, or removing the keyword "
        "'const' from the map.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY',
    withArguments: _withArgumentsConstMapKeyNotPrimitiveEquality,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constNotInitialized = CompileTimeErrorTemplate(
    name: 'CONST_NOT_INITIALIZED',
    problemMessage: "The constant '{0}' must be initialized.",
    correctionMessage: "Try adding an initialization to the declaration.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_NOT_INITIALIZED',
    withArguments: _withArgumentsConstNotInitialized,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type of the element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  constSetElementNotPrimitiveEquality = CompileTimeErrorTemplate(
    name: 'CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY',
    problemMessage:
        "An element in a constant set can't override the '==' operator, or "
        "'hashCode', but the type '{0}' does.",
    correctionMessage:
        "Try using a different value for the element, or removing the keyword "
        "'const' from the set.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY',
    withArguments: _withArgumentsConstSetElementNotPrimitiveEquality,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constSpreadExpectedListOrSet =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_SPREAD_EXPECTED_LIST_OR_SET',
        problemMessage: "A list or a set is expected in this spread.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constSpreadExpectedMap =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_SPREAD_EXPECTED_MAP',
        problemMessage: "A map is expected in this spread.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constTypeParameter =
      CompileTimeErrorWithoutArguments(
        name: 'CONST_TYPE_PARAMETER',
        problemMessage:
            "Type parameters can't be used in a constant expression.",
        correctionMessage:
            "Try replacing the type parameter with a different type.",
        uniqueNameCheck: 'CompileTimeErrorCode.CONST_TYPE_PARAMETER',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithNonConst = CompileTimeErrorWithoutArguments(
    name: 'CONST_WITH_NON_CONST',
    problemMessage: "The constructor being called isn't a const constructor.",
    correctionMessage: "Try removing 'const' from the constructor invocation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_WITH_NON_CONST',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithNonConstantArgument = CompileTimeErrorWithoutArguments(
    name: 'CONST_WITH_NON_CONSTANT_ARGUMENT',
    problemMessage:
        "Arguments of a constant creation must be constant expressions.",
    correctionMessage:
        "Try making the argument a valid constant, or use 'new' to call the "
        "constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constWithNonType = CompileTimeErrorTemplate(
    name: 'CREATION_WITH_NON_TYPE',
    problemMessage: "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'CONST_WITH_NON_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_WITH_NON_TYPE',
    withArguments: _withArgumentsConstWithNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithTypeParameters = CompileTimeErrorWithoutArguments(
    name: 'CONST_WITH_TYPE_PARAMETERS',
    problemMessage:
        "A constant creation can't use a type parameter as a type argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithTypeParametersConstructorTearoff = CompileTimeErrorWithoutArguments(
    name: 'CONST_WITH_TYPE_PARAMETERS',
    problemMessage:
        "A constant constructor tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithTypeParametersFunctionTearoff = CompileTimeErrorWithoutArguments(
    name: 'CONST_WITH_TYPE_PARAMETERS',
    problemMessage:
        "A constant function tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
    expectedTypes: [],
  );

  /// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  /// a constant constructor declared by the type <i>T</i>.
  ///
  /// Parameters:
  /// Object p0: the name of the type
  /// String p1: the name of the requested constant constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required String p1})
  >
  constWithUndefinedConstructor = CompileTimeErrorTemplate(
    name: 'CONST_WITH_UNDEFINED_CONSTRUCTOR',
    problemMessage:
        "The class '{0}' doesn't have a constant constructor '{1}'.",
    correctionMessage: "Try calling a different constructor.",
    uniqueNameCheck: 'CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR',
    withArguments: _withArgumentsConstWithUndefinedConstructor,
    expectedTypes: [ExpectedType.object, ExpectedType.string],
  );

  /// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
  /// a constant constructor declared by the type <i>T</i>.
  ///
  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constWithUndefinedConstructorDefault = CompileTimeErrorTemplate(
    name: 'CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    problemMessage:
        "The class '{0}' doesn't have an unnamed constant constructor.",
    correctionMessage: "Try calling a different constructor.",
    uniqueNameCheck:
        'CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    withArguments: _withArgumentsConstWithUndefinedConstructorDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  continueLabelInvalid = CompileTimeErrorWithoutArguments(
    name: 'CONTINUE_LABEL_INVALID',
    problemMessage:
        "The label used in a 'continue' statement must be defined on either a loop "
        "or a switch member.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.CONTINUE_LABEL_INVALID',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  /// String p1: detail text explaining why the type could not be inferred
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  couldNotInfer = CompileTimeErrorTemplate(
    name: 'COULD_NOT_INFER',
    problemMessage: "Couldn't infer type parameter '{0}'.{1}",
    uniqueNameCheck: 'CompileTimeErrorCode.COULD_NOT_INFER',
    withArguments: _withArgumentsCouldNotInfer,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  defaultValueInRedirectingFactoryConstructor = CompileTimeErrorWithoutArguments(
    name: 'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
    problemMessage:
        "Default values aren't allowed in factory constructors that redirect to "
        "another constructor.",
    correctionMessage: "Try removing the default value.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  defaultValueOnRequiredParameter = CompileTimeErrorWithoutArguments(
    name: 'DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
    problemMessage: "Required named parameters can't have a default value.",
    correctionMessage:
        "Try removing either the default value or the 'required' modifier.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments deferredImportOfExtension =
      CompileTimeErrorWithoutArguments(
        name: 'DEFERRED_IMPORT_OF_EXTENSION',
        problemMessage:
            "Imports of deferred libraries must hide all extensions.",
        correctionMessage:
            "Try adding either a show combinator listing the names you need to "
            "reference or a hide combinator listing all of the extensions.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  definitelyUnassignedLateLocalVariable = CompileTimeErrorTemplate(
    name: 'DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
    problemMessage:
        "The late local variable '{0}' is definitely unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
    withArguments: _withArgumentsDefinitelyUnassignedLateLocalVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  disallowedTypeInstantiationExpression = CompileTimeErrorWithoutArguments(
    name: 'DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
    problemMessage:
        "Only a generic type, generic function, generic instance method, or "
        "generic constructor can have type arguments.",
    correctionMessage:
        "Try removing the type arguments, or instantiating the type(s) of a "
        "generic type, generic function, generic instance method, or generic "
        "constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments dotShorthandMissingContext =
      CompileTimeErrorWithoutArguments(
        name: 'DOT_SHORTHAND_MISSING_CONTEXT',
        problemMessage:
            "A dot shorthand can't be used where there is no context type.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.DOT_SHORTHAND_MISSING_CONTEXT',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the static getter
  /// String p1: the name of the enclosing type where the getter is being looked
  ///            for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  dotShorthandUndefinedGetter = CompileTimeErrorTemplate(
    name: 'DOT_SHORTHAND_UNDEFINED_MEMBER',
    problemMessage:
        "The static getter '{0}' isn't defined for the context type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing static getter, or "
        "defining a getter or field named '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'DOT_SHORTHAND_UNDEFINED_GETTER',
    uniqueNameCheck: 'CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_GETTER',
    withArguments: _withArgumentsDotShorthandUndefinedGetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the static method or constructor
  /// String p1: the name of the enclosing type where the method or constructor
  ///            is being looked for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  dotShorthandUndefinedInvocation = CompileTimeErrorTemplate(
    name: 'DOT_SHORTHAND_UNDEFINED_MEMBER',
    problemMessage:
        "The static method or constructor '{0}' isn't defined for the context type "
        "'{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing static method or "
        "constructor, or defining a static method or constructor named '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'DOT_SHORTHAND_UNDEFINED_INVOCATION',
    uniqueNameCheck: 'CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_INVOCATION',
    withArguments: _withArgumentsDotShorthandUndefinedInvocation,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments duplicateConstructorDefault =
      CompileTimeErrorWithoutArguments(
        name: 'DUPLICATE_CONSTRUCTOR',
        problemMessage: "The unnamed constructor is already defined.",
        correctionMessage: "Try giving one of the constructors a name.",
        hasPublishedDocs: true,
        uniqueName: 'DUPLICATE_CONSTRUCTOR_DEFAULT',
        uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the duplicate entity
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateConstructorName = CompileTimeErrorTemplate(
    name: 'DUPLICATE_CONSTRUCTOR',
    problemMessage: "The constructor with name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the constructors.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_NAME',
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME',
    withArguments: _withArgumentsDuplicateConstructorName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the duplicate entity
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateDefinition = CompileTimeErrorTemplate(
    name: 'DUPLICATE_DEFINITION',
    problemMessage: "The name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the declarations.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_DEFINITION',
    withArguments: _withArgumentsDuplicateDefinition,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldFormalParameter = CompileTimeErrorTemplate(
    name: 'DUPLICATE_FIELD_FORMAL_PARAMETER',
    problemMessage:
        "The field '{0}' can't be initialized by multiple parameters in the same "
        "constructor.",
    correctionMessage:
        "Try removing one of the parameters, or using different fields.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER',
    withArguments: _withArgumentsDuplicateFieldFormalParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the duplicated name
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldName = CompileTimeErrorTemplate(
    name: 'DUPLICATE_FIELD_NAME',
    problemMessage: "The field name '{0}' is already used in this record.",
    correctionMessage: "Try renaming the field.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_FIELD_NAME',
    withArguments: _withArgumentsDuplicateFieldName,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the parameter that was duplicated
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateNamedArgument = CompileTimeErrorTemplate(
    name: 'DUPLICATE_NAMED_ARGUMENT',
    problemMessage:
        "The argument for the named parameter '{0}' was already specified.",
    correctionMessage:
        "Try removing one of the named arguments, or correcting one of the "
        "names to reference a different named parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT',
    withArguments: _withArgumentsDuplicateNamedArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Uri p0: the URI of the duplicate part
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Uri p0})
  >
  duplicatePart = CompileTimeErrorTemplate(
    name: 'DUPLICATE_PART',
    problemMessage: "The library already contains a part with the URI '{0}'.",
    correctionMessage:
        "Try removing all except one of the duplicated part directives.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_PART',
    withArguments: _withArgumentsDuplicatePart,
    expectedTypes: [ExpectedType.uri],
  );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternAssignmentVariable = CompileTimeErrorTemplate(
    name: 'DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE',
    problemMessage: "The variable '{0}' is already assigned in this pattern.",
    correctionMessage: "Try renaming the variable.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE',
    withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternField = CompileTimeErrorTemplate(
    name: 'DUPLICATE_PATTERN_FIELD',
    problemMessage: "The field '{0}' is already matched in this pattern.",
    correctionMessage: "Try removing the duplicate field.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD',
    withArguments: _withArgumentsDuplicatePatternField,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments duplicateRestElementInPattern =
      CompileTimeErrorWithoutArguments(
        name: 'DUPLICATE_REST_ELEMENT_IN_PATTERN',
        problemMessage:
            "At most one rest element is allowed in a list or map pattern.",
        correctionMessage: "Try removing the duplicate rest element.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.DUPLICATE_REST_ELEMENT_IN_PATTERN',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateVariablePattern = CompileTimeErrorTemplate(
    name: 'DUPLICATE_VARIABLE_PATTERN',
    problemMessage: "The variable '{0}' is already defined in this pattern.",
    correctionMessage: "Try renaming the variable.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN',
    withArguments: _withArgumentsDuplicateVariablePattern,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments emptyMapPattern =
      CompileTimeErrorWithoutArguments(
        name: 'EMPTY_MAP_PATTERN',
        problemMessage: "A map pattern must have at least one entry.",
        correctionMessage: "Try replacing it with an object pattern 'Map()'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EMPTY_MAP_PATTERN',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumConstantInvokesFactoryConstructor = CompileTimeErrorWithoutArguments(
    name: 'ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR',
    problemMessage: "An enum value can't invoke a factory constructor.",
    correctionMessage: "Try using a generative constructor.",
    uniqueNameCheck:
        'CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumConstantSameNameAsEnclosing = CompileTimeErrorWithoutArguments(
    name: 'ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
    problemMessage:
        "The name of the enum value can't be the same as the enum's name.",
    correctionMessage: "Try renaming the constant.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumInstantiatedToBoundsIsNotWellBounded = CompileTimeErrorWithoutArguments(
    name: 'ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
    problemMessage:
        "The result of instantiating the enum to bounds is not well-bounded.",
    correctionMessage: "Try using different bounds for type parameters.",
    uniqueNameCheck:
        'CompileTimeErrorCode.ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumMixinWithInstanceVariable = CompileTimeErrorWithoutArguments(
    name: 'ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
    problemMessage: "Mixins applied to enums can't have instance variables.",
    correctionMessage: "Try replacing the instance variables with getters.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing enum
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  enumWithAbstractMember = CompileTimeErrorTemplate(
    name: 'ENUM_WITH_ABSTRACT_MEMBER',
    problemMessage: "'{0}' must have a method body because '{1}' is an enum.",
    correctionMessage: "Try adding a body to '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER',
    withArguments: _withArgumentsEnumWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments enumWithNameValues =
      CompileTimeErrorWithoutArguments(
        name: 'ENUM_WITH_NAME_VALUES',
        problemMessage: "The name 'values' is not a valid name for an enum.",
        correctionMessage: "Try using a different name.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.ENUM_WITH_NAME_VALUES',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments enumWithoutConstants =
      CompileTimeErrorWithoutArguments(
        name: 'ENUM_WITHOUT_CONSTANTS',
        problemMessage: "The enum must have at least one enum constant.",
        correctionMessage: "Try declaring an enum constant.",
        uniqueNameCheck: 'CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalElementsInConstSet =
      CompileTimeErrorWithoutArguments(
        name: 'EQUAL_ELEMENTS_IN_CONST_SET',
        problemMessage:
            "Two elements in a constant set literal can't be equal.",
        correctionMessage: "Change or remove the duplicate element.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalKeysInConstMap =
      CompileTimeErrorWithoutArguments(
        name: 'EQUAL_KEYS_IN_CONST_MAP',
        problemMessage: "Two keys in a constant map literal can't be equal.",
        correctionMessage: "Change or remove the duplicate key.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalKeysInMapPattern =
      CompileTimeErrorWithoutArguments(
        name: 'EQUAL_KEYS_IN_MAP_PATTERN',
        problemMessage: "Two keys in a map pattern can't be equal.",
        correctionMessage: "Change or remove the duplicate key.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EQUAL_KEYS_IN_MAP_PATTERN',
        expectedTypes: [],
      );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListPatternTypeArguments = CompileTimeErrorTemplate(
    name: 'EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS',
    problemMessage:
        "List patterns require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS',
    withArguments: _withArgumentsExpectedOneListPatternTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListTypeArguments = CompileTimeErrorTemplate(
    name: 'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
    problemMessage:
        "List literals require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
    withArguments: _withArgumentsExpectedOneListTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneSetTypeArguments = CompileTimeErrorTemplate(
    name: 'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
    problemMessage:
        "Set literals require one type argument or none, but {0} were found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS',
    withArguments: _withArgumentsExpectedOneSetTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapPatternTypeArguments = CompileTimeErrorTemplate(
    name: 'EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS',
    problemMessage:
        "Map patterns require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS',
    withArguments: _withArgumentsExpectedTwoMapPatternTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapTypeArguments = CompileTimeErrorTemplate(
    name: 'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
    problemMessage:
        "Map literals require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
    withArguments: _withArgumentsExpectedTwoMapTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  exportInternalLibrary = CompileTimeErrorTemplate(
    name: 'EXPORT_INTERNAL_LIBRARY',
    problemMessage: "The library '{0}' is internal and can't be exported.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY',
    withArguments: _withArgumentsExportInternalLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  exportOfNonLibrary = CompileTimeErrorTemplate(
    name: 'EXPORT_OF_NON_LIBRARY',
    problemMessage:
        "The exported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try exporting the library that the part is a part of.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY',
    withArguments: _withArgumentsExportOfNonLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments expressionInMap =
      CompileTimeErrorWithoutArguments(
        name: 'EXPRESSION_IN_MAP',
        problemMessage: "Expressions can't be used in a map literal.",
        correctionMessage:
            "Try removing the expression or converting it to be a map entry.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EXPRESSION_IN_MAP',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extendsDeferredClass =
      CompileTimeErrorWithoutArguments(
        name: 'SUBTYPE_OF_DEFERRED_CLASS',
        problemMessage: "Classes can't extend deferred classes.",
        correctionMessage:
            "Try specifying a different superclass, or removing the extends "
            "clause.",
        hasPublishedDocs: true,
        uniqueName: 'EXTENDS_DEFERRED_CLASS',
        uniqueNameCheck: 'CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  extendsDisallowedClass = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_DISALLOWED_TYPE',
    problemMessage: "Classes can't extend '{0}'.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DISALLOWED_CLASS',
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS',
    withArguments: _withArgumentsExtendsDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extendsNonClass =
      CompileTimeErrorWithoutArguments(
        name: 'EXTENDS_NON_CLASS',
        problemMessage: "Classes can only extend other classes.",
        correctionMessage:
            "Try specifying a different superclass, or removing the extends "
            "clause.",
        hasPublishedDocs: true,
        isUnresolvedIdentifier: true,
        uniqueNameCheck: 'CompileTimeErrorCode.EXTENDS_NON_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extendsTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "A type alias that expands to a type parameter can't be used as a "
        "superclass.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the extension
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  extensionAsExpression = CompileTimeErrorTemplate(
    name: 'EXTENSION_AS_EXPRESSION',
    problemMessage: "Extension '{0}' can't be used as an expression.",
    correctionMessage: "Try replacing it with a valid expression.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_AS_EXPRESSION',
    withArguments: _withArgumentsExtensionAsExpression,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the conflicting static member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  extensionConflictingStaticAndInstance = CompileTimeErrorTemplate(
    name: 'EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
    problemMessage:
        "An extension can't define static member '{0}' and an instance member with "
        "the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
    withArguments: _withArgumentsExtensionConflictingStaticAndInstance,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extensionDeclaresInstanceField =
      CompileTimeErrorWithoutArguments(
        name: 'EXTENSION_DECLARES_INSTANCE_FIELD',
        problemMessage: "Extensions can't declare instance fields.",
        correctionMessage: "Try replacing the field with a getter.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionDeclaresMemberOfObject = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_DECLARES_MEMBER_OF_OBJECT',
    problemMessage:
        "Extensions can't declare members with the same name as a member declared "
        "by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionOverrideAccessToStaticMember = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
    problemMessage:
        "An extension override can't be used to access a static member from an "
        "extension.",
    correctionMessage: "Try using just the name of the extension.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the argument
  /// Type p1: the extended type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionOverrideArgumentNotAssignable = CompileTimeErrorTemplate(
    name: 'EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
    problemMessage:
        "The type of the argument to the extension override '{0}' isn't assignable "
        "to the extended type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
    withArguments: _withArgumentsExtensionOverrideArgumentNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionOverrideWithCascade = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_OVERRIDE_WITH_CASCADE',
    problemMessage:
        "Extension overrides have no value so they can't be used as the receiver "
        "of a cascade expression.",
    correctionMessage: "Try using '.' instead of '..'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionOverrideWithoutAccess = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_OVERRIDE_WITHOUT_ACCESS',
    problemMessage:
        "An extension override can only be used to access instance members.",
    correctionMessage: "Consider adding an access to an instance member.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_WITHOUT_ACCESS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeConstructorWithSuperFormalParameter =
      CompileTimeErrorWithoutArguments(
        name: 'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER',
        problemMessage:
            "Extension type constructors can't declare super formal parameters.",
        correctionMessage:
            "Try removing the super formal parameter declaration.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeConstructorWithSuperInvocation = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION',
    problemMessage:
        "Extension type constructors can't include super initializers.",
    correctionMessage: "Try removing the super constructor invocation.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeDeclaresInstanceField = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_DECLARES_INSTANCE_FIELD',
    problemMessage: "Extension types can't declare instance fields.",
    correctionMessage: "Try replacing the field with a getter.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeDeclaresMemberOfObject = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT',
    problemMessage:
        "Extension types can't declare members with the same name as a member "
        "declared by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the display string of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  extensionTypeImplementsDisallowedType = CompileTimeErrorTemplate(
    name: 'EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE',
    problemMessage: "Extension types can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE',
    withArguments: _withArgumentsExtensionTypeImplementsDisallowedType,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeImplementsItself = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_IMPLEMENTS_ITSELF',
    problemMessage: "The extension type can't implement itself.",
    correctionMessage:
        "Try removing the superinterface that references this extension type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the implemented not extension type
  /// Type p1: the ultimate representation type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionTypeImplementsNotSupertype = CompileTimeErrorTemplate(
    name: 'EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE',
    problemMessage:
        "'{0}' is not a supertype of '{1}', the representation type.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE',
    withArguments: _withArgumentsExtensionTypeImplementsNotSupertype,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the representation type of the implemented extension type
  /// String p1: the name of the implemented extension type
  /// Type p2: the representation type of the this extension type
  /// String p3: the name of the this extension type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
      required String p3,
    })
  >
  extensionTypeImplementsRepresentationNotSupertype = CompileTimeErrorTemplate(
    name: 'EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE',
    problemMessage:
        "'{0}', the representation type of '{1}', is not a supertype of '{2}', the "
        "representation type of '{3}'.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE',
    withArguments:
        _withArgumentsExtensionTypeImplementsRepresentationNotSupertype,
    expectedTypes: [
      ExpectedType.type,
      ExpectedType.string,
      ExpectedType.type,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the extension type
  /// String p1: the name of the conflicting member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  extensionTypeInheritedMemberConflict = CompileTimeErrorTemplate(
    name: 'EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT',
    problemMessage:
        "The extension type '{0}' has more than one distinct member named '{1}' "
        "from implemented types.",
    correctionMessage:
        "Try redeclaring the corresponding member in this extension type.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT',
    withArguments: _withArgumentsExtensionTypeInheritedMemberConflict,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeRepresentationDependsOnItself = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF',
    problemMessage: "The extension type representation can't depend on itself.",
    correctionMessage: "Try specifying a different type.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeRepresentationTypeBottom = CompileTimeErrorWithoutArguments(
    name: 'EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM',
    problemMessage: "The representation type can't be a bottom type.",
    correctionMessage: "Try specifying a different type.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing extension type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  extensionTypeWithAbstractMember = CompileTimeErrorTemplate(
    name: 'EXTENSION_TYPE_WITH_ABSTRACT_MEMBER',
    problemMessage:
        "'{0}' must have a method body because '{1}' is an extension type.",
    correctionMessage: "Try adding a body to '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER',
    withArguments: _withArgumentsExtensionTypeWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  externalFieldConstructorInitializer = CompileTimeErrorWithoutArguments(
    name: 'EXTERNAL_WITH_INITIALIZER',
    problemMessage: "External fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'external' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments externalFieldInitializer =
      CompileTimeErrorWithoutArguments(
        name: 'EXTERNAL_WITH_INITIALIZER',
        problemMessage: "External fields can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'external' keyword.",
        hasPublishedDocs: true,
        uniqueName: 'EXTERNAL_FIELD_INITIALIZER',
        uniqueNameCheck: 'CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments externalVariableInitializer =
      CompileTimeErrorWithoutArguments(
        name: 'EXTERNAL_WITH_INITIALIZER',
        problemMessage: "External variables can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'external' keyword.",
        hasPublishedDocs: true,
        uniqueName: 'EXTERNAL_VARIABLE_INITIALIZER',
        uniqueNameCheck: 'CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER',
        expectedTypes: [],
      );

  /// Parameters:
  /// int p0: the maximum number of positional arguments
  /// int p1: the actual number of positional arguments given
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  extraPositionalArguments = CompileTimeErrorTemplate(
    name: 'EXTRA_POSITIONAL_ARGUMENTS',
    problemMessage:
        "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage: "Try removing the extra arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS',
    withArguments: _withArgumentsExtraPositionalArguments,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the maximum number of positional arguments
  /// int p1: the actual number of positional arguments given
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  extraPositionalArgumentsCouldBeNamed = CompileTimeErrorTemplate(
    name: 'EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
    problemMessage:
        "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage:
        "Try removing the extra positional arguments, or specifying the name "
        "for named arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
    withArguments: _withArgumentsExtraPositionalArgumentsCouldBeNamed,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the field being initialized multiple times
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  fieldInitializedByMultipleInitializers = CompileTimeErrorTemplate(
    name: 'FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
    problemMessage:
        "The field '{0}' can't be initialized twice in the same constructor.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
    withArguments: _withArgumentsFieldInitializedByMultipleInitializers,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializedInInitializerAndDeclaration = CompileTimeErrorWithoutArguments(
    name: 'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
    problemMessage:
        "Fields can't be initialized in the constructor if they are final and were "
        "already initialized at their declaration.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializedInParameterAndInitializer = CompileTimeErrorWithoutArguments(
    name: 'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
    problemMessage:
        "Fields can't be initialized in both the parameter list and the "
        "initializers.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerFactoryConstructor = CompileTimeErrorWithoutArguments(
    name: 'FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
    problemMessage:
        "Initializing formal parameters can't be used in factory constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializerNotAssignable = CompileTimeErrorTemplate(
    name: 'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    problemMessage:
        "The initializer type '{0}' can't be assigned to the field type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE',
    withArguments: _withArgumentsFieldInitializerNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerOutsideConstructor = CompileTimeErrorWithoutArguments(
    name: 'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    problemMessage:
        "Field formal parameters can only be used in a constructor.",
    correctionMessage: "Try removing 'this.'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerRedirectingConstructor = CompileTimeErrorWithoutArguments(
    name: 'FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
    problemMessage:
        "The redirecting constructor can't have a field initializer.",
    correctionMessage:
        "Try initializing the field in the constructor being redirected to.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the type of the field formal parameter
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializingFormalNotAssignable = CompileTimeErrorTemplate(
    name: 'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
    problemMessage:
        "The parameter type '{0}' is incompatible with the field type '{1}'.",
    correctionMessage:
        "Try changing or removing the parameter's type, or changing the "
        "field's type.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
    withArguments: _withArgumentsFieldInitializingFormalNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the final class being extended.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassExtendedOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be extended outside of its library because it's a "
        "final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the final class being implemented.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be implemented outside of its library because it's "
        "a final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the final class being used as a mixin superclass
  ///            constraint.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassUsedAsMixinConstraintOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be used as a mixin superclass constraint outside of "
        "its library because it's a final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY',
    withArguments:
        _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the field in question
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalInitializedInDeclarationAndConstructor = CompileTimeErrorTemplate(
    name: 'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
    problemMessage:
        "'{0}' is final and was given a value when it was declared, so it can't be "
        "set to a new value.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
    withArguments: _withArgumentsFinalInitializedInDeclarationAndConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitialized = CompileTimeErrorTemplate(
    name: 'FINAL_NOT_INITIALIZED',
    problemMessage: "The final variable '{0}' must be initialized.",
    correctionMessage: "Try initializing the variable.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED',
    withArguments: _withArgumentsFinalNotInitialized,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitializedConstructor1 = CompileTimeErrorTemplate(
    name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    problemMessage: "All final variables must be initialized, but '{0}' isn't.",
    correctionMessage: "Try adding an initializer for the field.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
    uniqueNameCheck: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
    withArguments: _withArgumentsFinalNotInitializedConstructor1,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  /// String p1: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  finalNotInitializedConstructor2 = CompileTimeErrorTemplate(
    name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    problemMessage:
        "All final variables must be initialized, but '{0}' and '{1}' aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
    uniqueNameCheck: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
    withArguments: _withArgumentsFinalNotInitializedConstructor2,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  /// String p1: the name of the uninitialized final variable
  /// int p2: the number of additional not initialized variables that aren't
  ///         listed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required int p2,
    })
  >
  finalNotInitializedConstructor3Plus = CompileTimeErrorTemplate(
    name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    problemMessage:
        "All final variables must be initialized, but '{0}', '{1}', and {2} others "
        "aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
    uniqueNameCheck:
        'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
    withArguments: _withArgumentsFinalNotInitializedConstructor3Plus,
    expectedTypes: [ExpectedType.string, ExpectedType.string, ExpectedType.int],
  );

  /// Parameters:
  /// Type p0: the type of the iterable expression.
  /// String p1: the sequence type -- Iterable for `for` or Stream for `await
  ///            for`.
  /// Type p2: the loop variable type.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
    })
  >
  forInOfInvalidElementType = CompileTimeErrorTemplate(
    name: 'FOR_IN_OF_INVALID_ELEMENT_TYPE',
    problemMessage:
        "The type '{0}' used in the 'for' loop must implement '{1}' with a type "
        "argument that can be assigned to '{2}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE',
    withArguments: _withArgumentsForInOfInvalidElementType,
    expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the type of the iterable expression.
  /// String p1: the sequence type -- Iterable for `for` or Stream for `await
  ///            for`.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  forInOfInvalidType = CompileTimeErrorTemplate(
    name: 'FOR_IN_OF_INVALID_TYPE',
    problemMessage:
        "The type '{0}' used in the 'for' loop must implement '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE',
    withArguments: _withArgumentsForInOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments forInWithConstVariable =
      CompileTimeErrorWithoutArguments(
        name: 'FOR_IN_WITH_CONST_VARIABLE',
        problemMessage: "A for-in loop variable can't be a 'const'.",
        correctionMessage:
            "Try removing the 'const' modifier from the variable, or use a "
            "different variable.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE',
        expectedTypes: [],
      );

  /// It is a compile-time error if a generic function type is used as a bound
  /// for a formal type parameter of a class or a function.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericFunctionTypeCannotBeBound = CompileTimeErrorWithoutArguments(
    name: 'GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
    problemMessage:
        "Generic function types can't be used as type parameter bounds.",
    correctionMessage:
        "Try making the free variable in the function type part of the larger "
        "declaration signature.",
    uniqueNameCheck:
        'CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
    expectedTypes: [],
  );

  /// It is a compile-time error if a generic function type is used as an actual
  /// type argument.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericFunctionTypeCannotBeTypeArgument = CompileTimeErrorWithoutArguments(
    name: 'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
    problemMessage: "A generic function type can't be a type argument.",
    correctionMessage:
        "Try removing type parameters from the generic function type, or using "
        "'dynamic' as the type argument here.",
    uniqueNameCheck:
        'CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericMethodTypeInstantiationOnDynamic = CompileTimeErrorWithoutArguments(
    name: 'GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
    problemMessage:
        "A method tear-off on a receiver whose type is 'dynamic' can't have type "
        "arguments.",
    correctionMessage:
        "Specify the type of the receiver, or remove the type arguments from "
        "the method tear-off.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the getter
  /// Object p1: the type of the getter
  /// Object p2: the type of the setter
  /// Object p3: the name of the setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  getterNotAssignableSetterTypes = CompileTimeErrorTemplate(
    name: 'GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
    problemMessage:
        "The return type of getter '{0}' is '{1}' which isn't assignable to the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
    uniqueNameCheck: 'CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
    withArguments: _withArgumentsGetterNotAssignableSetterTypes,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// Parameters:
  /// Object p0: the name of the getter
  /// Object p1: the type of the getter
  /// Object p2: the type of the setter
  /// Object p3: the name of the setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  getterNotSubtypeSetterTypes = CompileTimeErrorTemplate(
    name: 'GETTER_NOT_SUBTYPE_SETTER_TYPES',
    problemMessage:
        "The return type of getter '{0}' is '{1}' which isn't a subtype of the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES',
    withArguments: _withArgumentsGetterNotSubtypeSetterTypes,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  ifElementConditionFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as values in an if "
        "condition inside a const collection literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
    uniqueNameCheck:
        'CompileTimeErrorCode.IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalAsyncGeneratorReturnType = CompileTimeErrorWithoutArguments(
    name: 'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
    problemMessage:
        "Functions marked 'async*' must have a return type that is a supertype of "
        "'Stream<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async*' from the function body.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalAsyncReturnType = CompileTimeErrorWithoutArguments(
    name: 'ILLEGAL_ASYNC_RETURN_TYPE',
    problemMessage:
        "Functions marked 'async' must have a return type which is a supertype of "
        "'Future'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async' from the function body.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of member that cannot be declared
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalConcreteEnumMemberDeclaration = CompileTimeErrorTemplate(
    name: 'ILLEGAL_CONCRETE_ENUM_MEMBER',
    problemMessage:
        "A concrete instance member named '{0}' can't be declared in a class that "
        "implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION',
    uniqueNameCheck:
        'CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION',
    withArguments: _withArgumentsIllegalConcreteEnumMemberDeclaration,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of member that cannot be inherited
  /// String p1: the name of the class that declares the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  illegalConcreteEnumMemberInheritance = CompileTimeErrorTemplate(
    name: 'ILLEGAL_CONCRETE_ENUM_MEMBER',
    problemMessage:
        "A concrete instance member named '{0}' can't be inherited from '{1}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE',
    uniqueNameCheck:
        'CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE',
    withArguments: _withArgumentsIllegalConcreteEnumMemberInheritance,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalEnumValuesDeclaration = CompileTimeErrorWithoutArguments(
    name: 'ILLEGAL_ENUM_VALUES',
    problemMessage:
        "An instance member named 'values' can't be declared in a class that "
        "implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_ENUM_VALUES_DECLARATION',
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the class that declares 'values'
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalEnumValuesInheritance = CompileTimeErrorTemplate(
    name: 'ILLEGAL_ENUM_VALUES',
    problemMessage:
        "An instance member named 'values' can't be inherited from '{0}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_ENUM_VALUES_INHERITANCE',
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE',
    withArguments: _withArgumentsIllegalEnumValuesInheritance,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the required language version
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalLanguageVersionOverride = CompileTimeErrorTemplate(
    name: 'ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
    problemMessage: "The language version must be {0}.",
    correctionMessage:
        "Try removing the language version override and migrating the code.",
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
    withArguments: _withArgumentsIllegalLanguageVersionOverride,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalSyncGeneratorReturnType = CompileTimeErrorWithoutArguments(
    name: 'ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
    problemMessage:
        "Functions marked 'sync*' must have a return type that is a supertype of "
        "'Iterable<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'sync*' from the function body.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments implementsDeferredClass =
      CompileTimeErrorWithoutArguments(
        name: 'SUBTYPE_OF_DEFERRED_CLASS',
        problemMessage: "Classes and mixins can't implement deferred classes.",
        correctionMessage:
            "Try specifying a different interface, removing the class from the "
            "list, or changing the import to not be deferred.",
        hasPublishedDocs: true,
        uniqueName: 'IMPLEMENTS_DEFERRED_CLASS',
        uniqueNameCheck: 'CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  implementsDisallowedClass = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_DISALLOWED_TYPE',
    problemMessage: "Classes and mixins can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different interface, or remove the class from the "
        "list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DISALLOWED_CLASS',
    uniqueNameCheck: 'CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS',
    withArguments: _withArgumentsImplementsDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  implementsNonClass = CompileTimeErrorWithoutArguments(
    name: 'IMPLEMENTS_NON_CLASS',
    problemMessage:
        "Classes and mixins can only implement other classes and mixins.",
    correctionMessage:
        "Try specifying a class or mixin, or remove the name from the list.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.IMPLEMENTS_NON_CLASS',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  implementsRepeated = CompileTimeErrorTemplate(
    name: 'IMPLEMENTS_REPEATED',
    problemMessage: "'{0}' can only be implemented once.",
    correctionMessage: "Try removing all but one occurrence of the class name.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.IMPLEMENTS_REPEATED',
    withArguments: _withArgumentsImplementsRepeated,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Element p0: the name of the class that appears in both "extends" and
  ///             "implements" clauses
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Element p0})
  >
  implementsSuperClass = CompileTimeErrorTemplate(
    name: 'IMPLEMENTS_SUPER_CLASS',
    problemMessage:
        "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS',
    withArguments: _withArgumentsImplementsSuperClass,
    expectedTypes: [ExpectedType.element],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  implementsTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "A type alias that expands to a type parameter can't be implemented.",
    correctionMessage: "Try specifying a class or mixin, or removing the list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    uniqueNameCheck:
        'CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  implicitSuperInitializerMissingArguments = CompileTimeErrorTemplate(
    name: 'IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
    problemMessage:
        "The implicitly invoked unnamed constructor from '{0}' has required "
        "parameters.",
    correctionMessage:
        "Try adding an explicit super parameter with the required arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
    withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the instance member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  implicitThisReferenceInInitializer = CompileTimeErrorTemplate(
    name: 'IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
    problemMessage:
        "The instance member '{0}' can't be accessed in an initializer.",
    correctionMessage:
        "Try replacing the reference to the instance member with a different "
        "expression",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
    withArguments: _withArgumentsImplicitThisReferenceInInitializer,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  importInternalLibrary = CompileTimeErrorTemplate(
    name: 'IMPORT_INTERNAL_LIBRARY',
    problemMessage: "The library '{0}' is internal and can't be imported.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY',
    withArguments: _withArgumentsImportInternalLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  importOfNonLibrary = CompileTimeErrorTemplate(
    name: 'IMPORT_OF_NON_LIBRARY',
    problemMessage:
        "The imported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try importing the library that the part is a part of.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY',
    withArguments: _withArgumentsImportOfNonLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// 13.9 Switch: It is a compile-time error if values of the expressions
  /// <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
  /// <i>1 &lt;= k &lt;= n</i>.
  ///
  /// Parameters:
  /// Object p0: the expression source code that is the unexpected type
  /// Object p1: the name of the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  inconsistentCaseExpressionTypes = CompileTimeErrorTemplate(
    name: 'INCONSISTENT_CASE_EXPRESSION_TYPES',
    problemMessage:
        "Case expressions must have the same types, '{0}' isn't a '{1}'.",
    uniqueNameCheck: 'CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES',
    withArguments: _withArgumentsInconsistentCaseExpressionTypes,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the instance member with inconsistent inheritance.
  /// String p1: the list of all inherited signatures for this member.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  inconsistentInheritance = CompileTimeErrorTemplate(
    name: 'INCONSISTENT_INHERITANCE',
    problemMessage:
        "Superinterfaces don't have a valid override for '{0}': {1}.",
    correctionMessage:
        "Try adding an explicit override that is consistent with all of the "
        "inherited members.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INCONSISTENT_INHERITANCE',
    withArguments: _withArgumentsInconsistentInheritance,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 11.1.1 Inheritance and Overriding. Let `I` be the implicit interface of a
  /// class `C` declared in library `L`. `I` inherits all members of
  /// `inherited(I, L)` and `I` overrides `m'` if `m' ∈ overrides(I, L)`. It is
  /// a compile-time error if `m` is a method and `m'` is a getter, or if `m`
  /// is a getter and `m'` is a method.
  ///
  /// Parameters:
  /// String p0: the name of the instance member with inconsistent inheritance.
  /// String p1: the name of the superinterface that declares the name as a
  ///            getter.
  /// String p2: the name of the superinterface that declares the name as a
  ///            method.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  inconsistentInheritanceGetterAndMethod = CompileTimeErrorTemplate(
    name: 'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
    problemMessage:
        "'{0}' is inherited as a getter (from '{1}') and also a method (from "
        "'{2}').",
    correctionMessage:
        "Try adjusting the supertypes of this class to remove the "
        "inconsistency.",
    uniqueNameCheck:
        'CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
    withArguments: _withArgumentsInconsistentInheritanceGetterAndMethod,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  inconsistentLanguageVersionOverride = CompileTimeErrorWithoutArguments(
    name: 'INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "Parts must have exactly the same language version override as the "
        "library.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inconsistentPatternVariableLogicalOr = CompileTimeErrorTemplate(
    name: 'INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR',
    problemMessage:
        "The variable '{0}' has a different type and/or finality in this branch of "
        "the logical-or pattern.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "both branches.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR',
    withArguments: _withArgumentsInconsistentPatternVariableLogicalOr,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the initializing formal that is not an instance
  ///            variable in the immediately enclosing class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  initializerForNonExistentField = CompileTimeErrorTemplate(
    name: 'INITIALIZER_FOR_NON_EXISTENT_FIELD',
    problemMessage: "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD',
    withArguments: _withArgumentsInitializerForNonExistentField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the initializing formal that is a static variable
  ///            in the immediately enclosing class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  initializerForStaticField = CompileTimeErrorTemplate(
    name: 'INITIALIZER_FOR_STATIC_FIELD',
    problemMessage:
        "'{0}' is a static field in the enclosing class. Fields initialized in a "
        "constructor can't be static.",
    correctionMessage: "Try removing the initialization.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD',
    withArguments: _withArgumentsInitializerForStaticField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the initializing formal that is not an instance
  ///            variable in the immediately enclosing class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  initializingFormalForNonExistentField = CompileTimeErrorTemplate(
    name: 'INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
    problemMessage: "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
    withArguments: _withArgumentsInitializingFormalForNonExistentField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the static member
  /// String p1: the kind of the static member (field, getter, setter, or
  ///            method)
  /// String p2: the name of the static member's enclosing element
  /// String p3: the kind of the static member's enclosing element (class,
  ///            mixin, or extension)
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  instanceAccessToStaticMember = CompileTimeErrorTemplate(
    name: 'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    problemMessage:
        "The static {1} '{0}' can't be accessed through an instance.",
    correctionMessage: "Try using the {3} '{2}' to access the {1}.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER',
    withArguments: _withArgumentsInstanceAccessToStaticMember,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// Object p0: the name of the static member
  /// Object p1: the kind of the static member (field, getter, setter, or
  ///            method)
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  instanceAccessToStaticMemberOfUnnamedExtension = CompileTimeErrorTemplate(
    name: 'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    problemMessage:
        "The static {1} '{0}' can't be accessed through an instance.",
    hasPublishedDocs: true,
    uniqueName: 'INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
    uniqueNameCheck:
        'CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
    withArguments: _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instanceMemberAccessFromFactory = CompileTimeErrorWithoutArguments(
    name: 'INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
    problemMessage:
        "Instance members can't be accessed from a factory constructor.",
    correctionMessage: "Try removing the reference to the instance member.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instanceMemberAccessFromStatic = CompileTimeErrorWithoutArguments(
    name: 'INSTANCE_MEMBER_ACCESS_FROM_STATIC',
    problemMessage: "Instance members can't be accessed from a static method.",
    correctionMessage:
        "Try removing the reference to the instance member, or removing the "
        "keyword 'static' from the method.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments instantiateAbstractClass =
      CompileTimeErrorWithoutArguments(
        name: 'INSTANTIATE_ABSTRACT_CLASS',
        problemMessage: "Abstract classes can't be instantiated.",
        correctionMessage: "Try creating an instance of a concrete subtype.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments instantiateEnum =
      CompileTimeErrorWithoutArguments(
        name: 'INSTANTIATE_ENUM',
        problemMessage: "Enums can't be instantiated.",
        correctionMessage: "Try using one of the defined constants.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.INSTANTIATE_ENUM',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instantiateTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "Type aliases that expand to a type parameter can't be instantiated.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the lexeme of the integer
  /// String p1: the closest valid double
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  integerLiteralImpreciseAsDouble = CompileTimeErrorTemplate(
    name: 'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
    problemMessage:
        "The integer literal is being used as a double, but can't be represented "
        "as a 64-bit double without overflow or loss of precision: '{0}'.",
    correctionMessage:
        "Try using the class 'BigInt', or switch to the closest valid double: "
        "'{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
    withArguments: _withArgumentsIntegerLiteralImpreciseAsDouble,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the value of the literal
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  integerLiteralOutOfRange = CompileTimeErrorTemplate(
    name: 'INTEGER_LITERAL_OUT_OF_RANGE',
    problemMessage: "The integer literal {0} can't be represented in 64 bits.",
    correctionMessage:
        "Try using the 'BigInt' class if you need an integer larger than "
        "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE',
    withArguments: _withArgumentsIntegerLiteralOutOfRange,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the interface class being extended.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  interfaceClassExtendedOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be extended outside of its library because it's an "
        "interface class.",
    hasPublishedDocs: true,
    uniqueName: 'INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotation = CompileTimeErrorWithoutArguments(
    name: 'INVALID_ANNOTATION',
    problemMessage:
        "Annotation must be either a const variable reference or const constructor "
        "invocation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotationConstantValueFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used in annotations.",
    correctionMessage:
        "Try moving the constant from the deferred library, or removing "
        "'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotationFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as annotations.",
    correctionMessage:
        "Try removing the annotation, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the right hand side type
  /// Type p1: the name of the left hand side type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  invalidAssignment = CompileTimeErrorTemplate(
    name: 'INVALID_ASSIGNMENT',
    problemMessage:
        "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
    correctionMessage:
        "Try changing the type of the variable, or casting the right-hand type "
        "to '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_ASSIGNMENT',
    withArguments: _withArgumentsInvalidAssignment,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the name of the function
  /// Object p1: the type of the function
  /// Object p2: the expected function type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastFunction = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_FUNCTION',
    problemMessage:
        "The function '{0}' has type '{1}' that isn't of expected type '{2}'. This "
        "means its parameter or return type doesn't match what is expected.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_FUNCTION',
    withArguments: _withArgumentsInvalidCastFunction,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the torn-off function expression
  /// Object p1: the expected function type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastFunctionExpr = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_FUNCTION_EXPR',
    problemMessage:
        "The function expression type '{0}' isn't of type '{1}'. This means its "
        "parameter or return type doesn't match what is expected. Consider "
        "changing parameter type(s) or the returned type(s).",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR',
    withArguments: _withArgumentsInvalidCastFunctionExpr,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the lexeme of the literal
  /// Object p1: the type of the literal
  /// Object p2: the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastLiteral = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_LITERAL',
    problemMessage:
        "The literal '{0}' with type '{1}' isn't of expected type '{2}'.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_LITERAL',
    withArguments: _withArgumentsInvalidCastLiteral,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the list literal
  /// Object p1: the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralList = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_LITERAL_LIST',
    problemMessage:
        "The list literal type '{0}' isn't of expected type '{1}'. The list's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST',
    withArguments: _withArgumentsInvalidCastLiteralList,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the map literal
  /// Object p1: the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralMap = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_LITERAL_MAP',
    problemMessage:
        "The map literal type '{0}' isn't of expected type '{1}'. The map's type "
        "can be changed with an explicit generic type arguments or by changing "
        "the key and value types.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP',
    withArguments: _withArgumentsInvalidCastLiteralMap,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the set literal
  /// Object p1: the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastLiteralSet = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_LITERAL_SET',
    problemMessage:
        "The set literal type '{0}' isn't of expected type '{1}'. The set's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_SET',
    withArguments: _withArgumentsInvalidCastLiteralSet,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the name of the torn-off method
  /// Object p1: the type of the torn-off method
  /// Object p2: the expected function type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidCastMethod = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_METHOD',
    problemMessage:
        "The method tear-off '{0}' has type '{1}' that isn't of expected type "
        "'{2}'. This means its parameter or return type doesn't match what is "
        "expected.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_METHOD',
    withArguments: _withArgumentsInvalidCastMethod,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// This error is only reported in libraries which are not null safe.
  ///
  /// Parameters:
  /// Object p0: the type of the instantiated object
  /// Object p1: the expected type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidCastNewExpr = CompileTimeErrorTemplate(
    name: 'INVALID_CAST_NEW_EXPR',
    problemMessage:
        "The constructor returns type '{0}' that isn't of expected type '{1}'.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CAST_NEW_EXPR',
    withArguments: _withArgumentsInvalidCastNewExpr,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// TODO(brianwilkerson): Remove this when we have decided on how to report
  /// errors in compile-time constants. Until then, this acts as a placeholder
  /// for more informative errors.
  ///
  /// See TODOs in ConstantVisitor
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidConstant =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_CONSTANT',
        problemMessage: "Invalid constant value.",
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_CONSTANT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidExtensionArgumentCount = CompileTimeErrorWithoutArguments(
    name: 'INVALID_EXTENSION_ARGUMENT_COUNT',
    problemMessage:
        "Extension overrides must have exactly one argument: the value of 'this' "
        "in the extension method.",
    correctionMessage: "Try specifying exactly one argument.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidFactoryNameNotAClass = CompileTimeErrorWithoutArguments(
    name: 'INVALID_FACTORY_NAME_NOT_A_CLASS',
    problemMessage:
        "The name of a factory constructor must be the same as the name of the "
        "immediately enclosing class.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidFieldNameFromObject =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_FIELD_NAME',
        problemMessage:
            "Record field names can't be the same as a member from 'Object'.",
        correctionMessage: "Try using a different name for the field.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_FIELD_NAME_FROM_OBJECT',
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidFieldNamePositional = CompileTimeErrorWithoutArguments(
    name: 'INVALID_FIELD_NAME',
    problemMessage:
        "Record field names can't be a dollar sign followed by an integer when the "
        "integer is the index of a positional field.",
    correctionMessage: "Try using a different name for the field.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_FIELD_NAME_POSITIONAL',
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidFieldNamePrivate =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_FIELD_NAME',
        problemMessage: "Record field names can't be private.",
        correctionMessage: "Try removing the leading underscore.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_FIELD_NAME_PRIVATE',
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE',
        expectedTypes: [],
      );

  /// The parameters of this error code must be kept in sync with those of
  /// [CompileTimeErrorCode.invalidOverride].
  ///
  /// Parameters:
  /// Object p0: the name of the declared member that is not a valid override.
  /// Object p1: the name of the interface that declares the member.
  /// Object p2: the type of the declared member in the interface.
  /// Object p3: the name of the interface with the overridden member.
  /// Object p4: the type of the overridden member.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidImplementationOverride = CompileTimeErrorTemplate(
    name: 'INVALID_IMPLEMENTATION_OVERRIDE',
    problemMessage:
        "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' "
        "('{4}').",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE',
    withArguments: _withArgumentsInvalidImplementationOverride,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// The parameters of this error code must be kept in sync with those of
  /// [CompileTimeErrorCode.invalidOverride].
  ///
  /// Parameters:
  /// Object p0: the name of the declared setter that is not a valid override.
  /// Object p1: the name of the interface that declares the setter.
  /// Object p2: the type of the declared setter in the interface.
  /// Object p3: the name of the interface with the overridden setter.
  /// Object p4: the type of the overridden setter.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidImplementationOverrideSetter = CompileTimeErrorTemplate(
    name: 'INVALID_IMPLEMENTATION_OVERRIDE',
    problemMessage:
        "The setter '{1}.{0}' ('{2}') isn't a valid concrete implementation of "
        "'{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_IMPLEMENTATION_OVERRIDE_SETTER',
    uniqueNameCheck:
        'CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE_SETTER',
    withArguments: _withArgumentsInvalidImplementationOverrideSetter,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidInlineFunctionType = CompileTimeErrorWithoutArguments(
    name: 'INVALID_INLINE_FUNCTION_TYPE',
    problemMessage:
        "Inline function types can't be used for parameters in a generic function "
        "type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the invalid modifier
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidModifierOnConstructor = CompileTimeErrorTemplate(
    name: 'INVALID_MODIFIER_ON_CONSTRUCTOR',
    problemMessage:
        "The modifier '{0}' can't be applied to the body of a constructor.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR',
    withArguments: _withArgumentsInvalidModifierOnConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidModifierOnSetter =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_MODIFIER_ON_SETTER',
        problemMessage: "Setters can't use 'async', 'async*', or 'sync*'.",
        correctionMessage: "Try removing the modifier.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the declared member that is not a valid override.
  /// String p1: the name of the interface that declares the member.
  /// Type p2: the type of the declared member in the interface.
  /// String p3: the name of the interface with the overridden member.
  /// Type p4: the type of the overridden member.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required DartType p2,
      required String p3,
      required DartType p4,
    })
  >
  invalidOverride = CompileTimeErrorTemplate(
    name: 'INVALID_OVERRIDE',
    problemMessage:
        "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_OVERRIDE',
    withArguments: _withArgumentsInvalidOverride,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.type,
      ExpectedType.string,
      ExpectedType.type,
    ],
  );

  /// Parameters:
  /// Object p0: the name of the declared setter that is not a valid override.
  /// Object p1: the name of the interface that declares the setter.
  /// Object p2: the type of the declared setter in the interface.
  /// Object p3: the name of the interface with the overridden setter.
  /// Object p4: the type of the overridden setter.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
      required Object p4,
    })
  >
  invalidOverrideSetter = CompileTimeErrorTemplate(
    name: 'INVALID_OVERRIDE',
    problemMessage:
        "The setter '{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_OVERRIDE_SETTER',
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_OVERRIDE_SETTER',
    withArguments: _withArgumentsInvalidOverrideSetter,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidReferenceToGenerativeEnumConstructor = CompileTimeErrorWithoutArguments(
    name: 'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
    problemMessage:
        "Generative enum constructors can only be used to create an enum constant.",
    correctionMessage: "Try using an enum value, or a factory constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidReferenceToGenerativeEnumConstructorTearoff =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
        problemMessage: "Generative enum constructors can't be torn off.",
        correctionMessage: "Try using an enum value, or a factory constructor.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR_TEAROFF',
        uniqueNameCheck:
            'CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR_TEAROFF',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidReferenceToThis =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_REFERENCE_TO_THIS',
        problemMessage: "Invalid reference to 'this' expression.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidSuperFormalParameterLocation = CompileTimeErrorWithoutArguments(
    name: 'INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
    problemMessage:
        "Super parameters can only be used in non-redirecting generative "
        "constructors.",
    correctionMessage:
        "Try removing the 'super' modifier, or changing the constructor to be "
        "non-redirecting and generative.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstList = CompileTimeErrorTemplate(
    name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    problemMessage:
        "Constant list literals can't use a type parameter in a type argument, "
        "such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
    withArguments: _withArgumentsInvalidTypeArgumentInConstList,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstMap = CompileTimeErrorTemplate(
    name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    problemMessage:
        "Constant map literals can't use a type parameter in a type argument, such "
        "as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
    withArguments: _withArgumentsInvalidTypeArgumentInConstMap,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidTypeArgumentInConstSet = CompileTimeErrorTemplate(
    name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    problemMessage:
        "Constant set literals can't use a type parameter in a type argument, such "
        "as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_SET',
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET',
    withArguments: _withArgumentsInvalidTypeArgumentInConstSet,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUri = CompileTimeErrorTemplate(
    name: 'INVALID_URI',
    problemMessage: "Invalid URI syntax: '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_URI',
    withArguments: _withArgumentsInvalidUri,
    expectedTypes: [ExpectedType.string],
  );

  /// The 'covariant' keyword was found in an inappropriate location.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidUseOfCovariant = CompileTimeErrorWithoutArguments(
    name: 'INVALID_USE_OF_COVARIANT',
    problemMessage:
        "The 'covariant' keyword can only be used for parameters in instance "
        "methods or before non-final instance fields.",
    correctionMessage: "Try removing the 'covariant' keyword.",
    uniqueNameCheck: 'CompileTimeErrorCode.INVALID_USE_OF_COVARIANT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidUseOfNullValue =
      CompileTimeErrorWithoutArguments(
        name: 'INVALID_USE_OF_NULL_VALUE',
        problemMessage:
            "An expression whose value is always 'null' can't be dereferenced.",
        correctionMessage: "Try changing the type of the expression.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the extension
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfExtensionWithoutCall = CompileTimeErrorTemplate(
    name: 'INVOCATION_OF_EXTENSION_WITHOUT_CALL',
    problemMessage:
        "The extension '{0}' doesn't define a 'call' method so the override can't "
        "be used in an invocation.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL',
    withArguments: _withArgumentsInvocationOfExtensionWithoutCall,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the identifier that is not a function type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfNonFunction = CompileTimeErrorTemplate(
    name: 'INVOCATION_OF_NON_FUNCTION',
    problemMessage: "'{0}' isn't a function.",
    correctionMessage:
        "Try correcting the name to match an existing function, or define a "
        "method or function named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION',
    withArguments: _withArgumentsInvocationOfNonFunction,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invocationOfNonFunctionExpression = CompileTimeErrorWithoutArguments(
    name: 'INVOCATION_OF_NON_FUNCTION_EXPRESSION',
    problemMessage:
        "The expression doesn't evaluate to a function, so it can't be invoked.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  labelInOuterScope = CompileTimeErrorTemplate(
    name: 'LABEL_IN_OUTER_SCOPE',
    problemMessage: "Can't reference label '{0}' declared in an outer method.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE',
    withArguments: _withArgumentsLabelInOuterScope,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  labelUndefined = CompileTimeErrorTemplate(
    name: 'LABEL_UNDEFINED',
    problemMessage: "Can't reference an undefined label '{0}'.",
    correctionMessage:
        "Try defining the label, or correcting the name to match an existing "
        "label.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.LABEL_UNDEFINED',
    withArguments: _withArgumentsLabelUndefined,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  lateFinalFieldWithConstConstructor = CompileTimeErrorWithoutArguments(
    name: 'LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
    problemMessage:
        "Can't have a late final field in a class with a generative const "
        "constructor.",
    correctionMessage:
        "Try removing the 'late' modifier, or don't declare 'const' "
        "constructors.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments lateFinalLocalAlreadyAssigned =
      CompileTimeErrorWithoutArguments(
        name: 'LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
        problemMessage: "The late final local variable is already assigned.",
        correctionMessage:
            "Try removing the 'final' modifier, or don't reassign the value.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the actual type of the list element
  /// Type p1: the expected type of the list element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  listElementTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsListElementTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the actual type of the list element
  /// Type p1: the expected type of the list element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  listElementTypeNotAssignableNullability = CompileTimeErrorTemplate(
    name: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    uniqueNameCheck:
        'CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsListElementTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mainFirstPositionalParameterType = CompileTimeErrorWithoutArguments(
    name: 'MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
    problemMessage:
        "The type of the first positional parameter of the 'main' function must be "
        "a supertype of 'List<String>'.",
    correctionMessage: "Try changing the type of the parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mainHasRequiredNamedParameters =
      CompileTimeErrorWithoutArguments(
        name: 'MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
        problemMessage:
            "The function 'main' can't have any required named parameters.",
        correctionMessage:
            "Try using a different name for the function, or removing the "
            "'required' modifier.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mainHasTooManyRequiredPositionalParameters = CompileTimeErrorWithoutArguments(
    name: 'MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
    problemMessage:
        "The function 'main' can't have more than two required positional "
        "parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing extra "
        "parameters.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mainIsNotFunction =
      CompileTimeErrorWithoutArguments(
        name: 'MAIN_IS_NOT_FUNCTION',
        problemMessage: "The declaration named 'main' must be a function.",
        correctionMessage: "Try using a different name for this declaration.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mapEntryNotInMap =
      CompileTimeErrorWithoutArguments(
        name: 'MAP_ENTRY_NOT_IN_MAP',
        problemMessage: "Map entries can only be used in a map literal.",
        correctionMessage:
            "Try converting the collection to a map or removing the map entry.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type of the expression being used as a key
  /// Type p1: the type of keys declared for the map
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapKeyTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsMapKeyTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the type of the expression being used as a key
  /// Type p1: the type of keys declared for the map
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapKeyTypeNotAssignableNullability = CompileTimeErrorTemplate(
    name: 'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'MAP_KEY_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    uniqueNameCheck:
        'CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsMapKeyTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the type of the expression being used as a value
  /// Type p1: the type of values declared for the map
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapValueTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsMapValueTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the type of the expression being used as a value
  /// Type p1: the type of values declared for the map
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapValueTypeNotAssignableNullability = CompileTimeErrorTemplate(
    name: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    uniqueNameCheck:
        'CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsMapValueTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// 12.1 Constants: A constant expression is ... a constant list literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments missingConstInListLiteral =
      CompileTimeErrorWithoutArguments(
        name: 'MISSING_CONST_IN_LIST_LITERAL',
        problemMessage:
            "Seeing this message constitutes a bug. Please report it.",
        uniqueNameCheck: 'CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL',
        expectedTypes: [],
      );

  /// 12.1 Constants: A constant expression is ... a constant map literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments missingConstInMapLiteral =
      CompileTimeErrorWithoutArguments(
        name: 'MISSING_CONST_IN_MAP_LITERAL',
        problemMessage:
            "Seeing this message constitutes a bug. Please report it.",
        uniqueNameCheck: 'CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL',
        expectedTypes: [],
      );

  /// 12.1 Constants: A constant expression is ... a constant set literal.
  ///
  /// Note: This diagnostic is never displayed to the user, so it doesn't need
  /// to be documented.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments missingConstInSetLiteral =
      CompileTimeErrorWithoutArguments(
        name: 'MISSING_CONST_IN_SET_LITERAL',
        problemMessage:
            "Seeing this message constitutes a bug. Please report it.",
        uniqueNameCheck: 'CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingDartLibrary = CompileTimeErrorTemplate(
    name: 'MISSING_DART_LIBRARY',
    problemMessage: "Required library '{0}' is missing.",
    correctionMessage: "Re-install the Dart or Flutter SDK.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MISSING_DART_LIBRARY',
    withArguments: _withArgumentsMissingDartLibrary,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameter = CompileTimeErrorTemplate(
    name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    problemMessage:
        "The parameter '{0}' can't have a value of 'null' because of its type, but "
        "the implicit default value is 'null'.",
    correctionMessage:
        "Try adding either an explicit non-'null' default value or the "
        "'required' modifier.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    withArguments: _withArgumentsMissingDefaultValueForParameter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameterPositional = CompileTimeErrorTemplate(
    name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    problemMessage:
        "The parameter '{0}' can't have a value of 'null' because of its type, but "
        "the implicit default value is 'null'.",
    correctionMessage: "Try adding an explicit non-'null' default value.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL',
    uniqueNameCheck:
        'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL',
    withArguments: _withArgumentsMissingDefaultValueForParameterPositional,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  missingDefaultValueForParameterWithAnnotation = CompileTimeErrorWithoutArguments(
    name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    problemMessage:
        "With null safety, use the 'required' keyword, not the '@required' "
        "annotation.",
    correctionMessage: "Try removing the '@'.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION',
    uniqueNameCheck:
        'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  missingNamedPatternFieldName = CompileTimeErrorWithoutArguments(
    name: 'MISSING_NAMED_PATTERN_FIELD_NAME',
    problemMessage:
        "The getter name is not specified explicitly, and the pattern is not a "
        "variable.",
    correctionMessage:
        "Try specifying the getter name explicitly, or using a variable "
        "pattern.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MISSING_NAMED_PATTERN_FIELD_NAME',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingRequiredArgument = CompileTimeErrorTemplate(
    name: 'MISSING_REQUIRED_ARGUMENT',
    problemMessage:
        "The named parameter '{0}' is required, but there's no corresponding "
        "argument.",
    correctionMessage: "Try adding the required argument.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT',
    withArguments: _withArgumentsMissingRequiredArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable pattern
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingVariablePattern = CompileTimeErrorTemplate(
    name: 'MISSING_VARIABLE_PATTERN',
    problemMessage:
        "Variable pattern '{0}' is missing in this branch of the logical-or "
        "pattern.",
    correctionMessage: "Try declaring this variable pattern in the branch.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MISSING_VARIABLE_PATTERN',
    withArguments: _withArgumentsMissingVariablePattern,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the super-invoked member
  /// Type p1: the display name of the type of the super-invoked member in the
  ///          mixin
  /// Type p2: the display name of the type of the concrete member in the class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required DartType p1,
      required DartType p2,
    })
  >
  mixinApplicationConcreteSuperInvokedMemberType = CompileTimeErrorTemplate(
    name: 'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
    problemMessage:
        "The super-invoked member '{0}' has the type '{1}', and the concrete "
        "member in the class has the type '{2}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
    withArguments: _withArgumentsMixinApplicationConcreteSuperInvokedMemberType,
    expectedTypes: [ExpectedType.string, ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the display name of the member without a concrete
  ///            implementation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinApplicationNoConcreteSuperInvokedMember = CompileTimeErrorTemplate(
    name: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    problemMessage:
        "The class doesn't have a concrete implementation of the super-invoked "
        "member '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the display name of the setter without a concrete
  ///            implementation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinApplicationNoConcreteSuperInvokedSetter = CompileTimeErrorTemplate(
    name: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    problemMessage:
        "The class doesn't have a concrete implementation of the super-invoked "
        "setter '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_SETTER',
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_SETTER',
    withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the display name of the mixin
  /// Type p1: the display name of the superclass
  /// Type p2: the display name of the type that is not implemented
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required DartType p2,
    })
  >
  mixinApplicationNotImplementedInterface = CompileTimeErrorTemplate(
    name: 'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
    problemMessage:
        "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
    correctionMessage: "Try extending the class '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
    withArguments: _withArgumentsMixinApplicationNotImplementedInterface,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the mixin class that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclarationExtendsNotObject = CompileTimeErrorTemplate(
    name: 'MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT',
    problemMessage:
        "The class '{0}' can't be declared a mixin because it extends a class "
        "other than 'Object'.",
    correctionMessage:
        "Try removing the 'mixin' modifier or changing the superclass to "
        "'Object'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT',
    withArguments: _withArgumentsMixinClassDeclarationExtendsNotObject,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclaresConstructor = CompileTimeErrorTemplate(
    name: 'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
    problemMessage:
        "The class '{0}' can't be used as a mixin because it declares a "
        "constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR',
    withArguments: _withArgumentsMixinClassDeclaresConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinDeferredClass =
      CompileTimeErrorWithoutArguments(
        name: 'SUBTYPE_OF_DEFERRED_CLASS',
        problemMessage: "Classes can't mixin deferred classes.",
        correctionMessage: "Try changing the import to not be deferred.",
        hasPublishedDocs: true,
        uniqueName: 'MIXIN_DEFERRED_CLASS',
        uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinInheritsFromNotObject = CompileTimeErrorTemplate(
    name: 'MIXIN_INHERITS_FROM_NOT_OBJECT',
    problemMessage:
        "The class '{0}' can't be used as a mixin because it extends a class other "
        "than 'Object'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT',
    withArguments: _withArgumentsMixinInheritsFromNotObject,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinInstantiate =
      CompileTimeErrorWithoutArguments(
        name: 'MIXIN_INSTANTIATE',
        problemMessage: "Mixins can't be instantiated.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_INSTANTIATE',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinOfDisallowedClass = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_DISALLOWED_TYPE',
    problemMessage: "Classes can't mixin '{0}'.",
    correctionMessage:
        "Try specifying a different class or mixin, or remove the class or "
        "mixin from the list.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_DISALLOWED_CLASS',
    uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS',
    withArguments: _withArgumentsMixinOfDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinOfNonClass =
      CompileTimeErrorWithoutArguments(
        name: 'MIXIN_OF_NON_CLASS',
        problemMessage: "Classes can only mix in mixins and classes.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_OF_NON_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinOfTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "A type alias that expands to a type parameter can't be mixed in.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinOnTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "A type alias that expands to a type parameter can't be used as a "
        "superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Element p0: the name of the class that appears in both "extends" and
  ///             "with" clauses
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Element p0})
  >
  mixinsSuperClass = CompileTimeErrorTemplate(
    name: 'IMPLEMENTS_SUPER_CLASS',
    problemMessage:
        "'{0}' can't be used in both the 'extends' and 'with' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
    uniqueName: 'MIXINS_SUPER_CLASS',
    uniqueNameCheck: 'CompileTimeErrorCode.MIXINS_SUPER_CLASS',
    withArguments: _withArgumentsMixinsSuperClass,
    expectedTypes: [ExpectedType.element],
  );

  /// Parameters:
  /// String p0: the name of the mixin that is not 'base'
  /// String p1: the name of the 'base' supertype
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  mixinSubtypeOfBaseIsNotBase = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    problemMessage:
        "The mixin '{0}' must be 'base' because the supertype '{1}' is 'base'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE',
    uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE',
    withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the mixin that is not 'final'
  /// String p1: the name of the 'final' supertype
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  mixinSubtypeOfFinalIsNotBase = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    problemMessage:
        "The mixin '{0}' must be 'base' because the supertype '{1}' is 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE',
    uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE',
    withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinSuperClassConstraintDeferredClass = CompileTimeErrorWithoutArguments(
    name: 'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
    problemMessage: "Deferred classes can't be used as superclass constraints.",
    correctionMessage: "Try changing the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinSuperClassConstraintDisallowedClass = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_DISALLOWED_TYPE',
    problemMessage: "'{0}' can't be used as a superclass constraint.",
    correctionMessage:
        "Try specifying a different super-class constraint, or remove the 'on' "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
    withArguments: _withArgumentsMixinSuperClassConstraintDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinSuperClassConstraintNonInterface = CompileTimeErrorWithoutArguments(
    name: 'MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
    problemMessage:
        "Only classes and mixins can be used as superclass constraints.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
    expectedTypes: [],
  );

  /// 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
  /// denote a class available in the immediately enclosing scope.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinWithNonClassSuperclass =
      CompileTimeErrorWithoutArguments(
        name: 'MIXIN_WITH_NON_CLASS_SUPERCLASS',
        problemMessage: "Mixin can only be applied to class.",
        uniqueNameCheck: 'CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  multipleRedirectingConstructorInvocations = CompileTimeErrorWithoutArguments(
    name: 'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
    problemMessage:
        "Constructors can have only one 'this' redirection, at most.",
    correctionMessage: "Try removing all but one of the redirections.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  multipleSuperInitializers = CompileTimeErrorWithoutArguments(
    name: 'MULTIPLE_SUPER_INITIALIZERS',
    problemMessage: "A constructor can have at most one 'super' initializer.",
    correctionMessage: "Try removing all but one of the 'super' initializers.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  newWithNonType = CompileTimeErrorTemplate(
    name: 'CREATION_WITH_NON_TYPE',
    problemMessage: "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'NEW_WITH_NON_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.NEW_WITH_NON_TYPE',
    withArguments: _withArgumentsNewWithNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// 12.11.1 New: If <i>T</i> is a class or parameterized type accessible in the
  /// current scope then:
  /// 1. If <i>e</i> is of the form <i>new T.id(a<sub>1</sub>, &hellip;,
  ///    a<sub>n</sub>, x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;,
  ///    x<sub>n+k</sub>: a<sub>n+k</sub>)</i> it is a static warning if
  ///    <i>T.id</i> is not the name of a constructor declared by the type
  ///    <i>T</i>.
  /// If <i>e</i> of the form <i>new T(a<sub>1</sub>, &hellip;, a<sub>n</sub>,
  /// x<sub>n+1</sub>: a<sub>n+1</sub>, &hellip;, x<sub>n+k</sub>:
  /// a<sub>n+kM/sub>)</i> it is a static warning if the type <i>T</i> does not
  /// declare a constructor with the same name as the declaration of <i>T</i>.
  ///
  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  newWithUndefinedConstructor = CompileTimeErrorTemplate(
    name: 'NEW_WITH_UNDEFINED_CONSTRUCTOR',
    problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or define a constructor named "
        "'{1}'.",
    uniqueNameCheck: 'CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR',
    withArguments: _withArgumentsNewWithUndefinedConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class being instantiated
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  newWithUndefinedConstructorDefault = CompileTimeErrorTemplate(
    name: 'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try using one of the named constructors defined in '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    withArguments: _withArgumentsNewWithUndefinedConstructorDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  noAnnotationConstructorArguments = CompileTimeErrorWithoutArguments(
    name: 'NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
    problemMessage: "Annotation creation must have arguments.",
    correctionMessage: "Try adding an empty argument list.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the class where override error was detected
  /// String p1: the list of candidate signatures which cannot be combined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  noCombinedSuperSignature = CompileTimeErrorTemplate(
    name: 'NO_COMBINED_SUPER_SIGNATURE',
    problemMessage:
        "Can't infer missing types in '{0}' from overridden methods: {1}.",
    correctionMessage:
        "Try providing explicit types for this method's parameters and return "
        "type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE',
    withArguments: _withArgumentsNoCombinedSuperSignature,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the superclass that does not define an implicitly
  ///            invoked constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  noDefaultSuperConstructorExplicit = CompileTimeErrorTemplate(
    name: 'NO_DEFAULT_SUPER_CONSTRUCTOR',
    problemMessage:
        "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or explicitly "
        "invoking a different constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
    uniqueNameCheck:
        'CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
    withArguments: _withArgumentsNoDefaultSuperConstructorExplicit,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Type p0: the name of the superclass that does not define an implicitly
  ///          invoked constructor
  /// String p1: the name of the subclass that does not contain any explicit
  ///            constructors
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  noDefaultSuperConstructorImplicit = CompileTimeErrorTemplate(
    name: 'NO_DEFAULT_SUPER_CONSTRUCTOR',
    problemMessage:
        "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or declaring a "
        "constructor in {1} that explicitly invokes a constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
    uniqueNameCheck:
        'CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
    withArguments: _withArgumentsNoDefaultSuperConstructorImplicit,
    expectedTypes: [ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the subclass
  /// String p1: the name of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  noGenerativeConstructorsInSuperclass = CompileTimeErrorTemplate(
    name: 'NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
    problemMessage:
        "The class '{0}' can't extend '{1}' because '{1}' only has factory "
        "constructors (no generative constructors), and '{0}' has at least one "
        "generative constructor.",
    correctionMessage:
        "Try implementing the class instead, adding a generative (not factory) "
        "constructor to the superclass '{1}', or a factory constructor to the "
        "subclass.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
    withArguments: _withArgumentsNoGenerativeConstructorsInSuperclass,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  /// String p3: the name of the fourth member
  /// int p4: the number of additional missing members that aren't listed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
      required int p4,
    })
  >
  nonAbstractClassInheritsAbstractMemberFivePlus = CompileTimeErrorTemplate(
    name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    problemMessage:
        "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} "
        "more.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberFivePlus,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.int,
    ],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  /// String p3: the name of the fourth member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  nonAbstractClassInheritsAbstractMemberFour = CompileTimeErrorTemplate(
    name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    problemMessage:
        "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberFour,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonAbstractClassInheritsAbstractMemberOne = CompileTimeErrorTemplate(
    name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    problemMessage: "Missing concrete implementation of '{0}'.",
    correctionMessage:
        "Try implementing the missing method, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberOne,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the name of the third member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  nonAbstractClassInheritsAbstractMemberThree = CompileTimeErrorTemplate(
    name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    problemMessage:
        "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberThree,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  nonAbstractClassInheritsAbstractMemberTwo = CompileTimeErrorTemplate(
    name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    problemMessage: "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberTwo,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolCondition =
      CompileTimeErrorWithoutArguments(
        name: 'NON_BOOL_CONDITION',
        problemMessage: "Conditions must have a static type of 'bool'.",
        correctionMessage: "Try changing the condition.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_BOOL_CONDITION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolExpression =
      CompileTimeErrorWithoutArguments(
        name: 'NON_BOOL_EXPRESSION',
        problemMessage: "The expression in an assert must be of type 'bool'.",
        correctionMessage: "Try changing the expression.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_BOOL_EXPRESSION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolNegationExpression =
      CompileTimeErrorWithoutArguments(
        name: 'NON_BOOL_NEGATION_EXPRESSION',
        problemMessage: "A negation operand must have a static type of 'bool'.",
        correctionMessage: "Try changing the operand to the '!' operator.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the lexeme of the logical operator
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonBoolOperand = CompileTimeErrorTemplate(
    name: 'NON_BOOL_OPERAND',
    problemMessage:
        "The operands of the operator '{0}' must be assignable to 'bool'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_BOOL_OPERAND',
    withArguments: _withArgumentsNonBoolOperand,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantAnnotationConstructor = CompileTimeErrorWithoutArguments(
    name: 'NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
    problemMessage: "Annotation creation can only call a const constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantCaseExpression =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_CASE_EXPRESSION',
        problemMessage: "Case expressions must be constant.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantCaseExpressionFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as a case "
        "expression.",
    correctionMessage:
        "Try re-writing the switch as a series of if statements, or changing "
        "the import to not be deferred.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantDefaultValue =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_DEFAULT_VALUE',
        problemMessage:
            "The default value of an optional parameter must be constant.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantDefaultValueFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as a default "
        "parameter value.",
    correctionMessage:
        "Try leaving the default as 'null' and initializing the parameter "
        "inside the function body.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantListElement =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_LIST_ELEMENT',
        problemMessage: "The values in a const list literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the list literal.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantListElementFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as values in a "
        "'const' list literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal or removing "
        "the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapElement =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_MAP_ELEMENT',
        problemMessage: "The elements in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapKey =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_MAP_KEY',
        problemMessage: "The keys in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_MAP_KEY',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantMapKeyFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as keys in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapPatternKey =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_MAP_PATTERN_KEY',
        problemMessage: "Key expressions in map patterns must be constants.",
        correctionMessage: "Try using constants instead.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapValue =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_MAP_VALUE',
        problemMessage: "The values in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantMapValueFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as values in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantRecordField =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_RECORD_FIELD',
        problemMessage:
            "The fields in a const record literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the record literal.",
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantRecordFieldFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as fields in a "
        "'const' record literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the record literal or removing "
        "the keyword 'deferred' from the import.",
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantRelationalPatternExpression = CompileTimeErrorWithoutArguments(
    name: 'NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION',
    problemMessage: "The relational pattern expression must be a constant.",
    correctionMessage: "Try using a constant instead.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantSetElement =
      CompileTimeErrorWithoutArguments(
        name: 'NON_CONSTANT_SET_ELEMENT',
        problemMessage: "The values in a const set literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the set literal.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstGenerativeEnumConstructor = CompileTimeErrorWithoutArguments(
    name: 'NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
    problemMessage: "Generative enum constructors must be 'const'.",
    correctionMessage: "Try adding the keyword 'const'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// 13.2 Expression Statements: It is a compile-time error if a non-constant
  /// map literal that has no explicit type arguments appears in a place where a
  /// statement is expected.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstMapAsExpressionStatement = CompileTimeErrorWithoutArguments(
    name: 'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
    problemMessage:
        "A non-constant map or set literal without type arguments can't be used as "
        "an expression statement.",
    uniqueNameCheck:
        'CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonCovariantTypeParameterPositionInRepresentationType =
      CompileTimeErrorWithoutArguments(
        name: 'NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE',
        problemMessage:
            "An extension type parameter can't be used in a non-covariant position of "
            "its representation type.",
        correctionMessage:
            "Try removing the type parameters from function parameter types and "
            "type parameter bounds.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type of the switch scrutinee
  /// String p1: the witness pattern for the unmatched value
  /// String p2: the suggested pattern for the unmatched value
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required String p2,
    })
  >
  nonExhaustiveSwitchExpression = CompileTimeErrorTemplate(
    name: 'NON_EXHAUSTIVE_SWITCH_EXPRESSION',
    problemMessage:
        "The type '{0}' isn't exhaustively matched by the switch cases since it "
        "doesn't match the pattern '{1}'.",
    correctionMessage:
        "Try adding a wildcard pattern or cases that match '{2}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION',
    withArguments: _withArgumentsNonExhaustiveSwitchExpression,
    expectedTypes: [
      ExpectedType.type,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// Type p0: the type of the switch scrutinee
  /// String p1: the witness pattern for the unmatched value
  /// String p2: the suggested pattern for the unmatched value
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required String p2,
    })
  >
  nonExhaustiveSwitchStatement = CompileTimeErrorTemplate(
    name: 'NON_EXHAUSTIVE_SWITCH_STATEMENT',
    problemMessage:
        "The type '{0}' isn't exhaustively matched by the switch cases since it "
        "doesn't match the pattern '{1}'.",
    correctionMessage: "Try adding a default case or cases that match '{2}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT',
    withArguments: _withArgumentsNonExhaustiveSwitchStatement,
    expectedTypes: [
      ExpectedType.type,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonFinalFieldInEnum =
      CompileTimeErrorWithoutArguments(
        name: 'NON_FINAL_FIELD_IN_ENUM',
        problemMessage: "Enums can only declare final fields.",
        correctionMessage: "Try making the field final.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM',
        expectedTypes: [],
      );

  /// Parameters:
  /// Element p0: the non-generative constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Element p0})
  >
  nonGenerativeConstructor = CompileTimeErrorTemplate(
    name: 'NON_GENERATIVE_CONSTRUCTOR',
    problemMessage:
        "The generative constructor '{0}' is expected, but a factory was found.",
    correctionMessage:
        "Try calling a different constructor of the superclass, or making the "
        "called constructor not be a factory constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR',
    withArguments: _withArgumentsNonGenerativeConstructor,
    expectedTypes: [ExpectedType.element],
  );

  /// Parameters:
  /// String p0: the name of the superclass
  /// String p1: the name of the current class
  /// Element p2: the implicitly called factory constructor of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required Element p2,
    })
  >
  nonGenerativeImplicitConstructor = CompileTimeErrorTemplate(
    name: 'NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
    problemMessage:
        "The unnamed constructor of superclass '{0}' (called by the default "
        "constructor of '{1}') must be a generative constructor, but factory "
        "found.",
    correctionMessage:
        "Try adding an explicit constructor that has a different "
        "superinitializer or changing the superclass constructor '{2}' to not "
        "be a factory constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
    withArguments: _withArgumentsNonGenerativeImplicitConstructor,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.element,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonSyncFactory =
      CompileTimeErrorWithoutArguments(
        name: 'NON_SYNC_FACTORY',
        problemMessage:
            "Factory bodies can't use 'async', 'async*', or 'sync*'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_SYNC_FACTORY',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name appearing where a type is expected
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeAsTypeArgument = CompileTimeErrorTemplate(
    name: 'NON_TYPE_AS_TYPE_ARGUMENT',
    problemMessage:
        "The name '{0}' isn't a type, so it can't be used as a type argument.",
    correctionMessage:
        "Try correcting the name to an existing type, or defining a type named "
        "'{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT',
    withArguments: _withArgumentsNonTypeAsTypeArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeInCatchClause = CompileTimeErrorTemplate(
    name: 'NON_TYPE_IN_CATCH_CLAUSE',
    problemMessage:
        "The name '{0}' isn't a type and can't be used in an on-catch clause.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE',
    withArguments: _withArgumentsNonTypeInCatchClause,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonVoidReturnForOperator =
      CompileTimeErrorWithoutArguments(
        name: 'NON_VOID_RETURN_FOR_OPERATOR',
        problemMessage: "The return type of the operator []= must be 'void'.",
        correctionMessage: "Try changing the return type to 'void'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonVoidReturnForSetter =
      CompileTimeErrorWithoutArguments(
        name: 'NON_VOID_RETURN_FOR_SETTER',
        problemMessage:
            "The return type of the setter must be 'void' or absent.",
        correctionMessage:
            "Try removing the return type, or define a method rather than a "
            "setter.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notAssignedPotentiallyNonNullableLocalVariable = CompileTimeErrorTemplate(
    name: 'NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
    problemMessage:
        "The non-nullable local variable '{0}' must be assigned before it can be "
        "used.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned "
        "on every execution path.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
    withArguments: _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name that is not a type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notAType = CompileTimeErrorTemplate(
    name: 'NOT_A_TYPE',
    problemMessage: "{0} isn't a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NOT_A_TYPE',
    withArguments: _withArgumentsNotAType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator that is not a binary operator.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notBinaryOperator = CompileTimeErrorTemplate(
    name: 'NOT_BINARY_OPERATOR',
    problemMessage: "'{0}' isn't a binary operator.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NOT_BINARY_OPERATOR',
    withArguments: _withArgumentsNotBinaryOperator,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// int p0: the expected number of required arguments
  /// int p1: the actual number of positional arguments given
  /// String p2: name of the function or method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required int p0,
      required int p1,
      required String p2,
    })
  >
  notEnoughPositionalArgumentsNamePlural = CompileTimeErrorTemplate(
    name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    problemMessage:
        "{0} positional arguments expected by '{2}', but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL',
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL',
    withArguments: _withArgumentsNotEnoughPositionalArgumentsNamePlural,
    expectedTypes: [ExpectedType.int, ExpectedType.int, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: name of the function or method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notEnoughPositionalArgumentsNameSingular = CompileTimeErrorTemplate(
    name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    problemMessage: "1 positional argument expected by '{0}', but 0 found.",
    correctionMessage: "Try adding the missing argument.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR',
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR',
    withArguments: _withArgumentsNotEnoughPositionalArgumentsNameSingular,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// int p0: the expected number of required arguments
  /// int p1: the actual number of positional arguments given
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  notEnoughPositionalArgumentsPlural = CompileTimeErrorTemplate(
    name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    problemMessage: "{0} positional arguments expected, but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL',
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL',
    withArguments: _withArgumentsNotEnoughPositionalArgumentsPlural,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  notEnoughPositionalArgumentsSingular = CompileTimeErrorWithoutArguments(
    name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    problemMessage: "1 positional argument expected, but 0 found.",
    correctionMessage: "Try adding the missing argument.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR',
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceField = CompileTimeErrorTemplate(
    name: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    problemMessage: "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or a generative constructor "
        "that initializes it, or mark it 'late'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    withArguments: _withArgumentsNotInitializedNonNullableInstanceField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceFieldConstructor = CompileTimeErrorTemplate(
    name: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    problemMessage: "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or add a field initializer in "
        "this constructor, or mark it 'late'.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
    withArguments:
        _withArgumentsNotInitializedNonNullableInstanceFieldConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableVariable = CompileTimeErrorTemplate(
    name: 'NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
    problemMessage: "The non-nullable variable '{0}' must be initialized.",
    correctionMessage: "Try adding an initializer expression.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
    withArguments: _withArgumentsNotInitializedNonNullableVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notInstantiatedBound =
      CompileTimeErrorWithoutArguments(
        name: 'NOT_INSTANTIATED_BOUND',
        problemMessage: "Type parameter bound types must be instantiated.",
        correctionMessage:
            "Try adding type arguments to the type parameter bound.",
        uniqueNameCheck: 'CompileTimeErrorCode.NOT_INSTANTIATED_BOUND',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  notIterableSpread = CompileTimeErrorWithoutArguments(
    name: 'NOT_ITERABLE_SPREAD',
    problemMessage:
        "Spread elements in list or set literals must implement 'Iterable'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NOT_ITERABLE_SPREAD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notMapSpread =
      CompileTimeErrorWithoutArguments(
        name: 'NOT_MAP_SPREAD',
        problemMessage: "Spread elements in map literals must implement 'Map'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NOT_MAP_SPREAD',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  notNullAwareNullSpread = CompileTimeErrorWithoutArguments(
    name: 'NOT_NULL_AWARE_NULL_SPREAD',
    problemMessage:
        "The Null-typed expression can't be used with a non-null-aware spread.",
    uniqueNameCheck: 'CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInExtendsClause =
      CompileTimeErrorWithoutArguments(
        name: 'NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
        problemMessage: "A class can't extend a nullable type.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nullableTypeInImplementsClause = CompileTimeErrorWithoutArguments(
    name: 'NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
    problemMessage:
        "A class, mixin, or extension type can't implement a nullable type.",
    correctionMessage: "Try removing the question mark.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInOnClause =
      CompileTimeErrorWithoutArguments(
        name: 'NULLABLE_TYPE_IN_ON_CLAUSE',
        problemMessage:
            "A mixin can't have a nullable type as a superclass constraint.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInWithClause =
      CompileTimeErrorWithoutArguments(
        name: 'NULLABLE_TYPE_IN_WITH_CLAUSE',
        problemMessage: "A class or mixin can't mix in a nullable type.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE',
        expectedTypes: [],
      );

  /// 7.9 Superclasses: It is a compile-time error to specify an extends clause
  /// for class Object.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments objectCannotExtendAnotherClass =
      CompileTimeErrorWithoutArguments(
        name: 'OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
        problemMessage: "The class 'Object' can't extend any other class.",
        uniqueNameCheck:
            'CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  obsoleteColonForDefaultValue = CompileTimeErrorWithoutArguments(
    name: 'OBSOLETE_COLON_FOR_DEFAULT_VALUE',
    problemMessage:
        "Using a colon as the separator before a default value is no longer "
        "supported.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  onRepeated = CompileTimeErrorTemplate(
    name: 'ON_REPEATED',
    problemMessage:
        "The type '{0}' can be included in the superclass constraints only once.",
    correctionMessage:
        "Try removing all except one occurrence of the type name.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.ON_REPEATED',
    withArguments: _withArgumentsOnRepeated,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments optionalParameterInOperator =
      CompileTimeErrorWithoutArguments(
        name: 'OPTIONAL_PARAMETER_IN_OPERATOR',
        problemMessage:
            "Optional parameters aren't allowed when defining an operator.",
        correctionMessage: "Try removing the optional parameters.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of expected library name
  /// String p1: the non-matching actual library name from the "part of"
  ///            declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  partOfDifferentLibrary = CompileTimeErrorTemplate(
    name: 'PART_OF_DIFFERENT_LIBRARY',
    problemMessage: "Expected this library to be part of '{0}', not '{1}'.",
    correctionMessage:
        "Try including a different part, or changing the name of the library "
        "in the part's part-of directive.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY',
    withArguments: _withArgumentsPartOfDifferentLibrary,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  partOfNonPart = CompileTimeErrorTemplate(
    name: 'PART_OF_NON_PART',
    problemMessage: "The included part '{0}' must have a part-of directive.",
    correctionMessage: "Try adding a part-of directive to '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.PART_OF_NON_PART',
    withArguments: _withArgumentsPartOfNonPart,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the non-matching actual library name from the "part of"
  ///            declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  partOfUnnamedLibrary = CompileTimeErrorTemplate(
    name: 'PART_OF_UNNAMED_LIBRARY',
    problemMessage:
        "The library is unnamed. A URI is expected, not a library name '{0}', in "
        "the part-of directive.",
    correctionMessage:
        "Try changing the part-of directive to a URI, or try including a "
        "different part.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY',
    withArguments: _withArgumentsPartOfUnnamedLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternAssignmentNotLocalVariable = CompileTimeErrorWithoutArguments(
    name: 'PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE',
    problemMessage:
        "Only local variables can be assigned in pattern assignments.",
    correctionMessage: "Try assigning to a local variable.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternConstantFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used in patterns.",
    correctionMessage: "Try removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the matched type
  /// Type p1: the required type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternTypeMismatchInIrrefutableContext = CompileTimeErrorTemplate(
    name: 'PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT',
    problemMessage:
        "The matched value of type '{0}' isn't assignable to the required type "
        "'{1}'.",
    correctionMessage:
        "Try changing the required type of the pattern, or the matched value "
        "type.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT',
    withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternVariableAssignmentInsideGuard = CompileTimeErrorWithoutArguments(
    name: 'PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD',
    problemMessage:
        "Pattern variables can't be assigned inside the guard of the enclosing "
        "guarded pattern.",
    correctionMessage: "Try assigning to a different variable.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeDifferentFinalityOrType = CompileTimeErrorTemplate(
    name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    problemMessage:
        "The variable '{0}' doesn't have the same type and/or finality in all "
        "cases that share this body.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "all cases.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE',
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE',
    withArguments:
        _withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeHasLabel = CompileTimeErrorTemplate(
    name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    problemMessage:
        "The variable '{0}' is not available because there is a label or 'default' "
        "case.",
    correctionMessage:
        "Try removing the label, or providing the 'default' case with its own "
        "body.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL',
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL',
    withArguments: _withArgumentsPatternVariableSharedCaseScopeHasLabel,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeNotAllCases = CompileTimeErrorTemplate(
    name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    problemMessage:
        "The variable '{0}' is available in some, but not all cases that share "
        "this body.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "all cases.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES',
    uniqueNameCheck:
        'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES',
    withArguments: _withArgumentsPatternVariableSharedCaseScopeNotAllCases,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments positionalFieldInObjectPattern =
      CompileTimeErrorWithoutArguments(
        name: 'POSITIONAL_FIELD_IN_OBJECT_PATTERN',
        problemMessage: "Object patterns can only use named fields.",
        correctionMessage: "Try specifying the field name.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.POSITIONAL_FIELD_IN_OBJECT_PATTERN',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  positionalSuperFormalParameterWithPositionalArgument = CompileTimeErrorWithoutArguments(
    name: 'POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
    problemMessage:
        "Positional super parameters can't be used when the super constructor "
        "invocation has a positional argument.",
    correctionMessage:
        "Try making all the positional parameters passed to the super "
        "constructor be either all super parameters or all normal parameters.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the prefix
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  prefixCollidesWithTopLevelMember = CompileTimeErrorTemplate(
    name: 'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
    problemMessage:
        "The name '{0}' is already used as an import prefix and can't be used to "
        "name a top-level element.",
    correctionMessage:
        "Try renaming either the top-level element or the prefix.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
    withArguments: _withArgumentsPrefixCollidesWithTopLevelMember,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the prefix
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  prefixIdentifierNotFollowedByDot = CompileTimeErrorTemplate(
    name: 'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
    problemMessage:
        "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
    correctionMessage:
        "Try correcting the name to refer to something other than a prefix, or "
        "renaming the prefix.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
    withArguments: _withArgumentsPrefixIdentifierNotFollowedByDot,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the prefix being shadowed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  prefixShadowedByLocalDeclaration = CompileTimeErrorTemplate(
    name: 'PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
    problemMessage:
        "The prefix '{0}' can't be used here because it's shadowed by a local "
        "declaration.",
    correctionMessage:
        "Try renaming either the prefix or the local declaration.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
    withArguments: _withArgumentsPrefixShadowedByLocalDeclaration,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the private name that collides
  /// String p1: the name of the first mixin
  /// String p2: the name of the second mixin
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  privateCollisionInMixinApplication = CompileTimeErrorTemplate(
    name: 'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
    problemMessage:
        "The private name '{0}', defined by '{1}', conflicts with the same name "
        "defined by '{2}'.",
    correctionMessage: "Try removing '{1}' from the 'with' clause.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
    withArguments: _withArgumentsPrivateCollisionInMixinApplication,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  privateNamedParameterWithoutPublicName = CompileTimeErrorWithoutArguments(
    name: 'PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME',
    problemMessage:
        "A private named parameter must be a public identifier after removing the "
        "leading underscore.",
    uniqueNameCheck:
        'CompileTimeErrorCode.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  privateSetter = CompileTimeErrorTemplate(
    name: 'PRIVATE_SETTER',
    problemMessage:
        "The setter '{0}' is private and can't be accessed outside the library "
        "that declares it.",
    correctionMessage: "Try making it public.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.PRIVATE_SETTER',
    withArguments: _withArgumentsPrivateSetter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  readPotentiallyUnassignedFinal = CompileTimeErrorTemplate(
    name: 'READ_POTENTIALLY_UNASSIGNED_FINAL',
    problemMessage:
        "The final variable '{0}' can't be read because it's potentially "
        "unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL',
    withArguments: _withArgumentsReadPotentiallyUnassignedFinal,
    expectedTypes: [ExpectedType.string],
  );

  /// This is similar to
  /// ParserErrorCode.recordLiteralOnePositionalNoTrailingComma, but
  /// it is reported at type analysis time, based on a type
  /// incompatibility, rather than at parse time.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  recordLiteralOnePositionalNoTrailingCommaByType = CompileTimeErrorWithoutArguments(
    name: 'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    problemMessage:
        "A record literal with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    uniqueName: 'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA_BY_TYPE',
    uniqueNameCheck:
        'CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA_BY_TYPE',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments recursiveCompileTimeConstant =
      CompileTimeErrorWithoutArguments(
        name: 'RECURSIVE_COMPILE_TIME_CONSTANT',
        problemMessage:
            "The compile-time constant expression depends on itself.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments recursiveConstantConstructor =
      CompileTimeErrorWithoutArguments(
        name: 'RECURSIVE_CONSTANT_CONSTRUCTOR',
        problemMessage: "The constant constructor depends on itself.",
        uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// TODO(scheglov): review this later, there are no explicit "it is a
  /// compile-time error" in specification. But it was added to the co19 and
  /// there is same error for factories.
  ///
  /// https://code.google.com/p/dart/issues/detail?id=954
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  recursiveConstructorRedirect = CompileTimeErrorWithoutArguments(
    name: 'RECURSIVE_CONSTRUCTOR_REDIRECT',
    problemMessage:
        "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  recursiveFactoryRedirect = CompileTimeErrorWithoutArguments(
    name: 'RECURSIVE_CONSTRUCTOR_REDIRECT',
    problemMessage:
        "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_FACTORY_REDIRECT',
    uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  /// String p1: a string representation of the implements loop
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  recursiveInterfaceInheritance = CompileTimeErrorTemplate(
    name: 'RECURSIVE_INTERFACE_INHERITANCE',
    problemMessage: "'{0}' can't be a superinterface of itself: {1}.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE',
    withArguments: _withArgumentsRecursiveInterfaceInheritance,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceExtends = CompileTimeErrorTemplate(
    name: 'RECURSIVE_INTERFACE_INHERITANCE',
    problemMessage: "'{0}' can't extend itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
    uniqueNameCheck:
        'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
    withArguments: _withArgumentsRecursiveInterfaceInheritanceExtends,
    expectedTypes: [ExpectedType.string],
  );

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceImplements = CompileTimeErrorTemplate(
    name: 'RECURSIVE_INTERFACE_INHERITANCE',
    problemMessage: "'{0}' can't implement itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
    uniqueNameCheck:
        'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
    withArguments: _withArgumentsRecursiveInterfaceInheritanceImplements,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the mixin that constraints itself recursively
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceOn = CompileTimeErrorTemplate(
    name: 'RECURSIVE_INTERFACE_INHERITANCE',
    problemMessage: "'{0}' can't use itself as a superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_ON',
    uniqueNameCheck: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON',
    withArguments: _withArgumentsRecursiveInterfaceInheritanceOn,
    expectedTypes: [ExpectedType.string],
  );

  /// 7.10 Superinterfaces: It is a compile-time error if the interface of a
  /// class <i>C</i> is a superinterface of itself.
  ///
  /// 8.1 Superinterfaces: It is a compile-time error if an interface is a
  /// superinterface of itself.
  ///
  /// 7.9 Superclasses: It is a compile-time error if a class <i>C</i> is a
  /// superclass of itself.
  ///
  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceWith = CompileTimeErrorTemplate(
    name: 'RECURSIVE_INTERFACE_INHERITANCE',
    problemMessage: "'{0}' can't use itself as a mixin.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_WITH',
    uniqueNameCheck:
        'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH',
    withArguments: _withArgumentsRecursiveInterfaceInheritanceWith,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor
  /// String p1: the name of the class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  redirectGenerativeToMissingConstructor = CompileTimeErrorTemplate(
    name: 'REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
    problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or defining the "
        "constructor named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
    withArguments: _withArgumentsRedirectGenerativeToMissingConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  redirectGenerativeToNonGenerativeConstructor = CompileTimeErrorWithoutArguments(
    name: 'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
    problemMessage:
        "Generative constructors can't redirect to a factory constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the redirecting constructor
  /// String p1: the name of the abstract class defining the constructor being
  ///            redirected to
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  redirectToAbstractClassConstructor = CompileTimeErrorTemplate(
    name: 'REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
    problemMessage:
        "The redirecting constructor '{0}' can't redirect to a constructor of the "
        "abstract class '{1}'.",
    correctionMessage: "Try redirecting to a constructor of a different class.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
    withArguments: _withArgumentsRedirectToAbstractClassConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the name of the redirected constructor
  /// Type p1: the name of the redirecting constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  redirectToInvalidFunctionType = CompileTimeErrorTemplate(
    name: 'REDIRECT_TO_INVALID_FUNCTION_TYPE',
    problemMessage:
        "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REDIRECT_TO_INVALID_FUNCTION_TYPE',
    withArguments: _withArgumentsRedirectToInvalidFunctionType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the name of the redirected constructor's return type
  /// Type p1: the name of the redirecting constructor's return type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  redirectToInvalidReturnType = CompileTimeErrorTemplate(
    name: 'REDIRECT_TO_INVALID_RETURN_TYPE',
    problemMessage:
        "The return type '{0}' of the redirected constructor isn't a subtype of "
        "'{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE',
    withArguments: _withArgumentsRedirectToInvalidReturnType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the constructor
  /// Type p1: the name of the class containing the constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  redirectToMissingConstructor = CompileTimeErrorTemplate(
    name: 'REDIRECT_TO_MISSING_CONSTRUCTOR',
    problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or define the constructor "
        "named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR',
    withArguments: _withArgumentsRedirectToMissingConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the non-type referenced in the redirect
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  redirectToNonClass = CompileTimeErrorTemplate(
    name: 'REDIRECT_TO_NON_CLASS',
    problemMessage:
        "The name '{0}' isn't a type and can't be used in a redirected "
        "constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REDIRECT_TO_NON_CLASS',
    withArguments: _withArgumentsRedirectToNonClass,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  redirectToNonConstConstructor = CompileTimeErrorWithoutArguments(
    name: 'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
    problemMessage:
        "A constant redirecting constructor can't redirect to a non-constant "
        "constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  redirectToTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    name: 'REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    problemMessage:
        "A redirecting constructor can't redirect to a type alias that expands to "
        "a type parameter.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  referencedBeforeDeclaration = CompileTimeErrorTemplate(
    name: 'REFERENCED_BEFORE_DECLARATION',
    problemMessage:
        "Local variable '{0}' can't be referenced before it is declared.",
    correctionMessage:
        "Try moving the declaration to before the first use, or renaming the "
        "local variable so that it doesn't hide a name from an enclosing "
        "scope.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION',
    withArguments: _withArgumentsReferencedBeforeDeclaration,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  refutablePatternInIrrefutableContext = CompileTimeErrorWithoutArguments(
    name: 'REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT',
    problemMessage:
        "Refutable patterns can't be used in an irrefutable context.",
    correctionMessage:
        "Try using an if-case, a 'switch' statement, or a 'switch' expression "
        "instead.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the operand type
  /// Type p1: the parameter type of the invoked operator
  /// String p2: the name of the invoked operator
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  relationalPatternOperandTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The constant expression type '{0}' is not assignable to the parameter "
        "type '{1}' of the '{2}' operator.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsRelationalPatternOperandTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  relationalPatternOperatorReturnTypeNotAssignableToBool =
      CompileTimeErrorWithoutArguments(
        name: 'RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL',
        problemMessage:
            "The return type of operators used in relational patterns must be "
            "assignable to 'bool'.",
        correctionMessage:
            "Try updating the operator declaration to return 'bool'.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments restElementInMapPattern =
      CompileTimeErrorWithoutArguments(
        name: 'REST_ELEMENT_IN_MAP_PATTERN',
        problemMessage: "A map pattern can't contain a rest pattern.",
        correctionMessage: "Try removing the rest pattern.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.REST_ELEMENT_IN_MAP_PATTERN',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments rethrowOutsideCatch =
      CompileTimeErrorWithoutArguments(
        name: 'RETHROW_OUTSIDE_CATCH',
        problemMessage: "A rethrow must be inside of a catch clause.",
        correctionMessage:
            "Try moving the expression into a catch clause, or using a 'throw' "
            "expression.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments returnInGenerativeConstructor =
      CompileTimeErrorWithoutArguments(
        name: 'RETURN_IN_GENERATIVE_CONSTRUCTOR',
        problemMessage: "Constructors can't return values.",
        correctionMessage:
            "Try removing the return statement or using a factory constructor.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  returnInGenerator = CompileTimeErrorWithoutArguments(
    name: 'RETURN_IN_GENERATOR',
    problemMessage:
        "Can't return a value from a generator function that uses the 'async*' or "
        "'sync*' modifier.",
    correctionMessage:
        "Try replacing 'return' with 'yield', using a block function body, or "
        "changing the method body modifier.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.RETURN_IN_GENERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnOfInvalidTypeFromClosure = CompileTimeErrorTemplate(
    name: 'RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
    problemMessage:
        "The returned type '{0}' isn't returnable from a '{1}' function, as "
        "required by the closure's context.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
    withArguments: _withArgumentsReturnOfInvalidTypeFromClosure,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the enclosing class
  /// String p2: the name of the constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromConstructor = CompileTimeErrorTemplate(
    name: 'RETURN_OF_INVALID_TYPE',
    problemMessage:
        "A value of type '{0}' can't be returned from the constructor '{2}' "
        "because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
    uniqueNameCheck:
        'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
    withArguments: _withArgumentsReturnOfInvalidTypeFromConstructor,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the method
  /// String p2: the name of the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromFunction = CompileTimeErrorTemplate(
    name: 'RETURN_OF_INVALID_TYPE',
    problemMessage:
        "A value of type '{0}' can't be returned from the function '{2}' because "
        "it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
    uniqueNameCheck:
        'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
    withArguments: _withArgumentsReturnOfInvalidTypeFromFunction,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type of the expression in the return statement
  /// Type p1: the expected return type as defined by the method
  /// String p2: the name of the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required DartType p1,
      required String p2,
    })
  >
  returnOfInvalidTypeFromMethod = CompileTimeErrorTemplate(
    name: 'RETURN_OF_INVALID_TYPE',
    problemMessage:
        "A value of type '{0}' can't be returned from the method '{2}' because it "
        "has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_METHOD',
    uniqueNameCheck: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD',
    withArguments: _withArgumentsReturnOfInvalidTypeFromMethod,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments returnWithoutValue =
      CompileTimeErrorWithoutArguments(
        name: 'RETURN_WITHOUT_VALUE',
        problemMessage: "The return value is missing after 'return'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.RETURN_WITHOUT_VALUE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the sealed class being extended, implemented, or
  ///            mixed in
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  sealedClassSubtypeOutsideOfLibrary = CompileTimeErrorTemplate(
    name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    problemMessage:
        "The class '{0}' can't be extended, implemented, or mixed in outside of "
        "its library because it's a sealed class.",
    hasPublishedDocs: true,
    uniqueName: 'SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY',
    uniqueNameCheck:
        'CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  setElementFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be used as values in a "
        "'const' set literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the set literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_FROM_DEFERRED_LIBRARY',
    uniqueNameCheck: 'CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the actual type of the set element
  /// Type p1: the expected type of the set element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  setElementTypeNotAssignable = CompileTimeErrorTemplate(
    name: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    withArguments: _withArgumentsSetElementTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the actual type of the set element
  /// Type p1: the expected type of the set element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  setElementTypeNotAssignableNullability = CompileTimeErrorTemplate(
    name: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    problemMessage:
        "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    uniqueNameCheck:
        'CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsSetElementTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  sharedDeferredPrefix = CompileTimeErrorWithoutArguments(
    name: 'SHARED_DEFERRED_PREFIX',
    problemMessage:
        "The prefix of a deferred import can't be used in other import directives.",
    correctionMessage: "Try renaming one of the prefixes.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.SHARED_DEFERRED_PREFIX',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  spreadExpressionFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    name: 'SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
    problemMessage:
        "Constant values from a deferred library can't be spread into a const "
        "literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
    uniqueNameCheck:
        'CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the instance member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  staticAccessToInstanceMember = CompileTimeErrorTemplate(
    name: 'STATIC_ACCESS_TO_INSTANCE_MEMBER',
    problemMessage:
        "Instance member '{0}' can't be accessed using static access.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER',
    withArguments: _withArgumentsStaticAccessToInstanceMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the subtype that is not 'base', 'final', or
  ///            'sealed'
  /// String p1: the name of the 'base' supertype
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfBaseIsNotBaseFinalOrSealed = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    problemMessage:
        "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
        "'{1}' is 'base'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED',
    uniqueNameCheck:
        'CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED',
    withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the subtype that is not 'base', 'final', or
  ///            'sealed'
  /// String p1: the name of the 'final' supertype
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  subtypeOfFinalIsNotBaseFinalOrSealed = CompileTimeErrorTemplate(
    name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    problemMessage:
        "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
        "'{1}' is 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    uniqueNameCheck:
        'CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type of super-parameter
  /// Type p1: the type of associated super-constructor parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  superFormalParameterTypeIsNotSubtypeOfAssociated = CompileTimeErrorTemplate(
    name: 'SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
    problemMessage:
        "The type '{0}' of this parameter isn't a subtype of the type '{1}' of the "
        "associated super constructor parameter.",
    correctionMessage:
        "Try removing the explicit type annotation from the parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
    withArguments:
        _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superFormalParameterWithoutAssociatedNamed = CompileTimeErrorWithoutArguments(
    name: 'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
    problemMessage: "No associated named super constructor parameter.",
    correctionMessage:
        "Try changing the name to the name of an existing named super "
        "constructor parameter, or creating such named parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superFormalParameterWithoutAssociatedPositional = CompileTimeErrorWithoutArguments(
    name: 'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
    problemMessage: "No associated positional super constructor parameter.",
    correctionMessage:
        "Try using a normal parameter, or adding more positional parameters to "
        "the super constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInEnumConstructor =
      CompileTimeErrorWithoutArguments(
        name: 'SUPER_IN_ENUM_CONSTRUCTOR',
        problemMessage:
            "The enum constructor can't have a 'super' initializer.",
        correctionMessage: "Try removing the 'super' invocation.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superInExtension = CompileTimeErrorWithoutArguments(
    name: 'SUPER_IN_EXTENSION',
    problemMessage:
        "The 'super' keyword can't be used in an extension because an extension "
        "doesn't have a superclass.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.SUPER_IN_EXTENSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInExtensionType =
      CompileTimeErrorWithoutArguments(
        name: 'SUPER_IN_EXTENSION_TYPE',
        problemMessage:
            "The 'super' keyword can't be used in an extension type because an "
            "extension type doesn't have a superclass.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.SUPER_IN_EXTENSION_TYPE',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInInvalidContext =
      CompileTimeErrorWithoutArguments(
        name: 'SUPER_IN_INVALID_CONTEXT',
        problemMessage: "Invalid context for 'super' invocation.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT',
        expectedTypes: [],
      );

  /// 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
  /// is a compile-time error if a generative constructor of class Object
  /// includes a superinitializer.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInitializerInObject =
      CompileTimeErrorWithoutArguments(
        name: 'SUPER_INITIALIZER_IN_OBJECT',
        problemMessage:
            "The class 'Object' can't invoke a constructor from a superclass.",
        uniqueNameCheck: 'CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInRedirectingConstructor =
      CompileTimeErrorWithoutArguments(
        name: 'SUPER_IN_REDIRECTING_CONSTRUCTOR',
        problemMessage:
            "The redirecting constructor can't have a 'super' initializer.",
        hasPublishedDocs: true,
        uniqueNameCheck:
            'CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the superinitializer
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  superInvocationNotLast = CompileTimeErrorTemplate(
    name: 'SUPER_INVOCATION_NOT_LAST',
    problemMessage:
        "The superconstructor call must be last in an initializer list: '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST',
    withArguments: _withArgumentsSuperInvocationNotLast,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments switchCaseCompletesNormally =
      CompileTimeErrorWithoutArguments(
        name: 'SWITCH_CASE_COMPLETES_NORMALLY',
        problemMessage: "The 'case' shouldn't complete normally.",
        correctionMessage: "Try adding 'break', 'return', or 'throw'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  tearoffOfGenerativeConstructorOfAbstractClass = CompileTimeErrorWithoutArguments(
    name: 'TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
    problemMessage:
        "A generative constructor of an abstract class can't be torn off.",
    correctionMessage:
        "Try tearing off a constructor of a concrete class, or a "
        "non-generative constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type that can't be thrown
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  throwOfInvalidType = CompileTimeErrorTemplate(
    name: 'THROW_OF_INVALID_TYPE',
    problemMessage:
        "The type '{0}' of the thrown expression must be assignable to 'Object'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.THROW_OF_INVALID_TYPE',
    withArguments: _withArgumentsThrowOfInvalidType,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the element whose type could not be inferred.
  /// String p1: The [TopLevelInferenceError]'s arguments that led to the cycle.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  topLevelCycle = CompileTimeErrorTemplate(
    name: 'TOP_LEVEL_CYCLE',
    problemMessage:
        "The type of '{0}' can't be inferred because it depends on itself through "
        "the cycle: {1}.",
    correctionMessage:
        "Try adding an explicit type to one or more of the variables in the "
        "cycle in order to break the cycle.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TOP_LEVEL_CYCLE',
    withArguments: _withArgumentsTopLevelCycle,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  typeAliasCannotReferenceItself = CompileTimeErrorWithoutArguments(
    name: 'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    problemMessage:
        "Typedefs can't reference themselves directly or recursively via another "
        "typedef.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the type that is deferred and being used in a type
  ///            annotation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeAnnotationDeferredClass = CompileTimeErrorTemplate(
    name: 'TYPE_ANNOTATION_DEFERRED_CLASS',
    problemMessage:
        "The deferred type '{0}' can't be used in a declaration, cast, or type "
        "test.",
    correctionMessage:
        "Try using a different type, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS',
    withArguments: _withArgumentsTypeAnnotationDeferredClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the name of the type used in the instance creation that should be
  ///          limited by the bound as specified in the class declaration
  /// String p1: the name of the type parameter
  /// Type p2: the substituted bound of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required String p1,
      required DartType p2,
    })
  >
  typeArgumentNotMatchingBounds = CompileTimeErrorTemplate(
    name: 'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
    problemMessage:
        "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
    correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
    withArguments: _withArgumentsTypeArgumentNotMatchingBounds,
    expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  typeParameterReferencedByStatic = CompileTimeErrorWithoutArguments(
    name: 'TYPE_PARAMETER_REFERENCED_BY_STATIC',
    problemMessage:
        "Static members can't reference type parameters of the class.",
    correctionMessage:
        "Try removing the reference to the type parameter, or making the "
        "member an instance member.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC',
    expectedTypes: [],
  );

  /// See [CompileTimeErrorCode.typeArgumentNotMatchingBounds].
  ///
  /// Parameters:
  /// String p0: the name of the type parameter
  /// Type p1: the name of the bounding type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  typeParameterSupertypeOfItsBound = CompileTimeErrorTemplate(
    name: 'TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    problemMessage: "'{0}' can't be a supertype of its upper bound.",
    correctionMessage:
        "Try using a type that is the same as or a subclass of '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    withArguments: _withArgumentsTypeParameterSupertypeOfItsBound,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithNonType = CompileTimeErrorTemplate(
    name: 'TYPE_TEST_WITH_NON_TYPE',
    problemMessage:
        "The name '{0}' isn't a type and can't be used in an 'is' expression.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_TEST_WITH_NON_TYPE',
    withArguments: _withArgumentsTypeTestWithNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithUndefinedName = CompileTimeErrorTemplate(
    name: 'TYPE_TEST_WITH_UNDEFINED_NAME',
    problemMessage:
        "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME',
    withArguments: _withArgumentsTypeTestWithUndefinedName,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedInvocationOfNullableValue = CompileTimeErrorWithoutArguments(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "The function can't be unconditionally invoked because it can be 'null'.",
    correctionMessage: "Try adding a null check ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_INVOCATION_OF_NULLABLE_VALUE',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedMethodInvocationOfNullableValue = CompileTimeErrorTemplate(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "The method '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the call conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedMethodInvocationOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedOperatorInvocationOfNullableValue = CompileTimeErrorTemplate(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "The operator '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage: "Try adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedOperatorInvocationOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the property
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedPropertyAccessOfNullableValue = CompileTimeErrorTemplate(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "The property '{0}' can't be unconditionally accessed because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the access conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedPropertyAccessOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueAsCondition = CompileTimeErrorWithoutArguments(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage: "A nullable expression can't be used as a condition.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as a "
        "condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueAsIterator = CompileTimeErrorWithoutArguments(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "A nullable expression can't be used as an iterator in a for-in loop.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as an "
        "iterator.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueInSpread = CompileTimeErrorWithoutArguments(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage: "A nullable expression can't be used in a spread.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a spread, "
        "or use a null-aware spread.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueInYieldEach = CompileTimeErrorWithoutArguments(
    name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
    problemMessage:
        "A nullable expression can't be used in a yield-each statement.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a "
        "yield-each statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the annotation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedAnnotation = CompileTimeErrorTemplate(
    name: 'UNDEFINED_ANNOTATION',
    problemMessage: "Undefined name '{0}' used as an annotation.",
    correctionMessage:
        "Try defining the name or importing it from another library.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_ANNOTATION',
    withArguments: _withArgumentsUndefinedAnnotation,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the undefined class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedClass = CompileTimeErrorTemplate(
    name: 'UNDEFINED_CLASS',
    problemMessage: "Undefined class '{0}'.",
    correctionMessage:
        "Try changing the name to the name of an existing class, or creating a "
        "class with the name '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_CLASS',
    withArguments: _withArgumentsUndefinedClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Same as [CompileTimeErrorCode.undefinedClass], but to catch using
  /// "boolean" instead of "bool" in order to improve the correction message.
  ///
  /// Parameters:
  /// String p0: the name of the undefined class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedClassBoolean = CompileTimeErrorTemplate(
    name: 'UNDEFINED_CLASS',
    problemMessage: "Undefined class '{0}'.",
    correctionMessage: "Try using the type 'bool'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'UNDEFINED_CLASS_BOOLEAN',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN',
    withArguments: _withArgumentsUndefinedClassBoolean,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the name of the superclass that does not define the invoked
  ///          constructor
  /// String p1: the name of the constructor being invoked
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required String p1})
  >
  undefinedConstructorInInitializer = CompileTimeErrorTemplate(
    name: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try defining a constructor named '{1}' in '{0}', or invoking a "
        "different constructor.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    withArguments: _withArgumentsUndefinedConstructorInInitializer,
    expectedTypes: [ExpectedType.type, ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the superclass that does not define the invoked
  ///            constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  undefinedConstructorInInitializerDefault = CompileTimeErrorTemplate(
    name: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try defining an unnamed constructor in '{0}', or invoking a different "
        "constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
    uniqueNameCheck:
        'CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
    withArguments: _withArgumentsUndefinedConstructorInInitializerDefault,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the enum value that is not defined
  /// String p1: the name of the enum used to access the constant
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedEnumConstant = CompileTimeErrorTemplate(
    name: 'UNDEFINED_ENUM_CONSTANT',
    problemMessage: "There's no constant named '{0}' in '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constant, or "
        "defining a constant named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT',
    withArguments: _withArgumentsUndefinedEnumConstant,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor that is undefined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedEnumConstructorNamed = CompileTimeErrorTemplate(
    name: 'UNDEFINED_ENUM_CONSTRUCTOR',
    problemMessage: "The enum doesn't have a constructor named '{0}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constructor, or "
        "defining constructor with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_NAMED',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED',
    withArguments: _withArgumentsUndefinedEnumConstructorNamed,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  undefinedEnumConstructorUnnamed = CompileTimeErrorWithoutArguments(
    name: 'UNDEFINED_ENUM_CONSTRUCTOR',
    problemMessage: "The enum doesn't have an unnamed constructor.",
    correctionMessage:
        "Try adding the name of an existing constructor, or defining an "
        "unnamed constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the getter that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionGetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_EXTENSION_GETTER',
    problemMessage: "The getter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER',
    withArguments: _withArgumentsUndefinedExtensionGetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionMethod = CompileTimeErrorTemplate(
    name: 'UNDEFINED_EXTENSION_METHOD',
    problemMessage: "The method '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD',
    withArguments: _withArgumentsUndefinedExtensionMethod,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionOperator = CompileTimeErrorTemplate(
    name: 'UNDEFINED_EXTENSION_OPERATOR',
    problemMessage: "The operator '{0}' isn't defined for the extension '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR',
    withArguments: _withArgumentsUndefinedExtensionOperator,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the setter that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionSetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_EXTENSION_SETTER',
    problemMessage: "The setter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER',
    withArguments: _withArgumentsUndefinedExtensionSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedFunction = CompileTimeErrorTemplate(
    name: 'UNDEFINED_FUNCTION',
    problemMessage: "The function '{0}' isn't defined.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing function, or defining a function named '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_FUNCTION',
    withArguments: _withArgumentsUndefinedFunction,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the getter
  /// Object p1: the name of the enclosing type where the getter is being looked
  ///            for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required Object p1})
  >
  undefinedGetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_GETTER',
    problemMessage: "The getter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing getter, or defining a getter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_GETTER',
    withArguments: _withArgumentsUndefinedGetter,
    expectedTypes: [ExpectedType.string, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the getter
  /// String p1: the name of the function type alias
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedGetterOnFunctionType = CompileTimeErrorTemplate(
    name: 'UNDEFINED_GETTER',
    problemMessage:
        "The getter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_GETTER_ON_FUNCTION_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE',
    withArguments: _withArgumentsUndefinedGetterOnFunctionType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the identifier
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedIdentifier = CompileTimeErrorTemplate(
    name: 'UNDEFINED_IDENTIFIER',
    problemMessage: "Undefined name '{0}'.",
    correctionMessage:
        "Try correcting the name to one that is defined, or defining the name.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_IDENTIFIER',
    withArguments: _withArgumentsUndefinedIdentifier,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  undefinedIdentifierAwait = CompileTimeErrorWithoutArguments(
    name: 'UNDEFINED_IDENTIFIER_AWAIT',
    problemMessage:
        "Undefined name 'await' in function body not marked with 'async'.",
    correctionMessage:
        "Try correcting the name to one that is defined, defining the name, or "
        "adding 'async' to the enclosing function body.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// Object p1: the resolved type name that the method lookup is happening on
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required Object p1})
  >
  undefinedMethod = CompileTimeErrorTemplate(
    name: 'UNDEFINED_METHOD',
    problemMessage: "The method '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_METHOD',
    withArguments: _withArgumentsUndefinedMethod,
    expectedTypes: [ExpectedType.string, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the method
  /// String p1: the name of the function type alias
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedMethodOnFunctionType = CompileTimeErrorTemplate(
    name: 'UNDEFINED_METHOD',
    problemMessage:
        "The method '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension method on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_METHOD_ON_FUNCTION_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE',
    withArguments: _withArgumentsUndefinedMethodOnFunctionType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the requested named parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedNamedParameter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_NAMED_PARAMETER',
    problemMessage: "The named parameter '{0}' isn't defined.",
    correctionMessage:
        "Try correcting the name to an existing named parameter's name, or "
        "defining a named parameter with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER',
    withArguments: _withArgumentsUndefinedNamedParameter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator
  /// Type p1: the name of the enclosing type where the operator is being looked
  ///          for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedOperator = CompileTimeErrorTemplate(
    name: 'UNDEFINED_OPERATOR',
    problemMessage: "The operator '{0}' isn't defined for the type '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_OPERATOR',
    withArguments: _withArgumentsUndefinedOperator,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the reference
  /// String p1: the name of the prefix
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedPrefixedName = CompileTimeErrorTemplate(
    name: 'UNDEFINED_PREFIXED_NAME',
    problemMessage:
        "The name '{0}' is being referenced through the prefix '{1}', but it isn't "
        "defined in any of the libraries imported using that prefix.",
    correctionMessage:
        "Try correcting the prefix or importing the library that defines "
        "'{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME',
    withArguments: _withArgumentsUndefinedPrefixedName,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the setter
  /// Type p1: the name of the enclosing type where the setter is being looked
  ///          for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SETTER',
    problemMessage: "The setter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing setter, or defining a setter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SETTER',
    withArguments: _withArgumentsUndefinedSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the setter
  /// String p1: the name of the function type alias
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedSetterOnFunctionType = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SETTER',
    problemMessage:
        "The setter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SETTER_ON_FUNCTION_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE',
    withArguments: _withArgumentsUndefinedSetterOnFunctionType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the getter
  /// Type p1: the name of the enclosing type where the getter is being looked
  ///          for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperGetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SUPER_MEMBER',
    problemMessage: "The getter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_GETTER',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SUPER_GETTER',
    withArguments: _withArgumentsUndefinedSuperGetter,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// String p1: the resolved type name that the method lookup is happening on
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedSuperMethod = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SUPER_MEMBER',
    problemMessage: "The method '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_METHOD',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SUPER_METHOD',
    withArguments: _withArgumentsUndefinedSuperMethod,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator
  /// Type p1: the name of the enclosing type where the operator is being looked
  ///          for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperOperator = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SUPER_MEMBER',
    problemMessage:
        "The operator '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage: "Try defining the operator '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_OPERATOR',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR',
    withArguments: _withArgumentsUndefinedSuperOperator,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the setter
  /// Type p1: the name of the enclosing type where the setter is being looked
  ///          for
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  undefinedSuperSetter = CompileTimeErrorTemplate(
    name: 'UNDEFINED_SUPER_MEMBER',
    problemMessage: "The setter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_SETTER',
    uniqueNameCheck: 'CompileTimeErrorCode.UNDEFINED_SUPER_SETTER',
    withArguments: _withArgumentsUndefinedSuperSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// This is a specialization of [instanceAccessToStaticMember] that is used
  /// when we are able to find the name defined in a supertype. It exists to
  /// provide a more informative error message.
  ///
  /// Parameters:
  /// String p0: the name of the defining type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unqualifiedReferenceToNonLocalStaticMember = CompileTimeErrorTemplate(
    name: 'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
    problemMessage:
        "Static members from supertypes must be qualified by the name of the "
        "defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
    withArguments: _withArgumentsUnqualifiedReferenceToNonLocalStaticMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the defining type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unqualifiedReferenceToStaticMemberOfExtendedType = CompileTimeErrorTemplate(
    name: 'UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
    problemMessage:
        "Static members from the extended type or one of its superclasses must be "
        "qualified by the name of the defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
    withArguments:
        _withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uriDoesNotExist = CompileTimeErrorTemplate(
    name: 'URI_DOES_NOT_EXIST',
    problemMessage: "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.URI_DOES_NOT_EXIST',
    withArguments: _withArgumentsUriDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uriHasNotBeenGenerated = CompileTimeErrorTemplate(
    name: 'URI_HAS_NOT_BEEN_GENERATED',
    problemMessage: "Target of URI hasn't been generated: '{0}'.",
    correctionMessage:
        "Try running the generator that will generate the file referenced by "
        "the URI.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED',
    withArguments: _withArgumentsUriHasNotBeenGenerated,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments uriWithInterpolation =
      CompileTimeErrorWithoutArguments(
        name: 'URI_WITH_INTERPOLATION',
        problemMessage: "URIs can't use string interpolation.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.URI_WITH_INTERPOLATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  useOfNativeExtension = CompileTimeErrorWithoutArguments(
    name: 'USE_OF_NATIVE_EXTENSION',
    problemMessage:
        "Dart native extensions are deprecated and aren't available in Dart 2.15.",
    correctionMessage: "Try using dart:ffi for C interop.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.USE_OF_NATIVE_EXTENSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  useOfVoidResult = CompileTimeErrorWithoutArguments(
    name: 'USE_OF_VOID_RESULT',
    problemMessage:
        "This expression has a type of 'void' so its value can't be used.",
    correctionMessage:
        "Try checking to see if you're using the correct API; there might be a "
        "function or call that returns void you didn't expect. Also check type "
        "parameters and variables which might also be void.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.USE_OF_VOID_RESULT',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments valuesDeclarationInEnum =
      CompileTimeErrorWithoutArguments(
        name: 'VALUES_DECLARATION_IN_ENUM',
        problemMessage: "A member named 'values' can't be declared in an enum.",
        correctionMessage: "Try using a different name.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the type of the object being assigned.
  /// Object p1: the type of the variable being assigned to
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  variableTypeMismatch = CompileTimeErrorTemplate(
    name: 'VARIABLE_TYPE_MISMATCH',
    problemMessage:
        "A value of type '{0}' can't be assigned to a const variable of type "
        "'{1}'.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH',
    withArguments: _withArgumentsVariableTypeMismatch,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Let `C` be a generic class that declares a formal type parameter `X`, and
  /// assume that `T` is a direct superinterface of `C`.
  ///
  /// It is a compile-time error if `X` is explicitly defined as a covariant or
  /// 'in' type parameter and `X` occurs in a non-covariant position in `T`.
  /// It is a compile-time error if `X` is explicitly defined as a contravariant
  /// or 'out' type parameter and `X` occurs in a non-contravariant position in
  /// `T`.
  ///
  /// Parameters:
  /// Object p0: the name of the type parameter
  /// Object p1: the variance modifier defined for {0}
  /// Object p2: the variance position of the type parameter {0} in the
  ///            superinterface {3}
  /// Object p3: the name of the superinterface
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
      required Object p3,
    })
  >
  wrongExplicitTypeParameterVarianceInSuperinterface = CompileTimeErrorTemplate(
    name: 'WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    problemMessage:
        "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position "
        "in '{3}'.",
    correctionMessage:
        "Try using 'in' type parameters in 'in' positions and 'out' type "
        "parameters in 'out' positions in the superinterface.",
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    withArguments:
        _withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// Parameters:
  /// String p0: the name of the declared operator
  /// int p1: the number of parameters expected
  /// int p2: the number of parameters found in the operator declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfParametersForOperator = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    problemMessage:
        "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    withArguments: _withArgumentsWrongNumberOfParametersForOperator,
    expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
  );

  /// 7.1.1 Operators: It is a compile time error if the arity of the
  /// user-declared operator - is not 0 or 1.
  ///
  /// Parameters:
  /// int p0: the number of parameters found in the operator declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  wrongNumberOfParametersForOperatorMinus = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    problemMessage:
        "Operator '-' should declare 0 or 1 parameter, but {0} found.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
    withArguments: _withArgumentsWrongNumberOfParametersForOperatorMinus,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// Object p0: the name of the type being referenced (<i>G</i>)
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArguments = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
    problemMessage:
        "The type '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS',
    withArguments: _withArgumentsWrongNumberOfTypeArguments,
    expectedTypes: [ExpectedType.object, ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of type parameters that were declared
  /// int p1: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  wrongNumberOfTypeArgumentsAnonymousFunction = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    problemMessage:
        "This function is declared with {0} type parameters, but {1} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsAnonymousFunction,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor being invoked
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  wrongNumberOfTypeArgumentsConstructor = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    problemMessage: "The constructor '{0}.{1}' doesn't have type parameters.",
    correctionMessage: "Try moving type arguments to after the type name.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class being instantiated
  /// String p1: the name of the constructor being invoked
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  wrongNumberOfTypeArgumentsDotShorthandConstructor = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    problemMessage: "The constructor '{0}.{1}` doesn't have type parameters.",
    correctionMessage:
        "Try removing the type arguments, or adding a class name, followed by "
        "the type arguments, then the constructor name.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR',
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR',
    withArguments:
        _withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// int p0: the number of type parameters that were declared
  /// int p1: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  wrongNumberOfTypeArgumentsEnum = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
    problemMessage:
        "The enum is declared with {0} type parameters, but {1} type arguments "
        "were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsEnum,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the extension being referenced
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArgumentsExtension = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
    problemMessage:
        "The extension '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsExtension,
    expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the function being referenced
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArgumentsFunction = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    problemMessage:
        "The function '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsFunction,
    expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// Type p0: the name of the method being referenced (<i>G</i>)
  /// int p1: the number of type parameters that were declared
  /// int p2: the number of type arguments provided
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required DartType p0,
      required int p1,
      required int p2,
    })
  >
  wrongNumberOfTypeArgumentsMethod = CompileTimeErrorTemplate(
    name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
    problemMessage:
        "The method '{0}' is declared with {1} type parameters, but {2} type "
        "arguments are given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
    withArguments: _withArgumentsWrongNumberOfTypeArgumentsMethod,
    expectedTypes: [ExpectedType.type, ExpectedType.int, ExpectedType.int],
  );

  /// Let `C` be a generic class that declares a formal type parameter `X`, and
  /// assume that `T` is a direct superinterface of `C`. It is a compile-time
  /// error if `X` occurs contravariantly or invariantly in `T`.
  ///
  /// Parameters:
  /// String p0: the name of the type parameter
  /// Type p1: the name of the super interface
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required DartType p1})
  >
  wrongTypeParameterVarianceInSuperinterface = CompileTimeErrorTemplate(
    name: 'WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    problemMessage:
        "'{0}' can't be used contravariantly or invariantly in '{1}'.",
    correctionMessage:
        "Try not using class type parameters in types of formal parameters of "
        "function types, nor in explicitly contravariant or invariant "
        "superinterfaces.",
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    withArguments: _withArgumentsWrongTypeParameterVarianceInSuperinterface,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Let `C` be a generic class that declares a formal type parameter `X`.
  ///
  /// If `X` is explicitly contravariant then it is a compile-time error for
  /// `X` to occur in a non-contravariant position in a member signature in the
  /// body of `C`, except when `X` is in a contravariant position in the type
  /// annotation of a covariant formal parameter.
  ///
  /// If `X` is explicitly covariant then it is a compile-time error for
  /// `X` to occur in a non-covariant position in a member signature in the
  /// body of `C`, except when `X` is in a covariant position in the type
  /// annotation of a covariant formal parameter.
  ///
  /// Parameters:
  /// Object p0: the variance modifier defined for {0}
  /// Object p1: the name of the type parameter
  /// Object p2: the variance position that the type parameter {1} is in
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  wrongTypeParameterVariancePosition = CompileTimeErrorTemplate(
    name: 'WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
    problemMessage:
        "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
    correctionMessage:
        "Try removing the type parameter or change the explicit variance "
        "modifier declaration for the type parameter to another one of 'in', "
        "'out', or 'inout'.",
    uniqueNameCheck:
        'CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
    withArguments: _withArgumentsWrongTypeParameterVariancePosition,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  yieldEachInNonGenerator = CompileTimeErrorWithoutArguments(
    name: 'YIELD_IN_NON_GENERATOR',
    problemMessage:
        "Yield-each statements must be in a generator function (one marked with "
        "either 'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_IN_NON_GENERATOR',
    uniqueNameCheck: 'CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the expression after `yield*`
  /// Type p1: the return type of the function containing the `yield*`
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldEachOfInvalidType = CompileTimeErrorTemplate(
    name: 'YIELD_OF_INVALID_TYPE',
    problemMessage:
        "The type '{0}' implied by the 'yield*' expression must be assignable to "
        "'{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_OF_INVALID_TYPE',
    uniqueNameCheck: 'CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE',
    withArguments: _withArgumentsYieldEachOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// ?? Yield: It is a compile-time error if a yield statement appears in a
  /// function that is not a generator function.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  yieldInNonGenerator = CompileTimeErrorWithoutArguments(
    name: 'YIELD_IN_NON_GENERATOR',
    problemMessage:
        "Yield statements must be in a generator function (one marked with either "
        "'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.YIELD_IN_NON_GENERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the expression after `yield`
  /// Type p1: the return type of the function containing the `yield`
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldOfInvalidType = CompileTimeErrorTemplate(
    name: 'YIELD_OF_INVALID_TYPE',
    problemMessage:
        "A yielded value of type '{0}' must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'CompileTimeErrorCode.YIELD_OF_INVALID_TYPE',
    withArguments: _withArgumentsYieldOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required String super.uniqueNameCheck,
    required super.expectedTypes,
  }) : super(
         type: DiagnosticType.COMPILE_TIME_ERROR,
         uniqueName: 'CompileTimeErrorCode.${uniqueName ?? name}',
       );

  static LocatableDiagnostic _withArgumentsAbstractSuperMemberReference({
    required String memberKind,
    required String name,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.abstractSuperMemberReference,
      [memberKind, name],
    );
  }

  static LocatableDiagnostic _withArgumentsAmbiguousExport({
    required String p0,
    required Uri p1,
    required Uri p2,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.ambiguousExport, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.ambiguousExtensionMemberAccessThreeOrMore,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessTwo({
    required String p0,
    required Element p1,
    required Element p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.ambiguousExtensionMemberAccessTwo,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsAmbiguousImport({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.ambiguousImport, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsArgumentTypeNotAssignable({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.argumentTypeNotAssignable,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.assignmentToFinal, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinalLocal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.assignmentToFinalLocal,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinalNoSetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.assignmentToFinalNoSetter,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAugmentationModifierExtra({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.augmentationModifierExtra,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAugmentationModifierMissing({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.augmentationModifierMissing,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsAugmentationOfDifferentDeclarationKind({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.augmentationOfDifferentDeclarationKind,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAugmentedExpressionNotOperator({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.augmentedExpressionNotOperator,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsBaseClassImplementedOutsideOfLibrary({
    required String implementedClassName,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary,
      [implementedClassName],
    );
  }

  static LocatableDiagnostic
  _withArgumentsBaseMixinImplementedOutsideOfLibrary({
    required String implementedMixinName,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.baseMixinImplementedOutsideOfLibrary,
      [implementedMixinName],
    );
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormally({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.bodyMightCompleteNormally,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsExtensionName,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsBuiltInIdentifierAsExtensionTypeName({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsExtensionTypeName,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsPrefixName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsPrefixName,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypedefName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsTypedefName,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsTypeName,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsBuiltInIdentifierAsTypeParameterName({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.builtInIdentifierAsTypeParameterName,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsCaseExpressionTypeImplementsEquals({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.caseExpressionTypeImplementsEquals,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.caseExpressionTypeIsNotSwitchExpressionSubtype,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsCastToNonType({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.castToNonType, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToInstanceMember({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.classInstantiationAccessToInstanceMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToStaticMember({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.classInstantiationAccessToStaticMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToUnknownMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.classInstantiationAccessToUnknownMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsClassUsedAsMixin({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.classUsedAsMixin, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConcreteClassWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.concreteClassWithAbstractMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticField({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingConstructorAndStaticField,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticGetter({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingConstructorAndStaticGetter,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticMethod({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingConstructorAndStaticMethod,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticSetter({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingConstructorAndStaticSetter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingFieldAndMethod({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingFieldAndMethod,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingGenericInterfaces({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingGenericInterfaces,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingInheritedMethodAndSetter({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingInheritedMethodAndSetter,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingMethodAndField({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingMethodAndField,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingStaticAndInstance({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingStaticAndInstance,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndEnum({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndEnum,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtension({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndExtension,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndExtensionType({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndExtensionType,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberClass({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMemberClass,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberEnum({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMemberEnum,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberExtension({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMemberExtension,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberExtensionType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMemberExtensionType,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberMixin({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMemberMixin,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMixin({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.conflictingTypeVariableAndMixin,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorFieldTypeMismatch({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorFieldTypeMismatch,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorParamTypeMismatch({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorParamTypeMismatch,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConstConstructorWithFieldInitializedByNonConst({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorWithFieldInitializedByNonConst,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorWithMixinWithField,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithFields({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorWithMixinWithFields,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithNonConstSuper({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constConstructorWithNonConstSuper,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConstEvalAssertionFailureWithMessage({required Object p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constEvalAssertionFailureWithMessage,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstEvalPropertyAccess({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constEvalPropertyAccess,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsConstFieldInitializerNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constFieldInitializerNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsConstMapKeyNotPrimitiveEquality({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constMapKeyNotPrimitiveEquality,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstNotInitialized({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.constNotInitialized, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConstSetElementNotPrimitiveEquality({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constSetElementNotPrimitiveEquality,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.constWithNonType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstWithUndefinedConstructor({
    required Object p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constWithUndefinedConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConstWithUndefinedConstructorDefault({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.constWithUndefinedConstructorDefault,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsCouldNotInfer({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.couldNotInfer, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsDefinitelyUnassignedLateLocalVariable({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.definitelyUnassignedLateLocalVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDotShorthandUndefinedGetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.dotShorthandUndefinedGetter,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDotShorthandUndefinedInvocation({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.dotShorthandUndefinedInvocation,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDuplicateConstructorName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.duplicateConstructorName,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDuplicateDefinition({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.duplicateDefinition, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateFieldFormalParameter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.duplicateFieldFormalParameter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDuplicateFieldName({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.duplicateFieldName, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateNamedArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.duplicateNamedArgument,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDuplicatePart({required Uri p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.duplicatePart, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicatePatternAssignmentVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.duplicatePatternAssignmentVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsDuplicatePatternField({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.duplicatePatternField, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateVariablePattern({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.duplicateVariablePattern,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsEnumWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.enumWithAbstractMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsExpectedOneListPatternTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.expectedOneListPatternTypeArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExpectedOneListTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.expectedOneListTypeArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExpectedOneSetTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.expectedOneSetTypeArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExpectedTwoMapPatternTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.expectedTwoMapPatternTypeArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExpectedTwoMapTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.expectedTwoMapTypeArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExportInternalLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.exportInternalLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsExportOfNonLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.exportOfNonLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsExtendsDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extendsDisallowedClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExtensionAsExpression({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.extensionAsExpression, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsExtensionConflictingStaticAndInstance({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionConflictingStaticAndInstance,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtensionOverrideArgumentNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionOverrideArgumentNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeImplementsDisallowedType({required DartType p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionTypeImplementsDisallowedType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsExtensionTypeImplementsNotSupertype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionTypeImplementsNotSupertype,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeImplementsRepresentationNotSupertype({
    required DartType p0,
    required String p1,
    required DartType p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionTypeImplementsRepresentationNotSupertype,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeInheritedMemberConflict({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionTypeInheritedMemberConflict,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsExtensionTypeWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extensionTypeWithAbstractMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsExtraPositionalArguments({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extraPositionalArguments,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtraPositionalArgumentsCouldBeNamed({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.extraPositionalArgumentsCouldBeNamed,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFieldInitializedByMultipleInitializers({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.fieldInitializedByMultipleInitializers,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsFieldInitializerNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.fieldInitializerNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFieldInitializingFormalNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.fieldInitializingFormalNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsFinalClassExtendedOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFinalClassImplementedOutsideOfLibrary({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalClassUsedAsMixinConstraintOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFinalInitializedInDeclarationAndConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalInitializedInDeclarationAndConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitialized({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.finalNotInitialized, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor1({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalNotInitializedConstructor1,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor2({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalNotInitializedConstructor2,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor3Plus({
    required String p0,
    required String p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.finalNotInitializedConstructor3Plus,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsForInOfInvalidElementType({
    required DartType p0,
    required String p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.forInOfInvalidElementType,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsForInOfInvalidType({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.forInOfInvalidType, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsGetterNotAssignableSetterTypes({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.getterNotAssignableSetterTypes,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic _withArgumentsGetterNotSubtypeSetterTypes({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.getterNotSubtypeSetterTypes,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic
  _withArgumentsIllegalConcreteEnumMemberDeclaration({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.illegalConcreteEnumMemberDeclaration,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsIllegalConcreteEnumMemberInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.illegalConcreteEnumMemberInheritance,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsIllegalEnumValuesInheritance({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.illegalEnumValuesInheritance,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsIllegalLanguageVersionOverride({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.illegalLanguageVersionOverride,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsImplementsDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.implementsDisallowedClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsImplementsRepeated({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.implementsRepeated, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsImplementsSuperClass({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.implementsSuperClass, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsImplicitSuperInitializerMissingArguments({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.implicitSuperInitializerMissingArguments,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsImplicitThisReferenceInInitializer({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.implicitThisReferenceInInitializer,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsImportInternalLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.importInternalLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsImportOfNonLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.importOfNonLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInconsistentCaseExpressionTypes({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.inconsistentCaseExpressionTypes,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInconsistentInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.inconsistentInheritance,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInconsistentInheritanceGetterAndMethod({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.inconsistentInheritanceGetterAndMethod,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInconsistentPatternVariableLogicalOr({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.inconsistentPatternVariableLogicalOr,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInitializerForNonExistentField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.initializerForNonExistentField,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInitializerForStaticField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.initializerForStaticField,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInitializingFormalForNonExistentField({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.initializingFormalForNonExistentField,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInstanceAccessToStaticMember({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.instanceAccessToStaticMember,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.instanceAccessToStaticMemberOfUnnamedExtension,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsIntegerLiteralImpreciseAsDouble({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.integerLiteralImpreciseAsDouble,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsIntegerLiteralOutOfRange({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.integerLiteralOutOfRange,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInterfaceClassExtendedOutsideOfLibrary({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.interfaceClassExtendedOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidAssignment({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidAssignment, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastFunction({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastFunction, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastFunctionExpr({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidCastFunctionExpr,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteral({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastLiteral, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralList({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidCastLiteralList,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralMap({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastLiteralMap, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralSet({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastLiteralSet, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastMethod({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastMethod, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastNewExpr({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidCastNewExpr, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidImplementationOverride({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidImplementationOverride,
      [p0, p1, p2, p3, p4],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidImplementationOverrideSetter({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidImplementationOverrideSetter,
      [p0, p1, p2, p3, p4],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidModifierOnConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidModifierOnConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidOverride({
    required String p0,
    required String p1,
    required DartType p2,
    required String p3,
    required DartType p4,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidOverride, [
      p0,
      p1,
      p2,
      p3,
      p4,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOverrideSetter({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidOverrideSetter, [
      p0,
      p1,
      p2,
      p3,
      p4,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstList({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidTypeArgumentInConstList,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstMap({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidTypeArgumentInConstMap,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstSet({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invalidTypeArgumentInConstSet,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidUri({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.invalidUri, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvocationOfExtensionWithoutCall({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invocationOfExtensionWithoutCall,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvocationOfNonFunction({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.invocationOfNonFunction,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsLabelInOuterScope({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.labelInOuterScope, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsLabelUndefined({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.labelUndefined, [p0]);
  }

  static LocatableDiagnostic _withArgumentsListElementTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.listElementTypeNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsListElementTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.listElementTypeNotAssignableNullability,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mapKeyTypeNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mapKeyTypeNotAssignableNullability,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMapValueTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mapValueTypeNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMapValueTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mapValueTypeNotAssignableNullability,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingDartLibrary({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.missingDartLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingDefaultValueForParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.missingDefaultValueForParameter,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMissingDefaultValueForParameterPositional({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.missingDefaultValueForParameterPositional,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.missingRequiredArgument,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingVariablePattern({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.missingVariablePattern,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationConcreteSuperInvokedMemberType({
    required String p0,
    required DartType p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinApplicationConcreteSuperInvokedMemberType,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNoConcreteSuperInvokedMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinApplicationNoConcreteSuperInvokedMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinApplicationNoConcreteSuperInvokedSetter,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNotImplementedInterface({
    required DartType p0,
    required DartType p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinApplicationNotImplementedInterface,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinClassDeclarationExtendsNotObject({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinClassDeclarationExtendsNotObject,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinClassDeclaresConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinClassDeclaresConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinInheritsFromNotObject({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinInheritsFromNotObject,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinOfDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinOfDisallowedClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinsSuperClass({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.mixinsSuperClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinSubtypeOfBaseIsNotBase({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinSubtypeOfBaseIsNotBase,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinSubtypeOfFinalIsNotBase({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinSubtypeOfFinalIsNotBase,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinSuperClassConstraintDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.mixinSuperClassConstraintDisallowedClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNewWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.newWithNonType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNewWithUndefinedConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.newWithUndefinedConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsNewWithUndefinedConstructorDefault({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.newWithUndefinedConstructorDefault,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNoCombinedSuperSignature({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.noCombinedSuperSignature,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorExplicit({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.noDefaultSuperConstructorExplicit,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorImplicit({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.noDefaultSuperConstructorImplicit,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNoGenerativeConstructorsInSuperclass({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.noGenerativeConstructorsInSuperclass,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberFivePlus({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
    required int p4,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFivePlus,
      [p0, p1, p2, p3, p4],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberFour({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberFour,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberOne({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberThree({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberThree,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberTwo({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberTwo,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsNonBoolOperand({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.nonBoolOperand, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonExhaustiveSwitchExpression({
    required DartType p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonExhaustiveSwitchExpression,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsNonExhaustiveSwitchStatement({
    required DartType p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonExhaustiveSwitchStatement,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsNonGenerativeConstructor({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonGenerativeConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNonGenerativeImplicitConstructor({
    required String p0,
    required String p1,
    required Element p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.nonGenerativeImplicitConstructor,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsNonTypeAsTypeArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.nonTypeAsTypeArgument, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNonTypeInCatchClause({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.nonTypeInCatchClause, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notAssignedPotentiallyNonNullableLocalVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNotAType({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.notAType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNotBinaryOperator({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.notBinaryOperator, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNotEnoughPositionalArgumentsNamePlural({
    required int p0,
    required int p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notEnoughPositionalArgumentsNamePlural,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNotEnoughPositionalArgumentsNameSingular({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notEnoughPositionalArgumentsNameSingular,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsPlural({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notEnoughPositionalArgumentsPlural,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNotInitializedNonNullableInstanceField({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notInitializedNonNullableInstanceField,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNotInitializedNonNullableInstanceFieldConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notInitializedNonNullableInstanceFieldConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNotInitializedNonNullableVariable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.notInitializedNonNullableVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsOnRepeated({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.onRepeated, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPartOfDifferentLibrary({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.partOfDifferentLibrary,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsPartOfNonPart({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.partOfNonPart, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPartOfUnnamedLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.partOfUnnamedLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsPatternTypeMismatchInIrrefutableContext({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.patternTypeMismatchInIrrefutableContext,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode
          .patternVariableSharedCaseScopeDifferentFinalityOrType,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeHasLabel({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.patternVariableSharedCaseScopeHasLabel,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeNotAllCases({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.patternVariableSharedCaseScopeNotAllCases,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPrefixCollidesWithTopLevelMember({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.prefixCollidesWithTopLevelMember,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPrefixIdentifierNotFollowedByDot({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.prefixIdentifierNotFollowedByDot,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPrefixShadowedByLocalDeclaration({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.prefixShadowedByLocalDeclaration,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsPrivateCollisionInMixinApplication({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.privateCollisionInMixinApplication,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsPrivateSetter({required String p0}) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.privateSetter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsReadPotentiallyUnassignedFinal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.readPotentiallyUnassignedFinal,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.recursiveInterfaceInheritance,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsRecursiveInterfaceInheritanceExtends({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.recursiveInterfaceInheritanceExtends,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsRecursiveInterfaceInheritanceImplements({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.recursiveInterfaceInheritanceImplements,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceOn({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.recursiveInterfaceInheritanceOn,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceWith({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.recursiveInterfaceInheritanceWith,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsRedirectGenerativeToMissingConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.redirectGenerativeToMissingConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsRedirectToAbstractClassConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.redirectToAbstractClassConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsRedirectToInvalidFunctionType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.redirectToInvalidFunctionType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsRedirectToInvalidReturnType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.redirectToInvalidReturnType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsRedirectToMissingConstructor({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.redirectToMissingConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsRedirectToNonClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.redirectToNonClass, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsReferencedBeforeDeclaration({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.referencedBeforeDeclaration,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsRelationalPatternOperandTypeNotAssignable({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.relationalPatternOperandTypeNotAssignable,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromClosure({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.returnOfInvalidTypeFromClosure,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromConstructor({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.returnOfInvalidTypeFromConstructor,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromFunction({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.returnOfInvalidTypeFromFunction,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromMethod({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.returnOfInvalidTypeFromMethod,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsSealedClassSubtypeOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.sealedClassSubtypeOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsSetElementTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.setElementTypeNotAssignable,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsSetElementTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.setElementTypeNotAssignableNullability,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsStaticAccessToInstanceMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.staticAccessToInstanceMember,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.subtypeOfBaseIsNotBaseFinalOrSealed,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.subtypeOfFinalIsNotBaseFinalOrSealed,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.superFormalParameterTypeIsNotSubtypeOfAssociated,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsSuperInvocationNotLast({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.superInvocationNotLast,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsThrowOfInvalidType({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.throwOfInvalidType, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsTopLevelCycle({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.topLevelCycle, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsTypeAnnotationDeferredClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.typeAnnotationDeferredClass,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsTypeArgumentNotMatchingBounds({
    required DartType p0,
    required String p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.typeArgumentNotMatchingBounds,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsTypeParameterSupertypeOfItsBound({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.typeParameterSupertypeOfItsBound,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsTypeTestWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.typeTestWithNonType, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsTypeTestWithUndefinedName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.typeTestWithUndefinedName,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedMethodInvocationOfNullableValue({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.uncheckedMethodInvocationOfNullableValue,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedOperatorInvocationOfNullableValue({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.uncheckedOperatorInvocationOfNullableValue,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedPropertyAccessOfNullableValue({required String p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.uncheckedPropertyAccessOfNullableValue,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedAnnotation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedAnnotation, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedClassBoolean({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedClassBoolean, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializer({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedConstructorInInitializer,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUndefinedConstructorInInitializerDefault({required Object p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedConstructorInInitializerDefault,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedEnumConstant({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedEnumConstant, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedEnumConstructorNamed({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedEnumConstructorNamed,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionGetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedExtensionGetter,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionMethod({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedExtensionMethod,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionOperator({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedExtensionOperator,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionSetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedExtensionSetter,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedFunction({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedFunction, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedGetter({
    required String p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedGetter, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedGetterOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedGetterOnFunctionType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedIdentifier({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedIdentifier, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedMethod({
    required String p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedMethod, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedMethodOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedMethodOnFunctionType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedNamedParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedNamedParameter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedOperator({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedOperator, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedPrefixedName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedPrefixedName, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedSetter, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSetterOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedSetterOnFunctionType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperGetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedSuperGetter, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperMethod({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedSuperMethod, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperOperator({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.undefinedSuperOperator,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperSetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.undefinedSuperSetter, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsUnqualifiedReferenceToNonLocalStaticMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.unqualifiedReferenceToNonLocalStaticMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.unqualifiedReferenceToStaticMemberOfExtendedType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUriDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.uriDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUriHasNotBeenGenerated({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.uriHasNotBeenGenerated,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsVariableTypeMismatch({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.variableTypeMismatch, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongExplicitTypeParameterVarianceInSuperinterface,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperator({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfParametersForOperator,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfParametersForOperatorMinus({required int p0}) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfParametersForOperatorMinus,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArguments({
    required Object p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArguments,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsAnonymousFunction({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsAnonymousFunction,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsDotShorthandConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsEnum({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsEnum,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsExtension({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsExtension,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsFunction({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsFunction,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsMethod({
    required DartType p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongNumberOfTypeArgumentsMethod,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongTypeParameterVarianceInSuperinterface({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongTypeParameterVarianceInSuperinterface,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongTypeParameterVariancePosition({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.wrongTypeParameterVariancePosition,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsYieldEachOfInvalidType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      CompileTimeErrorCode.yieldEachOfInvalidType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsYieldOfInvalidType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(CompileTimeErrorCode.yieldOfInvalidType, [
      p0,
      p1,
    ]);
  }
}

final class CompileTimeErrorTemplate<T extends Function>
    extends CompileTimeErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class CompileTimeErrorWithoutArguments extends CompileTimeErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
  });
}

class StaticWarningCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const StaticWarningWithoutArguments
  deadNullAwareExpression = StaticWarningWithoutArguments(
    name: 'DEAD_NULL_AWARE_EXPRESSION',
    problemMessage:
        "The left operand can't be null, so the right operand is never executed.",
    correctionMessage: "Try removing the operator and the right operand.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION',
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments
  invalidNullAwareElement = StaticWarningWithoutArguments(
    name: 'INVALID_NULL_AWARE_OPERATOR',
    problemMessage:
        "The element can't be null, so the null-aware operator '?' is unnecessary.",
    correctionMessage: "Try removing the operator '?'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_ELEMENT',
    uniqueNameCheck: 'StaticWarningCode.INVALID_NULL_AWARE_ELEMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments
  invalidNullAwareMapEntryKey = StaticWarningWithoutArguments(
    name: 'INVALID_NULL_AWARE_OPERATOR',
    problemMessage:
        "The map entry key can't be null, so the null-aware operator '?' is "
        "unnecessary.",
    correctionMessage: "Try removing the operator '?'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_MAP_ENTRY_KEY',
    uniqueNameCheck: 'StaticWarningCode.INVALID_NULL_AWARE_MAP_ENTRY_KEY',
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments
  invalidNullAwareMapEntryValue = StaticWarningWithoutArguments(
    name: 'INVALID_NULL_AWARE_OPERATOR',
    problemMessage:
        "The map entry value can't be null, so the null-aware operator '?' is "
        "unnecessary.",
    correctionMessage: "Try removing the operator '?'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_MAP_ENTRY_VALUE',
    uniqueNameCheck: 'StaticWarningCode.INVALID_NULL_AWARE_MAP_ENTRY_VALUE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the null-aware operator that is invalid
  /// String p1: the non-null-aware operator that can replace the invalid
  ///            operator
  static const StaticWarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidNullAwareOperator = StaticWarningTemplate(
    name: 'INVALID_NULL_AWARE_OPERATOR',
    problemMessage:
        "The receiver can't be null, so the null-aware operator '{0}' is "
        "unnecessary.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'StaticWarningCode.INVALID_NULL_AWARE_OPERATOR',
    withArguments: _withArgumentsInvalidNullAwareOperator,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the null-aware operator that is invalid
  /// Object p1: the non-null-aware operator that can replace the invalid
  ///            operator
  static const StaticWarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidNullAwareOperatorAfterShortCircuit = StaticWarningTemplate(
    name: 'INVALID_NULL_AWARE_OPERATOR',
    problemMessage:
        "The receiver can't be 'null' because of short-circuiting, so the "
        "null-aware operator '{0}' can't be used.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
    uniqueNameCheck:
        'StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
    withArguments: _withArgumentsInvalidNullAwareOperatorAfterShortCircuit,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the constant that is missing
  static const StaticWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingEnumConstantInSwitch = StaticWarningTemplate(
    name: 'MISSING_ENUM_CONSTANT_IN_SWITCH',
    problemMessage: "Missing case clause for '{0}'.",
    correctionMessage:
        "Try adding a case clause for the missing constant, or adding a "
        "default clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH',
    withArguments: _withArgumentsMissingEnumConstantInSwitch,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments unnecessaryNonNullAssertion =
      StaticWarningWithoutArguments(
        name: 'UNNECESSARY_NON_NULL_ASSERTION',
        problemMessage:
            "The '!' will have no effect because the receiver can't be null.",
        correctionMessage: "Try removing the '!' operator.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const StaticWarningWithoutArguments
  unnecessaryNullAssertPattern = StaticWarningWithoutArguments(
    name: 'UNNECESSARY_NULL_ASSERT_PATTERN',
    problemMessage:
        "The null-assert pattern will have no effect because the matched type "
        "isn't nullable.",
    correctionMessage:
        "Try replacing the null-assert pattern with its nested pattern.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN',
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments
  unnecessaryNullCheckPattern = StaticWarningWithoutArguments(
    name: 'UNNECESSARY_NULL_CHECK_PATTERN',
    problemMessage:
        "The null-check pattern will have no effect because the matched type isn't "
        "nullable.",
    correctionMessage:
        "Try replacing the null-check pattern with its nested pattern.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN',
    expectedTypes: [],
  );

  /// Initialize a newly created error code to have the given [name].
  const StaticWarningCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required String super.uniqueNameCheck,
    required super.expectedTypes,
  }) : super(
         type: DiagnosticType.STATIC_WARNING,
         uniqueName: 'StaticWarningCode.${uniqueName ?? name}',
       );

  static LocatableDiagnostic _withArgumentsInvalidNullAwareOperator({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(StaticWarningCode.invalidNullAwareOperator, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidNullAwareOperatorAfterShortCircuit({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingEnumConstantInSwitch({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      StaticWarningCode.missingEnumConstantInSwitch,
      [p0],
    );
  }
}

final class StaticWarningTemplate<T extends Function>
    extends StaticWarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const StaticWarningTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class StaticWarningWithoutArguments extends StaticWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const StaticWarningWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
  });
}

class WarningCode extends DiagnosticCodeWithExpectedTypes {
  /// Parameters:
  /// Type p0: the name of the actual argument type
  /// Type p1: the name of the expected function return type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  argumentTypeNotAssignableToErrorHandler = WarningTemplate(
    name: 'ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
    problemMessage:
        "The argument type '{0}' can't be assigned to the parameter type '{1} "
        "Function(Object)' or '{1} Function(Object, StackTrace)'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'WarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
    withArguments: _withArgumentsArgumentTypeNotAssignableToErrorHandler,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Users should not assign values marked `@doNotStore`.
  ///
  /// Parameters:
  /// String p0: the name of the field or variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentOfDoNotStore = WarningTemplate(
    name: 'ASSIGNMENT_OF_DO_NOT_STORE',
    problemMessage:
        "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or "
        "top-level variable.",
    correctionMessage: "Try removing the assignment.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.ASSIGNMENT_OF_DO_NOT_STORE',
    withArguments: _withArgumentsAssignmentOfDoNotStore,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the return type as derived by the type of the [Future].
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyCatchError = WarningTemplate(
    name: 'BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR',
    problemMessage:
        "This 'onError' handler must return a value assignable to '{0}', but ends "
        "without returning a value.",
    correctionMessage: "Try adding a return statement.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR',
    withArguments: _withArgumentsBodyMightCompleteNormallyCatchError,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the name of the declared return type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyNullable = WarningTemplate(
    name: 'BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
    problemMessage:
        "This function has a nullable return type of '{0}', but ends without "
        "returning a value.",
    correctionMessage:
        "Try adding a return statement, or if no value is ever returned, try "
        "changing the return type to 'void'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
    withArguments: _withArgumentsBodyMightCompleteNormallyNullable,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the unassigned variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  castFromNullableAlwaysFails = WarningTemplate(
    name: 'CAST_FROM_NULLABLE_ALWAYS_FAILS',
    problemMessage:
        "This cast will always throw an exception because the nullable local "
        "variable '{0}' is not assigned.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned "
        "on every execution path.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.CAST_FROM_NULLABLE_ALWAYS_FAILS',
    withArguments: _withArgumentsCastFromNullableAlwaysFails,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  castFromNullAlwaysFails = WarningWithoutArguments(
    name: 'CAST_FROM_NULL_ALWAYS_FAILS',
    problemMessage:
        "This cast always throws an exception because the expression always "
        "evaluates to 'null'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.CAST_FROM_NULL_ALWAYS_FAILS',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the constant value type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constantPatternNeverMatchesValueType = WarningTemplate(
    name: 'CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE',
    problemMessage:
        "The matched value type '{0}' can never be equal to this constant of type "
        "'{1}'.",
    correctionMessage:
        "Try a constant of the same type as the matched value type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE',
    withArguments: _withArgumentsConstantPatternNeverMatchesValueType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Dead code is code that is never reached, this can happen for instance if a
  /// statement follows a return statement.
  ///
  /// No parameters.
  static const WarningWithoutArguments deadCode = WarningWithoutArguments(
    name: 'DEAD_CODE',
    problemMessage: "Dead code.",
    correctionMessage:
        "Try removing the code, or fixing the code before it so that it can be "
        "reached.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEAD_CODE',
    expectedTypes: [],
  );

  /// Dead code is code that is never reached. This case covers cases where the
  /// user has catch clauses after `catch (e)` or `on Object catch (e)`.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  deadCodeCatchFollowingCatch = WarningWithoutArguments(
    name: 'DEAD_CODE_CATCH_FOLLOWING_CATCH',
    problemMessage:
        "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
        "are never reached.",
    correctionMessage:
        "Try reordering the catch clauses so that they can be reached, or "
        "removing the unreachable catch clauses.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEAD_CODE_CATCH_FOLLOWING_CATCH',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  deadCodeLateWildcardVariableInitializer = WarningWithoutArguments(
    name: 'DEAD_CODE',
    problemMessage:
        "Dead code: The assigned-to wildcard variable is marked late and can never "
        "be referenced so this initializer will never be evaluated.",
    correctionMessage:
        "Try removing the code, removing the late modifier or changing the "
        "variable to a non-wildcard.",
    hasPublishedDocs: true,
    uniqueName: 'DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER',
    uniqueNameCheck: 'WarningCode.DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER',
    expectedTypes: [],
  );

  /// Dead code is code that is never reached. This case covers cases where the
  /// user has an on-catch clause such as `on A catch (e)`, where a supertype of
  /// `A` was already caught.
  ///
  /// Parameters:
  /// Type p0: name of the subtype
  /// Type p1: name of the supertype
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  deadCodeOnCatchSubtype = WarningTemplate(
    name: 'DEAD_CODE_ON_CATCH_SUBTYPE',
    problemMessage:
        "Dead code: This on-catch block won't be executed because '{0}' is a "
        "subtype of '{1}' and hence will have been caught already.",
    correctionMessage:
        "Try reordering the catch clauses so that this block can be reached, "
        "or removing the unreachable catch clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEAD_CODE_ON_CATCH_SUBTYPE',
    withArguments: _withArgumentsDeadCodeOnCatchSubtype,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the element
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedExportUse = WarningTemplate(
    name: 'DEPRECATED_EXPORT_USE',
    problemMessage: "The ability to import '{0}' indirectly is deprecated.",
    correctionMessage: "Try importing '{0}' directly.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEPRECATED_EXPORT_USE',
    withArguments: _withArgumentsDeprecatedExportUse,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedExtend = WarningTemplate(
    name: 'DEPRECATED_EXTEND',
    problemMessage: "Extending '{0}' is deprecated.",
    correctionMessage: "Try removing the 'extends' clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEPRECATED_EXTEND',
    withArguments: _withArgumentsDeprecatedExtend,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedExtendsFunction =
      WarningWithoutArguments(
        name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
        problemMessage: "Extending 'Function' is deprecated.",
        correctionMessage: "Try removing 'Function' from the 'extends' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_EXTENDS_FUNCTION',
        uniqueNameCheck: 'WarningCode.DEPRECATED_EXTENDS_FUNCTION',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedImplement = WarningTemplate(
    name: 'DEPRECATED_IMPLEMENT',
    problemMessage: "Implementing '{0}' is deprecated.",
    correctionMessage: "Try removing '{0}' from the 'implements' clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEPRECATED_IMPLEMENT',
    withArguments: _withArgumentsDeprecatedImplement,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedImplementsFunction =
      WarningWithoutArguments(
        name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
        problemMessage: "Implementing 'Function' has no effect.",
        correctionMessage:
            "Try removing 'Function' from the 'implements' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_IMPLEMENTS_FUNCTION',
        uniqueNameCheck: 'WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedInstantiate = WarningTemplate(
    name: 'DEPRECATED_INSTANTIATE',
    problemMessage: "Instantiating '{0}' is deprecated.",
    correctionMessage: "Try instantiating a non-abstract class.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEPRECATED_INSTANTIATE',
    withArguments: _withArgumentsDeprecatedInstantiate,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedMixin = WarningTemplate(
    name: 'DEPRECATED_MIXIN',
    problemMessage: "Mixing in '{0}' is deprecated.",
    correctionMessage: "Try removing '{0}' from the 'with' clause.",
    uniqueNameCheck: 'WarningCode.DEPRECATED_MIXIN',
    withArguments: _withArgumentsDeprecatedMixin,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedMixinFunction =
      WarningWithoutArguments(
        name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
        problemMessage: "Mixing in 'Function' is deprecated.",
        correctionMessage: "Try removing 'Function' from the 'with' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_MIXIN_FUNCTION',
        uniqueNameCheck: 'WarningCode.DEPRECATED_MIXIN_FUNCTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments deprecatedNewInCommentReference =
      WarningWithoutArguments(
        name: 'DEPRECATED_NEW_IN_COMMENT_REFERENCE',
        problemMessage:
            "Using the 'new' keyword in a comment reference is deprecated.",
        correctionMessage: "Try referring to a constructor by its name.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object parameterName: the name of the parameter
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object parameterName})
  >
  deprecatedOptional = WarningTemplate(
    name: 'DEPRECATED_OPTIONAL',
    problemMessage:
        "Omitting an argument for the '{0}' parameter is deprecated.",
    correctionMessage: "Try passing an argument for '{0}'.",
    uniqueNameCheck: 'WarningCode.DEPRECATED_OPTIONAL',
    withArguments: _withArgumentsDeprecatedOptional,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedSubclass = WarningTemplate(
    name: 'DEPRECATED_SUBCLASS',
    problemMessage: "Subclassing '{0}' is deprecated.",
    correctionMessage:
        "Try removing the 'extends' clause, or removing '{0}' from the "
        "'implements' clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DEPRECATED_SUBCLASS',
    withArguments: _withArgumentsDeprecatedSubclass,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the doc directive argument
  /// String p1: the expected format
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveArgumentWrongFormat = WarningTemplate(
    name: 'DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT',
    problemMessage: "The '{0}' argument must be formatted as {1}.",
    correctionMessage: "Try formatting '{0}' as {1}.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT',
    withArguments: _withArgumentsDocDirectiveArgumentWrongFormat,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the doc directive
  /// int p1: the actual number of arguments
  /// int p2: the expected number of arguments
  static const WarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required int p1,
      required int p2,
    })
  >
  docDirectiveHasExtraArguments = WarningTemplate(
    name: 'DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS',
    problemMessage:
        "The '{0}' directive has '{1}' arguments, but only '{2}' are expected.",
    correctionMessage: "Try removing the extra arguments.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS',
    withArguments: _withArgumentsDocDirectiveHasExtraArguments,
    expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the unexpected argument
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveHasUnexpectedNamedArgument = WarningTemplate(
    name: 'DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT',
    problemMessage:
        "The '{0}' directive has an unexpected named argument, '{1}'.",
    correctionMessage: "Try removing the unexpected argument.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT',
    withArguments: _withArgumentsDocDirectiveHasUnexpectedNamedArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments docDirectiveMissingClosingBrace =
      WarningWithoutArguments(
        name: 'DOC_DIRECTIVE_MISSING_CLOSING_BRACE',
        problemMessage: "Doc directive is missing a closing curly brace ('}').",
        correctionMessage: "Try closing the directive with a curly brace.",
        uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingClosingTag = WarningTemplate(
    name: 'DOC_DIRECTIVE_MISSING_CLOSING_TAG',
    problemMessage: "Doc directive is missing a closing tag.",
    correctionMessage:
        "Try closing the directive with the appropriate closing tag, '{0}'.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG',
    withArguments: _withArgumentsDocDirectiveMissingClosingTag,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the missing argument
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  docDirectiveMissingOneArgument = WarningTemplate(
    name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
    problemMessage: "The '{0}' directive is missing a '{1}' argument.",
    correctionMessage: "Try adding a '{1}' argument before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_ONE_ARGUMENT',
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT',
    withArguments: _withArgumentsDocDirectiveMissingOneArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingOpeningTag = WarningTemplate(
    name: 'DOC_DIRECTIVE_MISSING_OPENING_TAG',
    problemMessage: "Doc directive is missing an opening tag.",
    correctionMessage:
        "Try opening the directive with the appropriate opening tag, '{0}'.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_OPENING_TAG',
    withArguments: _withArgumentsDocDirectiveMissingOpeningTag,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the first missing argument
  /// String p2: the name of the second missing argument
  /// String p3: the name of the third missing argument
  static const WarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
      required String p3,
    })
  >
  docDirectiveMissingThreeArguments = WarningTemplate(
    name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
    problemMessage:
        "The '{0}' directive is missing a '{1}', a '{2}', and a '{3}' argument.",
    correctionMessage:
        "Try adding the missing arguments before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS',
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS',
    withArguments: _withArgumentsDocDirectiveMissingThreeArguments,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the doc directive
  /// String p1: the name of the first missing argument
  /// String p2: the name of the second missing argument
  static const WarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  docDirectiveMissingTwoArguments = WarningTemplate(
    name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
    problemMessage:
        "The '{0}' directive is missing a '{1}' and a '{2}' argument.",
    correctionMessage:
        "Try adding the missing arguments before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS',
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS',
    withArguments: _withArgumentsDocDirectiveMissingTwoArguments,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the unknown doc directive.
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveUnknown = WarningTemplate(
    name: 'DOC_DIRECTIVE_UNKNOWN',
    problemMessage: "Doc directive '{0}' is unknown.",
    correctionMessage: "Try using one of the supported doc directives.",
    uniqueNameCheck: 'WarningCode.DOC_DIRECTIVE_UNKNOWN',
    withArguments: _withArgumentsDocDirectiveUnknown,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotBeDeferred =
      WarningWithoutArguments(
        name: 'DOC_IMPORT_CANNOT_BE_DEFERRED',
        problemMessage: "Doc imports can't be deferred.",
        correctionMessage: "Try removing the 'deferred' keyword.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DOC_IMPORT_CANNOT_BE_DEFERRED',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHaveCombinators =
      WarningWithoutArguments(
        name: 'DOC_IMPORT_CANNOT_HAVE_COMBINATORS',
        problemMessage: "Doc imports can't have show or hide combinators.",
        correctionMessage: "Try removing the combinator.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_COMBINATORS',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHaveConfigurations =
      WarningWithoutArguments(
        name: 'DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS',
        problemMessage: "Doc imports can't have configurations.",
        correctionMessage: "Try removing the configurations.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHavePrefix =
      WarningWithoutArguments(
        name: 'DOC_IMPORT_CANNOT_HAVE_PREFIX',
        problemMessage: "Doc imports can't have prefixes.",
        correctionMessage: "Try removing the prefix.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_PREFIX',
        expectedTypes: [],
      );

  /// Duplicate exports.
  ///
  /// No parameters.
  static const WarningWithoutArguments duplicateExport =
      WarningWithoutArguments(
        name: 'DUPLICATE_EXPORT',
        problemMessage: "Duplicate export.",
        correctionMessage: "Try removing all but one export of the library.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DUPLICATE_EXPORT',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments duplicateHiddenName =
      WarningWithoutArguments(
        name: 'DUPLICATE_HIDDEN_NAME',
        problemMessage: "Duplicate hidden name.",
        correctionMessage:
            "Try removing the repeated name from the list of hidden members.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DUPLICATE_HIDDEN_NAME',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the diagnostic being ignored
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateIgnore = WarningTemplate(
    name: 'DUPLICATE_IGNORE',
    problemMessage:
        "The diagnostic '{0}' doesn't need to be ignored here because it's already "
        "being ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.DUPLICATE_IGNORE',
    withArguments: _withArgumentsDuplicateIgnore,
    expectedTypes: [ExpectedType.string],
  );

  /// Duplicate imports.
  ///
  /// No parameters.
  static const WarningWithoutArguments duplicateImport =
      WarningWithoutArguments(
        name: 'DUPLICATE_IMPORT',
        problemMessage: "Duplicate import.",
        correctionMessage: "Try removing all but one import of the library.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DUPLICATE_IMPORT',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments duplicateShownName =
      WarningWithoutArguments(
        name: 'DUPLICATE_SHOWN_NAME',
        problemMessage: "Duplicate shown name.",
        correctionMessage:
            "Try removing the repeated name from the list of shown members.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.DUPLICATE_SHOWN_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments equalElementsInSet =
      WarningWithoutArguments(
        name: 'EQUAL_ELEMENTS_IN_SET',
        problemMessage: "Two elements in a set literal shouldn't be equal.",
        correctionMessage: "Change or remove the duplicate element.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.EQUAL_ELEMENTS_IN_SET',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments equalKeysInMap = WarningWithoutArguments(
    name: 'EQUAL_KEYS_IN_MAP',
    problemMessage: "Two keys in a map literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.EQUAL_KEYS_IN_MAP',
    expectedTypes: [],
  );

  /// Parameters:
  /// String member: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String member})
  >
  experimentalMemberUse = WarningTemplate(
    name: 'EXPERIMENTAL_MEMBER_USE',
    problemMessage:
        "'{0}' is experimental and could be removed or changed at any time.",
    uniqueNameCheck: 'WarningCode.EXPERIMENTAL_MEMBER_USE',
    withArguments: _withArgumentsExperimentalMemberUse,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" is enabled, collection literal types must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the collection
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnCollectionLiteral = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
    problemMessage: "The type argument(s) of '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
    withArguments: _withArgumentsInferenceFailureOnCollectionLiteral,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" is enabled, types in function invocations must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the function
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnFunctionInvocation = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
    problemMessage:
        "The type argument(s) of the function '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
    withArguments: _withArgumentsInferenceFailureOnFunctionInvocation,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" is enabled, recursive local functions, top-level
  /// functions, methods, and function-typed function parameters must all
  /// specify a return type. See the strict-inference resource:
  ///
  /// https://github.com/dart-lang/language/blob/master/resources/type-system/strict-inference.md
  ///
  /// Parameters:
  /// String p0: the name of the function or method whose return type can't be
  ///            inferred
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnFunctionReturnType = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
    problemMessage: "The return type of '{0}' can't be inferred.",
    correctionMessage: "Declare the return type of '{0}'.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
    withArguments: _withArgumentsInferenceFailureOnFunctionReturnType,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" is enabled, types in function invocations must be
  /// inferred via the context type, or have type arguments.
  ///
  /// Parameters:
  /// String p0: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnGenericInvocation = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
    problemMessage:
        "The type argument(s) of the generic function type '{0}' can't be "
        "inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
    withArguments: _withArgumentsInferenceFailureOnGenericInvocation,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" is enabled, types in instance creation
  /// (constructor calls) must be inferred via the context type, or have type
  /// arguments.
  ///
  /// Parameters:
  /// String p0: the name of the constructor
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnInstanceCreation = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
    problemMessage:
        "The type argument(s) of the constructor '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION',
    withArguments: _withArgumentsInferenceFailureOnInstanceCreation,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" in enabled, uninitialized variables must be
  /// declared with a specific type.
  ///
  /// Parameters:
  /// String p0: the name of the variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnUninitializedVariable = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
    problemMessage:
        "The type of {0} can't be inferred without either a type or initializer.",
    correctionMessage: "Try specifying the type of the variable.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
    withArguments: _withArgumentsInferenceFailureOnUninitializedVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// When "strict-inference" in enabled, function parameters must be
  /// declared with a specific type, or inherit a type.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inferenceFailureOnUntypedParameter = WarningTemplate(
    name: 'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
    problemMessage:
        "The type of {0} can't be inferred; a type must be explicitly provided.",
    correctionMessage: "Try specifying the type of the parameter.",
    uniqueNameCheck: 'WarningCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
    withArguments: _withArgumentsInferenceFailureOnUntypedParameter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the annotation
  /// String p1: the list of valid targets
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidAnnotationTarget = WarningTemplate(
    name: 'INVALID_ANNOTATION_TARGET',
    problemMessage: "The annotation '{0}' can only be used on {1}.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_ANNOTATION_TARGET',
    withArguments: _withArgumentsInvalidAnnotationTarget,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidAwaitNotRequiredAnnotation =
      WarningWithoutArguments(
        name: 'INVALID_AWAIT_NOT_REQUIRED_ANNOTATION',
        problemMessage:
            "The annotation 'awaitNotRequired' can only be applied to a "
            "Future-returning function, or a Future-typed field.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.INVALID_AWAIT_NOT_REQUIRED_ANNOTATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedExtendAnnotation = WarningWithoutArguments(
    name: 'INVALID_DEPRECATED_EXTEND_ANNOTATION',
    problemMessage:
        "The annotation '@Deprecated.extend' can only be applied to extendable "
        "classes.",
    correctionMessage: "Try removing the '@Deprecated.extend' annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_EXTEND_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidDeprecatedImplementAnnotation =
      WarningWithoutArguments(
        name: 'INVALID_DEPRECATED_IMPLEMENT_ANNOTATION',
        problemMessage:
            "The annotation '@Deprecated.implement' can only be applied to "
            "implementable classes.",
        correctionMessage:
            "Try removing the '@Deprecated.implement' annotation.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_IMPLEMENT_ANNOTATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedInstantiateAnnotation = WarningWithoutArguments(
    name: 'INVALID_DEPRECATED_INSTANTIATE_ANNOTATION',
    problemMessage:
        "The annotation '@Deprecated.instantiate' can only be applied to classes.",
    correctionMessage: "Try removing the '@Deprecated.instantiate' annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_INSTANTIATE_ANNOTATION',
    expectedTypes: [],
  );

  /// This warning is generated anywhere where `@Deprecated.mixin` annotates
  /// something other than a mixin class.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedMixinAnnotation = WarningWithoutArguments(
    name: 'INVALID_DEPRECATED_MIXIN_ANNOTATION',
    problemMessage:
        "The annotation '@Deprecated.mixin' can only be applied to classes.",
    correctionMessage: "Try removing the '@Deprecated.mixin' annotation.",
    uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_MIXIN_ANNOTATION',
    expectedTypes: [],
  );

  /// This warning is generated anywhere where `@Deprecated.optional`
  /// annotates something other than an optional parameter.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedOptionalAnnotation = WarningWithoutArguments(
    name: 'INVALID_DEPRECATED_OPTIONAL_ANNOTATION',
    problemMessage:
        "The annotation '@Deprecated.optional' can only be applied to optional "
        "parameters.",
    correctionMessage: "Try removing the '@Deprecated.optional' annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_OPTIONAL_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedSubclassAnnotation = WarningWithoutArguments(
    name: 'INVALID_DEPRECATED_SUBCLASS_ANNOTATION',
    problemMessage:
        "The annotation '@Deprecated.subclass' can only be applied to subclassable "
        "classes and mixins.",
    correctionMessage: "Try removing the '@Deprecated.subclass' annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_DEPRECATED_SUBCLASS_ANNOTATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the element
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidExportOfInternalElement = WarningTemplate(
    name: 'INVALID_EXPORT_OF_INTERNAL_ELEMENT',
    problemMessage:
        "The member '{0}' can't be exported as a part of a package's public API.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT',
    withArguments: _withArgumentsInvalidExportOfInternalElement,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the internal element
  /// String p1: the name of the exported element that indirectly exposes the
  ///            internal element
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidExportOfInternalElementIndirectly = WarningTemplate(
    name: 'INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
    problemMessage:
        "The member '{0}' can't be exported as a part of a package's public API, "
        "but is indirectly exported as part of the signature of '{1}'.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck:
        'WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
    withArguments: _withArgumentsInvalidExportOfInternalElementIndirectly,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: The name of the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodDecl = WarningTemplate(
    name: 'INVALID_FACTORY_METHOD_DECL',
    problemMessage: "Factory method '{0}' must have a return type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_FACTORY_METHOD_DECL',
    withArguments: _withArgumentsInvalidFactoryMethodDecl,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodImpl = WarningTemplate(
    name: 'INVALID_FACTORY_METHOD_IMPL',
    problemMessage:
        "Factory method '{0}' doesn't return a newly allocated object.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_FACTORY_METHOD_IMPL',
    withArguments: _withArgumentsInvalidFactoryMethodImpl,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidInternalAnnotation = WarningWithoutArguments(
    name: 'INVALID_INTERNAL_ANNOTATION',
    problemMessage:
        "Only public elements in a package's private API can be annotated as being "
        "internal.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_INTERNAL_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideAtSign = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override number must begin with '@dart'.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideEquals = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override comment must be specified with an '=' "
        "character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the latest major version
  /// Object p1: the latest minor version
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidLanguageVersionOverrideGreater = WarningTemplate(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The language version override can't specify a version greater than the "
        "latest known language version: {0}.{1}.",
    correctionMessage: "Try removing the language version override.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
    withArguments: _withArgumentsInvalidLanguageVersionOverrideGreater,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideLocation = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The language version override must be specified before any declaration or "
        "directive.",
    correctionMessage:
        "Try moving the language version override to the top of the file.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideLowerCase = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override comment must be specified with the "
        "word 'dart' in all lower case.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideNumber = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override comment must be specified with a "
        "version number, like '2.0', after the '=' character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverridePrefix = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override number can't be prefixed with a "
        "letter.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
    uniqueNameCheck: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideTrailingCharacters = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override comment can't be followed by any "
        "non-whitespace characters.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
    uniqueNameCheck:
        'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideTwoSlashes = WarningWithoutArguments(
    name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
    problemMessage:
        "The Dart language version override comment must be specified with exactly "
        "two slashes.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
    uniqueNameCheck:
        'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidLiteralAnnotation =
      WarningWithoutArguments(
        name: 'INVALID_LITERAL_ANNOTATION',
        problemMessage:
            "Only const constructors can have the `@literal` annotation.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.INVALID_LITERAL_ANNOTATION',
        expectedTypes: [],
      );

  /// This warning is generated anywhere where `@nonVirtual` annotates something
  /// other than a non-abstract instance member in a class or mixin.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  invalidNonVirtualAnnotation = WarningWithoutArguments(
    name: 'INVALID_NON_VIRTUAL_ANNOTATION',
    problemMessage:
        "The annotation '@nonVirtual' can only be applied to a concrete instance "
        "member.",
    correctionMessage: "Try removing '@nonVirtual'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_NON_VIRTUAL_ANNOTATION',
    expectedTypes: [],
  );

  /// This warning is generated anywhere where an instance member annotated with
  /// `@nonVirtual` is overridden in a subclass.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the defining class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidOverrideOfNonVirtualMember = WarningTemplate(
    name: 'INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
    problemMessage:
        "The member '{0}' is declared non-virtual in '{1}' and can't be overridden "
        "in subclasses.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
    withArguments: _withArgumentsInvalidOverrideOfNonVirtualMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// This warning is generated anywhere where `@reopen` annotates a class which
  /// did not reopen any type.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  invalidReopenAnnotation = WarningWithoutArguments(
    name: 'INVALID_REOPEN_ANNOTATION',
    problemMessage:
        "The annotation '@reopen' can only be applied to a class that opens "
        "capabilities that the supertype intentionally disallows.",
    correctionMessage: "Try removing the '@reopen' annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_REOPEN_ANNOTATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfDoNotSubmitMember = WarningTemplate(
    name: 'INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER',
    problemMessage: "Uses of '{0}' should not be submitted to source control.",
    correctionMessage: "Try removing the reference to '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER',
    withArguments: _withArgumentsInvalidUseOfDoNotSubmitMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfInternalMember = WarningTemplate(
    name: 'INVALID_USE_OF_INTERNAL_MEMBER',
    problemMessage: "The member '{0}' can only be used within its package.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_INTERNAL_MEMBER',
    withArguments: _withArgumentsInvalidUseOfInternalMember,
    expectedTypes: [ExpectedType.string],
  );

  /// This warning is generated anywhere where a member annotated with
  /// `@protected` is used outside of an instance member of a subclass.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the defining class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidUseOfProtectedMember = WarningTemplate(
    name: 'INVALID_USE_OF_PROTECTED_MEMBER',
    problemMessage:
        "The member '{0}' can only be used within instance members of subclasses "
        "of '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_PROTECTED_MEMBER',
    withArguments: _withArgumentsInvalidUseOfProtectedMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfVisibleForOverridingMember = WarningTemplate(
    name: 'INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
    problemMessage: "The member '{0}' can only be used for overriding.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
    withArguments: _withArgumentsInvalidUseOfVisibleForOverridingMember,
    expectedTypes: [ExpectedType.string],
  );

  /// This warning is generated anywhere where a member annotated with
  /// `@visibleForTemplate` is used outside of a "template" Dart file.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// Uri p1: the name of the defining class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required Uri p1})
  >
  invalidUseOfVisibleForTemplateMember = WarningTemplate(
    name: 'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
    problemMessage:
        "The member '{0}' can only be used within '{1}' or a template library.",
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
    withArguments: _withArgumentsInvalidUseOfVisibleForTemplateMember,
    expectedTypes: [ExpectedType.string, ExpectedType.uri],
  );

  /// This warning is generated anywhere where a member annotated with
  /// `@visibleForTesting` is used outside the defining library, or a test.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// Uri p1: the name of the defining class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required Uri p1})
  >
  invalidUseOfVisibleForTestingMember = WarningTemplate(
    name: 'INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
    problemMessage: "The member '{0}' can only be used within '{1}' or a test.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
    withArguments: _withArgumentsInvalidUseOfVisibleForTestingMember,
    expectedTypes: [ExpectedType.string, ExpectedType.uri],
  );

  /// This warning is generated anywhere where a private declaration is
  /// annotated with `@visibleForTemplate` or `@visibleForTesting`.
  ///
  /// Parameters:
  /// String p0: the name of the member
  /// String p1: the name of the annotation
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidVisibilityAnnotation = WarningTemplate(
    name: 'INVALID_VISIBILITY_ANNOTATION',
    problemMessage:
        "The member '{0}' is annotated with '{1}', but this annotation is only "
        "meaningful on declarations of public members.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_VISIBILITY_ANNOTATION',
    withArguments: _withArgumentsInvalidVisibilityAnnotation,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidVisibleForOverridingAnnotation = WarningWithoutArguments(
    name: 'INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
    problemMessage:
        "The annotation 'visibleForOverriding' can only be applied to a public "
        "instance member that can be overridden.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidVisibleOutsideTemplateAnnotation = WarningWithoutArguments(
    name: 'INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION',
    problemMessage:
        "The annotation 'visibleOutsideTemplate' can only be applied to a member "
        "of a class, enum, or mixin that is annotated with "
        "'visibleForTemplate'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidWidgetPreviewApplication = WarningWithoutArguments(
    name: 'INVALID_WIDGET_PREVIEW_APPLICATION',
    problemMessage:
        "The '@Preview(...)' annotation can only be applied to public, statically "
        "accessible constructors and functions.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_WIDGET_PREVIEW_APPLICATION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the private symbol
  /// String p1: the name of the proposed public symbol equivalent
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidWidgetPreviewPrivateArgument = WarningTemplate(
    name: 'INVALID_WIDGET_PREVIEW_PRIVATE_ARGUMENT',
    problemMessage:
        "'@Preview(...)' can only accept arguments that consist of literals and "
        "public symbols.",
    correctionMessage: "Rename private symbol '{0}' to '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.INVALID_WIDGET_PREVIEW_PRIVATE_ARGUMENT',
    withArguments: _withArgumentsInvalidWidgetPreviewPrivateArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingOverrideOfMustBeOverriddenOne = WarningTemplate(
    name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    problemMessage: "Missing concrete implementation of '{0}'.",
    correctionMessage: "Try overriding the missing member.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE',
    uniqueNameCheck: 'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE',
    withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenOne,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  /// String p2: the number of additional missing members that aren't listed
  static const WarningTemplate<
    LocatableDiagnostic Function({
      required String p0,
      required String p1,
      required String p2,
    })
  >
  missingOverrideOfMustBeOverriddenThreePlus = WarningTemplate(
    name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    problemMessage:
        "Missing concrete implementations of '{0}', '{1}', and {2} more.",
    correctionMessage: "Try overriding the missing members.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS',
    uniqueNameCheck:
        'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS',
    withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// Parameters:
  /// String p0: the name of the first member
  /// String p1: the name of the second member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  missingOverrideOfMustBeOverriddenTwo = WarningTemplate(
    name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    problemMessage: "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage: "Try overriding the missing members.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO',
    uniqueNameCheck: 'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO',
    withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenTwo,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Generates a warning for a constructor, function or method invocation where
  /// a required parameter is missing.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingRequiredParam = WarningTemplate(
    name: 'MISSING_REQUIRED_PARAM',
    problemMessage: "The parameter '{0}' is required.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.MISSING_REQUIRED_PARAM',
    withArguments: _withArgumentsMissingRequiredParam,
    expectedTypes: [ExpectedType.string],
  );

  /// Generates a warning for a constructor, function or method invocation where
  /// a required parameter is missing.
  ///
  /// Parameters:
  /// String p0: the name of the parameter
  /// String p1: message details
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  missingRequiredParamWithDetails = WarningTemplate(
    name: 'MISSING_REQUIRED_PARAM',
    problemMessage: "The parameter '{0}' is required. {1}.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_REQUIRED_PARAM_WITH_DETAILS',
    uniqueNameCheck: 'WarningCode.MISSING_REQUIRED_PARAM_WITH_DETAILS',
    withArguments: _withArgumentsMissingRequiredParamWithDetails,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// This warning is generated anywhere where a `@sealed` class is used as a
  /// a superclass constraint of a mixin.
  ///
  /// Parameters:
  /// String p0: the name of the sealed class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinOnSealedClass = WarningTemplate(
    name: 'MIXIN_ON_SEALED_CLASS',
    problemMessage:
        "The class '{0}' shouldn't be used as a mixin constraint because it is "
        "sealed, and any class mixing in this mixin must have '{0}' as a "
        "superclass.",
    correctionMessage:
        "Try composing with this class, or refer to its documentation for more "
        "information.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.MIXIN_ON_SEALED_CLASS',
    withArguments: _withArgumentsMixinOnSealedClass,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  multipleCombinators = WarningWithoutArguments(
    name: 'MULTIPLE_COMBINATORS',
    problemMessage:
        "Using multiple 'hide' or 'show' combinators is never necessary and often "
        "produces surprising results.",
    correctionMessage: "Try using a single combinator.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.MULTIPLE_COMBINATORS',
    expectedTypes: [],
  );

  /// Generates a warning for classes that inherit from classes annotated with
  /// `@immutable` but that are not immutable.
  ///
  /// Parameters:
  /// String p0: the name of the class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mustBeImmutable = WarningTemplate(
    name: 'MUST_BE_IMMUTABLE',
    problemMessage:
        "This class (or a class that this class inherits from) is marked as "
        "'@immutable', but one or more of its instance fields aren't final: "
        "{0}",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.MUST_BE_IMMUTABLE',
    withArguments: _withArgumentsMustBeImmutable,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class declaring the overridden method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mustCallSuper = WarningTemplate(
    name: 'MUST_CALL_SUPER',
    problemMessage:
        "This method overrides a method annotated as '@mustCallSuper' in '{0}', "
        "but doesn't invoke the overridden method.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.MUST_CALL_SUPER',
    withArguments: _withArgumentsMustCallSuper,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the argument
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstArgumentForConstParameter = WarningTemplate(
    name: 'NON_CONST_ARGUMENT_FOR_CONST_PARAMETER',
    problemMessage: "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the argument with a constant.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER',
    withArguments: _withArgumentsNonConstArgumentForConstParameter,
    expectedTypes: [ExpectedType.string],
  );

  /// Generates a warning for non-const instance creation using a constructor
  /// annotated with `@literal`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the annotated constructor
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstCallToLiteralConstructor = WarningTemplate(
    name: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    problemMessage:
        "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try adding a 'const' keyword.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    withArguments: _withArgumentsNonConstCallToLiteralConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// Generate a warning for non-const instance creation (with the `new` keyword)
  /// using a constructor annotated with `@literal`.
  ///
  /// Parameters:
  /// String p0: the name of the class defining the annotated constructor
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstCallToLiteralConstructorUsingNew = WarningTemplate(
    name: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    problemMessage:
        "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try replacing the 'new' keyword with 'const'.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
    uniqueNameCheck:
        'WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
    withArguments: _withArgumentsNonConstCallToLiteralConstructorUsingNew,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments nonNullableEqualsParameter =
      WarningWithoutArguments(
        name: 'NON_NULLABLE_EQUALS_PARAMETER',
        problemMessage:
            "The parameter type of '==' operators should be non-nullable.",
        correctionMessage: "Try using a non-nullable type.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.NON_NULLABLE_EQUALS_PARAMETER',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  nullableTypeInCatchClause = WarningWithoutArguments(
    name: 'NULLABLE_TYPE_IN_CATCH_CLAUSE',
    problemMessage:
        "A potentially nullable type can't be used in an 'on' clause because it "
        "isn't valid to throw a nullable expression.",
    correctionMessage: "Try using a non-nullable type.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method being invoked
  /// String p1: the type argument associated with the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  nullArgumentToNonNullType = WarningTemplate(
    name: 'NULL_ARGUMENT_TO_NON_NULL_TYPE',
    problemMessage:
        "'{0}' shouldn't be called with a 'null' argument for the non-nullable "
        "type argument '{1}'.",
    correctionMessage: "Try adding a non-null argument.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE',
    withArguments: _withArgumentsNullArgumentToNonNullType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  nullCheckAlwaysFails = WarningWithoutArguments(
    name: 'NULL_CHECK_ALWAYS_FAILS',
    problemMessage:
        "This null-check will always throw an exception because the expression "
        "will always evaluate to 'null'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.NULL_CHECK_ALWAYS_FAILS',
    expectedTypes: [],
  );

  /// A field with the override annotation does not override a getter or setter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingField =
      WarningWithoutArguments(
        name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        problemMessage:
            "The field doesn't override an inherited getter or setter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_FIELD',
        uniqueNameCheck: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD',
        expectedTypes: [],
      );

  /// A getter with the override annotation does not override an existing getter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingGetter =
      WarningWithoutArguments(
        name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        problemMessage: "The getter doesn't override an inherited getter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_GETTER',
        uniqueNameCheck: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_GETTER',
        expectedTypes: [],
      );

  /// A method with the override annotation does not override an existing method.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingMethod =
      WarningWithoutArguments(
        name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        problemMessage: "The method doesn't override an inherited method.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_METHOD',
        uniqueNameCheck: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD',
        expectedTypes: [],
      );

  /// A setter with the override annotation does not override an existing setter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingSetter =
      WarningWithoutArguments(
        name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        problemMessage: "The setter doesn't override an inherited setter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_SETTER',
        uniqueNameCheck: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_SETTER',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the required pattern type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternNeverMatchesValueType = WarningTemplate(
    name: 'PATTERN_NEVER_MATCHES_VALUE_TYPE',
    problemMessage:
        "The matched value type '{0}' can never match the required type '{1}'.",
    correctionMessage: "Try using a different pattern.",
    uniqueNameCheck: 'WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE',
    withArguments: _withArgumentsPatternNeverMatchesValueType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// It is not an error to call or tear-off a method, setter, or getter, or to
  /// read or write a field, on a receiver of static type `Never`.
  /// Implementations that provide feedback about dead or unreachable code are
  /// encouraged to indicate that any arguments to the invocation are
  /// unreachable.
  ///
  /// It is not an error to apply an expression of type `Never` in the function
  /// position of a function call. Implementations that provide feedback about
  /// dead or unreachable code are encouraged to indicate that any arguments to
  /// the call are unreachable.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  receiverOfTypeNever = WarningWithoutArguments(
    name: 'RECEIVER_OF_TYPE_NEVER',
    problemMessage:
        "The receiver is of type 'Never', and will never complete with a value.",
    correctionMessage:
        "Try checking for throw expressions or type errors in the receiver",
    uniqueNameCheck: 'WarningCode.RECEIVER_OF_TYPE_NEVER',
    expectedTypes: [],
  );

  /// An error code indicating the use of a redeclare annotation on a member that does not redeclare.
  ///
  /// Parameters:
  /// String p0: the kind of member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  redeclareOnNonRedeclaringMember = WarningTemplate(
    name: 'REDECLARE_ON_NON_REDECLARING_MEMBER',
    problemMessage:
        "The {0} doesn't redeclare a {0} declared in a superinterface.",
    correctionMessage:
        "Try updating this member to match a declaration in a superinterface, "
        "or removing the redeclare annotation.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER',
    withArguments: _withArgumentsRedeclareOnNonRedeclaringMember,
    expectedTypes: [ExpectedType.string],
  );

  /// An error code indicating use of a removed lint rule.
  ///
  /// Parameters:
  /// Object p0: the rule name
  /// Object p1: the SDK version in which the lint was removed
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  removedLintUse = WarningTemplate(
    name: 'REMOVED_LINT_USE',
    problemMessage: "'{0}' was removed in Dart '{1}'",
    correctionMessage: "Remove the reference to '{0}'.",
    uniqueNameCheck: 'WarningCode.REMOVED_LINT_USE',
    withArguments: _withArgumentsRemovedLintUse,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// An error code indicating use of a removed lint rule.
  ///
  /// Parameters:
  /// Object p0: the rule name
  /// Object p1: the SDK version in which the lint was removed
  /// Object p2: the name of a replacing lint
  static const WarningTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  replacedLintUse = WarningTemplate(
    name: 'REPLACED_LINT_USE',
    problemMessage: "'{0}' was replaced by '{2}' in Dart '{1}'.",
    correctionMessage: "Replace '{0}' with '{1}'.",
    uniqueNameCheck: 'WarningCode.REPLACED_LINT_USE',
    withArguments: _withArgumentsReplacedLintUse,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// Parameters:
  /// String p0: the name of the annotated function being invoked
  /// String p1: the name of the function containing the return
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  returnOfDoNotStore = WarningTemplate(
    name: 'RETURN_OF_DO_NOT_STORE',
    problemMessage:
        "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless "
        "'{1}' is also annotated.",
    correctionMessage: "Annotate '{1}' with 'doNotStore'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.RETURN_OF_DO_NOT_STORE',
    withArguments: _withArgumentsReturnOfDoNotStore,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the type of the Future
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnOfInvalidTypeFromCatchError = WarningTemplate(
    name: 'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    problemMessage:
        "A value of type '{0}' can't be returned by the 'onError' handler because "
        "it must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
    uniqueNameCheck: 'WarningCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
    withArguments: _withArgumentsReturnOfInvalidTypeFromCatchError,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the return type of the function
  /// Type p1: the expected return type as defined by the type of the Future
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnTypeInvalidForCatchError = WarningTemplate(
    name: 'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    problemMessage:
        "The return type '{0}' isn't assignable to '{1}', as required by "
        "'Future.catchError'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
    uniqueNameCheck: 'WarningCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
    withArguments: _withArgumentsReturnTypeInvalidForCatchError,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// There is also a [ParserErrorCode.experimentNotEnabled] code which
  /// catches some cases of constructor tearoff features (like
  /// `List<int>.filled;`). Other constructor tearoff cases are not realized
  /// until resolution (like `List.filled;`).
  ///
  /// No parameters.
  static const WarningWithoutArguments
  sdkVersionConstructorTearoffs = WarningWithoutArguments(
    name: 'SDK_VERSION_CONSTRUCTOR_TEAROFFS',
    problemMessage:
        "Tearing off a constructor requires the 'constructor-tearoffs' language "
        "feature.",
    correctionMessage:
        "Try updating your 'pubspec.yaml' to set the minimum SDK constraint to "
        "2.15 or higher, and running 'pub get'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  sdkVersionGtGtGtOperator = WarningWithoutArguments(
    name: 'SDK_VERSION_GT_GT_GT_OPERATOR',
    problemMessage:
        "The operator '>>>' wasn't supported until version 2.14.0, but this code "
        "is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the version specified in the `@Since()` annotation
  /// String p1: the SDK version constraints
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  sdkVersionSince = WarningTemplate(
    name: 'SDK_VERSION_SINCE',
    problemMessage:
        "This API is available since SDK {0}, but constraints '{1}' don't "
        "guarantee it.",
    correctionMessage: "Try updating the SDK constraints.",
    uniqueNameCheck: 'WarningCode.SDK_VERSION_SINCE',
    withArguments: _withArgumentsSdkVersionSince,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// When "strict-raw-types" is enabled, "raw types" must have type arguments.
  ///
  /// A "raw type" is a type name that does not use inference to fill in missing
  /// type arguments; instead, each type argument is instantiated to its bound.
  ///
  /// Parameters:
  /// Type p0: the name of the generic type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  strictRawType = WarningTemplate(
    name: 'STRICT_RAW_TYPE',
    problemMessage:
        "The generic type '{0}' should have explicit type arguments but doesn't.",
    correctionMessage: "Use explicit type arguments for '{0}'.",
    uniqueNameCheck: 'WarningCode.STRICT_RAW_TYPE',
    withArguments: _withArgumentsStrictRawType,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the sealed class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  subtypeOfSealedClass = WarningTemplate(
    name: 'SUBTYPE_OF_SEALED_CLASS',
    problemMessage:
        "The class '{0}' shouldn't be extended, mixed in, or implemented because "
        "it's sealed.",
    correctionMessage:
        "Try composing instead of inheriting, or refer to the documentation of "
        "'{0}' for more information.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.SUBTYPE_OF_SEALED_CLASS',
    withArguments: _withArgumentsSubtypeOfSealedClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInComment = WarningTemplate(
    name: 'TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    problemMessage:
        "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    withArguments: _withArgumentsTextDirectionCodePointInComment,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInLiteral = WarningTemplate(
    name: 'TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
    problemMessage:
        "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
    withArguments: _withArgumentsTextDirectionCodePointInLiteral,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments typeCheckIsNotNull =
      WarningWithoutArguments(
        name: 'TYPE_CHECK_WITH_NULL',
        problemMessage: "Tests for non-null should be done with '!= null'.",
        correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
        hasPublishedDocs: true,
        uniqueName: 'TYPE_CHECK_IS_NOT_NULL',
        uniqueNameCheck: 'WarningCode.TYPE_CHECK_IS_NOT_NULL',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments typeCheckIsNull =
      WarningWithoutArguments(
        name: 'TYPE_CHECK_WITH_NULL',
        problemMessage: "Tests for null should be done with '== null'.",
        correctionMessage: "Try replacing the 'is Null' check with '== null'.",
        hasPublishedDocs: true,
        uniqueName: 'TYPE_CHECK_IS_NULL',
        uniqueNameCheck: 'WarningCode.TYPE_CHECK_IS_NULL',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the library being imported
  /// String p1: the name in the hide clause that isn't defined in the library
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedHiddenName = WarningTemplate(
    name: 'UNDEFINED_HIDDEN_NAME',
    problemMessage:
        "The library '{0}' doesn't export a member with the hidden name '{1}'.",
    correctionMessage: "Try removing the name from the list of hidden members.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNDEFINED_HIDDEN_NAME',
    withArguments: _withArgumentsUndefinedHiddenName,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the undefined parameter
  /// String p1: the name of the targeted member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedReferencedParameter = WarningTemplate(
    name: 'UNDEFINED_REFERENCED_PARAMETER',
    problemMessage: "The parameter '{0}' isn't defined by '{1}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNDEFINED_REFERENCED_PARAMETER',
    withArguments: _withArgumentsUndefinedReferencedParameter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the library being imported
  /// String p1: the name in the show clause that isn't defined in the library
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedShownName = WarningTemplate(
    name: 'UNDEFINED_SHOWN_NAME',
    problemMessage:
        "The library '{0}' doesn't export a member with the shown name '{1}'.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNDEFINED_SHOWN_NAME',
    withArguments: _withArgumentsUndefinedShownName,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the non-diagnostic being ignored
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unignorableIgnore = WarningTemplate(
    name: 'UNIGNORABLE_IGNORE',
    problemMessage: "The diagnostic '{0}' can't be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
    uniqueNameCheck: 'WarningCode.UNIGNORABLE_IGNORE',
    withArguments: _withArgumentsUnignorableIgnore,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryCast =
      WarningWithoutArguments(
        name: 'UNNECESSARY_CAST',
        problemMessage: "Unnecessary cast.",
        correctionMessage: "Try removing the cast.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNNECESSARY_CAST',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryCastPattern =
      WarningWithoutArguments(
        name: 'UNNECESSARY_CAST_PATTERN',
        problemMessage: "Unnecessary cast pattern.",
        correctionMessage: "Try removing the cast pattern.",
        uniqueNameCheck: 'WarningCode.UNNECESSARY_CAST_PATTERN',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryFinal = WarningWithoutArguments(
    name: 'UNNECESSARY_FINAL',
    problemMessage:
        "The keyword 'final' isn't necessary because the parameter is implicitly "
        "'final'.",
    correctionMessage: "Try removing the 'final'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNNECESSARY_FINAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryNanComparisonFalse = WarningWithoutArguments(
    name: 'UNNECESSARY_NAN_COMPARISON',
    problemMessage:
        "A double can't equal 'double.nan', so the condition is always 'false'.",
    correctionMessage: "Try using 'double.isNan', or removing the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NAN_COMPARISON_FALSE',
    uniqueNameCheck: 'WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryNanComparisonTrue = WarningWithoutArguments(
    name: 'UNNECESSARY_NAN_COMPARISON',
    problemMessage:
        "A double can't equal 'double.nan', so the condition is always 'true'.",
    correctionMessage: "Try using 'double.isNan', or removing the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NAN_COMPARISON_TRUE',
    uniqueNameCheck: 'WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNoSuchMethod =
      WarningWithoutArguments(
        name: 'UNNECESSARY_NO_SUCH_METHOD',
        problemMessage: "Unnecessary 'noSuchMethod' declaration.",
        correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNNECESSARY_NO_SUCH_METHOD',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryNullComparisonAlwaysNullFalse = WarningWithoutArguments(
    name: 'UNNECESSARY_NULL_COMPARISON',
    problemMessage:
        "The operand must be 'null', so the condition is always 'false'.",
    correctionMessage: "Remove the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_FALSE',
    uniqueNameCheck:
        'WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_FALSE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonAlwaysNullTrue =
      WarningWithoutArguments(
        name: 'UNNECESSARY_NULL_COMPARISON',
        problemMessage:
            "The operand must be 'null', so the condition is always 'true'.",
        correctionMessage: "Remove the condition.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_TRUE',
        uniqueNameCheck:
            'WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_TRUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonNeverNullFalse =
      WarningWithoutArguments(
        name: 'UNNECESSARY_NULL_COMPARISON',
        problemMessage:
            "The operand can't be 'null', so the condition is always 'false'.",
        correctionMessage:
            "Try removing the condition, an enclosing condition, or the whole "
            "conditional statement.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE',
        uniqueNameCheck:
            'WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonNeverNullTrue =
      WarningWithoutArguments(
        name: 'UNNECESSARY_NULL_COMPARISON',
        problemMessage:
            "The operand can't be 'null', so the condition is always 'true'.",
        correctionMessage: "Remove the condition.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE',
        uniqueNameCheck:
            'WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryQuestionMark = WarningTemplate(
    name: 'UNNECESSARY_QUESTION_MARK',
    problemMessage:
        "The '?' is unnecessary because '{0}' is nullable without it.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNNECESSARY_QUESTION_MARK',
    withArguments: _withArgumentsUnnecessaryQuestionMark,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessarySetLiteral =
      WarningWithoutArguments(
        name: 'UNNECESSARY_SET_LITERAL',
        problemMessage:
            "Braces unnecessarily wrap this expression in a set literal.",
        correctionMessage:
            "Try removing the set literal around the expression.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNNECESSARY_SET_LITERAL',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryTypeCheckFalse =
      WarningWithoutArguments(
        name: 'UNNECESSARY_TYPE_CHECK',
        problemMessage: "Unnecessary type check; the result is always 'false'.",
        correctionMessage:
            "Try correcting the type check, or removing the type check.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_TYPE_CHECK_FALSE',
        uniqueNameCheck: 'WarningCode.UNNECESSARY_TYPE_CHECK_FALSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryTypeCheckTrue =
      WarningWithoutArguments(
        name: 'UNNECESSARY_TYPE_CHECK',
        problemMessage: "Unnecessary type check; the result is always 'true'.",
        correctionMessage:
            "Try correcting the type check, or removing the type check.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_TYPE_CHECK_TRUE',
        uniqueNameCheck: 'WarningCode.UNNECESSARY_TYPE_CHECK_TRUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryWildcardPattern =
      WarningWithoutArguments(
        name: 'UNNECESSARY_WILDCARD_PATTERN',
        problemMessage: "Unnecessary wildcard pattern.",
        correctionMessage: "Try removing the wildcard pattern.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNNECESSARY_WILDCARD_PATTERN',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unreachableSwitchCase =
      WarningWithoutArguments(
        name: 'UNREACHABLE_SWITCH_CASE',
        problemMessage: "This case is covered by the previous cases.",
        correctionMessage:
            "Try removing the case clause, or restructuring the preceding "
            "patterns.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNREACHABLE_SWITCH_CASE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unreachableSwitchDefault =
      WarningWithoutArguments(
        name: 'UNREACHABLE_SWITCH_DEFAULT',
        problemMessage: "This default clause is covered by the previous cases.",
        correctionMessage:
            "Try removing the default clause, or restructuring the preceding "
            "patterns.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'WarningCode.UNREACHABLE_SWITCH_DEFAULT',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the exception variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchClause = WarningTemplate(
    name: 'UNUSED_CATCH_CLAUSE',
    problemMessage:
        "The exception variable '{0}' isn't used, so the 'catch' clause can be "
        "removed.",
    correctionMessage: "Try removing the catch clause.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_CATCH_CLAUSE',
    withArguments: _withArgumentsUnusedCatchClause,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the stack trace variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchStack = WarningTemplate(
    name: 'UNUSED_CATCH_STACK',
    problemMessage:
        "The stack trace variable '{0}' isn't used and can be removed.",
    correctionMessage: "Try removing the stack trace variable, or using it.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_CATCH_STACK',
    withArguments: _withArgumentsUnusedCatchStack,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name that is declared but not referenced
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElement = WarningTemplate(
    name: 'UNUSED_ELEMENT',
    problemMessage: "The declaration '{0}' isn't referenced.",
    correctionMessage: "Try removing the declaration of '{0}'.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_ELEMENT',
    withArguments: _withArgumentsUnusedElement,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the parameter that is declared but not used
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElementParameter = WarningTemplate(
    name: 'UNUSED_ELEMENT_PARAMETER',
    problemMessage: "A value for optional parameter '{0}' isn't ever given.",
    correctionMessage: "Try removing the unused parameter.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_ELEMENT_PARAMETER',
    withArguments: _withArgumentsUnusedElementParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the unused field
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedField = WarningTemplate(
    name: 'UNUSED_FIELD',
    problemMessage: "The value of the field '{0}' isn't used.",
    correctionMessage: "Try removing the field, or using it.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_FIELD',
    withArguments: _withArgumentsUnusedField,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the content of the unused import's URI
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedImport = WarningTemplate(
    name: 'UNUSED_IMPORT',
    problemMessage: "Unused import: '{0}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_IMPORT',
    withArguments: _withArgumentsUnusedImport,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the label that isn't used
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedLabel = WarningTemplate(
    name: 'UNUSED_LABEL',
    problemMessage: "The label '{0}' isn't used.",
    correctionMessage:
        "Try removing the label, or using it in either a 'break' or 'continue' "
        "statement.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_LABEL',
    withArguments: _withArgumentsUnusedLabel,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the unused variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedLocalVariable = WarningTemplate(
    name: 'UNUSED_LOCAL_VARIABLE',
    problemMessage: "The value of the local variable '{0}' isn't used.",
    correctionMessage: "Try removing the variable or using it.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_LOCAL_VARIABLE',
    withArguments: _withArgumentsUnusedLocalVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the annotated method, property or function
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedResult = WarningTemplate(
    name: 'UNUSED_RESULT',
    problemMessage: "The value of '{0}' should be used.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_RESULT',
    withArguments: _withArgumentsUnusedResult,
    expectedTypes: [ExpectedType.string],
  );

  /// The result of invoking a method, property, or function annotated with
  /// `@useResult` must be used (assigned, passed to a function as an argument,
  /// or returned by a function).
  ///
  /// Parameters:
  /// Object p0: the name of the annotated method, property or function
  /// Object p1: message details
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  unusedResultWithMessage = WarningTemplate(
    name: 'UNUSED_RESULT',
    problemMessage: "'{0}' should be used. {1}.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_RESULT_WITH_MESSAGE',
    uniqueNameCheck: 'WarningCode.UNUSED_RESULT_WITH_MESSAGE',
    withArguments: _withArgumentsUnusedResultWithMessage,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name that is shown but not used
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedShownName = WarningTemplate(
    name: 'UNUSED_SHOWN_NAME',
    problemMessage: "The name {0} is shown, but isn't used.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.UNUSED_SHOWN_NAME',
    withArguments: _withArgumentsUnusedShownName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uriDoesNotExistInDocImport = WarningTemplate(
    name: 'URI_DOES_NOT_EXIST_IN_DOC_IMPORT',
    problemMessage: "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT',
    withArguments: _withArgumentsUriDoesNotExistInDocImport,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const WarningCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required String super.uniqueNameCheck,
    required super.expectedTypes,
  }) : super(
         type: DiagnosticType.STATIC_WARNING,
         uniqueName: 'WarningCode.${uniqueName ?? name}',
       );

  static LocatableDiagnostic
  _withArgumentsArgumentTypeNotAssignableToErrorHandler({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.argumentTypeNotAssignableToErrorHandler,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsAssignmentOfDoNotStore({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.assignmentOfDoNotStore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyCatchError({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.bodyMightCompleteNormallyCatchError,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyNullable({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.bodyMightCompleteNormallyNullable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsCastFromNullableAlwaysFails({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.castFromNullableAlwaysFails, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsConstantPatternNeverMatchesValueType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.constantPatternNeverMatchesValueType,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDeadCodeOnCatchSubtype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deadCodeOnCatchSubtype, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedExportUse({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedExportUse, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedExtend({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedExtend, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedImplement({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedImplement, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedInstantiate({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedInstantiate, [
      typeName,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedMixin({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedMixin, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedOptional({
    required Object parameterName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedOptional, [
      parameterName,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedSubclass({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(WarningCode.deprecatedSubclass, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveArgumentWrongFormat({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.docDirectiveArgumentWrongFormat,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveHasExtraArguments({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(WarningCode.docDirectiveHasExtraArguments, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsDocDirectiveHasUnexpectedNamedArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.docDirectiveHasUnexpectedNamedArgument,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingClosingTag({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.docDirectiveMissingClosingTag, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingOneArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.docDirectiveMissingOneArgument, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingOpeningTag({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.docDirectiveMissingOpeningTag, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingThreeArguments({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.docDirectiveMissingThreeArguments,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingTwoArguments({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.docDirectiveMissingTwoArguments,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveUnknown({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.docDirectiveUnknown, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateIgnore({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.duplicateIgnore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExperimentalMemberUse({
    required String member,
  }) {
    return LocatableDiagnosticImpl(WarningCode.experimentalMemberUse, [member]);
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnCollectionLiteral({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnCollectionLiteral,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnFunctionInvocation({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnFunctionInvocation,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnFunctionReturnType({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnFunctionReturnType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnGenericInvocation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnGenericInvocation,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnInstanceCreation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnInstanceCreation,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnUninitializedVariable({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnUninitializedVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnUntypedParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.inferenceFailureOnUntypedParameter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidAnnotationTarget({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidAnnotationTarget, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidExportOfInternalElement({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidExportOfInternalElement, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidExportOfInternalElementIndirectly({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidExportOfInternalElementIndirectly,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidFactoryMethodDecl({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidFactoryMethodDecl, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidFactoryMethodImpl({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidFactoryMethodImpl, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidLanguageVersionOverrideGreater({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidLanguageVersionOverrideGreater,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidOverrideOfNonVirtualMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidOverrideOfNonVirtualMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfDoNotSubmitMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidUseOfDoNotSubmitMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfInternalMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidUseOfInternalMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfProtectedMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidUseOfProtectedMember, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidUseOfVisibleForOverridingMember({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidUseOfVisibleForOverridingMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsInvalidUseOfVisibleForTemplateMember({
    required String p0,
    required Uri p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidUseOfVisibleForTemplateMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTestingMember({
    required String p0,
    required Uri p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidUseOfVisibleForTestingMember,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidVisibilityAnnotation({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.invalidVisibilityAnnotation, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidWidgetPreviewPrivateArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.invalidWidgetPreviewPrivateArgument,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenOne({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.missingOverrideOfMustBeOverriddenOne,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.missingOverrideOfMustBeOverriddenThreePlus,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenTwo({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.missingOverrideOfMustBeOverriddenTwo,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredParam({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.missingRequiredParam, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredParamWithDetails({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.missingRequiredParamWithDetails,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsMixinOnSealedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.mixinOnSealedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMustBeImmutable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.mustBeImmutable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMustCallSuper({required String p0}) {
    return LocatableDiagnosticImpl(WarningCode.mustCallSuper, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonConstArgumentForConstParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.nonConstArgumentForConstParameter,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.nonConstCallToLiteralConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonConstCallToLiteralConstructorUsingNew({required String p0}) {
    return LocatableDiagnosticImpl(
      WarningCode.nonConstCallToLiteralConstructorUsingNew,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNullArgumentToNonNullType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.nullArgumentToNonNullType, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsPatternNeverMatchesValueType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.patternNeverMatchesValueType, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsRedeclareOnNonRedeclaringMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.redeclareOnNonRedeclaringMember,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsRemovedLintUse({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.removedLintUse, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReplacedLintUse({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(WarningCode.replacedLintUse, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfDoNotStore({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.returnOfDoNotStore, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromCatchError({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.returnOfInvalidTypeFromCatchError,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsReturnTypeInvalidForCatchError({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.returnTypeInvalidForCatchError, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsSdkVersionSince({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.sdkVersionSince, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsStrictRawType({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.strictRawType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfSealedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.subtypeOfSealedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTextDirectionCodePointInComment({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.textDirectionCodePointInComment,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsTextDirectionCodePointInLiteral({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      WarningCode.textDirectionCodePointInLiteral,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUndefinedHiddenName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.undefinedHiddenName, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedReferencedParameter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.undefinedReferencedParameter, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedShownName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.undefinedShownName, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUnignorableIgnore({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unignorableIgnore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryQuestionMark({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unnecessaryQuestionMark, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedCatchClause({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedCatchClause, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedCatchStack({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedCatchStack, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedElement({required Object p0}) {
    return LocatableDiagnosticImpl(WarningCode.unusedElement, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedElementParameter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedElementParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedField({required Object p0}) {
    return LocatableDiagnosticImpl(WarningCode.unusedField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedImport({required String p0}) {
    return LocatableDiagnosticImpl(WarningCode.unusedImport, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedLabel({required String p0}) {
    return LocatableDiagnosticImpl(WarningCode.unusedLabel, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedLocalVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedLocalVariable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedResult({required String p0}) {
    return LocatableDiagnosticImpl(WarningCode.unusedResult, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedResultWithMessage({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedResultWithMessage, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnusedShownName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.unusedShownName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUriDoesNotExistInDocImport({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(WarningCode.uriDoesNotExistInDocImport, [
      p0,
    ]);
  }
}

final class WarningTemplate<T extends Function> extends WarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const WarningTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class WarningWithoutArguments extends WarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const WarningWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
  });
}
