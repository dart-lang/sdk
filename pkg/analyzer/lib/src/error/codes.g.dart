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
    'ABSTRACT_FIELD_INITIALIZER',
    "Abstract fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'abstract' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments abstractFieldInitializer =
      CompileTimeErrorWithoutArguments(
        'ABSTRACT_FIELD_INITIALIZER',
        "Abstract fields can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'abstract' keyword.",
        hasPublishedDocs: true,
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
    'ABSTRACT_SUPER_MEMBER_REFERENCE',
    "The {0} '{1}' is always abstract in the supertype.",
    hasPublishedDocs: true,
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
    'AMBIGUOUS_EXPORT',
    "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
    correctionMessage:
        "Try removing the export of one of the libraries, or explicitly hiding "
        "the name in one of the export directives.",
    hasPublishedDocs: true,
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
    'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    "A member named '{0}' is defined in {1}, and none are more specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to "
        "be chosen.",
    hasPublishedDocs: true,
    uniqueName: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS_THREE_OR_MORE',
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
    'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
    "A member named '{0}' is defined in '{1}' and '{2}', and neither is more "
        "specific.",
    correctionMessage:
        "Try using an extension override to specify the extension you want to "
        "be chosen.",
    hasPublishedDocs: true,
    uniqueName: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO',
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
    'AMBIGUOUS_IMPORT',
    "The name '{0}' is defined in the libraries {1}.",
    correctionMessage:
        "Try using 'as prefix' for one of the import directives, or hiding the "
        "name from all but one of the imports.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAmbiguousImport,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  ambiguousSetOrMapLiteralBoth = CompileTimeErrorWithoutArguments(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
    "The literal can't be either a map or a set because it contains at least "
        "one literal map entry or a spread operator spreading a 'Map', and at "
        "least one element which is neither of these.",
    correctionMessage:
        "Try removing or changing some of the elements so that all of the "
        "elements are consistent.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  ambiguousSetOrMapLiteralEither = CompileTimeErrorWithoutArguments(
    'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
    "This literal must be either a map or a set, but the elements don't have "
        "enough information for type inference to work.",
    correctionMessage:
        "Try adding type arguments to the literal (one for sets, two for "
        "maps).",
    hasPublishedDocs: true,
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
    'ARGUMENT_TYPE_NOT_ASSIGNABLE',
    "The argument type '{0}' can't be assigned to the parameter type '{1}'. "
        "{2}",
    hasPublishedDocs: true,
    withArguments: _withArgumentsArgumentTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assertInRedirectingConstructor =
      CompileTimeErrorWithoutArguments(
        'ASSERT_IN_REDIRECTING_CONSTRUCTOR',
        "A redirecting constructor can't have an 'assert' initializer.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  assignmentToConst = CompileTimeErrorWithoutArguments(
    'ASSIGNMENT_TO_CONST',
    "Constant variables can't be assigned a value after initialization.",
    correctionMessage:
        "Try removing the assignment, or remove the modifier 'const' from the "
        "variable.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinal = CompileTimeErrorTemplate(
    'ASSIGNMENT_TO_FINAL',
    "'{0}' can't be used as a setter because it's final.",
    correctionMessage:
        "Try finding a different setter, or making '{0}' non-final.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAssignmentToFinal,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assignmentToFinalLocal = CompileTimeErrorTemplate(
    'ASSIGNMENT_TO_FINAL_LOCAL',
    "The final variable '{0}' can only be set once.",
    correctionMessage: "Try making '{0}' non-final.",
    hasPublishedDocs: true,
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
    'ASSIGNMENT_TO_FINAL_NO_SETTER',
    "There isn't a setter named '{0}' in class '{1}'.",
    correctionMessage:
        "Try correcting the name to reference an existing setter, or declare "
        "the setter.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAssignmentToFinalNoSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToFunction =
      CompileTimeErrorWithoutArguments(
        'ASSIGNMENT_TO_FUNCTION',
        "Functions can't be assigned a value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToMethod =
      CompileTimeErrorWithoutArguments(
        'ASSIGNMENT_TO_METHOD',
        "Methods can't be assigned a value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments assignmentToType =
      CompileTimeErrorWithoutArguments(
        'ASSIGNMENT_TO_TYPE',
        "Types can't be assigned a value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments asyncForInWrongContext =
      CompileTimeErrorWithoutArguments(
        'ASYNC_FOR_IN_WRONG_CONTEXT',
        "The async for-in loop can only be used in an async function.",
        correctionMessage:
            "Try marking the function body with either 'async' or 'async*', or "
            "removing the 'await' before the for-in loop.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentationExtendsClauseAlreadyPresent = CompileTimeErrorWithoutArguments(
    'AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT',
    "The augmentation has an 'extends' clause, but an augmentation target "
        "already includes an 'extends' clause and it isn't allowed to be "
        "repeated or changed.",
    correctionMessage:
        "Try removing the 'extends' clause, either here or in the augmentation "
        "target.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierExtra = CompileTimeErrorTemplate(
    'AUGMENTATION_MODIFIER_EXTRA',
    "The augmentation has the '{0}' modifier that the declaration doesn't "
        "have.",
    correctionMessage:
        "Try removing the '{0}' modifier, or adding it to the declaration.",
    withArguments: _withArgumentsAugmentationModifierExtra,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the lexeme of the modifier.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentationModifierMissing = CompileTimeErrorTemplate(
    'AUGMENTATION_MODIFIER_MISSING',
    "The augmentation is missing the '{0}' modifier that the declaration has.",
    correctionMessage:
        "Try adding the '{0}' modifier, or removing it from the declaration.",
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
    'AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND',
    "Can't augment a {0} with a {1}.",
    correctionMessage:
        "Try changing the augmentation to match the declaration kind.",
    withArguments: _withArgumentsAugmentationOfDifferentDeclarationKind,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationTypeParameterBound =
      CompileTimeErrorWithoutArguments(
        'AUGMENTATION_TYPE_PARAMETER_BOUND',
        "The augmentation type parameter must have the same bound as the "
            "corresponding type parameter of the declaration.",
        correctionMessage:
            "Try changing the augmentation to match the declaration type "
            "parameters.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationTypeParameterCount =
      CompileTimeErrorWithoutArguments(
        'AUGMENTATION_TYPE_PARAMETER_COUNT',
        "The augmentation must have the same number of type parameters as the "
            "declaration.",
        correctionMessage:
            "Try changing the augmentation to match the declaration type "
            "parameters.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationTypeParameterName =
      CompileTimeErrorWithoutArguments(
        'AUGMENTATION_TYPE_PARAMETER_NAME',
        "The augmentation type parameter must have the same name as the "
            "corresponding type parameter of the declaration.",
        correctionMessage:
            "Try changing the augmentation to match the declaration type "
            "parameters.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments augmentationWithoutDeclaration =
      CompileTimeErrorWithoutArguments(
        'AUGMENTATION_WITHOUT_DECLARATION',
        "The declaration being augmented doesn't exist.",
        correctionMessage:
            "Try changing the augmentation to match an existing declaration.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentedExpressionIsNotSetter = CompileTimeErrorWithoutArguments(
    'AUGMENTED_EXPRESSION_IS_NOT_SETTER',
    "The augmented declaration is not a setter, it can't be used to write a "
        "value.",
    correctionMessage: "Try assigning a value to a setter.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  augmentedExpressionIsSetter = CompileTimeErrorWithoutArguments(
    'AUGMENTED_EXPRESSION_IS_SETTER',
    "The augmented declaration is a setter, it can't be used to read a value.",
    correctionMessage: "Try assigning a value to the augmented setter.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the lexeme of the operator.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  augmentedExpressionNotOperator = CompileTimeErrorTemplate(
    'AUGMENTED_EXPRESSION_NOT_OPERATOR',
    "The enclosing augmentation doesn't augment the operator '{0}'.",
    correctionMessage: "Try augmenting or invoking the correct operator.",
    withArguments: _withArgumentsAugmentedExpressionNotOperator,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  awaitInLateLocalVariableInitializer = CompileTimeErrorWithoutArguments(
    'AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
    "The 'await' expression can't be used in a 'late' local variable's "
        "initializer.",
    correctionMessage:
        "Try removing the 'late' modifier, or rewriting the initializer "
        "without using the 'await' expression.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// 16.30 Await Expressions: It is a compile-time error if the function
  /// immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
  /// await expression.)
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments awaitInWrongContext =
      CompileTimeErrorWithoutArguments(
        'AWAIT_IN_WRONG_CONTEXT',
        "The await expression can only be used in an async function.",
        correctionMessage:
            "Try marking the function body with either 'async' or 'async*'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  awaitOfIncompatibleType = CompileTimeErrorWithoutArguments(
    'AWAIT_OF_INCOMPATIBLE_TYPE',
    "The 'await' expression can't be used for an expression with an extension "
        "type that is not a subtype of 'Future'.",
    correctionMessage:
        "Try removing the `await`, or updating the extension type to implement "
        "'Future'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String implementedClassName: the name of the base class being implemented
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String implementedClassName})
  >
  baseClassImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be implemented outside of its library because it's "
        "a base class.",
    hasPublishedDocs: true,
    uniqueName: 'BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String implementedMixinName: the name of the base mixin being implemented
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String implementedMixinName})
  >
  baseMixinImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The mixin '{0}' can't be implemented outside of its library because it's "
        "a base mixin.",
    hasPublishedDocs: true,
    uniqueName: 'BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the name of the return type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormally = CompileTimeErrorTemplate(
    'BODY_MIGHT_COMPLETE_NORMALLY',
    "The body might complete normally, causing 'null' to be returned, but the "
        "return type, '{0}', is a potentially non-nullable type.",
    correctionMessage:
        "Try adding either a return or a throw statement at the end.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsBodyMightCompleteNormally,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments breakLabelOnSwitchMember =
      CompileTimeErrorWithoutArguments(
        'BREAK_LABEL_ON_SWITCH_MEMBER',
        "A break label resolves to the 'case' or 'default' statement.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as an extension name.",
    correctionMessage: "Try choosing a different name for the extension.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsExtensionName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsExtensionTypeName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as an extension type name.",
    correctionMessage: "Try choosing a different name for the extension type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_EXTENSION_TYPE_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsExtensionTypeName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsPrefixName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a prefix name.",
    correctionMessage: "Try choosing a different name for the prefix.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsPrefixName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsType = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_AS_TYPE',
    "The built-in identifier '{0}' can't be used as a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsBuiltInIdentifierAsType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypedefName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a typedef name.",
    correctionMessage: "Try choosing a different name for the typedef.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypedefName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type name.",
    correctionMessage: "Try choosing a different name for the type.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypeName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the built-in identifier that is being used
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  builtInIdentifierAsTypeParameterName = CompileTimeErrorTemplate(
    'BUILT_IN_IDENTIFIER_IN_DECLARATION',
    "The built-in identifier '{0}' can't be used as a type parameter name.",
    correctionMessage: "Try choosing a different name for the type parameter.",
    hasPublishedDocs: true,
    uniqueName: 'BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
    withArguments: _withArgumentsBuiltInIdentifierAsTypeParameterName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the this of the switch case expression
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  caseExpressionTypeImplementsEquals = CompileTimeErrorTemplate(
    'CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
    "The switch case expression type '{0}' can't override the '==' operator.",
    hasPublishedDocs: true,
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
    'CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
    "The switch case expression type '{0}' must be a subtype of the switch "
        "expression type '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  castToNonType = CompileTimeErrorTemplate(
    'CAST_TO_NON_TYPE',
    "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCastToNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToInstanceMember = CompileTimeErrorTemplate(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The instance member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try changing the member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
    withArguments: _withArgumentsClassInstantiationAccessToInstanceMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classInstantiationAccessToStaticMember = CompileTimeErrorTemplate(
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The static member '{0}' can't be accessed on a class instantiation.",
    correctionMessage:
        "Try removing the type arguments from the class name, or changing the "
        "member name to the name of a constructor.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
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
    'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or defining a constructor named "
        "'{1}'.",
    uniqueName: 'CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
    withArguments: _withArgumentsClassInstantiationAccessToUnknownMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class being used as a mixin
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  classUsedAsMixin = CompileTimeErrorTemplate(
    'CLASS_USED_AS_MIXIN',
    "The class '{0}' can't be used as a mixin because it's neither a mixin "
        "class nor a mixin.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsClassUsedAsMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  concreteClassHasEnumSuperinterface = CompileTimeErrorWithoutArguments(
    'CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
    "Concrete classes can't have 'Enum' as a superinterface.",
    correctionMessage:
        "Try specifying a different interface, or remove it from the list.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  concreteClassWithAbstractMember = CompileTimeErrorTemplate(
    'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' isn't abstract.",
    correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConcreteClassWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticField = CompileTimeErrorTemplate(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static field in this "
        "class.",
    correctionMessage: "Try renaming either the constructor or the field.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
    withArguments: _withArgumentsConflictingConstructorAndStaticField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and getter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticGetter = CompileTimeErrorTemplate(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static getter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the getter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
    withArguments: _withArgumentsConflictingConstructorAndStaticGetter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticMethod = CompileTimeErrorTemplate(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static method in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the method.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
    withArguments: _withArgumentsConflictingConstructorAndStaticMethod,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor and setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingConstructorAndStaticSetter = CompileTimeErrorTemplate(
    'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
    "'{0}' can't be used to name both a constructor and a static setter in "
        "this class.",
    correctionMessage: "Try renaming either the constructor or the setter.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
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
    'CONFLICTING_FIELD_AND_METHOD',
    "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the getter to a method, or renaming the field to a "
        "name that doesn't conflict.",
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
    'CONFLICTING_GENERIC_INTERFACES',
    "The {0} '{1}' can't implement both '{2}' and '{3}' because the type "
        "arguments are different.",
    hasPublishedDocs: true,
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
    'CONFLICTING_INHERITED_METHOD_AND_SETTER',
    "The {0} '{1}' can't inherit both a method and a setter named '{2}'.",
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
    'CONFLICTING_METHOD_AND_FIELD',
    "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the "
        "same name.",
    correctionMessage:
        "Try converting the method to a getter, or renaming the method to a "
        "name that doesn't conflict.",
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
    'CONFLICTING_STATIC_AND_INSTANCE',
    "Class '{0}' can't define static member '{1}' and have instance member "
        "'{2}.{1}' with the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
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
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type parameter and the class in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the class.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_CLASS',
    withArguments: _withArgumentsConflictingTypeVariableAndClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndEnum = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type parameter and the enum in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the enum.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_ENUM',
    withArguments: _withArgumentsConflictingTypeVariableAndEnum,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtension = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type parameter and the extension in "
        "which the type parameter is defined.",
    correctionMessage:
        "Try renaming either the type parameter or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
    withArguments: _withArgumentsConflictingTypeVariableAndExtension,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndExtensionType = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type parameter and the extension type "
        "in which the type parameter is defined.",
    correctionMessage:
        "Try renaming either the type parameter or the extension.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_TYPE',
    withArguments: _withArgumentsConflictingTypeVariableAndExtensionType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberClass = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type parameter and a member in this "
        "class.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberEnum = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type parameter and a member in this "
        "enum.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberEnum,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtension = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type parameter and a member in this "
        "extension.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberExtension,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberExtensionType = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type parameter and a member in this "
        "extension type.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION_TYPE',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberExtensionType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMemberMixin = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
    "'{0}' can't be used to name both a type parameter and a member in this "
        "mixin.",
    correctionMessage: "Try renaming either the type parameter or the member.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
    withArguments: _withArgumentsConflictingTypeVariableAndMemberMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  conflictingTypeVariableAndMixin = CompileTimeErrorTemplate(
    'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
    "'{0}' can't be used to name both a type parameter and the mixin in which "
        "the type parameter is defined.",
    correctionMessage: "Try renaming either the type parameter or the mixin.",
    hasPublishedDocs: true,
    uniqueName: 'CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
    withArguments: _withArgumentsConflictingTypeVariableAndMixin,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constantPatternWithNonConstantExpression = CompileTimeErrorWithoutArguments(
    'CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION',
    "The expression of a constant pattern must be a valid constant.",
    correctionMessage: "Try making the expression a valid constant.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorConstantFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' constructor.",
    correctionMessage:
        "Try removing the keyword 'const' from the constructor or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY',
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
    'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
    "In a const constructor, a value of type '{0}' can't be assigned to the "
        "field '{1}', which has type '{2}'.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
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
    'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstConstructorParamTypeMismatch,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorThrowsException = CompileTimeErrorWithoutArguments(
    'CONST_CONSTRUCTOR_THROWS_EXCEPTION',
    "Const constructors can't throw exceptions.",
    correctionMessage:
        "Try removing the throw statement, or removing the keyword 'const'.",
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithFieldInitializedByNonConst = CompileTimeErrorTemplate(
    'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
    "Can't define the 'const' constructor because the field '{0}' is "
        "initialized with a non-constant value.",
    correctionMessage:
        "Try initializing the field to a constant value, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
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
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because a mixin adds the "
        "instance field: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the field from the mixin class.",
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
    'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
    "This constructor can't be declared 'const' because the mixins add the "
        "instance fields: {0}.",
    correctionMessage:
        "Try removing the 'const' keyword or removing the 'with' clause from "
        "the class declaration, or removing the fields from the mixin classes.",
    uniqueName: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
    withArguments: _withArgumentsConstConstructorWithMixinWithFields,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constConstructorWithNonConstSuper = CompileTimeErrorTemplate(
    'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
    "A constant constructor can't call a non-constant super constructor of "
        "'{0}'.",
    correctionMessage:
        "Try calling a constant constructor in the superclass, or removing the "
        "keyword 'const' from the constructor.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstConstructorWithNonConstSuper,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constConstructorWithNonFinalField = CompileTimeErrorWithoutArguments(
    'CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
    "Can't define a const constructor for a class with non-final fields.",
    correctionMessage:
        "Try making all of the fields final, or removing the keyword 'const' "
        "from the constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constDeferredClass = CompileTimeErrorWithoutArguments(
    'CONST_DEFERRED_CLASS',
    "Deferred classes can't be created with 'const'.",
    correctionMessage:
        "Try using 'new' to create the instance, or changing the import to not "
        "be deferred.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalAssertionFailure =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_ASSERTION_FAILURE',
        "The assertion in this constant expression failed.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the message of the assertion
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  constEvalAssertionFailureWithMessage = CompileTimeErrorTemplate(
    'CONST_EVAL_ASSERTION_FAILURE_WITH_MESSAGE',
    "An assertion failed with message '{0}'.",
    withArguments: _withArgumentsConstEvalAssertionFailureWithMessage,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalExtensionMethod =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_EXTENSION_METHOD',
        "Extension methods can't be used in constant expressions.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalExtensionTypeMethod =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_EXTENSION_TYPE_METHOD',
        "Extension type methods can't be used in constant expressions.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalForElement = CompileTimeErrorWithoutArguments(
    'CONST_EVAL_FOR_ELEMENT',
    "Constant expressions don't support 'for' elements.",
    correctionMessage:
        "Try replacing the 'for' element with a spread, or removing 'const'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalMethodInvocation =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_METHOD_INVOCATION',
        "Methods can't be invoked in constant expressions.",
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 == e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalPrimitiveEquality =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_PRIMITIVE_EQUALITY',
        "In constant expressions, operands of the equality operator must have "
            "primitive equality.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the property being accessed
  /// String p1: the type with the property being accessed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  constEvalPropertyAccess = CompileTimeErrorTemplate(
    'CONST_EVAL_PROPERTY_ACCESS',
    "The property '{0}' can't be accessed on the type '{1}' in a constant "
        "expression.",
    withArguments: _withArgumentsConstEvalPropertyAccess,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalThrowsException =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_THROWS_EXCEPTION',
        "Evaluation of this constant expression throws an exception.",
        expectedTypes: [],
      );

  /// 16.12.2 Const: It is a compile-time error if evaluation of a constant
  /// object results in an uncaught exception being thrown.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalThrowsIdbze =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_THROWS_IDBZE',
        "Evaluation of this constant expression throws an "
            "IntegerDivisionByZeroException.",
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form !e1", "An expression of the form
  /// e1 && e2", and "An expression of the form e1 || e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalTypeBool =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_TYPE_BOOL',
        "In constant expressions, operands of this operator must be of type "
            "'bool'.",
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 & e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeBoolInt = CompileTimeErrorWithoutArguments(
    'CONST_EVAL_TYPE_BOOL_INT',
    "In constant expressions, operands of this operator must be of type 'bool' "
        "or 'int'.",
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "A literal string".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalTypeBoolNumString =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_TYPE_BOOL_NUM_STRING',
        "In constant expressions, operands of this operator must be of type "
            "'bool', 'num', 'String' or 'null'.",
        expectedTypes: [],
      );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form ~e1", "An expression of one of
  /// the forms e1 >> e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeInt = CompileTimeErrorWithoutArguments(
    'CONST_EVAL_TYPE_INT',
    "In constant expressions, operands of this operator must be of type 'int'.",
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 - e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeNum = CompileTimeErrorWithoutArguments(
    'CONST_EVAL_TYPE_NUM',
    "In constant expressions, operands of this operator must be of type 'num'.",
    expectedTypes: [],
  );

  /// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
  /// for text about "An expression of the form e1 + e2".
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constEvalTypeNumString = CompileTimeErrorWithoutArguments(
    'CONST_EVAL_TYPE_NUM_STRING',
    "In constant expressions, operands of this operator must be of type 'num' "
        "or 'String'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalTypeString =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_TYPE_STRING',
        "In constant expressions, operands of this operator must be of type "
            "'String'.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constEvalTypeType =
      CompileTimeErrorWithoutArguments(
        'CONST_EVAL_TYPE_TYPE',
        "In constant expressions, operands of this operator must be of type "
            "'Type'.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constFieldInitializerNotAssignable = CompileTimeErrorTemplate(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}' in a "
        "const constructor.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
    uniqueName: 'CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
    withArguments: _withArgumentsConstFieldInitializerNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constInitializedWithNonConstantValue = CompileTimeErrorWithoutArguments(
    'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
    "Const variables must be initialized with a constant value.",
    correctionMessage:
        "Try changing the initializer to be a constant expression.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constInitializedWithNonConstantValueFromDeferredLibrary =
      CompileTimeErrorWithoutArguments(
        'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
        "Constant values from a deferred library can't be used to initialize a "
            "'const' variable.",
        correctionMessage:
            "Try initializing the variable without referencing members of the "
            "deferred library, or changing the import to not be deferred.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constInstanceField =
      CompileTimeErrorWithoutArguments(
        'CONST_INSTANCE_FIELD',
        "Only static fields can be declared as const.",
        correctionMessage:
            "Try declaring the field as final, or adding the keyword 'static'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type of the entry's key
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  constMapKeyNotPrimitiveEquality = CompileTimeErrorTemplate(
    'CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY',
    "The type of a key in a constant map can't override the '==' operator, or "
        "'hashCode', but the class '{0}' does.",
    correctionMessage:
        "Try using a different value for the key, or removing the keyword "
        "'const' from the map.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstMapKeyNotPrimitiveEquality,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constNotInitialized = CompileTimeErrorTemplate(
    'CONST_NOT_INITIALIZED',
    "The constant '{0}' must be initialized.",
    correctionMessage: "Try adding an initialization to the declaration.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstNotInitialized,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the type of the element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  constSetElementNotPrimitiveEquality = CompileTimeErrorTemplate(
    'CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY',
    "An element in a constant set can't override the '==' operator, or "
        "'hashCode', but the type '{0}' does.",
    correctionMessage:
        "Try using a different value for the element, or removing the keyword "
        "'const' from the set.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstSetElementNotPrimitiveEquality,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constSpreadExpectedListOrSet =
      CompileTimeErrorWithoutArguments(
        'CONST_SPREAD_EXPECTED_LIST_OR_SET',
        "A list or a set is expected in this spread.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constSpreadExpectedMap =
      CompileTimeErrorWithoutArguments(
        'CONST_SPREAD_EXPECTED_MAP',
        "A map is expected in this spread.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constTypeParameter =
      CompileTimeErrorWithoutArguments(
        'CONST_TYPE_PARAMETER',
        "Type parameters can't be used in a constant expression.",
        correctionMessage:
            "Try replacing the type parameter with a different type.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constWithNonConst =
      CompileTimeErrorWithoutArguments(
        'CONST_WITH_NON_CONST',
        "The constructor being called isn't a const constructor.",
        correctionMessage:
            "Try removing 'const' from the constructor invocation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithNonConstantArgument = CompileTimeErrorWithoutArguments(
    'CONST_WITH_NON_CONSTANT_ARGUMENT',
    "Arguments of a constant creation must be constant expressions.",
    correctionMessage:
        "Try making the argument a valid constant, or use 'new' to call the "
        "constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  constWithNonType = CompileTimeErrorTemplate(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'CONST_WITH_NON_TYPE',
    withArguments: _withArgumentsConstWithNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments constWithTypeParameters =
      CompileTimeErrorWithoutArguments(
        'CONST_WITH_TYPE_PARAMETERS',
        "A constant creation can't use a type parameter as a type argument.",
        correctionMessage:
            "Try replacing the type parameter with a different type.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithTypeParametersConstructorTearoff = CompileTimeErrorWithoutArguments(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant constructor tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  constWithTypeParametersFunctionTearoff = CompileTimeErrorWithoutArguments(
    'CONST_WITH_TYPE_PARAMETERS',
    "A constant function tearoff can't use a type parameter as a type "
        "argument.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
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
    'CONST_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constant constructor '{1}'.",
    correctionMessage: "Try calling a different constructor.",
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
    'CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constant constructor.",
    correctionMessage: "Try calling a different constructor.",
    withArguments: _withArgumentsConstWithUndefinedConstructorDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  continueLabelInvalid = CompileTimeErrorWithoutArguments(
    'CONTINUE_LABEL_INVALID',
    "The label used in a 'continue' statement must be defined on either a loop "
        "or a switch member.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  /// String p1: detail text explaining why the type could not be inferred
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  couldNotInfer = CompileTimeErrorTemplate(
    'COULD_NOT_INFER',
    "Couldn't infer type parameter '{0}'.{1}",
    withArguments: _withArgumentsCouldNotInfer,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  defaultValueInRedirectingFactoryConstructor = CompileTimeErrorWithoutArguments(
    'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
    "Default values aren't allowed in factory constructors that redirect to "
        "another constructor.",
    correctionMessage: "Try removing the default value.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  defaultValueOnRequiredParameter = CompileTimeErrorWithoutArguments(
    'DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
    "Required named parameters can't have a default value.",
    correctionMessage:
        "Try removing either the default value or the 'required' modifier.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments deferredImportOfExtension =
      CompileTimeErrorWithoutArguments(
        'DEFERRED_IMPORT_OF_EXTENSION',
        "Imports of deferred libraries must hide all extensions.",
        correctionMessage:
            "Try adding either a show combinator listing the names you need to "
            "reference or a hide combinator listing all of the extensions.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  definitelyUnassignedLateLocalVariable = CompileTimeErrorTemplate(
    'DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
    "The late local variable '{0}' is definitely unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDefinitelyUnassignedLateLocalVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  disallowedTypeInstantiationExpression = CompileTimeErrorWithoutArguments(
    'DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
    "Only a generic type, generic function, generic instance method, or "
        "generic constructor can have type arguments.",
    correctionMessage:
        "Try removing the type arguments, or instantiating the type(s) of a "
        "generic type, generic function, generic instance method, or generic "
        "constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments dotShorthandMissingContext =
      CompileTimeErrorWithoutArguments(
        'DOT_SHORTHAND_MISSING_CONTEXT',
        "A dot shorthand can't be used where there is no context type.",
        hasPublishedDocs: true,
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
    'DOT_SHORTHAND_UNDEFINED_MEMBER',
    "The static getter '{0}' isn't defined for the context type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing static getter, or "
        "defining a getter or field named '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'DOT_SHORTHAND_UNDEFINED_GETTER',
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
    'DOT_SHORTHAND_UNDEFINED_MEMBER',
    "The static method or constructor '{0}' isn't defined for the context type "
        "'{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing static method or "
        "constructor, or defining a static method or constructor named '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'DOT_SHORTHAND_UNDEFINED_INVOCATION',
    withArguments: _withArgumentsDotShorthandUndefinedInvocation,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments duplicateConstructorDefault =
      CompileTimeErrorWithoutArguments(
        'DUPLICATE_CONSTRUCTOR',
        "The unnamed constructor is already defined.",
        correctionMessage: "Try giving one of the constructors a name.",
        hasPublishedDocs: true,
        uniqueName: 'DUPLICATE_CONSTRUCTOR_DEFAULT',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the duplicate entity
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateConstructorName = CompileTimeErrorTemplate(
    'DUPLICATE_CONSTRUCTOR',
    "The constructor with name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the constructors.",
    hasPublishedDocs: true,
    uniqueName: 'DUPLICATE_CONSTRUCTOR_NAME',
    withArguments: _withArgumentsDuplicateConstructorName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the duplicate entity
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateDefinition = CompileTimeErrorTemplate(
    'DUPLICATE_DEFINITION',
    "The name '{0}' is already defined.",
    correctionMessage: "Try renaming one of the declarations.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateDefinition,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldFormalParameter = CompileTimeErrorTemplate(
    'DUPLICATE_FIELD_FORMAL_PARAMETER',
    "The field '{0}' can't be initialized by multiple parameters in the same "
        "constructor.",
    correctionMessage:
        "Try removing one of the parameters, or using different fields.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateFieldFormalParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the duplicated name
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateFieldName = CompileTimeErrorTemplate(
    'DUPLICATE_FIELD_NAME',
    "The field name '{0}' is already used in this record.",
    correctionMessage: "Try renaming the field.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateFieldName,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the parameter that was duplicated
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateNamedArgument = CompileTimeErrorTemplate(
    'DUPLICATE_NAMED_ARGUMENT',
    "The argument for the named parameter '{0}' was already specified.",
    correctionMessage:
        "Try removing one of the named arguments, or correcting one of the "
        "names to reference a different named parameter.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateNamedArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Uri p0: the URI of the duplicate part
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Uri p0})
  >
  duplicatePart = CompileTimeErrorTemplate(
    'DUPLICATE_PART',
    "The library already contains a part with the URI '{0}'.",
    correctionMessage:
        "Try removing all except one of the duplicated part directives.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicatePart,
    expectedTypes: [ExpectedType.uri],
  );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternAssignmentVariable = CompileTimeErrorTemplate(
    'DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE',
    "The variable '{0}' is already assigned in this pattern.",
    correctionMessage: "Try renaming the variable.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicatePatternField = CompileTimeErrorTemplate(
    'DUPLICATE_PATTERN_FIELD',
    "The field '{0}' is already matched in this pattern.",
    correctionMessage: "Try removing the duplicate field.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicatePatternField,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments duplicateRestElementInPattern =
      CompileTimeErrorWithoutArguments(
        'DUPLICATE_REST_ELEMENT_IN_PATTERN',
        "At most one rest element is allowed in a list or map pattern.",
        correctionMessage: "Try removing the duplicate rest element.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  duplicateVariablePattern = CompileTimeErrorTemplate(
    'DUPLICATE_VARIABLE_PATTERN',
    "The variable '{0}' is already defined in this pattern.",
    correctionMessage: "Try renaming the variable.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateVariablePattern,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments emptyMapPattern =
      CompileTimeErrorWithoutArguments(
        'EMPTY_MAP_PATTERN',
        "A map pattern must have at least one entry.",
        correctionMessage: "Try replacing it with an object pattern 'Map()'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumConstantInvokesFactoryConstructor = CompileTimeErrorWithoutArguments(
    'ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR',
    "An enum value can't invoke a factory constructor.",
    correctionMessage: "Try using a generative constructor.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumConstantSameNameAsEnclosing = CompileTimeErrorWithoutArguments(
    'ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
    "The name of the enum value can't be the same as the enum's name.",
    correctionMessage: "Try renaming the constant.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  enumInstantiatedToBoundsIsNotWellBounded = CompileTimeErrorWithoutArguments(
    'ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
    "The result of instantiating the enum to bounds is not well-bounded.",
    correctionMessage: "Try using different bounds for type parameters.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments enumMixinWithInstanceVariable =
      CompileTimeErrorWithoutArguments(
        'ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
        "Mixins applied to enums can't have instance variables.",
        correctionMessage: "Try replacing the instance variables with getters.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing enum
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  enumWithAbstractMember = CompileTimeErrorTemplate(
    'ENUM_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' is an enum.",
    correctionMessage: "Try adding a body to '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsEnumWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments enumWithNameValues =
      CompileTimeErrorWithoutArguments(
        'ENUM_WITH_NAME_VALUES',
        "The name 'values' is not a valid name for an enum.",
        correctionMessage: "Try using a different name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments enumWithoutConstants =
      CompileTimeErrorWithoutArguments(
        'ENUM_WITHOUT_CONSTANTS',
        "The enum must have at least one enum constant.",
        correctionMessage: "Try declaring an enum constant.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalElementsInConstSet =
      CompileTimeErrorWithoutArguments(
        'EQUAL_ELEMENTS_IN_CONST_SET',
        "Two elements in a constant set literal can't be equal.",
        correctionMessage: "Change or remove the duplicate element.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalKeysInConstMap =
      CompileTimeErrorWithoutArguments(
        'EQUAL_KEYS_IN_CONST_MAP',
        "Two keys in a constant map literal can't be equal.",
        correctionMessage: "Change or remove the duplicate key.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments equalKeysInMapPattern =
      CompileTimeErrorWithoutArguments(
        'EQUAL_KEYS_IN_MAP_PATTERN',
        "Two keys in a map pattern can't be equal.",
        correctionMessage: "Change or remove the duplicate key.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListPatternTypeArguments = CompileTimeErrorTemplate(
    'EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS',
    "List patterns require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExpectedOneListPatternTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneListTypeArguments = CompileTimeErrorTemplate(
    'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
    "List literals require one type argument or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExpectedOneListTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedOneSetTypeArguments = CompileTimeErrorTemplate(
    'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
    "Set literals require one type argument or none, but {0} were found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExpectedOneSetTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapPatternTypeArguments = CompileTimeErrorTemplate(
    'EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS',
    "Map patterns require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExpectedTwoMapPatternTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// int p0: the number of provided type arguments
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0})
  >
  expectedTwoMapTypeArguments = CompileTimeErrorTemplate(
    'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
    "Map literals require two type arguments or none, but {0} found.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExpectedTwoMapTypeArguments,
    expectedTypes: [ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  exportInternalLibrary = CompileTimeErrorTemplate(
    'EXPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be exported.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExportInternalLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  exportOfNonLibrary = CompileTimeErrorTemplate(
    'EXPORT_OF_NON_LIBRARY',
    "The exported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try exporting the library that the part is a part of.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExportOfNonLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments expressionInMap =
      CompileTimeErrorWithoutArguments(
        'EXPRESSION_IN_MAP',
        "Expressions can't be used in a map literal.",
        correctionMessage:
            "Try removing the expression or converting it to be a map entry.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extendsDeferredClass =
      CompileTimeErrorWithoutArguments(
        'SUBTYPE_OF_DEFERRED_CLASS',
        "Classes can't extend deferred classes.",
        correctionMessage:
            "Try specifying a different superclass, or removing the extends "
            "clause.",
        hasPublishedDocs: true,
        uniqueName: 'EXTENDS_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  extendsDisallowedClass = CompileTimeErrorTemplate(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't extend '{0}'.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_DISALLOWED_CLASS',
    withArguments: _withArgumentsExtendsDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extendsNonClass =
      CompileTimeErrorWithoutArguments(
        'EXTENDS_NON_CLASS',
        "Classes can only extend other classes.",
        correctionMessage:
            "Try specifying a different superclass, or removing the extends "
            "clause.",
        hasPublishedDocs: true,
        isUnresolvedIdentifier: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extendsTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a "
        "superclass.",
    correctionMessage:
        "Try specifying a different superclass, or removing the extends "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the extension
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  extensionAsExpression = CompileTimeErrorTemplate(
    'EXTENSION_AS_EXPRESSION',
    "Extension '{0}' can't be used as an expression.",
    correctionMessage: "Try replacing it with a valid expression.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionAsExpression,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the conflicting static member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  extensionConflictingStaticAndInstance = CompileTimeErrorTemplate(
    'EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
    "An extension can't define static member '{0}' and an instance member with "
        "the same name.",
    correctionMessage:
        "Try renaming the member to a name that doesn't conflict.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionConflictingStaticAndInstance,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extensionDeclaresInstanceField =
      CompileTimeErrorWithoutArguments(
        'EXTENSION_DECLARES_INSTANCE_FIELD',
        "Extensions can't declare instance fields.",
        correctionMessage: "Try replacing the field with a getter.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionDeclaresMemberOfObject = CompileTimeErrorWithoutArguments(
    'EXTENSION_DECLARES_MEMBER_OF_OBJECT',
    "Extensions can't declare members with the same name as a member declared "
        "by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionOverrideAccessToStaticMember = CompileTimeErrorWithoutArguments(
    'EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
    "An extension override can't be used to access a static member from an "
        "extension.",
    correctionMessage: "Try using just the name of the extension.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the argument
  /// Type p1: the extended type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionOverrideArgumentNotAssignable = CompileTimeErrorTemplate(
    'EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
    "The type of the argument to the extension override '{0}' isn't assignable "
        "to the extended type '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionOverrideArgumentNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionOverrideWithCascade = CompileTimeErrorWithoutArguments(
    'EXTENSION_OVERRIDE_WITH_CASCADE',
    "Extension overrides have no value so they can't be used as the receiver "
        "of a cascade expression.",
    correctionMessage: "Try using '.' instead of '..'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments extensionOverrideWithoutAccess =
      CompileTimeErrorWithoutArguments(
        'EXTENSION_OVERRIDE_WITHOUT_ACCESS',
        "An extension override can only be used to access instance members.",
        correctionMessage: "Consider adding an access to an instance member.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeConstructorWithSuperFormalParameter =
      CompileTimeErrorWithoutArguments(
        'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER',
        "Extension type constructors can't declare super formal parameters.",
        correctionMessage:
            "Try removing the super formal parameter declaration.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeConstructorWithSuperInvocation =
      CompileTimeErrorWithoutArguments(
        'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION',
        "Extension type constructors can't include super initializers.",
        correctionMessage: "Try removing the super constructor invocation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeDeclaresInstanceField = CompileTimeErrorWithoutArguments(
    'EXTENSION_TYPE_DECLARES_INSTANCE_FIELD',
    "Extension types can't declare instance fields.",
    correctionMessage: "Try replacing the field with a getter.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeDeclaresMemberOfObject = CompileTimeErrorWithoutArguments(
    'EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT',
    "Extension types can't declare members with the same name as a member "
        "declared by 'Object'.",
    correctionMessage: "Try specifying a different name for the member.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the display string of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  extensionTypeImplementsDisallowedType = CompileTimeErrorTemplate(
    'EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE',
    "Extension types can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionTypeImplementsDisallowedType,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeImplementsItself = CompileTimeErrorWithoutArguments(
    'EXTENSION_TYPE_IMPLEMENTS_ITSELF',
    "The extension type can't implement itself.",
    correctionMessage:
        "Try removing the superinterface that references this extension type.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the implemented not extension type
  /// Type p1: the ultimate representation type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  extensionTypeImplementsNotSupertype = CompileTimeErrorTemplate(
    'EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE',
    "'{0}' is not a supertype of '{1}', the representation type.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
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
    'EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE',
    "'{0}', the representation type of '{1}', is not a supertype of '{2}', the "
        "representation type of '{3}'.",
    correctionMessage:
        "Try specifying a different type, or remove the type from the list.",
    hasPublishedDocs: true,
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
    'EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT',
    "The extension type '{0}' has more than one distinct member named '{1}' "
        "from implemented types.",
    correctionMessage:
        "Try redeclaring the corresponding member in this extension type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionTypeInheritedMemberConflict,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeRepresentationDependsOnItself = CompileTimeErrorWithoutArguments(
    'EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF',
    "The extension type representation can't depend on itself.",
    correctionMessage: "Try specifying a different type.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  extensionTypeRepresentationTypeBottom = CompileTimeErrorWithoutArguments(
    'EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM',
    "The representation type can't be a bottom type.",
    correctionMessage: "Try specifying a different type.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the abstract method
  /// String p1: the name of the enclosing extension type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  extensionTypeWithAbstractMember = CompileTimeErrorTemplate(
    'EXTENSION_TYPE_WITH_ABSTRACT_MEMBER',
    "'{0}' must have a method body because '{1}' is an extension type.",
    correctionMessage: "Try adding a body to '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtensionTypeWithAbstractMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  externalFieldConstructorInitializer = CompileTimeErrorWithoutArguments(
    'EXTERNAL_WITH_INITIALIZER',
    "External fields can't have initializers.",
    correctionMessage:
        "Try removing the field initializer or the 'external' keyword from the "
        "field declaration.",
    hasPublishedDocs: true,
    uniqueName: 'EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments externalFieldInitializer =
      CompileTimeErrorWithoutArguments(
        'EXTERNAL_WITH_INITIALIZER',
        "External fields can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'external' keyword.",
        hasPublishedDocs: true,
        uniqueName: 'EXTERNAL_FIELD_INITIALIZER',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments externalVariableInitializer =
      CompileTimeErrorWithoutArguments(
        'EXTERNAL_WITH_INITIALIZER',
        "External variables can't have initializers.",
        correctionMessage:
            "Try removing the initializer or the 'external' keyword.",
        hasPublishedDocs: true,
        uniqueName: 'EXTERNAL_VARIABLE_INITIALIZER',
        expectedTypes: [],
      );

  /// Parameters:
  /// int p0: the maximum number of positional arguments
  /// int p1: the actual number of positional arguments given
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required int p0, required int p1})
  >
  extraPositionalArguments = CompileTimeErrorTemplate(
    'EXTRA_POSITIONAL_ARGUMENTS',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage: "Try removing the extra arguments.",
    hasPublishedDocs: true,
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
    'EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
    "Too many positional arguments: {0} expected, but {1} found.",
    correctionMessage:
        "Try removing the extra positional arguments, or specifying the name "
        "for named arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsExtraPositionalArgumentsCouldBeNamed,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// Parameters:
  /// String p0: the name of the field being initialized multiple times
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  fieldInitializedByMultipleInitializers = CompileTimeErrorTemplate(
    'FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
    "The field '{0}' can't be initialized twice in the same constructor.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFieldInitializedByMultipleInitializers,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializedInInitializerAndDeclaration = CompileTimeErrorWithoutArguments(
    'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
    "Fields can't be initialized in the constructor if they are final and were "
        "already initialized at their declaration.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializedInParameterAndInitializer = CompileTimeErrorWithoutArguments(
    'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
    "Fields can't be initialized in both the parameter list and the "
        "initializers.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerFactoryConstructor = CompileTimeErrorWithoutArguments(
    'FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
    "Initializing formal parameters can't be used in factory constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the type of the initializer expression
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializerNotAssignable = CompileTimeErrorTemplate(
    'FIELD_INITIALIZER_NOT_ASSIGNABLE',
    "The initializer type '{0}' can't be assigned to the field type '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFieldInitializerNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerOutsideConstructor = CompileTimeErrorWithoutArguments(
    'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
    "Initializing formal parameters can only be used in constructors.",
    correctionMessage: "Try using a normal parameter.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  fieldInitializerRedirectingConstructor = CompileTimeErrorWithoutArguments(
    'FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
    "The redirecting constructor can't have a field initializer.",
    correctionMessage:
        "Try initializing the field in the constructor being redirected to.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the type of the field formal parameter
  /// Type p1: the name of the type of the field
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  fieldInitializingFormalNotAssignable = CompileTimeErrorTemplate(
    'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
    "The parameter type '{0}' is incompatible with the field type '{1}'.",
    correctionMessage:
        "Try changing or removing the parameter's type, or changing the "
        "field's type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFieldInitializingFormalNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the final class being extended.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassExtendedOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be extended outside of its library because it's a "
        "final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the final class being implemented.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalClassImplementedOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be implemented outside of its library because it's "
        "a final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
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
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be used as a mixin superclass constraint outside of "
        "its library because it's a final class.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY',
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
    'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
    "'{0}' is final and was given a value when it was declared, so it can't be "
        "set to a new value.",
    correctionMessage: "Try removing one of the initializations.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFinalInitializedInDeclarationAndConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitialized = CompileTimeErrorTemplate(
    'FINAL_NOT_INITIALIZED',
    "The final variable '{0}' must be initialized.",
    correctionMessage: "Try initializing the variable.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsFinalNotInitialized,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the uninitialized final variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  finalNotInitializedConstructor1 = CompileTimeErrorTemplate(
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' isn't.",
    correctionMessage: "Try adding an initializer for the field.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
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
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}' and '{1}' aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
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
    'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
    "All final variables must be initialized, but '{0}', '{1}', and {2} others "
        "aren't.",
    correctionMessage: "Try adding initializers for the fields.",
    hasPublishedDocs: true,
    uniqueName: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
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
    'FOR_IN_OF_INVALID_ELEMENT_TYPE',
    "The type '{0}' used in the 'for' loop must implement '{1}' with a type "
        "argument that can be assigned to '{2}'.",
    hasPublishedDocs: true,
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
    'FOR_IN_OF_INVALID_TYPE',
    "The type '{0}' used in the 'for' loop must implement '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsForInOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments forInWithConstVariable =
      CompileTimeErrorWithoutArguments(
        'FOR_IN_WITH_CONST_VARIABLE',
        "A for-in loop variable can't be a 'const'.",
        correctionMessage:
            "Try removing the 'const' modifier from the variable, or use a "
            "different variable.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// It is a compile-time error if a generic function type is used as a bound
  /// for a formal type parameter of a class or a function.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericFunctionTypeCannotBeBound = CompileTimeErrorWithoutArguments(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
    "Generic function types can't be used as type parameter bounds.",
    correctionMessage:
        "Try making the free variable in the function type part of the larger "
        "declaration signature.",
    expectedTypes: [],
  );

  /// It is a compile-time error if a generic function type is used as an actual
  /// type argument.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericFunctionTypeCannotBeTypeArgument = CompileTimeErrorWithoutArguments(
    'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
    "A generic function type can't be a type argument.",
    correctionMessage:
        "Try removing type parameters from the generic function type, or using "
        "'dynamic' as the type argument here.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  genericMethodTypeInstantiationOnDynamic = CompileTimeErrorWithoutArguments(
    'GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
    "A method tear-off on a receiver whose type is 'dynamic' can't have type "
        "arguments.",
    correctionMessage:
        "Specify the type of the receiver, or remove the type arguments from "
        "the method tear-off.",
    hasPublishedDocs: true,
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
    'GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't assignable to the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
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
    'GETTER_NOT_SUBTYPE_SETTER_TYPES',
    "The return type of getter '{0}' is '{1}' which isn't a subtype of the "
        "type '{2}' of its setter '{3}'.",
    correctionMessage: "Try changing the types so that they are compatible.",
    hasPublishedDocs: true,
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
    'IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in an if "
        "condition inside a const collection literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalAsyncGeneratorReturnType = CompileTimeErrorWithoutArguments(
    'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'async*' must have a return type that is a supertype of "
        "'Stream<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async*' from the function body.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalAsyncReturnType = CompileTimeErrorWithoutArguments(
    'ILLEGAL_ASYNC_RETURN_TYPE',
    "Functions marked 'async' must have a return type which is a supertype of "
        "'Future'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'async' from the function body.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of member that cannot be declared
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalConcreteEnumMemberDeclaration = CompileTimeErrorTemplate(
    'ILLEGAL_CONCRETE_ENUM_MEMBER',
    "A concrete instance member named '{0}' can't be declared in a class that "
        "implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION',
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
    'ILLEGAL_CONCRETE_ENUM_MEMBER',
    "A concrete instance member named '{0}' can't be inherited from '{1}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE',
    withArguments: _withArgumentsIllegalConcreteEnumMemberInheritance,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments illegalEnumValuesDeclaration =
      CompileTimeErrorWithoutArguments(
        'ILLEGAL_ENUM_VALUES',
        "An instance member named 'values' can't be declared in a class that "
            "implements 'Enum'.",
        correctionMessage: "Try using a different name.",
        hasPublishedDocs: true,
        uniqueName: 'ILLEGAL_ENUM_VALUES_DECLARATION',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the class that declares 'values'
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalEnumValuesInheritance = CompileTimeErrorTemplate(
    'ILLEGAL_ENUM_VALUES',
    "An instance member named 'values' can't be inherited from '{0}' in a "
        "class that implements 'Enum'.",
    correctionMessage: "Try using a different name.",
    hasPublishedDocs: true,
    uniqueName: 'ILLEGAL_ENUM_VALUES_INHERITANCE',
    withArguments: _withArgumentsIllegalEnumValuesInheritance,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the required language version
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  illegalLanguageVersionOverride = CompileTimeErrorTemplate(
    'ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
    "The language version must be {0}.",
    correctionMessage:
        "Try removing the language version override and migrating the code.",
    withArguments: _withArgumentsIllegalLanguageVersionOverride,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  illegalSyncGeneratorReturnType = CompileTimeErrorWithoutArguments(
    'ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
    "Functions marked 'sync*' must have a return type that is a supertype of "
        "'Iterable<T>' for some type 'T'.",
    correctionMessage:
        "Try fixing the return type of the function, or removing the modifier "
        "'sync*' from the function body.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments implementsDeferredClass =
      CompileTimeErrorWithoutArguments(
        'SUBTYPE_OF_DEFERRED_CLASS',
        "Classes and mixins can't implement deferred classes.",
        correctionMessage:
            "Try specifying a different interface, removing the class from the "
            "list, or changing the import to not be deferred.",
        hasPublishedDocs: true,
        uniqueName: 'IMPLEMENTS_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  implementsDisallowedClass = CompileTimeErrorTemplate(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes and mixins can't implement '{0}'.",
    correctionMessage:
        "Try specifying a different interface, or remove the class from the "
        "list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_DISALLOWED_CLASS',
    withArguments: _withArgumentsImplementsDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  implementsNonClass = CompileTimeErrorWithoutArguments(
    'IMPLEMENTS_NON_CLASS',
    "Classes and mixins can only implement other classes and mixins.",
    correctionMessage:
        "Try specifying a class or mixin, or remove the name from the list.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  implementsRepeated = CompileTimeErrorTemplate(
    'IMPLEMENTS_REPEATED',
    "'{0}' can only be implemented once.",
    correctionMessage: "Try removing all but one occurrence of the class name.",
    hasPublishedDocs: true,
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
    'IMPLEMENTS_SUPER_CLASS',
    "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsImplementsSuperClass,
    expectedTypes: [ExpectedType.element],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  implementsTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be implemented.",
    correctionMessage: "Try specifying a class or mixin, or removing the list.",
    hasPublishedDocs: true,
    uniqueName: 'IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the superclass
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  implicitSuperInitializerMissingArguments = CompileTimeErrorTemplate(
    'IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
    "The implicitly invoked unnamed constructor from '{0}' has required "
        "parameters.",
    correctionMessage:
        "Try adding an explicit super parameter with the required arguments.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the instance member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  implicitThisReferenceInInitializer = CompileTimeErrorTemplate(
    'IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
    "The instance member '{0}' can't be accessed in an initializer.",
    correctionMessage:
        "Try replacing the reference to the instance member with a different "
        "expression",
    hasPublishedDocs: true,
    withArguments: _withArgumentsImplicitThisReferenceInInitializer,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  importInternalLibrary = CompileTimeErrorTemplate(
    'IMPORT_INTERNAL_LIBRARY',
    "The library '{0}' is internal and can't be imported.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsImportInternalLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  importOfNonLibrary = CompileTimeErrorTemplate(
    'IMPORT_OF_NON_LIBRARY',
    "The imported library '{0}' can't have a part-of directive.",
    correctionMessage: "Try importing the library that the part is a part of.",
    hasPublishedDocs: true,
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
    'INCONSISTENT_CASE_EXPRESSION_TYPES',
    "Case expressions must have the same types, '{0}' isn't a '{1}'.",
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
    'INCONSISTENT_INHERITANCE',
    "Superinterfaces don't have a valid override for '{0}': {1}.",
    correctionMessage:
        "Try adding an explicit override that is consistent with all of the "
        "inherited members.",
    hasPublishedDocs: true,
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
    'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
    "'{0}' is inherited as a getter (from '{1}') and also a method (from "
        "'{2}').",
    correctionMessage:
        "Try adjusting the supertypes of this class to remove the "
        "inconsistency.",
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
    'INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
    "Parts must have exactly the same language version override as the "
        "library.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  inconsistentPatternVariableLogicalOr = CompileTimeErrorTemplate(
    'INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR',
    "The variable '{0}' has a different type and/or finality in this branch of "
        "the logical-or pattern.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "both branches.",
    hasPublishedDocs: true,
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
    'INITIALIZER_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
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
    'INITIALIZER_FOR_STATIC_FIELD',
    "'{0}' is a static field in the enclosing class. Fields initialized in a "
        "constructor can't be static.",
    correctionMessage: "Try removing the initialization.",
    hasPublishedDocs: true,
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
    'INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
    "'{0}' isn't a field in the enclosing class.",
    correctionMessage:
        "Try correcting the name to match an existing field, or defining a "
        "field named '{0}'.",
    hasPublishedDocs: true,
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
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    correctionMessage: "Try using the {3} '{2}' to access the {1}.",
    hasPublishedDocs: true,
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
    'INSTANCE_ACCESS_TO_STATIC_MEMBER',
    "The static {1} '{0}' can't be accessed through an instance.",
    hasPublishedDocs: true,
    uniqueName: 'INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
    withArguments: _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instanceMemberAccessFromFactory = CompileTimeErrorWithoutArguments(
    'INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
    "Instance members can't be accessed from a factory constructor.",
    correctionMessage: "Try removing the reference to the instance member.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instanceMemberAccessFromStatic = CompileTimeErrorWithoutArguments(
    'INSTANCE_MEMBER_ACCESS_FROM_STATIC',
    "Instance members can't be accessed from a static method.",
    correctionMessage:
        "Try removing the reference to the instance member, or removing the "
        "keyword 'static' from the method.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments instantiateAbstractClass =
      CompileTimeErrorWithoutArguments(
        'INSTANTIATE_ABSTRACT_CLASS',
        "Abstract classes can't be instantiated.",
        correctionMessage: "Try creating an instance of a concrete subtype.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments instantiateEnum =
      CompileTimeErrorWithoutArguments(
        'INSTANTIATE_ENUM',
        "Enums can't be instantiated.",
        correctionMessage: "Try using one of the defined constants.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  instantiateTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "Type aliases that expand to a type parameter can't be instantiated.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the lexeme of the integer
  /// String p1: the closest valid double
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  integerLiteralImpreciseAsDouble = CompileTimeErrorTemplate(
    'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
    "The integer literal is being used as a double, but can't be represented "
        "as a 64-bit double without overflow or loss of precision: '{0}'.",
    correctionMessage:
        "Try using the class 'BigInt', or switch to the closest valid double: "
        "'{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsIntegerLiteralImpreciseAsDouble,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the value of the literal
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  integerLiteralOutOfRange = CompileTimeErrorTemplate(
    'INTEGER_LITERAL_OUT_OF_RANGE',
    "The integer literal {0} can't be represented in 64 bits.",
    correctionMessage:
        "Try using the 'BigInt' class if you need an integer larger than "
        "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsIntegerLiteralOutOfRange,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the interface class being extended.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  interfaceClassExtendedOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be extended outside of its library because it's an "
        "interface class.",
    hasPublishedDocs: true,
    uniqueName: 'INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotation = CompileTimeErrorWithoutArguments(
    'INVALID_ANNOTATION',
    "Annotation must be either a const variable reference or const constructor "
        "invocation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotationConstantValueFromDeferredLibrary =
      CompileTimeErrorWithoutArguments(
        'INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
        "Constant values from a deferred library can't be used in annotations.",
        correctionMessage:
            "Try moving the constant from the deferred library, or removing "
            "'deferred' from the import.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidAnnotationFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as annotations.",
    correctionMessage:
        "Try removing the annotation, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the right hand side type
  /// Type p1: the name of the left hand side type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  invalidAssignment = CompileTimeErrorTemplate(
    'INVALID_ASSIGNMENT',
    "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
    correctionMessage:
        "Try changing the type of the variable, or casting the right-hand type "
        "to '{1}'.",
    hasPublishedDocs: true,
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
    'INVALID_CAST_FUNCTION',
    "The function '{0}' has type '{1}' that isn't of expected type '{2}'. This "
        "means its parameter or return type doesn't match what is expected.",
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
    'INVALID_CAST_FUNCTION_EXPR',
    "The function expression type '{0}' isn't of type '{1}'. This means its "
        "parameter or return type doesn't match what is expected. Consider "
        "changing parameter type(s) or the returned type(s).",
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
    'INVALID_CAST_LITERAL',
    "The literal '{0}' with type '{1}' isn't of expected type '{2}'.",
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
    'INVALID_CAST_LITERAL_LIST',
    "The list literal type '{0}' isn't of expected type '{1}'. The list's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
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
    'INVALID_CAST_LITERAL_MAP',
    "The map literal type '{0}' isn't of expected type '{1}'. The map's type "
        "can be changed with an explicit generic type arguments or by changing "
        "the key and value types.",
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
    'INVALID_CAST_LITERAL_SET',
    "The set literal type '{0}' isn't of expected type '{1}'. The set's type "
        "can be changed with an explicit generic type argument or by changing "
        "the element types.",
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
    'INVALID_CAST_METHOD',
    "The method tear-off '{0}' has type '{1}' that isn't of expected type "
        "'{2}'. This means its parameter or return type doesn't match what is "
        "expected.",
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
    'INVALID_CAST_NEW_EXPR',
    "The constructor returns type '{0}' that isn't of expected type '{1}'.",
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
        'INVALID_CONSTANT',
        "Invalid constant value.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidExtensionArgumentCount = CompileTimeErrorWithoutArguments(
    'INVALID_EXTENSION_ARGUMENT_COUNT',
    "Extension overrides must have exactly one argument: the value of 'this' "
        "in the extension method.",
    correctionMessage: "Try specifying exactly one argument.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidFactoryNameNotAClass =
      CompileTimeErrorWithoutArguments(
        'INVALID_FACTORY_NAME_NOT_A_CLASS',
        "The name of a factory constructor must be the same as the name of the "
            "immediately enclosing class.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidFieldNameFromObject =
      CompileTimeErrorWithoutArguments(
        'INVALID_FIELD_NAME',
        "Record field names can't be the same as a member from 'Object'.",
        correctionMessage: "Try using a different name for the field.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_FIELD_NAME_FROM_OBJECT',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidFieldNamePositional = CompileTimeErrorWithoutArguments(
    'INVALID_FIELD_NAME',
    "Record field names can't be a dollar sign followed by an integer when the "
        "integer is the index of a positional field.",
    correctionMessage: "Try using a different name for the field.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_FIELD_NAME_POSITIONAL',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidFieldNamePrivate =
      CompileTimeErrorWithoutArguments(
        'INVALID_FIELD_NAME',
        "Record field names can't be private.",
        correctionMessage: "Try removing the leading underscore.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_FIELD_NAME_PRIVATE',
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
    'INVALID_IMPLEMENTATION_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' "
        "('{4}').",
    hasPublishedDocs: true,
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
    'INVALID_IMPLEMENTATION_OVERRIDE',
    "The setter '{1}.{0}' ('{2}') isn't a valid concrete implementation of "
        "'{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_IMPLEMENTATION_OVERRIDE_SETTER',
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
    'INVALID_INLINE_FUNCTION_TYPE',
    "Inline function types can't be used for parameters in a generic function "
        "type.",
    correctionMessage:
        "Try using a generic function type (returnType 'Function(' parameters "
        "')').",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the invalid modifier
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidModifierOnConstructor = CompileTimeErrorTemplate(
    'INVALID_MODIFIER_ON_CONSTRUCTOR',
    "The modifier '{0}' can't be applied to the body of a constructor.",
    correctionMessage: "Try removing the modifier.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidModifierOnConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidModifierOnSetter =
      CompileTimeErrorWithoutArguments(
        'INVALID_MODIFIER_ON_SETTER',
        "Setters can't use 'async', 'async*', or 'sync*'.",
        correctionMessage: "Try removing the modifier.",
        hasPublishedDocs: true,
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
    'INVALID_OVERRIDE',
    "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
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
    'INVALID_OVERRIDE',
    "The setter '{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_OVERRIDE_SETTER',
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
    'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
    "Generative enum constructors can only be used as targets of redirection.",
    correctionMessage: "Try using an enum value, or a factory constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidReferenceToThis =
      CompileTimeErrorWithoutArguments(
        'INVALID_REFERENCE_TO_THIS',
        "Invalid reference to 'this' expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invalidSuperFormalParameterLocation = CompileTimeErrorWithoutArguments(
    'INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
    "Super parameters can only be used in non-redirecting generative "
        "constructors.",
    correctionMessage:
        "Try removing the 'super' modifier, or changing the constructor to be "
        "non-redirecting and generative.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstList = CompileTimeErrorTemplate(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant list literals can't use a type parameter in a type argument, "
        "such as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
    withArguments: _withArgumentsInvalidTypeArgumentInConstList,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidTypeArgumentInConstMap = CompileTimeErrorTemplate(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant map literals can't use a type parameter in a type argument, such "
        "as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
    withArguments: _withArgumentsInvalidTypeArgumentInConstMap,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the type parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidTypeArgumentInConstSet = CompileTimeErrorTemplate(
    'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
    "Constant set literals can't use a type parameter in a type argument, such "
        "as '{0}'.",
    correctionMessage:
        "Try replacing the type parameter with a different type.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_TYPE_ARGUMENT_IN_CONST_SET',
    withArguments: _withArgumentsInvalidTypeArgumentInConstSet,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUri = CompileTimeErrorTemplate(
    'INVALID_URI',
    "Invalid URI syntax: '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidUri,
    expectedTypes: [ExpectedType.string],
  );

  /// The 'covariant' keyword was found in an inappropriate location.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidUseOfCovariant =
      CompileTimeErrorWithoutArguments(
        'INVALID_USE_OF_COVARIANT',
        "The 'covariant' keyword can only be used for parameters in instance "
            "methods or before non-final instance fields.",
        correctionMessage: "Try removing the 'covariant' keyword.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments invalidUseOfNullValue =
      CompileTimeErrorWithoutArguments(
        'INVALID_USE_OF_NULL_VALUE',
        "An expression whose value is always 'null' can't be dereferenced.",
        correctionMessage: "Try changing the type of the expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the extension
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfExtensionWithoutCall = CompileTimeErrorTemplate(
    'INVOCATION_OF_EXTENSION_WITHOUT_CALL',
    "The extension '{0}' doesn't define a 'call' method so the override can't "
        "be used in an invocation.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvocationOfExtensionWithoutCall,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the identifier that is not a function type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invocationOfNonFunction = CompileTimeErrorTemplate(
    'INVOCATION_OF_NON_FUNCTION',
    "'{0}' isn't a function.",
    correctionMessage:
        "Try correcting the name to match an existing function, or define a "
        "method or function named '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvocationOfNonFunction,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  invocationOfNonFunctionExpression = CompileTimeErrorWithoutArguments(
    'INVOCATION_OF_NON_FUNCTION_EXPRESSION',
    "The expression doesn't evaluate to a function, so it can't be invoked.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  labelInOuterScope = CompileTimeErrorTemplate(
    'LABEL_IN_OUTER_SCOPE',
    "Can't reference label '{0}' declared in an outer method.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsLabelInOuterScope,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the unresolvable label
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  labelUndefined = CompileTimeErrorTemplate(
    'LABEL_UNDEFINED',
    "Can't reference an undefined label '{0}'.",
    correctionMessage:
        "Try defining the label, or correcting the name to match an existing "
        "label.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsLabelUndefined,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  lateFinalFieldWithConstConstructor = CompileTimeErrorWithoutArguments(
    'LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
    "Can't have a late final field in a class with a generative const "
        "constructor.",
    correctionMessage:
        "Try removing the 'late' modifier, or don't declare 'const' "
        "constructors.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments lateFinalLocalAlreadyAssigned =
      CompileTimeErrorWithoutArguments(
        'LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
        "The late final local variable is already assigned.",
        correctionMessage:
            "Try removing the 'final' modifier, or don't reassign the value.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the actual type of the list element
  /// Type p1: the expected type of the list element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  listElementTypeNotAssignable = CompileTimeErrorTemplate(
    'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
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
    'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the list type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsListElementTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mainFirstPositionalParameterType = CompileTimeErrorWithoutArguments(
    'MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
    "The type of the first positional parameter of the 'main' function must be "
        "a supertype of 'List<String>'.",
    correctionMessage: "Try changing the type of the parameter.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mainHasRequiredNamedParameters =
      CompileTimeErrorWithoutArguments(
        'MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
        "The function 'main' can't have any required named parameters.",
        correctionMessage:
            "Try using a different name for the function, or removing the "
            "'required' modifier.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mainHasTooManyRequiredPositionalParameters = CompileTimeErrorWithoutArguments(
    'MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
    "The function 'main' can't have more than two required positional "
        "parameters.",
    correctionMessage:
        "Try using a different name for the function, or removing extra "
        "parameters.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mainIsNotFunction =
      CompileTimeErrorWithoutArguments(
        'MAIN_IS_NOT_FUNCTION',
        "The declaration named 'main' must be a function.",
        correctionMessage: "Try using a different name for this declaration.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mapEntryNotInMap =
      CompileTimeErrorWithoutArguments(
        'MAP_ENTRY_NOT_IN_MAP',
        "Map entries can only be used in a map literal.",
        correctionMessage:
            "Try converting the collection to a map or removing the map entry.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type of the expression being used as a key
  /// Type p1: the type of keys declared for the map
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  mapKeyTypeNotAssignable = CompileTimeErrorTemplate(
    'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
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
    'MAP_KEY_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map key type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'MAP_KEY_TYPE_NOT_ASSIGNABLE_NULLABILITY',
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
    'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
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
    'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the map value type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE_NULLABILITY',
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
        'MISSING_CONST_IN_LIST_LITERAL',
        "Seeing this message constitutes a bug. Please report it.",
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
        'MISSING_CONST_IN_MAP_LITERAL',
        "Seeing this message constitutes a bug. Please report it.",
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
        'MISSING_CONST_IN_SET_LITERAL',
        "Seeing this message constitutes a bug. Please report it.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the library
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingDartLibrary = CompileTimeErrorTemplate(
    'MISSING_DART_LIBRARY',
    "Required library '{0}' is missing.",
    correctionMessage: "Re-install the Dart or Flutter SDK.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingDartLibrary,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameter = CompileTimeErrorTemplate(
    'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    "The parameter '{0}' can't have a value of 'null' because of its type, but "
        "the implicit default value is 'null'.",
    correctionMessage:
        "Try adding either an explicit non-'null' default value or the "
        "'required' modifier.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingDefaultValueForParameter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingDefaultValueForParameterPositional = CompileTimeErrorTemplate(
    'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
    "The parameter '{0}' can't have a value of 'null' because of its type, but "
        "the implicit default value is 'null'.",
    correctionMessage: "Try adding an explicit non-'null' default value.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL',
    withArguments: _withArgumentsMissingDefaultValueForParameterPositional,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  missingDefaultValueForParameterWithAnnotation =
      CompileTimeErrorWithoutArguments(
        'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
        "With null safety, use the 'required' keyword, not the '@required' "
            "annotation.",
        correctionMessage: "Try removing the '@'.",
        hasPublishedDocs: true,
        uniqueName: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION',
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments missingNamedPatternFieldName =
      CompileTimeErrorWithoutArguments(
        'MISSING_NAMED_PATTERN_FIELD_NAME',
        "The getter name is not specified explicitly, and the pattern is not a "
            "variable.",
        correctionMessage:
            "Try specifying the getter name explicitly, or using a variable "
            "pattern.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingRequiredArgument = CompileTimeErrorTemplate(
    'MISSING_REQUIRED_ARGUMENT',
    "The named parameter '{0}' is required, but there's no corresponding "
        "argument.",
    correctionMessage: "Try adding the required argument.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingRequiredArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable pattern
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingVariablePattern = CompileTimeErrorTemplate(
    'MISSING_VARIABLE_PATTERN',
    "Variable pattern '{0}' is missing in this branch of the logical-or "
        "pattern.",
    correctionMessage: "Try declaring this variable pattern in the branch.",
    hasPublishedDocs: true,
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
    'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
    "The super-invoked member '{0}' has the type '{1}', and the concrete "
        "member in the class has the type '{2}'.",
    hasPublishedDocs: true,
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
    'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    "The class doesn't have a concrete implementation of the super-invoked "
        "member '{0}'.",
    hasPublishedDocs: true,
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
    'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
    "The class doesn't have a concrete implementation of the super-invoked "
        "setter '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_SETTER',
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
    'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
    "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
    correctionMessage: "Try extending the class '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMixinApplicationNotImplementedInterface,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the mixin class that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclarationExtendsNotObject = CompileTimeErrorTemplate(
    'MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT',
    "The class '{0}' can't be declared a mixin because it extends a class "
        "other than 'Object'.",
    correctionMessage:
        "Try removing the 'mixin' modifier or changing the superclass to "
        "'Object'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMixinClassDeclarationExtendsNotObject,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinClassDeclaresConstructor = CompileTimeErrorTemplate(
    'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
    "The class '{0}' can't be used as a mixin because it declares a "
        "constructor.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMixinClassDeclaresConstructor,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinDeferredClass =
      CompileTimeErrorWithoutArguments(
        'SUBTYPE_OF_DEFERRED_CLASS',
        "Classes can't mixin deferred classes.",
        correctionMessage: "Try changing the import to not be deferred.",
        hasPublishedDocs: true,
        uniqueName: 'MIXIN_DEFERRED_CLASS',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the mixin that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mixinInheritsFromNotObject = CompileTimeErrorTemplate(
    'MIXIN_INHERITS_FROM_NOT_OBJECT',
    "The class '{0}' can't be used as a mixin because it extends a class other "
        "than 'Object'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMixinInheritsFromNotObject,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinInstantiate =
      CompileTimeErrorWithoutArguments(
        'MIXIN_INSTANTIATE',
        "Mixins can't be instantiated.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinOfDisallowedClass = CompileTimeErrorTemplate(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "Classes can't mixin '{0}'.",
    correctionMessage:
        "Try specifying a different class or mixin, or remove the class or "
        "mixin from the list.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_DISALLOWED_CLASS',
    withArguments: _withArgumentsMixinOfDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinOfNonClass =
      CompileTimeErrorWithoutArguments(
        'MIXIN_OF_NON_CLASS',
        "Classes can only mix in mixins and classes.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinOfTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be mixed in.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinOnTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
    "A type alias that expands to a type parameter can't be used as a "
        "superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    expectedTypes: [],
  );

  /// Parameters:
  /// Element p0: the name of the class that appears in both "extends" and
  ///             "with" clauses
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Element p0})
  >
  mixinsSuperClass = CompileTimeErrorTemplate(
    'IMPLEMENTS_SUPER_CLASS',
    "'{0}' can't be used in both the 'extends' and 'with' clauses.",
    correctionMessage: "Try removing one of the occurrences.",
    hasPublishedDocs: true,
    uniqueName: 'MIXINS_SUPER_CLASS',
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
    'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    "The mixin '{0}' must be 'base' because the supertype '{1}' is 'base'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE',
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
    'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    "The mixin '{0}' must be 'base' because the supertype '{1}' is 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE',
    withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinSuperClassConstraintDeferredClass = CompileTimeErrorWithoutArguments(
    'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
    "Deferred classes can't be used as superclass constraints.",
    correctionMessage: "Try changing the import to not be deferred.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the name of the disallowed type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  mixinSuperClassConstraintDisallowedClass = CompileTimeErrorTemplate(
    'SUBTYPE_OF_DISALLOWED_TYPE',
    "'{0}' can't be used as a superclass constraint.",
    correctionMessage:
        "Try specifying a different super-class constraint, or remove the 'on' "
        "clause.",
    hasPublishedDocs: true,
    uniqueName: 'MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
    withArguments: _withArgumentsMixinSuperClassConstraintDisallowedClass,
    expectedTypes: [ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  mixinSuperClassConstraintNonInterface = CompileTimeErrorWithoutArguments(
    'MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
    "Only classes and mixins can be used as superclass constraints.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
  /// denote a class available in the immediately enclosing scope.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments mixinWithNonClassSuperclass =
      CompileTimeErrorWithoutArguments(
        'MIXIN_WITH_NON_CLASS_SUPERCLASS',
        "Mixin can only be applied to class.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  multipleRedirectingConstructorInvocations = CompileTimeErrorWithoutArguments(
    'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
    "Constructors can have only one 'this' redirection, at most.",
    correctionMessage: "Try removing all but one of the redirections.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments multipleSuperInitializers =
      CompileTimeErrorWithoutArguments(
        'MULTIPLE_SUPER_INITIALIZERS',
        "A constructor can have at most one 'super' initializer.",
        correctionMessage:
            "Try removing all but one of the 'super' initializers.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  newWithNonType = CompileTimeErrorTemplate(
    'CREATION_WITH_NON_TYPE',
    "The name '{0}' isn't a class.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'NEW_WITH_NON_TYPE',
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
    'NEW_WITH_UNDEFINED_CONSTRUCTOR',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try invoking a different constructor, or define a constructor named "
        "'{1}'.",
    withArguments: _withArgumentsNewWithUndefinedConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class being instantiated
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  newWithUndefinedConstructorDefault = CompileTimeErrorTemplate(
    'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try using one of the named constructors defined in '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNewWithUndefinedConstructorDefault,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  noAnnotationConstructorArguments = CompileTimeErrorWithoutArguments(
    'NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
    "Annotation creation must have arguments.",
    correctionMessage: "Try adding an empty argument list.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the class where override error was detected
  /// String p1: the list of candidate signatures which cannot be combined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  noCombinedSuperSignature = CompileTimeErrorTemplate(
    'NO_COMBINED_SUPER_SIGNATURE',
    "Can't infer missing types in '{0}' from overridden methods: {1}.",
    correctionMessage:
        "Try providing explicit types for this method's parameters and return "
        "type.",
    hasPublishedDocs: true,
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
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or explicitly "
        "invoking a different constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
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
    'NO_DEFAULT_SUPER_CONSTRUCTOR',
    "The superclass '{0}' doesn't have a zero argument constructor.",
    correctionMessage:
        "Try declaring a zero argument constructor in '{0}', or declaring a "
        "constructor in {1} that explicitly invokes a constructor in '{0}'.",
    uniqueName: 'NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
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
    'NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
    "The class '{0}' can't extend '{1}' because '{1}' only has factory "
        "constructors (no generative constructors), and '{0}' has at least one "
        "generative constructor.",
    correctionMessage:
        "Try implementing the class instead, adding a generative (not factory) "
        "constructor to the superclass '{1}', or a factory constructor to the "
        "subclass.",
    hasPublishedDocs: true,
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
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} "
        "more.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FIVE_PLUS',
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
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_FOUR',
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
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementation of '{0}'.",
    correctionMessage:
        "Try implementing the missing method, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
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
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_THREE',
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
    'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
    "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage:
        "Try implementing the missing methods, or make the class abstract.",
    hasPublishedDocs: true,
    uniqueName: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
    withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberTwo,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolCondition =
      CompileTimeErrorWithoutArguments(
        'NON_BOOL_CONDITION',
        "Conditions must have a static type of 'bool'.",
        correctionMessage: "Try changing the condition.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolExpression =
      CompileTimeErrorWithoutArguments(
        'NON_BOOL_EXPRESSION',
        "The expression in an assert must be of type 'bool'.",
        correctionMessage: "Try changing the expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonBoolNegationExpression =
      CompileTimeErrorWithoutArguments(
        'NON_BOOL_NEGATION_EXPRESSION',
        "A negation operand must have a static type of 'bool'.",
        correctionMessage: "Try changing the operand to the '!' operator.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the lexeme of the logical operator
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonBoolOperand = CompileTimeErrorTemplate(
    'NON_BOOL_OPERAND',
    "The operands of the operator '{0}' must be assignable to 'bool'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonBoolOperand,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantAnnotationConstructor = CompileTimeErrorWithoutArguments(
    'NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
    "Annotation creation can only call a const constructor.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantCaseExpression =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_CASE_EXPRESSION',
        "Case expressions must be constant.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantCaseExpressionFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a case "
        "expression.",
    correctionMessage:
        "Try re-writing the switch as a series of if statements, or changing "
        "the import to not be deferred.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantDefaultValue =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_DEFAULT_VALUE',
        "The default value of an optional parameter must be constant.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantDefaultValueFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as a default "
        "parameter value.",
    correctionMessage:
        "Try leaving the default as 'null' and initializing the parameter "
        "inside the function body.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantListElement =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_LIST_ELEMENT',
        "The values in a const list literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the list literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantListElementFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' list literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the list literal or removing "
        "the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapElement =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_MAP_ELEMENT',
        "The elements in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapKey =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_MAP_KEY',
        "The keys in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantMapKeyFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as keys in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapPatternKey =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_MAP_PATTERN_KEY',
        "Key expressions in map patterns must be constants.",
        correctionMessage: "Try using constants instead.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantMapValue =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_MAP_VALUE',
        "The values in a const map literal must be constant.",
        correctionMessage:
            "Try removing the keyword 'const' from the map literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantMapValueFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' map literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the map literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantRecordField =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_RECORD_FIELD',
        "The fields in a const record literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the record literal.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantRecordFieldFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as fields in a "
        "'const' record literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the record literal or removing "
        "the keyword 'deferred' from the import.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstantRelationalPatternExpression = CompileTimeErrorWithoutArguments(
    'NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION',
    "The relational pattern expression must be a constant.",
    correctionMessage: "Try using a constant instead.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonConstantSetElement =
      CompileTimeErrorWithoutArguments(
        'NON_CONSTANT_SET_ELEMENT',
        "The values in a const set literal must be constants.",
        correctionMessage:
            "Try removing the keyword 'const' from the set literal.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstGenerativeEnumConstructor = CompileTimeErrorWithoutArguments(
    'NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
    "Generative enum constructors must be 'const'.",
    correctionMessage: "Try adding the keyword 'const'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// 13.2 Expression Statements: It is a compile-time error if a non-constant
  /// map literal that has no explicit type arguments appears in a place where a
  /// statement is expected.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonConstMapAsExpressionStatement = CompileTimeErrorWithoutArguments(
    'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
    "A non-constant map or set literal without type arguments can't be used as "
        "an expression statement.",
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  nonCovariantTypeParameterPositionInRepresentationType =
      CompileTimeErrorWithoutArguments(
        'NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE',
        "An extension type parameter can't be used in a non-covariant position of "
            "its representation type.",
        correctionMessage:
            "Try removing the type parameters from function parameter types and "
            "type parameter bounds.",
        hasPublishedDocs: true,
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
    'NON_EXHAUSTIVE_SWITCH_EXPRESSION',
    "The type '{0}' isn't exhaustively matched by the switch cases since it "
        "doesn't match the pattern '{1}'.",
    correctionMessage:
        "Try adding a wildcard pattern or cases that match '{2}'.",
    hasPublishedDocs: true,
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
    'NON_EXHAUSTIVE_SWITCH_STATEMENT',
    "The type '{0}' isn't exhaustively matched by the switch cases since it "
        "doesn't match the pattern '{1}'.",
    correctionMessage: "Try adding a default case or cases that match '{2}'.",
    hasPublishedDocs: true,
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
        'NON_FINAL_FIELD_IN_ENUM',
        "Enums can only declare final fields.",
        correctionMessage: "Try making the field final.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Element p0: the non-generative constructor
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Element p0})
  >
  nonGenerativeConstructor = CompileTimeErrorTemplate(
    'NON_GENERATIVE_CONSTRUCTOR',
    "The generative constructor '{0}' is expected, but a factory was found.",
    correctionMessage:
        "Try calling a different constructor of the superclass, or making the "
        "called constructor not be a factory constructor.",
    hasPublishedDocs: true,
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
    'NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
    "The unnamed constructor of superclass '{0}' (called by the default "
        "constructor of '{1}') must be a generative constructor, but factory "
        "found.",
    correctionMessage:
        "Try adding an explicit constructor that has a different "
        "superinitializer or changing the superclass constructor '{2}' to not "
        "be a factory constructor.",
    hasPublishedDocs: true,
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
        'NON_SYNC_FACTORY',
        "Factory bodies can't use 'async', 'async*', or 'sync*'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name appearing where a type is expected
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeAsTypeArgument = CompileTimeErrorTemplate(
    'NON_TYPE_AS_TYPE_ARGUMENT',
    "The name '{0}' isn't a type, so it can't be used as a type argument.",
    correctionMessage:
        "Try correcting the name to an existing type, or defining a type named "
        "'{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    withArguments: _withArgumentsNonTypeAsTypeArgument,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the non-type element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonTypeInCatchClause = CompileTimeErrorTemplate(
    'NON_TYPE_IN_CATCH_CLAUSE',
    "The name '{0}' isn't a type and can't be used in an on-catch clause.",
    correctionMessage: "Try correcting the name to match an existing class.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNonTypeInCatchClause,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonVoidReturnForOperator =
      CompileTimeErrorWithoutArguments(
        'NON_VOID_RETURN_FOR_OPERATOR',
        "The return type of the operator []= must be 'void'.",
        correctionMessage: "Try changing the return type to 'void'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nonVoidReturnForSetter =
      CompileTimeErrorWithoutArguments(
        'NON_VOID_RETURN_FOR_SETTER',
        "The return type of the setter must be 'void' or absent.",
        correctionMessage:
            "Try removing the return type, or define a method rather than a "
            "setter.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the variable that is invalid
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notAssignedPotentiallyNonNullableLocalVariable = CompileTimeErrorTemplate(
    'NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
    "The non-nullable local variable '{0}' must be assigned before it can be "
        "used.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned "
        "on every execution path.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name that is not a type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notAType = CompileTimeErrorTemplate(
    'NOT_A_TYPE',
    "{0} isn't a type.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNotAType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator that is not a binary operator.
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notBinaryOperator = CompileTimeErrorTemplate(
    'NOT_BINARY_OPERATOR',
    "'{0}' isn't a binary operator.",
    hasPublishedDocs: true,
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
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "{0} positional arguments expected by '{2}', but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL',
    withArguments: _withArgumentsNotEnoughPositionalArgumentsNamePlural,
    expectedTypes: [ExpectedType.int, ExpectedType.int, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: name of the function or method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notEnoughPositionalArgumentsNameSingular = CompileTimeErrorTemplate(
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "1 positional argument expected by '{0}', but 0 found.",
    correctionMessage: "Try adding the missing argument.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR',
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
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "{0} positional arguments expected, but {1} found.",
    correctionMessage: "Try adding the missing arguments.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL',
    withArguments: _withArgumentsNotEnoughPositionalArgumentsPlural,
    expectedTypes: [ExpectedType.int, ExpectedType.int],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  notEnoughPositionalArgumentsSingular = CompileTimeErrorWithoutArguments(
    'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
    "1 positional argument expected, but 0 found.",
    correctionMessage: "Try adding the missing argument.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceField = CompileTimeErrorTemplate(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or a generative constructor "
        "that initializes it, or mark it 'late'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNotInitializedNonNullableInstanceField,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the field that is not initialized
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  notInitializedNonNullableInstanceFieldConstructor = CompileTimeErrorTemplate(
    'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
    "Non-nullable instance field '{0}' must be initialized.",
    correctionMessage:
        "Try adding an initializer expression, or add a field initializer in "
        "this constructor, or mark it 'late'.",
    hasPublishedDocs: true,
    uniqueName: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
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
    'NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
    "The non-nullable variable '{0}' must be initialized.",
    correctionMessage: "Try adding an initializer expression.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNotInitializedNonNullableVariable,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notInstantiatedBound =
      CompileTimeErrorWithoutArguments(
        'NOT_INSTANTIATED_BOUND',
        "Type parameter bound types must be instantiated.",
        correctionMessage:
            "Try adding type arguments to the type parameter bound.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notIterableSpread =
      CompileTimeErrorWithoutArguments(
        'NOT_ITERABLE_SPREAD',
        "Spread elements in list or set literals must implement 'Iterable'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notMapSpread =
      CompileTimeErrorWithoutArguments(
        'NOT_MAP_SPREAD',
        "Spread elements in map literals must implement 'Map'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments notNullAwareNullSpread =
      CompileTimeErrorWithoutArguments(
        'NOT_NULL_AWARE_NULL_SPREAD',
        "The Null-typed expression can't be used with a non-null-aware spread.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInExtendsClause =
      CompileTimeErrorWithoutArguments(
        'NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
        "A class can't extend a nullable type.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInImplementsClause =
      CompileTimeErrorWithoutArguments(
        'NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
        "A class, mixin, or extension type can't implement a nullable type.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInOnClause =
      CompileTimeErrorWithoutArguments(
        'NULLABLE_TYPE_IN_ON_CLAUSE',
        "A mixin can't have a nullable type as a superclass constraint.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments nullableTypeInWithClause =
      CompileTimeErrorWithoutArguments(
        'NULLABLE_TYPE_IN_WITH_CLAUSE',
        "A class or mixin can't mix in a nullable type.",
        correctionMessage: "Try removing the question mark.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// 7.9 Superclasses: It is a compile-time error to specify an extends clause
  /// for class Object.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments objectCannotExtendAnotherClass =
      CompileTimeErrorWithoutArguments(
        'OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
        "The class 'Object' can't extend any other class.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments obsoleteColonForDefaultValue =
      CompileTimeErrorWithoutArguments(
        'OBSOLETE_COLON_FOR_DEFAULT_VALUE',
        "Using a colon as the separator before a default value is no longer "
            "supported.",
        correctionMessage: "Try replacing the colon with an equal sign.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the interface that is implemented more than once
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  onRepeated = CompileTimeErrorTemplate(
    'ON_REPEATED',
    "The type '{0}' can be included in the superclass constraints only once.",
    correctionMessage:
        "Try removing all except one occurrence of the type name.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsOnRepeated,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments optionalParameterInOperator =
      CompileTimeErrorWithoutArguments(
        'OPTIONAL_PARAMETER_IN_OPERATOR',
        "Optional parameters aren't allowed when defining an operator.",
        correctionMessage: "Try removing the optional parameters.",
        hasPublishedDocs: true,
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
    'PART_OF_DIFFERENT_LIBRARY',
    "Expected this library to be part of '{0}', not '{1}'.",
    correctionMessage:
        "Try including a different part, or changing the name of the library "
        "in the part's part-of directive.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPartOfDifferentLibrary,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a non-library declaration
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  partOfNonPart = CompileTimeErrorTemplate(
    'PART_OF_NON_PART',
    "The included part '{0}' must have a part-of directive.",
    correctionMessage: "Try adding a part-of directive to '{0}'.",
    hasPublishedDocs: true,
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
    'PART_OF_UNNAMED_LIBRARY',
    "The library is unnamed. A URI is expected, not a library name '{0}', in "
        "the part-of directive.",
    correctionMessage:
        "Try changing the part-of directive to a URI, or try including a "
        "different part.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPartOfUnnamedLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternAssignmentNotLocalVariable = CompileTimeErrorWithoutArguments(
    'PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE',
    "Only local variables can be assigned in pattern assignments.",
    correctionMessage: "Try assigning to a local variable.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternConstantFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used in patterns.",
    correctionMessage: "Try removing the keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the matched type
  /// Type p1: the required type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternTypeMismatchInIrrefutableContext = CompileTimeErrorTemplate(
    'PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT',
    "The matched value of type '{0}' isn't assignable to the required type "
        "'{1}'.",
    correctionMessage:
        "Try changing the required type of the pattern, or the matched value "
        "type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  patternVariableAssignmentInsideGuard = CompileTimeErrorWithoutArguments(
    'PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD',
    "Pattern variables can't be assigned inside the guard of the enclosing "
        "guarded pattern.",
    correctionMessage: "Try assigning to a different variable.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeDifferentFinalityOrType = CompileTimeErrorTemplate(
    'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    "The variable '{0}' doesn't have the same type and/or finality in all "
        "cases that share this body.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "all cases.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE',
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
    'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    "The variable '{0}' is not available because there is a label or 'default' "
        "case.",
    correctionMessage:
        "Try removing the label, or providing the 'default' case with its own "
        "body.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL',
    withArguments: _withArgumentsPatternVariableSharedCaseScopeHasLabel,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the pattern variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  patternVariableSharedCaseScopeNotAllCases = CompileTimeErrorTemplate(
    'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
    "The variable '{0}' is available in some, but not all cases that share "
        "this body.",
    correctionMessage:
        "Try declaring the variable pattern with the same type and finality in "
        "all cases.",
    hasPublishedDocs: true,
    uniqueName: 'PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES',
    withArguments: _withArgumentsPatternVariableSharedCaseScopeNotAllCases,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments positionalFieldInObjectPattern =
      CompileTimeErrorWithoutArguments(
        'POSITIONAL_FIELD_IN_OBJECT_PATTERN',
        "Object patterns can only use named fields.",
        correctionMessage: "Try specifying the field name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  positionalSuperFormalParameterWithPositionalArgument =
      CompileTimeErrorWithoutArguments(
        'POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
        "Positional super parameters can't be used when the super constructor "
            "invocation has a positional argument.",
        correctionMessage:
            "Try making all the positional parameters passed to the super "
            "constructor be either all super parameters or all normal parameters.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the prefix
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  prefixCollidesWithTopLevelMember = CompileTimeErrorTemplate(
    'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
    "The name '{0}' is already used as an import prefix and can't be used to "
        "name a top-level element.",
    correctionMessage:
        "Try renaming either the top-level element or the prefix.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPrefixCollidesWithTopLevelMember,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the prefix
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  prefixIdentifierNotFollowedByDot = CompileTimeErrorTemplate(
    'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
    "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
    correctionMessage:
        "Try correcting the name to refer to something other than a prefix, or "
        "renaming the prefix.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPrefixIdentifierNotFollowedByDot,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the prefix being shadowed
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  prefixShadowedByLocalDeclaration = CompileTimeErrorTemplate(
    'PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
    "The prefix '{0}' can't be used here because it's shadowed by a local "
        "declaration.",
    correctionMessage:
        "Try renaming either the prefix or the local declaration.",
    hasPublishedDocs: true,
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
    'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
    "The private name '{0}', defined by '{1}', conflicts with the same name "
        "defined by '{2}'.",
    correctionMessage: "Try removing '{1}' from the 'with' clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPrivateCollisionInMixinApplication,
    expectedTypes: [
      ExpectedType.string,
      ExpectedType.string,
      ExpectedType.string,
    ],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments privateOptionalParameter =
      CompileTimeErrorWithoutArguments(
        'PRIVATE_OPTIONAL_PARAMETER',
        "Named parameters can't start with an underscore.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the setter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  privateSetter = CompileTimeErrorTemplate(
    'PRIVATE_SETTER',
    "The setter '{0}' is private and can't be accessed outside the library "
        "that declares it.",
    correctionMessage: "Try making it public.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPrivateSetter,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  readPotentiallyUnassignedFinal = CompileTimeErrorTemplate(
    'READ_POTENTIALLY_UNASSIGNED_FINAL',
    "The final variable '{0}' can't be read because it's potentially "
        "unassigned at this point.",
    correctionMessage:
        "Ensure that it is assigned on necessary execution paths.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsReadPotentiallyUnassignedFinal,
    expectedTypes: [ExpectedType.string],
  );

  /// The documentation is in `front_end/message.yaml`.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  recordLiteralOnePositionalNoTrailingComma = CompileTimeErrorWithoutArguments(
    'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
    "A record literal with exactly one positional field requires a trailing "
        "comma.",
    correctionMessage: "Try adding a trailing comma.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments recursiveCompileTimeConstant =
      CompileTimeErrorWithoutArguments(
        'RECURSIVE_COMPILE_TIME_CONSTANT',
        "The compile-time constant expression depends on itself.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments recursiveConstantConstructor =
      CompileTimeErrorWithoutArguments(
        'RECURSIVE_CONSTANT_CONSTRUCTOR',
        "The constant constructor depends on itself.",
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
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  recursiveFactoryRedirect = CompileTimeErrorWithoutArguments(
    'RECURSIVE_CONSTRUCTOR_REDIRECT',
    "Constructors can't redirect to themselves either directly or indirectly.",
    correctionMessage:
        "Try changing one of the constructors in the loop to not redirect.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_FACTORY_REDIRECT',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the class that implements itself recursively
  /// String p1: a string representation of the implements loop
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  recursiveInterfaceInheritance = CompileTimeErrorTemplate(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't be a superinterface of itself: {1}.",
    hasPublishedDocs: true,
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
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't extend itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
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
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't implement itself.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
    withArguments: _withArgumentsRecursiveInterfaceInheritanceImplements,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the mixin that constraints itself recursively
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  recursiveInterfaceInheritanceOn = CompileTimeErrorTemplate(
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a superclass constraint.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_ON',
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
    'RECURSIVE_INTERFACE_INHERITANCE',
    "'{0}' can't use itself as a mixin.",
    hasPublishedDocs: true,
    uniqueName: 'RECURSIVE_INTERFACE_INHERITANCE_WITH',
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
    'REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or defining the "
        "constructor named '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsRedirectGenerativeToMissingConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  redirectGenerativeToNonGenerativeConstructor =
      CompileTimeErrorWithoutArguments(
        'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
        "Generative constructors can't redirect to a factory constructor.",
        correctionMessage: "Try redirecting to a different constructor.",
        hasPublishedDocs: true,
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
    'REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
    "The redirecting constructor '{0}' can't redirect to a constructor of the "
        "abstract class '{1}'.",
    correctionMessage: "Try redirecting to a constructor of a different class.",
    hasPublishedDocs: true,
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
    'REDIRECT_TO_INVALID_FUNCTION_TYPE',
    "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
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
    'REDIRECT_TO_INVALID_RETURN_TYPE',
    "The return type '{0}' of the redirected constructor isn't a subtype of "
        "'{1}'.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
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
    'REDIRECT_TO_MISSING_CONSTRUCTOR',
    "The constructor '{0}' couldn't be found in '{1}'.",
    correctionMessage:
        "Try redirecting to a different constructor, or define the constructor "
        "named '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsRedirectToMissingConstructor,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the non-type referenced in the redirect
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  redirectToNonClass = CompileTimeErrorTemplate(
    'REDIRECT_TO_NON_CLASS',
    "The name '{0}' isn't a type and can't be used in a redirected "
        "constructor.",
    correctionMessage: "Try redirecting to a different constructor.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsRedirectToNonClass,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments redirectToNonConstConstructor =
      CompileTimeErrorWithoutArguments(
        'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
        "A constant redirecting constructor can't redirect to a non-constant "
            "constructor.",
        correctionMessage: "Try redirecting to a different constructor.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  redirectToTypeAliasExpandsToTypeParameter = CompileTimeErrorWithoutArguments(
    'REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
    "A redirecting constructor can't redirect to a type alias that expands to "
        "a type parameter.",
    correctionMessage: "Try replacing it with a class.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the name of the variable
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  referencedBeforeDeclaration = CompileTimeErrorTemplate(
    'REFERENCED_BEFORE_DECLARATION',
    "Local variable '{0}' can't be referenced before it is declared.",
    correctionMessage:
        "Try moving the declaration to before the first use, or renaming the "
        "local variable so that it doesn't hide a name from an enclosing "
        "scope.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsReferencedBeforeDeclaration,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  refutablePatternInIrrefutableContext = CompileTimeErrorWithoutArguments(
    'REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT',
    "Refutable patterns can't be used in an irrefutable context.",
    correctionMessage:
        "Try using an if-case, a 'switch' statement, or a 'switch' expression "
        "instead.",
    hasPublishedDocs: true,
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
    'RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE',
    "The constant expression type '{0}' is not assignable to the parameter "
        "type '{1}' of the '{2}' operator.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsRelationalPatternOperandTypeNotAssignable,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  relationalPatternOperatorReturnTypeNotAssignableToBool =
      CompileTimeErrorWithoutArguments(
        'RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL',
        "The return type of operators used in relational patterns must be "
            "assignable to 'bool'.",
        correctionMessage:
            "Try updating the operator declaration to return 'bool'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments restElementInMapPattern =
      CompileTimeErrorWithoutArguments(
        'REST_ELEMENT_IN_MAP_PATTERN',
        "A map pattern can't contain a rest pattern.",
        correctionMessage: "Try removing the rest pattern.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments rethrowOutsideCatch =
      CompileTimeErrorWithoutArguments(
        'RETHROW_OUTSIDE_CATCH',
        "A rethrow must be inside of a catch clause.",
        correctionMessage:
            "Try moving the expression into a catch clause, or using a 'throw' "
            "expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments returnInGenerativeConstructor =
      CompileTimeErrorWithoutArguments(
        'RETURN_IN_GENERATIVE_CONSTRUCTOR',
        "Constructors can't return values.",
        correctionMessage:
            "Try removing the return statement or using a factory constructor.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  returnInGenerator = CompileTimeErrorWithoutArguments(
    'RETURN_IN_GENERATOR',
    "Can't return a value from a generator function that uses the 'async*' or "
        "'sync*' modifier.",
    correctionMessage:
        "Try replacing 'return' with 'yield', using a block function body, or "
        "changing the method body modifier.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the return type as declared in the return statement
  /// Type p1: the expected return type as defined by the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  returnOfInvalidTypeFromClosure = CompileTimeErrorTemplate(
    'RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
    "The returned type '{0}' isn't returnable from a '{1}' function, as "
        "required by the closure's context.",
    hasPublishedDocs: true,
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
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the constructor '{2}' "
        "because it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
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
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the function '{2}' because "
        "it has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
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
    'RETURN_OF_INVALID_TYPE',
    "A value of type '{0}' can't be returned from the method '{2}' because it "
        "has a return type of '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_METHOD',
    withArguments: _withArgumentsReturnOfInvalidTypeFromMethod,
    expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments returnWithoutValue =
      CompileTimeErrorWithoutArguments(
        'RETURN_WITHOUT_VALUE',
        "The return value is missing after 'return'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the sealed class being extended, implemented, or
  ///            mixed in
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  sealedClassSubtypeOutsideOfLibrary = CompileTimeErrorTemplate(
    'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
    "The class '{0}' can't be extended, implemented, or mixed in outside of "
        "its library because it's a sealed class.",
    hasPublishedDocs: true,
    uniqueName: 'SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY',
    withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  setElementFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be used as values in a "
        "'const' set literal.",
    correctionMessage:
        "Try removing the keyword 'const' from the set literal or removing the "
        "keyword 'deferred' from the import.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_FROM_DEFERRED_LIBRARY',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the actual type of the set element
  /// Type p1: the expected type of the set element
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  setElementTypeNotAssignable = CompileTimeErrorTemplate(
    'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
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
    'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
    "The element type '{0}' can't be assigned to the set type '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
    withArguments: _withArgumentsSetElementTypeNotAssignableNullability,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  sharedDeferredPrefix = CompileTimeErrorWithoutArguments(
    'SHARED_DEFERRED_PREFIX',
    "The prefix of a deferred import can't be used in other import directives.",
    correctionMessage: "Try renaming one of the prefixes.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  spreadExpressionFromDeferredLibrary = CompileTimeErrorWithoutArguments(
    'SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
    "Constant values from a deferred library can't be spread into a const "
        "literal.",
    correctionMessage: "Try making the deferred import non-deferred.",
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the instance member
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  staticAccessToInstanceMember = CompileTimeErrorTemplate(
    'STATIC_ACCESS_TO_INSTANCE_MEMBER',
    "Instance member '{0}' can't be accessed using static access.",
    hasPublishedDocs: true,
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
    'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
        "'{1}' is 'base'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED',
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
    'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
    "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
        "'{1}' is 'final'.",
    hasPublishedDocs: true,
    uniqueName: 'SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
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
    'SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
    "The type '{0}' of this parameter isn't a subtype of the type '{1}' of the "
        "associated super constructor parameter.",
    correctionMessage:
        "Try removing the explicit type annotation from the parameter.",
    hasPublishedDocs: true,
    withArguments:
        _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superFormalParameterWithoutAssociatedNamed = CompileTimeErrorWithoutArguments(
    'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
    "No associated named super constructor parameter.",
    correctionMessage:
        "Try changing the name to the name of an existing named super "
        "constructor parameter, or creating such named parameter.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superFormalParameterWithoutAssociatedPositional =
      CompileTimeErrorWithoutArguments(
        'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
        "No associated positional super constructor parameter.",
        correctionMessage:
            "Try using a normal parameter, or adding more positional parameters to "
            "the super constructor.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInEnumConstructor =
      CompileTimeErrorWithoutArguments(
        'SUPER_IN_ENUM_CONSTRUCTOR',
        "The enum constructor can't have a 'super' initializer.",
        correctionMessage: "Try removing the 'super' invocation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  superInExtension = CompileTimeErrorWithoutArguments(
    'SUPER_IN_EXTENSION',
    "The 'super' keyword can't be used in an extension because an extension "
        "doesn't have a superclass.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInExtensionType =
      CompileTimeErrorWithoutArguments(
        'SUPER_IN_EXTENSION_TYPE',
        "The 'super' keyword can't be used in an extension type because an "
            "extension type doesn't have a superclass.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInInvalidContext =
      CompileTimeErrorWithoutArguments(
        'SUPER_IN_INVALID_CONTEXT',
        "Invalid context for 'super' invocation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
  /// is a compile-time error if a generative constructor of class Object
  /// includes a superinitializer.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInitializerInObject =
      CompileTimeErrorWithoutArguments(
        'SUPER_INITIALIZER_IN_OBJECT',
        "The class 'Object' can't invoke a constructor from a superclass.",
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments superInRedirectingConstructor =
      CompileTimeErrorWithoutArguments(
        'SUPER_IN_REDIRECTING_CONSTRUCTOR',
        "The redirecting constructor can't have a 'super' initializer.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the superinitializer
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  superInvocationNotLast = CompileTimeErrorTemplate(
    'SUPER_INVOCATION_NOT_LAST',
    "The superconstructor call must be last in an initializer list: '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsSuperInvocationNotLast,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments switchCaseCompletesNormally =
      CompileTimeErrorWithoutArguments(
        'SWITCH_CASE_COMPLETES_NORMALLY',
        "The 'case' shouldn't complete normally.",
        correctionMessage: "Try adding 'break', 'return', or 'throw'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  tearoffOfGenerativeConstructorOfAbstractClass =
      CompileTimeErrorWithoutArguments(
        'TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
        "A generative constructor of an abstract class can't be torn off.",
        correctionMessage:
            "Try tearing off a constructor of a concrete class, or a "
            "non-generative constructor.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the type that can't be thrown
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  throwOfInvalidType = CompileTimeErrorTemplate(
    'THROW_OF_INVALID_TYPE',
    "The type '{0}' of the thrown expression must be assignable to 'Object'.",
    hasPublishedDocs: true,
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
    'TOP_LEVEL_CYCLE',
    "The type of '{0}' can't be inferred because it depends on itself through "
        "the cycle: {1}.",
    correctionMessage:
        "Try adding an explicit type to one or more of the variables in the "
        "cycle in order to break the cycle.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTopLevelCycle,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  typeAliasCannotReferenceItself = CompileTimeErrorWithoutArguments(
    'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
    "Typedefs can't reference themselves directly or recursively via another "
        "typedef.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the type that is deferred and being used in a type
  ///            annotation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeAnnotationDeferredClass = CompileTimeErrorTemplate(
    'TYPE_ANNOTATION_DEFERRED_CLASS',
    "The deferred type '{0}' can't be used in a declaration, cast, or type "
        "test.",
    correctionMessage:
        "Try using a different type, or changing the import to not be "
        "deferred.",
    hasPublishedDocs: true,
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
    'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
    "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
    correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTypeArgumentNotMatchingBounds,
    expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  typeParameterReferencedByStatic = CompileTimeErrorWithoutArguments(
    'TYPE_PARAMETER_REFERENCED_BY_STATIC',
    "Static members can't reference type parameters of the class.",
    correctionMessage:
        "Try removing the reference to the type parameter, or making the "
        "member an instance member.",
    hasPublishedDocs: true,
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
    'TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
    "'{0}' can't be a supertype of its upper bound.",
    correctionMessage:
        "Try using a type that is the same as or a subclass of '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTypeParameterSupertypeOfItsBound,
    expectedTypes: [ExpectedType.string, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithNonType = CompileTimeErrorTemplate(
    'TYPE_TEST_WITH_NON_TYPE',
    "The name '{0}' isn't a type and can't be used in an 'is' expression.",
    correctionMessage: "Try correcting the name to match an existing type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTypeTestWithNonType,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  typeTestWithUndefinedName = CompileTimeErrorTemplate(
    'TYPE_TEST_WITH_UNDEFINED_NAME',
    "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
    correctionMessage:
        "Try changing the name to the name of an existing type, or creating a "
        "type with the name '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTypeTestWithUndefinedName,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedInvocationOfNullableValue = CompileTimeErrorWithoutArguments(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The function can't be unconditionally invoked because it can be 'null'.",
    correctionMessage: "Try adding a null check ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_INVOCATION_OF_NULLABLE_VALUE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedMethodInvocationOfNullableValue = CompileTimeErrorTemplate(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The method '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the call conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedMethodInvocationOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the operator
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedOperatorInvocationOfNullableValue = CompileTimeErrorTemplate(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The operator '{0}' can't be unconditionally invoked because the receiver "
        "can be 'null'.",
    correctionMessage: "Try adding a null check to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedOperatorInvocationOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the property
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uncheckedPropertyAccessOfNullableValue = CompileTimeErrorTemplate(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "The property '{0}' can't be unconditionally accessed because the receiver "
        "can be 'null'.",
    correctionMessage:
        "Try making the access conditional (using '?.') or adding a null check "
        "to the target ('!').",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
    withArguments: _withArgumentsUncheckedPropertyAccessOfNullableValue,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueAsCondition = CompileTimeErrorWithoutArguments(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as a condition.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as a "
        "condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueAsIterator = CompileTimeErrorWithoutArguments(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used as an iterator in a for-in loop.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it as an "
        "iterator.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueInSpread = CompileTimeErrorWithoutArguments(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a spread.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a spread, "
        "or use a null-aware spread.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  uncheckedUseOfNullableValueInYieldEach = CompileTimeErrorWithoutArguments(
    'UNCHECKED_USE_OF_NULLABLE_VALUE',
    "A nullable expression can't be used in a yield-each statement.",
    correctionMessage:
        "Try checking that the value isn't 'null' before using it in a "
        "yield-each statement.",
    hasPublishedDocs: true,
    uniqueName: 'UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the annotation
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedAnnotation = CompileTimeErrorTemplate(
    'UNDEFINED_ANNOTATION',
    "Undefined name '{0}' used as an annotation.",
    correctionMessage:
        "Try defining the name or importing it from another library.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    withArguments: _withArgumentsUndefinedAnnotation,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the undefined class
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedClass = CompileTimeErrorTemplate(
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage:
        "Try changing the name to the name of an existing class, or creating a "
        "class with the name '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
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
    'UNDEFINED_CLASS',
    "Undefined class '{0}'.",
    correctionMessage: "Try using the type 'bool'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    uniqueName: 'UNDEFINED_CLASS_BOOLEAN',
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
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have a constructor named '{1}'.",
    correctionMessage:
        "Try defining a constructor named '{1}' in '{0}', or invoking a "
        "different constructor.",
    hasPublishedDocs: true,
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
    'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
    "The class '{0}' doesn't have an unnamed constructor.",
    correctionMessage:
        "Try defining an unnamed constructor in '{0}', or invoking a different "
        "constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
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
    'UNDEFINED_ENUM_CONSTANT',
    "There's no constant named '{0}' in '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constant, or "
        "defining a constant named '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUndefinedEnumConstant,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the constructor that is undefined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedEnumConstructorNamed = CompileTimeErrorTemplate(
    'UNDEFINED_ENUM_CONSTRUCTOR',
    "The enum doesn't have a constructor named '{0}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing constructor, or "
        "defining constructor with the name '{0}'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_NAMED',
    withArguments: _withArgumentsUndefinedEnumConstructorNamed,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  undefinedEnumConstructorUnnamed = CompileTimeErrorWithoutArguments(
    'UNDEFINED_ENUM_CONSTRUCTOR',
    "The enum doesn't have an unnamed constructor.",
    correctionMessage:
        "Try adding the name of an existing constructor, or defining an "
        "unnamed constructor.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the getter that is undefined
  /// String p1: the name of the extension that was explicitly specified
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedExtensionGetter = CompileTimeErrorTemplate(
    'UNDEFINED_EXTENSION_GETTER',
    "The getter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter named '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_EXTENSION_METHOD',
    "The method '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_EXTENSION_OPERATOR',
    "The operator '{0}' isn't defined for the extension '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_EXTENSION_SETTER',
    "The setter '{0}' isn't defined for the extension '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter named '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUndefinedExtensionSetter,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedFunction = CompileTimeErrorTemplate(
    'UNDEFINED_FUNCTION',
    "The function '{0}' isn't defined.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing function, or defining a function named '{0}'.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
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
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing getter, or defining a getter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_GETTER',
    "The getter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_GETTER_ON_FUNCTION_TYPE',
    withArguments: _withArgumentsUndefinedGetterOnFunctionType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the identifier
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedIdentifier = CompileTimeErrorTemplate(
    'UNDEFINED_IDENTIFIER',
    "Undefined name '{0}'.",
    correctionMessage:
        "Try correcting the name to one that is defined, or defining the name.",
    hasPublishedDocs: true,
    isUnresolvedIdentifier: true,
    withArguments: _withArgumentsUndefinedIdentifier,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  undefinedIdentifierAwait = CompileTimeErrorWithoutArguments(
    'UNDEFINED_IDENTIFIER_AWAIT',
    "Undefined name 'await' in function body not marked with 'async'.",
    correctionMessage:
        "Try correcting the name to one that is defined, defining the name, or "
        "adding 'async' to the enclosing function body.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method that is undefined
  /// Object p1: the resolved type name that the method lookup is happening on
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0, required Object p1})
  >
  undefinedMethod = CompileTimeErrorTemplate(
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_METHOD',
    "The method '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension method on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_METHOD_ON_FUNCTION_TYPE',
    withArguments: _withArgumentsUndefinedMethodOnFunctionType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the requested named parameter
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  undefinedNamedParameter = CompileTimeErrorTemplate(
    'UNDEFINED_NAMED_PARAMETER',
    "The named parameter '{0}' isn't defined.",
    correctionMessage:
        "Try correcting the name to an existing named parameter's name, or "
        "defining a named parameter with the name '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_OPERATOR',
    "The operator '{0}' isn't defined for the type '{1}'.",
    correctionMessage: "Try defining the operator '{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_PREFIXED_NAME',
    "The name '{0}' is being referenced through the prefix '{1}', but it isn't "
        "defined in any of the libraries imported using that prefix.",
    correctionMessage:
        "Try correcting the prefix or importing the library that defines "
        "'{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the type '{1}'.",
    correctionMessage:
        "Try importing the library that defines '{0}', correcting the name to "
        "the name of an existing setter, or defining a setter or field named "
        "'{0}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_SETTER',
    "The setter '{0}' isn't defined for the '{1}' function type.",
    correctionMessage:
        "Try wrapping the function type alias in parentheses in order to "
        "access '{0}' as an extension getter on 'Type'.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SETTER_ON_FUNCTION_TYPE',
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
    'UNDEFINED_SUPER_MEMBER',
    "The getter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing getter, or "
        "defining a getter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_GETTER',
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
    'UNDEFINED_SUPER_MEMBER',
    "The method '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing method, or "
        "defining a method named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_METHOD',
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
    'UNDEFINED_SUPER_MEMBER',
    "The operator '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage: "Try defining the operator '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_OPERATOR',
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
    'UNDEFINED_SUPER_MEMBER',
    "The setter '{0}' isn't defined in a superclass of '{1}'.",
    correctionMessage:
        "Try correcting the name to the name of an existing setter, or "
        "defining a setter or field named '{0}' in a superclass.",
    hasPublishedDocs: true,
    uniqueName: 'UNDEFINED_SUPER_SETTER',
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
    'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
    "Static members from supertypes must be qualified by the name of the "
        "defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnqualifiedReferenceToNonLocalStaticMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the defining type
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unqualifiedReferenceToStaticMemberOfExtendedType = CompileTimeErrorTemplate(
    'UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
    "Static members from the extended type or one of its superclasses must be "
        "qualified by the name of the defining type.",
    correctionMessage: "Try adding '{0}.' before the name.",
    hasPublishedDocs: true,
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
    'URI_DOES_NOT_EXIST',
    "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUriDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uriHasNotBeenGenerated = CompileTimeErrorTemplate(
    'URI_HAS_NOT_BEEN_GENERATED',
    "Target of URI hasn't been generated: '{0}'.",
    correctionMessage:
        "Try running the generator that will generate the file referenced by "
        "the URI.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUriHasNotBeenGenerated,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments uriWithInterpolation =
      CompileTimeErrorWithoutArguments(
        'URI_WITH_INTERPOLATION',
        "URIs can't use string interpolation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  useOfNativeExtension = CompileTimeErrorWithoutArguments(
    'USE_OF_NATIVE_EXTENSION',
    "Dart native extensions are deprecated and aren't available in Dart 2.15.",
    correctionMessage: "Try using dart:ffi for C interop.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  useOfVoidResult = CompileTimeErrorWithoutArguments(
    'USE_OF_VOID_RESULT',
    "This expression has a type of 'void' so its value can't be used.",
    correctionMessage:
        "Try checking to see if you're using the correct API; there might be a "
        "function or call that returns void you didn't expect. Also check type "
        "parameters and variables which might also be void.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const CompileTimeErrorWithoutArguments valuesDeclarationInEnum =
      CompileTimeErrorWithoutArguments(
        'VALUES_DECLARATION_IN_ENUM',
        "A member named 'values' can't be declared in an enum.",
        correctionMessage: "Try using a different name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the type of the object being assigned.
  /// Object p1: the type of the variable being assigned to
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  variableTypeMismatch = CompileTimeErrorTemplate(
    'VARIABLE_TYPE_MISMATCH',
    "A value of type '{0}' can't be assigned to a const variable of type "
        "'{1}'.",
    correctionMessage: "Try using a subtype, or removing the 'const' keyword",
    hasPublishedDocs: true,
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
    'WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position "
        "in '{3}'.",
    correctionMessage:
        "Try using 'in' type parameters in 'in' positions and 'out' type "
        "parameters in 'out' positions in the superinterface.",
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
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
    hasPublishedDocs: true,
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
    'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
    "Operator '-' should declare 0 or 1 parameter, but {0} found.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
    "The type '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    hasPublishedDocs: true,
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "This function is declared with {0} type parameters, but {1} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    "The constructor '{0}.{1}' doesn't have type parameters.",
    correctionMessage: "Try moving type arguments to after the type name.",
    hasPublishedDocs: true,
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
    "The constructor '{0}.{1}` doesn't have type parameters.",
    correctionMessage:
        "Try removing the type arguments, or adding a class name, followed by "
        "the type arguments, then the constructor name.",
    hasPublishedDocs: true,
    uniqueName: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR',
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
    "The enum is declared with {0} type parameters, but {1} type arguments "
        "were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
    "The extension '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
    "The function '{0}' is declared with {1} type parameters, but {2} type "
        "arguments were given.",
    correctionMessage:
        "Try adjusting the number of type arguments to match the number of "
        "type parameters.",
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
    'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
    "The method '{0}' is declared with {1} type parameters, but {2} type "
        "arguments are given.",
    correctionMessage: "Try adjusting the number of type arguments.",
    hasPublishedDocs: true,
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
    'WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
    "'{0}' can't be used contravariantly or invariantly in '{1}'.",
    correctionMessage:
        "Try not using class type parameters in types of formal parameters of "
        "function types, nor in explicitly contravariant or invariant "
        "superinterfaces.",
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
    'WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
    "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
    correctionMessage:
        "Try removing the type parameter or change the explicit variance "
        "modifier declaration for the type parameter to another one of 'in', "
        "'out', or 'inout'.",
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
    'YIELD_IN_NON_GENERATOR',
    "Yield-each statements must be in a generator function (one marked with "
        "either 'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_IN_NON_GENERATOR',
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the expression after `yield*`
  /// Type p1: the return type of the function containing the `yield*`
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldEachOfInvalidType = CompileTimeErrorTemplate(
    'YIELD_OF_INVALID_TYPE',
    "The type '{0}' implied by the 'yield*' expression must be assignable to "
        "'{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'YIELD_EACH_OF_INVALID_TYPE',
    withArguments: _withArgumentsYieldEachOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// ?? Yield: It is a compile-time error if a yield statement appears in a
  /// function that is not a generator function.
  ///
  /// No parameters.
  static const CompileTimeErrorWithoutArguments
  yieldInNonGenerator = CompileTimeErrorWithoutArguments(
    'YIELD_IN_NON_GENERATOR',
    "Yield statements must be in a generator function (one marked with either "
        "'async*' or 'sync*').",
    correctionMessage:
        "Try adding 'async*' or 'sync*' to the enclosing function.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// Type p0: the type of the expression after `yield`
  /// Type p1: the return type of the function containing the `yield`
  static const CompileTimeErrorTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  yieldOfInvalidType = CompileTimeErrorTemplate(
    'YIELD_OF_INVALID_TYPE',
    "A yielded value of type '{0}' must be assignable to '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsYieldOfInvalidType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorCode(
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
         uniqueName: 'CompileTimeErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticType.COMPILE_TIME_ERROR.severity;

  @override
  DiagnosticType get type => DiagnosticType.COMPILE_TIME_ERROR;

  static LocatableDiagnostic _withArgumentsAbstractSuperMemberReference({
    required String memberKind,
    required String name,
  }) {
    return LocatableDiagnosticImpl(abstractSuperMemberReference, [
      memberKind,
      name,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAmbiguousExport({
    required String p0,
    required Uri p1,
    required Uri p2,
  }) {
    return LocatableDiagnosticImpl(ambiguousExport, [p0, p1, p2]);
  }

  static LocatableDiagnostic
  _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(ambiguousExtensionMemberAccessThreeOrMore, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessTwo({
    required String p0,
    required Element p1,
    required Element p2,
  }) {
    return LocatableDiagnosticImpl(ambiguousExtensionMemberAccessTwo, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAmbiguousImport({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(ambiguousImport, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsArgumentTypeNotAssignable({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(argumentTypeNotAssignable, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(assignmentToFinal, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinalLocal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(assignmentToFinalLocal, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAssignmentToFinalNoSetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(assignmentToFinalNoSetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsAugmentationModifierExtra({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(augmentationModifierExtra, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAugmentationModifierMissing({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(augmentationModifierMissing, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsAugmentationOfDifferentDeclarationKind({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(augmentationOfDifferentDeclarationKind, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAugmentedExpressionNotOperator({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(augmentedExpressionNotOperator, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsBaseClassImplementedOutsideOfLibrary({
    required String implementedClassName,
  }) {
    return LocatableDiagnosticImpl(baseClassImplementedOutsideOfLibrary, [
      implementedClassName,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsBaseMixinImplementedOutsideOfLibrary({
    required String implementedMixinName,
  }) {
    return LocatableDiagnosticImpl(baseMixinImplementedOutsideOfLibrary, [
      implementedMixinName,
    ]);
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormally({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(bodyMightCompleteNormally, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(builtInIdentifierAsExtensionName, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsBuiltInIdentifierAsExtensionTypeName({required String p0}) {
    return LocatableDiagnosticImpl(builtInIdentifierAsExtensionTypeName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsPrefixName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(builtInIdentifierAsPrefixName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(builtInIdentifierAsType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypedefName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(builtInIdentifierAsTypedefName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(builtInIdentifierAsTypeName, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsBuiltInIdentifierAsTypeParameterName({required String p0}) {
    return LocatableDiagnosticImpl(builtInIdentifierAsTypeParameterName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCaseExpressionTypeImplementsEquals({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(caseExpressionTypeImplementsEquals, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      caseExpressionTypeIsNotSwitchExpressionSubtype,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsCastToNonType({required String p0}) {
    return LocatableDiagnosticImpl(castToNonType, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToInstanceMember({required String p0}) {
    return LocatableDiagnosticImpl(classInstantiationAccessToInstanceMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToStaticMember({required String p0}) {
    return LocatableDiagnosticImpl(classInstantiationAccessToStaticMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsClassInstantiationAccessToUnknownMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(classInstantiationAccessToUnknownMember, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsClassUsedAsMixin({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(classUsedAsMixin, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConcreteClassWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(concreteClassWithAbstractMember, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticField({required String p0}) {
    return LocatableDiagnosticImpl(conflictingConstructorAndStaticField, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticGetter({required String p0}) {
    return LocatableDiagnosticImpl(conflictingConstructorAndStaticGetter, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticMethod({required String p0}) {
    return LocatableDiagnosticImpl(conflictingConstructorAndStaticMethod, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingConstructorAndStaticSetter({required String p0}) {
    return LocatableDiagnosticImpl(conflictingConstructorAndStaticSetter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConflictingFieldAndMethod({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(conflictingFieldAndMethod, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsConflictingGenericInterfaces({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(conflictingGenericInterfaces, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConflictingInheritedMethodAndSetter({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(conflictingInheritedMethodAndSetter, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConflictingMethodAndField({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(conflictingMethodAndField, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsConflictingStaticAndInstance({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(conflictingStaticAndInstance, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndEnum({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndEnum, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtension({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndExtension, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndExtensionType({required String p0}) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndExtensionType, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberClass({required String p0}) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndMemberClass, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberEnum({required String p0}) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndMemberEnum, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberExtension({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndMemberExtension, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberExtensionType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      conflictingTypeVariableAndMemberExtensionType,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsConflictingTypeVariableAndMemberMixin({required String p0}) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndMemberMixin, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMixin({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(conflictingTypeVariableAndMixin, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstConstructorFieldTypeMismatch({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(constConstructorFieldTypeMismatch, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConstConstructorParamTypeMismatch({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(constConstructorParamTypeMismatch, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsConstConstructorWithFieldInitializedByNonConst({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      constConstructorWithFieldInitializedByNonConst,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(constConstructorWithMixinWithField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithFields({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(constConstructorWithMixinWithFields, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstConstructorWithNonConstSuper({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(constConstructorWithNonConstSuper, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConstEvalAssertionFailureWithMessage({required Object p0}) {
    return LocatableDiagnosticImpl(constEvalAssertionFailureWithMessage, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstEvalPropertyAccess({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(constEvalPropertyAccess, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsConstFieldInitializerNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(constFieldInitializerNotAssignable, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsConstMapKeyNotPrimitiveEquality({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(constMapKeyNotPrimitiveEquality, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstNotInitialized({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(constNotInitialized, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstSetElementNotPrimitiveEquality({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(constSetElementNotPrimitiveEquality, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(constWithNonType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsConstWithUndefinedConstructor({
    required Object p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(constWithUndefinedConstructor, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsConstWithUndefinedConstructorDefault({required String p0}) {
    return LocatableDiagnosticImpl(constWithUndefinedConstructorDefault, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCouldNotInfer({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(couldNotInfer, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsDefinitelyUnassignedLateLocalVariable({required String p0}) {
    return LocatableDiagnosticImpl(definitelyUnassignedLateLocalVariable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDotShorthandUndefinedGetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(dotShorthandUndefinedGetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDotShorthandUndefinedInvocation({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(dotShorthandUndefinedInvocation, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateConstructorName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(duplicateConstructorName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateDefinition({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicateDefinition, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateFieldFormalParameter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicateFieldFormalParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateFieldName({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicateFieldName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateNamedArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(duplicateNamedArgument, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicatePart({required Uri p0}) {
    return LocatableDiagnosticImpl(duplicatePart, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicatePatternAssignmentVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicatePatternAssignmentVariable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicatePatternField({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicatePatternField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateVariablePattern({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(duplicateVariablePattern, [p0]);
  }

  static LocatableDiagnostic _withArgumentsEnumWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(enumWithAbstractMember, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsExpectedOneListPatternTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(expectedOneListPatternTypeArguments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExpectedOneListTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(expectedOneListTypeArguments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExpectedOneSetTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(expectedOneSetTypeArguments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExpectedTwoMapPatternTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(expectedTwoMapPatternTypeArguments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExpectedTwoMapTypeArguments({
    required int p0,
  }) {
    return LocatableDiagnosticImpl(expectedTwoMapTypeArguments, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExportInternalLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(exportInternalLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExportOfNonLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(exportOfNonLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExtendsDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(extendsDisallowedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExtensionAsExpression({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(extensionAsExpression, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsExtensionConflictingStaticAndInstance({required String p0}) {
    return LocatableDiagnosticImpl(extensionConflictingStaticAndInstance, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsExtensionOverrideArgumentNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(extensionOverrideArgumentNotAssignable, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeImplementsDisallowedType({required DartType p0}) {
    return LocatableDiagnosticImpl(extensionTypeImplementsDisallowedType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsExtensionTypeImplementsNotSupertype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(extensionTypeImplementsNotSupertype, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeImplementsRepresentationNotSupertype({
    required DartType p0,
    required String p1,
    required DartType p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(
      extensionTypeImplementsRepresentationNotSupertype,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic
  _withArgumentsExtensionTypeInheritedMemberConflict({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(extensionTypeInheritedMemberConflict, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsExtensionTypeWithAbstractMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(extensionTypeWithAbstractMember, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsExtraPositionalArguments({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(extraPositionalArguments, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsExtraPositionalArgumentsCouldBeNamed({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(extraPositionalArgumentsCouldBeNamed, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsFieldInitializedByMultipleInitializers({required String p0}) {
    return LocatableDiagnosticImpl(fieldInitializedByMultipleInitializers, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsFieldInitializerNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(fieldInitializerNotAssignable, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsFieldInitializingFormalNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(fieldInitializingFormalNotAssignable, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsFinalClassExtendedOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(finalClassExtendedOutsideOfLibrary, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsFinalClassImplementedOutsideOfLibrary({required String p0}) {
    return LocatableDiagnosticImpl(finalClassImplementedOutsideOfLibrary, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      finalClassUsedAsMixinConstraintOutsideOfLibrary,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsFinalInitializedInDeclarationAndConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      finalInitializedInDeclarationAndConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitialized({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(finalNotInitialized, [p0]);
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor1({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(finalNotInitializedConstructor1, [p0]);
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor2({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(finalNotInitializedConstructor2, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor3Plus({
    required String p0,
    required String p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(finalNotInitializedConstructor3Plus, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsForInOfInvalidElementType({
    required DartType p0,
    required String p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(forInOfInvalidElementType, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsForInOfInvalidType({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(forInOfInvalidType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsGetterNotAssignableSetterTypes({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(getterNotAssignableSetterTypes, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic _withArgumentsGetterNotSubtypeSetterTypes({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(getterNotSubtypeSetterTypes, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsIllegalConcreteEnumMemberDeclaration({required String p0}) {
    return LocatableDiagnosticImpl(illegalConcreteEnumMemberDeclaration, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsIllegalConcreteEnumMemberInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(illegalConcreteEnumMemberInheritance, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsIllegalEnumValuesInheritance({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(illegalEnumValuesInheritance, [p0]);
  }

  static LocatableDiagnostic _withArgumentsIllegalLanguageVersionOverride({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(illegalLanguageVersionOverride, [p0]);
  }

  static LocatableDiagnostic _withArgumentsImplementsDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(implementsDisallowedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsImplementsRepeated({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(implementsRepeated, [p0]);
  }

  static LocatableDiagnostic _withArgumentsImplementsSuperClass({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(implementsSuperClass, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsImplicitSuperInitializerMissingArguments({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(implicitSuperInitializerMissingArguments, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsImplicitThisReferenceInInitializer({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(implicitThisReferenceInInitializer, [p0]);
  }

  static LocatableDiagnostic _withArgumentsImportInternalLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(importInternalLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsImportOfNonLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(importOfNonLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInconsistentCaseExpressionTypes({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(inconsistentCaseExpressionTypes, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInconsistentInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(inconsistentInheritance, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsInconsistentInheritanceGetterAndMethod({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(inconsistentInheritanceGetterAndMethod, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInconsistentPatternVariableLogicalOr({required String p0}) {
    return LocatableDiagnosticImpl(inconsistentPatternVariableLogicalOr, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInitializerForNonExistentField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(initializerForNonExistentField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInitializerForStaticField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(initializerForStaticField, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInitializingFormalForNonExistentField({required String p0}) {
    return LocatableDiagnosticImpl(initializingFormalForNonExistentField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInstanceAccessToStaticMember({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(instanceAccessToStaticMember, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      instanceAccessToStaticMemberOfUnnamedExtension,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsIntegerLiteralImpreciseAsDouble({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(integerLiteralImpreciseAsDouble, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsIntegerLiteralOutOfRange({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(integerLiteralOutOfRange, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInterfaceClassExtendedOutsideOfLibrary({required String p0}) {
    return LocatableDiagnosticImpl(interfaceClassExtendedOutsideOfLibrary, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidAssignment({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(invalidAssignment, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastFunction({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(invalidCastFunction, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastFunctionExpr({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidCastFunctionExpr, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteral({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(invalidCastLiteral, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralList({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidCastLiteralList, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralMap({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidCastLiteralMap, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastLiteralSet({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidCastLiteralSet, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastMethod({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(invalidCastMethod, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCastNewExpr({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidCastNewExpr, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidImplementationOverride({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(invalidImplementationOverride, [
      p0,
      p1,
      p2,
      p3,
      p4,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidImplementationOverrideSetter({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(invalidImplementationOverrideSetter, [
      p0,
      p1,
      p2,
      p3,
      p4,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidModifierOnConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidModifierOnConstructor, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOverride({
    required String p0,
    required String p1,
    required DartType p2,
    required String p3,
    required DartType p4,
  }) {
    return LocatableDiagnosticImpl(invalidOverride, [p0, p1, p2, p3, p4]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOverrideSetter({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  }) {
    return LocatableDiagnosticImpl(invalidOverrideSetter, [p0, p1, p2, p3, p4]);
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstList({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(invalidTypeArgumentInConstList, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstMap({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(invalidTypeArgumentInConstMap, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstSet({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidTypeArgumentInConstSet, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUri({required String p0}) {
    return LocatableDiagnosticImpl(invalidUri, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvocationOfExtensionWithoutCall({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invocationOfExtensionWithoutCall, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvocationOfNonFunction({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invocationOfNonFunction, [p0]);
  }

  static LocatableDiagnostic _withArgumentsLabelInOuterScope({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(labelInOuterScope, [p0]);
  }

  static LocatableDiagnostic _withArgumentsLabelUndefined({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(labelUndefined, [p0]);
  }

  static LocatableDiagnostic _withArgumentsListElementTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(listElementTypeNotAssignable, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsListElementTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(listElementTypeNotAssignableNullability, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(mapKeyTypeNotAssignable, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(mapKeyTypeNotAssignableNullability, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMapValueTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(mapValueTypeNotAssignable, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsMapValueTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(mapValueTypeNotAssignableNullability, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingDartLibrary({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(missingDartLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingDefaultValueForParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingDefaultValueForParameter, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsMissingDefaultValueForParameterPositional({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingDefaultValueForParameterPositional, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingRequiredArgument, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingVariablePattern({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingVariablePattern, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationConcreteSuperInvokedMemberType({
    required String p0,
    required DartType p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(
      mixinApplicationConcreteSuperInvokedMemberType,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNoConcreteSuperInvokedMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      mixinApplicationNoConcreteSuperInvokedMember,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      mixinApplicationNoConcreteSuperInvokedSetter,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsMixinApplicationNotImplementedInterface({
    required DartType p0,
    required DartType p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(mixinApplicationNotImplementedInterface, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsMixinClassDeclarationExtendsNotObject({required String p0}) {
    return LocatableDiagnosticImpl(mixinClassDeclarationExtendsNotObject, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinClassDeclaresConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(mixinClassDeclaresConstructor, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinInheritsFromNotObject({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(mixinInheritsFromNotObject, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinOfDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(mixinOfDisallowedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinsSuperClass({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(mixinsSuperClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMixinSubtypeOfBaseIsNotBase({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(mixinSubtypeOfBaseIsNotBase, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsMixinSubtypeOfFinalIsNotBase({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(mixinSubtypeOfFinalIsNotBase, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsMixinSuperClassConstraintDisallowedClass({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(mixinSuperClassConstraintDisallowedClass, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNewWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(newWithNonType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNewWithUndefinedConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(newWithUndefinedConstructor, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsNewWithUndefinedConstructorDefault({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(newWithUndefinedConstructorDefault, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNoCombinedSuperSignature({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(noCombinedSuperSignature, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorExplicit({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(noDefaultSuperConstructorExplicit, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorImplicit({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(noDefaultSuperConstructorImplicit, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsNoGenerativeConstructorsInSuperclass({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(noGenerativeConstructorsInSuperclass, [
      p0,
      p1,
    ]);
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
      nonAbstractClassInheritsAbstractMemberFivePlus,
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
    return LocatableDiagnosticImpl(nonAbstractClassInheritsAbstractMemberFour, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberOne({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonAbstractClassInheritsAbstractMemberOne, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberThree({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(
      nonAbstractClassInheritsAbstractMemberThree,
      [p0, p1, p2],
    );
  }

  static LocatableDiagnostic
  _withArgumentsNonAbstractClassInheritsAbstractMemberTwo({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(nonAbstractClassInheritsAbstractMemberTwo, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNonBoolOperand({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonBoolOperand, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonExhaustiveSwitchExpression({
    required DartType p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(nonExhaustiveSwitchExpression, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsNonExhaustiveSwitchStatement({
    required DartType p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(nonExhaustiveSwitchStatement, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsNonGenerativeConstructor({
    required Element p0,
  }) {
    return LocatableDiagnosticImpl(nonGenerativeConstructor, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonGenerativeImplicitConstructor({
    required String p0,
    required String p1,
    required Element p2,
  }) {
    return LocatableDiagnosticImpl(nonGenerativeImplicitConstructor, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNonTypeAsTypeArgument({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonTypeAsTypeArgument, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonTypeInCatchClause({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonTypeInCatchClause, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      notAssignedPotentiallyNonNullableLocalVariable,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNotAType({required String p0}) {
    return LocatableDiagnosticImpl(notAType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNotBinaryOperator({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(notBinaryOperator, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsNotEnoughPositionalArgumentsNamePlural({
    required int p0,
    required int p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(notEnoughPositionalArgumentsNamePlural, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNotEnoughPositionalArgumentsNameSingular({required String p0}) {
    return LocatableDiagnosticImpl(notEnoughPositionalArgumentsNameSingular, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsPlural({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(notEnoughPositionalArgumentsPlural, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNotInitializedNonNullableInstanceField({required String p0}) {
    return LocatableDiagnosticImpl(notInitializedNonNullableInstanceField, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsNotInitializedNonNullableInstanceFieldConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      notInitializedNonNullableInstanceFieldConstructor,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsNotInitializedNonNullableVariable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(notInitializedNonNullableVariable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsOnRepeated({required String p0}) {
    return LocatableDiagnosticImpl(onRepeated, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPartOfDifferentLibrary({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(partOfDifferentLibrary, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsPartOfNonPart({required String p0}) {
    return LocatableDiagnosticImpl(partOfNonPart, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPartOfUnnamedLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(partOfUnnamedLibrary, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsPatternTypeMismatchInIrrefutableContext({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(patternTypeMismatchInIrrefutableContext, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      patternVariableSharedCaseScopeDifferentFinalityOrType,
      [p0],
    );
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeHasLabel({required String p0}) {
    return LocatableDiagnosticImpl(patternVariableSharedCaseScopeHasLabel, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsPatternVariableSharedCaseScopeNotAllCases({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(patternVariableSharedCaseScopeNotAllCases, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsPrefixCollidesWithTopLevelMember({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(prefixCollidesWithTopLevelMember, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPrefixIdentifierNotFollowedByDot({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(prefixIdentifierNotFollowedByDot, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPrefixShadowedByLocalDeclaration({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(prefixShadowedByLocalDeclaration, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPrivateCollisionInMixinApplication({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(privateCollisionInMixinApplication, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsPrivateSetter({required String p0}) {
    return LocatableDiagnosticImpl(privateSetter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsReadPotentiallyUnassignedFinal({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(readPotentiallyUnassignedFinal, [p0]);
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritance({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(recursiveInterfaceInheritance, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsRecursiveInterfaceInheritanceExtends({required String p0}) {
    return LocatableDiagnosticImpl(recursiveInterfaceInheritanceExtends, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsRecursiveInterfaceInheritanceImplements({required String p0}) {
    return LocatableDiagnosticImpl(recursiveInterfaceInheritanceImplements, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceOn({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(recursiveInterfaceInheritanceOn, [p0]);
  }

  static LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceWith({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(recursiveInterfaceInheritanceWith, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsRedirectGenerativeToMissingConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(redirectGenerativeToMissingConstructor, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsRedirectToAbstractClassConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(redirectToAbstractClassConstructor, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsRedirectToInvalidFunctionType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(redirectToInvalidFunctionType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsRedirectToInvalidReturnType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(redirectToInvalidReturnType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsRedirectToMissingConstructor({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(redirectToMissingConstructor, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsRedirectToNonClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(redirectToNonClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsReferencedBeforeDeclaration({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(referencedBeforeDeclaration, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsRelationalPatternOperandTypeNotAssignable({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(relationalPatternOperandTypeNotAssignable, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromClosure({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(returnOfInvalidTypeFromClosure, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromConstructor({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(returnOfInvalidTypeFromConstructor, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromFunction({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(returnOfInvalidTypeFromFunction, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromMethod({
    required DartType p0,
    required DartType p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(returnOfInvalidTypeFromMethod, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsSealedClassSubtypeOutsideOfLibrary({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(sealedClassSubtypeOutsideOfLibrary, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSetElementTypeNotAssignable({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(setElementTypeNotAssignable, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsSetElementTypeNotAssignableNullability({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(setElementTypeNotAssignableNullability, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsStaticAccessToInstanceMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(staticAccessToInstanceMember, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(subtypeOfBaseIsNotBaseFinalOrSealed, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(subtypeOfFinalIsNotBaseFinalOrSealed, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(
      superFormalParameterTypeIsNotSubtypeOfAssociated,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsSuperInvocationNotLast({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(superInvocationNotLast, [p0]);
  }

  static LocatableDiagnostic _withArgumentsThrowOfInvalidType({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(throwOfInvalidType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTopLevelCycle({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(topLevelCycle, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsTypeAnnotationDeferredClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(typeAnnotationDeferredClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTypeArgumentNotMatchingBounds({
    required DartType p0,
    required String p1,
    required DartType p2,
  }) {
    return LocatableDiagnosticImpl(typeArgumentNotMatchingBounds, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsTypeParameterSupertypeOfItsBound({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(typeParameterSupertypeOfItsBound, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsTypeTestWithNonType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(typeTestWithNonType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTypeTestWithUndefinedName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(typeTestWithUndefinedName, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedMethodInvocationOfNullableValue({required String p0}) {
    return LocatableDiagnosticImpl(uncheckedMethodInvocationOfNullableValue, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedOperatorInvocationOfNullableValue({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(uncheckedOperatorInvocationOfNullableValue, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsUncheckedPropertyAccessOfNullableValue({required String p0}) {
    return LocatableDiagnosticImpl(uncheckedPropertyAccessOfNullableValue, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedAnnotation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedAnnotation, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedClassBoolean({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedClassBoolean, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializer({
    required DartType p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedConstructorInInitializer, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsUndefinedConstructorInInitializerDefault({required Object p0}) {
    return LocatableDiagnosticImpl(undefinedConstructorInInitializerDefault, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedEnumConstant({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedEnumConstant, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedEnumConstructorNamed({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedEnumConstructorNamed, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionGetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedExtensionGetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionMethod({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedExtensionMethod, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionOperator({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedExtensionOperator, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedExtensionSetter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedExtensionSetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedFunction({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedFunction, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedGetter({
    required String p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(undefinedGetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedGetterOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedGetterOnFunctionType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedIdentifier({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedIdentifier, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedMethod({
    required String p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(undefinedMethod, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedMethodOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedMethodOnFunctionType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedNamedParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(undefinedNamedParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedOperator({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(undefinedOperator, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedPrefixedName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedPrefixedName, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSetterOnFunctionType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSetterOnFunctionType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperGetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSuperGetter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperMethod({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSuperMethod, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperOperator({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSuperOperator, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedSuperSetter({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(undefinedSuperSetter, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsUnqualifiedReferenceToNonLocalStaticMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unqualifiedReferenceToNonLocalStaticMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      unqualifiedReferenceToStaticMemberOfExtendedType,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUriDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(uriDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUriHasNotBeenGenerated({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(uriHasNotBeenGenerated, [p0]);
  }

  static LocatableDiagnostic _withArgumentsVariableTypeMismatch({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(variableTypeMismatch, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  }) {
    return LocatableDiagnosticImpl(
      wrongExplicitTypeParameterVarianceInSuperinterface,
      [p0, p1, p2, p3],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperator({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfParametersForOperator, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfParametersForOperatorMinus({required int p0}) {
    return LocatableDiagnosticImpl(wrongNumberOfParametersForOperatorMinus, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArguments({
    required Object p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArguments, [p0, p1, p2]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsAnonymousFunction({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(
      wrongNumberOfTypeArgumentsAnonymousFunction,
      [p0, p1],
    );
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArgumentsConstructor, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(
      wrongNumberOfTypeArgumentsDotShorthandConstructor,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsEnum({
    required int p0,
    required int p1,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArgumentsEnum, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsExtension({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArgumentsExtension, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsFunction({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArgumentsFunction, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsMethod({
    required DartType p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(wrongNumberOfTypeArgumentsMethod, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsWrongTypeParameterVarianceInSuperinterface({
    required String p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(wrongTypeParameterVarianceInSuperinterface, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsWrongTypeParameterVariancePosition({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(wrongTypeParameterVariancePosition, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsYieldEachOfInvalidType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(yieldEachOfInvalidType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsYieldOfInvalidType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(yieldOfInvalidType, [p0, p1]);
  }
}

final class CompileTimeErrorTemplate<T extends Function>
    extends CompileTimeErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorTemplate(
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

final class CompileTimeErrorWithoutArguments extends CompileTimeErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const CompileTimeErrorWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}

class StaticWarningCode extends DiagnosticCodeWithExpectedTypes {
  /// No parameters.
  static const StaticWarningWithoutArguments
  deadNullAwareExpression = StaticWarningWithoutArguments(
    'DEAD_NULL_AWARE_EXPRESSION',
    "The left operand can't be null, so the right operand is never executed.",
    correctionMessage: "Try removing the operator and the right operand.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments
  invalidNullAwareElement = StaticWarningWithoutArguments(
    'INVALID_NULL_AWARE_OPERATOR',
    "The element can't be null, so the null-aware operator '?' is unnecessary.",
    correctionMessage: "Try removing the operator '?'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_ELEMENT',
    expectedTypes: [],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments invalidNullAwareMapEntryKey =
      StaticWarningWithoutArguments(
        'INVALID_NULL_AWARE_OPERATOR',
        "The map entry key can't be null, so the null-aware operator '?' is "
            "unnecessary.",
        correctionMessage: "Try removing the operator '?'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_NULL_AWARE_MAP_ENTRY_KEY',
        expectedTypes: [],
      );

  /// No parameters.
  static const StaticWarningWithoutArguments invalidNullAwareMapEntryValue =
      StaticWarningWithoutArguments(
        'INVALID_NULL_AWARE_OPERATOR',
        "The map entry value can't be null, so the null-aware operator '?' is "
            "unnecessary.",
        correctionMessage: "Try removing the operator '?'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_NULL_AWARE_MAP_ENTRY_VALUE',
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
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be null, so the null-aware operator '{0}' is "
        "unnecessary.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
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
    'INVALID_NULL_AWARE_OPERATOR',
    "The receiver can't be 'null' because of short-circuiting, so the "
        "null-aware operator '{0}' can't be used.",
    correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
    withArguments: _withArgumentsInvalidNullAwareOperatorAfterShortCircuit,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the constant that is missing
  static const StaticWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingEnumConstantInSwitch = StaticWarningTemplate(
    'MISSING_ENUM_CONSTANT_IN_SWITCH',
    "Missing case clause for '{0}'.",
    correctionMessage:
        "Try adding a case clause for the missing constant, or adding a "
        "default clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingEnumConstantInSwitch,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const StaticWarningWithoutArguments unnecessaryNonNullAssertion =
      StaticWarningWithoutArguments(
        'UNNECESSARY_NON_NULL_ASSERTION',
        "The '!' will have no effect because the receiver can't be null.",
        correctionMessage: "Try removing the '!' operator.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const StaticWarningWithoutArguments unnecessaryNullAssertPattern =
      StaticWarningWithoutArguments(
        'UNNECESSARY_NULL_ASSERT_PATTERN',
        "The null-assert pattern will have no effect because the matched type "
            "isn't nullable.",
        correctionMessage:
            "Try replacing the null-assert pattern with its nested pattern.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const StaticWarningWithoutArguments
  unnecessaryNullCheckPattern = StaticWarningWithoutArguments(
    'UNNECESSARY_NULL_CHECK_PATTERN',
    "The null-check pattern will have no effect because the matched type isn't "
        "nullable.",
    correctionMessage:
        "Try replacing the null-check pattern with its nested pattern.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Initialize a newly created error code to have the given [name].
  const StaticWarningCode(
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
         uniqueName: 'StaticWarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;

  static LocatableDiagnostic _withArgumentsInvalidNullAwareOperator({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidNullAwareOperator, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidNullAwareOperatorAfterShortCircuit({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidNullAwareOperatorAfterShortCircuit, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingEnumConstantInSwitch({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingEnumConstantInSwitch, [p0]);
  }
}

final class StaticWarningTemplate<T extends Function>
    extends StaticWarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const StaticWarningTemplate(
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

final class StaticWarningWithoutArguments extends StaticWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const StaticWarningWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
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
    'ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
    "The argument type '{0}' can't be assigned to the parameter type '{1} "
        "Function(Object)' or '{1} Function(Object, StackTrace)'.",
    hasPublishedDocs: true,
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
    'ASSIGNMENT_OF_DO_NOT_STORE',
    "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or "
        "top-level variable.",
    correctionMessage: "Try removing the assignment.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAssignmentOfDoNotStore,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Type p0: the return type as derived by the type of the [Future].
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyCatchError = WarningTemplate(
    'BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR',
    "This 'onError' handler must return a value assignable to '{0}', but ends "
        "without returning a value.",
    correctionMessage: "Try adding a return statement.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsBodyMightCompleteNormallyCatchError,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// Type p0: the name of the declared return type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0})
  >
  bodyMightCompleteNormallyNullable = WarningTemplate(
    'BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
    "This function has a nullable return type of '{0}', but ends without "
        "returning a value.",
    correctionMessage:
        "Try adding a return statement, or if no value is ever returned, try "
        "changing the return type to 'void'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsBodyMightCompleteNormallyNullable,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the unassigned variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  castFromNullableAlwaysFails = WarningTemplate(
    'CAST_FROM_NULLABLE_ALWAYS_FAILS',
    "This cast will always throw an exception because the nullable local "
        "variable '{0}' is not assigned.",
    correctionMessage:
        "Try giving it an initializer expression, or ensure that it's assigned "
        "on every execution path.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsCastFromNullableAlwaysFails,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments castFromNullAlwaysFails =
      WarningWithoutArguments(
        'CAST_FROM_NULL_ALWAYS_FAILS',
        "This cast always throws an exception because the expression always "
            "evaluates to 'null'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the constant value type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  constantPatternNeverMatchesValueType = WarningTemplate(
    'CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE',
    "The matched value type '{0}' can never be equal to this constant of type "
        "'{1}'.",
    correctionMessage:
        "Try a constant of the same type as the matched value type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsConstantPatternNeverMatchesValueType,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Dead code is code that is never reached, this can happen for instance if a
  /// statement follows a return statement.
  ///
  /// No parameters.
  static const WarningWithoutArguments deadCode = WarningWithoutArguments(
    'DEAD_CODE',
    "Dead code.",
    correctionMessage:
        "Try removing the code, or fixing the code before it so that it can be "
        "reached.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Dead code is code that is never reached. This case covers cases where the
  /// user has catch clauses after `catch (e)` or `on Object catch (e)`.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  deadCodeCatchFollowingCatch = WarningWithoutArguments(
    'DEAD_CODE_CATCH_FOLLOWING_CATCH',
    "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
        "are never reached.",
    correctionMessage:
        "Try reordering the catch clauses so that they can be reached, or "
        "removing the unreachable catch clauses.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  deadCodeLateWildcardVariableInitializer = WarningWithoutArguments(
    'DEAD_CODE',
    "Dead code: The assigned-to wildcard variable is marked late and can never "
        "be referenced so this initializer will never be evaluated.",
    correctionMessage:
        "Try removing the code, removing the late modifier or changing the "
        "variable to a non-wildcard.",
    hasPublishedDocs: true,
    uniqueName: 'DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER',
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
    'DEAD_CODE_ON_CATCH_SUBTYPE',
    "Dead code: This on-catch block won't be executed because '{0}' is a "
        "subtype of '{1}' and hence will have been caught already.",
    correctionMessage:
        "Try reordering the catch clauses so that this block can be reached, "
        "or removing the unreachable catch clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeadCodeOnCatchSubtype,
    expectedTypes: [ExpectedType.type, ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the element
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedExportUse = WarningTemplate(
    'DEPRECATED_EXPORT_USE',
    "The ability to import '{0}' indirectly is deprecated.",
    correctionMessage: "Try importing '{0}' directly.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedExportUse,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedExtend = WarningTemplate(
    'DEPRECATED_EXTEND',
    "Extending '{0}' is deprecated.",
    correctionMessage: "Try removing the 'extends' clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedExtend,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedExtendsFunction =
      WarningWithoutArguments(
        'DEPRECATED_SUBTYPE_OF_FUNCTION',
        "Extending 'Function' is deprecated.",
        correctionMessage: "Try removing 'Function' from the 'extends' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_EXTENDS_FUNCTION',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedImplement = WarningTemplate(
    'DEPRECATED_IMPLEMENT',
    "Implementing '{0}' is deprecated.",
    correctionMessage: "Try removing '{0}' from the 'implements' clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedImplement,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedImplementsFunction =
      WarningWithoutArguments(
        'DEPRECATED_SUBTYPE_OF_FUNCTION',
        "Implementing 'Function' has no effect.",
        correctionMessage:
            "Try removing 'Function' from the 'implements' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_IMPLEMENTS_FUNCTION',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedInstantiate = WarningTemplate(
    'DEPRECATED_INSTANTIATE',
    "Instantiating '{0}' is deprecated.",
    correctionMessage: "Try instantiating a non-abstract class.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedInstantiate,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedMixin = WarningTemplate(
    'DEPRECATED_MIXIN',
    "Mixing in '{0}' is deprecated.",
    correctionMessage: "Try removing '{0}' from the 'with' clause.",
    withArguments: _withArgumentsDeprecatedMixin,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments deprecatedMixinFunction =
      WarningWithoutArguments(
        'DEPRECATED_SUBTYPE_OF_FUNCTION',
        "Mixing in 'Function' is deprecated.",
        correctionMessage: "Try removing 'Function' from the 'with' clause.",
        hasPublishedDocs: true,
        uniqueName: 'DEPRECATED_MIXIN_FUNCTION',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments deprecatedNewInCommentReference =
      WarningWithoutArguments(
        'DEPRECATED_NEW_IN_COMMENT_REFERENCE',
        "Using the 'new' keyword in a comment reference is deprecated.",
        correctionMessage: "Try referring to a constructor by its name.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object typeName: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object typeName})
  >
  deprecatedSubclass = WarningTemplate(
    'DEPRECATED_SUBCLASS',
    "Subclassing '{0}' is deprecated.",
    correctionMessage:
        "Try removing the 'extends' clause, or removing '{0}' from the "
        "'implements' clause.",
    hasPublishedDocs: true,
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
    'DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT',
    "The '{0}' argument must be formatted as {1}.",
    correctionMessage: "Try formatting '{0}' as {1}.",
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
    'DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS',
    "The '{0}' directive has '{1}' arguments, but only '{2}' are expected.",
    correctionMessage: "Try removing the extra arguments.",
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
    'DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT',
    "The '{0}' directive has an unexpected named argument, '{1}'.",
    correctionMessage: "Try removing the unexpected argument.",
    withArguments: _withArgumentsDocDirectiveHasUnexpectedNamedArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments docDirectiveMissingClosingBrace =
      WarningWithoutArguments(
        'DOC_DIRECTIVE_MISSING_CLOSING_BRACE',
        "Doc directive is missing a closing curly brace ('}').",
        correctionMessage: "Try closing the directive with a curly brace.",
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingClosingTag = WarningTemplate(
    'DOC_DIRECTIVE_MISSING_CLOSING_TAG',
    "Doc directive is missing a closing tag.",
    correctionMessage:
        "Try closing the directive with the appropriate closing tag, '{0}'.",
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
    'DOC_DIRECTIVE_MISSING_ARGUMENT',
    "The '{0}' directive is missing a '{1}' argument.",
    correctionMessage: "Try adding a '{1}' argument before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_ONE_ARGUMENT',
    withArguments: _withArgumentsDocDirectiveMissingOneArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the corresponding doc directive tag
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  docDirectiveMissingOpeningTag = WarningTemplate(
    'DOC_DIRECTIVE_MISSING_OPENING_TAG',
    "Doc directive is missing an opening tag.",
    correctionMessage:
        "Try opening the directive with the appropriate opening tag, '{0}'.",
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
    'DOC_DIRECTIVE_MISSING_ARGUMENT',
    "The '{0}' directive is missing a '{1}', a '{2}', and a '{3}' argument.",
    correctionMessage:
        "Try adding the missing arguments before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS',
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
    'DOC_DIRECTIVE_MISSING_ARGUMENT',
    "The '{0}' directive is missing a '{1}' and a '{2}' argument.",
    correctionMessage:
        "Try adding the missing arguments before the closing '}'.",
    uniqueName: 'DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS',
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
    'DOC_DIRECTIVE_UNKNOWN',
    "Doc directive '{0}' is unknown.",
    correctionMessage: "Try using one of the supported doc directives.",
    withArguments: _withArgumentsDocDirectiveUnknown,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotBeDeferred =
      WarningWithoutArguments(
        'DOC_IMPORT_CANNOT_BE_DEFERRED',
        "Doc imports can't be deferred.",
        correctionMessage: "Try removing the 'deferred' keyword.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHaveCombinators =
      WarningWithoutArguments(
        'DOC_IMPORT_CANNOT_HAVE_COMBINATORS',
        "Doc imports can't have show or hide combinators.",
        correctionMessage: "Try removing the combinator.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHaveConfigurations =
      WarningWithoutArguments(
        'DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS',
        "Doc imports can't have configurations.",
        correctionMessage: "Try removing the configurations.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments docImportCannotHavePrefix =
      WarningWithoutArguments(
        'DOC_IMPORT_CANNOT_HAVE_PREFIX',
        "Doc imports can't have prefixes.",
        correctionMessage: "Try removing the prefix.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Duplicate exports.
  ///
  /// No parameters.
  static const WarningWithoutArguments duplicateExport =
      WarningWithoutArguments(
        'DUPLICATE_EXPORT',
        "Duplicate export.",
        correctionMessage: "Try removing all but one export of the library.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments duplicateHiddenName =
      WarningWithoutArguments(
        'DUPLICATE_HIDDEN_NAME',
        "Duplicate hidden name.",
        correctionMessage:
            "Try removing the repeated name from the list of hidden members.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the diagnostic being ignored
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  duplicateIgnore = WarningTemplate(
    'DUPLICATE_IGNORE',
    "The diagnostic '{0}' doesn't need to be ignored here because it's already "
        "being ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDuplicateIgnore,
    expectedTypes: [ExpectedType.string],
  );

  /// Duplicate imports.
  ///
  /// No parameters.
  static const WarningWithoutArguments duplicateImport =
      WarningWithoutArguments(
        'DUPLICATE_IMPORT',
        "Duplicate import.",
        correctionMessage: "Try removing all but one import of the library.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments duplicateShownName =
      WarningWithoutArguments(
        'DUPLICATE_SHOWN_NAME',
        "Duplicate shown name.",
        correctionMessage:
            "Try removing the repeated name from the list of shown members.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments equalElementsInSet =
      WarningWithoutArguments(
        'EQUAL_ELEMENTS_IN_SET',
        "Two elements in a set literal shouldn't be equal.",
        correctionMessage: "Change or remove the duplicate element.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments equalKeysInMap = WarningWithoutArguments(
    'EQUAL_KEYS_IN_MAP',
    "Two keys in a map literal shouldn't be equal.",
    correctionMessage: "Change or remove the duplicate key.",
    hasPublishedDocs: true,
    expectedTypes: [],
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
    'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
    "The type argument(s) of '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
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
    'INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
    "The type argument(s) of the function '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
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
    'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
    "The return type of '{0}' can't be inferred.",
    correctionMessage: "Declare the return type of '{0}'.",
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
    'INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
    "The type argument(s) of the generic function type '{0}' can't be "
        "inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
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
    'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
    "The type argument(s) of the constructor '{0}' can't be inferred.",
    correctionMessage: "Use explicit type argument(s) for '{0}'.",
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
    'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
    "The type of {0} can't be inferred without either a type or initializer.",
    correctionMessage: "Try specifying the type of the variable.",
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
    'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
    "The type of {0} can't be inferred; a type must be explicitly provided.",
    correctionMessage: "Try specifying the type of the parameter.",
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
    'INVALID_ANNOTATION_TARGET',
    "The annotation '{0}' can only be used on {1}.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidAnnotationTarget,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidAwaitNotRequiredAnnotation =
      WarningWithoutArguments(
        'INVALID_AWAIT_NOT_REQUIRED_ANNOTATION',
        "The annotation 'awaitNotRequired' can only be applied to a "
            "Future-returning function, or a Future-typed field.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments invalidDeprecatedExtendAnnotation =
      WarningWithoutArguments(
        'INVALID_DEPRECATED_EXTEND_ANNOTATION',
        "The annotation '@Deprecated.extend' can only be applied to extendable "
            "classes.",
        correctionMessage: "Try removing the '@Deprecated.extend' annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments invalidDeprecatedImplementAnnotation =
      WarningWithoutArguments(
        'INVALID_DEPRECATED_IMPLEMENT_ANNOTATION',
        "The annotation '@Deprecated.implement' can only be applied to "
            "implementable classes.",
        correctionMessage:
            "Try removing the '@Deprecated.implement' annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedInstantiateAnnotation = WarningWithoutArguments(
    'INVALID_DEPRECATED_INSTANTIATE_ANNOTATION',
    "The annotation '@Deprecated.instantiate' can only be applied to classes.",
    correctionMessage: "Try removing the '@Deprecated.instantiate' annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// This warning is generated anywhere where `@Deprecated.mixin` annotates
  /// something other than a mixin class.
  ///
  /// No parameters.
  static const WarningWithoutArguments invalidDeprecatedMixinAnnotation =
      WarningWithoutArguments(
        'INVALID_DEPRECATED_MIXIN_ANNOTATION',
        "The annotation '@Deprecated.mixin' can only be applied to classes.",
        correctionMessage: "Try removing the '@Deprecated.mixin' annotation.",
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidDeprecatedSubclassAnnotation = WarningWithoutArguments(
    'INVALID_DEPRECATED_SUBCLASS_ANNOTATION',
    "The annotation '@Deprecated.subclass' can only be applied to subclassable "
        "classes and mixins.",
    correctionMessage: "Try removing the '@Deprecated.subclass' annotation.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the element
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidExportOfInternalElement = WarningTemplate(
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT',
    "The member '{0}' can't be exported as a part of a package's public API.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
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
    'INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
    "The member '{0}' can't be exported as a part of a package's public API, "
        "but is indirectly exported as part of the signature of '{1}'.",
    correctionMessage: "Try using a hide clause to hide '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidExportOfInternalElementIndirectly,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: The name of the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodDecl = WarningTemplate(
    'INVALID_FACTORY_METHOD_DECL',
    "Factory method '{0}' must have a return type.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidFactoryMethodDecl,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidFactoryMethodImpl = WarningTemplate(
    'INVALID_FACTORY_METHOD_IMPL',
    "Factory method '{0}' doesn't return a newly allocated object.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidFactoryMethodImpl,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidInternalAnnotation = WarningWithoutArguments(
    'INVALID_INTERNAL_ANNOTATION',
    "Only public elements in a package's private API can be annotated as being "
        "internal.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidLanguageVersionOverrideAtSign =
      WarningWithoutArguments(
        'INVALID_LANGUAGE_VERSION_OVERRIDE',
        "The Dart language version override number must begin with '@dart'.",
        correctionMessage:
            "Specify a Dart language version override with a comment like '// "
            "@dart = 2.0'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideEquals = WarningWithoutArguments(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with an '=' "
        "character.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the latest major version
  /// Object p1: the latest minor version
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidLanguageVersionOverrideGreater = WarningTemplate(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override can't specify a version greater than the "
        "latest known language version: {0}.{1}.",
    correctionMessage: "Try removing the language version override.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
    withArguments: _withArgumentsInvalidLanguageVersionOverrideGreater,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideLocation = WarningWithoutArguments(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The language version override must be specified before any declaration or "
        "directive.",
    correctionMessage:
        "Try moving the language version override to the top of the file.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidLanguageVersionOverrideLowerCase =
      WarningWithoutArguments(
        'INVALID_LANGUAGE_VERSION_OVERRIDE',
        "The Dart language version override comment must be specified with the "
            "word 'dart' in all lower case.",
        correctionMessage:
            "Specify a Dart language version override with a comment like '// "
            "@dart = 2.0'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments invalidLanguageVersionOverrideNumber =
      WarningWithoutArguments(
        'INVALID_LANGUAGE_VERSION_OVERRIDE',
        "The Dart language version override comment must be specified with a "
            "version number, like '2.0', after the '=' character.",
        correctionMessage:
            "Specify a Dart language version override with a comment like '// "
            "@dart = 2.0'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments invalidLanguageVersionOverridePrefix =
      WarningWithoutArguments(
        'INVALID_LANGUAGE_VERSION_OVERRIDE',
        "The Dart language version override number can't be prefixed with a "
            "letter.",
        correctionMessage:
            "Specify a Dart language version override with a comment like '// "
            "@dart = 2.0'.",
        hasPublishedDocs: true,
        uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideTrailingCharacters = WarningWithoutArguments(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment can't be followed by any "
        "non-whitespace characters.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidLanguageVersionOverrideTwoSlashes = WarningWithoutArguments(
    'INVALID_LANGUAGE_VERSION_OVERRIDE',
    "The Dart language version override comment must be specified with exactly "
        "two slashes.",
    correctionMessage:
        "Specify a Dart language version override with a comment like '// "
        "@dart = 2.0'.",
    hasPublishedDocs: true,
    uniqueName: 'INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidLiteralAnnotation =
      WarningWithoutArguments(
        'INVALID_LITERAL_ANNOTATION',
        "Only const constructors can have the `@literal` annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// This warning is generated anywhere where `@nonVirtual` annotates something
  /// other than a non-abstract instance member in a class or mixin.
  ///
  /// No parameters.
  static const WarningWithoutArguments
  invalidNonVirtualAnnotation = WarningWithoutArguments(
    'INVALID_NON_VIRTUAL_ANNOTATION',
    "The annotation '@nonVirtual' can only be applied to a concrete instance "
        "member.",
    correctionMessage: "Try removing '@nonVirtual'.",
    hasPublishedDocs: true,
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
    'INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
    "The member '{0}' is declared non-virtual in '{1}' and can't be overridden "
        "in subclasses.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidOverrideOfNonVirtualMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// This warning is generated anywhere where `@reopen` annotates a class which
  /// did not reopen any type.
  ///
  /// No parameters.
  static const WarningWithoutArguments invalidReopenAnnotation =
      WarningWithoutArguments(
        'INVALID_REOPEN_ANNOTATION',
        "The annotation '@reopen' can only be applied to a class that opens "
            "capabilities that the supertype intentionally disallows.",
        correctionMessage: "Try removing the '@reopen' annotation.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// This warning is generated anywhere where `@required` annotates a named
  /// parameter with a default value.
  ///
  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidRequiredNamedParam = WarningTemplate(
    'INVALID_REQUIRED_NAMED_PARAM',
    "The type parameter '{0}' is annotated with @required but only named "
        "parameters without a default value can be annotated with it.",
    correctionMessage: "Remove @required.",
    withArguments: _withArgumentsInvalidRequiredNamedParam,
    expectedTypes: [ExpectedType.string],
  );

  /// This warning is generated anywhere where `@required` annotates an optional
  /// positional parameter.
  ///
  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidRequiredOptionalPositionalParam = WarningTemplate(
    'INVALID_REQUIRED_OPTIONAL_POSITIONAL_PARAM',
    "Incorrect use of the annotation @required on the optional positional "
        "parameter '{0}'. Optional positional parameters cannot be required.",
    correctionMessage: "Remove @required.",
    withArguments: _withArgumentsInvalidRequiredOptionalPositionalParam,
    expectedTypes: [ExpectedType.string],
  );

  /// This warning is generated anywhere where `@required` annotates a
  /// non-optional positional parameter.
  ///
  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidRequiredPositionalParam = WarningTemplate(
    'INVALID_REQUIRED_POSITIONAL_PARAM',
    "Redundant use of the annotation @required on the required positional "
        "parameter '{0}'.",
    correctionMessage: "Remove @required.",
    withArguments: _withArgumentsInvalidRequiredPositionalParam,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfDoNotSubmitMember = WarningTemplate(
    'INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER',
    "Uses of '{0}' should not be submitted to source control.",
    correctionMessage: "Try removing the reference to '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidUseOfDoNotSubmitMember,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfInternalMember = WarningTemplate(
    'INVALID_USE_OF_INTERNAL_MEMBER',
    "The member '{0}' can only be used within its package.",
    hasPublishedDocs: true,
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
    'INVALID_USE_OF_PROTECTED_MEMBER',
    "The member '{0}' can only be used within instance members of subclasses "
        "of '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidUseOfProtectedMember,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidUseOfVisibleForOverridingMember = WarningTemplate(
    'INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
    "The member '{0}' can only be used for overriding.",
    hasPublishedDocs: true,
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
    'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
    "The member '{0}' can only be used within '{1}' or a template library.",
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
    'INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
    "The member '{0}' can only be used within '{1}' or a test.",
    hasPublishedDocs: true,
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
    'INVALID_VISIBILITY_ANNOTATION',
    "The member '{0}' is annotated with '{1}', but this annotation is only "
        "meaningful on declarations of public members.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidVisibilityAnnotation,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments invalidVisibleForOverridingAnnotation =
      WarningWithoutArguments(
        'INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
        "The annotation 'visibleForOverriding' can only be applied to a public "
            "instance member that can be overridden.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  invalidVisibleOutsideTemplateAnnotation = WarningWithoutArguments(
    'INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION',
    "The annotation 'visibleOutsideTemplate' can only be applied to a member "
        "of a class, enum, or mixin that is annotated with "
        "'visibleForTemplate'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  invalidWidgetPreviewApplication = WarningWithoutArguments(
    'INVALID_WIDGET_PREVIEW_APPLICATION',
    "The '@Preview(...)' annotation can only be applied to public, statically "
        "accessible constructors and functions.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the private symbol
  /// String p1: the name of the proposed public symbol equivalent
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  invalidWidgetPreviewPrivateArgument = WarningTemplate(
    'INVALID_WIDGET_PREVIEW_PRIVATE_ARGUMENT',
    "'@Preview(...)' can only accept arguments that consist of literals and "
        "public symbols.",
    correctionMessage: "Rename private symbol '{0}' to '{1}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidWidgetPreviewPrivateArgument,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingOverrideOfMustBeOverriddenOne = WarningTemplate(
    'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    "Missing concrete implementation of '{0}'.",
    correctionMessage: "Try overriding the missing member.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE',
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
    'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    "Missing concrete implementations of '{0}', '{1}', and {2} more.",
    correctionMessage: "Try overriding the missing members.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS',
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
    'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
    "Missing concrete implementations of '{0}' and '{1}'.",
    correctionMessage: "Try overriding the missing members.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO',
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
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required.",
    hasPublishedDocs: true,
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
    'MISSING_REQUIRED_PARAM',
    "The parameter '{0}' is required. {1}.",
    hasPublishedDocs: true,
    uniqueName: 'MISSING_REQUIRED_PARAM_WITH_DETAILS',
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
    'MIXIN_ON_SEALED_CLASS',
    "The class '{0}' shouldn't be used as a mixin constraint because it is "
        "sealed, and any class mixing in this mixin must have '{0}' as a "
        "superclass.",
    correctionMessage:
        "Try composing with this class, or refer to its documentation for more "
        "information.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMixinOnSealedClass,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments
  multipleCombinators = WarningWithoutArguments(
    'MULTIPLE_COMBINATORS',
    "Using multiple 'hide' or 'show' combinators is never necessary and often "
        "produces surprising results.",
    correctionMessage: "Try using a single combinator.",
    hasPublishedDocs: true,
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
    'MUST_BE_IMMUTABLE',
    "This class (or a class that this class inherits from) is marked as "
        "'@immutable', but one or more of its instance fields aren't final: "
        "{0}",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMustBeImmutable,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the class declaring the overridden method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  mustCallSuper = WarningTemplate(
    'MUST_CALL_SUPER',
    "This method overrides a method annotated as '@mustCallSuper' in '{0}', "
        "but doesn't invoke the overridden method.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMustCallSuper,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the argument
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  nonConstArgumentForConstParameter = WarningTemplate(
    'NON_CONST_ARGUMENT_FOR_CONST_PARAMETER',
    "Argument '{0}' must be a constant.",
    correctionMessage: "Try replacing the argument with a constant.",
    hasPublishedDocs: true,
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
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try adding a 'const' keyword.",
    hasPublishedDocs: true,
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
    'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
    "This instance creation must be 'const', because the {0} constructor is "
        "marked as '@literal'.",
    correctionMessage: "Try replacing the 'new' keyword with 'const'.",
    hasPublishedDocs: true,
    uniqueName: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
    withArguments: _withArgumentsNonConstCallToLiteralConstructorUsingNew,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments nonNullableEqualsParameter =
      WarningWithoutArguments(
        'NON_NULLABLE_EQUALS_PARAMETER',
        "The parameter type of '==' operators should be non-nullable.",
        correctionMessage: "Try using a non-nullable type.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  nullableTypeInCatchClause = WarningWithoutArguments(
    'NULLABLE_TYPE_IN_CATCH_CLAUSE',
    "A potentially nullable type can't be used in an 'on' clause because it "
        "isn't valid to throw a nullable expression.",
    correctionMessage: "Try using a non-nullable type.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the method being invoked
  /// String p1: the type argument associated with the method
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  nullArgumentToNonNullType = WarningTemplate(
    'NULL_ARGUMENT_TO_NON_NULL_TYPE',
    "'{0}' shouldn't be called with a 'null' argument for the non-nullable "
        "type argument '{1}'.",
    correctionMessage: "Try adding a non-null argument.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsNullArgumentToNonNullType,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments nullCheckAlwaysFails =
      WarningWithoutArguments(
        'NULL_CHECK_ALWAYS_FAILS',
        "This null-check will always throw an exception because the expression "
            "will always evaluate to 'null'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// A field with the override annotation does not override a getter or setter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingField =
      WarningWithoutArguments(
        'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        "The field doesn't override an inherited getter or setter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_FIELD',
        expectedTypes: [],
      );

  /// A getter with the override annotation does not override an existing getter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingGetter =
      WarningWithoutArguments(
        'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        "The getter doesn't override an inherited getter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_GETTER',
        expectedTypes: [],
      );

  /// A method with the override annotation does not override an existing method.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingMethod =
      WarningWithoutArguments(
        'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        "The method doesn't override an inherited method.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_METHOD',
        expectedTypes: [],
      );

  /// A setter with the override annotation does not override an existing setter.
  ///
  /// No parameters.
  static const WarningWithoutArguments overrideOnNonOverridingSetter =
      WarningWithoutArguments(
        'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
        "The setter doesn't override an inherited setter.",
        correctionMessage:
            "Try updating this class to match the superclass, or removing the "
            "override annotation.",
        hasPublishedDocs: true,
        uniqueName: 'OVERRIDE_ON_NON_OVERRIDING_SETTER',
        expectedTypes: [],
      );

  /// Parameters:
  /// Type p0: the matched value type
  /// Type p1: the required pattern type
  static const WarningTemplate<
    LocatableDiagnostic Function({required DartType p0, required DartType p1})
  >
  patternNeverMatchesValueType = WarningTemplate(
    'PATTERN_NEVER_MATCHES_VALUE_TYPE',
    "The matched value type '{0}' can never match the required type '{1}'.",
    correctionMessage: "Try using a different pattern.",
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
    'RECEIVER_OF_TYPE_NEVER',
    "The receiver is of type 'Never', and will never complete with a value.",
    correctionMessage:
        "Try checking for throw expressions or type errors in the receiver",
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
    'REDECLARE_ON_NON_REDECLARING_MEMBER',
    "The {0} doesn't redeclare a {0} declared in a superinterface.",
    correctionMessage:
        "Try updating this member to match a declaration in a superinterface, "
        "or removing the redeclare annotation.",
    hasPublishedDocs: true,
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
    'REMOVED_LINT_USE',
    "'{0}' was removed in Dart '{1}'",
    correctionMessage: "Remove the reference to '{0}'.",
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
    'REPLACED_LINT_USE',
    "'{0}' was replaced by '{2}' in Dart '{1}'.",
    correctionMessage: "Replace '{0}' with '{1}'.",
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
    'RETURN_OF_DO_NOT_STORE',
    "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless "
        "'{1}' is also annotated.",
    correctionMessage: "Annotate '{1}' with 'doNotStore'.",
    hasPublishedDocs: true,
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
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "A value of type '{0}' can't be returned by the 'onError' handler because "
        "it must be assignable to '{1}'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
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
    'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
    "The return type '{0}' isn't assignable to '{1}', as required by "
        "'Future.catchError'.",
    hasPublishedDocs: true,
    uniqueName: 'RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
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
    'SDK_VERSION_CONSTRUCTOR_TEAROFFS',
    "Tearing off a constructor requires the 'constructor-tearoffs' language "
        "feature.",
    correctionMessage:
        "Try updating your 'pubspec.yaml' to set the minimum SDK constraint to "
        "2.15 or higher, and running 'pub get'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  sdkVersionGtGtGtOperator = WarningWithoutArguments(
    'SDK_VERSION_GT_GT_GT_OPERATOR',
    "The operator '>>>' wasn't supported until version 2.14.0, but this code "
        "is required to be able to run on earlier versions.",
    correctionMessage: "Try updating the SDK constraints.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the version specified in the `@Since()` annotation
  /// String p1: the SDK version constraints
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  sdkVersionSince = WarningTemplate(
    'SDK_VERSION_SINCE',
    "This API is available since SDK {0}, but constraints '{1}' don't "
        "guarantee it.",
    correctionMessage: "Try updating the SDK constraints.",
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
    'STRICT_RAW_TYPE',
    "The generic type '{0}' should have explicit type arguments but doesn't.",
    correctionMessage: "Use explicit type arguments for '{0}'.",
    withArguments: _withArgumentsStrictRawType,
    expectedTypes: [ExpectedType.type],
  );

  /// Parameters:
  /// String p0: the name of the sealed class
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  subtypeOfSealedClass = WarningTemplate(
    'SUBTYPE_OF_SEALED_CLASS',
    "The class '{0}' shouldn't be extended, mixed in, or implemented because "
        "it's sealed.",
    correctionMessage:
        "Try composing instead of inheriting, or refer to the documentation of "
        "'{0}' for more information.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsSubtypeOfSealedClass,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInComment = WarningTemplate(
    'TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
    "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTextDirectionCodePointInComment,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the unicode sequence of the code point.
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  textDirectionCodePointInLiteral = WarningTemplate(
    'TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
    "The Unicode code point 'U+{0}' changes the appearance of text from how "
        "it's interpreted by the compiler.",
    correctionMessage:
        "Try removing the code point or using the Unicode escape sequence "
        "'\\u{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsTextDirectionCodePointInLiteral,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments typeCheckIsNotNull =
      WarningWithoutArguments(
        'TYPE_CHECK_WITH_NULL',
        "Tests for non-null should be done with '!= null'.",
        correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
        hasPublishedDocs: true,
        uniqueName: 'TYPE_CHECK_IS_NOT_NULL',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments typeCheckIsNull =
      WarningWithoutArguments(
        'TYPE_CHECK_WITH_NULL',
        "Tests for null should be done with '== null'.",
        correctionMessage: "Try replacing the 'is Null' check with '== null'.",
        hasPublishedDocs: true,
        uniqueName: 'TYPE_CHECK_IS_NULL',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the library being imported
  /// String p1: the name in the hide clause that isn't defined in the library
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  undefinedHiddenName = WarningTemplate(
    'UNDEFINED_HIDDEN_NAME',
    "The library '{0}' doesn't export a member with the hidden name '{1}'.",
    correctionMessage: "Try removing the name from the list of hidden members.",
    hasPublishedDocs: true,
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
    'UNDEFINED_REFERENCED_PARAMETER',
    "The parameter '{0}' isn't defined by '{1}'.",
    hasPublishedDocs: true,
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
    'UNDEFINED_SHOWN_NAME',
    "The library '{0}' doesn't export a member with the shown name '{1}'.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUndefinedShownName,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the non-diagnostic being ignored
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unignorableIgnore = WarningTemplate(
    'UNIGNORABLE_IGNORE',
    "The diagnostic '{0}' can't be ignored.",
    correctionMessage:
        "Try removing the name from the list, or removing the whole comment if "
        "this is the only name in the list.",
    withArguments: _withArgumentsUnignorableIgnore,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryCast =
      WarningWithoutArguments(
        'UNNECESSARY_CAST',
        "Unnecessary cast.",
        correctionMessage: "Try removing the cast.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryCastPattern =
      WarningWithoutArguments(
        'UNNECESSARY_CAST_PATTERN',
        "Unnecessary cast pattern.",
        correctionMessage: "Try removing the cast pattern.",
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryFinal = WarningWithoutArguments(
    'UNNECESSARY_FINAL',
    "The keyword 'final' isn't necessary because the parameter is implicitly "
        "'final'.",
    correctionMessage: "Try removing the 'final'.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryNanComparisonFalse = WarningWithoutArguments(
    'UNNECESSARY_NAN_COMPARISON',
    "A double can't equal 'double.nan', so the condition is always 'false'.",
    correctionMessage: "Try using 'double.isNan', or removing the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NAN_COMPARISON_FALSE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNanComparisonTrue =
      WarningWithoutArguments(
        'UNNECESSARY_NAN_COMPARISON',
        "A double can't equal 'double.nan', so the condition is always 'true'.",
        correctionMessage:
            "Try using 'double.isNan', or removing the condition.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NAN_COMPARISON_TRUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNoSuchMethod =
      WarningWithoutArguments(
        'UNNECESSARY_NO_SUCH_METHOD',
        "Unnecessary 'noSuchMethod' declaration.",
        correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments
  unnecessaryNullComparisonAlwaysNullFalse = WarningWithoutArguments(
    'UNNECESSARY_NULL_COMPARISON',
    "The operand must be 'null', so the condition is always 'false'.",
    correctionMessage: "Remove the condition.",
    hasPublishedDocs: true,
    uniqueName: 'UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_FALSE',
    expectedTypes: [],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonAlwaysNullTrue =
      WarningWithoutArguments(
        'UNNECESSARY_NULL_COMPARISON',
        "The operand must be 'null', so the condition is always 'true'.",
        correctionMessage: "Remove the condition.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_TRUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonNeverNullFalse =
      WarningWithoutArguments(
        'UNNECESSARY_NULL_COMPARISON',
        "The operand can't be 'null', so the condition is always 'false'.",
        correctionMessage:
            "Try removing the condition, an enclosing condition, or the whole "
            "conditional statement.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryNullComparisonNeverNullTrue =
      WarningWithoutArguments(
        'UNNECESSARY_NULL_COMPARISON',
        "The operand can't be 'null', so the condition is always 'true'.",
        correctionMessage: "Remove the condition.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the type
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryQuestionMark = WarningTemplate(
    'UNNECESSARY_QUESTION_MARK',
    "The '?' is unnecessary because '{0}' is nullable without it.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnnecessaryQuestionMark,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const WarningWithoutArguments unnecessarySetLiteral =
      WarningWithoutArguments(
        'UNNECESSARY_SET_LITERAL',
        "Braces unnecessarily wrap this expression in a set literal.",
        correctionMessage:
            "Try removing the set literal around the expression.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryTypeCheckFalse =
      WarningWithoutArguments(
        'UNNECESSARY_TYPE_CHECK',
        "Unnecessary type check; the result is always 'false'.",
        correctionMessage:
            "Try correcting the type check, or removing the type check.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_TYPE_CHECK_FALSE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryTypeCheckTrue =
      WarningWithoutArguments(
        'UNNECESSARY_TYPE_CHECK',
        "Unnecessary type check; the result is always 'true'.",
        correctionMessage:
            "Try correcting the type check, or removing the type check.",
        hasPublishedDocs: true,
        uniqueName: 'UNNECESSARY_TYPE_CHECK_TRUE',
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unnecessaryWildcardPattern =
      WarningWithoutArguments(
        'UNNECESSARY_WILDCARD_PATTERN',
        "Unnecessary wildcard pattern.",
        correctionMessage: "Try removing the wildcard pattern.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unreachableSwitchCase =
      WarningWithoutArguments(
        'UNREACHABLE_SWITCH_CASE',
        "This case is covered by the previous cases.",
        correctionMessage:
            "Try removing the case clause, or restructuring the preceding "
            "patterns.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const WarningWithoutArguments unreachableSwitchDefault =
      WarningWithoutArguments(
        'UNREACHABLE_SWITCH_DEFAULT',
        "This default clause is covered by the previous cases.",
        correctionMessage:
            "Try removing the default clause, or restructuring the preceding "
            "patterns.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the name of the exception variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchClause = WarningTemplate(
    'UNUSED_CATCH_CLAUSE',
    "The exception variable '{0}' isn't used, so the 'catch' clause can be "
        "removed.",
    correctionMessage: "Try removing the catch clause.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedCatchClause,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the stack trace variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedCatchStack = WarningTemplate(
    'UNUSED_CATCH_STACK',
    "The stack trace variable '{0}' isn't used and can be removed.",
    correctionMessage: "Try removing the stack trace variable, or using it.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedCatchStack,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name that is declared but not referenced
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElement = WarningTemplate(
    'UNUSED_ELEMENT',
    "The declaration '{0}' isn't referenced.",
    correctionMessage: "Try removing the declaration of '{0}'.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedElement,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the parameter that is declared but not used
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedElementParameter = WarningTemplate(
    'UNUSED_ELEMENT_PARAMETER',
    "A value for optional parameter '{0}' isn't ever given.",
    correctionMessage: "Try removing the unused parameter.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedElementParameter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the name of the unused field
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedField = WarningTemplate(
    'UNUSED_FIELD',
    "The value of the field '{0}' isn't used.",
    correctionMessage: "Try removing the field, or using it.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedField,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the content of the unused import's URI
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedImport = WarningTemplate(
    'UNUSED_IMPORT',
    "Unused import: '{0}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedImport,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the label that isn't used
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedLabel = WarningTemplate(
    'UNUSED_LABEL',
    "The label '{0}' isn't used.",
    correctionMessage:
        "Try removing the label, or using it in either a 'break' or 'continue' "
        "statement.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedLabel,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the name of the unused variable
  static const WarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unusedLocalVariable = WarningTemplate(
    'UNUSED_LOCAL_VARIABLE',
    "The value of the local variable '{0}' isn't used.",
    correctionMessage: "Try removing the variable or using it.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedLocalVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the annotated method, property or function
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedResult = WarningTemplate(
    'UNUSED_RESULT',
    "The value of '{0}' should be used.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
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
    'UNUSED_RESULT',
    "'{0}' should be used. {1}.",
    correctionMessage:
        "Try using the result by invoking a member, passing it to a function, "
        "or returning it from this function.",
    hasPublishedDocs: true,
    uniqueName: 'UNUSED_RESULT_WITH_MESSAGE',
    withArguments: _withArgumentsUnusedResultWithMessage,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name that is shown but not used
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unusedShownName = WarningTemplate(
    'UNUSED_SHOWN_NAME',
    "The name {0} is shown, but isn't used.",
    correctionMessage: "Try removing the name from the list of shown members.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnusedShownName,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the URI pointing to a nonexistent file
  static const WarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  uriDoesNotExistInDocImport = WarningTemplate(
    'URI_DOES_NOT_EXIST_IN_DOC_IMPORT',
    "Target of URI doesn't exist: '{0}'.",
    correctionMessage:
        "Try creating the file referenced by the URI, or try using a URI for a "
        "file that does exist.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUriDoesNotExistInDocImport,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const WarningCode(
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
         uniqueName: 'WarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;

  static LocatableDiagnostic
  _withArgumentsArgumentTypeNotAssignableToErrorHandler({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(argumentTypeNotAssignableToErrorHandler, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsAssignmentOfDoNotStore({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(assignmentOfDoNotStore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyCatchError({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(bodyMightCompleteNormallyCatchError, [p0]);
  }

  static LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyNullable({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(bodyMightCompleteNormallyNullable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsCastFromNullableAlwaysFails({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(castFromNullableAlwaysFails, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsConstantPatternNeverMatchesValueType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(constantPatternNeverMatchesValueType, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeadCodeOnCatchSubtype({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(deadCodeOnCatchSubtype, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedExportUse({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(deprecatedExportUse, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedExtend({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(deprecatedExtend, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedImplement({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(deprecatedImplement, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedInstantiate({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(deprecatedInstantiate, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedMixin({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(deprecatedMixin, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedSubclass({
    required Object typeName,
  }) {
    return LocatableDiagnosticImpl(deprecatedSubclass, [typeName]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveArgumentWrongFormat({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(docDirectiveArgumentWrongFormat, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveHasExtraArguments({
    required String p0,
    required int p1,
    required int p2,
  }) {
    return LocatableDiagnosticImpl(docDirectiveHasExtraArguments, [p0, p1, p2]);
  }

  static LocatableDiagnostic
  _withArgumentsDocDirectiveHasUnexpectedNamedArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(docDirectiveHasUnexpectedNamedArgument, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingClosingTag({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(docDirectiveMissingClosingTag, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingOneArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(docDirectiveMissingOneArgument, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingOpeningTag({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(docDirectiveMissingOpeningTag, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingThreeArguments({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  }) {
    return LocatableDiagnosticImpl(docDirectiveMissingThreeArguments, [
      p0,
      p1,
      p2,
      p3,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveMissingTwoArguments({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(docDirectiveMissingTwoArguments, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDocDirectiveUnknown({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(docDirectiveUnknown, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDuplicateIgnore({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(duplicateIgnore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnCollectionLiteral({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(inferenceFailureOnCollectionLiteral, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnFunctionInvocation({required String p0}) {
    return LocatableDiagnosticImpl(inferenceFailureOnFunctionInvocation, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnFunctionReturnType({required String p0}) {
    return LocatableDiagnosticImpl(inferenceFailureOnFunctionReturnType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnGenericInvocation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(inferenceFailureOnGenericInvocation, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnInstanceCreation({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(inferenceFailureOnInstanceCreation, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInferenceFailureOnUninitializedVariable({required String p0}) {
    return LocatableDiagnosticImpl(inferenceFailureOnUninitializedVariable, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInferenceFailureOnUntypedParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(inferenceFailureOnUntypedParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidAnnotationTarget({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidAnnotationTarget, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidExportOfInternalElement({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidExportOfInternalElement, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidExportOfInternalElementIndirectly({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidExportOfInternalElementIndirectly, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidFactoryMethodDecl({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidFactoryMethodDecl, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidFactoryMethodImpl({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidFactoryMethodImpl, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidLanguageVersionOverrideGreater({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(invalidLanguageVersionOverrideGreater, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidOverrideOfNonVirtualMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidOverrideOfNonVirtualMember, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidRequiredNamedParam({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidRequiredNamedParam, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidRequiredOptionalPositionalParam({required String p0}) {
    return LocatableDiagnosticImpl(invalidRequiredOptionalPositionalParam, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidRequiredPositionalParam({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidRequiredPositionalParam, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfDoNotSubmitMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidUseOfDoNotSubmitMember, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfInternalMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidUseOfInternalMember, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfProtectedMember({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidUseOfProtectedMember, [p0, p1]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidUseOfVisibleForOverridingMember({required String p0}) {
    return LocatableDiagnosticImpl(invalidUseOfVisibleForOverridingMember, [
      p0,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsInvalidUseOfVisibleForTemplateMember({
    required String p0,
    required Uri p1,
  }) {
    return LocatableDiagnosticImpl(invalidUseOfVisibleForTemplateMember, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTestingMember({
    required String p0,
    required Uri p1,
  }) {
    return LocatableDiagnosticImpl(invalidUseOfVisibleForTestingMember, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidVisibilityAnnotation({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidVisibilityAnnotation, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsInvalidWidgetPreviewPrivateArgument({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(invalidWidgetPreviewPrivateArgument, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenOne({required String p0}) {
    return LocatableDiagnosticImpl(missingOverrideOfMustBeOverriddenOne, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus({
    required String p0,
    required String p1,
    required String p2,
  }) {
    return LocatableDiagnosticImpl(missingOverrideOfMustBeOverriddenThreePlus, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic
  _withArgumentsMissingOverrideOfMustBeOverriddenTwo({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(missingOverrideOfMustBeOverriddenTwo, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredParam({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingRequiredParam, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingRequiredParamWithDetails({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(missingRequiredParamWithDetails, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsMixinOnSealedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(mixinOnSealedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMustBeImmutable({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(mustBeImmutable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMustCallSuper({required String p0}) {
    return LocatableDiagnosticImpl(mustCallSuper, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonConstArgumentForConstParameter({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonConstArgumentForConstParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructor({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(nonConstCallToLiteralConstructor, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsNonConstCallToLiteralConstructorUsingNew({required String p0}) {
    return LocatableDiagnosticImpl(nonConstCallToLiteralConstructorUsingNew, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsNullArgumentToNonNullType({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(nullArgumentToNonNullType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsPatternNeverMatchesValueType({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(patternNeverMatchesValueType, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsRedeclareOnNonRedeclaringMember({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(redeclareOnNonRedeclaringMember, [p0]);
  }

  static LocatableDiagnostic _withArgumentsRemovedLintUse({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(removedLintUse, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReplacedLintUse({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(replacedLintUse, [p0, p1, p2]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfDoNotStore({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(returnOfDoNotStore, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromCatchError({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(returnOfInvalidTypeFromCatchError, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsReturnTypeInvalidForCatchError({
    required DartType p0,
    required DartType p1,
  }) {
    return LocatableDiagnosticImpl(returnTypeInvalidForCatchError, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsSdkVersionSince({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(sdkVersionSince, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsStrictRawType({
    required DartType p0,
  }) {
    return LocatableDiagnosticImpl(strictRawType, [p0]);
  }

  static LocatableDiagnostic _withArgumentsSubtypeOfSealedClass({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(subtypeOfSealedClass, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTextDirectionCodePointInComment({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(textDirectionCodePointInComment, [p0]);
  }

  static LocatableDiagnostic _withArgumentsTextDirectionCodePointInLiteral({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(textDirectionCodePointInLiteral, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedHiddenName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedHiddenName, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedReferencedParameter({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedReferencedParameter, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedShownName({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(undefinedShownName, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUnignorableIgnore({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unignorableIgnore, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryQuestionMark({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unnecessaryQuestionMark, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedCatchClause({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unusedCatchClause, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedCatchStack({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unusedCatchStack, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedElement({required Object p0}) {
    return LocatableDiagnosticImpl(unusedElement, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedElementParameter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unusedElementParameter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedField({required Object p0}) {
    return LocatableDiagnosticImpl(unusedField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedImport({required String p0}) {
    return LocatableDiagnosticImpl(unusedImport, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedLabel({required String p0}) {
    return LocatableDiagnosticImpl(unusedLabel, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedLocalVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unusedLocalVariable, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedResult({required String p0}) {
    return LocatableDiagnosticImpl(unusedResult, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnusedResultWithMessage({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(unusedResultWithMessage, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUnusedShownName({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unusedShownName, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUriDoesNotExistInDocImport({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(uriDoesNotExistInDocImport, [p0]);
  }
}

final class WarningTemplate<T extends Function> extends WarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const WarningTemplate(
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

final class WarningWithoutArguments extends WarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const WarningWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
