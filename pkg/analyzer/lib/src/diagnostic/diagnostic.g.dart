// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/diagnostic/diagnostic.dart";

/// No parameters.
const DiagnosticWithoutArguments abiSpecificIntegerInvalid =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABI_SPECIFIC_INTEGER_INVALID',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one const "
          "constructor, no other members, and no type parameters.",
      correctionMessage:
          "Try removing all type parameters, removing all members, and adding "
          "one const constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.ABI_SPECIFIC_INTEGER_INVALID',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abiSpecificIntegerMappingExtra =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABI_SPECIFIC_INTEGER_MAPPING_EXTRA',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one "
          "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
          "ABI to a 'NativeType' integer with a fixed size.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_EXTRA',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abiSpecificIntegerMappingMissing =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABI_SPECIFIC_INTEGER_MAPPING_MISSING',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one "
          "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
          "ABI to a 'NativeType' integer with a fixed size.",
      correctionMessage: "Try adding an annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_MISSING',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the value of the invalid mapping
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
abiSpecificIntegerMappingUnsupported = DiagnosticWithArguments(
  name: 'ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED',
  problemMessage:
      "Invalid mapping to '{0}'; only mappings to 'Int8', 'Int16', 'Int32', "
      "'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.",
  correctionMessage:
      "Try changing the value to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', "
      "'Uint16', 'UInt32', or 'Uint64'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED',
  withArguments: _withArgumentsAbiSpecificIntegerMappingUnsupported,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments abstractClassMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_CLASS_MEMBER',
      problemMessage: "Members of classes can't be declared to be 'abstract'.",
      correctionMessage:
          "Try removing the 'abstract' keyword. You can add the 'abstract' "
          "keyword before the class declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_CLASS_MEMBER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractExternalField =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_EXTERNAL_FIELD',
      problemMessage:
          "Fields can't be declared both 'abstract' and 'external'.",
      correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_EXTERNAL_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
abstractFieldConstructorInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'ABSTRACT_FIELD_INITIALIZER',
  problemMessage: "Abstract fields can't have initializers.",
  correctionMessage:
      "Try removing the field initializer or the 'abstract' keyword from the "
      "field declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ABSTRACT_FIELD_CONSTRUCTOR_INITIALIZER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments abstractFieldInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_FIELD_INITIALIZER',
      problemMessage: "Abstract fields can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'abstract' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ABSTRACT_FIELD_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractFinalBaseClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_FINAL_BASE_CLASS',
      problemMessage:
          "An 'abstract' class can't be declared as both 'final' and 'base'.",
      correctionMessage: "Try removing either the 'final' or 'base' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_FINAL_BASE_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
abstractFinalInterfaceClass = DiagnosticWithoutArgumentsImpl(
  name: 'ABSTRACT_FINAL_INTERFACE_CLASS',
  problemMessage:
      "An 'abstract' class can't be declared as both 'final' and 'interface'.",
  correctionMessage: "Try removing either the 'final' or 'interface' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.ABSTRACT_FINAL_INTERFACE_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments abstractLateField =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_LATE_FIELD',
      problemMessage: "Abstract fields cannot be late.",
      correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_LATE_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractSealedClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_SEALED_CLASS',
      problemMessage:
          "A 'sealed' class can't be marked 'abstract' because it's already "
          "implicitly abstract.",
      correctionMessage: "Try removing the 'abstract' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_SEALED_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractStaticField =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_STATIC_FIELD',
      problemMessage: "Static fields can't be declared 'abstract'.",
      correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_STATIC_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractStaticMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'ABSTRACT_STATIC_METHOD',
      problemMessage: "Static methods can't be declared to be 'abstract'.",
      correctionMessage: "Try removing the keyword 'abstract'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ABSTRACT_STATIC_METHOD',
      expectedTypes: [],
    );

/// Parameters:
/// String memberKind: the display name for the kind of the found abstract
///                    member
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberKind,
    required String name,
  })
>
abstractSuperMemberReference = DiagnosticWithArguments(
  name: 'ABSTRACT_SUPER_MEMBER_REFERENCE',
  problemMessage: "The {0} '{1}' is always abstract in the supertype.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE',
  withArguments: _withArgumentsAbstractSuperMemberReference,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
addressPosition = DiagnosticWithoutArgumentsImpl(
  name: 'ADDRESS_POSITION',
  problemMessage:
      "The '.address' expression can only be used as argument to a leaf native "
      "external call.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.ADDRESS_POSITION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
addressReceiver = DiagnosticWithoutArgumentsImpl(
  name: 'ADDRESS_RECEIVER',
  problemMessage:
      "The receiver of '.address' must be a concrete 'TypedData', a concrete "
      "'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a "
      "Union field.",
  correctionMessage:
      "Change the receiver of '.address' to one of the allowed kinds.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.ADDRESS_RECEIVER',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the ambiguous element
/// Uri p1: the name of the first library in which the type is found
/// Uri p2: the name of the second library in which the type is found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required Uri p1,
    required Uri p2,
  })
>
ambiguousExport = DiagnosticWithArguments(
  name: 'AMBIGUOUS_EXPORT',
  problemMessage: "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
  correctionMessage:
      "Try removing the export of one of the libraries, or explicitly hiding "
      "the name in one of the export directives.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AMBIGUOUS_EXPORT',
  withArguments: _withArgumentsAmbiguousExport,
  expectedTypes: [ExpectedType.string, ExpectedType.uri, ExpectedType.uri],
);

/// Parameters:
/// String p0: the name of the member
/// String p1: the names of the declaring extensions
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
ambiguousExtensionMemberAccessThreeOrMore = DiagnosticWithArguments(
  name: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
  problemMessage:
      "A member named '{0}' is defined in {1}, and none are more specific.",
  correctionMessage:
      "Try using an extension override to specify the extension you want to "
      "be chosen.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_THREE_OR_MORE',
  withArguments: _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the member
/// Element p1: the name of the first declaring extension
/// Element p2: the names of the second declaring extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required Element p1,
    required Element p2,
  })
>
ambiguousExtensionMemberAccessTwo = DiagnosticWithArguments(
  name: 'AMBIGUOUS_EXTENSION_MEMBER_ACCESS',
  problemMessage:
      "A member named '{0}' is defined in '{1}' and '{2}', and neither is more "
      "specific.",
  correctionMessage:
      "Try using an extension override to specify the extension you want to "
      "be chosen.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AMBIGUOUS_EXTENSION_MEMBER_ACCESS_TWO',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
ambiguousImport = DiagnosticWithArguments(
  name: 'AMBIGUOUS_IMPORT',
  problemMessage: "The name '{0}' is defined in the libraries {1}.",
  correctionMessage:
      "Try using 'as prefix' for one of the import directives, or hiding the "
      "name from all but one of the imports.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AMBIGUOUS_IMPORT',
  withArguments: _withArgumentsAmbiguousImport,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
ambiguousSetOrMapLiteralBoth = DiagnosticWithoutArgumentsImpl(
  name: 'AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
  problemMessage:
      "The literal can't be either a map or a set because it contains at least "
      "one literal map entry or a spread operator spreading a 'Map', and at "
      "least one element which is neither of these.",
  correctionMessage:
      "Try removing or changing some of the elements so that all of the "
      "elements are consistent.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
ambiguousSetOrMapLiteralEither = DiagnosticWithoutArgumentsImpl(
  name: 'AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
  problemMessage:
      "This literal must be either a map or a set, but the elements don't have "
      "enough information for type inference to work.",
  correctionMessage:
      "Try adding type arguments to the literal (one for sets, two for "
      "maps).",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_EITHER',
  expectedTypes: [],
);

/// An error code indicating that the given option is deprecated.
///
/// Parameters:
/// Object p0: the option name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
analysisOptionDeprecated = DiagnosticWithArguments(
  name: 'ANALYSIS_OPTION_DEPRECATED',
  problemMessage: "The option '{0}' is no longer supported.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED',
  withArguments: _withArgumentsAnalysisOptionDeprecated,
  expectedTypes: [ExpectedType.object],
);

/// An error code indicating that the given option is deprecated.
///
/// Parameters:
/// Object p0: the option name
/// Object p1: the replacement option name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
analysisOptionDeprecatedWithReplacement = DiagnosticWithArguments(
  name: 'ANALYSIS_OPTION_DEPRECATED',
  problemMessage: "The option '{0}' is no longer supported.",
  correctionMessage: "Try using the new '{1}' option.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName:
      'AnalysisOptionsWarningCode.ANALYSIS_OPTION_DEPRECATED_WITH_REPLACEMENT',
  withArguments: _withArgumentsAnalysisOptionDeprecatedWithReplacement,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments annotationOnPointerField =
    DiagnosticWithoutArgumentsImpl(
      name: 'ANNOTATION_ON_POINTER_FIELD',
      problemMessage:
          "Fields in a struct class whose type is 'Pointer' shouldn't have any "
          "annotations.",
      correctionMessage: "Try removing the annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.ANNOTATION_ON_POINTER_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
annotationOnTypeArgument = DiagnosticWithoutArgumentsImpl(
  name: 'ANNOTATION_ON_TYPE_ARGUMENT',
  problemMessage:
      "Type arguments can't have annotations because they aren't declarations.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments annotationSpaceBeforeParenthesis =
    DiagnosticWithoutArgumentsImpl(
      name: 'ANNOTATION_SPACE_BEFORE_PARENTHESIS',
      problemMessage:
          "Annotations can't have spaces or comments before the parenthesis.",
      correctionMessage:
          "Remove any spaces or comments before the parenthesis.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ANNOTATION_SPACE_BEFORE_PARENTHESIS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments annotationWithTypeArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'ANNOTATION_WITH_TYPE_ARGUMENTS',
      problemMessage: "An annotation can't use type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
annotationWithTypeArgumentsUninstantiated = DiagnosticWithoutArgumentsImpl(
  name: 'ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
  problemMessage:
      "An annotation with type arguments must be followed by an argument list.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.ANNOTATION_WITH_TYPE_ARGUMENTS_UNINSTANTIATED',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
argumentMustBeAConstant = DiagnosticWithArguments(
  name: 'ARGUMENT_MUST_BE_A_CONSTANT',
  problemMessage: "Argument '{0}' must be a constant.",
  correctionMessage: "Try replacing the value with a literal or const.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.ARGUMENT_MUST_BE_A_CONSTANT',
  withArguments: _withArgumentsArgumentMustBeAConstant,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments argumentMustBeNative =
    DiagnosticWithoutArgumentsImpl(
      name: 'ARGUMENT_MUST_BE_NATIVE',
      problemMessage:
          "Argument to 'Native.addressOf' must be annotated with @Native",
      correctionMessage:
          "Try passing a static function or field annotated with '@Native'",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.ARGUMENT_MUST_BE_NATIVE',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the name of the actual argument type
/// Type p1: the name of the expected type
/// String p2: additional information, if any, when problem is associated with
///            records
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
argumentTypeNotAssignable = DiagnosticWithArguments(
  name: 'ARGUMENT_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The argument type '{0}' can't be assigned to the parameter type '{1}'. "
      "{2}",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsArgumentTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the actual argument type
/// Type p1: the name of the expected function return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
argumentTypeNotAssignableToErrorHandler = DiagnosticWithArguments(
  name: 'ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
  problemMessage:
      "The argument type '{0}' can't be assigned to the parameter type '{1} "
      "Function(Object)' or '{1} Function(Object, StackTrace)'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE_TO_ERROR_HANDLER',
  withArguments: _withArgumentsArgumentTypeNotAssignableToErrorHandler,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments assertInRedirectingConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSERT_IN_REDIRECTING_CONSTRUCTOR',
      problemMessage:
          "A redirecting constructor can't have an 'assert' initializer.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ASSERT_IN_REDIRECTING_CONSTRUCTOR',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the path to the asset directory as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
assetDirectoryDoesNotExist = DiagnosticWithArguments(
  name: 'ASSET_DIRECTORY_DOES_NOT_EXIST',
  problemMessage: "The asset directory '{0}' doesn't exist.",
  correctionMessage:
      "Try creating the directory or fixing the path to the directory.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST',
  withArguments: _withArgumentsAssetDirectoryDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the path to the asset as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
assetDoesNotExist = DiagnosticWithArguments(
  name: 'ASSET_DOES_NOT_EXIST',
  problemMessage: "The asset file '{0}' doesn't exist.",
  correctionMessage: "Try creating the file or fixing the path to the file.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.ASSET_DOES_NOT_EXIST',
  withArguments: _withArgumentsAssetDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
assetFieldNotList = DiagnosticWithoutArgumentsImpl(
  name: 'ASSET_FIELD_NOT_LIST',
  problemMessage:
      "The value of the 'assets' field is expected to be a list of relative file "
      "paths.",
  correctionMessage:
      "Try converting the value to be a list of relative file paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.ASSET_FIELD_NOT_LIST',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments assetMissingPath =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSET_MISSING_PATH',
      problemMessage: "Asset map entry must contain a 'path' field.",
      correctionMessage: "Try adding a 'path' field.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.ASSET_MISSING_PATH',
      expectedTypes: [],
    );

/// This code is deprecated in favor of the
/// 'ASSET_NOT_STRING_OR_MAP' code, and will be removed.
///
/// No parameters.
const DiagnosticWithoutArguments assetNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSET_NOT_STRING',
      problemMessage: "Assets are required to be file paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.ASSET_NOT_STRING',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assetNotStringOrMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSET_NOT_STRING_OR_MAP',
      problemMessage:
          "An asset value is required to be a file path (string) or map.",
      correctionMessage: "Try converting the value to be a string or map.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.ASSET_NOT_STRING_OR_MAP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assetPathNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSET_PATH_NOT_STRING',
      problemMessage: "Asset paths are required to be file paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.ASSET_PATH_NOT_STRING',
      expectedTypes: [],
    );

/// Users should not assign values marked `@doNotStore`.
///
/// Parameters:
/// String p0: the name of the field or variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
assignmentOfDoNotStore = DiagnosticWithArguments(
  name: 'ASSIGNMENT_OF_DO_NOT_STORE',
  problemMessage:
      "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or "
      "top-level variable.",
  correctionMessage: "Try removing the assignment.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.ASSIGNMENT_OF_DO_NOT_STORE',
  withArguments: _withArgumentsAssignmentOfDoNotStore,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
assignmentToConst = DiagnosticWithoutArgumentsImpl(
  name: 'ASSIGNMENT_TO_CONST',
  problemMessage:
      "Constant variables can't be assigned a value after initialization.",
  correctionMessage:
      "Try removing the assignment, or remove the modifier 'const' from the "
      "variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_CONST',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
assignmentToFinal = DiagnosticWithArguments(
  name: 'ASSIGNMENT_TO_FINAL',
  problemMessage: "'{0}' can't be used as a setter because it's final.",
  correctionMessage:
      "Try finding a different setter, or making '{0}' non-final.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL',
  withArguments: _withArgumentsAssignmentToFinal,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
assignmentToFinalLocal = DiagnosticWithArguments(
  name: 'ASSIGNMENT_TO_FINAL_LOCAL',
  problemMessage: "The final variable '{0}' can only be set once.",
  correctionMessage: "Try making '{0}' non-final.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_LOCAL',
  withArguments: _withArgumentsAssignmentToFinalLocal,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the reference
/// String p1: the name of the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
assignmentToFinalNoSetter = DiagnosticWithArguments(
  name: 'ASSIGNMENT_TO_FINAL_NO_SETTER',
  problemMessage: "There isn't a setter named '{0}' in class '{1}'.",
  correctionMessage:
      "Try correcting the name to reference an existing setter, or declare "
      "the setter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_FINAL_NO_SETTER',
  withArguments: _withArgumentsAssignmentToFinalNoSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments assignmentToFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSIGNMENT_TO_FUNCTION',
      problemMessage: "Functions can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_FUNCTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assignmentToMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSIGNMENT_TO_METHOD',
      problemMessage: "Methods can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_METHOD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assignmentToType =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASSIGNMENT_TO_TYPE',
      problemMessage: "Types can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ASSIGNMENT_TO_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments asyncForInWrongContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASYNC_FOR_IN_WRONG_CONTEXT',
      problemMessage:
          "The async for-in loop can only be used in an async function.",
      correctionMessage:
          "Try marking the function body with either 'async' or 'async*', or "
          "removing the 'await' before the for-in loop.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT',
      expectedTypes: [],
    );

/// 16.32 Identifier Reference: It is a compile-time error if any of the
/// identifiers async, await, or yield is used as an identifier in a function
/// body marked with either async, async, or sync.
///
/// No parameters.
const DiagnosticWithoutArguments asyncKeywordUsedAsIdentifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'ASYNC_KEYWORD_USED_AS_IDENTIFIER',
      problemMessage:
          "The keywords 'await' and 'yield' can't be used as identifiers in an "
          "asynchronous or generator function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentationExtendsClauseAlreadyPresent = DiagnosticWithoutArgumentsImpl(
  name: 'AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT',
  problemMessage:
      "The augmentation has an 'extends' clause, but an augmentation target "
      "already includes an 'extends' clause and it isn't allowed to be "
      "repeated or changed.",
  correctionMessage:
      "Try removing the 'extends' clause, either here or in the augmentation "
      "target.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.AUGMENTATION_EXTENDS_CLAUSE_ALREADY_PRESENT',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the lexeme of the modifier.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
augmentationModifierExtra = DiagnosticWithArguments(
  name: 'AUGMENTATION_MODIFIER_EXTRA',
  problemMessage:
      "The augmentation has the '{0}' modifier that the declaration doesn't "
      "have.",
  correctionMessage:
      "Try removing the '{0}' modifier, or adding it to the declaration.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTATION_MODIFIER_EXTRA',
  withArguments: _withArgumentsAugmentationModifierExtra,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the lexeme of the modifier.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
augmentationModifierMissing = DiagnosticWithArguments(
  name: 'AUGMENTATION_MODIFIER_MISSING',
  problemMessage:
      "The augmentation is missing the '{0}' modifier that the declaration has.",
  correctionMessage:
      "Try adding the '{0}' modifier, or removing it from the declaration.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTATION_MODIFIER_MISSING',
  withArguments: _withArgumentsAugmentationModifierMissing,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the declaration kind.
/// Object p1: the name of the augmentation kind.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
augmentationOfDifferentDeclarationKind = DiagnosticWithArguments(
  name: 'AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND',
  problemMessage: "Can't augment a {0} with a {1}.",
  correctionMessage:
      "Try changing the augmentation to match the declaration kind.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTATION_OF_DIFFERENT_DECLARATION_KIND',
  withArguments: _withArgumentsAugmentationOfDifferentDeclarationKind,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments augmentationTypeParameterBound =
    DiagnosticWithoutArgumentsImpl(
      name: 'AUGMENTATION_TYPE_PARAMETER_BOUND',
      problemMessage:
          "The augmentation type parameter must have the same bound as the "
          "corresponding type parameter of the declaration.",
      correctionMessage:
          "Try changing the augmentation to match the declaration type "
          "parameters.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_BOUND',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentationTypeParameterCount = DiagnosticWithoutArgumentsImpl(
  name: 'AUGMENTATION_TYPE_PARAMETER_COUNT',
  problemMessage:
      "The augmentation must have the same number of type parameters as the "
      "declaration.",
  correctionMessage:
      "Try changing the augmentation to match the declaration type "
      "parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_COUNT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments augmentationTypeParameterName =
    DiagnosticWithoutArgumentsImpl(
      name: 'AUGMENTATION_TYPE_PARAMETER_NAME',
      problemMessage:
          "The augmentation type parameter must have the same name as the "
          "corresponding type parameter of the declaration.",
      correctionMessage:
          "Try changing the augmentation to match the declaration type "
          "parameters.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.AUGMENTATION_TYPE_PARAMETER_NAME',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments augmentationWithoutDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'AUGMENTATION_WITHOUT_DECLARATION',
      problemMessage: "The declaration being augmented doesn't exist.",
      correctionMessage:
          "Try changing the augmentation to match an existing declaration.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.AUGMENTATION_WITHOUT_DECLARATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentedExpressionIsNotSetter = DiagnosticWithoutArgumentsImpl(
  name: 'AUGMENTED_EXPRESSION_IS_NOT_SETTER',
  problemMessage:
      "The augmented declaration is not a setter, it can't be used to write a "
      "value.",
  correctionMessage: "Try assigning a value to a setter.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_NOT_SETTER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
augmentedExpressionIsSetter = DiagnosticWithoutArgumentsImpl(
  name: 'AUGMENTED_EXPRESSION_IS_SETTER',
  problemMessage:
      "The augmented declaration is a setter, it can't be used to read a value.",
  correctionMessage: "Try assigning a value to the augmented setter.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_IS_SETTER',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the lexeme of the operator.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
augmentedExpressionNotOperator = DiagnosticWithArguments(
  name: 'AUGMENTED_EXPRESSION_NOT_OPERATOR',
  problemMessage:
      "The enclosing augmentation doesn't augment the operator '{0}'.",
  correctionMessage: "Try augmenting or invoking the correct operator.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AUGMENTED_EXPRESSION_NOT_OPERATOR',
  withArguments: _withArgumentsAugmentedExpressionNotOperator,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments awaitInLateLocalVariableInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
      problemMessage:
          "The 'await' expression can't be used in a 'late' local variable's "
          "initializer.",
      correctionMessage:
          "Try removing the 'late' modifier, or rewriting the initializer "
          "without using the 'await' expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.AWAIT_IN_LATE_LOCAL_VARIABLE_INITIALIZER',
      expectedTypes: [],
    );

/// 16.30 Await Expressions: It is a compile-time error if the function
/// immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
/// await expression.)
///
/// No parameters.
const DiagnosticWithoutArguments awaitInWrongContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'AWAIT_IN_WRONG_CONTEXT',
      problemMessage:
          "The await expression can only be used in an async function.",
      correctionMessage:
          "Try marking the function body with either 'async' or 'async*'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
awaitOfIncompatibleType = DiagnosticWithoutArgumentsImpl(
  name: 'AWAIT_OF_INCOMPATIBLE_TYPE',
  problemMessage:
      "The 'await' expression can't be used for an expression with an extension "
      "type that is not a subtype of 'Future'.",
  correctionMessage:
      "Try removing the `await`, or updating the extension type to implement "
      "'Future'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.AWAIT_OF_INCOMPATIBLE_TYPE',
  expectedTypes: [],
);

/// Parameters:
/// String implementedClassName: the name of the base class being implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String implementedClassName})
>
baseClassImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be implemented outside of its library because it's "
      "a base class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments baseEnum = DiagnosticWithoutArgumentsImpl(
  name: 'BASE_ENUM',
  problemMessage: "Enums can't be declared to be 'base'.",
  correctionMessage: "Try removing the keyword 'base'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.BASE_ENUM',
  expectedTypes: [],
);

/// Parameters:
/// String implementedMixinName: the name of the base mixin being implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String implementedMixinName})
>
baseMixinImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The mixin '{0}' can't be implemented outside of its library because it's "
      "a base mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
binaryOperatorWrittenOut = DiagnosticWithArguments(
  name: 'BINARY_OPERATOR_WRITTEN_OUT',
  problemMessage:
      "Binary operator '{0}' is written as '{1}' instead of the written out "
      "word.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.BINARY_OPERATOR_WRITTEN_OUT',
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
bodyMightCompleteNormally = DiagnosticWithArguments(
  name: 'BODY_MIGHT_COMPLETE_NORMALLY',
  problemMessage:
      "The body might complete normally, causing 'null' to be returned, but the "
      "return type, '{0}', is a potentially non-nullable type.",
  correctionMessage:
      "Try adding either a return or a throw statement at the end.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BODY_MIGHT_COMPLETE_NORMALLY',
  withArguments: _withArgumentsBodyMightCompleteNormally,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type p0: the return type as derived by the type of the [Future].
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
bodyMightCompleteNormallyCatchError = DiagnosticWithArguments(
  name: 'BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR',
  problemMessage:
      "This 'onError' handler must return a value assignable to '{0}', but ends "
      "without returning a value.",
  correctionMessage: "Try adding a return statement.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_CATCH_ERROR',
  withArguments: _withArgumentsBodyMightCompleteNormallyCatchError,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type p0: the name of the declared return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
bodyMightCompleteNormallyNullable = DiagnosticWithArguments(
  name: 'BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
  problemMessage:
      "This function has a nullable return type of '{0}', but ends without "
      "returning a value.",
  correctionMessage:
      "Try adding a return statement, or if no value is ever returned, try "
      "changing the return type to 'void'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.BODY_MIGHT_COMPLETE_NORMALLY_NULLABLE',
  withArguments: _withArgumentsBodyMightCompleteNormallyNullable,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments breakLabelOnSwitchMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'BREAK_LABEL_ON_SWITCH_MEMBER',
      problemMessage:
          "A break label resolves to the 'case' or 'default' statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
breakOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
  name: 'BREAK_OUTSIDE_OF_LOOP',
  problemMessage:
      "A break statement can't be used outside of a loop or switch statement.",
  correctionMessage: "Try removing the break statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.BREAK_OUTSIDE_OF_LOOP',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsExtensionName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage:
      "The built-in identifier '{0}' can't be used as an extension name.",
  correctionMessage: "Try choosing a different name for the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsExtensionName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsExtensionTypeName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage:
      "The built-in identifier '{0}' can't be used as an extension type name.",
  correctionMessage: "Try choosing a different name for the extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_TYPE_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsExtensionTypeName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsPrefixName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a prefix name.",
  correctionMessage: "Try choosing a different name for the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsPrefixName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsType = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_AS_TYPE',
  problemMessage: "The built-in identifier '{0}' can't be used as a type.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE',
  withArguments: _withArgumentsBuiltInIdentifierAsType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsTypedefName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a typedef name.",
  correctionMessage: "Try choosing a different name for the typedef.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsTypedefName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsTypeName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage: "The built-in identifier '{0}' can't be used as a type name.",
  correctionMessage: "Try choosing a different name for the type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsTypeName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
builtInIdentifierAsTypeParameterName = DiagnosticWithArguments(
  name: 'BUILT_IN_IDENTIFIER_IN_DECLARATION',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a type parameter name.",
  correctionMessage: "Try choosing a different name for the type parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME',
  withArguments: _withArgumentsBuiltInIdentifierAsTypeParameterName,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that the camera permissions is not supported on Chrome
/// OS.
///
/// No parameters.
const DiagnosticWithoutArguments
cameraPermissionsIncompatible = DiagnosticWithoutArgumentsImpl(
  name: 'CAMERA_PERMISSIONS_INCOMPATIBLE',
  problemMessage:
      "Camera permissions make app incompatible for Chrome OS, consider adding "
      "optional features \"android.hardware.camera\" and "
      "\"android.hardware.camera.autofocus\".",
  correctionMessage:
      "Try adding `<uses-feature android:name=\"android.hardware.camera\"  "
      "android:required=\"false\">` `<uses-feature "
      "android:name=\"android.hardware.camera.autofocus\"  "
      "android:required=\"false\">`.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.CAMERA_PERMISSIONS_INCOMPATIBLE',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the this of the switch case expression
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
caseExpressionTypeImplementsEquals = DiagnosticWithArguments(
  name: 'CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
  problemMessage:
      "The switch case expression type '{0}' can't override the '==' operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS',
  withArguments: _withArgumentsCaseExpressionTypeImplementsEquals,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type p0: the type of the case expression
/// Type p1: the type of the switch expression
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
caseExpressionTypeIsNotSwitchExpressionSubtype = DiagnosticWithArguments(
  name: 'CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
  problemMessage:
      "The switch case expression type '{0}' must be a subtype of the switch "
      "expression type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IS_NOT_SWITCH_EXPRESSION_SUBTYPE',
  withArguments: _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the unassigned variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
castFromNullableAlwaysFails = DiagnosticWithArguments(
  name: 'CAST_FROM_NULLABLE_ALWAYS_FAILS',
  problemMessage:
      "This cast will always throw an exception because the nullable local "
      "variable '{0}' is not assigned.",
  correctionMessage:
      "Try giving it an initializer expression, or ensure that it's assigned "
      "on every execution path.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.CAST_FROM_NULLABLE_ALWAYS_FAILS',
  withArguments: _withArgumentsCastFromNullableAlwaysFails,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments castFromNullAlwaysFails =
    DiagnosticWithoutArgumentsImpl(
      name: 'CAST_FROM_NULL_ALWAYS_FAILS',
      problemMessage:
          "This cast always throws an exception because the expression always "
          "evaluates to 'null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.CAST_FROM_NULL_ALWAYS_FAILS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
castToNonType = DiagnosticWithArguments(
  name: 'CAST_TO_NON_TYPE',
  problemMessage:
      "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
  correctionMessage:
      "Try changing the name to the name of an existing type, or creating a "
      "type with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CAST_TO_NON_TYPE',
  withArguments: _withArgumentsCastToNonType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments catchSyntax = DiagnosticWithoutArgumentsImpl(
  name: 'CATCH_SYNTAX',
  problemMessage:
      "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
  correctionMessage:
      "No types are needed, the first is given by 'on', the second is always "
      "'StackTrace'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CATCH_SYNTAX',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
catchSyntaxExtraParameters = DiagnosticWithoutArgumentsImpl(
  name: 'CATCH_SYNTAX_EXTRA_PARAMETERS',
  problemMessage:
      "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
  correctionMessage:
      "No types are needed, the first is given by 'on', the second is always "
      "'StackTrace'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CATCH_SYNTAX_EXTRA_PARAMETERS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments classInClass = DiagnosticWithoutArgumentsImpl(
  name: 'CLASS_IN_CLASS',
  problemMessage: "Classes can't be declared inside other classes.",
  correctionMessage: "Try moving the class to the top-level.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CLASS_IN_CLASS',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
classInstantiationAccessToInstanceMember = DiagnosticWithArguments(
  name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
  problemMessage:
      "The instance member '{0}' can't be accessed on a class instantiation.",
  correctionMessage:
      "Try changing the member name to the name of a constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_INSTANCE_MEMBER',
  withArguments: _withArgumentsClassInstantiationAccessToInstanceMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
classInstantiationAccessToStaticMember = DiagnosticWithArguments(
  name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
  problemMessage:
      "The static member '{0}' can't be accessed on a class instantiation.",
  correctionMessage:
      "Try removing the type arguments from the class name, or changing the "
      "member name to the name of a constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_STATIC_MEMBER',
  withArguments: _withArgumentsClassInstantiationAccessToStaticMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the class
/// String p1: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
classInstantiationAccessToUnknownMember = DiagnosticWithArguments(
  name: 'CLASS_INSTANTIATION_ACCESS_TO_MEMBER',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try invoking a different constructor, or defining a constructor named "
      "'{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CLASS_INSTANTIATION_ACCESS_TO_UNKNOWN_MEMBER',
  withArguments: _withArgumentsClassInstantiationAccessToUnknownMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the class being used as a mixin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
classUsedAsMixin = DiagnosticWithArguments(
  name: 'CLASS_USED_AS_MIXIN',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it's neither a mixin "
      "class nor a mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CLASS_USED_AS_MIXIN',
  withArguments: _withArgumentsClassUsedAsMixin,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments colonInPlaceOfIn =
    DiagnosticWithoutArgumentsImpl(
      name: 'COLON_IN_PLACE_OF_IN',
      problemMessage: "For-in loops use 'in' rather than a colon.",
      correctionMessage: "Try replacing the colon with the keyword 'in'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.COLON_IN_PLACE_OF_IN',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the struct or union class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
compoundImplementsFinalizable = DiagnosticWithArguments(
  name: 'COMPOUND_IMPLEMENTS_FINALIZABLE',
  problemMessage: "The class '{0}' can't implement Finalizable.",
  correctionMessage: "Try removing the implements clause from '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.COMPOUND_IMPLEMENTS_FINALIZABLE',
  withArguments: _withArgumentsCompoundImplementsFinalizable,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments concreteClassHasEnumSuperinterface =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
      problemMessage: "Concrete classes can't have 'Enum' as a superinterface.",
      correctionMessage:
          "Try specifying a different interface, or remove it from the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONCRETE_CLASS_HAS_ENUM_SUPERINTERFACE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the abstract method
/// String p1: the name of the enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
concreteClassWithAbstractMember = DiagnosticWithArguments(
  name: 'CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
  problemMessage: "'{0}' must have a method body because '{1}' isn't abstract.",
  correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER',
  withArguments: _withArgumentsConcreteClassWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor and field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingConstructorAndStaticField = DiagnosticWithArguments(
  name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static field in this "
      "class.",
  correctionMessage: "Try renaming either the constructor or the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_FIELD',
  withArguments: _withArgumentsConflictingConstructorAndStaticField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor and getter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingConstructorAndStaticGetter = DiagnosticWithArguments(
  name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static getter in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the getter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_GETTER',
  withArguments: _withArgumentsConflictingConstructorAndStaticGetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingConstructorAndStaticMethod = DiagnosticWithArguments(
  name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static method in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the method.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_METHOD',
  withArguments: _withArgumentsConflictingConstructorAndStaticMethod,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor and setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingConstructorAndStaticSetter = DiagnosticWithArguments(
  name: 'CONFLICTING_CONSTRUCTOR_AND_STATIC_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static setter in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the setter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_AND_STATIC_SETTER',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
conflictingFieldAndMethod = DiagnosticWithArguments(
  name: 'CONFLICTING_FIELD_AND_METHOD',
  problemMessage:
      "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the "
      "same name.",
  correctionMessage:
      "Try converting the getter to a method, or renaming the field to a "
      "name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_FIELD_AND_METHOD',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  })
>
conflictingGenericInterfaces = DiagnosticWithArguments(
  name: 'CONFLICTING_GENERIC_INTERFACES',
  problemMessage:
      "The {0} '{1}' can't implement both '{2}' and '{3}' because the type "
      "arguments are different.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
conflictingInheritedMethodAndSetter = DiagnosticWithArguments(
  name: 'CONFLICTING_INHERITED_METHOD_AND_SETTER',
  problemMessage:
      "The {0} '{1}' can't inherit both a method and a setter named '{2}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_INHERITED_METHOD_AND_SETTER',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
conflictingMethodAndField = DiagnosticWithArguments(
  name: 'CONFLICTING_METHOD_AND_FIELD',
  problemMessage:
      "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the "
      "same name.",
  correctionMessage:
      "Try converting the method to a getter, or renaming the method to a "
      "name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_METHOD_AND_FIELD',
  withArguments: _withArgumentsConflictingMethodAndField,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
conflictingModifiers = DiagnosticWithArguments(
  name: 'CONFLICTING_MODIFIERS',
  problemMessage: "Members can't be declared to be both '{0}' and '{1}'.",
  correctionMessage: "Try removing one of the keywords.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONFLICTING_MODIFIERS',
  withArguments: _withArgumentsConflictingModifiers,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
conflictingStaticAndInstance = DiagnosticWithArguments(
  name: 'CONFLICTING_STATIC_AND_INSTANCE',
  problemMessage:
      "Class '{0}' can't define static member '{1}' and have instance member "
      "'{2}.{1}' with the same name.",
  correctionMessage: "Try renaming the member to a name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_STATIC_AND_INSTANCE',
  withArguments: _withArgumentsConflictingStaticAndInstance,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndClass = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the class in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS',
  withArguments: _withArgumentsConflictingTypeVariableAndClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndEnum = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the enum in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the enum.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_ENUM',
  withArguments: _withArgumentsConflictingTypeVariableAndEnum,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndExtension = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the extension in "
      "which the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION',
  withArguments: _withArgumentsConflictingTypeVariableAndExtension,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndExtensionType = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the extension type "
      "in which the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_EXTENSION_TYPE',
  withArguments: _withArgumentsConflictingTypeVariableAndExtensionType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMemberClass = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "class.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_CLASS',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMemberEnum = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "enum.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_ENUM',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberEnum,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMemberExtension = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "extension.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberExtension,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMemberExtensionType = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "extension type.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_EXTENSION_TYPE',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberExtensionType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMemberMixin = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_MEMBER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "mixin.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER_MIXIN',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberMixin,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
conflictingTypeVariableAndMixin = DiagnosticWithArguments(
  name: 'CONFLICTING_TYPE_VARIABLE_AND_CONTAINER',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the mixin in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MIXIN',
  withArguments: _withArgumentsConflictingTypeVariableAndMixin,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constAndFinal = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_AND_FINAL',
  problemMessage: "Members can't be declared to be both 'const' and 'final'.",
  correctionMessage: "Try removing either the 'const' or 'final' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONST_AND_FINAL',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the matched value type
/// Type p1: the constant value type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
constantPatternNeverMatchesValueType = DiagnosticWithArguments(
  name: 'CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE',
  problemMessage:
      "The matched value type '{0}' can never be equal to this constant of type "
      "'{1}'.",
  correctionMessage:
      "Try a constant of the same type as the matched value type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.CONSTANT_PATTERN_NEVER_MATCHES_VALUE_TYPE',
  withArguments: _withArgumentsConstantPatternNeverMatchesValueType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constantPatternWithNonConstantExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION',
      problemMessage:
          "The expression of a constant pattern must be a valid constant.",
      correctionMessage: "Try making the expression a valid constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.CONSTANT_PATTERN_WITH_NON_CONSTANT_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constClass = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_CLASS',
  problemMessage: "Classes can't be declared to be 'const'.",
  correctionMessage:
      "Try removing the 'const' keyword. If you're trying to indicate that "
      "instances of the class can be constants, place the 'const' keyword on "
      " the class' constructor(s).",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONST_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
constConstructorConstantFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' constructor.",
  correctionMessage:
      "Try removing the keyword 'const' from the constructor or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.CONST_CONSTRUCTOR_CONSTANT_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// Parameters:
/// Object valueType: the type of the runtime value of the argument
/// Object fieldName: the name of the field
/// Object fieldType: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object valueType,
    required Object fieldName,
    required Object fieldType,
  })
>
constConstructorFieldTypeMismatch = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
  problemMessage:
      "In a const constructor, a value of type '{0}' can't be assigned to the "
      "field '{1}', which has type '{2}'.",
  correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH',
  withArguments: _withArgumentsConstConstructorFieldTypeMismatch,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// Parameters:
/// String valueType: the type of the runtime value of the argument
/// String parameterType: the static type of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String valueType,
    required String parameterType,
  })
>
constConstructorParamTypeMismatch = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
  problemMessage:
      "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a "
      "const constructor.",
  correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH',
  withArguments: _withArgumentsConstConstructorParamTypeMismatch,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constConstructorThrowsException =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_CONSTRUCTOR_THROWS_EXCEPTION',
      problemMessage: "Const constructors can't throw exceptions.",
      correctionMessage:
          "Try removing the throw statement, or removing the keyword 'const'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constConstructorWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_CONSTRUCTOR_WITH_BODY',
      problemMessage: "Const constructors can't have a body.",
      correctionMessage: "Try removing either the 'const' keyword or the body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.CONST_CONSTRUCTOR_WITH_BODY',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constConstructorWithFieldInitializedByNonConst = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST',
  problemMessage:
      "Can't define the 'const' constructor because the field '{0}' is "
      "initialized with a non-constant value.",
  correctionMessage:
      "Try initializing the field to a constant value, or removing the "
      "keyword 'const' from the constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constConstructorWithMixinWithField = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
  problemMessage:
      "This constructor can't be declared 'const' because a mixin adds the "
      "instance field: {0}.",
  correctionMessage:
      "Try removing the 'const' keyword or removing the 'with' clause from "
      "the class declaration, or removing the field from the mixin class.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constConstructorWithMixinWithFields = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD',
  problemMessage:
      "This constructor can't be declared 'const' because the mixins add the "
      "instance fields: {0}.",
  correctionMessage:
      "Try removing the 'const' keyword or removing the 'with' clause from "
      "the class declaration, or removing the fields from the mixin classes.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELDS',
  withArguments: _withArgumentsConstConstructorWithMixinWithFields,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constConstructorWithNonConstSuper = DiagnosticWithArguments(
  name: 'CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
  problemMessage:
      "A constant constructor can't call a non-constant super constructor of "
      "'{0}'.",
  correctionMessage:
      "Try calling a constant constructor in the superclass, or removing the "
      "keyword 'const' from the constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER',
  withArguments: _withArgumentsConstConstructorWithNonConstSuper,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constConstructorWithNonFinalField =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
      problemMessage:
          "Can't define a const constructor for a class with non-final fields.",
      correctionMessage:
          "Try making all of the fields final, or removing the keyword 'const' "
          "from the constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
constDeferredClass = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_DEFERRED_CLASS',
  problemMessage: "Deferred classes can't be created with 'const'.",
  correctionMessage:
      "Try using 'new' to create the instance, or changing the import to not "
      "be deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_DEFERRED_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalAssertionFailure =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_ASSERTION_FAILURE',
      problemMessage: "The assertion in this constant expression failed.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_ASSERTION_FAILURE',
      expectedTypes: [],
    );

/// Parameters:
/// Object message: the message of the assertion
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object message})
>
constEvalAssertionFailureWithMessage = DiagnosticWithArguments(
  name: 'CONST_EVAL_ASSERTION_FAILURE_WITH_MESSAGE',
  problemMessage: "An assertion failed with message '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_ASSERTION_FAILURE_WITH_MESSAGE',
  withArguments: _withArgumentsConstEvalAssertionFailureWithMessage,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalExtensionMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_EXTENSION_METHOD',
      problemMessage:
          "Extension methods can't be used in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_EXTENSION_METHOD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalExtensionTypeMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_EXTENSION_TYPE_METHOD',
      problemMessage:
          "Extension type methods can't be used in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_EXTENSION_TYPE_METHOD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalForElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_FOR_ELEMENT',
      problemMessage: "Constant expressions don't support 'for' elements.",
      correctionMessage:
          "Try replacing the 'for' element with a spread, or removing 'const'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_FOR_ELEMENT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalMethodInvocation =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_METHOD_INVOCATION',
      problemMessage: "Methods can't be invoked in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_METHOD_INVOCATION',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 == e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalPrimitiveEquality = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_EVAL_PRIMITIVE_EQUALITY',
  problemMessage:
      "In constant expressions, operands of the equality operator must have "
      "primitive equality.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_PRIMITIVE_EQUALITY',
  expectedTypes: [],
);

/// Parameters:
/// String propertyName: the name of the property being accessed
/// String type: the type with the property being accessed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String propertyName,
    required String type,
  })
>
constEvalPropertyAccess = DiagnosticWithArguments(
  name: 'CONST_EVAL_PROPERTY_ACCESS',
  problemMessage:
      "The property '{0}' can't be accessed on the type '{1}' in a constant "
      "expression.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_PROPERTY_ACCESS',
  withArguments: _withArgumentsConstEvalPropertyAccess,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constEvalThrowsException =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_THROWS_EXCEPTION',
      problemMessage:
          "Evaluation of this constant expression throws an exception.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION',
      expectedTypes: [],
    );

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constEvalThrowsIdbze =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_THROWS_IDBZE',
      problemMessage:
          "Evaluation of this constant expression throws an "
          "IntegerDivisionByZeroException.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form !e1", "An expression of the form
/// e1 && e2", and "An expression of the form e1 || e2".
///
/// No parameters.
const DiagnosticWithoutArguments constEvalTypeBool =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_TYPE_BOOL',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'bool'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 & e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeBoolInt = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_EVAL_TYPE_BOOL_INT',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'bool' "
      "or 'int'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "A literal string".
///
/// No parameters.
const DiagnosticWithoutArguments constEvalTypeBoolNumString =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_TYPE_BOOL_NUM_STRING',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'bool', 'num', 'String' or 'null'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form ~e1", "An expression of one of
/// the forms e1 >> e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeInt = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_EVAL_TYPE_INT',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'int'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_INT',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 - e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeNum = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_EVAL_TYPE_NUM',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'num'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_NUM',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 + e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeNumString = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_EVAL_TYPE_NUM_STRING',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'num' "
      "or 'String'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_NUM_STRING',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalTypeString =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_TYPE_STRING',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'String'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_STRING',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalTypeType =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_EVAL_TYPE_TYPE',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'Type'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_EVAL_TYPE_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constFactory = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_FACTORY',
  problemMessage:
      "Only redirecting factory constructors can be declared to be 'const'.",
  correctionMessage:
      "Try removing the 'const' keyword, or replacing the body with '=' "
      "followed by a valid target.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONST_FACTORY',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the name of the type of the initializer expression
/// Type p1: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
constFieldInitializerNotAssignable = DiagnosticWithArguments(
  name: 'FIELD_INITIALIZER_NOT_ASSIGNABLE',
  problemMessage:
      "The initializer type '{0}' can't be assigned to the field type '{1}' in a "
      "const constructor.",
  correctionMessage: "Try using a subtype, or removing the 'const' keyword",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE',
  withArguments: _withArgumentsConstFieldInitializerNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
constInitializedWithNonConstantValue = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
  problemMessage: "Const variables must be initialized with a constant value.",
  correctionMessage:
      "Try changing the initializer to be a constant expression.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
constInitializedWithNonConstantValueFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
      problemMessage:
          "Constant values from a deferred library can't be used to initialize a "
          "'const' variable.",
      correctionMessage:
          "Try initializing the variable without referencing members of the "
          "deferred library, or changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_INSTANCE_FIELD',
      problemMessage: "Only static fields can be declared as const.",
      correctionMessage:
          "Try declaring the field as final, or adding the keyword 'static'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_INSTANCE_FIELD',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the type of the entry's key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
constMapKeyNotPrimitiveEquality = DiagnosticWithArguments(
  name: 'CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY',
  problemMessage:
      "The type of a key in a constant map can't override the '==' operator, or "
      "'hashCode', but the class '{0}' does.",
  correctionMessage:
      "Try using a different value for the key, or removing the keyword "
      "'const' from the map.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_MAP_KEY_NOT_PRIMITIVE_EQUALITY',
  withArguments: _withArgumentsConstMapKeyNotPrimitiveEquality,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constMethod = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_METHOD',
  problemMessage:
      "Getters, setters and methods can't be declared to be 'const'.",
  correctionMessage: "Try removing the 'const' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONST_METHOD',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constNotInitialized = DiagnosticWithArguments(
  name: 'CONST_NOT_INITIALIZED',
  problemMessage: "The constant '{0}' must be initialized.",
  correctionMessage: "Try adding an initialization to the declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_NOT_INITIALIZED',
  withArguments: _withArgumentsConstNotInitialized,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constructorWithReturnType =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONSTRUCTOR_WITH_RETURN_TYPE',
      problemMessage: "Constructors can't have a return type.",
      correctionMessage: "Try removing the return type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.CONSTRUCTOR_WITH_RETURN_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
constructorWithTypeArguments = DiagnosticWithoutArgumentsImpl(
  name: 'CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
  problemMessage:
      "A constructor invocation can't have type arguments after the constructor "
      "name.",
  correctionMessage:
      "Try removing the type arguments or placing them after the class name.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONSTRUCTOR_WITH_TYPE_ARGUMENTS',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the type of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
constSetElementNotPrimitiveEquality = DiagnosticWithArguments(
  name: 'CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY',
  problemMessage:
      "An element in a constant set can't override the '==' operator, or "
      "'hashCode', but the type '{0}' does.",
  correctionMessage:
      "Try using a different value for the element, or removing the keyword "
      "'const' from the set.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_SET_ELEMENT_NOT_PRIMITIVE_EQUALITY',
  withArguments: _withArgumentsConstSetElementNotPrimitiveEquality,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constSpreadExpectedListOrSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_SPREAD_EXPECTED_LIST_OR_SET',
      problemMessage: "A list or a set is expected in this spread.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_SPREAD_EXPECTED_LIST_OR_SET',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constSpreadExpectedMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_SPREAD_EXPECTED_MAP',
      problemMessage: "A map is expected in this spread.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_SPREAD_EXPECTED_MAP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_TYPE_PARAMETER',
      problemMessage: "Type parameters can't be used in a constant expression.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_TYPE_PARAMETER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithNonConst =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_WITH_NON_CONST',
      problemMessage: "The constructor being called isn't a const constructor.",
      correctionMessage:
          "Try removing 'const' from the constructor invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_WITH_NON_CONST',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithNonConstantArgument =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_WITH_NON_CONSTANT_ARGUMENT',
      problemMessage:
          "Arguments of a constant creation must be constant expressions.",
      correctionMessage:
          "Try making the argument a valid constant, or use 'new' to call the "
          "constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constWithNonType = DiagnosticWithArguments(
  name: 'CREATION_WITH_NON_TYPE',
  problemMessage: "The name '{0}' isn't a class.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_WITH_NON_TYPE',
  withArguments: _withArgumentsConstWithNonType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
constWithoutPrimaryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'CONST_WITHOUT_PRIMARY_CONSTRUCTOR',
  problemMessage:
      "'const' can only be used together with a primary constructor declaration.",
  correctionMessage:
      "Try removing the 'const' keyword or adding a primary constructor "
      "declaration.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONST_WITHOUT_PRIMARY_CONSTRUCTOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_WITH_TYPE_PARAMETERS',
      problemMessage:
          "A constant creation can't use a type parameter as a type argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParametersConstructorTearoff =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_WITH_TYPE_PARAMETERS',
      problemMessage:
          "A constant constructor tearoff can't use a type parameter as a type "
          "argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_CONSTRUCTOR_TEAROFF',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParametersFunctionTearoff =
    DiagnosticWithoutArgumentsImpl(
      name: 'CONST_WITH_TYPE_PARAMETERS',
      problemMessage:
          "A constant function tearoff can't use a type parameter as a type "
          "argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS_FUNCTION_TEAROFF',
      expectedTypes: [],
    );

/// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
/// a constant constructor declared by the type <i>T</i>.
///
/// Parameters:
/// Object p0: the name of the type
/// String p1: the name of the requested constant constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required String p1})
>
constWithUndefinedConstructor = DiagnosticWithArguments(
  name: 'CONST_WITH_UNDEFINED_CONSTRUCTOR',
  problemMessage: "The class '{0}' doesn't have a constant constructor '{1}'.",
  correctionMessage: "Try calling a different constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR',
  withArguments: _withArgumentsConstWithUndefinedConstructor,
  expectedTypes: [ExpectedType.object, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
/// a constant constructor declared by the type <i>T</i>.
///
/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
constWithUndefinedConstructorDefault = DiagnosticWithArguments(
  name: 'CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
  problemMessage:
      "The class '{0}' doesn't have an unnamed constant constructor.",
  correctionMessage: "Try calling a different constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
  withArguments: _withArgumentsConstWithUndefinedConstructorDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
continueLabelInvalid = DiagnosticWithoutArgumentsImpl(
  name: 'CONTINUE_LABEL_INVALID',
  problemMessage:
      "The label used in a 'continue' statement must be defined on either a loop "
      "or a switch member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.CONTINUE_LABEL_INVALID',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
continueOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
  name: 'CONTINUE_OUTSIDE_OF_LOOP',
  problemMessage:
      "A continue statement can't be used outside of a loop or switch statement.",
  correctionMessage: "Try removing the continue statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
continueWithoutLabelInCase = DiagnosticWithoutArgumentsImpl(
  name: 'CONTINUE_WITHOUT_LABEL_IN_CASE',
  problemMessage:
      "A continue statement in a switch statement must have a label as a target.",
  correctionMessage:
      "Try adding a label associated with one of the case clauses to the "
      "continue statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.CONTINUE_WITHOUT_LABEL_IN_CASE',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the type parameter
/// String p1: detail text explaining why the type could not be inferred
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
couldNotInfer = DiagnosticWithArguments(
  name: 'COULD_NOT_INFER',
  problemMessage: "Couldn't infer type parameter '{0}'.{1}",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.COULD_NOT_INFER',
  withArguments: _withArgumentsCouldNotInfer,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments covariantAndStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'COVARIANT_AND_STATIC',
      problemMessage:
          "Members can't be declared to be both 'covariant' and 'static'.",
      correctionMessage:
          "Try removing either the 'covariant' or 'static' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.COVARIANT_AND_STATIC',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments covariantConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'COVARIANT_CONSTRUCTOR',
      problemMessage: "A constructor can't be declared to be 'covariant'.",
      correctionMessage: "Try removing the keyword 'covariant'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.COVARIANT_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments covariantMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'COVARIANT_MEMBER',
      problemMessage:
          "Getters, setters and methods can't be declared to be 'covariant'.",
      correctionMessage: "Try removing the 'covariant' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.COVARIANT_MEMBER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
creationOfStructOrUnion = DiagnosticWithoutArgumentsImpl(
  name: 'CREATION_OF_STRUCT_OR_UNION',
  problemMessage:
      "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't "
      "be instantiated by a generative constructor.",
  correctionMessage:
      "Try allocating it via allocation, or load from a 'Pointer'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.CREATION_OF_STRUCT_OR_UNION',
  expectedTypes: [],
);

/// Dead code is code that is never reached, this can happen for instance if a
/// statement follows a return statement.
///
/// No parameters.
const DiagnosticWithoutArguments deadCode = DiagnosticWithoutArgumentsImpl(
  name: 'DEAD_CODE',
  problemMessage: "Dead code.",
  correctionMessage:
      "Try removing the code, or fixing the code before it so that it can be "
      "reached.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEAD_CODE',
  expectedTypes: [],
);

/// Dead code is code that is never reached. This case covers cases where the
/// user has catch clauses after `catch (e)` or `on Object catch (e)`.
///
/// No parameters.
const DiagnosticWithoutArguments
deadCodeCatchFollowingCatch = DiagnosticWithoutArgumentsImpl(
  name: 'DEAD_CODE_CATCH_FOLLOWING_CATCH',
  problemMessage:
      "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
      "are never reached.",
  correctionMessage:
      "Try reordering the catch clauses so that they can be reached, or "
      "removing the unreachable catch clauses.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEAD_CODE_CATCH_FOLLOWING_CATCH',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
deadCodeLateWildcardVariableInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'DEAD_CODE',
  problemMessage:
      "Dead code: The assigned-to wildcard variable is marked late and can never "
      "be referenced so this initializer will never be evaluated.",
  correctionMessage:
      "Try removing the code, removing the late modifier or changing the "
      "variable to a non-wildcard.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEAD_CODE_LATE_WILDCARD_VARIABLE_INITIALIZER',
  expectedTypes: [],
);

/// Dead code is code that is never reached. This case covers cases where the
/// user has an on-catch clause such as `on A catch (e)`, where a supertype of
/// `A` was already caught.
///
/// Parameters:
/// Type p0: name of the subtype
/// Type p1: name of the supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
deadCodeOnCatchSubtype = DiagnosticWithArguments(
  name: 'DEAD_CODE_ON_CATCH_SUBTYPE',
  problemMessage:
      "Dead code: This on-catch block won't be executed because '{0}' is a "
      "subtype of '{1}' and hence will have been caught already.",
  correctionMessage:
      "Try reordering the catch clauses so that this block can be reached, "
      "or removing the unreachable catch clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEAD_CODE_ON_CATCH_SUBTYPE',
  withArguments: _withArgumentsDeadCodeOnCatchSubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
deadNullAwareExpression = DiagnosticWithoutArgumentsImpl(
  name: 'DEAD_NULL_AWARE_EXPRESSION',
  problemMessage:
      "The left operand can't be null, so the right operand is never executed.",
  correctionMessage: "Try removing the operator and the right operand.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.DEAD_NULL_AWARE_EXPRESSION',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments defaultInSwitchExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEFAULT_IN_SWITCH_EXPRESSION',
      problemMessage: "A switch expression may not use the `default` keyword.",
      correctionMessage: "Try replacing `default` with `_`.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DEFAULT_IN_SWITCH_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments defaultValueInFunctionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEFAULT_VALUE_IN_FUNCTION_TYPE',
      problemMessage:
          "Parameters in a function type can't have default values.",
      correctionMessage: "Try removing the default value.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
defaultValueInRedirectingFactoryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
  problemMessage:
      "Default values aren't allowed in factory constructors that redirect to "
      "another constructor.",
  correctionMessage: "Try removing the default value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments defaultValueOnRequiredParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
      problemMessage: "Required named parameters can't have a default value.",
      correctionMessage:
          "Try removing either the default value or the 'required' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.DEFAULT_VALUE_ON_REQUIRED_PARAMETER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
deferredAfterPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'DEFERRED_AFTER_PREFIX',
  problemMessage:
      "The deferred keyword should come immediately before the prefix ('as' "
      "clause).",
  correctionMessage: "Try moving the deferred keyword before the prefix.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.DEFERRED_AFTER_PREFIX',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments deferredImportOfExtension =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEFERRED_IMPORT_OF_EXTENSION',
      problemMessage: "Imports of deferred libraries must hide all extensions.",
      correctionMessage:
          "Try adding either a show combinator listing the names you need to "
          "reference or a hide combinator listing all of the extensions.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.DEFERRED_IMPORT_OF_EXTENSION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
definitelyUnassignedLateLocalVariable = DiagnosticWithArguments(
  name: 'DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
  problemMessage:
      "The late local variable '{0}' is definitely unassigned at this point.",
  correctionMessage: "Ensure that it is assigned on necessary execution paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE',
  withArguments: _withArgumentsDefinitelyUnassignedLateLocalVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
dependenciesFieldNotMap = DiagnosticWithArguments(
  name: 'DEPENDENCIES_FIELD_NOT_MAP',
  problemMessage: "The value of the '{0}' field is expected to be a map.",
  correctionMessage: "Try converting the value to be a map.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP',
  withArguments: _withArgumentsDependenciesFieldNotMap,
  expectedTypes: [ExpectedType.string],
);

/// Note: Since this diagnostic is only produced in pre-3.0 code, we do not
/// plan to go through the exercise of converting it to a Warning.
///
/// No parameters.
const DiagnosticWithoutArguments
deprecatedColonForDefaultValue = DiagnosticWithoutArgumentsImpl(
  name: 'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
  problemMessage:
      "Using a colon as the separator before a default value is deprecated and "
      "will not be supported in language version 3.0 and later.",
  correctionMessage: "Try replacing the colon with an equal sign.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
deprecatedExportUse = DiagnosticWithArguments(
  name: 'DEPRECATED_EXPORT_USE',
  problemMessage: "The ability to import '{0}' indirectly is deprecated.",
  correctionMessage: "Try importing '{0}' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_EXPORT_USE',
  withArguments: _withArgumentsDeprecatedExportUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Object typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object typeName})
>
deprecatedExtend = DiagnosticWithArguments(
  name: 'DEPRECATED_EXTEND',
  problemMessage: "Extending '{0}' is deprecated.",
  correctionMessage: "Try removing the 'extends' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_EXTEND',
  withArguments: _withArgumentsDeprecatedExtend,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedExtendsFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
      problemMessage: "Extending 'Function' is deprecated.",
      correctionMessage: "Try removing 'Function' from the 'extends' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DEPRECATED_EXTENDS_FUNCTION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
deprecatedField = DiagnosticWithArguments(
  name: 'DEPRECATED_FIELD',
  problemMessage: "The '{0}' field is no longer used and can be removed.",
  correctionMessage: "Try removing the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.DEPRECATED_FIELD',
  withArguments: _withArgumentsDeprecatedField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Object typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object typeName})
>
deprecatedImplement = DiagnosticWithArguments(
  name: 'DEPRECATED_IMPLEMENT',
  problemMessage: "Implementing '{0}' is deprecated.",
  correctionMessage: "Try removing '{0}' from the 'implements' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_IMPLEMENT',
  withArguments: _withArgumentsDeprecatedImplement,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedImplementsFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
      problemMessage: "Implementing 'Function' has no effect.",
      correctionMessage:
          "Try removing 'Function' from the 'implements' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DEPRECATED_IMPLEMENTS_FUNCTION',
      expectedTypes: [],
    );

/// Parameters:
/// Object typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object typeName})
>
deprecatedInstantiate = DiagnosticWithArguments(
  name: 'DEPRECATED_INSTANTIATE',
  problemMessage: "Instantiating '{0}' is deprecated.",
  correctionMessage: "Try instantiating a non-abstract class.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_INSTANTIATE',
  withArguments: _withArgumentsDeprecatedInstantiate,
  expectedTypes: [ExpectedType.object],
);

/// A hint code indicating reference to a deprecated lint.
///
/// Parameters:
/// String p0: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
deprecatedLint = DiagnosticWithArguments(
  name: 'DEPRECATED_LINT',
  problemMessage: "'{0}' is a deprecated lint rule and should not be used.",
  correctionMessage: "Try removing '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.DEPRECATED_LINT',
  withArguments: _withArgumentsDeprecatedLint,
  expectedTypes: [ExpectedType.string],
);

/// A hint code indicating reference to a deprecated lint.
///
/// Parameters:
/// String p0: the deprecated lint name
/// String p1: the replacing rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
deprecatedLintWithReplacement = DiagnosticWithArguments(
  name: 'DEPRECATED_LINT_WITH_REPLACEMENT',
  problemMessage: "'{0}' is deprecated and should be replaced by '{1}'.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.DEPRECATED_LINT_WITH_REPLACEMENT',
  withArguments: _withArgumentsDeprecatedLintWithReplacement,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
deprecatedMemberUse = DiagnosticWithArguments(
  name: 'DEPRECATED_MEMBER_USE',
  problemMessage: "'{0}' is deprecated and shouldn't be used.",
  correctionMessage:
      "Try replacing the use of the deprecated member with the replacement.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'HintCode.DEPRECATED_MEMBER_USE',
  withArguments: _withArgumentsDeprecatedMemberUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the member
/// String p1: message details
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
deprecatedMemberUseWithMessage = DiagnosticWithArguments(
  name: 'DEPRECATED_MEMBER_USE',
  problemMessage: "'{0}' is deprecated and shouldn't be used. {1}",
  correctionMessage:
      "Try replacing the use of the deprecated member with the replacement.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  withArguments: _withArgumentsDeprecatedMemberUseWithMessage,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Object typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object typeName})
>
deprecatedMixin = DiagnosticWithArguments(
  name: 'DEPRECATED_MIXIN',
  problemMessage: "Mixing in '{0}' is deprecated.",
  correctionMessage: "Try removing '{0}' from the 'with' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_MIXIN',
  withArguments: _withArgumentsDeprecatedMixin,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedMixinFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEPRECATED_SUBTYPE_OF_FUNCTION',
      problemMessage: "Mixing in 'Function' is deprecated.",
      correctionMessage: "Try removing 'Function' from the 'with' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DEPRECATED_MIXIN_FUNCTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments deprecatedNewInCommentReference =
    DiagnosticWithoutArgumentsImpl(
      name: 'DEPRECATED_NEW_IN_COMMENT_REFERENCE',
      problemMessage:
          "Using the 'new' keyword in a comment reference is deprecated.",
      correctionMessage: "Try referring to a constructor by its name.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DEPRECATED_NEW_IN_COMMENT_REFERENCE',
      expectedTypes: [],
    );

/// Parameters:
/// Object parameterName: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object parameterName})
>
deprecatedOptional = DiagnosticWithArguments(
  name: 'DEPRECATED_OPTIONAL',
  problemMessage: "Omitting an argument for the '{0}' parameter is deprecated.",
  correctionMessage: "Try passing an argument for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_OPTIONAL',
  withArguments: _withArgumentsDeprecatedOptional,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object typeName})
>
deprecatedSubclass = DiagnosticWithArguments(
  name: 'DEPRECATED_SUBCLASS',
  problemMessage: "Subclassing '{0}' is deprecated.",
  correctionMessage:
      "Try removing the 'extends' clause, or removing '{0}' from the "
      "'implements' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DEPRECATED_SUBCLASS',
  withArguments: _withArgumentsDeprecatedSubclass,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments directiveAfterDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'DIRECTIVE_AFTER_DECLARATION',
      problemMessage: "Directives must appear before any declarations.",
      correctionMessage: "Try moving the directive before any declarations.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DIRECTIVE_AFTER_DECLARATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments disallowedTypeInstantiationExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
      problemMessage:
          "Only a generic type, generic function, generic instance method, or "
          "generic constructor can have type arguments.",
      correctionMessage:
          "Try removing the type arguments, or instantiating the type(s) of a "
          "generic type, generic function, generic instance method, or generic "
          "constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.DISALLOWED_TYPE_INSTANTIATION_EXPRESSION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the doc directive argument
/// String p1: the expected format
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
docDirectiveArgumentWrongFormat = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT',
  problemMessage: "The '{0}' argument must be formatted as {1}.",
  correctionMessage: "Try formatting '{0}' as {1}.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT',
  withArguments: _withArgumentsDocDirectiveArgumentWrongFormat,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the doc directive
/// int p1: the actual number of arguments
/// int p2: the expected number of arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required int p1,
    required int p2,
  })
>
docDirectiveHasExtraArguments = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS',
  problemMessage:
      "The '{0}' directive has '{1}' arguments, but only '{2}' are expected.",
  correctionMessage: "Try removing the extra arguments.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS',
  withArguments: _withArgumentsDocDirectiveHasExtraArguments,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String p0: the name of the doc directive
/// String p1: the name of the unexpected argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
docDirectiveHasUnexpectedNamedArgument = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT',
  problemMessage:
      "The '{0}' directive has an unexpected named argument, '{1}'.",
  correctionMessage: "Try removing the unexpected argument.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT',
  withArguments: _withArgumentsDocDirectiveHasUnexpectedNamedArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments docDirectiveMissingClosingBrace =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOC_DIRECTIVE_MISSING_CLOSING_BRACE',
      problemMessage: "Doc directive is missing a closing curly brace ('}').",
      correctionMessage: "Try closing the directive with a curly brace.",
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_BRACE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the corresponding doc directive tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
docDirectiveMissingClosingTag = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_MISSING_CLOSING_TAG',
  problemMessage: "Doc directive is missing a closing tag.",
  correctionMessage:
      "Try closing the directive with the appropriate closing tag, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_CLOSING_TAG',
  withArguments: _withArgumentsDocDirectiveMissingClosingTag,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the doc directive
/// String p1: the name of the missing argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
docDirectiveMissingOneArgument = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
  problemMessage: "The '{0}' directive is missing a '{1}' argument.",
  correctionMessage: "Try adding a '{1}' argument before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT',
  withArguments: _withArgumentsDocDirectiveMissingOneArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the corresponding doc directive tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
docDirectiveMissingOpeningTag = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_MISSING_OPENING_TAG',
  problemMessage: "Doc directive is missing an opening tag.",
  correctionMessage:
      "Try opening the directive with the appropriate opening tag, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_OPENING_TAG',
  withArguments: _withArgumentsDocDirectiveMissingOpeningTag,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the doc directive
/// String p1: the name of the first missing argument
/// String p2: the name of the second missing argument
/// String p3: the name of the third missing argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  })
>
docDirectiveMissingThreeArguments = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
  problemMessage:
      "The '{0}' directive is missing a '{1}', a '{2}', and a '{3}' argument.",
  correctionMessage: "Try adding the missing arguments before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
docDirectiveMissingTwoArguments = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_MISSING_ARGUMENT',
  problemMessage:
      "The '{0}' directive is missing a '{1}' and a '{2}' argument.",
  correctionMessage: "Try adding the missing arguments before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS',
  withArguments: _withArgumentsDocDirectiveMissingTwoArguments,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String p0: the name of the unknown doc directive.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
docDirectiveUnknown = DiagnosticWithArguments(
  name: 'DOC_DIRECTIVE_UNKNOWN',
  problemMessage: "Doc directive '{0}' is unknown.",
  correctionMessage: "Try using one of the supported doc directives.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DOC_DIRECTIVE_UNKNOWN',
  withArguments: _withArgumentsDocDirectiveUnknown,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments docImportCannotBeDeferred =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOC_IMPORT_CANNOT_BE_DEFERRED',
      problemMessage: "Doc imports can't be deferred.",
      correctionMessage: "Try removing the 'deferred' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DOC_IMPORT_CANNOT_BE_DEFERRED',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHaveCombinators =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOC_IMPORT_CANNOT_HAVE_COMBINATORS',
      problemMessage: "Doc imports can't have show or hide combinators.",
      correctionMessage: "Try removing the combinator.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_COMBINATORS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHaveConfigurations =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS',
      problemMessage: "Doc imports can't have configurations.",
      correctionMessage: "Try removing the configurations.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHavePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOC_IMPORT_CANNOT_HAVE_PREFIX',
      problemMessage: "Doc imports can't have prefixes.",
      correctionMessage: "Try removing the prefix.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DOC_IMPORT_CANNOT_HAVE_PREFIX',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments dotShorthandMissingContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'DOT_SHORTHAND_MISSING_CONTEXT',
      problemMessage:
          "A dot shorthand can't be used where there is no context type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.DOT_SHORTHAND_MISSING_CONTEXT',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the static getter
/// String p1: the name of the enclosing type where the getter is being looked
///            for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
dotShorthandUndefinedGetter = DiagnosticWithArguments(
  name: 'DOT_SHORTHAND_UNDEFINED_MEMBER',
  problemMessage:
      "The static getter '{0}' isn't defined for the context type '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing static getter, or "
      "defining a getter or field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_GETTER',
  withArguments: _withArgumentsDotShorthandUndefinedGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the static method or constructor
/// String p1: the name of the enclosing type where the method or constructor
///            is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
dotShorthandUndefinedInvocation = DiagnosticWithArguments(
  name: 'DOT_SHORTHAND_UNDEFINED_MEMBER',
  problemMessage:
      "The static method or constructor '{0}' isn't defined for the context type "
      "'{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing static method or "
      "constructor, or defining a static method or constructor named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DOT_SHORTHAND_UNDEFINED_INVOCATION',
  withArguments: _withArgumentsDotShorthandUndefinedInvocation,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateConstructorDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_CONSTRUCTOR',
      problemMessage: "The unnamed constructor is already defined.",
      correctionMessage: "Try giving one of the constructors a name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the duplicate entity
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
duplicateConstructorName = DiagnosticWithArguments(
  name: 'DUPLICATE_CONSTRUCTOR',
  problemMessage: "The constructor with name '{0}' is already defined.",
  correctionMessage: "Try renaming one of the constructors.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME',
  withArguments: _withArgumentsDuplicateConstructorName,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateDeferred =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_DEFERRED',
      problemMessage:
          "An import directive can only have one 'deferred' keyword.",
      correctionMessage: "Try removing all but one 'deferred' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DUPLICATE_DEFERRED',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the duplicate entity
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicateDefinition = DiagnosticWithArguments(
  name: 'DUPLICATE_DEFINITION',
  problemMessage: "The name '{0}' is already defined.",
  correctionMessage: "Try renaming one of the declarations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_DEFINITION',
  withArguments: _withArgumentsDuplicateDefinition,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// 0: the modifier that was duplicated
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode duplicatedModifier = DiagnosticCodeWithExpectedTypes(
  name: 'DUPLICATED_MODIFIER',
  problemMessage: "The modifier '{0}' was already specified.",
  correctionMessage: "Try removing all but one occurrence of the modifier.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.DUPLICATED_MODIFIER',
  expectedTypes: [ExpectedType.token],
);

/// Duplicate exports.
///
/// No parameters.
const DiagnosticWithoutArguments duplicateExport =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_EXPORT',
      problemMessage: "Duplicate export.",
      correctionMessage: "Try removing all but one export of the library.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DUPLICATE_EXPORT',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicateFieldFormalParameter = DiagnosticWithArguments(
  name: 'DUPLICATE_FIELD_FORMAL_PARAMETER',
  problemMessage:
      "The field '{0}' can't be initialized by multiple parameters in the same "
      "constructor.",
  correctionMessage:
      "Try removing one of the parameters, or using different fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_FIELD_FORMAL_PARAMETER',
  withArguments: _withArgumentsDuplicateFieldFormalParameter,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the duplicated name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicateFieldName = DiagnosticWithArguments(
  name: 'DUPLICATE_FIELD_NAME',
  problemMessage: "The field name '{0}' is already used in this record.",
  correctionMessage: "Try renaming the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_FIELD_NAME',
  withArguments: _withArgumentsDuplicateFieldName,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateHiddenName =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_HIDDEN_NAME',
      problemMessage: "Duplicate hidden name.",
      correctionMessage:
          "Try removing the repeated name from the list of hidden members.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DUPLICATE_HIDDEN_NAME',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the diagnostic being ignored
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
duplicateIgnore = DiagnosticWithArguments(
  name: 'DUPLICATE_IGNORE',
  problemMessage:
      "The diagnostic '{0}' doesn't need to be ignored here because it's already "
      "being ignored.",
  correctionMessage:
      "Try removing the name from the list, or removing the whole comment if "
      "this is the only name in the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.DUPLICATE_IGNORE',
  withArguments: _withArgumentsDuplicateIgnore,
  expectedTypes: [ExpectedType.string],
);

/// Duplicate imports.
///
/// No parameters.
const DiagnosticWithoutArguments duplicateImport =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_IMPORT',
      problemMessage: "Duplicate import.",
      correctionMessage: "Try removing all but one import of the library.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DUPLICATE_IMPORT',
      expectedTypes: [],
    );

/// Parameters:
/// 0: the label that was duplicated
///
/// Parameters:
/// Name name: undocumented
const DiagnosticCode duplicateLabelInSwitchStatement =
    DiagnosticCodeWithExpectedTypes(
      name: 'DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
      problemMessage:
          "The label '{0}' was already used in this switch statement.",
      correctionMessage: "Try choosing a different name for this label.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DUPLICATE_LABEL_IN_SWITCH_STATEMENT',
      expectedTypes: [ExpectedType.name],
    );

/// Parameters:
/// String p0: the name of the parameter that was duplicated
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
duplicateNamedArgument = DiagnosticWithArguments(
  name: 'DUPLICATE_NAMED_ARGUMENT',
  problemMessage:
      "The argument for the named parameter '{0}' was already specified.",
  correctionMessage:
      "Try removing one of the named arguments, or correcting one of the "
      "names to reference a different named parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT',
  withArguments: _withArgumentsDuplicateNamedArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Uri p0: the URI of the duplicate part
const DiagnosticWithArguments<LocatableDiagnostic Function({required Uri p0})>
duplicatePart = DiagnosticWithArguments(
  name: 'DUPLICATE_PART',
  problemMessage: "The library already contains a part with the URI '{0}'.",
  correctionMessage:
      "Try removing all except one of the duplicated part directives.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_PART',
  withArguments: _withArgumentsDuplicatePart,
  expectedTypes: [ExpectedType.uri],
);

/// Parameters:
/// Object p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicatePatternAssignmentVariable = DiagnosticWithArguments(
  name: 'DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE',
  problemMessage: "The variable '{0}' is already assigned in this pattern.",
  correctionMessage: "Try renaming the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE',
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicatePatternField = DiagnosticWithArguments(
  name: 'DUPLICATE_PATTERN_FIELD',
  problemMessage: "The field '{0}' is already matched in this pattern.",
  correctionMessage: "Try removing the duplicate field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD',
  withArguments: _withArgumentsDuplicatePatternField,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments duplicatePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_PREFIX',
      problemMessage:
          "An import directive can only have one prefix ('as' clause).",
      correctionMessage: "Try removing all but one prefix.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.DUPLICATE_PREFIX',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments duplicateRestElementInPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_REST_ELEMENT_IN_PATTERN',
      problemMessage:
          "At most one rest element is allowed in a list or map pattern.",
      correctionMessage: "Try removing the duplicate rest element.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.DUPLICATE_REST_ELEMENT_IN_PATTERN',
      expectedTypes: [],
    );

/// Duplicate rules.
///
/// Parameters:
/// String p0: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
duplicateRule = DiagnosticWithArguments(
  name: 'DUPLICATE_RULE',
  problemMessage:
      "The rule {0} is already specified and doesn't need to be specified again.",
  correctionMessage: "Try removing all but one specification of the rule.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.DUPLICATE_RULE',
  withArguments: _withArgumentsDuplicateRule,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateShownName =
    DiagnosticWithoutArgumentsImpl(
      name: 'DUPLICATE_SHOWN_NAME',
      problemMessage: "Duplicate shown name.",
      correctionMessage:
          "Try removing the repeated name from the list of shown members.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.DUPLICATE_SHOWN_NAME',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
duplicateVariablePattern = DiagnosticWithArguments(
  name: 'DUPLICATE_VARIABLE_PATTERN',
  problemMessage: "The variable '{0}' is already defined in this pattern.",
  correctionMessage: "Try renaming the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN',
  withArguments: _withArgumentsDuplicateVariablePattern,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments emptyEnumBody = DiagnosticWithoutArgumentsImpl(
  name: 'EMPTY_ENUM_BODY',
  problemMessage: "An enum must declare at least one constant name.",
  correctionMessage: "Try declaring a constant.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EMPTY_ENUM_BODY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments emptyMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'EMPTY_MAP_PATTERN',
      problemMessage: "A map pattern must have at least one entry.",
      correctionMessage: "Try replacing it with an object pattern 'Map()'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EMPTY_MAP_PATTERN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordLiteralWithComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'EMPTY_RECORD_LITERAL_WITH_COMMA',
      problemMessage:
          "A record literal without fields can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EMPTY_RECORD_LITERAL_WITH_COMMA',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordTypeNamedFieldsList =
    DiagnosticWithoutArgumentsImpl(
      name: 'EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
      problemMessage:
          "The list of named fields in a record type can't be empty.",
      correctionMessage: "Try adding a named field to the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EMPTY_RECORD_TYPE_NAMED_FIELDS_LIST',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordTypeWithComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'EMPTY_RECORD_TYPE_WITH_COMMA',
      problemMessage:
          "A record type without fields can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EMPTY_RECORD_TYPE_WITH_COMMA',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the subclass
/// String p1: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
emptyStruct = DiagnosticWithArguments(
  name: 'EMPTY_STRUCT',
  problemMessage:
      "The class '{0}' can't be empty because it's a subclass of '{1}'.",
  correctionMessage:
      "Try adding a field to '{0}' or use a different superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.EMPTY_STRUCT',
  withArguments: _withArgumentsEmptyStruct,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments encoding = DiagnosticWithoutArgumentsImpl(
  name: 'ENCODING',
  problemMessage: "Unable to decode bytes as UTF-8.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.ENCODING',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments enumConstantInvokesFactoryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR',
      problemMessage: "An enum value can't invoke a factory constructor.",
      correctionMessage: "Try using a generative constructor.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.ENUM_CONSTANT_INVOKES_FACTORY_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumConstantSameNameAsEnclosing =
    DiagnosticWithoutArgumentsImpl(
      name: 'ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
      problemMessage:
          "The name of the enum value can't be the same as the enum's name.",
      correctionMessage: "Try renaming the constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ENUM_CONSTANT_SAME_NAME_AS_ENCLOSING',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumInClass = DiagnosticWithoutArgumentsImpl(
  name: 'ENUM_IN_CLASS',
  problemMessage: "Enums can't be declared inside classes.",
  correctionMessage: "Try moving the enum to the top-level.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.ENUM_IN_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
enumInstantiatedToBoundsIsNotWellBounded = DiagnosticWithoutArgumentsImpl(
  name: 'ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
  problemMessage:
      "The result of instantiating the enum to bounds is not well-bounded.",
  correctionMessage: "Try using different bounds for type parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.ENUM_INSTANTIATED_TO_BOUNDS_IS_NOT_WELL_BOUNDED',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments enumMixinWithInstanceVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
      problemMessage: "Mixins applied to enums can't have instance variables.",
      correctionMessage: "Try replacing the instance variables with getters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ENUM_MIXIN_WITH_INSTANCE_VARIABLE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the abstract method
/// String p1: the name of the enclosing enum
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
enumWithAbstractMember = DiagnosticWithArguments(
  name: 'ENUM_WITH_ABSTRACT_MEMBER',
  problemMessage: "'{0}' must have a method body because '{1}' is an enum.",
  correctionMessage: "Try adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ENUM_WITH_ABSTRACT_MEMBER',
  withArguments: _withArgumentsEnumWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments enumWithNameValues =
    DiagnosticWithoutArgumentsImpl(
      name: 'ENUM_WITH_NAME_VALUES',
      problemMessage: "The name 'values' is not a valid name for an enum.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ENUM_WITH_NAME_VALUES',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumWithoutConstants =
    DiagnosticWithoutArgumentsImpl(
      name: 'ENUM_WITHOUT_CONSTANTS',
      problemMessage: "The enum must have at least one enum constant.",
      correctionMessage: "Try declaring an enum constant.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ENUM_WITHOUT_CONSTANTS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalElementsInConstSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUAL_ELEMENTS_IN_CONST_SET',
      problemMessage: "Two elements in a constant set literal can't be equal.",
      correctionMessage: "Change or remove the duplicate element.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalElementsInSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUAL_ELEMENTS_IN_SET',
      problemMessage: "Two elements in a set literal shouldn't be equal.",
      correctionMessage: "Change or remove the duplicate element.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.EQUAL_ELEMENTS_IN_SET',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalityCannotBeEqualityOperand =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
      problemMessage:
          "A comparison expression can't be an operand of another comparison "
          "expression.",
      correctionMessage:
          "Try putting parentheses around one of the comparisons.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EQUALITY_CANNOT_BE_EQUALITY_OPERAND',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInConstMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUAL_KEYS_IN_CONST_MAP',
      problemMessage: "Two keys in a constant map literal can't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUAL_KEYS_IN_MAP',
      problemMessage: "Two keys in a map literal shouldn't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.EQUAL_KEYS_IN_MAP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'EQUAL_KEYS_IN_MAP_PATTERN',
      problemMessage: "Two keys in a map pattern can't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EQUAL_KEYS_IN_MAP_PATTERN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedCaseOrDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_CASE_OR_DEFAULT',
      problemMessage: "Expected 'case' or 'default'.",
      correctionMessage: "Try placing this code inside a case clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_CASE_OR_DEFAULT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedCatchClauseBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage: "A catch clause must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_CATCH_CLAUSE_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedClassBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage:
          "A class declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_CLASS_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedClassMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_CLASS_MEMBER',
      problemMessage: "Expected a class member.",
      correctionMessage: "Try placing this code inside a class member.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_CLASS_MEMBER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedElseOrComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_ELSE_OR_COMMA',
      problemMessage: "Expected 'else' or comma.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_ELSE_OR_COMMA',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
expectedExecutable = DiagnosticWithoutArgumentsImpl(
  name: 'EXPECTED_EXECUTABLE',
  problemMessage: "Expected a method, getter, setter or operator declaration.",
  correctionMessage:
      "This appears to be incomplete code. Try removing it or completing it.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPECTED_EXECUTABLE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments expectedExtensionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage:
          "An extension declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_EXTENSION_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
expectedExtensionTypeBody = DiagnosticWithoutArgumentsImpl(
  name: 'EXPECTED_BODY',
  problemMessage:
      "An extension type declaration must have a body, even if it is empty.",
  correctionMessage: "Try adding an empty body.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPECTED_EXTENSION_TYPE_BODY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments expectedFinallyClauseBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage: "A finally clause must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_FINALLY_CLAUSE_BODY',
      expectedTypes: [],
    );

/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode expectedIdentifierButGotKeyword =
    DiagnosticCodeWithExpectedTypes(
      name: 'EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
      problemMessage:
          "'{0}' can't be used as an identifier because it's a keyword.",
      correctionMessage:
          "Try renaming this to be an identifier that isn't a keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// String string: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String string})
>
expectedInstead = DiagnosticWithArguments(
  name: 'EXPECTED_INSTEAD',
  problemMessage: "Expected '{0}' instead of this.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPECTED_INSTEAD',
  withArguments: _withArgumentsExpectedInstead,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expectedListOrMapLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_LIST_OR_MAP_LITERAL',
      problemMessage: "Expected a list or map literal.",
      correctionMessage:
          "Try inserting a list or map literal, or remove the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_LIST_OR_MAP_LITERAL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedMixinBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage:
          "A mixin declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_MIXIN_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_NAMED_TYPE',
      problemMessage: "Expected a class name.",
      correctionMessage:
          "Try using a class name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_EXTENDS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeImplements =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_NAMED_TYPE',
      problemMessage: "Expected the name of a class or mixin.",
      correctionMessage:
          "Try using a class or mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_IMPLEMENTS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeOn =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_NAMED_TYPE',
      problemMessage: "Expected the name of a class or mixin.",
      correctionMessage:
          "Try using a class or mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_ON',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_NAMED_TYPE',
      problemMessage: "Expected a mixin name.",
      correctionMessage:
          "Try using a mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_NAMED_TYPE_WITH',
      expectedTypes: [],
    );

/// Parameters:
/// int p0: the number of provided type arguments
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
expectedOneListPatternTypeArguments = DiagnosticWithArguments(
  name: 'EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS',
  problemMessage:
      "List patterns require one type argument or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPECTED_ONE_LIST_PATTERN_TYPE_ARGUMENTS',
  withArguments: _withArgumentsExpectedOneListPatternTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int p0: the number of provided type arguments
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
expectedOneListTypeArguments = DiagnosticWithArguments(
  name: 'EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
  problemMessage:
      "List literals require one type argument or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS',
  withArguments: _withArgumentsExpectedOneListTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int p0: the number of provided type arguments
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
expectedOneSetTypeArguments = DiagnosticWithArguments(
  name: 'EXPECTED_ONE_SET_TYPE_ARGUMENTS',
  problemMessage:
      "Set literals require one type argument or none, but {0} were found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS',
  withArguments: _withArgumentsExpectedOneSetTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments expectedRepresentationField =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_REPRESENTATION_FIELD',
      problemMessage: "Expected a representation field.",
      correctionMessage:
          "Try providing the representation field for this extension type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_REPRESENTATION_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedRepresentationType =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_REPRESENTATION_TYPE',
      problemMessage: "Expected a representation type.",
      correctionMessage:
          "Try providing the representation type for this extension type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_REPRESENTATION_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedStringLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_STRING_LITERAL',
      problemMessage: "Expected a string literal.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_STRING_LITERAL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedSwitchExpressionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage:
          "A switch expression must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_SWITCH_EXPRESSION_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedSwitchStatementBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage:
          "A switch statement must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_SWITCH_STATEMENT_BODY',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the token that was expected but not found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
expectedToken = DiagnosticWithArguments(
  name: 'EXPECTED_TOKEN',
  problemMessage: "Expected to find '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPECTED_TOKEN',
  withArguments: _withArgumentsExpectedToken,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expectedTryStatementBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_BODY',
      problemMessage: "A try statement must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_TRY_STATEMENT_BODY',
      expectedTypes: [],
    );

/// Parameters:
/// int p0: the number of provided type arguments
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
expectedTwoMapPatternTypeArguments = DiagnosticWithArguments(
  name: 'EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS',
  problemMessage:
      "Map patterns require two type arguments or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPECTED_TWO_MAP_PATTERN_TYPE_ARGUMENTS',
  withArguments: _withArgumentsExpectedTwoMapPatternTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int p0: the number of provided type arguments
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
expectedTwoMapTypeArguments = DiagnosticWithArguments(
  name: 'EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
  problemMessage:
      "Map literals require two type arguments or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS',
  withArguments: _withArgumentsExpectedTwoMapTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments expectedTypeName =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPECTED_TYPE_NAME',
      problemMessage: "Expected a type name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPECTED_TYPE_NAME',
      expectedTypes: [],
    );

/// Parameters:
/// String member: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String member})
>
experimentalMemberUse = DiagnosticWithArguments(
  name: 'EXPERIMENTAL_MEMBER_USE',
  problemMessage:
      "'{0}' is experimental and could be removed or changed at any time.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.EXPERIMENTAL_MEMBER_USE',
  withArguments: _withArgumentsExperimentalMemberUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
experimentNotEnabled = DiagnosticWithArguments(
  name: 'EXPERIMENT_NOT_ENABLED',
  problemMessage: "This requires the '{0}' language feature to be enabled.",
  correctionMessage:
      "Try updating your pubspec.yaml to set the minimum SDK constraint to "
      "{1} or higher, and running 'pub get'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPERIMENT_NOT_ENABLED',
  withArguments: _withArgumentsExperimentNotEnabled,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String string: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String string})
>
experimentNotEnabledOffByDefault = DiagnosticWithArguments(
  name: 'EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
  problemMessage:
      "This requires the experimental '{0}' language feature to be enabled.",
  correctionMessage:
      "Try passing the '--enable-experiment={0}' command line option.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXPERIMENT_NOT_ENABLED_OFF_BY_DEFAULT',
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments exportDirectiveAfterPartDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
      problemMessage: "Export directives must precede part directives.",
      correctionMessage:
          "Try moving the export directives before the part directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the URI pointing to a library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
exportInternalLibrary = DiagnosticWithArguments(
  name: 'EXPORT_INTERNAL_LIBRARY',
  problemMessage: "The library '{0}' is internal and can't be exported.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY',
  withArguments: _withArgumentsExportInternalLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
exportOfNonLibrary = DiagnosticWithArguments(
  name: 'EXPORT_OF_NON_LIBRARY',
  problemMessage: "The exported library '{0}' can't have a part-of directive.",
  correctionMessage: "Try exporting the library that the part is a part of.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY',
  withArguments: _withArgumentsExportOfNonLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expressionInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXPRESSION_IN_MAP',
      problemMessage: "Expressions can't be used in a map literal.",
      correctionMessage:
          "Try removing the expression or converting it to be a map entry.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXPRESSION_IN_MAP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extendsDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUBTYPE_OF_DEFERRED_CLASS',
      problemMessage: "Classes can't extend deferred classes.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
extendsDisallowedClass = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_DISALLOWED_TYPE',
  problemMessage: "Classes can't extend '{0}'.",
  correctionMessage:
      "Try specifying a different superclass, or removing the extends "
      "clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS',
  withArguments: _withArgumentsExtendsDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments extendsNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENDS_NON_CLASS',
      problemMessage: "Classes can only extend other classes.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      isUnresolvedIdentifier: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTENDS_NON_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extendsTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
      problemMessage:
          "A type alias that expands to a type parameter can't be used as a "
          "superclass.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.EXTENDS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
extensionAsExpression = DiagnosticWithArguments(
  name: 'EXTENSION_AS_EXPRESSION',
  problemMessage: "Extension '{0}' can't be used as an expression.",
  correctionMessage: "Try replacing it with a valid expression.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_AS_EXPRESSION',
  withArguments: _withArgumentsExtensionAsExpression,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionAugmentationHasOnClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
      problemMessage: "Extension augmentations can't have 'on' clauses.",
      correctionMessage: "Try removing the 'on' clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTENSION_AUGMENTATION_HAS_ON_CLAUSE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the conflicting static member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
extensionConflictingStaticAndInstance = DiagnosticWithArguments(
  name: 'EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
  problemMessage:
      "An extension can't define static member '{0}' and an instance member with "
      "the same name.",
  correctionMessage: "Try renaming the member to a name that doesn't conflict.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_CONFLICTING_STATIC_AND_INSTANCE',
  withArguments: _withArgumentsExtensionConflictingStaticAndInstance,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresAbstractMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_DECLARES_ABSTRACT_MEMBER',
      problemMessage: "Extensions can't declare abstract members.",
      correctionMessage: "Try providing an implementation for the member.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTENSION_DECLARES_ABSTRACT_MEMBER',
      expectedTypes: [],
    );

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_DECLARES_CONSTRUCTOR',
      problemMessage: "Extensions can't declare constructors.",
      correctionMessage: "Try removing the constructor declaration.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTENSION_DECLARES_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_DECLARES_INSTANCE_FIELD',
      problemMessage: "Extensions can't declare instance fields.",
      correctionMessage: "Try replacing the field with a getter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionDeclaresMemberOfObject = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_DECLARES_MEMBER_OF_OBJECT',
  problemMessage:
      "Extensions can't declare members with the same name as a member declared "
      "by 'Object'.",
  correctionMessage: "Try specifying a different name for the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_DECLARES_MEMBER_OF_OBJECT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionOverrideAccessToStaticMember = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
  problemMessage:
      "An extension override can't be used to access a static member from an "
      "extension.",
  correctionMessage: "Try using just the name of the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the type of the argument
/// Type p1: the extended type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
extensionOverrideArgumentNotAssignable = DiagnosticWithArguments(
  name: 'EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
  problemMessage:
      "The type of the argument to the extension override '{0}' isn't assignable "
      "to the extended type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_ARGUMENT_NOT_ASSIGNABLE',
  withArguments: _withArgumentsExtensionOverrideArgumentNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionOverrideWithCascade = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_OVERRIDE_WITH_CASCADE',
  problemMessage:
      "Extension overrides have no value so they can't be used as the receiver "
      "of a cascade expression.",
  correctionMessage: "Try using '.' instead of '..'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionOverrideWithoutAccess =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_OVERRIDE_WITHOUT_ACCESS',
      problemMessage:
          "An extension override can only be used to access instance members.",
      correctionMessage: "Consider adding an access to an instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTENSION_OVERRIDE_WITHOUT_ACCESS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeConstructorWithSuperFormalParameter = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER',
  problemMessage:
      "Extension type constructors can't declare super formal parameters.",
  correctionMessage: "Try removing the super formal parameter declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_FORMAL_PARAMETER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeConstructorWithSuperInvocation = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION',
  problemMessage:
      "Extension type constructors can't include super initializers.",
  correctionMessage: "Try removing the super constructor invocation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.EXTENSION_TYPE_CONSTRUCTOR_WITH_SUPER_INVOCATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionTypeDeclaresInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_TYPE_DECLARES_INSTANCE_FIELD',
      problemMessage: "Extension types can't declare instance fields.",
      correctionMessage: "Try replacing the field with a getter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeDeclaresMemberOfObject = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT',
  problemMessage:
      "Extension types can't declare members with the same name as a member "
      "declared by 'Object'.",
  correctionMessage: "Try specifying a different name for the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionTypeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_TYPE_EXTENDS',
      problemMessage:
          "An extension type declaration can't have an 'extends' clause.",
      correctionMessage:
          "Try removing the 'extends' clause or replacing the 'extends' with "
          "'implements'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTENSION_TYPE_EXTENDS',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the display string of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
extensionTypeImplementsDisallowedType = DiagnosticWithArguments(
  name: 'EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE',
  problemMessage: "Extension types can't implement '{0}'.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_DISALLOWED_TYPE',
  withArguments: _withArgumentsExtensionTypeImplementsDisallowedType,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeImplementsItself = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_TYPE_IMPLEMENTS_ITSELF',
  problemMessage: "The extension type can't implement itself.",
  correctionMessage:
      "Try removing the superinterface that references this extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_ITSELF',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the implemented not extension type
/// Type p1: the ultimate representation type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
extensionTypeImplementsNotSupertype = DiagnosticWithArguments(
  name: 'EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE',
  problemMessage: "'{0}' is not a supertype of '{1}', the representation type.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_IMPLEMENTS_NOT_SUPERTYPE',
  withArguments: _withArgumentsExtensionTypeImplementsNotSupertype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the representation type of the implemented extension type
/// String p1: the name of the implemented extension type
/// Type p2: the representation type of the this extension type
/// String p3: the name of the this extension type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required String p1,
    required DartType p2,
    required String p3,
  })
>
extensionTypeImplementsRepresentationNotSupertype = DiagnosticWithArguments(
  name: 'EXTENSION_TYPE_IMPLEMENTS_REPRESENTATION_NOT_SUPERTYPE',
  problemMessage:
      "'{0}', the representation type of '{1}', is not a supertype of '{2}', the "
      "representation type of '{3}'.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
extensionTypeInheritedMemberConflict = DiagnosticWithArguments(
  name: 'EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT',
  problemMessage:
      "The extension type '{0}' has more than one distinct member named '{1}' "
      "from implemented types.",
  correctionMessage:
      "Try redeclaring the corresponding member in this extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_INHERITED_MEMBER_CONFLICT',
  withArguments: _withArgumentsExtensionTypeInheritedMemberConflict,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeRepresentationDependsOnItself = DiagnosticWithoutArgumentsImpl(
  name: 'EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF',
  problemMessage: "The extension type representation can't depend on itself.",
  correctionMessage: "Try specifying a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_DEPENDS_ON_ITSELF',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionTypeRepresentationTypeBottom =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM',
      problemMessage: "The representation type can't be a bottom type.",
      correctionMessage: "Try specifying a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.EXTENSION_TYPE_REPRESENTATION_TYPE_BOTTOM',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionTypeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTENSION_TYPE_WITH',
      problemMessage:
          "An extension type declaration can't have a 'with' clause.",
      correctionMessage:
          "Try removing the 'with' clause or replacing the 'with' with "
          "'implements'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTENSION_TYPE_WITH',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the abstract method
/// String p1: the name of the enclosing extension type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
extensionTypeWithAbstractMember = DiagnosticWithArguments(
  name: 'EXTENSION_TYPE_WITH_ABSTRACT_MEMBER',
  problemMessage:
      "'{0}' must have a method body because '{1}' is an extension type.",
  correctionMessage: "Try adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER',
  withArguments: _withArgumentsExtensionTypeWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments externalClass = DiagnosticWithoutArgumentsImpl(
  name: 'EXTERNAL_CLASS',
  problemMessage: "Classes can't be declared to be 'external'.",
  correctionMessage: "Try removing the keyword 'external'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXTERNAL_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalConstructorWithFieldInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
      problemMessage: "An external constructor can't initialize fields.",
      correctionMessage:
          "Try removing the field initializers, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName:
          'ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalConstructorWithInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
      problemMessage: "An external constructor can't have any initializers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalEnum = DiagnosticWithoutArgumentsImpl(
  name: 'EXTERNAL_ENUM',
  problemMessage: "Enums can't be declared to be 'external'.",
  correctionMessage: "Try removing the keyword 'external'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXTERNAL_ENUM',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalFactoryRedirection =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_FACTORY_REDIRECTION',
      problemMessage: "A redirecting factory can't be external.",
      correctionMessage: "Try removing the 'external' modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_FACTORY_REDIRECTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalFactoryWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_FACTORY_WITH_BODY',
      problemMessage: "External factories can't have a body.",
      correctionMessage:
          "Try removing the body of the factory, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_FACTORY_WITH_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
externalFieldConstructorInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'EXTERNAL_WITH_INITIALIZER',
  problemMessage: "External fields can't have initializers.",
  correctionMessage:
      "Try removing the field initializer or the 'external' keyword from the "
      "field declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTERNAL_FIELD_CONSTRUCTOR_INITIALIZER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalFieldInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_WITH_INITIALIZER',
      problemMessage: "External fields can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'external' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTERNAL_FIELD_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalGetterWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_GETTER_WITH_BODY',
      problemMessage: "External getters can't have a body.",
      correctionMessage:
          "Try removing the body of the getter, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_GETTER_WITH_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalLateField =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_LATE_FIELD',
      problemMessage: "External fields cannot be late.",
      correctionMessage: "Try removing the 'external' or 'late' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_LATE_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalMethodWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_METHOD_WITH_BODY',
      problemMessage: "An external or native method can't have a body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_METHOD_WITH_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalOperatorWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_OPERATOR_WITH_BODY',
      problemMessage: "External operators can't have a body.",
      correctionMessage:
          "Try removing the body of the operator, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_OPERATOR_WITH_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalSetterWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_SETTER_WITH_BODY',
      problemMessage: "External setters can't have a body.",
      correctionMessage:
          "Try removing the body of the setter, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_SETTER_WITH_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalTypedef =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_TYPEDEF',
      problemMessage: "Typedefs can't be declared to be 'external'.",
      correctionMessage: "Try removing the keyword 'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTERNAL_TYPEDEF',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalVariableInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTERNAL_WITH_INITIALIZER',
      problemMessage: "External variables can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'external' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.EXTERNAL_VARIABLE_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extraAnnotationOnStructField = DiagnosticWithoutArgumentsImpl(
  name: 'EXTRA_ANNOTATION_ON_STRUCT_FIELD',
  problemMessage:
      "Fields in a struct class must have exactly one annotation indicating the "
      "native type.",
  correctionMessage: "Try removing the extra annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.EXTRA_ANNOTATION_ON_STRUCT_FIELD',
  expectedTypes: [],
);

/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode extraneousModifier = DiagnosticCodeWithExpectedTypes(
  name: 'EXTRANEOUS_MODIFIER',
  problemMessage: "Can't have modifier '{0}' here.",
  correctionMessage: "Try removing '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.EXTRANEOUS_MODIFIER',
  expectedTypes: [ExpectedType.token],
);

/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode extraneousModifierInExtensionType =
    DiagnosticCodeWithExpectedTypes(
      name: 'EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
      problemMessage: "Can't have modifier '{0}' in an extension type.",
      correctionMessage: "Try removing '{0}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTRANEOUS_MODIFIER_IN_EXTENSION_TYPE',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode extraneousModifierInPrimaryConstructor =
    DiagnosticCodeWithExpectedTypes(
      name: 'EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
      problemMessage: "Can't have modifier '{0}' in a primary constructor.",
      correctionMessage: "Try removing '{0}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.EXTRANEOUS_MODIFIER_IN_PRIMARY_CONSTRUCTOR',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// int p0: the maximum number of positional arguments
/// int p1: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
extraPositionalArguments = DiagnosticWithArguments(
  name: 'EXTRA_POSITIONAL_ARGUMENTS',
  problemMessage: "Too many positional arguments: {0} expected, but {1} found.",
  correctionMessage: "Try removing the extra arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS',
  withArguments: _withArgumentsExtraPositionalArguments,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// int p0: the maximum number of positional arguments
/// int p1: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
extraPositionalArgumentsCouldBeNamed = DiagnosticWithArguments(
  name: 'EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
  problemMessage: "Too many positional arguments: {0} expected, but {1} found.",
  correctionMessage:
      "Try removing the extra positional arguments, or specifying the name "
      "for named arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED',
  withArguments: _withArgumentsExtraPositionalArgumentsCouldBeNamed,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments extraSizeAnnotationCarray =
    DiagnosticWithoutArgumentsImpl(
      name: 'EXTRA_SIZE_ANNOTATION_CARRAY',
      problemMessage: "'Array's must have exactly one 'Array' annotation.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.EXTRA_SIZE_ANNOTATION_CARRAY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryTopLevelDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'FACTORY_TOP_LEVEL_DECLARATION',
      problemMessage:
          "Top-level declarations can't be declared to be 'factory'.",
      correctionMessage: "Try removing the keyword 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FACTORY_TOP_LEVEL_DECLARATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryWithInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'FACTORY_WITH_INITIALIZERS',
      problemMessage: "A 'factory' constructor can't have initializers.",
      correctionMessage:
          "Try removing the 'factory' keyword to make this a generative "
          "constructor, or removing the initializers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FACTORY_WITH_INITIALIZERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'FACTORY_WITHOUT_BODY',
      problemMessage:
          "A non-redirecting 'factory' constructor must have a body.",
      correctionMessage: "Try adding a body to the constructor.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FACTORY_WITHOUT_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments ffiNativeInvalidDuplicateDefaultAsset =
    DiagnosticWithoutArgumentsImpl(
      name: 'FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET',
      problemMessage:
          "There may be at most one @DefaultAsset annotation on a library.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
ffiNativeInvalidMultipleAnnotations = DiagnosticWithoutArgumentsImpl(
  name: 'FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS',
  problemMessage:
      "Native functions and fields must have exactly one `@Native` annotation.",
  correctionMessage: "Try removing the extra annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments ffiNativeMustBeExternal =
    DiagnosticWithoutArgumentsImpl(
      name: 'FFI_NATIVE_MUST_BE_EXTERNAL',
      problemMessage: "Native functions must be declared external.",
      correctionMessage: "Add the `external` keyword to the function.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer =
    DiagnosticWithoutArgumentsImpl(
      name:
          'FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
      problemMessage:
          "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
      correctionMessage: "Pass as Handle instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'FfiCode.FFI_NATIVE_ONLY_CLASSES_EXTENDING_NATIVEFIELDWRAPPERCLASS1_CAN_BE_POINTER',
      expectedTypes: [],
    );

/// Parameters:
/// int p0: the expected number of parameters
/// int p1: the actual number of parameters
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
ffiNativeUnexpectedNumberOfParameters = DiagnosticWithArguments(
  name: 'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
  problemMessage:
      "Unexpected number of Native annotation parameters. Expected {0} but has "
      "{1}.",
  correctionMessage: "Make sure parameters match the function annotated.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS',
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// int p0: the expected number of parameters
/// int p1: the actual number of parameters
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
ffiNativeUnexpectedNumberOfParametersWithReceiver = DiagnosticWithArguments(
  name: 'FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
  problemMessage:
      "Unexpected number of Native annotation parameters. Expected {0} but has "
      "{1}. Native instance method annotation must have receiver as first "
      "argument.",
  correctionMessage:
      "Make sure parameters match the function annotated, including an extra "
      "first parameter for the receiver.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER',
  withArguments:
      _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String p0: the name of the field being initialized multiple times
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
fieldInitializedByMultipleInitializers = DiagnosticWithArguments(
  name: 'FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
  problemMessage:
      "The field '{0}' can't be initialized twice in the same constructor.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS',
  withArguments: _withArgumentsFieldInitializedByMultipleInitializers,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializedInInitializerAndDeclaration = DiagnosticWithoutArgumentsImpl(
  name: 'FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
  problemMessage:
      "Fields can't be initialized in the constructor if they are final and were "
      "already initialized at their declaration.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments fieldInitializedInParameterAndInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
      problemMessage:
          "Fields can't be initialized in both the parameter list and the "
          "initializers.",
      correctionMessage: "Try removing one of the initializations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments fieldInitializedOutsideDeclaringClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
      problemMessage: "A field can only be initialized in its declaring class",
      correctionMessage:
          "Try passing a value into the superclass constructor, or moving the "
          "initialization into the constructor body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FIELD_INITIALIZED_OUTSIDE_DECLARING_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializerFactoryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
  problemMessage:
      "Initializing formal parameters can't be used in factory constructors.",
  correctionMessage: "Try using a normal parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the name of the type of the initializer expression
/// Type p1: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
fieldInitializerNotAssignable = DiagnosticWithArguments(
  name: 'FIELD_INITIALIZER_NOT_ASSIGNABLE',
  problemMessage:
      "The initializer type '{0}' can't be assigned to the field type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZER_NOT_ASSIGNABLE',
  withArguments: _withArgumentsFieldInitializerNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments fieldInitializerOutsideConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
      problemMessage:
          "Field formal parameters can only be used in a constructor.",
      correctionMessage: "Try removing 'this.'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializerRedirectingConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
  problemMessage: "The redirecting constructor can't have a field initializer.",
  correctionMessage:
      "Try initializing the field in the constructor being redirected to.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the name of the type of the field formal parameter
/// Type p1: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
fieldInitializingFormalNotAssignable = DiagnosticWithArguments(
  name: 'FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
  problemMessage:
      "The parameter type '{0}' is incompatible with the field type '{1}'.",
  correctionMessage:
      "Try changing or removing the parameter's type, or changing the "
      "field's type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE',
  withArguments: _withArgumentsFieldInitializingFormalNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments fieldMustBeExternalInStruct =
    DiagnosticWithoutArgumentsImpl(
      name: 'FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
      problemMessage:
          "Fields of 'Struct' and 'Union' subclasses must be marked external.",
      correctionMessage: "Try adding the 'external' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.FIELD_MUST_BE_EXTERNAL_IN_STRUCT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments finalAndCovariant =
    DiagnosticWithoutArgumentsImpl(
      name: 'FINAL_AND_COVARIANT',
      problemMessage:
          "Members can't be declared to be both 'final' and 'covariant'.",
      correctionMessage:
          "Try removing either the 'final' or 'covariant' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FINAL_AND_COVARIANT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
finalAndCovariantLateWithInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
  problemMessage:
      "Members marked 'late' with an initializer can't be declared to be both "
      "'final' and 'covariant'.",
  correctionMessage:
      "Try removing either the 'final' or 'covariant' keyword, or removing "
      "the initializer.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FINAL_AND_COVARIANT_LATE_WITH_INITIALIZER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalAndVar = DiagnosticWithoutArgumentsImpl(
  name: 'FINAL_AND_VAR',
  problemMessage: "Members can't be declared to be both 'final' and 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FINAL_AND_VAR',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the final class being extended.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalClassExtendedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be extended outside of its library because it's a "
      "final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the final class being implemented.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalClassImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be implemented outside of its library because it's "
      "a final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the final class being used as a mixin superclass
///            constraint.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalClassUsedAsMixinConstraintOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be used as a mixin superclass constraint outside of "
      "its library because it's a final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.FINAL_CLASS_USED_AS_MIXIN_CONSTRAINT_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments finalConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'FINAL_CONSTRUCTOR',
      problemMessage: "A constructor can't be declared to be 'final'.",
      correctionMessage: "Try removing the keyword 'final'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FINAL_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments finalEnum = DiagnosticWithoutArgumentsImpl(
  name: 'FINAL_ENUM',
  problemMessage: "Enums can't be declared to be 'final'.",
  correctionMessage: "Try removing the keyword 'final'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FINAL_ENUM',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the field in question
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalInitializedInDeclarationAndConstructor = DiagnosticWithArguments(
  name: 'FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
  problemMessage:
      "'{0}' is final and was given a value when it was declared, so it can't be "
      "set to a new value.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR',
  withArguments: _withArgumentsFinalInitializedInDeclarationAndConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments finalMethod = DiagnosticWithoutArgumentsImpl(
  name: 'FINAL_METHOD',
  problemMessage:
      "Getters, setters and methods can't be declared to be 'final'.",
  correctionMessage: "Try removing the keyword 'final'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FINAL_METHOD',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalMixin = DiagnosticWithoutArgumentsImpl(
  name: 'FINAL_MIXIN',
  problemMessage: "A mixin can't be declared 'final'.",
  correctionMessage: "Try removing the 'final' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FINAL_MIXIN',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'FINAL_MIXIN_CLASS',
      problemMessage: "A mixin class can't be declared 'final'.",
      correctionMessage: "Try removing the 'final' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.FINAL_MIXIN_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalNotInitialized = DiagnosticWithArguments(
  name: 'FINAL_NOT_INITIALIZED',
  problemMessage: "The final variable '{0}' must be initialized.",
  correctionMessage: "Try initializing the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED',
  withArguments: _withArgumentsFinalNotInitialized,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
finalNotInitializedConstructor1 = DiagnosticWithArguments(
  name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
  problemMessage: "All final variables must be initialized, but '{0}' isn't.",
  correctionMessage: "Try adding an initializer for the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1',
  withArguments: _withArgumentsFinalNotInitializedConstructor1,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the uninitialized final variable
/// String p1: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
finalNotInitializedConstructor2 = DiagnosticWithArguments(
  name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
  problemMessage:
      "All final variables must be initialized, but '{0}' and '{1}' aren't.",
  correctionMessage: "Try adding initializers for the fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2',
  withArguments: _withArgumentsFinalNotInitializedConstructor2,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the uninitialized final variable
/// String p1: the name of the uninitialized final variable
/// int p2: the number of additional not initialized variables that aren't
///         listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required int p2,
  })
>
finalNotInitializedConstructor3Plus = DiagnosticWithArguments(
  name: 'FINAL_NOT_INITIALIZED_CONSTRUCTOR',
  problemMessage:
      "All final variables must be initialized, but '{0}', '{1}', and {2} others "
      "aren't.",
  correctionMessage: "Try adding initializers for the fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS',
  withArguments: _withArgumentsFinalNotInitializedConstructor3Plus,
  expectedTypes: [ExpectedType.string, ExpectedType.string, ExpectedType.int],
);

/// A TODO comment marked as FIXME.
///
/// Parameters:
/// String message: the user-supplied problem message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
fixme = DiagnosticWithArguments(
  name: 'FIXME',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'TodoCode.FIXME',
  withArguments: _withArgumentsFixme,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments flutterFieldNotMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'FLUTTER_FIELD_NOT_MAP',
      problemMessage:
          "The value of the 'flutter' field is expected to be a map.",
      correctionMessage: "Try converting the value to be a map.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.FLUTTER_FIELD_NOT_MAP',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the type of the iterable expression.
/// String p1: the sequence type -- Iterable for `for` or Stream for `await
///            for`.
/// Type p2: the loop variable type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required String p1,
    required DartType p2,
  })
>
forInOfInvalidElementType = DiagnosticWithArguments(
  name: 'FOR_IN_OF_INVALID_ELEMENT_TYPE',
  problemMessage:
      "The type '{0}' used in the 'for' loop must implement '{1}' with a type "
      "argument that can be assigned to '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FOR_IN_OF_INVALID_ELEMENT_TYPE',
  withArguments: _withArgumentsForInOfInvalidElementType,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// Type p0: the type of the iterable expression.
/// String p1: the sequence type -- Iterable for `for` or Stream for `await
///            for`.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required String p1})
>
forInOfInvalidType = DiagnosticWithArguments(
  name: 'FOR_IN_OF_INVALID_TYPE',
  problemMessage: "The type '{0}' used in the 'for' loop must implement '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE',
  withArguments: _withArgumentsForInOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments forInWithConstVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'FOR_IN_WITH_CONST_VARIABLE',
      problemMessage: "A for-in loop variable can't be a 'const'.",
      correctionMessage:
          "Try removing the 'const' modifier from the variable, or use a "
          "different variable.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
functionTypedParameterVar = DiagnosticWithoutArgumentsImpl(
  name: 'FUNCTION_TYPED_PARAMETER_VAR',
  problemMessage:
      "Function-typed parameters can't specify 'const', 'final' or 'var' in "
      "place of a return type.",
  correctionMessage: "Try replacing the keyword with a return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.FUNCTION_TYPED_PARAMETER_VAR',
  expectedTypes: [],
);

/// It is a compile-time error if a generic function type is used as a bound
/// for a formal type parameter of a class or a function.
///
/// No parameters.
const DiagnosticWithoutArguments
genericFunctionTypeCannotBeBound = DiagnosticWithoutArgumentsImpl(
  name: 'GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
  problemMessage:
      "Generic function types can't be used as type parameter bounds.",
  correctionMessage:
      "Try making the free variable in the function type part of the larger "
      "declaration signature.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND',
  expectedTypes: [],
);

/// It is a compile-time error if a generic function type is used as an actual
/// type argument.
///
/// No parameters.
const DiagnosticWithoutArguments
genericFunctionTypeCannotBeTypeArgument = DiagnosticWithoutArgumentsImpl(
  name: 'GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
  problemMessage: "A generic function type can't be a type argument.",
  correctionMessage:
      "Try removing type parameters from the generic function type, or using "
      "'dynamic' as the type argument here.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
genericMethodTypeInstantiationOnDynamic = DiagnosticWithoutArgumentsImpl(
  name: 'GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
  problemMessage:
      "A method tear-off on a receiver whose type is 'dynamic' can't have type "
      "arguments.",
  correctionMessage:
      "Specify the type of the receiver, or remove the type arguments from "
      "the method tear-off.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.GENERIC_METHOD_TYPE_INSTANTIATION_ON_DYNAMIC',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the struct class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
genericStructSubclass = DiagnosticWithArguments(
  name: 'GENERIC_STRUCT_SUBCLASS',
  problemMessage:
      "The class '{0}' can't extend 'Struct' or 'Union' because '{0}' is "
      "generic.",
  correctionMessage: "Try removing the type parameters from '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.GENERIC_STRUCT_SUBCLASS',
  withArguments: _withArgumentsGenericStructSubclass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments getterConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'GETTER_CONSTRUCTOR',
      problemMessage: "Constructors can't be a getter.",
      correctionMessage: "Try removing 'get'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.GETTER_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments getterInFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'GETTER_IN_FUNCTION',
      problemMessage: "Getters can't be defined within methods or functions.",
      correctionMessage:
          "Try moving the getter outside the method or function, or converting "
          "the getter to a function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.GETTER_IN_FUNCTION',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the getter
/// Object p1: the type of the getter
/// Object p2: the type of the setter
/// Object p3: the name of the setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
getterNotAssignableSetterTypes = DiagnosticWithArguments(
  name: 'GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
  problemMessage:
      "The return type of getter '{0}' is '{1}' which isn't assignable to the "
      "type '{2}' of its setter '{3}'.",
  correctionMessage: "Try changing the types so that they are compatible.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.GETTER_NOT_ASSIGNABLE_SETTER_TYPES',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
getterNotSubtypeSetterTypes = DiagnosticWithArguments(
  name: 'GETTER_NOT_SUBTYPE_SETTER_TYPES',
  problemMessage:
      "The return type of getter '{0}' is '{1}' which isn't a subtype of the "
      "type '{2}' of its setter '{3}'.",
  correctionMessage: "Try changing the types so that they are compatible.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.GETTER_NOT_SUBTYPE_SETTER_TYPES',
  withArguments: _withArgumentsGetterNotSubtypeSetterTypes,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments getterWithParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'GETTER_WITH_PARAMETERS',
      problemMessage: "Getters must be declared without a parameter list.",
      correctionMessage:
          "Try removing the parameter list, or removing the keyword 'get' to "
          "define a method rather than a getter.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.GETTER_WITH_PARAMETERS',
      expectedTypes: [],
    );

/// A TODO comment marked as HACK.
///
/// Parameters:
/// String message: the user-supplied problem message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
hack = DiagnosticWithArguments(
  name: 'HACK',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'TodoCode.HACK',
  withArguments: _withArgumentsHack,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
ifElementConditionFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as values in an if "
      "condition inside a const collection literal.",
  correctionMessage: "Try making the deferred import non-deferred.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IF_ELEMENT_CONDITION_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments illegalAssignmentToNonAssignable =
    DiagnosticWithoutArgumentsImpl(
      name: 'ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
      problemMessage: "Illegal assignment to non-assignable expression.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ILLEGAL_ASSIGNMENT_TO_NON_ASSIGNABLE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
illegalAsyncGeneratorReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
  problemMessage:
      "Functions marked 'async*' must have a return type that is a supertype of "
      "'Stream<T>' for some type 'T'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'async*' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
illegalAsyncReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'ILLEGAL_ASYNC_RETURN_TYPE',
  problemMessage:
      "Functions marked 'async' must have a return type which is a supertype of "
      "'Future'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'async' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_ASYNC_RETURN_TYPE',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the illegal character
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
illegalCharacter = DiagnosticWithArguments(
  name: 'ILLEGAL_CHARACTER',
  problemMessage: "Illegal character '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.ILLEGAL_CHARACTER',
  withArguments: _withArgumentsIllegalCharacter,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of member that cannot be declared
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
illegalConcreteEnumMemberDeclaration = DiagnosticWithArguments(
  name: 'ILLEGAL_CONCRETE_ENUM_MEMBER',
  problemMessage:
      "A concrete instance member named '{0}' can't be declared in a class that "
      "implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION',
  withArguments: _withArgumentsIllegalConcreteEnumMemberDeclaration,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of member that cannot be inherited
/// String p1: the name of the class that declares the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
illegalConcreteEnumMemberInheritance = DiagnosticWithArguments(
  name: 'ILLEGAL_CONCRETE_ENUM_MEMBER',
  problemMessage:
      "A concrete instance member named '{0}' can't be inherited from '{1}' in a "
      "class that implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_INHERITANCE',
  withArguments: _withArgumentsIllegalConcreteEnumMemberInheritance,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments illegalEnumValuesDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'ILLEGAL_ENUM_VALUES',
      problemMessage:
          "An instance member named 'values' can't be declared in a class that "
          "implements 'Enum'.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_DECLARATION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the class that declares 'values'
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
illegalEnumValuesInheritance = DiagnosticWithArguments(
  name: 'ILLEGAL_ENUM_VALUES',
  problemMessage:
      "An instance member named 'values' can't be inherited from '{0}' in a "
      "class that implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_ENUM_VALUES_INHERITANCE',
  withArguments: _withArgumentsIllegalEnumValuesInheritance,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the required language version
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
illegalLanguageVersionOverride = DiagnosticWithArguments(
  name: 'ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
  problemMessage: "The language version must be {0}.",
  correctionMessage:
      "Try removing the language version override and migrating the code.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_LANGUAGE_VERSION_OVERRIDE',
  withArguments: _withArgumentsIllegalLanguageVersionOverride,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode illegalPatternAssignmentVariableName =
    DiagnosticCodeWithExpectedTypes(
      name: 'ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
      problemMessage:
          "A variable assigned by a pattern assignment can't be named '{0}'.",
      correctionMessage: "Choose a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_ASSIGNMENT_VARIABLE_NAME',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode illegalPatternIdentifierName =
    DiagnosticCodeWithExpectedTypes(
      name: 'ILLEGAL_PATTERN_IDENTIFIER_NAME',
      problemMessage: "A pattern can't refer to an identifier named '{0}'.",
      correctionMessage: "Match the identifier using '==",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_IDENTIFIER_NAME',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode illegalPatternVariableName =
    DiagnosticCodeWithExpectedTypes(
      name: 'ILLEGAL_PATTERN_VARIABLE_NAME',
      problemMessage:
          "The variable declared by a variable pattern can't be named '{0}'.",
      correctionMessage: "Choose a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.ILLEGAL_PATTERN_VARIABLE_NAME',
      expectedTypes: [ExpectedType.token],
    );

/// No parameters.
const DiagnosticWithoutArguments
illegalSyncGeneratorReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
  problemMessage:
      "Functions marked 'sync*' must have a return type that is a supertype of "
      "'Iterable<T>' for some type 'T'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'sync*' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'IMPLEMENTS_BEFORE_EXTENDS',
      problemMessage:
          "The extends clause must be before the implements clause.",
      correctionMessage:
          "Try moving the extends clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_EXTENDS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeOn =
    DiagnosticWithoutArgumentsImpl(
      name: 'IMPLEMENTS_BEFORE_ON',
      problemMessage: "The on clause must be before the implements clause.",
      correctionMessage:
          "Try moving the on clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_ON',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'IMPLEMENTS_BEFORE_WITH',
      problemMessage: "The with clause must be before the implements clause.",
      correctionMessage:
          "Try moving the with clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.IMPLEMENTS_BEFORE_WITH',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUBTYPE_OF_DEFERRED_CLASS',
      problemMessage: "Classes and mixins can't implement deferred classes.",
      correctionMessage:
          "Try specifying a different interface, removing the class from the "
          "list, or changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
implementsDisallowedClass = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_DISALLOWED_TYPE',
  problemMessage: "Classes and mixins can't implement '{0}'.",
  correctionMessage:
      "Try specifying a different interface, or remove the class from the "
      "list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS',
  withArguments: _withArgumentsImplementsDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments implementsNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'IMPLEMENTS_NON_CLASS',
      problemMessage:
          "Classes and mixins can only implement other classes and mixins.",
      correctionMessage:
          "Try specifying a class or mixin, or remove the name from the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.IMPLEMENTS_NON_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the interface that is implemented more than once
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
implementsRepeated = DiagnosticWithArguments(
  name: 'IMPLEMENTS_REPEATED',
  problemMessage: "'{0}' can only be implemented once.",
  correctionMessage: "Try removing all but one occurrence of the class name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPLEMENTS_REPEATED',
  withArguments: _withArgumentsImplementsRepeated,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Element p0: the name of the class that appears in both "extends" and
///             "implements" clauses
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element p0})
>
implementsSuperClass = DiagnosticWithArguments(
  name: 'IMPLEMENTS_SUPER_CLASS',
  problemMessage:
      "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
  correctionMessage: "Try removing one of the occurrences.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS',
  withArguments: _withArgumentsImplementsSuperClass,
  expectedTypes: [ExpectedType.element],
);

/// No parameters.
const DiagnosticWithoutArguments
implementsTypeAliasExpandsToTypeParameter = DiagnosticWithoutArgumentsImpl(
  name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
  problemMessage:
      "A type alias that expands to a type parameter can't be implemented.",
  correctionMessage: "Try specifying a class or mixin, or removing the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.IMPLEMENTS_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
implicitSuperInitializerMissingArguments = DiagnosticWithArguments(
  name: 'IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
  problemMessage:
      "The implicitly invoked unnamed constructor from '{0}' has required "
      "parameters.",
  correctionMessage:
      "Try adding an explicit super parameter with the required arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.IMPLICIT_SUPER_INITIALIZER_MISSING_ARGUMENTS',
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the instance member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
implicitThisReferenceInInitializer = DiagnosticWithArguments(
  name: 'IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
  problemMessage:
      "The instance member '{0}' can't be accessed in an initializer.",
  correctionMessage:
      "Try replacing the reference to the instance member with a different "
      "expression",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER',
  withArguments: _withArgumentsImplicitThisReferenceInInitializer,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
importDeferredLibraryWithLoadFunction = DiagnosticWithoutArgumentsImpl(
  name: 'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
  problemMessage:
      "The imported library defines a top-level function named 'loadLibrary' "
      "that is hidden by deferring this library.",
  correctionMessage:
      "Try changing the import to not be deferred, or rename the function in "
      "the imported library.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments importDirectiveAfterPartDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
      problemMessage: "Import directives must precede part directives.",
      correctionMessage:
          "Try moving the import directives before the part directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.IMPORT_DIRECTIVE_AFTER_PART_DIRECTIVE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the URI pointing to a library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
importInternalLibrary = DiagnosticWithArguments(
  name: 'IMPORT_INTERNAL_LIBRARY',
  problemMessage: "The library '{0}' is internal and can't be imported.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY',
  withArguments: _withArgumentsImportInternalLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
importOfNonLibrary = DiagnosticWithArguments(
  name: 'IMPORT_OF_NON_LIBRARY',
  problemMessage: "The imported library '{0}' can't have a part-of directive.",
  correctionMessage: "Try importing the library that the part is a part of.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY',
  withArguments: _withArgumentsImportOfNonLibrary,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating that there is a syntactic error in the included
/// file.
///
/// Parameters:
/// Object p0: the path of the file containing the error
/// Object p1: the starting offset of the text in the file that contains the
///            error
/// Object p2: the ending offset of the text in the file that contains the
///            error
/// Object p3: the error message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
includedFileParseError = DiagnosticWithArguments(
  name: 'INCLUDED_FILE_PARSE_ERROR',
  problemMessage: "{3} in {0}({1}..{2})",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'AnalysisOptionsErrorCode.INCLUDED_FILE_PARSE_ERROR',
  withArguments: _withArgumentsIncludedFileParseError,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// An error code indicating a specified include file has a warning.
///
/// Parameters:
/// Object p0: the path of the file containing the warnings
/// Object p1: the starting offset of the text in the file that contains the
///            warning
/// Object p2: the ending offset of the text in the file that contains the
///            warning
/// Object p3: the warning message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
includedFileWarning = DiagnosticWithArguments(
  name: 'INCLUDED_FILE_WARNING',
  problemMessage: "Warning in the included options file {0}({1}..{2}): {3}",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INCLUDED_FILE_WARNING',
  withArguments: _withArgumentsIncludedFileWarning,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// An error code indicating a specified include file could not be found.
///
/// Parameters:
/// Object p0: the URI of the file to be included
/// Object p1: the path of the file containing the include directive
/// Object p2: the path of the context being analyzed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
includeFileNotFound = DiagnosticWithArguments(
  name: 'INCLUDE_FILE_NOT_FOUND',
  problemMessage:
      "The include file '{0}' in '{1}' can't be found when analyzing '{2}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INCLUDE_FILE_NOT_FOUND',
  withArguments: _withArgumentsIncludeFileNotFound,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// An error code indicating an incompatible rule.
///
/// The incompatible rules must be included by context messages.
///
/// Parameters:
/// String p0: the rule name
/// String p1: the incompatible rules
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
incompatibleLint = DiagnosticWithArguments(
  name: 'INCOMPATIBLE_LINT',
  problemMessage: "The rule '{0}' is incompatible with {1}.",
  correctionMessage: "Try removing all but one of the incompatible rules.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INCOMPATIBLE_LINT',
  withArguments: _withArgumentsIncompatibleLint,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating an incompatible rule.
///
/// The files that enable the referenced rules must be included by context messages.
///
/// Parameters:
/// String p0: the rule name
/// String p1: the incompatible rules
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
incompatibleLintFiles = DiagnosticWithArguments(
  name: 'INCOMPATIBLE_LINT',
  problemMessage: "The rule '{0}' is incompatible with {1}.",
  correctionMessage:
      "Try locally disabling all but one of the conflicting rules or "
      "removing one of the incompatible files.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INCOMPATIBLE_LINT_FILES',
  withArguments: _withArgumentsIncompatibleLintFiles,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating an incompatible rule.
///
/// Parameters:
/// String p0: the rule name
/// String p1: the incompatible rules
/// int p2: the number of files that include the incompatible rule
/// String p3: plural suffix for the word "file"
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required int p2,
    required String p3,
  })
>
incompatibleLintIncluded = DiagnosticWithArguments(
  name: 'INCOMPATIBLE_LINT',
  problemMessage:
      "The rule '{0}' is incompatible with {1}, which is included from {2} "
      "file{3}.",
  correctionMessage:
      "Try locally disabling all but one of the conflicting rules or "
      "removing one of the incompatible files.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INCOMPATIBLE_LINT_INCLUDED',
  withArguments: _withArgumentsIncompatibleLintIncluded,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.int,
    ExpectedType.string,
  ],
);

/// 13.9 Switch: It is a compile-time error if values of the expressions
/// <i>e<sub>k</sub></i> are not instances of the same class <i>C</i>, for all
/// <i>1 &lt;= k &lt;= n</i>.
///
/// Parameters:
/// Object p0: the expression source code that is the unexpected type
/// Object p1: the name of the expected type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
inconsistentCaseExpressionTypes = DiagnosticWithArguments(
  name: 'INCONSISTENT_CASE_EXPRESSION_TYPES',
  problemMessage:
      "Case expressions must have the same types, '{0}' isn't a '{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES',
  withArguments: _withArgumentsInconsistentCaseExpressionTypes,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the instance member with inconsistent inheritance.
/// String p1: the list of all inherited signatures for this member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
inconsistentInheritance = DiagnosticWithArguments(
  name: 'INCONSISTENT_INHERITANCE',
  problemMessage: "Superinterfaces don't have a valid override for '{0}': {1}.",
  correctionMessage:
      "Try adding an explicit override that is consistent with all of the "
      "inherited members.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INCONSISTENT_INHERITANCE',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
inconsistentInheritanceGetterAndMethod = DiagnosticWithArguments(
  name: 'INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
  problemMessage:
      "'{0}' is inherited as a getter (from '{1}') and also a method (from "
      "'{2}').",
  correctionMessage:
      "Try adjusting the supertypes of this class to remove the "
      "inconsistency.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INCONSISTENT_INHERITANCE_GETTER_AND_METHOD',
  withArguments: _withArgumentsInconsistentInheritanceGetterAndMethod,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments inconsistentLanguageVersionOverride =
    DiagnosticWithoutArgumentsImpl(
      name: 'INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
      problemMessage:
          "Parts must have exactly the same language version override as the "
          "library.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inconsistentPatternVariableLogicalOr = DiagnosticWithArguments(
  name: 'INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR',
  problemMessage:
      "The variable '{0}' has a different type and/or finality in this branch of "
      "the logical-or pattern.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "both branches.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR',
  withArguments: _withArgumentsInconsistentPatternVariableLogicalOr,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, collection literal types must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String p0: the name of the collection
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnCollectionLiteral = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
  problemMessage: "The type argument(s) of '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_COLLECTION_LITERAL',
  withArguments: _withArgumentsInferenceFailureOnCollectionLiteral,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in function invocations must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String p0: the name of the function
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnFunctionInvocation = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
  problemMessage:
      "The type argument(s) of the function '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_FUNCTION_INVOCATION',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnFunctionReturnType = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
  problemMessage: "The return type of '{0}' can't be inferred.",
  correctionMessage: "Declare the return type of '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_FUNCTION_RETURN_TYPE',
  withArguments: _withArgumentsInferenceFailureOnFunctionReturnType,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in function invocations must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnGenericInvocation = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
  problemMessage:
      "The type argument(s) of the generic function type '{0}' can't be "
      "inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_GENERIC_INVOCATION',
  withArguments: _withArgumentsInferenceFailureOnGenericInvocation,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in instance creation
/// (constructor calls) must be inferred via the context type, or have type
/// arguments.
///
/// Parameters:
/// String p0: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnInstanceCreation = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_INSTANCE_CREATION',
  problemMessage:
      "The type argument(s) of the constructor '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_INSTANCE_CREATION',
  withArguments: _withArgumentsInferenceFailureOnInstanceCreation,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" in enabled, uninitialized variables must be
/// declared with a specific type.
///
/// Parameters:
/// String p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnUninitializedVariable = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
  problemMessage:
      "The type of {0} can't be inferred without either a type or initializer.",
  correctionMessage: "Try specifying the type of the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_UNINITIALIZED_VARIABLE',
  withArguments: _withArgumentsInferenceFailureOnUninitializedVariable,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" in enabled, function parameters must be
/// declared with a specific type, or inherit a type.
///
/// Parameters:
/// String p0: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
inferenceFailureOnUntypedParameter = DiagnosticWithArguments(
  name: 'INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
  problemMessage:
      "The type of {0} can't be inferred; a type must be explicitly provided.",
  correctionMessage: "Try specifying the type of the parameter.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INFERENCE_FAILURE_ON_UNTYPED_PARAMETER',
  withArguments: _withArgumentsInferenceFailureOnUntypedParameter,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments initializedVariableInForEach =
    DiagnosticWithoutArgumentsImpl(
      name: 'INITIALIZED_VARIABLE_IN_FOR_EACH',
      problemMessage:
          "The loop variable in a for-each loop can't be initialized.",
      correctionMessage:
          "Try removing the initializer, or using a different kind of loop.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INITIALIZED_VARIABLE_IN_FOR_EACH',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the initializing formal that is not an instance
///            variable in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
initializerForNonExistentField = DiagnosticWithArguments(
  name: 'INITIALIZER_FOR_NON_EXISTENT_FIELD',
  problemMessage: "'{0}' isn't a field in the enclosing class.",
  correctionMessage:
      "Try correcting the name to match an existing field, or defining a "
      "field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD',
  withArguments: _withArgumentsInitializerForNonExistentField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the initializing formal that is a static variable
///            in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
initializerForStaticField = DiagnosticWithArguments(
  name: 'INITIALIZER_FOR_STATIC_FIELD',
  problemMessage:
      "'{0}' is a static field in the enclosing class. Fields initialized in a "
      "constructor can't be static.",
  correctionMessage: "Try removing the initialization.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD',
  withArguments: _withArgumentsInitializerForStaticField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the initializing formal that is not an instance
///            variable in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
initializingFormalForNonExistentField = DiagnosticWithArguments(
  name: 'INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
  problemMessage: "'{0}' isn't a field in the enclosing class.",
  correctionMessage:
      "Try correcting the name to match an existing field, or defining a "
      "field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  })
>
instanceAccessToStaticMember = DiagnosticWithArguments(
  name: 'INSTANCE_ACCESS_TO_STATIC_MEMBER',
  problemMessage: "The static {1} '{0}' can't be accessed through an instance.",
  correctionMessage: "Try using the {3} '{2}' to access the {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
instanceAccessToStaticMemberOfUnnamedExtension = DiagnosticWithArguments(
  name: 'INSTANCE_ACCESS_TO_STATIC_MEMBER',
  problemMessage: "The static {1} '{0}' can't be accessed through an instance.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER_OF_UNNAMED_EXTENSION',
  withArguments: _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments instanceMemberAccessFromFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
      problemMessage:
          "Instance members can't be accessed from a factory constructor.",
      correctionMessage: "Try removing the reference to the instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instanceMemberAccessFromStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'INSTANCE_MEMBER_ACCESS_FROM_STATIC',
      problemMessage:
          "Instance members can't be accessed from a static method.",
      correctionMessage:
          "Try removing the reference to the instance member, or removing the "
          "keyword 'static' from the method.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instantiateAbstractClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'INSTANTIATE_ABSTRACT_CLASS',
      problemMessage: "Abstract classes can't be instantiated.",
      correctionMessage: "Try creating an instance of a concrete subtype.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INSTANTIATE_ABSTRACT_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instantiateEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'INSTANTIATE_ENUM',
      problemMessage: "Enums can't be instantiated.",
      correctionMessage: "Try using one of the defined constants.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INSTANTIATE_ENUM',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
instantiateTypeAliasExpandsToTypeParameter = DiagnosticWithoutArgumentsImpl(
  name: 'INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  problemMessage:
      "Type aliases that expand to a type parameter can't be instantiated.",
  correctionMessage: "Try replacing it with a class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INSTANTIATE_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the lexeme of the integer
/// String p1: the closest valid double
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
integerLiteralImpreciseAsDouble = DiagnosticWithArguments(
  name: 'INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
  problemMessage:
      "The integer literal is being used as a double, but can't be represented "
      "as a 64-bit double without overflow or loss of precision: '{0}'.",
  correctionMessage:
      "Try using the class 'BigInt', or switch to the closest valid double: "
      "'{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE',
  withArguments: _withArgumentsIntegerLiteralImpreciseAsDouble,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the value of the literal
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
integerLiteralOutOfRange = DiagnosticWithArguments(
  name: 'INTEGER_LITERAL_OUT_OF_RANGE',
  problemMessage: "The integer literal {0} can't be represented in 64 bits.",
  correctionMessage:
      "Try using the 'BigInt' class if you need an integer larger than "
      "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE',
  withArguments: _withArgumentsIntegerLiteralOutOfRange,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the interface class being extended.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
interfaceClassExtendedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be extended outside of its library because it's an "
      "interface class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INTERFACE_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments interfaceEnum = DiagnosticWithoutArgumentsImpl(
  name: 'INTERFACE_ENUM',
  problemMessage: "Enums can't be declared to be 'interface'.",
  correctionMessage: "Try removing the keyword 'interface'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INTERFACE_ENUM',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments interfaceMixin =
    DiagnosticWithoutArgumentsImpl(
      name: 'INTERFACE_MIXIN',
      problemMessage: "A mixin can't be declared 'interface'.",
      correctionMessage: "Try removing the 'interface' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INTERFACE_MIXIN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments interfaceMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'INTERFACE_MIXIN_CLASS',
      problemMessage: "A mixin class can't be declared 'interface'.",
      correctionMessage: "Try removing the 'interface' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INTERFACE_MIXIN_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_ANNOTATION',
  problemMessage:
      "Annotation must be either a const variable reference or const constructor "
      "invocation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotationConstantValueFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used in annotations.",
  correctionMessage:
      "Try moving the constant from the deferred library, or removing "
      "'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INVALID_ANNOTATION_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotationFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as annotations.",
  correctionMessage:
      "Try removing the annotation, or changing the import to not be "
      "deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the annotation
/// String p1: the list of valid targets
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidAnnotationTarget = DiagnosticWithArguments(
  name: 'INVALID_ANNOTATION_TARGET',
  problemMessage: "The annotation '{0}' can only be used on {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_ANNOTATION_TARGET',
  withArguments: _withArgumentsInvalidAnnotationTarget,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the right hand side type
/// Type p1: the name of the left hand side type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
invalidAssignment = DiagnosticWithArguments(
  name: 'INVALID_ASSIGNMENT',
  problemMessage:
      "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
  correctionMessage:
      "Try changing the type of the variable, or casting the right-hand type "
      "to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_ASSIGNMENT',
  withArguments: _withArgumentsInvalidAssignment,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments invalidAwaitInFor =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_AWAIT_IN_FOR',
      problemMessage:
          "The keyword 'await' isn't allowed for a normal 'for' statement.",
      correctionMessage:
          "Try removing the keyword, or use a for-each statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_AWAIT_IN_FOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidAwaitNotRequiredAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_AWAIT_NOT_REQUIRED_ANNOTATION',
      problemMessage:
          "The annotation 'awaitNotRequired' can only be applied to a "
          "Future-returning function, or a Future-typed field.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_AWAIT_NOT_REQUIRED_ANNOTATION',
      expectedTypes: [],
    );

/// This error is only reported in libraries which are not null safe.
///
/// Parameters:
/// Object p0: the name of the function
/// Object p1: the type of the function
/// Object p2: the expected function type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
invalidCastFunction = DiagnosticWithArguments(
  name: 'INVALID_CAST_FUNCTION',
  problemMessage:
      "The function '{0}' has type '{1}' that isn't of expected type '{2}'. This "
      "means its parameter or return type doesn't match what is expected.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_FUNCTION',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidCastFunctionExpr = DiagnosticWithArguments(
  name: 'INVALID_CAST_FUNCTION_EXPR',
  problemMessage:
      "The function expression type '{0}' isn't of type '{1}'. This means its "
      "parameter or return type doesn't match what is expected. Consider "
      "changing parameter type(s) or the returned type(s).",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_FUNCTION_EXPR',
  withArguments: _withArgumentsInvalidCastFunctionExpr,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// This error is only reported in libraries which are not null safe.
///
/// Parameters:
/// Object p0: the lexeme of the literal
/// Object p1: the type of the literal
/// Object p2: the expected type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
invalidCastLiteral = DiagnosticWithArguments(
  name: 'INVALID_CAST_LITERAL',
  problemMessage:
      "The literal '{0}' with type '{1}' isn't of expected type '{2}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_LITERAL',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidCastLiteralList = DiagnosticWithArguments(
  name: 'INVALID_CAST_LITERAL_LIST',
  problemMessage:
      "The list literal type '{0}' isn't of expected type '{1}'. The list's type "
      "can be changed with an explicit generic type argument or by changing "
      "the element types.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_LIST',
  withArguments: _withArgumentsInvalidCastLiteralList,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// This error is only reported in libraries which are not null safe.
///
/// Parameters:
/// Object p0: the type of the map literal
/// Object p1: the expected type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidCastLiteralMap = DiagnosticWithArguments(
  name: 'INVALID_CAST_LITERAL_MAP',
  problemMessage:
      "The map literal type '{0}' isn't of expected type '{1}'. The map's type "
      "can be changed with an explicit generic type arguments or by changing "
      "the key and value types.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_MAP',
  withArguments: _withArgumentsInvalidCastLiteralMap,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// This error is only reported in libraries which are not null safe.
///
/// Parameters:
/// Object p0: the type of the set literal
/// Object p1: the expected type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidCastLiteralSet = DiagnosticWithArguments(
  name: 'INVALID_CAST_LITERAL_SET',
  problemMessage:
      "The set literal type '{0}' isn't of expected type '{1}'. The set's type "
      "can be changed with an explicit generic type argument or by changing "
      "the element types.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_LITERAL_SET',
  withArguments: _withArgumentsInvalidCastLiteralSet,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// This error is only reported in libraries which are not null safe.
///
/// Parameters:
/// Object p0: the name of the torn-off method
/// Object p1: the type of the torn-off method
/// Object p2: the expected function type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
invalidCastMethod = DiagnosticWithArguments(
  name: 'INVALID_CAST_METHOD',
  problemMessage:
      "The method tear-off '{0}' has type '{1}' that isn't of expected type "
      "'{2}'. This means its parameter or return type doesn't match what is "
      "expected.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_METHOD',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidCastNewExpr = DiagnosticWithArguments(
  name: 'INVALID_CAST_NEW_EXPR',
  problemMessage:
      "The constructor returns type '{0}' that isn't of expected type '{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_CAST_NEW_EXPR',
  withArguments: _withArgumentsInvalidCastNewExpr,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// String p0: the invalid escape sequence
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidCodePoint = DiagnosticWithArguments(
  name: 'INVALID_CODE_POINT',
  problemMessage: "The escape sequence '{0}' isn't a valid code point.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_CODE_POINT',
  withArguments: _withArgumentsInvalidCodePoint,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidCommentReference = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_COMMENT_REFERENCE',
  problemMessage:
      "Comment references should contain a possibly prefixed identifier and can "
      "start with 'new', but shouldn't contain anything else.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_COMMENT_REFERENCE',
  expectedTypes: [],
);

/// TODO(brianwilkerson): Remove this when we have decided on how to report
/// errors in compile-time constants. Until then, this acts as a placeholder
/// for more informative errors.
///
/// See TODOs in ConstantVisitor
///
/// No parameters.
const DiagnosticWithoutArguments invalidConstant =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_CONSTANT',
      problemMessage: "Invalid constant value.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_CONSTANT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstantConstPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_CONSTANT_CONST_PREFIX',
  problemMessage:
      "The expression can't be prefixed by 'const' to form a constant pattern.",
  correctionMessage: "Try wrapping the expression in 'const ( ... )' instead.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_CONSTANT_CONST_PREFIX',
  expectedTypes: [],
);

/// Parameters:
/// Name name: undocumented
const DiagnosticCode invalidConstantPatternBinary =
    DiagnosticCodeWithExpectedTypes(
      name: 'INVALID_CONSTANT_PATTERN_BINARY',
      problemMessage:
          "The binary operator {0} is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_BINARY',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternDuplicateConst =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
      problemMessage: "Duplicate 'const' keyword in constant expression.",
      correctionMessage: "Try removing one of the 'const' keywords.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_DUPLICATE_CONST',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternEmptyRecordLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
      problemMessage:
          "The empty record literal is not supported as a constant pattern.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName:
          'ParserErrorCode.INVALID_CONSTANT_PATTERN_EMPTY_RECORD_LITERAL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternGeneric =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_CONSTANT_PATTERN_GENERIC',
      problemMessage: "This expression is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_GENERIC',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstantPatternNegation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_CONSTANT_PATTERN_NEGATION',
  problemMessage:
      "Only negation of a numeric literal is supported as a constant pattern.",
  correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_NEGATION',
  expectedTypes: [],
);

/// Parameters:
/// Name name: undocumented
const DiagnosticCode invalidConstantPatternUnary =
    DiagnosticCodeWithExpectedTypes(
      name: 'INVALID_CONSTANT_PATTERN_UNARY',
      problemMessage:
          "The unary operator {0} is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_CONSTANT_PATTERN_UNARY',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstructorName = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_CONSTRUCTOR_NAME',
  problemMessage:
      "The name of a constructor must match the name of the enclosing class.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_CONSTRUCTOR_NAME',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the kind of dependency.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidDependency = DiagnosticWithArguments(
  name: 'INVALID_DEPENDENCY',
  problemMessage: "Publishable packages can't have '{0}' dependencies.",
  correctionMessage:
      "Try adding a 'publish_to: none' entry to mark the package as not for "
      "publishing or remove the {0} dependency.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.INVALID_DEPENDENCY',
  withArguments: _withArgumentsInvalidDependency,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedExtendAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_DEPRECATED_EXTEND_ANNOTATION',
  problemMessage:
      "The annotation '@Deprecated.extend' can only be applied to extendable "
      "classes.",
  correctionMessage: "Try removing the '@Deprecated.extend' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_DEPRECATED_EXTEND_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidDeprecatedImplementAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_DEPRECATED_IMPLEMENT_ANNOTATION',
      problemMessage:
          "The annotation '@Deprecated.implement' can only be applied to "
          "implementable classes.",
      correctionMessage: "Try removing the '@Deprecated.implement' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_DEPRECATED_IMPLEMENT_ANNOTATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedInstantiateAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_DEPRECATED_INSTANTIATE_ANNOTATION',
  problemMessage:
      "The annotation '@Deprecated.instantiate' can only be applied to classes.",
  correctionMessage: "Try removing the '@Deprecated.instantiate' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_DEPRECATED_INSTANTIATE_ANNOTATION',
  expectedTypes: [],
);

/// This warning is generated anywhere where `@Deprecated.mixin` annotates
/// something other than a mixin class.
///
/// No parameters.
const DiagnosticWithoutArguments invalidDeprecatedMixinAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_DEPRECATED_MIXIN_ANNOTATION',
      problemMessage:
          "The annotation '@Deprecated.mixin' can only be applied to classes.",
      correctionMessage: "Try removing the '@Deprecated.mixin' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_DEPRECATED_MIXIN_ANNOTATION',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@Deprecated.optional`
/// annotates something other than an optional parameter.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedOptionalAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_DEPRECATED_OPTIONAL_ANNOTATION',
  problemMessage:
      "The annotation '@Deprecated.optional' can only be applied to optional "
      "parameters.",
  correctionMessage: "Try removing the '@Deprecated.optional' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_DEPRECATED_OPTIONAL_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedSubclassAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_DEPRECATED_SUBCLASS_ANNOTATION',
  problemMessage:
      "The annotation '@Deprecated.subclass' can only be applied to subclassable "
      "classes and mixins.",
  correctionMessage: "Try removing the '@Deprecated.subclass' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_DEPRECATED_SUBCLASS_ANNOTATION',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidExceptionValue = DiagnosticWithArguments(
  name: 'INVALID_EXCEPTION_VALUE',
  problemMessage:
      "The method {0} can't have an exceptional return value (the second "
      "argument) when the return type of the function is either 'void', "
      "'Handle' or 'Pointer'.",
  correctionMessage: "Try removing the exceptional return value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.INVALID_EXCEPTION_VALUE',
  withArguments: _withArgumentsInvalidExceptionValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidExportOfInternalElement = DiagnosticWithArguments(
  name: 'INVALID_EXPORT_OF_INTERNAL_ELEMENT',
  problemMessage:
      "The member '{0}' can't be exported as a part of a package's public API.",
  correctionMessage: "Try using a hide clause to hide '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT',
  withArguments: _withArgumentsInvalidExportOfInternalElement,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the internal element
/// String p1: the name of the exported element that indirectly exposes the
///            internal element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidExportOfInternalElementIndirectly = DiagnosticWithArguments(
  name: 'INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
  problemMessage:
      "The member '{0}' can't be exported as a part of a package's public API, "
      "but is indirectly exported as part of the signature of '{1}'.",
  correctionMessage: "Try using a hide clause to hide '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_EXPORT_OF_INTERNAL_ELEMENT_INDIRECTLY',
  withArguments: _withArgumentsInvalidExportOfInternalElementIndirectly,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidExtensionArgumentCount = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_EXTENSION_ARGUMENT_COUNT',
  problemMessage:
      "Extension overrides must have exactly one argument: the value of 'this' "
      "in the extension method.",
  correctionMessage: "Try specifying exactly one argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_EXTENSION_ARGUMENT_COUNT',
  expectedTypes: [],
);

/// Parameters:
/// String p0: The name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidFactoryMethodDecl = DiagnosticWithArguments(
  name: 'INVALID_FACTORY_METHOD_DECL',
  problemMessage: "Factory method '{0}' must have a return type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_FACTORY_METHOD_DECL',
  withArguments: _withArgumentsInvalidFactoryMethodDecl,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidFactoryMethodImpl = DiagnosticWithArguments(
  name: 'INVALID_FACTORY_METHOD_IMPL',
  problemMessage:
      "Factory method '{0}' doesn't return a newly allocated object.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_FACTORY_METHOD_IMPL',
  withArguments: _withArgumentsInvalidFactoryMethodImpl,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidFactoryNameNotAClass = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_FACTORY_NAME_NOT_A_CLASS',
  problemMessage:
      "The name of a factory constructor must be the same as the name of the "
      "immediately enclosing class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidFieldNameFromObject =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_FIELD_NAME',
      problemMessage:
          "Record field names can't be the same as a member from 'Object'.",
      correctionMessage: "Try using a different name for the field.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_FIELD_NAME_FROM_OBJECT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidFieldNamePositional = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_FIELD_NAME',
  problemMessage:
      "Record field names can't be a dollar sign followed by an integer when the "
      "integer is the index of a positional field.",
  correctionMessage: "Try using a different name for the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_FIELD_NAME_POSITIONAL',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidFieldNamePrivate =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_FIELD_NAME',
      problemMessage: "Record field names can't be private.",
      correctionMessage: "Try removing the leading underscore.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_FIELD_NAME_PRIVATE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidFieldTypeInStruct = DiagnosticWithArguments(
  name: 'INVALID_FIELD_TYPE_IN_STRUCT',
  problemMessage:
      "Fields in struct classes can't have the type '{0}'. They can only be "
      "declared as 'int', 'double', 'Array', 'Pointer', or subtype of "
      "'Struct' or 'Union'.",
  correctionMessage:
      "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' "
      "or 'Union'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.INVALID_FIELD_TYPE_IN_STRUCT',
  withArguments: _withArgumentsInvalidFieldTypeInStruct,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidGenericFunctionType = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_GENERIC_FUNCTION_TYPE',
  problemMessage: "Invalid generic function type.",
  correctionMessage:
      "Try using a generic function type (returnType 'Function(' parameters "
      "')').",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_GENERIC_FUNCTION_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidHexEscape = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_HEX_ESCAPE',
  problemMessage:
      "An escape sequence starting with '\\x' must be followed by 2 hexadecimal "
      "digits.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_HEX_ESCAPE',
  expectedTypes: [],
);

/// The parameters of this error code must be kept in sync with those of
/// [diag.invalidOverride].
///
/// Parameters:
/// Object p0: the name of the declared member that is not a valid override.
/// Object p1: the name of the interface that declares the member.
/// Object p2: the type of the declared member in the interface.
/// Object p3: the name of the interface with the overridden member.
/// Object p4: the type of the overridden member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  })
>
invalidImplementationOverride = DiagnosticWithArguments(
  name: 'INVALID_IMPLEMENTATION_OVERRIDE',
  problemMessage:
      "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' "
      "('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE',
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
/// [diag.invalidOverride].
///
/// Parameters:
/// Object p0: the name of the declared setter that is not a valid override.
/// Object p1: the name of the interface that declares the setter.
/// Object p2: the type of the declared setter in the interface.
/// Object p3: the name of the interface with the overridden setter.
/// Object p4: the type of the overridden setter.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  })
>
invalidImplementationOverrideSetter = DiagnosticWithArguments(
  name: 'INVALID_IMPLEMENTATION_OVERRIDE',
  problemMessage:
      "The setter '{1}.{0}' ('{2}') isn't a valid concrete implementation of "
      "'{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_IMPLEMENTATION_OVERRIDE_SETTER',
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
const DiagnosticWithoutArguments invalidInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_INITIALIZER',
      problemMessage: "Not a valid initializer.",
      correctionMessage:
          "To initialize a field, use the syntax 'name = value'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidInlineFunctionType = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_INLINE_FUNCTION_TYPE',
  problemMessage:
      "Inline function types can't be used for parameters in a generic function "
      "type.",
  correctionMessage:
      "Try using a generic function type (returnType 'Function(' parameters "
      "')').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_INLINE_FUNCTION_TYPE',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidInsideUnaryPattern = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_INSIDE_UNARY_PATTERN',
  problemMessage:
      "This pattern cannot appear inside a unary pattern (cast pattern, null "
      "check pattern, or null assert pattern) without parentheses.",
  correctionMessage:
      "Try combining into a single pattern if possible, or enclose the inner "
      "pattern in parentheses.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_INSIDE_UNARY_PATTERN',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidInternalAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_INTERNAL_ANNOTATION',
  problemMessage:
      "Only public elements in a package's private API can be annotated as being "
      "internal.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_INTERNAL_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverrideAtSign =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
      problemMessage:
          "The Dart language version override number must begin with '@dart'.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_AT_SIGN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideEquals = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
  problemMessage:
      "The Dart language version override comment must be specified with an '=' "
      "character.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_EQUALS',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the latest major version
/// Object p1: the latest minor version
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidLanguageVersionOverrideGreater = DiagnosticWithArguments(
  name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
  problemMessage:
      "The language version override can't specify a version greater than the "
      "latest known language version: {0}.{1}.",
  correctionMessage: "Try removing the language version override.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_GREATER',
  withArguments: _withArgumentsInvalidLanguageVersionOverrideGreater,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideLocation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
  problemMessage:
      "The language version override must be specified before any declaration or "
      "directive.",
  correctionMessage:
      "Try moving the language version override to the top of the file.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOCATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideLowerCase = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
  problemMessage:
      "The Dart language version override comment must be specified with the "
      "word 'dart' in all lower case.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_LOWER_CASE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverrideNumber =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
      problemMessage:
          "The Dart language version override comment must be specified with a "
          "version number, like '2.0', after the '=' character.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_NUMBER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverridePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
      problemMessage:
          "The Dart language version override number can't be prefixed with a "
          "letter.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_PREFIX',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideTrailingCharacters =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
      problemMessage:
          "The Dart language version override comment can't be followed by any "
          "non-whitespace characters.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName:
          'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TRAILING_CHARACTERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideTwoSlashes = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_LANGUAGE_VERSION_OVERRIDE',
  problemMessage:
      "The Dart language version override comment must be specified with exactly "
      "two slashes.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_LANGUAGE_VERSION_OVERRIDE_TWO_SLASHES',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLiteralAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LITERAL_ANNOTATION',
      problemMessage:
          "Only const constructors can have the `@literal` annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_LITERAL_ANNOTATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidLiteralInConfiguration =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_LITERAL_IN_CONFIGURATION',
      problemMessage:
          "The literal in a configuration can't contain interpolation.",
      correctionMessage: "Try removing the interpolation expressions.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_LITERAL_IN_CONFIGURATION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the invalid modifier
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidModifierOnConstructor = DiagnosticWithArguments(
  name: 'INVALID_MODIFIER_ON_CONSTRUCTOR',
  problemMessage:
      "The modifier '{0}' can't be applied to the body of a constructor.",
  correctionMessage: "Try removing the modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR',
  withArguments: _withArgumentsInvalidModifierOnConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidModifierOnSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_MODIFIER_ON_SETTER',
      problemMessage: "Setters can't use 'async', 'async*', or 'sync*'.",
      correctionMessage: "Try removing the modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@nonVirtual` annotates something
/// other than a non-abstract instance member in a class or mixin.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidNonVirtualAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_NON_VIRTUAL_ANNOTATION',
  problemMessage:
      "The annotation '@nonVirtual' can only be applied to a concrete instance "
      "member.",
  correctionMessage: "Try removing '@nonVirtual'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_NON_VIRTUAL_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidNullAwareElement = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_NULL_AWARE_OPERATOR',
  problemMessage:
      "The element can't be null, so the null-aware operator '?' is unnecessary.",
  correctionMessage: "Try removing the operator '?'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.INVALID_NULL_AWARE_ELEMENT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidNullAwareMapEntryKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_NULL_AWARE_OPERATOR',
      problemMessage:
          "The map entry key can't be null, so the null-aware operator '?' is "
          "unnecessary.",
      correctionMessage: "Try removing the operator '?'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'StaticWarningCode.INVALID_NULL_AWARE_MAP_ENTRY_KEY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidNullAwareMapEntryValue = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_NULL_AWARE_OPERATOR',
  problemMessage:
      "The map entry value can't be null, so the null-aware operator '?' is "
      "unnecessary.",
  correctionMessage: "Try removing the operator '?'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.INVALID_NULL_AWARE_MAP_ENTRY_VALUE',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the null-aware operator that is invalid
/// String p1: the non-null-aware operator that can replace the invalid
///            operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidNullAwareOperator = DiagnosticWithArguments(
  name: 'INVALID_NULL_AWARE_OPERATOR',
  problemMessage:
      "The receiver can't be null, so the null-aware operator '{0}' is "
      "unnecessary.",
  correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.INVALID_NULL_AWARE_OPERATOR',
  withArguments: _withArgumentsInvalidNullAwareOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Object p0: the null-aware operator that is invalid
/// Object p1: the non-null-aware operator that can replace the invalid
///            operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
invalidNullAwareOperatorAfterShortCircuit = DiagnosticWithArguments(
  name: 'INVALID_NULL_AWARE_OPERATOR',
  problemMessage:
      "The receiver can't be 'null' because of short-circuiting, so the "
      "null-aware operator '{0}' can't be used.",
  correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName:
      'StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT',
  withArguments: _withArgumentsInvalidNullAwareOperatorAfterShortCircuit,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// 0: the operator that is invalid
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode invalidOperator = DiagnosticCodeWithExpectedTypes(
  name: 'INVALID_OPERATOR',
  problemMessage: "The string '{0}' isn't a user-definable operator.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_OPERATOR',
  expectedTypes: [ExpectedType.token],
);

/// Only generated by the old parser.
/// Replaced by INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER.
///
/// Parameters:
/// Object p0: the operator being applied to 'super'
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
invalidOperatorForSuper = DiagnosticWithArguments(
  name: 'INVALID_OPERATOR_FOR_SUPER',
  problemMessage: "The operator '{0}' can't be used with 'super'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_OPERATOR_FOR_SUPER',
  withArguments: _withArgumentsInvalidOperatorForSuper,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidOperatorQuestionmarkPeriodForSuper = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
  problemMessage:
      "The operator '?.' cannot be used with 'super' because 'super' cannot be "
      "null.",
  correctionMessage: "Try replacing '?.' with '.'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_OPERATOR_QUESTIONMARK_PERIOD_FOR_SUPER',
  expectedTypes: [],
);

/// An error code indicating that a plugin is being configured with an invalid
/// value for an option and a detail message is provided.
///
/// Parameters:
/// String p0: the option name
/// String p1: the detail message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidOption = DiagnosticWithArguments(
  name: 'INVALID_OPTION',
  problemMessage: "Invalid option specified for '{0}': {1}",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INVALID_OPTION',
  withArguments: _withArgumentsInvalidOption,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the declared member that is not a valid override.
/// String p1: the name of the interface that declares the member.
/// Type p2: the type of the declared member in the interface.
/// String p3: the name of the interface with the overridden member.
/// Type p4: the type of the overridden member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required DartType p2,
    required String p3,
    required DartType p4,
  })
>
invalidOverride = DiagnosticWithArguments(
  name: 'INVALID_OVERRIDE',
  problemMessage:
      "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_OVERRIDE',
  withArguments: _withArgumentsInvalidOverride,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.type,
    ExpectedType.string,
    ExpectedType.type,
  ],
);

/// This warning is generated anywhere where an instance member annotated with
/// `@nonVirtual` is overridden in a subclass.
///
/// Parameters:
/// String p0: the name of the member
/// String p1: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidOverrideOfNonVirtualMember = DiagnosticWithArguments(
  name: 'INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
  problemMessage:
      "The member '{0}' is declared non-virtual in '{1}' and can't be overridden "
      "in subclasses.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_OVERRIDE_OF_NON_VIRTUAL_MEMBER',
  withArguments: _withArgumentsInvalidOverrideOfNonVirtualMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Object p0: the name of the declared setter that is not a valid override.
/// Object p1: the name of the interface that declares the setter.
/// Object p2: the type of the declared setter in the interface.
/// Object p3: the name of the interface with the overridden setter.
/// Object p4: the type of the overridden setter.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
    required Object p4,
  })
>
invalidOverrideSetter = DiagnosticWithArguments(
  name: 'INVALID_OVERRIDE',
  problemMessage:
      "The setter '{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_OVERRIDE_SETTER',
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
const DiagnosticWithoutArguments invalidPlatformsField =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_PLATFORMS_FIELD',
      problemMessage:
          "The 'platforms' field must be a map with platforms as keys.",
      correctionMessage:
          "Try changing the 'platforms' field to a map with platforms as keys.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.INVALID_PLATFORMS_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidReferenceToGenerativeEnumConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
  problemMessage:
      "Generative enum constructors can only be used to create an enum constant.",
  correctionMessage: "Try using an enum value, or a factory constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidReferenceToGenerativeEnumConstructorTearoff = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR',
  problemMessage: "Generative enum constructors can't be torn off.",
  correctionMessage: "Try using an enum value, or a factory constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.INVALID_REFERENCE_TO_GENERATIVE_ENUM_CONSTRUCTOR_TEAROFF',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidReferenceToThis =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_REFERENCE_TO_THIS',
      problemMessage: "Invalid reference to 'this' expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@reopen` annotates a class which
/// did not reopen any type.
///
/// No parameters.
const DiagnosticWithoutArguments invalidReopenAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_REOPEN_ANNOTATION',
      problemMessage:
          "The annotation '@reopen' can only be applied to a class that opens "
          "capabilities that the supertype intentionally disallows.",
      correctionMessage: "Try removing the '@reopen' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.INVALID_REOPEN_ANNOTATION',
      expectedTypes: [],
    );

/// An error code indicating an invalid format for an options file section.
///
/// Parameters:
/// String p0: the section name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidSectionFormat = DiagnosticWithArguments(
  name: 'INVALID_SECTION_FORMAT',
  problemMessage: "Invalid format for the '{0}' section.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.INVALID_SECTION_FORMAT',
  withArguments: _withArgumentsInvalidSectionFormat,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidStarAfterAsync = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_STAR_AFTER_ASYNC',
  problemMessage:
      "The modifier 'async*' isn't allowed for an expression function body.",
  correctionMessage: "Try converting the body to a block.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_STAR_AFTER_ASYNC',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidSuperFormalParameterLocation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
  problemMessage:
      "Super parameters can only be used in non-redirecting generative "
      "constructors.",
  correctionMessage:
      "Try removing the 'super' modifier, or changing the constructor to be "
      "non-redirecting and generative.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_SUPER_FORMAL_PARAMETER_LOCATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidSuperInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_SUPER_IN_INITIALIZER',
      problemMessage:
          "Can only use 'super' in an initializer for calling the superclass "
          "constructor (e.g. 'super()' or 'super.namedConstructor()')",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_SUPER_IN_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidSync = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_SYNC',
  problemMessage:
      "The modifier 'sync' isn't allowed for an expression function body.",
  correctionMessage: "Try converting the body to a block.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_SYNC',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidThisInInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_THIS_IN_INITIALIZER',
  problemMessage:
      "Can only use 'this' in an initializer for field initialization (e.g. "
      "'this.x = something') and constructor redirection (e.g. 'this()' or "
      "'this.namedConstructor())",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_THIS_IN_INITIALIZER',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
invalidTypeArgumentInConstList = DiagnosticWithArguments(
  name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
  problemMessage:
      "Constant list literals can't use a type parameter in a type argument, "
      "such as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST',
  withArguments: _withArgumentsInvalidTypeArgumentInConstList,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
invalidTypeArgumentInConstMap = DiagnosticWithArguments(
  name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
  problemMessage:
      "Constant map literals can't use a type parameter in a type argument, such "
      "as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP',
  withArguments: _withArgumentsInvalidTypeArgumentInConstMap,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidTypeArgumentInConstSet = DiagnosticWithArguments(
  name: 'INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL',
  problemMessage:
      "Constant set literals can't use a type parameter in a type argument, such "
      "as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET',
  withArguments: _withArgumentsInvalidTypeArgumentInConstSet,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidUnicodeEscapeStarted =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_UNICODE_ESCAPE_STARTED',
      problemMessage: "The string '\\' can't stand alone.",
      correctionMessage:
          "Try adding another backslash (\\) to escape the '\\'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_STARTED',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidUnicodeEscapeUBracket =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_UNICODE_ESCAPE_U_BRACKET',
      problemMessage:
          "An escape sequence starting with '\\u{' must be followed by 1 to 6 "
          "hexadecimal digits followed by a '}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_BRACKET',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidUnicodeEscapeUNoBracket = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
  problemMessage:
      "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
      "digits.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_NO_BRACKET',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidUnicodeEscapeUStarted = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_UNICODE_ESCAPE_U_STARTED',
  problemMessage:
      "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
      "digits or from 1 to 6 digits between '{' and '}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_UNICODE_ESCAPE_U_STARTED',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the URI that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidUri = DiagnosticWithArguments(
  name: 'INVALID_URI',
  problemMessage: "Invalid URI syntax: '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVALID_URI',
  withArguments: _withArgumentsInvalidUri,
  expectedTypes: [ExpectedType.string],
);

/// The 'covariant' keyword was found in an inappropriate location.
///
/// No parameters.
const DiagnosticWithoutArguments invalidUseOfCovariant =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_USE_OF_COVARIANT',
      problemMessage:
          "The 'covariant' keyword can only be used for parameters in instance "
          "methods or before non-final instance fields.",
      correctionMessage: "Try removing the 'covariant' keyword.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_USE_OF_COVARIANT',
      expectedTypes: [],
    );

/// No parameters.
///
/// Parameters:
/// Token lexeme: undocumented
const DiagnosticCode invalidUseOfCovariantInExtension =
    DiagnosticCodeWithExpectedTypes(
      name: 'INVALID_USE_OF_COVARIANT_IN_EXTENSION',
      problemMessage: "Can't have modifier '{0}' in an extension.",
      correctionMessage: "Try removing '{0}'.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.INVALID_USE_OF_COVARIANT_IN_EXTENSION',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidUseOfDoNotSubmitMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER',
  problemMessage: "Uses of '{0}' should not be submitted to source control.",
  correctionMessage: "Try removing the reference to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_DO_NOT_SUBMIT_MEMBER',
  withArguments: _withArgumentsInvalidUseOfDoNotSubmitMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidUseOfIdentifierAugmented = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_USE_OF_IDENTIFIER_AUGMENTED',
  problemMessage:
      "The identifier 'augmented' can only be used to reference the augmented "
      "declaration inside an augmentation.",
  correctionMessage: "Try using a different identifier.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.INVALID_USE_OF_IDENTIFIER_AUGMENTED',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidUseOfInternalMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_INTERNAL_MEMBER',
  problemMessage: "The member '{0}' can only be used within its package.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_INTERNAL_MEMBER',
  withArguments: _withArgumentsInvalidUseOfInternalMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidUseOfNullValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'INVALID_USE_OF_NULL_VALUE',
      problemMessage:
          "An expression whose value is always 'null' can't be dereferenced.",
      correctionMessage: "Try changing the type of the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.INVALID_USE_OF_NULL_VALUE',
      expectedTypes: [],
    );

/// This warning is generated anywhere where a member annotated with
/// `@protected` is used outside of an instance member of a subclass.
///
/// Parameters:
/// String p0: the name of the member
/// String p1: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidUseOfProtectedMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_PROTECTED_MEMBER',
  problemMessage:
      "The member '{0}' can only be used within instance members of subclasses "
      "of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_PROTECTED_MEMBER',
  withArguments: _withArgumentsInvalidUseOfProtectedMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invalidUseOfVisibleForOverridingMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
  problemMessage: "The member '{0}' can only be used for overriding.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_OVERRIDING_MEMBER',
  withArguments: _withArgumentsInvalidUseOfVisibleForOverridingMember,
  expectedTypes: [ExpectedType.string],
);

/// This warning is generated anywhere where a member annotated with
/// `@visibleForTemplate` is used outside of a "template" Dart file.
///
/// Parameters:
/// String p0: the name of the member
/// Uri p1: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required Uri p1})
>
invalidUseOfVisibleForTemplateMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
  problemMessage:
      "The member '{0}' can only be used within '{1}' or a template library.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_TEMPLATE_MEMBER',
  withArguments: _withArgumentsInvalidUseOfVisibleForTemplateMember,
  expectedTypes: [ExpectedType.string, ExpectedType.uri],
);

/// This warning is generated anywhere where a member annotated with
/// `@visibleForTesting` is used outside the defining library, or a test.
///
/// Parameters:
/// String p0: the name of the member
/// Uri p1: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required Uri p1})
>
invalidUseOfVisibleForTestingMember = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
  problemMessage: "The member '{0}' can only be used within '{1}' or a test.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_USE_OF_VISIBLE_FOR_TESTING_MEMBER',
  withArguments: _withArgumentsInvalidUseOfVisibleForTestingMember,
  expectedTypes: [ExpectedType.string, ExpectedType.uri],
);

/// This warning is generated anywhere where a private declaration is
/// annotated with `@visibleForTemplate` or `@visibleForTesting`.
///
/// Parameters:
/// String p0: the name of the member
/// String p1: the name of the annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidVisibilityAnnotation = DiagnosticWithArguments(
  name: 'INVALID_VISIBILITY_ANNOTATION',
  problemMessage:
      "The member '{0}' is annotated with '{1}', but this annotation is only "
      "meaningful on declarations of public members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_VISIBILITY_ANNOTATION',
  withArguments: _withArgumentsInvalidVisibilityAnnotation,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidVisibleForOverridingAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
  problemMessage:
      "The annotation 'visibleForOverriding' can only be applied to a public "
      "instance member that can be overridden.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_VISIBLE_FOR_OVERRIDING_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidVisibleOutsideTemplateAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION',
  problemMessage:
      "The annotation 'visibleOutsideTemplate' can only be applied to a member "
      "of a class, enum, or mixin that is annotated with "
      "'visibleForTemplate'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_VISIBLE_OUTSIDE_TEMPLATE_ANNOTATION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidWidgetPreviewApplication = DiagnosticWithoutArgumentsImpl(
  name: 'INVALID_WIDGET_PREVIEW_APPLICATION',
  problemMessage:
      "The '@Preview(...)' annotation can only be applied to public, statically "
      "accessible constructors and functions.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_WIDGET_PREVIEW_APPLICATION',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the private symbol
/// String p1: the name of the proposed public symbol equivalent
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
invalidWidgetPreviewPrivateArgument = DiagnosticWithArguments(
  name: 'INVALID_WIDGET_PREVIEW_PRIVATE_ARGUMENT',
  problemMessage:
      "'@Preview(...)' can only accept arguments that consist of literals and "
      "public symbols.",
  correctionMessage: "Rename private symbol '{0}' to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.INVALID_WIDGET_PREVIEW_PRIVATE_ARGUMENT',
  withArguments: _withArgumentsInvalidWidgetPreviewPrivateArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invocationOfExtensionWithoutCall = DiagnosticWithArguments(
  name: 'INVOCATION_OF_EXTENSION_WITHOUT_CALL',
  problemMessage:
      "The extension '{0}' doesn't define a 'call' method so the override can't "
      "be used in an invocation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVOCATION_OF_EXTENSION_WITHOUT_CALL',
  withArguments: _withArgumentsInvocationOfExtensionWithoutCall,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the identifier that is not a function type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
invocationOfNonFunction = DiagnosticWithArguments(
  name: 'INVOCATION_OF_NON_FUNCTION',
  problemMessage: "'{0}' isn't a function.",
  correctionMessage:
      "Try correcting the name to match an existing function, or define a "
      "method or function named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION',
  withArguments: _withArgumentsInvocationOfNonFunction,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invocationOfNonFunctionExpression = DiagnosticWithoutArgumentsImpl(
  name: 'INVOCATION_OF_NON_FUNCTION_EXPRESSION',
  problemMessage:
      "The expression doesn't evaluate to a function, so it can't be invoked.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the unresolvable label
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
labelInOuterScope = DiagnosticWithArguments(
  name: 'LABEL_IN_OUTER_SCOPE',
  problemMessage: "Can't reference label '{0}' declared in an outer method.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE',
  withArguments: _withArgumentsLabelInOuterScope,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the unresolvable label
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
labelUndefined = DiagnosticWithArguments(
  name: 'LABEL_UNDEFINED',
  problemMessage: "Can't reference an undefined label '{0}'.",
  correctionMessage:
      "Try defining the label, or correcting the name to match an existing "
      "label.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.LABEL_UNDEFINED',
  withArguments: _withArgumentsLabelUndefined,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments lateFinalFieldWithConstConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
      problemMessage:
          "Can't have a late final field in a class with a generative const "
          "constructor.",
      correctionMessage:
          "Try removing the 'late' modifier, or don't declare 'const' "
          "constructors.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.LATE_FINAL_FIELD_WITH_CONST_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments lateFinalLocalAlreadyAssigned =
    DiagnosticWithoutArgumentsImpl(
      name: 'LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
      problemMessage: "The late final local variable is already assigned.",
      correctionMessage:
          "Try removing the 'final' modifier, or don't reassign the value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.LATE_FINAL_LOCAL_ALREADY_ASSIGNED',
      expectedTypes: [],
    );

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments latePatternVariableDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'LATE_PATTERN_VARIABLE_DECLARATION',
      problemMessage:
          "A pattern variable declaration may not use the `late` keyword.",
      correctionMessage: "Try removing the keyword `late`.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.LATE_PATTERN_VARIABLE_DECLARATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments leafCallMustNotReturnHandle =
    DiagnosticWithoutArgumentsImpl(
      name: 'LEAF_CALL_MUST_NOT_RETURN_HANDLE',
      problemMessage: "FFI leaf call can't return a 'Handle'.",
      correctionMessage: "Try changing the return type to primitive or struct.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments leafCallMustNotTakeHandle =
    DiagnosticWithoutArgumentsImpl(
      name: 'LEAF_CALL_MUST_NOT_TAKE_HANDLE',
      problemMessage: "FFI leaf call can't take arguments of type 'Handle'.",
      correctionMessage:
          "Try changing the argument type to primitive or struct.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments libraryDirectiveNotFirst =
    DiagnosticWithoutArgumentsImpl(
      name: 'LIBRARY_DIRECTIVE_NOT_FIRST',
      problemMessage:
          "The library directive must appear before all other directives.",
      correctionMessage:
          "Try moving the library directive before any other directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.LIBRARY_DIRECTIVE_NOT_FIRST',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the actual type of the list element
/// Type p1: the expected type of the list element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
listElementTypeNotAssignable = DiagnosticWithArguments(
  name: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the list type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsListElementTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the actual type of the list element
/// Type p1: the expected type of the list element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
listElementTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'LIST_ELEMENT_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the list type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
  withArguments: _withArgumentsListElementTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String string: undocumented
/// Token lexeme: undocumented
const DiagnosticCode literalWithClass = DiagnosticCodeWithExpectedTypes(
  name: 'LITERAL_WITH_CLASS',
  problemMessage: "A {0} literal can't be prefixed by '{1}'.",
  correctionMessage: "Try removing '{1}'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.LITERAL_WITH_CLASS',
  expectedTypes: [ExpectedType.string, ExpectedType.token],
);

/// Parameters:
/// String string: undocumented
/// Token lexeme: undocumented
const DiagnosticCode literalWithClassAndNew = DiagnosticCodeWithExpectedTypes(
  name: 'LITERAL_WITH_CLASS_AND_NEW',
  problemMessage: "A {0} literal can't be prefixed by 'new {1}'.",
  correctionMessage: "Try removing 'new' and '{1}'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.LITERAL_WITH_CLASS_AND_NEW',
  expectedTypes: [ExpectedType.string, ExpectedType.token],
);

/// No parameters.
const DiagnosticWithoutArguments literalWithNew =
    DiagnosticWithoutArgumentsImpl(
      name: 'LITERAL_WITH_NEW',
      problemMessage: "A literal can't be prefixed by 'new'.",
      correctionMessage: "Try removing 'new'",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.LITERAL_WITH_NEW',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments localFunctionDeclarationModifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'LOCAL_FUNCTION_DECLARATION_MODIFIER',
      problemMessage:
          "Local function declarations can't specify any modifiers.",
      correctionMessage: "Try removing the modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.LOCAL_FUNCTION_DECLARATION_MODIFIER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
mainFirstPositionalParameterType = DiagnosticWithoutArgumentsImpl(
  name: 'MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
  problemMessage:
      "The type of the first positional parameter of the 'main' function must be "
      "a supertype of 'List<String>'.",
  correctionMessage: "Try changing the type of the parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MAIN_FIRST_POSITIONAL_PARAMETER_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments mainHasRequiredNamedParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
      problemMessage:
          "The function 'main' can't have any required named parameters.",
      correctionMessage:
          "Try using a different name for the function, or removing the "
          "'required' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MAIN_HAS_REQUIRED_NAMED_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
mainHasTooManyRequiredPositionalParameters = DiagnosticWithoutArgumentsImpl(
  name: 'MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
  problemMessage:
      "The function 'main' can't have more than two required positional "
      "parameters.",
  correctionMessage:
      "Try using a different name for the function, or removing extra "
      "parameters.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MAIN_HAS_TOO_MANY_REQUIRED_POSITIONAL_PARAMETERS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments mainIsNotFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'MAIN_IS_NOT_FUNCTION',
      problemMessage: "The declaration named 'main' must be a function.",
      correctionMessage: "Try using a different name for this declaration.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mapEntryNotInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'MAP_ENTRY_NOT_IN_MAP',
      problemMessage: "Map entries can only be used in a map literal.",
      correctionMessage:
          "Try converting the collection to a map or removing the map entry.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MAP_ENTRY_NOT_IN_MAP',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the type of the expression being used as a key
/// Type p1: the type of keys declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
mapKeyTypeNotAssignable = DiagnosticWithArguments(
  name: 'MAP_KEY_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the map key type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsMapKeyTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the type of the expression being used as a key
/// Type p1: the type of keys declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
mapKeyTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'MAP_KEY_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the map key type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE_NULLABILITY',
  withArguments: _withArgumentsMapKeyTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the type of the expression being used as a value
/// Type p1: the type of values declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
mapValueTypeNotAssignable = DiagnosticWithArguments(
  name: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the map value type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsMapValueTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the type of the expression being used as a value
/// Type p1: the type of values declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
mapValueTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'MAP_VALUE_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the map value type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE_NULLABILITY',
  withArguments: _withArgumentsMapValueTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments memberWithClassName =
    DiagnosticWithoutArgumentsImpl(
      name: 'MEMBER_WITH_CLASS_NAME',
      problemMessage:
          "A class member can't have the same name as the enclosing class.",
      correctionMessage: "Try renaming the member.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MEMBER_WITH_CLASS_NAME',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mismatchedAnnotationOnStructField =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
      problemMessage:
          "The annotation doesn't match the declared type of the field.",
      correctionMessage:
          "Try using a different annotation or changing the declared type to "
          "match.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the type that is missing a native type annotation
/// String p1: the superclass which is extended by this field's class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required String p1})
>
missingAnnotationOnStructField = DiagnosticWithArguments(
  name: 'MISSING_ANNOTATION_ON_STRUCT_FIELD',
  problemMessage:
      "Fields of type '{0}' in a subclass of '{1}' must have an annotation "
      "indicating the native type.",
  correctionMessage: "Try adding an annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MISSING_ANNOTATION_ON_STRUCT_FIELD',
  withArguments: _withArgumentsMissingAnnotationOnStructField,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingAssignableSelector =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_ASSIGNABLE_SELECTOR',
      problemMessage: "Missing selector such as '.identifier' or '[0]'.",
      correctionMessage: "Try adding a selector.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingAssignmentInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_ASSIGNMENT_IN_INITIALIZER',
      problemMessage: "Expected an assignment after the field name.",
      correctionMessage:
          "To initialize a field, use the syntax 'name = value'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_ASSIGNMENT_IN_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingCatchOrFinally = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_CATCH_OR_FINALLY',
  problemMessage:
      "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
  correctionMessage:
      "Try adding either a catch or finally clause, or remove the try "
      "statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_CATCH_OR_FINALLY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingClosingParenthesis =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_CLOSING_PARENTHESIS',
      problemMessage: "The closing parenthesis is missing.",
      correctionMessage: "Try adding the closing parenthesis.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_CLOSING_PARENTHESIS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingConstFinalVarOrType = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_CONST_FINAL_VAR_OR_TYPE',
  problemMessage:
      "Variables must be declared using the keywords 'const', 'final', 'var' or "
      "a type name.",
  correctionMessage:
      "Try adding the name of the type of the variable or the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE',
  expectedTypes: [],
);

/// 12.1 Constants: A constant expression is ... a constant list literal.
///
/// Note: This diagnostic is never displayed to the user, so it doesn't need
/// to be documented.
///
/// No parameters.
const DiagnosticWithoutArguments missingConstInListLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_CONST_IN_LIST_LITERAL',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MISSING_CONST_IN_LIST_LITERAL',
      expectedTypes: [],
    );

/// 12.1 Constants: A constant expression is ... a constant map literal.
///
/// Note: This diagnostic is never displayed to the user, so it doesn't need
/// to be documented.
///
/// No parameters.
const DiagnosticWithoutArguments missingConstInMapLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_CONST_IN_MAP_LITERAL',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MISSING_CONST_IN_MAP_LITERAL',
      expectedTypes: [],
    );

/// 12.1 Constants: A constant expression is ... a constant set literal.
///
/// Note: This diagnostic is never displayed to the user, so it doesn't need
/// to be documented.
///
/// No parameters.
const DiagnosticWithoutArguments missingConstInSetLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_CONST_IN_SET_LITERAL',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MISSING_CONST_IN_SET_LITERAL',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
missingDartLibrary = DiagnosticWithArguments(
  name: 'MISSING_DART_LIBRARY',
  problemMessage: "Required library '{0}' is missing.",
  correctionMessage: "Re-install the Dart or Flutter SDK.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MISSING_DART_LIBRARY',
  withArguments: _withArgumentsMissingDartLibrary,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingDefaultValueForParameter = DiagnosticWithArguments(
  name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
  problemMessage:
      "The parameter '{0}' can't have a value of 'null' because of its type, but "
      "the implicit default value is 'null'.",
  correctionMessage:
      "Try adding either an explicit non-'null' default value or the "
      "'required' modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER',
  withArguments: _withArgumentsMissingDefaultValueForParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingDefaultValueForParameterPositional = DiagnosticWithArguments(
  name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
  problemMessage:
      "The parameter '{0}' can't have a value of 'null' because of its type, but "
      "the implicit default value is 'null'.",
  correctionMessage: "Try adding an explicit non-'null' default value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_POSITIONAL',
  withArguments: _withArgumentsMissingDefaultValueForParameterPositional,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
missingDefaultValueForParameterWithAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_DEFAULT_VALUE_FOR_PARAMETER',
  problemMessage:
      "With null safety, use the 'required' keyword, not the '@required' "
      "annotation.",
  correctionMessage: "Try removing the '@'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MISSING_DEFAULT_VALUE_FOR_PARAMETER_WITH_ANNOTATION',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the list of packages missing from the dependencies and the list
///            of packages missing from the dev_dependencies (if any) in the
///            pubspec file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingDependency = DiagnosticWithArguments(
  name: 'MISSING_DEPENDENCY',
  problemMessage: "Missing a dependency on imported package '{0}'.",
  correctionMessage: "Try adding {0}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.MISSING_DEPENDENCY',
  withArguments: _withArgumentsMissingDependency,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingDigit = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_DIGIT',
  problemMessage: "Decimal digit expected.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.MISSING_DIGIT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingEnumBody = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_ENUM_BODY',
  problemMessage:
      "An enum definition must have a body with at least one constant name.",
  correctionMessage: "Try adding a body and defining at least one constant.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_ENUM_BODY',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the constant that is missing
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingEnumConstantInSwitch = DiagnosticWithArguments(
  name: 'MISSING_ENUM_CONSTANT_IN_SWITCH',
  problemMessage: "Missing case clause for '{0}'.",
  correctionMessage:
      "Try adding a case clause for the missing constant, or adding a "
      "default clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.MISSING_ENUM_CONSTANT_IN_SWITCH',
  withArguments: _withArgumentsMissingEnumConstantInSwitch,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingExceptionValue = DiagnosticWithArguments(
  name: 'MISSING_EXCEPTION_VALUE',
  problemMessage:
      "The method {0} must have an exceptional return value (the second "
      "argument) when the return type of the function is neither 'void', "
      "'Handle', nor 'Pointer'.",
  correctionMessage: "Try adding an exceptional return value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MISSING_EXCEPTION_VALUE',
  withArguments: _withArgumentsMissingExceptionValue,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingExpressionInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_EXPRESSION_IN_INITIALIZER',
      problemMessage: "Expected an expression after the assignment operator.",
      correctionMessage:
          "Try adding the value to be assigned, or remove the assignment "
          "operator.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_EXPRESSION_IN_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingExpressionInThrow =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_EXPRESSION_IN_THROW',
      problemMessage: "Missing expression after 'throw'.",
      correctionMessage:
          "Add an expression after 'throw' or use 'rethrow' to throw a caught "
          "exception",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_EXPRESSION_IN_THROW',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingFieldTypeInStruct = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_FIELD_TYPE_IN_STRUCT',
  problemMessage:
      "Fields in struct classes must have an explicitly declared type of 'int', "
      "'double' or 'Pointer'.",
  correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MISSING_FIELD_TYPE_IN_STRUCT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingFunctionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_FUNCTION_BODY',
      problemMessage: "A function body must be provided.",
      correctionMessage: "Try adding a function body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_FUNCTION_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingFunctionKeyword = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_FUNCTION_KEYWORD',
  problemMessage:
      "Function types must have the keyword 'Function' before the parameter "
      "list.",
  correctionMessage: "Try adding the keyword 'Function'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_FUNCTION_KEYWORD',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingFunctionParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_FUNCTION_PARAMETERS',
      problemMessage: "Functions must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_FUNCTION_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingGet = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_GET',
  problemMessage: "Getters must have the keyword 'get' before the getter name.",
  correctionMessage: "Try adding the keyword 'get'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_GET',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingHexDigit =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_HEX_DIGIT',
      problemMessage: "Hexadecimal digit expected.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ScannerErrorCode.MISSING_HEX_DIGIT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingIdentifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_IDENTIFIER',
      problemMessage: "Expected an identifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_IDENTIFIER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_INITIALIZER',
      problemMessage: "Expected an initializer.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_INITIALIZER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingKeywordOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_KEYWORD_OPERATOR',
      problemMessage:
          "Operator declarations must be preceded by the keyword 'operator'.",
      correctionMessage: "Try adding the keyword 'operator'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_KEYWORD_OPERATOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingMethodParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_METHOD_PARAMETERS',
      problemMessage: "Methods must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_METHOD_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingName = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_NAME',
  problemMessage: "The 'name' field is required but missing.",
  correctionMessage: "Try adding a field named 'name'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.MISSING_NAME',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNamedPatternFieldName = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_NAMED_PATTERN_FIELD_NAME',
  problemMessage:
      "The getter name is not specified explicitly, and the pattern is not a "
      "variable.",
  correctionMessage:
      "Try specifying the getter name explicitly, or using a variable "
      "pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MISSING_NAMED_PATTERN_FIELD_NAME',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNameForNamedParameter = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_NAME_FOR_NAMED_PARAMETER',
  problemMessage: "Named parameters in a function type must have a name",
  correctionMessage:
      "Try providing a name for the parameter or removing the curly braces.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_NAME_FOR_NAMED_PARAMETER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNameInLibraryDirective = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_NAME_IN_LIBRARY_DIRECTIVE',
  problemMessage: "Library directives must include a library name.",
  correctionMessage:
      "Try adding a library name after the keyword 'library', or remove the "
      "library directive if the library doesn't have any parts.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_NAME_IN_LIBRARY_DIRECTIVE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingNameInPartOfDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_NAME_IN_PART_OF_DIRECTIVE',
      problemMessage: "Part-of directives must include a library name.",
      correctionMessage: "Try adding a library name after the 'of'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE',
      expectedTypes: [],
    );

/// Parameters:
/// String member: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String member})
>
missingOverrideOfMustBeOverriddenOne = DiagnosticWithArguments(
  name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
  problemMessage: "Missing a required override of '{0}'.",
  correctionMessage: "Try overriding the missing member.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_ONE',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenOne,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String firstMember: the name of the first member
/// String secondMember: the name of the second member
/// String additionalCount: the number of additional missing members that
///                         aren't listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String firstMember,
    required String secondMember,
    required String additionalCount,
  })
>
missingOverrideOfMustBeOverriddenThreePlus = DiagnosticWithArguments(
  name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
  problemMessage: "Missing a required override of '{0}', '{1}', and {2} more.",
  correctionMessage: "Try overriding the missing members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_THREE_PLUS',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String firstMember: the name of the first member
/// String secondMember: the name of the second member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String firstMember,
    required String secondMember,
  })
>
missingOverrideOfMustBeOverriddenTwo = DiagnosticWithArguments(
  name: 'MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN',
  problemMessage: "Missing a required override of '{0}' and '{1}'.",
  correctionMessage: "Try overriding the missing members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MISSING_OVERRIDE_OF_MUST_BE_OVERRIDDEN_TWO',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenTwo,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingPrefixInDeferredImport =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_PREFIX_IN_DEFERRED_IMPORT',
      problemMessage: "Deferred imports should have a prefix.",
      correctionMessage:
          "Try adding a prefix to the import by adding an 'as' clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_PREFIX_IN_DEFERRED_IMPORT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingPrimaryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_PRIMARY_CONSTRUCTOR',
      problemMessage:
          "An extension type declaration must have a primary constructor "
          "declaration.",
      correctionMessage:
          "Try adding a primary constructor to the extension type declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_PRIMARY_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingPrimaryConstructorParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
      problemMessage:
          "A primary constructor declaration must have formal parameters.",
      correctionMessage:
          "Try adding formal parameters after the primary constructor name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingQuote = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_QUOTE',
  problemMessage: "Expected quote (' or \").",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.MISSING_QUOTE',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingRequiredArgument = DiagnosticWithArguments(
  name: 'MISSING_REQUIRED_ARGUMENT',
  problemMessage:
      "The named parameter '{0}' is required, but there's no corresponding "
      "argument.",
  correctionMessage: "Try adding the required argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT',
  withArguments: _withArgumentsMissingRequiredArgument,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for a constructor, function or method invocation where
/// a required parameter is missing.
///
/// Parameters:
/// String p0: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingRequiredParam = DiagnosticWithArguments(
  name: 'MISSING_REQUIRED_PARAM',
  problemMessage: "The parameter '{0}' is required.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MISSING_REQUIRED_PARAM',
  withArguments: _withArgumentsMissingRequiredParam,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for a constructor, function or method invocation where
/// a required parameter is missing.
///
/// Parameters:
/// String p0: the name of the parameter
/// String p1: message details
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
missingRequiredParamWithDetails = DiagnosticWithArguments(
  name: 'MISSING_REQUIRED_PARAM',
  problemMessage: "The parameter '{0}' is required. {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MISSING_REQUIRED_PARAM_WITH_DETAILS',
  withArguments: _withArgumentsMissingRequiredParamWithDetails,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingSizeAnnotationCarray =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_SIZE_ANNOTATION_CARRAY',
      problemMessage:
          "Fields of type 'Array' must have exactly one 'Array' annotation.",
      correctionMessage:
          "Try adding an 'Array' annotation, or removing all but one of the "
          "annotations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.MISSING_SIZE_ANNOTATION_CARRAY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingStarAfterSync =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_STAR_AFTER_SYNC',
      problemMessage: "The modifier 'sync' must be followed by a star ('*').",
      correctionMessage: "Try removing the modifier, or add a star.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_STAR_AFTER_SYNC',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingStatement =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_STATEMENT',
      problemMessage: "Expected a statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_STATEMENT',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the terminator that is missing
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
missingTerminatorForParameterGroup = DiagnosticWithArguments(
  name: 'MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
  problemMessage: "There is no '{0}' to close the parameter group.",
  correctionMessage: "Try inserting a '{0}' at the end of the group.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_TERMINATOR_FOR_PARAMETER_GROUP',
  withArguments: _withArgumentsMissingTerminatorForParameterGroup,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments missingTypedefParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'MISSING_TYPEDEF_PARAMETERS',
      problemMessage: "Typedefs must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MISSING_TYPEDEF_PARAMETERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingVariableInForEach = DiagnosticWithoutArgumentsImpl(
  name: 'MISSING_VARIABLE_IN_FOR_EACH',
  problemMessage:
      "A loop variable must be declared in a for-each loop before the 'in', but "
      "none was found.",
  correctionMessage: "Try declaring a loop variable.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MISSING_VARIABLE_IN_FOR_EACH',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the variable pattern
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
missingVariablePattern = DiagnosticWithArguments(
  name: 'MISSING_VARIABLE_PATTERN',
  problemMessage:
      "Variable pattern '{0}' is missing in this branch of the logical-or "
      "pattern.",
  correctionMessage: "Try declaring this variable pattern in the branch.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MISSING_VARIABLE_PATTERN',
  withArguments: _withArgumentsMissingVariablePattern,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
mixedParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'MIXED_PARAMETER_GROUPS',
  problemMessage:
      "Can't have both positional and named parameters in a single parameter "
      "list.",
  correctionMessage: "Try choosing a single style of optional parameters.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MIXED_PARAMETER_GROUPS',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the super-invoked member
/// Type p1: the display name of the type of the super-invoked member in the
///          mixin
/// Type p2: the display name of the type of the concrete member in the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required DartType p1,
    required DartType p2,
  })
>
mixinApplicationConcreteSuperInvokedMemberType = DiagnosticWithArguments(
  name: 'MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
  problemMessage:
      "The super-invoked member '{0}' has the type '{1}', and the concrete "
      "member in the class has the type '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MIXIN_APPLICATION_CONCRETE_SUPER_INVOKED_MEMBER_TYPE',
  withArguments: _withArgumentsMixinApplicationConcreteSuperInvokedMemberType,
  expectedTypes: [ExpectedType.string, ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String p0: the display name of the member without a concrete
///            implementation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinApplicationNoConcreteSuperInvokedMember = DiagnosticWithArguments(
  name: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
  problemMessage:
      "The class doesn't have a concrete implementation of the super-invoked "
      "member '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
  withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the display name of the setter without a concrete
///            implementation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinApplicationNoConcreteSuperInvokedSetter = DiagnosticWithArguments(
  name: 'MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_MEMBER',
  problemMessage:
      "The class doesn't have a concrete implementation of the super-invoked "
      "setter '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MIXIN_APPLICATION_NO_CONCRETE_SUPER_INVOKED_SETTER',
  withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type p0: the display name of the mixin
/// Type p1: the display name of the superclass
/// Type p2: the display name of the type that is not implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required DartType p2,
  })
>
mixinApplicationNotImplementedInterface = DiagnosticWithArguments(
  name: 'MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
  problemMessage:
      "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
  correctionMessage: "Try extending the class '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE',
  withArguments: _withArgumentsMixinApplicationNotImplementedInterface,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the mixin class that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinClassDeclarationExtendsNotObject = DiagnosticWithArguments(
  name: 'MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT',
  problemMessage:
      "The class '{0}' can't be declared a mixin because it extends a class "
      "other than 'Object'.",
  correctionMessage:
      "Try removing the 'mixin' modifier or changing the superclass to "
      "'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_CLASS_DECLARATION_EXTENDS_NOT_OBJECT',
  withArguments: _withArgumentsMixinClassDeclarationExtendsNotObject,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the mixin that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinClassDeclaresConstructor = DiagnosticWithArguments(
  name: 'MIXIN_CLASS_DECLARES_CONSTRUCTOR',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it declares a "
      "constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR',
  withArguments: _withArgumentsMixinClassDeclaresConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinDeclaresConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_DECLARES_CONSTRUCTOR',
      problemMessage: "Mixins can't declare constructors.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MIXIN_DECLARES_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUBTYPE_OF_DEFERRED_CLASS',
      problemMessage: "Classes can't mixin deferred classes.",
      correctionMessage: "Try changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MIXIN_DEFERRED_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the mixin that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinInheritsFromNotObject = DiagnosticWithArguments(
  name: 'MIXIN_INHERITS_FROM_NOT_OBJECT',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it extends a class other "
      "than 'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT',
  withArguments: _withArgumentsMixinInheritsFromNotObject,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinInstantiate =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_INSTANTIATE',
      problemMessage: "Mixins can't be instantiated.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MIXIN_INSTANTIATE',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
mixinOfDisallowedClass = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_DISALLOWED_TYPE',
  problemMessage: "Classes can't mixin '{0}'.",
  correctionMessage:
      "Try specifying a different class or mixin, or remove the class or "
      "mixin from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS',
  withArguments: _withArgumentsMixinOfDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments mixinOfNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_OF_NON_CLASS',
      problemMessage: "Classes can only mix in mixins and classes.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MIXIN_OF_NON_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinOfTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
      problemMessage:
          "A type alias that expands to a type parameter can't be mixed in.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.MIXIN_OF_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
      expectedTypes: [],
    );

/// This warning is generated anywhere where a `@sealed` class is used as a
/// a superclass constraint of a mixin.
///
/// Parameters:
/// String p0: the name of the sealed class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mixinOnSealedClass = DiagnosticWithArguments(
  name: 'MIXIN_ON_SEALED_CLASS',
  problemMessage:
      "The class '{0}' shouldn't be used as a mixin constraint because it is "
      "sealed, and any class mixing in this mixin must have '{0}' as a "
      "superclass.",
  correctionMessage:
      "Try composing with this class, or refer to its documentation for more "
      "information.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MIXIN_ON_SEALED_CLASS',
  withArguments: _withArgumentsMixinOnSealedClass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinOnTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPERTYPE_EXPANDS_TO_TYPE_PARAMETER',
      problemMessage:
          "A type alias that expands to a type parameter can't be used as a "
          "superclass constraint.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.MIXIN_ON_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
      expectedTypes: [],
    );

/// Parameters:
/// Element p0: the name of the class that appears in both "extends" and
///             "with" clauses
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element p0})
>
mixinsSuperClass = DiagnosticWithArguments(
  name: 'IMPLEMENTS_SUPER_CLASS',
  problemMessage:
      "'{0}' can't be used in both the 'extends' and 'with' clauses.",
  correctionMessage: "Try removing one of the occurrences.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXINS_SUPER_CLASS',
  withArguments: _withArgumentsMixinsSuperClass,
  expectedTypes: [ExpectedType.element],
);

/// Parameters:
/// String p0: the name of the mixin that is not 'base'
/// String p1: the name of the 'base' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
mixinSubtypeOfBaseIsNotBase = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
  problemMessage:
      "The mixin '{0}' must be 'base' because the supertype '{1}' is 'base'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_SUBTYPE_OF_BASE_IS_NOT_BASE',
  withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the mixin that is not 'final'
/// String p1: the name of the 'final' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
mixinSubtypeOfFinalIsNotBase = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
  problemMessage:
      "The mixin '{0}' must be 'base' because the supertype '{1}' is 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.MIXIN_SUBTYPE_OF_FINAL_IS_NOT_BASE',
  withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinSuperClassConstraintDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
      problemMessage:
          "Deferred classes can't be used as superclass constraints.",
      correctionMessage: "Try changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DEFERRED_CLASS',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
mixinSuperClassConstraintDisallowedClass = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_DISALLOWED_TYPE',
  problemMessage: "'{0}' can't be used as a superclass constraint.",
  correctionMessage:
      "Try specifying a different super-class constraint, or remove the 'on' "
      "clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_DISALLOWED_CLASS',
  withArguments: _withArgumentsMixinSuperClassConstraintDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments mixinSuperClassConstraintNonInterface =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
      problemMessage:
          "Only classes and mixins can be used as superclass constraints.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.MIXIN_SUPER_CLASS_CONSTRAINT_NON_INTERFACE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinWithClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_WITH_CLAUSE',
      problemMessage: "A mixin can't have a with clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MIXIN_WITH_CLAUSE',
      expectedTypes: [],
    );

/// 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
/// denote a class available in the immediately enclosing scope.
///
/// No parameters.
const DiagnosticWithoutArguments mixinWithNonClassSuperclass =
    DiagnosticWithoutArgumentsImpl(
      name: 'MIXIN_WITH_NON_CLASS_SUPERCLASS',
      problemMessage: "Mixin can only be applied to class.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS',
      expectedTypes: [],
    );

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
modifierOutOfOrder = DiagnosticWithArguments(
  name: 'MODIFIER_OUT_OF_ORDER',
  problemMessage: "The modifier '{0}' should be before the modifier '{1}'.",
  correctionMessage: "Try re-ordering the modifiers.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MODIFIER_OUT_OF_ORDER',
  withArguments: _withArgumentsModifierOutOfOrder,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
multipleClauses = DiagnosticWithArguments(
  name: 'MULTIPLE_CLAUSES',
  problemMessage: "Each '{0}' definition can have at most one '{1}' clause.",
  correctionMessage:
      "Try combining all of the '{1}' clauses into a single clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MULTIPLE_CLAUSES',
  withArguments: _withArgumentsMultipleClauses,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
multipleCombinators = DiagnosticWithoutArgumentsImpl(
  name: 'MULTIPLE_COMBINATORS',
  problemMessage:
      "Using multiple 'hide' or 'show' combinators is never necessary and often "
      "produces surprising results.",
  correctionMessage: "Try using a single combinator.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MULTIPLE_COMBINATORS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleExtendsClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_EXTENDS_CLAUSES',
      problemMessage:
          "Each class definition can have at most one extends clause.",
      correctionMessage:
          "Try choosing one superclass and define your class to implement (or "
          "mix in) the others.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_EXTENDS_CLAUSES',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
multipleImplementsClauses = DiagnosticWithoutArgumentsImpl(
  name: 'MULTIPLE_IMPLEMENTS_CLAUSES',
  problemMessage:
      "Each class or mixin definition can have at most one implements clause.",
  correctionMessage:
      "Try combining all of the implements clauses into a single clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MULTIPLE_IMPLEMENTS_CLAUSES',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleLibraryDirectives =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_LIBRARY_DIRECTIVES',
      problemMessage: "Only one library directive may be declared in a file.",
      correctionMessage: "Try removing all but one of the library directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_LIBRARY_DIRECTIVES',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
multipleNamedParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'MULTIPLE_NAMED_PARAMETER_GROUPS',
  problemMessage:
      "Can't have multiple groups of named parameters in a single parameter "
      "list.",
  correctionMessage: "Try combining all of the groups into a single group.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MULTIPLE_NAMED_PARAMETER_GROUPS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleOnClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_ON_CLAUSES',
      problemMessage: "Each mixin definition can have at most one on clause.",
      correctionMessage:
          "Try combining all of the on clauses into a single clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_ON_CLAUSES',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multiplePartOfDirectives =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_PART_OF_DIRECTIVES',
      problemMessage: "Only one part-of directive may be declared in a file.",
      correctionMessage: "Try removing all but one of the part-of directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_PART_OF_DIRECTIVES',
      expectedTypes: [],
    );

/// An error code indicating multiple plugins have been specified as enabled.
///
/// Parameters:
/// String p0: the name of the first plugin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
multiplePlugins = DiagnosticWithArguments(
  name: 'MULTIPLE_PLUGINS',
  problemMessage: "Multiple plugins can't be enabled.",
  correctionMessage: "Remove all plugins following the first, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.MULTIPLE_PLUGINS',
  withArguments: _withArgumentsMultiplePlugins,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
multiplePositionalParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
  problemMessage:
      "Can't have multiple groups of positional parameters in a single parameter "
      "list.",
  correctionMessage: "Try combining all of the groups into a single group.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MULTIPLE_POSITIONAL_PARAMETER_GROUPS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleRedirectingConstructorInvocations =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
      problemMessage:
          "Constructors can have only one 'this' redirection, at most.",
      correctionMessage: "Try removing all but one of the redirections.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleRepresentationFields =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_REPRESENTATION_FIELDS',
      problemMessage:
          "Each extension type should have exactly one representation field.",
      correctionMessage:
          "Try combining fields into a record, or removing extra fields.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_REPRESENTATION_FIELDS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleSuperInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_SUPER_INITIALIZERS',
      problemMessage: "A constructor can have at most one 'super' initializer.",
      correctionMessage:
          "Try removing all but one of the 'super' initializers.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the number of variables being declared
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
multipleVariablesInForEach = DiagnosticWithArguments(
  name: 'MULTIPLE_VARIABLES_IN_FOR_EACH',
  problemMessage:
      "A single loop variable must be declared in a for-each loop before the "
      "'in', but {0} were found.",
  correctionMessage:
      "Try moving all but one of the declarations inside the loop body.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.MULTIPLE_VARIABLES_IN_FOR_EACH',
  withArguments: _withArgumentsMultipleVariablesInForEach,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments multipleVarianceModifiers =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_VARIANCE_MODIFIERS',
      problemMessage:
          "Each type parameter can have at most one variance modifier.",
      correctionMessage:
          "Use at most one of the 'in', 'out', or 'inout' modifiers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_VARIANCE_MODIFIERS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleWithClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'MULTIPLE_WITH_CLAUSES',
      problemMessage: "Each class definition can have at most one with clause.",
      correctionMessage:
          "Try combining all of the with clauses into a single clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.MULTIPLE_WITH_CLAUSES',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the type that should be a valid dart:ffi native type.
/// String p1: the name of the function whose invocation depends on this
///            relationship
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required String p1})
>
mustBeANativeFunctionType = DiagnosticWithArguments(
  name: 'MUST_BE_A_NATIVE_FUNCTION_TYPE',
  problemMessage:
      "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function "
      "type.",
  correctionMessage:
      "Try changing the type to only use members for 'dart:ffi'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE',
  withArguments: _withArgumentsMustBeANativeFunctionType,
  expectedTypes: [ExpectedType.object, ExpectedType.string],
);

/// Parameters:
/// Type p0: the type that should be a subtype
/// Type p1: the supertype that the subtype is compared to
/// String p2: the name of the function whose invocation depends on this
///            relationship
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
mustBeASubtype = DiagnosticWithArguments(
  name: 'MUST_BE_A_SUBTYPE',
  problemMessage: "The type '{0}' must be a subtype of '{1}' for '{2}'.",
  correctionMessage: "Try changing one or both of the type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MUST_BE_A_SUBTYPE',
  withArguments: _withArgumentsMustBeASubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Generates a warning for classes that inherit from classes annotated with
/// `@immutable` but that are not immutable.
///
/// Parameters:
/// String p0: the name of the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mustBeImmutable = DiagnosticWithArguments(
  name: 'MUST_BE_IMMUTABLE',
  problemMessage:
      "This class (or a class that this class inherits from) is marked as "
      "'@immutable', but one or more of its instance fields aren't final: "
      "{0}",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MUST_BE_IMMUTABLE',
  withArguments: _withArgumentsMustBeImmutable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the class declaring the overridden method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
mustCallSuper = DiagnosticWithArguments(
  name: 'MUST_CALL_SUPER',
  problemMessage:
      "This method overrides a method annotated as '@mustCallSuper' in '{0}', "
      "but doesn't invoke the overridden method.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.MUST_CALL_SUPER',
  withArguments: _withArgumentsMustCallSuper,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type p0: the return type that should be 'void'.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
mustReturnVoid = DiagnosticWithArguments(
  name: 'MUST_RETURN_VOID',
  problemMessage:
      "The return type of the function passed to 'NativeCallable.listener' must "
      "be 'void' rather than '{0}'.",
  correctionMessage: "Try changing the return type to 'void'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.MUST_RETURN_VOID',
  withArguments: _withArgumentsMustReturnVoid,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments namedFunctionExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'NAMED_FUNCTION_EXPRESSION',
      problemMessage: "Function expressions can't be named.",
      correctionMessage:
          "Try removing the name, or moving the function expression to a "
          "function declaration statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NAMED_FUNCTION_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments namedFunctionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'NAMED_FUNCTION_TYPE',
      problemMessage: "Function types can't be named.",
      correctionMessage: "Try replacing the name with the keyword 'Function'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NAMED_FUNCTION_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments namedParameterOutsideGroup =
    DiagnosticWithoutArgumentsImpl(
      name: 'NAMED_PARAMETER_OUTSIDE_GROUP',
      problemMessage:
          "Named parameters must be enclosed in curly braces ('{' and '}').",
      correctionMessage:
          "Try surrounding the named parameters in curly braces.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NAMED_PARAMETER_OUTSIDE_GROUP',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nameNotString = DiagnosticWithoutArgumentsImpl(
  name: 'NAME_NOT_STRING',
  problemMessage: "The value of the 'name' field is required to be a string.",
  correctionMessage: "Try converting the value to be a string.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.NAME_NOT_STRING',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nativeClauseInNonSdkCode = DiagnosticWithoutArgumentsImpl(
  name: 'NATIVE_CLAUSE_IN_NON_SDK_CODE',
  problemMessage:
      "Native clause can only be used in the SDK and code that is loaded through "
      "native extensions.",
  correctionMessage: "Try removing the native clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeClauseShouldBeAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
      problemMessage: "Native clause in this form is deprecated.",
      correctionMessage:
          "Try removing this native clause and adding @native() or "
          "@native('native-name') before the declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NATIVE_CLAUSE_SHOULD_BE_ANNOTATION',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: The invalid type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
nativeFieldInvalidType = DiagnosticWithArguments(
  name: 'NATIVE_FIELD_INVALID_TYPE',
  problemMessage:
      "'{0}' is an unsupported type for native fields. Native fields only "
      "support pointers, arrays or numeric and compound types.",
  correctionMessage:
      "Try changing the type in the `@Native` annotation to a numeric FFI "
      "type, a pointer, array, or a compound class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NATIVE_FIELD_INVALID_TYPE',
  withArguments: _withArgumentsNativeFieldInvalidType,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
nativeFieldMissingType = DiagnosticWithoutArgumentsImpl(
  name: 'NATIVE_FIELD_MISSING_TYPE',
  problemMessage:
      "The native type of this field could not be inferred and must be specified "
      "in the annotation.",
  correctionMessage:
      "Try adding a type parameter extending `NativeType` to the `@Native` "
      "annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NATIVE_FIELD_MISSING_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeFieldNotStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'NATIVE_FIELD_NOT_STATIC',
      problemMessage: "Native fields must be static.",
      correctionMessage: "Try adding the modifier 'static' to this field.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.NATIVE_FIELD_NOT_STATIC',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nativeFunctionBodyInNonSdkCode = DiagnosticWithoutArgumentsImpl(
  name: 'NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
  problemMessage:
      "Native functions can only be declared in the SDK and code that is loaded "
      "through native extensions.",
  correctionMessage: "Try removing the word 'native'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeFunctionMissingType =
    DiagnosticWithoutArgumentsImpl(
      name: 'NATIVE_FUNCTION_MISSING_TYPE',
      problemMessage:
          "The native type of this function couldn't be inferred so it must be "
          "specified in the annotation.",
      correctionMessage:
          "Try adding a type parameter extending `NativeType` to the `@Native` "
          "annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.NATIVE_FUNCTION_MISSING_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
negativeVariableDimension = DiagnosticWithoutArgumentsImpl(
  name: 'NEGATIVE_VARIABLE_DIMENSION',
  problemMessage:
      "The variable dimension of a variable-length array must be non-negative.",
  correctionMessage: "Try using a value that is zero or greater.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NEGATIVE_VARIABLE_DIMENSION',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
newWithNonType = DiagnosticWithArguments(
  name: 'CREATION_WITH_NON_TYPE',
  problemMessage: "The name '{0}' isn't a class.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NEW_WITH_NON_TYPE',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
newWithUndefinedConstructor = DiagnosticWithArguments(
  name: 'NEW_WITH_UNDEFINED_CONSTRUCTOR',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try invoking a different constructor, or define a constructor named "
      "'{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR',
  withArguments: _withArgumentsNewWithUndefinedConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the class being instantiated
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
newWithUndefinedConstructorDefault = DiagnosticWithArguments(
  name: 'NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
  problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
  correctionMessage:
      "Try using one of the named constructors defined in '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT',
  withArguments: _withArgumentsNewWithUndefinedConstructorDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments noAnnotationConstructorArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
      problemMessage: "Annotation creation must have arguments.",
      correctionMessage: "Try adding an empty argument list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the class where override error was detected
/// String p1: the list of candidate signatures which cannot be combined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
noCombinedSuperSignature = DiagnosticWithArguments(
  name: 'NO_COMBINED_SUPER_SIGNATURE',
  problemMessage:
      "Can't infer missing types in '{0}' from overridden methods: {1}.",
  correctionMessage:
      "Try providing explicit types for this method's parameters and return "
      "type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NO_COMBINED_SUPER_SIGNATURE',
  withArguments: _withArgumentsNoCombinedSuperSignature,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Object p0: the name of the superclass that does not define an implicitly
///            invoked constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
noDefaultSuperConstructorExplicit = DiagnosticWithArguments(
  name: 'NO_DEFAULT_SUPER_CONSTRUCTOR',
  problemMessage:
      "The superclass '{0}' doesn't have a zero argument constructor.",
  correctionMessage:
      "Try declaring a zero argument constructor in '{0}', or explicitly "
      "invoking a different constructor in '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT',
  withArguments: _withArgumentsNoDefaultSuperConstructorExplicit,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Type p0: the name of the superclass that does not define an implicitly
///          invoked constructor
/// String p1: the name of the subclass that does not contain any explicit
///            constructors
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required String p1})
>
noDefaultSuperConstructorImplicit = DiagnosticWithArguments(
  name: 'NO_DEFAULT_SUPER_CONSTRUCTOR',
  problemMessage:
      "The superclass '{0}' doesn't have a zero argument constructor.",
  correctionMessage:
      "Try declaring a zero argument constructor in '{0}', or declaring a "
      "constructor in {1} that explicitly invokes a constructor in '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT',
  withArguments: _withArgumentsNoDefaultSuperConstructorImplicit,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the subclass
/// String p1: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
noGenerativeConstructorsInSuperclass = DiagnosticWithArguments(
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
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS',
  withArguments: _withArgumentsNoGenerativeConstructorsInSuperclass,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the first member
/// String p1: the name of the second member
/// String p2: the name of the third member
/// String p3: the name of the fourth member
/// int p4: the number of additional missing members that aren't listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
    required int p4,
  })
>
nonAbstractClassInheritsAbstractMemberFivePlus = DiagnosticWithArguments(
  name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} "
      "more.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
    required String p3,
  })
>
nonAbstractClassInheritsAbstractMemberFour = DiagnosticWithArguments(
  name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonAbstractClassInheritsAbstractMemberOne = DiagnosticWithArguments(
  name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
  problemMessage: "Missing concrete implementation of '{0}'.",
  correctionMessage:
      "Try implementing the missing method, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberOne,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the first member
/// String p1: the name of the second member
/// String p2: the name of the third member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
nonAbstractClassInheritsAbstractMemberThree = DiagnosticWithArguments(
  name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
nonAbstractClassInheritsAbstractMemberTwo = DiagnosticWithArguments(
  name: 'NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER',
  problemMessage: "Missing concrete implementations of '{0}' and '{1}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberTwo,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonBoolCondition =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_BOOL_CONDITION',
      problemMessage: "Conditions must have a static type of 'bool'.",
      correctionMessage: "Try changing the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_BOOL_CONDITION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonBoolExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_BOOL_EXPRESSION',
      problemMessage: "The expression in an assert must be of type 'bool'.",
      correctionMessage: "Try changing the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_BOOL_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonBoolNegationExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_BOOL_NEGATION_EXPRESSION',
      problemMessage: "A negation operand must have a static type of 'bool'.",
      correctionMessage: "Try changing the operand to the '!' operator.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_BOOL_NEGATION_EXPRESSION',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the lexeme of the logical operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonBoolOperand = DiagnosticWithArguments(
  name: 'NON_BOOL_OPERAND',
  problemMessage:
      "The operands of the operator '{0}' must be assignable to 'bool'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_BOOL_OPERAND',
  withArguments: _withArgumentsNonBoolOperand,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantAnnotationConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
      problemMessage: "Annotation creation can only call a const constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantCaseExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_CASE_EXPRESSION',
      problemMessage: "Case expressions must be constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantCaseExpressionFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as a case "
      "expression.",
  correctionMessage:
      "Try re-writing the switch as a series of if statements, or changing "
      "the import to not be deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantDefaultValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_DEFAULT_VALUE',
      problemMessage:
          "The default value of an optional parameter must be constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantDefaultValueFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as a default "
      "parameter value.",
  correctionMessage:
      "Try leaving the default as 'null' and initializing the parameter "
      "inside the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantListElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_LIST_ELEMENT',
      problemMessage: "The values in a const list literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the list literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantListElementFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' list literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the list literal or removing "
      "the keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_MAP_ELEMENT',
      problemMessage: "The elements in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_MAP_KEY',
      problemMessage: "The keys in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_MAP_KEY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantMapKeyFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as keys in a "
      "'const' map literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the map literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapPatternKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_MAP_PATTERN_KEY',
      problemMessage: "Key expressions in map patterns must be constants.",
      correctionMessage: "Try using constants instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_MAP_PATTERN_KEY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_MAP_VALUE',
      problemMessage: "The values in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantMapValueFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' map literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the map literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantRecordField =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_RECORD_FIELD',
      problemMessage: "The fields in a const record literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the record literal.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantRecordFieldFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as fields in a "
      "'const' record literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the record literal or removing "
      "the keyword 'deferred' from the import.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantRelationalPatternExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION',
      problemMessage: "The relational pattern expression must be a constant.",
      correctionMessage: "Try using a constant instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantSetElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTANT_SET_ELEMENT',
      problemMessage: "The values in a const set literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the set literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the function, method, or constructor having type
///            arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonConstantTypeArgument = DiagnosticWithArguments(
  name: 'NON_CONSTANT_TYPE_ARGUMENT',
  problemMessage:
      "The type arguments to '{0}' must be known at compile time, so they can't "
      "be type parameters.",
  correctionMessage: "Try changing the type argument to be a constant type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NON_CONSTANT_TYPE_ARGUMENT',
  withArguments: _withArgumentsNonConstantTypeArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonConstArgumentForConstParameter = DiagnosticWithArguments(
  name: 'NON_CONST_ARGUMENT_FOR_CONST_PARAMETER',
  problemMessage: "Argument '{0}' must be a constant.",
  correctionMessage: "Try replacing the argument with a constant.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NON_CONST_ARGUMENT_FOR_CONST_PARAMETER',
  withArguments: _withArgumentsNonConstArgumentForConstParameter,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for non-const instance creation using a constructor
/// annotated with `@literal`.
///
/// Parameters:
/// String p0: the name of the class defining the annotated constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonConstCallToLiteralConstructor = DiagnosticWithArguments(
  name: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
  problemMessage:
      "This instance creation must be 'const', because the {0} constructor is "
      "marked as '@literal'.",
  correctionMessage: "Try adding a 'const' keyword.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
  withArguments: _withArgumentsNonConstCallToLiteralConstructor,
  expectedTypes: [ExpectedType.string],
);

/// Generate a warning for non-const instance creation (with the `new` keyword)
/// using a constructor annotated with `@literal`.
///
/// Parameters:
/// String p0: the name of the class defining the annotated constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonConstCallToLiteralConstructorUsingNew = DiagnosticWithArguments(
  name: 'NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR',
  problemMessage:
      "This instance creation must be 'const', because the {0} constructor is "
      "marked as '@literal'.",
  correctionMessage: "Try replacing the 'new' keyword with 'const'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW',
  withArguments: _withArgumentsNonConstCallToLiteralConstructorUsingNew,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstGenerativeEnumConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
      problemMessage: "Generative enum constructors must be 'const'.",
      correctionMessage: "Try adding the keyword 'const'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR',
      expectedTypes: [],
    );

/// 13.2 Expression Statements: It is a compile-time error if a non-constant
/// map literal that has no explicit type arguments appears in a place where a
/// statement is expected.
///
/// No parameters.
const DiagnosticWithoutArguments
nonConstMapAsExpressionStatement = DiagnosticWithoutArgumentsImpl(
  name: 'NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
  problemMessage:
      "A non-constant map or set literal without type arguments can't be used as "
      "an expression statement.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstructorFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_CONSTRUCTOR_FACTORY',
      problemMessage: "Only a constructor can be declared to be a factory.",
      correctionMessage: "Try removing the keyword 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NON_CONSTRUCTOR_FACTORY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonCovariantTypeParameterPositionInRepresentationType = DiagnosticWithoutArgumentsImpl(
  name: 'NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE',
  problemMessage:
      "An extension type parameter can't be used in a non-covariant position of "
      "its representation type.",
  correctionMessage:
      "Try removing the type parameters from function parameter types and "
      "type parameter bounds.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NON_COVARIANT_TYPE_PARAMETER_POSITION_IN_REPRESENTATION_TYPE',
  expectedTypes: [],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
/// String unmatchedPattern: the witness pattern for the unmatched value
/// String suggestedPattern: the suggested pattern for the unmatched value
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required String unmatchedPattern,
    required String suggestedPattern,
  })
>
nonExhaustiveSwitchExpression = DiagnosticWithArguments(
  name: 'NON_EXHAUSTIVE_SWITCH_EXPRESSION',
  problemMessage:
      "The type '{0}' isn't exhaustively matched by the switch cases since it "
      "doesn't match the pattern '{1}'.",
  correctionMessage: "Try adding a wildcard pattern or cases that match '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION',
  withArguments: _withArgumentsNonExhaustiveSwitchExpression,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nonExhaustiveSwitchExpressionPrivate = DiagnosticWithArguments(
  name: 'NON_EXHAUSTIVE_SWITCH_EXPRESSION',
  problemMessage:
      "The enum '{0}' isn't exhaustively matched by the switch cases because "
      "some of the enum constants are private.",
  correctionMessage: "Try adding a wildcard pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_EXPRESSION_PRIVATE',
  withArguments: _withArgumentsNonExhaustiveSwitchExpressionPrivate,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
/// String unmatchedPattern: the witness pattern for the unmatched value
/// String suggestedPattern: the suggested pattern for the unmatched value
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required String unmatchedPattern,
    required String suggestedPattern,
  })
>
nonExhaustiveSwitchStatement = DiagnosticWithArguments(
  name: 'NON_EXHAUSTIVE_SWITCH_STATEMENT',
  problemMessage:
      "The type '{0}' isn't exhaustively matched by the switch cases since it "
      "doesn't match the pattern '{1}'.",
  correctionMessage: "Try adding a default case or cases that match '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT',
  withArguments: _withArgumentsNonExhaustiveSwitchStatement,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nonExhaustiveSwitchStatementPrivate = DiagnosticWithArguments(
  name: 'NON_EXHAUSTIVE_SWITCH_STATEMENT',
  problemMessage:
      "The enum '{0}' isn't exhaustively matched by the switch cases because "
      "some of the enum constants are private.",
  correctionMessage: "Try adding a default case.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_EXHAUSTIVE_SWITCH_STATEMENT_PRIVATE',
  withArguments: _withArgumentsNonExhaustiveSwitchStatementPrivate,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonFinalFieldInEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_FINAL_FIELD_IN_ENUM',
      problemMessage: "Enums can only declare final fields.",
      correctionMessage: "Try making the field final.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_FINAL_FIELD_IN_ENUM',
      expectedTypes: [],
    );

/// Parameters:
/// Element p0: the non-generative constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element p0})
>
nonGenerativeConstructor = DiagnosticWithArguments(
  name: 'NON_GENERATIVE_CONSTRUCTOR',
  problemMessage:
      "The generative constructor '{0}' is expected, but a factory was found.",
  correctionMessage:
      "Try calling a different constructor of the superclass, or making the "
      "called constructor not be a factory constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR',
  withArguments: _withArgumentsNonGenerativeConstructor,
  expectedTypes: [ExpectedType.element],
);

/// Parameters:
/// String p0: the name of the superclass
/// String p1: the name of the current class
/// Element p2: the implicitly called factory constructor of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required Element p2,
  })
>
nonGenerativeImplicitConstructor = DiagnosticWithArguments(
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
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_GENERATIVE_IMPLICIT_CONSTRUCTOR',
  withArguments: _withArgumentsNonGenerativeImplicitConstructor,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.element,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments nonIdentifierLibraryName =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_IDENTIFIER_LIBRARY_NAME',
      problemMessage: "The name of a library must be an identifier.",
      correctionMessage: "Try using an identifier as the name of the library.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NON_IDENTIFIER_LIBRARY_NAME',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the type that should be a valid dart:ffi native type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
nonNativeFunctionTypeArgumentToPointer = DiagnosticWithArguments(
  name: 'NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
  problemMessage:
      "Can't invoke 'asFunction' because the function signature '{0}' for the "
      "pointer isn't a valid C function signature.",
  correctionMessage:
      "Try changing the function argument in 'NativeFunction' to only use "
      "NativeTypes.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER',
  withArguments: _withArgumentsNonNativeFunctionTypeArgumentToPointer,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonNullableEqualsParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_NULLABLE_EQUALS_PARAMETER',
      problemMessage:
          "The parameter type of '==' operators should be non-nullable.",
      correctionMessage: "Try using a non-nullable type.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.NON_NULLABLE_EQUALS_PARAMETER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonPartOfDirectiveInPart = DiagnosticWithoutArgumentsImpl(
  name: 'NON_PART_OF_DIRECTIVE_IN_PART',
  problemMessage: "The part-of directive must be the only directive in a part.",
  correctionMessage:
      "Try removing the other directives, or moving them to the library for "
      "which this is a part.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonPositiveArrayDimension =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_POSITIVE_ARRAY_DIMENSION',
      problemMessage: "Array dimensions must be positive numbers.",
      correctionMessage: "Try changing the input to a positive number.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.NON_POSITIVE_ARRAY_DIMENSION',
      expectedTypes: [],
    );

/// A code indicating that the activity is set to be non resizable.
///
/// No parameters.
const DiagnosticWithoutArguments
nonResizableActivity = DiagnosticWithoutArgumentsImpl(
  name: 'NON_RESIZABLE_ACTIVITY',
  problemMessage:
      "The `<activity>` element should be allowed to be resized to allow users "
      "to take advantage of the multi-window environment on Chrome OS",
  correctionMessage:
      "Consider declaring the corresponding activity element with "
      "`resizableActivity=\"true\"` attribute.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.NON_RESIZABLE_ACTIVITY',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the field
/// Type p1: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
nonSizedTypeArgument = DiagnosticWithArguments(
  name: 'NON_SIZED_TYPE_ARGUMENT',
  problemMessage:
      "The type '{1}' isn't a valid type argument for '{0}'. The type argument "
      "must be a native integer, 'Float', 'Double', 'Pointer', or subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype "
      "of 'Struct', 'Union', or 'AbiSpecificInteger'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.NON_SIZED_TYPE_ARGUMENT',
  withArguments: _withArgumentsNonSizedTypeArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonStringLiteralAsUri =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_STRING_LITERAL_AS_URI',
      problemMessage: "The URI must be a string literal.",
      correctionMessage:
          "Try enclosing the URI in either single or double quotes.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NON_STRING_LITERAL_AS_URI',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonSyncFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_SYNC_FACTORY',
      problemMessage: "Factory bodies can't use 'async', 'async*', or 'sync*'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_SYNC_FACTORY',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name appearing where a type is expected
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonTypeAsTypeArgument = DiagnosticWithArguments(
  name: 'NON_TYPE_AS_TYPE_ARGUMENT',
  problemMessage:
      "The name '{0}' isn't a type, so it can't be used as a type argument.",
  correctionMessage:
      "Try correcting the name to an existing type, or defining a type named "
      "'{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_TYPE_AS_TYPE_ARGUMENT',
  withArguments: _withArgumentsNonTypeAsTypeArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
nonTypeInCatchClause = DiagnosticWithArguments(
  name: 'NON_TYPE_IN_CATCH_CLAUSE',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in an on-catch clause.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NON_TYPE_IN_CATCH_CLAUSE',
  withArguments: _withArgumentsNonTypeInCatchClause,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Object p0: the operator that the user is trying to define
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
nonUserDefinableOperator = DiagnosticWithArguments(
  name: 'NON_USER_DEFINABLE_OPERATOR',
  problemMessage: "The operator '{0}' isn't user definable.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.NON_USER_DEFINABLE_OPERATOR',
  withArguments: _withArgumentsNonUserDefinableOperator,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments nonVoidReturnForOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_VOID_RETURN_FOR_OPERATOR',
      problemMessage: "The return type of the operator []= must be 'void'.",
      correctionMessage: "Try changing the return type to 'void'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_VOID_RETURN_FOR_OPERATOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonVoidReturnForSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'NON_VOID_RETURN_FOR_SETTER',
      problemMessage: "The return type of the setter must be 'void' or absent.",
      correctionMessage:
          "Try removing the return type, or define a method rather than a "
          "setter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NON_VOID_RETURN_FOR_SETTER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments normalBeforeOptionalParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'NORMAL_BEFORE_OPTIONAL_PARAMETERS',
      problemMessage:
          "Normal parameters must occur before optional parameters.",
      correctionMessage:
          "Try moving all of the normal parameters before the optional "
          "parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.NORMAL_BEFORE_OPTIONAL_PARAMETERS',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notAssignedPotentiallyNonNullableLocalVariable = DiagnosticWithArguments(
  name: 'NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
  problemMessage:
      "The non-nullable local variable '{0}' must be assigned before it can be "
      "used.",
  correctionMessage:
      "Try giving it an initializer expression, or ensure that it's assigned "
      "on every execution path.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE',
  withArguments: _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name that is not a type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notAType = DiagnosticWithArguments(
  name: 'NOT_A_TYPE',
  problemMessage: "{0} isn't a type.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_A_TYPE',
  withArguments: _withArgumentsNotAType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the operator that is not a binary operator.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notBinaryOperator = DiagnosticWithArguments(
  name: 'NOT_BINARY_OPERATOR',
  problemMessage: "'{0}' isn't a binary operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_BINARY_OPERATOR',
  withArguments: _withArgumentsNotBinaryOperator,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// int p0: the expected number of required arguments
/// int p1: the actual number of positional arguments given
/// String p2: name of the function or method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required int p0,
    required int p1,
    required String p2,
  })
>
notEnoughPositionalArgumentsNamePlural = DiagnosticWithArguments(
  name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
  problemMessage: "{0} positional arguments expected by '{2}', but {1} found.",
  correctionMessage: "Try adding the missing arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsNamePlural,
  expectedTypes: [ExpectedType.int, ExpectedType.int, ExpectedType.string],
);

/// Parameters:
/// String p0: name of the function or method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notEnoughPositionalArgumentsNameSingular = DiagnosticWithArguments(
  name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
  problemMessage: "1 positional argument expected by '{0}', but 0 found.",
  correctionMessage: "Try adding the missing argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsNameSingular,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// int p0: the expected number of required arguments
/// int p1: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
notEnoughPositionalArgumentsPlural = DiagnosticWithArguments(
  name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
  problemMessage: "{0} positional arguments expected, but {1} found.",
  correctionMessage: "Try adding the missing arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsPlural,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments notEnoughPositionalArgumentsSingular =
    DiagnosticWithoutArgumentsImpl(
      name: 'NOT_ENOUGH_POSITIONAL_ARGUMENTS',
      problemMessage: "1 positional argument expected, but 0 found.",
      correctionMessage: "Try adding the missing argument.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the field that is not initialized
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notInitializedNonNullableInstanceField = DiagnosticWithArguments(
  name: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
  problemMessage: "Non-nullable instance field '{0}' must be initialized.",
  correctionMessage:
      "Try adding an initializer expression, or a generative constructor "
      "that initializes it, or mark it 'late'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
  withArguments: _withArgumentsNotInitializedNonNullableInstanceField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the field that is not initialized
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notInitializedNonNullableInstanceFieldConstructor = DiagnosticWithArguments(
  name: 'NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD',
  problemMessage: "Non-nullable instance field '{0}' must be initialized.",
  correctionMessage:
      "Try adding an initializer expression, or add a field initializer in "
      "this constructor, or mark it 'late'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_INSTANCE_FIELD_CONSTRUCTOR',
  withArguments:
      _withArgumentsNotInitializedNonNullableInstanceFieldConstructor,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
notInitializedNonNullableVariable = DiagnosticWithArguments(
  name: 'NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
  problemMessage: "The non-nullable variable '{0}' must be initialized.",
  correctionMessage: "Try adding an initializer expression.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE',
  withArguments: _withArgumentsNotInitializedNonNullableVariable,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments notInstantiatedBound =
    DiagnosticWithoutArgumentsImpl(
      name: 'NOT_INSTANTIATED_BOUND',
      problemMessage: "Type parameter bound types must be instantiated.",
      correctionMessage:
          "Try adding type arguments to the type parameter bound.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NOT_INSTANTIATED_BOUND',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments notIterableSpread =
    DiagnosticWithoutArgumentsImpl(
      name: 'NOT_ITERABLE_SPREAD',
      problemMessage:
          "Spread elements in list or set literals must implement 'Iterable'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NOT_ITERABLE_SPREAD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments notMapSpread = DiagnosticWithoutArgumentsImpl(
  name: 'NOT_MAP_SPREAD',
  problemMessage: "Spread elements in map literals must implement 'Map'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_MAP_SPREAD',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
notNullAwareNullSpread = DiagnosticWithoutArgumentsImpl(
  name: 'NOT_NULL_AWARE_NULL_SPREAD',
  problemMessage:
      "The Null-typed expression can't be used with a non-null-aware spread.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.NOT_NULL_AWARE_NULL_SPREAD',
  expectedTypes: [],
);

/// A code indicating that the touchscreen feature is not specified in the
/// manifest.
///
/// No parameters.
const DiagnosticWithoutArguments
noTouchscreenFeature = DiagnosticWithoutArgumentsImpl(
  name: 'NO_TOUCHSCREEN_FEATURE',
  problemMessage:
      "The default \"android.hardware.touchscreen\" needs to be optional for "
      "Chrome OS.",
  correctionMessage:
      "Consider adding <uses-feature "
      "android:name=\"android.hardware.touchscreen\" android:required=\"false\" "
      "/> to the manifest.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.NO_TOUCHSCREEN_FEATURE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nullableTypeInCatchClause = DiagnosticWithoutArgumentsImpl(
  name: 'NULLABLE_TYPE_IN_CATCH_CLAUSE',
  problemMessage:
      "A potentially nullable type can't be used in an 'on' clause because it "
      "isn't valid to throw a nullable expression.",
  correctionMessage: "Try using a non-nullable type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NULLABLE_TYPE_IN_CATCH_CLAUSE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInExtendsClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
      problemMessage: "A class can't extend a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_EXTENDS_CLAUSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInImplementsClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
      problemMessage:
          "A class, mixin, or extension type can't implement a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_IMPLEMENTS_CLAUSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInOnClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'NULLABLE_TYPE_IN_ON_CLAUSE',
      problemMessage:
          "A mixin can't have a nullable type as a superclass constraint.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInWithClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'NULLABLE_TYPE_IN_WITH_CLAUSE',
      problemMessage: "A class or mixin can't mix in a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.NULLABLE_TYPE_IN_WITH_CLAUSE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the method being invoked
/// String p1: the type argument associated with the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
nullArgumentToNonNullType = DiagnosticWithArguments(
  name: 'NULL_ARGUMENT_TO_NON_NULL_TYPE',
  problemMessage:
      "'{0}' shouldn't be called with a 'null' argument for the non-nullable "
      "type argument '{1}'.",
  correctionMessage: "Try adding a non-null argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NULL_ARGUMENT_TO_NON_NULL_TYPE',
  withArguments: _withArgumentsNullArgumentToNonNullType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
nullAwareCascadeOutOfOrder = DiagnosticWithoutArgumentsImpl(
  name: 'NULL_AWARE_CASCADE_OUT_OF_ORDER',
  problemMessage:
      "The '?..' cascade operator must be first in the cascade sequence.",
  correctionMessage:
      "Try moving the '?..' operator to be the first cascade operator in the "
      "sequence.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.NULL_AWARE_CASCADE_OUT_OF_ORDER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nullCheckAlwaysFails = DiagnosticWithoutArgumentsImpl(
  name: 'NULL_CHECK_ALWAYS_FAILS',
  problemMessage:
      "This null-check will always throw an exception because the expression "
      "will always evaluate to 'null'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.NULL_CHECK_ALWAYS_FAILS',
  expectedTypes: [],
);

/// 7.9 Superclasses: It is a compile-time error to specify an extends clause
/// for class Object.
///
/// No parameters.
const DiagnosticWithoutArguments objectCannotExtendAnotherClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
      problemMessage: "The class 'Object' can't extend any other class.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments obsoleteColonForDefaultValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'OBSOLETE_COLON_FOR_DEFAULT_VALUE',
      problemMessage:
          "Using a colon as the separator before a default value is no longer "
          "supported.",
      correctionMessage: "Try replacing the colon with an equal sign.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.OBSOLETE_COLON_FOR_DEFAULT_VALUE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the interface that is implemented more than once
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
onRepeated = DiagnosticWithArguments(
  name: 'ON_REPEATED',
  problemMessage:
      "The type '{0}' can be included in the superclass constraints only once.",
  correctionMessage: "Try removing all except one occurrence of the type name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.ON_REPEATED',
  withArguments: _withArgumentsOnRepeated,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments optionalParameterInOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'OPTIONAL_PARAMETER_IN_OPERATOR',
      problemMessage:
          "Optional parameters aren't allowed when defining an operator.",
      correctionMessage: "Try removing the optional parameters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR',
      expectedTypes: [],
    );

/// Parameters:
/// String string: undocumented
/// String string2: undocumented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String string,
    required String string2,
  })
>
outOfOrderClauses = DiagnosticWithArguments(
  name: 'OUT_OF_ORDER_CLAUSES',
  problemMessage: "The '{0}' clause must come before the '{1}' clause.",
  correctionMessage: "Try moving the '{0}' clause before the '{1}' clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.OUT_OF_ORDER_CLAUSES',
  withArguments: _withArgumentsOutOfOrderClauses,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// A field with the override annotation does not override a getter or setter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingField =
    DiagnosticWithoutArgumentsImpl(
      name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
      problemMessage:
          "The field doesn't override an inherited getter or setter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_FIELD',
      expectedTypes: [],
    );

/// A getter with the override annotation does not override an existing getter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingGetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
      problemMessage: "The getter doesn't override an inherited getter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_GETTER',
      expectedTypes: [],
    );

/// A method with the override annotation does not override an existing method.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
      problemMessage: "The method doesn't override an inherited method.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD',
      expectedTypes: [],
    );

/// A setter with the override annotation does not override an existing setter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'OVERRIDE_ON_NON_OVERRIDING_MEMBER',
      problemMessage: "The setter doesn't override an inherited setter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.OVERRIDE_ON_NON_OVERRIDING_SETTER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments packedAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'PACKED_ANNOTATION',
      problemMessage: "Structs must have at most one 'Packed' annotation.",
      correctionMessage: "Try removing extra 'Packed' annotations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'FfiCode.PACKED_ANNOTATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
packedAnnotationAlignment = DiagnosticWithoutArgumentsImpl(
  name: 'PACKED_ANNOTATION_ALIGNMENT',
  problemMessage: "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
  correctionMessage:
      "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.PACKED_ANNOTATION_ALIGNMENT',
  expectedTypes: [],
);

/// An error code indicating that there is a syntactic error in the file.
///
/// Parameters:
/// Object p0: the error message from the parse error
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
parseError = DiagnosticWithArguments(
  name: 'PARSE_ERROR',
  problemMessage: "{0}",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'AnalysisOptionsErrorCode.PARSE_ERROR',
  withArguments: _withArgumentsParseError,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of expected library name
/// String p1: the non-matching actual library name from the "part of"
///            declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
partOfDifferentLibrary = DiagnosticWithArguments(
  name: 'PART_OF_DIFFERENT_LIBRARY',
  problemMessage: "Expected this library to be part of '{0}', not '{1}'.",
  correctionMessage:
      "Try including a different part, or changing the name of the library "
      "in the part's part-of directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY',
  withArguments: _withArgumentsPartOfDifferentLibrary,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments partOfName = DiagnosticWithoutArgumentsImpl(
  name: 'PART_OF_NAME',
  problemMessage:
      "The 'part of' directive can't use a name with the enhanced-parts feature.",
  correctionMessage: "Try using 'part of' with a URI instead.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.PART_OF_NAME',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
partOfNonPart = DiagnosticWithArguments(
  name: 'PART_OF_NON_PART',
  problemMessage: "The included part '{0}' must have a part-of directive.",
  correctionMessage: "Try adding a part-of directive to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PART_OF_NON_PART',
  withArguments: _withArgumentsPartOfNonPart,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the non-matching actual library name from the "part of"
///            declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
partOfUnnamedLibrary = DiagnosticWithArguments(
  name: 'PART_OF_UNNAMED_LIBRARY',
  problemMessage:
      "The library is unnamed. A URI is expected, not a library name '{0}', in "
      "the part-of directive.",
  correctionMessage:
      "Try changing the part-of directive to a URI, or try including a "
      "different part.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY',
  withArguments: _withArgumentsPartOfUnnamedLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the path to the dependency as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
pathDoesNotExist = DiagnosticWithArguments(
  name: 'PATH_DOES_NOT_EXIST',
  problemMessage: "The path '{0}' doesn't exist.",
  correctionMessage:
      "Try creating the referenced path or using a path that exists.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.PATH_DOES_NOT_EXIST',
  withArguments: _withArgumentsPathDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the path as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
pathNotPosix = DiagnosticWithArguments(
  name: 'PATH_NOT_POSIX',
  problemMessage: "The path '{0}' isn't a POSIX-style path.",
  correctionMessage: "Try converting the value to a POSIX-style path.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.PATH_NOT_POSIX',
  withArguments: _withArgumentsPathNotPosix,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the path to the dependency as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
pathPubspecDoesNotExist = DiagnosticWithArguments(
  name: 'PATH_PUBSPEC_DOES_NOT_EXIST',
  problemMessage: "The directory '{0}' doesn't contain a pubspec.",
  correctionMessage:
      "Try creating a pubspec in the referenced directory or using a path "
      "that has a pubspec.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST',
  withArguments: _withArgumentsPathPubspecDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Name name: undocumented
const DiagnosticCode patternAssignmentDeclaresVariable =
    DiagnosticCodeWithExpectedTypes(
      name: 'PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
      problemMessage:
          "Variable '{0}' can't be declared in a pattern assignment.",
      correctionMessage:
          "Try using a preexisting variable or changing the assignment to a "
          "pattern variable declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.PATTERN_ASSIGNMENT_DECLARES_VARIABLE',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments patternAssignmentNotLocalVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE',
      problemMessage:
          "Only local variables can be assigned in pattern assignments.",
      correctionMessage: "Try assigning to a local variable.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.PATTERN_ASSIGNMENT_NOT_LOCAL_VARIABLE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments patternConstantFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY',
      problemMessage:
          "Constant values from a deferred library can't be used in patterns.",
      correctionMessage: "Try removing the keyword 'deferred' from the import.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.PATTERN_CONSTANT_FROM_DEFERRED_LIBRARY',
      expectedTypes: [],
    );

/// Parameters:
/// Type p0: the matched value type
/// Type p1: the required pattern type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
patternNeverMatchesValueType = DiagnosticWithArguments(
  name: 'PATTERN_NEVER_MATCHES_VALUE_TYPE',
  problemMessage:
      "The matched value type '{0}' can never match the required type '{1}'.",
  correctionMessage: "Try using a different pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.PATTERN_NEVER_MATCHES_VALUE_TYPE',
  withArguments: _withArgumentsPatternNeverMatchesValueType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the matched type
/// Type p1: the required type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
patternTypeMismatchInIrrefutableContext = DiagnosticWithArguments(
  name: 'PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT',
  problemMessage:
      "The matched value of type '{0}' isn't assignable to the required type "
      "'{1}'.",
  correctionMessage:
      "Try changing the required type of the pattern, or the matched value "
      "type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.PATTERN_TYPE_MISMATCH_IN_IRREFUTABLE_CONTEXT',
  withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
patternVariableAssignmentInsideGuard = DiagnosticWithoutArgumentsImpl(
  name: 'PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD',
  problemMessage:
      "Pattern variables can't be assigned inside the guard of the enclosing "
      "guarded pattern.",
  correctionMessage: "Try assigning to a different variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PATTERN_VARIABLE_ASSIGNMENT_INSIDE_GUARD',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
patternVariableDeclarationOutsideFunctionOrMethod = DiagnosticWithoutArgumentsImpl(
  name: 'PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
  problemMessage:
      "A pattern variable declaration may not appear outside a function or "
      "method.",
  correctionMessage:
      "Try declaring ordinary variables and assigning from within a function "
      "or method.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName:
      'ParserErrorCode.PATTERN_VARIABLE_DECLARATION_OUTSIDE_FUNCTION_OR_METHOD',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
patternVariableSharedCaseScopeDifferentFinalityOrType = DiagnosticWithArguments(
  name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
  problemMessage:
      "The variable '{0}' doesn't have the same type and/or finality in all "
      "cases that share this body.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "all cases.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE',
  withArguments:
      _withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
patternVariableSharedCaseScopeHasLabel = DiagnosticWithArguments(
  name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
  problemMessage:
      "The variable '{0}' is not available because there is a label or 'default' "
      "case.",
  correctionMessage:
      "Try removing the label, or providing the 'default' case with its own "
      "body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL',
  withArguments: _withArgumentsPatternVariableSharedCaseScopeHasLabel,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
patternVariableSharedCaseScopeNotAllCases = DiagnosticWithArguments(
  name: 'INVALID_PATTERN_VARIABLE_IN_SHARED_CASE_SCOPE',
  problemMessage:
      "The variable '{0}' is available in some, but not all cases that share "
      "this body.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "all cases.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES',
  withArguments: _withArgumentsPatternVariableSharedCaseScopeNotAllCases,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified permission is not supported on Chrome
/// OS.
///
/// Parameters:
/// Object p0: the name of the feature tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
permissionImpliesUnsupportedHardware = DiagnosticWithArguments(
  name: 'PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
  problemMessage:
      "Permission makes app incompatible for Chrome OS, consider adding optional "
      "{0} feature tag,",
  correctionMessage:
      " Try adding `<uses-feature android:name=\"{0}\"  "
      "android:required=\"false\">`.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
  withArguments: _withArgumentsPermissionImpliesUnsupportedHardware,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments platformValueDisallowed =
    DiagnosticWithoutArgumentsImpl(
      name: 'PLATFORM_VALUE_DISALLOWED',
      problemMessage: "Keys in the `platforms` field can't have values.",
      correctionMessage: "Try removing the value, while keeping the key.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.PLATFORM_VALUE_DISALLOWED',
      expectedTypes: [],
    );

/// An error code indicating plugins have been specified in an "inner"
/// analysis options file.
///
/// Parameters:
/// String contextRoot: the root of the analysis context
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String contextRoot})
>
pluginsInInnerOptions = DiagnosticWithArguments(
  name: 'PLUGINS_IN_INNER_OPTIONS',
  problemMessage:
      "Plugins can only be specified in the root of a pub workspace or the root "
      "of a package that isn't in a workspace.",
  correctionMessage:
      "Try specifying plugins in an analysis options file at '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.PLUGINS_IN_INNER_OPTIONS',
  withArguments: _withArgumentsPluginsInInnerOptions,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments positionalAfterNamedArgument =
    DiagnosticWithoutArgumentsImpl(
      name: 'POSITIONAL_AFTER_NAMED_ARGUMENT',
      problemMessage: "Positional arguments must occur before named arguments.",
      correctionMessage:
          "Try moving all of the positional arguments before the named "
          "arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments positionalFieldInObjectPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'POSITIONAL_FIELD_IN_OBJECT_PATTERN',
      problemMessage: "Object patterns can only use named fields.",
      correctionMessage: "Try specifying the field name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.POSITIONAL_FIELD_IN_OBJECT_PATTERN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
positionalParameterOutsideGroup = DiagnosticWithoutArgumentsImpl(
  name: 'POSITIONAL_PARAMETER_OUTSIDE_GROUP',
  problemMessage:
      "Positional parameters must be enclosed in square brackets ('[' and ']').",
  correctionMessage:
      "Try surrounding the positional parameters in square brackets.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.POSITIONAL_PARAMETER_OUTSIDE_GROUP',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
positionalSuperFormalParameterWithPositionalArgument = DiagnosticWithoutArgumentsImpl(
  name: 'POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
  problemMessage:
      "Positional super parameters can't be used when the super constructor "
      "invocation has a positional argument.",
  correctionMessage:
      "Try making all the positional parameters passed to the super "
      "constructor be either all super parameters or all normal parameters.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.POSITIONAL_SUPER_FORMAL_PARAMETER_WITH_POSITIONAL_ARGUMENT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
prefixAfterCombinator = DiagnosticWithoutArgumentsImpl(
  name: 'PREFIX_AFTER_COMBINATOR',
  problemMessage:
      "The prefix ('as' clause) should come before any show/hide combinators.",
  correctionMessage: "Try moving the prefix before the combinators.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.PREFIX_AFTER_COMBINATOR',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
prefixCollidesWithTopLevelMember = DiagnosticWithArguments(
  name: 'PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
  problemMessage:
      "The name '{0}' is already used as an import prefix and can't be used to "
      "name a top-level element.",
  correctionMessage: "Try renaming either the top-level element or the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER',
  withArguments: _withArgumentsPrefixCollidesWithTopLevelMember,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
prefixIdentifierNotFollowedByDot = DiagnosticWithArguments(
  name: 'PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
  problemMessage:
      "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
  correctionMessage:
      "Try correcting the name to refer to something other than a prefix, or "
      "renaming the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT',
  withArguments: _withArgumentsPrefixIdentifierNotFollowedByDot,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the prefix being shadowed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
prefixShadowedByLocalDeclaration = DiagnosticWithArguments(
  name: 'PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
  problemMessage:
      "The prefix '{0}' can't be used here because it's shadowed by a local "
      "declaration.",
  correctionMessage: "Try renaming either the prefix or the local declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PREFIX_SHADOWED_BY_LOCAL_DECLARATION',
  withArguments: _withArgumentsPrefixShadowedByLocalDeclaration,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the private name that collides
/// String p1: the name of the first mixin
/// String p2: the name of the second mixin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
privateCollisionInMixinApplication = DiagnosticWithArguments(
  name: 'PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
  problemMessage:
      "The private name '{0}', defined by '{1}', conflicts with the same name "
      "defined by '{2}'.",
  correctionMessage: "Try removing '{1}' from the 'with' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION',
  withArguments: _withArgumentsPrivateCollisionInMixinApplication,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments
privateNamedNonFieldParameter = DiagnosticWithoutArgumentsImpl(
  name: 'PRIVATE_NAMED_NON_FIELD_PARAMETER',
  problemMessage:
      "Named parameters that don't refer to instance variables can't start with "
      "underscore.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.PRIVATE_NAMED_NON_FIELD_PARAMETER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
privateNamedParameterWithoutPublicName = DiagnosticWithoutArgumentsImpl(
  name: 'PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME',
  problemMessage:
      "A private named parameter must be a public identifier after removing the "
      "leading underscore.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.PRIVATE_NAMED_PARAMETER_WITHOUT_PUBLIC_NAME',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments privateOptionalParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'PRIVATE_OPTIONAL_PARAMETER',
      problemMessage: "Named parameters can't start with an underscore.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.PRIVATE_OPTIONAL_PARAMETER',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
privateSetter = DiagnosticWithArguments(
  name: 'PRIVATE_SETTER',
  problemMessage:
      "The setter '{0}' is private and can't be accessed outside the library "
      "that declares it.",
  correctionMessage: "Try making it public.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.PRIVATE_SETTER',
  withArguments: _withArgumentsPrivateSetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
readPotentiallyUnassignedFinal = DiagnosticWithArguments(
  name: 'READ_POTENTIALLY_UNASSIGNED_FINAL',
  problemMessage:
      "The final variable '{0}' can't be read because it's potentially "
      "unassigned at this point.",
  correctionMessage: "Ensure that it is assigned on necessary execution paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.READ_POTENTIALLY_UNASSIGNED_FINAL',
  withArguments: _withArgumentsReadPotentiallyUnassignedFinal,
  expectedTypes: [ExpectedType.string],
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
const DiagnosticWithoutArguments
receiverOfTypeNever = DiagnosticWithoutArgumentsImpl(
  name: 'RECEIVER_OF_TYPE_NEVER',
  problemMessage:
      "The receiver is of type 'Never', and will never complete with a value.",
  correctionMessage:
      "Try checking for throw expressions or type errors in the receiver",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.RECEIVER_OF_TYPE_NEVER',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
recordLiteralOnePositionalNoTrailingComma = DiagnosticWithoutArgumentsImpl(
  name: 'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
  problemMessage:
      "A record literal with exactly one positional field requires a trailing "
      "comma.",
  correctionMessage: "Try adding a trailing comma.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
  expectedTypes: [],
);

/// This is similar to
/// ParserErrorCode.recordLiteralOnePositionalNoTrailingComma, but
/// it is reported at type analysis time, based on a type
/// incompatibility, rather than at parse time.
///
/// No parameters.
const DiagnosticWithoutArguments
recordLiteralOnePositionalNoTrailingCommaByType = DiagnosticWithoutArgumentsImpl(
  name: 'RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA',
  problemMessage:
      "A record literal with exactly one positional field requires a trailing "
      "comma.",
  correctionMessage: "Try adding a trailing comma.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.RECORD_LITERAL_ONE_POSITIONAL_NO_TRAILING_COMMA_BY_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments recordTypeOnePositionalNoTrailingComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
      problemMessage:
          "A record type with exactly one positional field requires a trailing "
          "comma.",
      correctionMessage: "Try adding a trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName:
          'ParserErrorCode.RECORD_TYPE_ONE_POSITIONAL_NO_TRAILING_COMMA',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments recursiveCompileTimeConstant =
    DiagnosticWithoutArgumentsImpl(
      name: 'RECURSIVE_COMPILE_TIME_CONSTANT',
      problemMessage: "The compile-time constant expression depends on itself.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments recursiveConstantConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'RECURSIVE_CONSTANT_CONSTRUCTOR',
      problemMessage: "The constant constructor depends on itself.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.RECURSIVE_CONSTANT_CONSTRUCTOR',
      expectedTypes: [],
    );

/// TODO(scheglov): review this later, there are no explicit "it is a
/// compile-time error" in specification. But it was added to the co19 and
/// there is same error for factories.
///
/// https://code.google.com/p/dart/issues/detail?id=954
///
/// No parameters.
const DiagnosticWithoutArguments
recursiveConstructorRedirect = DiagnosticWithoutArgumentsImpl(
  name: 'RECURSIVE_CONSTRUCTOR_REDIRECT',
  problemMessage:
      "Constructors can't redirect to themselves either directly or indirectly.",
  correctionMessage:
      "Try changing one of the constructors in the loop to not redirect.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
recursiveFactoryRedirect = DiagnosticWithoutArgumentsImpl(
  name: 'RECURSIVE_CONSTRUCTOR_REDIRECT',
  problemMessage:
      "Constructors can't redirect to themselves either directly or indirectly.",
  correctionMessage:
      "Try changing one of the constructors in the loop to not redirect.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT',
  expectedTypes: [],
);

/// An error code indicating a specified include file includes itself recursively.
///
/// Parameters:
/// Object p0: the URI of the file to be included
/// Object p1: the path of the file containing the include directive
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
recursiveIncludeFile = DiagnosticWithArguments(
  name: 'RECURSIVE_INCLUDE_FILE',
  problemMessage:
      "The include file '{0}' in '{1}' includes itself recursively.",
  correctionMessage:
      "Try changing the chain of 'include's to not re-include this file.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.RECURSIVE_INCLUDE_FILE',
  withArguments: _withArgumentsRecursiveIncludeFile,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the class that implements itself recursively
/// String p1: a string representation of the implements loop
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
recursiveInterfaceInheritance = DiagnosticWithArguments(
  name: 'RECURSIVE_INTERFACE_INHERITANCE',
  problemMessage: "'{0}' can't be a superinterface of itself: {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
recursiveInterfaceInheritanceExtends = DiagnosticWithArguments(
  name: 'RECURSIVE_INTERFACE_INHERITANCE',
  problemMessage: "'{0}' can't extend itself.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_EXTENDS',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
recursiveInterfaceInheritanceImplements = DiagnosticWithArguments(
  name: 'RECURSIVE_INTERFACE_INHERITANCE',
  problemMessage: "'{0}' can't implement itself.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_IMPLEMENTS',
  withArguments: _withArgumentsRecursiveInterfaceInheritanceImplements,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the mixin that constraints itself recursively
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
recursiveInterfaceInheritanceOn = DiagnosticWithArguments(
  name: 'RECURSIVE_INTERFACE_INHERITANCE',
  problemMessage: "'{0}' can't use itself as a superclass constraint.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_ON',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
recursiveInterfaceInheritanceWith = DiagnosticWithArguments(
  name: 'RECURSIVE_INTERFACE_INHERITANCE',
  problemMessage: "'{0}' can't use itself as a mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_WITH',
  withArguments: _withArgumentsRecursiveInterfaceInheritanceWith,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating the use of a redeclare annotation on a member that does not redeclare.
///
/// Parameters:
/// String p0: the kind of member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
redeclareOnNonRedeclaringMember = DiagnosticWithArguments(
  name: 'REDECLARE_ON_NON_REDECLARING_MEMBER',
  problemMessage:
      "The {0} doesn't redeclare a {0} declared in a superinterface.",
  correctionMessage:
      "Try updating this member to match a declaration in a superinterface, "
      "or removing the redeclare annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.REDECLARE_ON_NON_REDECLARING_MEMBER',
  withArguments: _withArgumentsRedeclareOnNonRedeclaringMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor
/// String p1: the name of the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
redirectGenerativeToMissingConstructor = DiagnosticWithArguments(
  name: 'REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
  problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
  correctionMessage:
      "Try redirecting to a different constructor, or defining the "
      "constructor named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR',
  withArguments: _withArgumentsRedirectGenerativeToMissingConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
redirectGenerativeToNonGenerativeConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
  problemMessage:
      "Generative constructors can't redirect to a factory constructor.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
redirectingConstructorWithBody = DiagnosticWithoutArgumentsImpl(
  name: 'REDIRECTING_CONSTRUCTOR_WITH_BODY',
  problemMessage: "Redirecting constructors can't have a body.",
  correctionMessage:
      "Try removing the body, or not making this a redirecting constructor.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.REDIRECTING_CONSTRUCTOR_WITH_BODY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments redirectionInNonFactoryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
      problemMessage: "Only factory constructor can specify '=' redirection.",
      correctionMessage:
          "Try making this a factory constructor, or remove the redirection.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.REDIRECTION_IN_NON_FACTORY_CONSTRUCTOR',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the redirecting constructor
/// String p1: the name of the abstract class defining the constructor being
///            redirected to
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
redirectToAbstractClassConstructor = DiagnosticWithArguments(
  name: 'REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
  problemMessage:
      "The redirecting constructor '{0}' can't redirect to a constructor of the "
      "abstract class '{1}'.",
  correctionMessage: "Try redirecting to a constructor of a different class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_ABSTRACT_CLASS_CONSTRUCTOR',
  withArguments: _withArgumentsRedirectToAbstractClassConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the redirected constructor
/// Type p1: the name of the redirecting constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
redirectToInvalidFunctionType = DiagnosticWithArguments(
  name: 'REDIRECT_TO_INVALID_FUNCTION_TYPE',
  problemMessage:
      "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_INVALID_FUNCTION_TYPE',
  withArguments: _withArgumentsRedirectToInvalidFunctionType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the name of the redirected constructor's return type
/// Type p1: the name of the redirecting constructor's return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
redirectToInvalidReturnType = DiagnosticWithArguments(
  name: 'REDIRECT_TO_INVALID_RETURN_TYPE',
  problemMessage:
      "The return type '{0}' of the redirected constructor isn't a subtype of "
      "'{1}'.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_INVALID_RETURN_TYPE',
  withArguments: _withArgumentsRedirectToInvalidReturnType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the constructor
/// Type p1: the name of the class containing the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
redirectToMissingConstructor = DiagnosticWithArguments(
  name: 'REDIRECT_TO_MISSING_CONSTRUCTOR',
  problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
  correctionMessage:
      "Try redirecting to a different constructor, or define the constructor "
      "named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR',
  withArguments: _withArgumentsRedirectToMissingConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the non-type referenced in the redirect
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
redirectToNonClass = DiagnosticWithArguments(
  name: 'REDIRECT_TO_NON_CLASS',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in a redirected "
      "constructor.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_NON_CLASS',
  withArguments: _withArgumentsRedirectToNonClass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments redirectToNonConstConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'REDIRECT_TO_NON_CONST_CONSTRUCTOR',
      problemMessage:
          "A constant redirecting constructor can't redirect to a non-constant "
          "constructor.",
      correctionMessage: "Try redirecting to a different constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
redirectToTypeAliasExpandsToTypeParameter = DiagnosticWithoutArgumentsImpl(
  name: 'REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  problemMessage:
      "A redirecting constructor can't redirect to a type alias that expands to "
      "a type parameter.",
  correctionMessage: "Try replacing it with a class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.REDIRECT_TO_TYPE_ALIAS_EXPANDS_TO_TYPE_PARAMETER',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
referencedBeforeDeclaration = DiagnosticWithArguments(
  name: 'REFERENCED_BEFORE_DECLARATION',
  problemMessage:
      "Local variable '{0}' can't be referenced before it is declared.",
  correctionMessage:
      "Try moving the declaration to before the first use, or renaming the "
      "local variable so that it doesn't hide a name from an enclosing "
      "scope.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION',
  withArguments: _withArgumentsReferencedBeforeDeclaration,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments
refutablePatternInIrrefutableContext = DiagnosticWithoutArgumentsImpl(
  name: 'REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT',
  problemMessage: "Refutable patterns can't be used in an irrefutable context.",
  correctionMessage:
      "Try using an if-case, a 'switch' statement, or a 'switch' expression "
      "instead.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the operand type
/// Type p1: the parameter type of the invoked operator
/// String p2: the name of the invoked operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
relationalPatternOperandTypeNotAssignable = DiagnosticWithArguments(
  name: 'RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The constant expression type '{0}' is not assignable to the parameter "
      "type '{1}' of the '{2}' operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsRelationalPatternOperandTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
relationalPatternOperatorReturnTypeNotAssignableToBool =
    DiagnosticWithoutArgumentsImpl(
      name: 'RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL',
      problemMessage:
          "The return type of operators used in relational patterns must be "
          "assignable to 'bool'.",
      correctionMessage:
          "Try updating the operator declaration to return 'bool'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.RELATIONAL_PATTERN_OPERATOR_RETURN_TYPE_NOT_ASSIGNABLE_TO_BOOL',
      expectedTypes: [],
    );

/// An error code indicating a removed lint rule.
///
/// Parameters:
/// String p0: the rule name
/// String p1: the SDK version in which the lint was removed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
removedLint = DiagnosticWithArguments(
  name: 'REMOVED_LINT',
  problemMessage: "'{0}' was removed in Dart '{1}'",
  correctionMessage: "Remove the reference to '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.REMOVED_LINT',
  withArguments: _withArgumentsRemovedLint,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating use of a removed lint rule.
///
/// Parameters:
/// Object p0: the rule name
/// Object p1: the SDK version in which the lint was removed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
removedLintUse = DiagnosticWithArguments(
  name: 'REMOVED_LINT_USE',
  problemMessage: "'{0}' was removed in Dart '{1}'",
  correctionMessage: "Remove the reference to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.REMOVED_LINT_USE',
  withArguments: _withArgumentsRemovedLintUse,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// An error code indicating a removed lint rule.
///
/// Parameters:
/// String p0: the rule name
/// String p1: the SDK version in which the lint was removed
/// String p2: the name of a replacing lint
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
replacedLint = DiagnosticWithArguments(
  name: 'REPLACED_LINT',
  problemMessage: "'{0}' was replaced by '{2}' in Dart '{1}'.",
  correctionMessage: "Replace '{0}' with '{1}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.REPLACED_LINT',
  withArguments: _withArgumentsReplacedLint,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// An error code indicating use of a removed lint rule.
///
/// Parameters:
/// Object p0: the rule name
/// Object p1: the SDK version in which the lint was removed
/// Object p2: the name of a replacing lint
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
replacedLintUse = DiagnosticWithArguments(
  name: 'REPLACED_LINT_USE',
  problemMessage: "'{0}' was replaced by '{2}' in Dart '{1}'.",
  correctionMessage: "Replace '{0}' with '{1}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.REPLACED_LINT_USE',
  withArguments: _withArgumentsReplacedLintUse,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments representationFieldModifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'REPRESENTATION_FIELD_MODIFIER',
      problemMessage: "Representation fields can't have modifiers.",
      correctionMessage: "Try removing the modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.REPRESENTATION_FIELD_MODIFIER',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments representationFieldTrailingComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'REPRESENTATION_FIELD_TRAILING_COMMA',
      problemMessage: "The representation field can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.REPRESENTATION_FIELD_TRAILING_COMMA',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments restElementInMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'REST_ELEMENT_IN_MAP_PATTERN',
      problemMessage: "A map pattern can't contain a rest pattern.",
      correctionMessage: "Try removing the rest pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.REST_ELEMENT_IN_MAP_PATTERN',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments rethrowOutsideCatch =
    DiagnosticWithoutArgumentsImpl(
      name: 'RETHROW_OUTSIDE_CATCH',
      problemMessage: "A rethrow must be inside of a catch clause.",
      correctionMessage:
          "Try moving the expression into a catch clause, or using a 'throw' "
          "expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments returnInGenerativeConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'RETURN_IN_GENERATIVE_CONSTRUCTOR',
      problemMessage: "Constructors can't return values.",
      correctionMessage:
          "Try removing the return statement or using a factory constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
returnInGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'RETURN_IN_GENERATOR',
  problemMessage:
      "Can't return a value from a generator function that uses the 'async*' or "
      "'sync*' modifier.",
  correctionMessage:
      "Try replacing 'return' with 'yield', using a block function body, or "
      "changing the method body modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RETURN_IN_GENERATOR',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the annotated function being invoked
/// String p1: the name of the function containing the return
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
returnOfDoNotStore = DiagnosticWithArguments(
  name: 'RETURN_OF_DO_NOT_STORE',
  problemMessage:
      "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless "
      "'{1}' is also annotated.",
  correctionMessage: "Annotate '{1}' with 'doNotStore'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.RETURN_OF_DO_NOT_STORE',
  withArguments: _withArgumentsReturnOfDoNotStore,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type p0: the return type as declared in the return statement
/// Type p1: the expected return type as defined by the type of the Future
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
returnOfInvalidTypeFromCatchError = DiagnosticWithArguments(
  name: 'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
  problemMessage:
      "A value of type '{0}' can't be returned by the 'onError' handler because "
      "it must be assignable to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.RETURN_OF_INVALID_TYPE_FROM_CATCH_ERROR',
  withArguments: _withArgumentsReturnOfInvalidTypeFromCatchError,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the return type as declared in the return statement
/// Type p1: the expected return type as defined by the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
returnOfInvalidTypeFromClosure = DiagnosticWithArguments(
  name: 'RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
  problemMessage:
      "The returned type '{0}' isn't returnable from a '{1}' function, as "
      "required by the closure's context.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CLOSURE',
  withArguments: _withArgumentsReturnOfInvalidTypeFromClosure,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the return type as declared in the return statement
/// Type p1: the expected return type as defined by the enclosing class
/// String p2: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
returnOfInvalidTypeFromConstructor = DiagnosticWithArguments(
  name: 'RETURN_OF_INVALID_TYPE',
  problemMessage:
      "A value of type '{0}' can't be returned from the constructor '{2}' "
      "because it has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_CONSTRUCTOR',
  withArguments: _withArgumentsReturnOfInvalidTypeFromConstructor,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type p0: the return type as declared in the return statement
/// Type p1: the expected return type as defined by the method
/// String p2: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
returnOfInvalidTypeFromFunction = DiagnosticWithArguments(
  name: 'RETURN_OF_INVALID_TYPE',
  problemMessage:
      "A value of type '{0}' can't be returned from the function '{2}' because "
      "it has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION',
  withArguments: _withArgumentsReturnOfInvalidTypeFromFunction,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type p0: the type of the expression in the return statement
/// Type p1: the expected return type as defined by the method
/// String p2: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required DartType p1,
    required String p2,
  })
>
returnOfInvalidTypeFromMethod = DiagnosticWithArguments(
  name: 'RETURN_OF_INVALID_TYPE',
  problemMessage:
      "A value of type '{0}' can't be returned from the method '{2}' because it "
      "has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.RETURN_OF_INVALID_TYPE_FROM_METHOD',
  withArguments: _withArgumentsReturnOfInvalidTypeFromMethod,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type p0: the return type of the function
/// Type p1: the expected return type as defined by the type of the Future
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
returnTypeInvalidForCatchError = DiagnosticWithArguments(
  name: 'INVALID_RETURN_TYPE_FOR_CATCH_ERROR',
  problemMessage:
      "The return type '{0}' isn't assignable to '{1}', as required by "
      "'Future.catchError'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.RETURN_TYPE_INVALID_FOR_CATCH_ERROR',
  withArguments: _withArgumentsReturnTypeInvalidForCatchError,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments returnWithoutValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'RETURN_WITHOUT_VALUE',
      problemMessage: "The return value is missing after 'return'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.RETURN_WITHOUT_VALUE',
      expectedTypes: [],
    );

/// There is also a [diag.experimentNotEnabled] code which
/// catches some cases of constructor tearoff features (like
/// `List<int>.filled;`). Other constructor tearoff cases are not realized
/// until resolution (like `List.filled;`).
///
/// No parameters.
const DiagnosticWithoutArguments
sdkVersionConstructorTearoffs = DiagnosticWithoutArgumentsImpl(
  name: 'SDK_VERSION_CONSTRUCTOR_TEAROFFS',
  problemMessage:
      "Tearing off a constructor requires the 'constructor-tearoffs' language "
      "feature.",
  correctionMessage:
      "Try updating your 'pubspec.yaml' to set the minimum SDK constraint to "
      "2.15 or higher, and running 'pub get'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.SDK_VERSION_CONSTRUCTOR_TEAROFFS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sdkVersionGtGtGtOperator = DiagnosticWithoutArgumentsImpl(
  name: 'SDK_VERSION_GT_GT_GT_OPERATOR',
  problemMessage:
      "The operator '>>>' wasn't supported until version 2.14.0, but this code "
      "is required to be able to run on earlier versions.",
  correctionMessage: "Try updating the SDK constraints.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.SDK_VERSION_GT_GT_GT_OPERATOR',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the version specified in the `@Since()` annotation
/// String p1: the SDK version constraints
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
sdkVersionSince = DiagnosticWithArguments(
  name: 'SDK_VERSION_SINCE',
  problemMessage:
      "This API is available since SDK {0}, but constraints '{1}' don't "
      "guarantee it.",
  correctionMessage: "Try updating the SDK constraints.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.SDK_VERSION_SINCE',
  withArguments: _withArgumentsSdkVersionSince,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the sealed class being extended, implemented, or
///            mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
sealedClassSubtypeOutsideOfLibrary = DiagnosticWithArguments(
  name: 'INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY',
  problemMessage:
      "The class '{0}' can't be extended, implemented, or mixed in outside of "
      "its library because it's a sealed class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY',
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments sealedEnum = DiagnosticWithoutArgumentsImpl(
  name: 'SEALED_ENUM',
  problemMessage: "Enums can't be declared to be 'sealed'.",
  correctionMessage: "Try removing the keyword 'sealed'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.SEALED_ENUM',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments sealedMixin = DiagnosticWithoutArgumentsImpl(
  name: 'SEALED_MIXIN',
  problemMessage: "A mixin can't be declared 'sealed'.",
  correctionMessage: "Try removing the 'sealed' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.SEALED_MIXIN',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments sealedMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'SEALED_MIXIN_CLASS',
      problemMessage: "A mixin class can't be declared 'sealed'.",
      correctionMessage: "Try removing the 'sealed' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.SEALED_MIXIN_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
setElementFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'COLLECTION_ELEMENT_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' set literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the set literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SET_ELEMENT_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the actual type of the set element
/// Type p1: the expected type of the set element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
setElementTypeNotAssignable = DiagnosticWithArguments(
  name: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the set type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
  withArguments: _withArgumentsSetElementTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type p0: the actual type of the set element
/// Type p1: the expected type of the set element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
setElementTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'SET_ELEMENT_TYPE_NOT_ASSIGNABLE',
  problemMessage:
      "The element type '{0}' can't be assigned to the set type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE_NULLABILITY',
  withArguments: _withArgumentsSetElementTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments setterConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'SETTER_CONSTRUCTOR',
      problemMessage: "Constructors can't be a setter.",
      correctionMessage: "Try removing 'set'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.SETTER_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments setterInFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'SETTER_IN_FUNCTION',
      problemMessage: "Setters can't be defined within methods or functions.",
      correctionMessage:
          "Try moving the setter outside the method or function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.SETTER_IN_FUNCTION',
      expectedTypes: [],
    );

/// A code indicating that the activity is locked to an orientation.
///
/// No parameters.
const DiagnosticWithoutArguments
settingOrientationOnActivity = DiagnosticWithoutArgumentsImpl(
  name: 'SETTING_ORIENTATION_ON_ACTIVITY',
  problemMessage:
      "The `<activity>` element should not be locked to any orientation so that "
      "users can take advantage of the multi-window environments and larger "
      "screens on Chrome OS",
  correctionMessage:
      "Consider declaring the corresponding activity element with "
      "`screenOrientation=\"unspecified\"` or `\"fullSensor\"` attribute.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.SETTING_ORIENTATION_ON_ACTIVITY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sharedDeferredPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'SHARED_DEFERRED_PREFIX',
  problemMessage:
      "The prefix of a deferred import can't be used in other import directives.",
  correctionMessage: "Try renaming one of the prefixes.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SHARED_DEFERRED_PREFIX',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sizeAnnotationDimensions = DiagnosticWithoutArgumentsImpl(
  name: 'SIZE_ANNOTATION_DIMENSIONS',
  problemMessage:
      "'Array's must have an 'Array' annotation that matches the dimensions.",
  correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.SIZE_ANNOTATION_DIMENSIONS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
spreadExpressionFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
  problemMessage:
      "Constant values from a deferred library can't be spread into a const "
      "literal.",
  correctionMessage: "Try making the deferred import non-deferred.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SPREAD_EXPRESSION_FROM_DEFERRED_LIBRARY',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments stackOverflow = DiagnosticWithoutArgumentsImpl(
  name: 'STACK_OVERFLOW',
  problemMessage: "The file has too many nested expressions or statements.",
  correctionMessage: "Try simplifying the code.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.STACK_OVERFLOW',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the instance member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
staticAccessToInstanceMember = DiagnosticWithArguments(
  name: 'STATIC_ACCESS_TO_INSTANCE_MEMBER',
  problemMessage:
      "Instance member '{0}' can't be accessed using static access.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.STATIC_ACCESS_TO_INSTANCE_MEMBER',
  withArguments: _withArgumentsStaticAccessToInstanceMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments staticConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'STATIC_CONSTRUCTOR',
      problemMessage: "Constructors can't be static.",
      correctionMessage: "Try removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.STATIC_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticGetterWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'STATIC_GETTER_WITHOUT_BODY',
      problemMessage: "A 'static' getter must have a body.",
      correctionMessage:
          "Try adding a body to the getter, or removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.STATIC_GETTER_WITHOUT_BODY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'STATIC_OPERATOR',
      problemMessage: "Operators can't be static.",
      correctionMessage: "Try removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.STATIC_OPERATOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticSetterWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'STATIC_SETTER_WITHOUT_BODY',
      problemMessage: "A 'static' setter must have a body.",
      correctionMessage:
          "Try adding a body to the setter, or removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.STATIC_SETTER_WITHOUT_BODY',
      expectedTypes: [],
    );

/// When "strict-raw-types" is enabled, "raw types" must have type arguments.
///
/// A "raw type" is a type name that does not use inference to fill in missing
/// type arguments; instead, each type argument is instantiated to its bound.
///
/// Parameters:
/// Type p0: the name of the generic type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
strictRawType = DiagnosticWithArguments(
  name: 'STRICT_RAW_TYPE',
  problemMessage:
      "The generic type '{0}' should have explicit type arguments but doesn't.",
  correctionMessage: "Use explicit type arguments for '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.STRICT_RAW_TYPE',
  withArguments: _withArgumentsStrictRawType,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the subtype that is not 'base', 'final', or
///            'sealed'
/// String p1: the name of the 'base' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
subtypeOfBaseIsNotBaseFinalOrSealed = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
  problemMessage:
      "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
      "'{1}' is 'base'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED',
  withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the subtype that is not 'base', 'final', or
///            'sealed'
/// String p1: the name of the 'final' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
subtypeOfFinalIsNotBaseFinalOrSealed = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
  problemMessage:
      "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
      "'{1}' is 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED',
  withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the sealed class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
subtypeOfSealedClass = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_SEALED_CLASS',
  problemMessage:
      "The class '{0}' shouldn't be extended, mixed in, or implemented because "
      "it's sealed.",
  correctionMessage:
      "Try composing instead of inheriting, or refer to the documentation of "
      "'{0}' for more information.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.SUBTYPE_OF_SEALED_CLASS',
  withArguments: _withArgumentsSubtypeOfSealedClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the subclass
/// String p1: the name of the class being extended, implemented, or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
subtypeOfStructClassInExtends = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_STRUCT_CLASS',
  problemMessage:
      "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS',
  withArguments: _withArgumentsSubtypeOfStructClassInExtends,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the subclass
/// String p1: the name of the class being extended, implemented, or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
subtypeOfStructClassInImplements = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_STRUCT_CLASS',
  problemMessage:
      "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS',
  withArguments: _withArgumentsSubtypeOfStructClassInImplements,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the subclass
/// String p1: the name of the class being extended, implemented, or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
subtypeOfStructClassInWith = DiagnosticWithArguments(
  name: 'SUBTYPE_OF_STRUCT_CLASS',
  problemMessage:
      "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH',
  withArguments: _withArgumentsSubtypeOfStructClassInWith,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type p0: the type of super-parameter
/// Type p1: the type of associated super-constructor parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
superFormalParameterTypeIsNotSubtypeOfAssociated = DiagnosticWithArguments(
  name: 'SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
  problemMessage:
      "The type '{0}' of this parameter isn't a subtype of the type '{1}' of the "
      "associated super constructor parameter.",
  correctionMessage:
      "Try removing the explicit type annotation from the parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_TYPE_IS_NOT_SUBTYPE_OF_ASSOCIATED',
  withArguments: _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
superFormalParameterWithoutAssociatedNamed = DiagnosticWithoutArgumentsImpl(
  name: 'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
  problemMessage: "No associated named super constructor parameter.",
  correctionMessage:
      "Try changing the name to the name of an existing named super "
      "constructor parameter, or creating such named parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_NAMED',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
superFormalParameterWithoutAssociatedPositional = DiagnosticWithoutArgumentsImpl(
  name: 'SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
  problemMessage: "No associated positional super constructor parameter.",
  correctionMessage:
      "Try using a normal parameter, or adding more positional parameters to "
      "the super constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.SUPER_FORMAL_PARAMETER_WITHOUT_ASSOCIATED_POSITIONAL',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments superInEnumConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPER_IN_ENUM_CONSTRUCTOR',
      problemMessage: "The enum constructor can't have a 'super' initializer.",
      correctionMessage: "Try removing the 'super' invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SUPER_IN_ENUM_CONSTRUCTOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
superInExtension = DiagnosticWithoutArgumentsImpl(
  name: 'SUPER_IN_EXTENSION',
  problemMessage:
      "The 'super' keyword can't be used in an extension because an extension "
      "doesn't have a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SUPER_IN_EXTENSION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments superInExtensionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPER_IN_EXTENSION_TYPE',
      problemMessage:
          "The 'super' keyword can't be used in an extension type because an "
          "extension type doesn't have a superclass.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SUPER_IN_EXTENSION_TYPE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments superInInvalidContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPER_IN_INVALID_CONTEXT',
      problemMessage: "Invalid context for 'super' invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT',
      expectedTypes: [],
    );

/// 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
/// is a compile-time error if a generative constructor of class Object
/// includes a superinitializer.
///
/// No parameters.
const DiagnosticWithoutArguments superInitializerInObject =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPER_INITIALIZER_IN_OBJECT',
      problemMessage:
          "The class 'Object' can't invoke a constructor from a superclass.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments superInRedirectingConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'SUPER_IN_REDIRECTING_CONSTRUCTOR',
      problemMessage:
          "The redirecting constructor can't have a 'super' initializer.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the superinitializer
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
superInvocationNotLast = DiagnosticWithArguments(
  name: 'SUPER_INVOCATION_NOT_LAST',
  problemMessage:
      "The superconstructor call must be last in an initializer list: '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.SUPER_INVOCATION_NOT_LAST',
  withArguments: _withArgumentsSuperInvocationNotLast,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments switchCaseCompletesNormally =
    DiagnosticWithoutArgumentsImpl(
      name: 'SWITCH_CASE_COMPLETES_NORMALLY',
      problemMessage: "The 'case' shouldn't complete normally.",
      correctionMessage: "Try adding 'break', 'return', or 'throw'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.SWITCH_CASE_COMPLETES_NORMALLY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments switchHasCaseAfterDefaultCase =
    DiagnosticWithoutArgumentsImpl(
      name: 'SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
      problemMessage:
          "The default case should be the last case in a switch statement.",
      correctionMessage:
          "Try moving the default case after the other case clauses.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments switchHasMultipleDefaultCases =
    DiagnosticWithoutArgumentsImpl(
      name: 'SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
      problemMessage: "The 'default' case can only be declared once.",
      correctionMessage: "Try removing all but one default case.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
tearoffOfGenerativeConstructorOfAbstractClass = DiagnosticWithoutArgumentsImpl(
  name: 'TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
  problemMessage:
      "A generative constructor of an abstract class can't be torn off.",
  correctionMessage:
      "Try tearing off a constructor of a concrete class, or a "
      "non-generative constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.TEAROFF_OF_GENERATIVE_CONSTRUCTOR_OF_ABSTRACT_CLASS',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the unicode sequence of the code point.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
textDirectionCodePointInComment = DiagnosticWithArguments(
  name: 'TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
  problemMessage:
      "The Unicode code point 'U+{0}' changes the appearance of text from how "
      "it's interpreted by the compiler.",
  correctionMessage:
      "Try removing the code point or using the Unicode escape sequence "
      "'\\u{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_COMMENT',
  withArguments: _withArgumentsTextDirectionCodePointInComment,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the unicode sequence of the code point.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
textDirectionCodePointInLiteral = DiagnosticWithArguments(
  name: 'TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
  problemMessage:
      "The Unicode code point 'U+{0}' changes the appearance of text from how "
      "it's interpreted by the compiler.",
  correctionMessage:
      "Try removing the code point or using the Unicode escape sequence "
      "'\\u{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.TEXT_DIRECTION_CODE_POINT_IN_LITERAL',
  withArguments: _withArgumentsTextDirectionCodePointInLiteral,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type p0: the type that can't be thrown
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0})
>
throwOfInvalidType = DiagnosticWithArguments(
  name: 'THROW_OF_INVALID_TYPE',
  problemMessage:
      "The type '{0}' of the thrown expression must be assignable to 'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.THROW_OF_INVALID_TYPE',
  withArguments: _withArgumentsThrowOfInvalidType,
  expectedTypes: [ExpectedType.type],
);

/// A standard TODO comment marked as TODO.
///
/// Parameters:
/// String message: the user-supplied problem message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
todo = DiagnosticWithArguments(
  name: 'TODO',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'TodoCode.TODO',
  withArguments: _withArgumentsTodo,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the element whose type could not be inferred.
/// String p1: The [TopLevelInferenceError]'s arguments that led to the cycle.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
topLevelCycle = DiagnosticWithArguments(
  name: 'TOP_LEVEL_CYCLE',
  problemMessage:
      "The type of '{0}' can't be inferred because it depends on itself through "
      "the cycle: {1}.",
  correctionMessage:
      "Try adding an explicit type to one or more of the variables in the "
      "cycle in order to break the cycle.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TOP_LEVEL_CYCLE',
  withArguments: _withArgumentsTopLevelCycle,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
topLevelOperator = DiagnosticWithoutArgumentsImpl(
  name: 'TOP_LEVEL_OPERATOR',
  problemMessage: "Operators must be declared within a class.",
  correctionMessage:
      "Try removing the operator, moving it to a class, or converting it to "
      "be a function.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.TOP_LEVEL_OPERATOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
typeAliasCannotReferenceItself = DiagnosticWithoutArgumentsImpl(
  name: 'TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
  problemMessage:
      "Typedefs can't reference themselves directly or recursively via another "
      "typedef.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the type that is deferred and being used in a type
///            annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
typeAnnotationDeferredClass = DiagnosticWithArguments(
  name: 'TYPE_ANNOTATION_DEFERRED_CLASS',
  problemMessage:
      "The deferred type '{0}' can't be used in a declaration, cast, or type "
      "test.",
  correctionMessage:
      "Try using a different type, or changing the import to not be "
      "deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_ANNOTATION_DEFERRED_CLASS',
  withArguments: _withArgumentsTypeAnnotationDeferredClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the type used in the instance creation that should be
///          limited by the bound as specified in the class declaration
/// String p1: the name of the type parameter
/// Type p2: the substituted bound of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required String p1,
    required DartType p2,
  })
>
typeArgumentNotMatchingBounds = DiagnosticWithArguments(
  name: 'TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
  problemMessage:
      "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
  correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS',
  withArguments: _withArgumentsTypeArgumentNotMatchingBounds,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// Name name: undocumented
const DiagnosticCode typeArgumentsOnTypeVariable =
    DiagnosticCodeWithExpectedTypes(
      name: 'TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
      problemMessage: "Can't use type arguments with type variable '{0}'.",
      correctionMessage: "Try removing the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.TYPE_ARGUMENTS_ON_TYPE_VARIABLE',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments typeBeforeFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_BEFORE_FACTORY',
      problemMessage: "Factory constructors cannot have a return type.",
      correctionMessage: "Try removing the type appearing before 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.TYPE_BEFORE_FACTORY',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeCheckIsNotNull =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_CHECK_WITH_NULL',
      problemMessage: "Tests for non-null should be done with '!= null'.",
      correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.TYPE_CHECK_IS_NOT_NULL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeCheckIsNull =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_CHECK_WITH_NULL',
      problemMessage: "Tests for null should be done with '== null'.",
      correctionMessage: "Try replacing the 'is Null' check with '== null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.TYPE_CHECK_IS_NULL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typedefInClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPEDEF_IN_CLASS',
      problemMessage: "Typedefs can't be declared inside classes.",
      correctionMessage: "Try moving the typedef to the top-level.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.TYPEDEF_IN_CLASS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeParameterOnConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_PARAMETER_ON_CONSTRUCTOR',
      problemMessage: "Constructors can't have type parameters.",
      correctionMessage: "Try removing the type parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.TYPE_PARAMETER_ON_CONSTRUCTOR',
      expectedTypes: [],
    );

/// 7.1.1 Operators: Type parameters are not syntactically supported on an
/// operator.
///
/// No parameters.
const DiagnosticWithoutArguments typeParameterOnOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_PARAMETER_ON_OPERATOR',
      problemMessage:
          "Types parameters aren't allowed when defining an operator.",
      correctionMessage: "Try removing the type parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.TYPE_PARAMETER_ON_OPERATOR',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeParameterReferencedByStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'TYPE_PARAMETER_REFERENCED_BY_STATIC',
      problemMessage:
          "Static members can't reference type parameters of the class.",
      correctionMessage:
          "Try removing the reference to the type parameter, or making the "
          "member an instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.TYPE_PARAMETER_REFERENCED_BY_STATIC',
      expectedTypes: [],
    );

/// See [diag.typeArgumentNotMatchingBounds].
///
/// Parameters:
/// String p0: the name of the type parameter
/// Type p1: the name of the bounding type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
typeParameterSupertypeOfItsBound = DiagnosticWithArguments(
  name: 'TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
  problemMessage: "'{0}' can't be a supertype of its upper bound.",
  correctionMessage:
      "Try using a type that is the same as or a subclass of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND',
  withArguments: _withArgumentsTypeParameterSupertypeOfItsBound,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
typeTestWithNonType = DiagnosticWithArguments(
  name: 'TYPE_TEST_WITH_NON_TYPE',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in an 'is' expression.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_TEST_WITH_NON_TYPE',
  withArguments: _withArgumentsTypeTestWithNonType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
typeTestWithUndefinedName = DiagnosticWithArguments(
  name: 'TYPE_TEST_WITH_UNDEFINED_NAME',
  problemMessage:
      "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
  correctionMessage:
      "Try changing the name to the name of an existing type, or creating a "
      "type with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.TYPE_TEST_WITH_UNDEFINED_NAME',
  withArguments: _withArgumentsTypeTestWithUndefinedName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Object p0: the path of the file that cannot be read
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unableGetContent = DiagnosticWithArguments(
  name: 'UNABLE_GET_CONTENT',
  problemMessage: "Unable to get content of '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.UNABLE_GET_CONTENT',
  withArguments: _withArgumentsUnableGetContent,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments
uncheckedInvocationOfNullableValue = DiagnosticWithoutArgumentsImpl(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage:
      "The function can't be unconditionally invoked because it can be 'null'.",
  correctionMessage: "Try adding a null check ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNCHECKED_INVOCATION_OF_NULLABLE_VALUE',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uncheckedMethodInvocationOfNullableValue = DiagnosticWithArguments(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage:
      "The method '{0}' can't be unconditionally invoked because the receiver "
      "can be 'null'.",
  correctionMessage:
      "Try making the call conditional (using '?.') or adding a null check "
      "to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNCHECKED_METHOD_INVOCATION_OF_NULLABLE_VALUE',
  withArguments: _withArgumentsUncheckedMethodInvocationOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uncheckedOperatorInvocationOfNullableValue = DiagnosticWithArguments(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage:
      "The operator '{0}' can't be unconditionally invoked because the receiver "
      "can be 'null'.",
  correctionMessage: "Try adding a null check to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNCHECKED_OPERATOR_INVOCATION_OF_NULLABLE_VALUE',
  withArguments: _withArgumentsUncheckedOperatorInvocationOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the property
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uncheckedPropertyAccessOfNullableValue = DiagnosticWithArguments(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage:
      "The property '{0}' can't be unconditionally accessed because the receiver "
      "can be 'null'.",
  correctionMessage:
      "Try making the access conditional (using '?.') or adding a null check "
      "to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE',
  withArguments: _withArgumentsUncheckedPropertyAccessOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments uncheckedUseOfNullableValueAsCondition =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
      problemMessage: "A nullable expression can't be used as a condition.",
      correctionMessage:
          "Try checking that the value isn't 'null' before using it as a "
          "condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_CONDITION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
uncheckedUseOfNullableValueAsIterator = DiagnosticWithoutArgumentsImpl(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage:
      "A nullable expression can't be used as an iterator in a for-in loop.",
  correctionMessage:
      "Try checking that the value isn't 'null' before using it as an "
      "iterator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_AS_ITERATOR',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
uncheckedUseOfNullableValueInSpread = DiagnosticWithoutArgumentsImpl(
  name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
  problemMessage: "A nullable expression can't be used in a spread.",
  correctionMessage:
      "Try checking that the value isn't 'null' before using it in a spread, "
      "or use a null-aware spread.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_SPREAD',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments uncheckedUseOfNullableValueInYieldEach =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNCHECKED_USE_OF_NULLABLE_VALUE',
      problemMessage:
          "A nullable expression can't be used in a yield-each statement.",
      correctionMessage:
          "Try checking that the value isn't 'null' before using it in a "
          "yield-each statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'CompileTimeErrorCode.UNCHECKED_USE_OF_NULLABLE_VALUE_IN_YIELD_EACH',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedAnnotation = DiagnosticWithArguments(
  name: 'UNDEFINED_ANNOTATION',
  problemMessage: "Undefined name '{0}' used as an annotation.",
  correctionMessage:
      "Try defining the name or importing it from another library.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_ANNOTATION',
  withArguments: _withArgumentsUndefinedAnnotation,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the undefined class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedClass = DiagnosticWithArguments(
  name: 'UNDEFINED_CLASS',
  problemMessage: "Undefined class '{0}'.",
  correctionMessage:
      "Try changing the name to the name of an existing class, or creating a "
      "class with the name '{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_CLASS',
  withArguments: _withArgumentsUndefinedClass,
  expectedTypes: [ExpectedType.string],
);

/// Same as [diag.undefinedClass], but to catch using
/// "boolean" instead of "bool" in order to improve the correction message.
///
/// Parameters:
/// String p0: the name of the undefined class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedClassBoolean = DiagnosticWithArguments(
  name: 'UNDEFINED_CLASS',
  problemMessage: "Undefined class '{0}'.",
  correctionMessage: "Try using the type 'bool'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_CLASS_BOOLEAN',
  withArguments: _withArgumentsUndefinedClassBoolean,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type p0: the name of the superclass that does not define the invoked
///          constructor
/// String p1: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required String p1})
>
undefinedConstructorInInitializer = DiagnosticWithArguments(
  name: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try defining a constructor named '{1}' in '{0}', or invoking a "
      "different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
  withArguments: _withArgumentsUndefinedConstructorInInitializer,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Object p0: the name of the superclass that does not define the invoked
///            constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
undefinedConstructorInInitializerDefault = DiagnosticWithArguments(
  name: 'UNDEFINED_CONSTRUCTOR_IN_INITIALIZER',
  problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
  correctionMessage:
      "Try defining an unnamed constructor in '{0}', or invoking a different "
      "constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT',
  withArguments: _withArgumentsUndefinedConstructorInInitializerDefault,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the enum value that is not defined
/// String p1: the name of the enum used to access the constant
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedEnumConstant = DiagnosticWithArguments(
  name: 'UNDEFINED_ENUM_CONSTANT',
  problemMessage: "There's no constant named '{0}' in '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing constant, or "
      "defining a constant named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTANT',
  withArguments: _withArgumentsUndefinedEnumConstant,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the constructor that is undefined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedEnumConstructorNamed = DiagnosticWithArguments(
  name: 'UNDEFINED_ENUM_CONSTRUCTOR',
  problemMessage: "The enum doesn't have a constructor named '{0}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing constructor, or "
      "defining constructor with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_NAMED',
  withArguments: _withArgumentsUndefinedEnumConstructorNamed,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments undefinedEnumConstructorUnnamed =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNDEFINED_ENUM_CONSTRUCTOR',
      problemMessage: "The enum doesn't have an unnamed constructor.",
      correctionMessage:
          "Try adding the name of an existing constructor, or defining an "
          "unnamed constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.UNDEFINED_ENUM_CONSTRUCTOR_UNNAMED',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the getter that is undefined
/// String p1: the name of the extension that was explicitly specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedExtensionGetter = DiagnosticWithArguments(
  name: 'UNDEFINED_EXTENSION_GETTER',
  problemMessage: "The getter '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing getter, or "
      "defining a getter named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER',
  withArguments: _withArgumentsUndefinedExtensionGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the method that is undefined
/// String p1: the name of the extension that was explicitly specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedExtensionMethod = DiagnosticWithArguments(
  name: 'UNDEFINED_EXTENSION_METHOD',
  problemMessage: "The method '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_METHOD',
  withArguments: _withArgumentsUndefinedExtensionMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the operator that is undefined
/// String p1: the name of the extension that was explicitly specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedExtensionOperator = DiagnosticWithArguments(
  name: 'UNDEFINED_EXTENSION_OPERATOR',
  problemMessage: "The operator '{0}' isn't defined for the extension '{1}'.",
  correctionMessage: "Try defining the operator '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR',
  withArguments: _withArgumentsUndefinedExtensionOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the setter that is undefined
/// String p1: the name of the extension that was explicitly specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedExtensionSetter = DiagnosticWithArguments(
  name: 'UNDEFINED_EXTENSION_SETTER',
  problemMessage: "The setter '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing setter, or "
      "defining a setter named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER',
  withArguments: _withArgumentsUndefinedExtensionSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the method that is undefined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedFunction = DiagnosticWithArguments(
  name: 'UNDEFINED_FUNCTION',
  problemMessage: "The function '{0}' isn't defined.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing function, or defining a function named '{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_FUNCTION',
  withArguments: _withArgumentsUndefinedFunction,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the getter
/// Object p1: the name of the enclosing type where the getter is being looked
///            for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required Object p1})
>
undefinedGetter = DiagnosticWithArguments(
  name: 'UNDEFINED_GETTER',
  problemMessage: "The getter '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing getter, or defining a getter or field named "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_GETTER',
  withArguments: _withArgumentsUndefinedGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the getter
/// String p1: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedGetterOnFunctionType = DiagnosticWithArguments(
  name: 'UNDEFINED_GETTER',
  problemMessage: "The getter '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension getter on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_GETTER_ON_FUNCTION_TYPE',
  withArguments: _withArgumentsUndefinedGetterOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the library being imported
/// String p1: the name in the hide clause that isn't defined in the library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedHiddenName = DiagnosticWithArguments(
  name: 'UNDEFINED_HIDDEN_NAME',
  problemMessage:
      "The library '{0}' doesn't export a member with the hidden name '{1}'.",
  correctionMessage: "Try removing the name from the list of hidden members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNDEFINED_HIDDEN_NAME',
  withArguments: _withArgumentsUndefinedHiddenName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the identifier
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedIdentifier = DiagnosticWithArguments(
  name: 'UNDEFINED_IDENTIFIER',
  problemMessage: "Undefined name '{0}'.",
  correctionMessage:
      "Try correcting the name to one that is defined, or defining the name.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_IDENTIFIER',
  withArguments: _withArgumentsUndefinedIdentifier,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
undefinedIdentifierAwait = DiagnosticWithoutArgumentsImpl(
  name: 'UNDEFINED_IDENTIFIER_AWAIT',
  problemMessage:
      "Undefined name 'await' in function body not marked with 'async'.",
  correctionMessage:
      "Try correcting the name to one that is defined, defining the name, or "
      "adding 'async' to the enclosing function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT',
  expectedTypes: [],
);

/// An error code indicating an undefined lint rule.
///
/// Parameters:
/// String p0: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedLint = DiagnosticWithArguments(
  name: 'UNDEFINED_LINT',
  problemMessage: "'{0}' is not a recognized lint rule.",
  correctionMessage: "Try using the name of a recognized lint rule.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNDEFINED_LINT',
  withArguments: _withArgumentsUndefinedLint,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the method that is undefined
/// Object p1: the resolved type name that the method lookup is happening on
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required Object p1})
>
undefinedMethod = DiagnosticWithArguments(
  name: 'UNDEFINED_METHOD',
  problemMessage: "The method '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_METHOD',
  withArguments: _withArgumentsUndefinedMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the method
/// String p1: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedMethodOnFunctionType = DiagnosticWithArguments(
  name: 'UNDEFINED_METHOD',
  problemMessage: "The method '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension method on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_METHOD_ON_FUNCTION_TYPE',
  withArguments: _withArgumentsUndefinedMethodOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the requested named parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
undefinedNamedParameter = DiagnosticWithArguments(
  name: 'UNDEFINED_NAMED_PARAMETER',
  problemMessage: "The named parameter '{0}' isn't defined.",
  correctionMessage:
      "Try correcting the name to an existing named parameter's name, or "
      "defining a named parameter with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER',
  withArguments: _withArgumentsUndefinedNamedParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the operator
/// Type p1: the name of the enclosing type where the operator is being looked
///          for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
undefinedOperator = DiagnosticWithArguments(
  name: 'UNDEFINED_OPERATOR',
  problemMessage: "The operator '{0}' isn't defined for the type '{1}'.",
  correctionMessage: "Try defining the operator '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_OPERATOR',
  withArguments: _withArgumentsUndefinedOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the reference
/// String p1: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedPrefixedName = DiagnosticWithArguments(
  name: 'UNDEFINED_PREFIXED_NAME',
  problemMessage:
      "The name '{0}' is being referenced through the prefix '{1}', but it isn't "
      "defined in any of the libraries imported using that prefix.",
  correctionMessage:
      "Try correcting the prefix or importing the library that defines "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME',
  withArguments: _withArgumentsUndefinedPrefixedName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the undefined parameter
/// String p1: the name of the targeted member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedReferencedParameter = DiagnosticWithArguments(
  name: 'UNDEFINED_REFERENCED_PARAMETER',
  problemMessage: "The parameter '{0}' isn't defined by '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNDEFINED_REFERENCED_PARAMETER',
  withArguments: _withArgumentsUndefinedReferencedParameter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the setter
/// Type p1: the name of the enclosing type where the setter is being looked
///          for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
undefinedSetter = DiagnosticWithArguments(
  name: 'UNDEFINED_SETTER',
  problemMessage: "The setter '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing setter, or defining a setter or field named "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SETTER',
  withArguments: _withArgumentsUndefinedSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the setter
/// String p1: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedSetterOnFunctionType = DiagnosticWithArguments(
  name: 'UNDEFINED_SETTER',
  problemMessage: "The setter '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension getter on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SETTER_ON_FUNCTION_TYPE',
  withArguments: _withArgumentsUndefinedSetterOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the library being imported
/// String p1: the name in the show clause that isn't defined in the library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedShownName = DiagnosticWithArguments(
  name: 'UNDEFINED_SHOWN_NAME',
  problemMessage:
      "The library '{0}' doesn't export a member with the shown name '{1}'.",
  correctionMessage: "Try removing the name from the list of shown members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNDEFINED_SHOWN_NAME',
  withArguments: _withArgumentsUndefinedShownName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the getter
/// Type p1: the name of the enclosing type where the getter is being looked
///          for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
undefinedSuperGetter = DiagnosticWithArguments(
  name: 'UNDEFINED_SUPER_MEMBER',
  problemMessage: "The getter '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing getter, or "
      "defining a getter or field named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SUPER_GETTER',
  withArguments: _withArgumentsUndefinedSuperGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the method that is undefined
/// String p1: the resolved type name that the method lookup is happening on
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
undefinedSuperMethod = DiagnosticWithArguments(
  name: 'UNDEFINED_SUPER_MEMBER',
  problemMessage: "The method '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SUPER_METHOD',
  withArguments: _withArgumentsUndefinedSuperMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the operator
/// Type p1: the name of the enclosing type where the operator is being looked
///          for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
undefinedSuperOperator = DiagnosticWithArguments(
  name: 'UNDEFINED_SUPER_MEMBER',
  problemMessage: "The operator '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage: "Try defining the operator '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SUPER_OPERATOR',
  withArguments: _withArgumentsUndefinedSuperOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String p0: the name of the setter
/// Type p1: the name of the enclosing type where the setter is being looked
///          for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
undefinedSuperSetter = DiagnosticWithArguments(
  name: 'UNDEFINED_SUPER_MEMBER',
  problemMessage: "The setter '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing setter, or "
      "defining a setter or field named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.UNDEFINED_SUPER_SETTER',
  withArguments: _withArgumentsUndefinedSuperSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// A TODO comment marked as UNDONE.
///
/// Parameters:
/// String message: the user-supplied problem message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
undone = DiagnosticWithArguments(
  name: 'UNDONE',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'TodoCode.UNDONE',
  withArguments: _withArgumentsUndone,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unexpectedDollarInString = DiagnosticWithoutArgumentsImpl(
  name: 'UNEXPECTED_DOLLAR_IN_STRING',
  problemMessage:
      "A '\$' has special meaning inside a string, and must be followed by an "
      "identifier or an expression in curly braces ({}).",
  correctionMessage: "Try adding a backslash (\\) to escape the '\$'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.UNEXPECTED_DOLLAR_IN_STRING',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unexpectedSeparatorInNumber = DiagnosticWithoutArgumentsImpl(
  name: 'UNEXPECTED_SEPARATOR_IN_NUMBER',
  problemMessage:
      "Digit separators ('_') in a number literal can only be placed between two "
      "digits.",
  correctionMessage: "Try removing the '_'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.UNEXPECTED_SEPARATOR_IN_NUMBER',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the starting character that was missing
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unexpectedTerminatorForParameterGroup = DiagnosticWithArguments(
  name: 'UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
  problemMessage: "There is no '{0}' to open a parameter group.",
  correctionMessage: "Try inserting the '{0}' at the appropriate location.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.UNEXPECTED_TERMINATOR_FOR_PARAMETER_GROUP',
  withArguments: _withArgumentsUnexpectedTerminatorForParameterGroup,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the unexpected text that was found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unexpectedToken = DiagnosticWithArguments(
  name: 'UNEXPECTED_TOKEN',
  problemMessage: "Unexpected text '{0}'.",
  correctionMessage: "Try removing the text.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.UNEXPECTED_TOKEN',
  withArguments: _withArgumentsUnexpectedToken,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unexpectedTokens =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNEXPECTED_TOKENS',
      problemMessage: "Unexpected tokens.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.UNEXPECTED_TOKENS',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the non-diagnostic being ignored
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unignorableIgnore = DiagnosticWithArguments(
  name: 'UNIGNORABLE_IGNORE',
  problemMessage: "The diagnostic '{0}' can't be ignored.",
  correctionMessage:
      "Try removing the name from the list, or removing the whole comment if "
      "this is the only name in the list.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNIGNORABLE_IGNORE',
  withArguments: _withArgumentsUnignorableIgnore,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the unknown platform.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unknownPlatform = DiagnosticWithArguments(
  name: 'UNKNOWN_PLATFORM',
  problemMessage: "The platform '{0}' is not a recognized platform.",
  correctionMessage: "Try correcting the platform name or removing it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.UNKNOWN_PLATFORM',
  withArguments: _withArgumentsUnknownPlatform,
  expectedTypes: [ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryCast =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_CAST',
      problemMessage: "Unnecessary cast.",
      correctionMessage: "Try removing the cast.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_CAST',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryCastPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_CAST_PATTERN',
      problemMessage: "Unnecessary cast pattern.",
      correctionMessage: "Try removing the cast pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_CAST_PATTERN',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the package in the dev_dependency list.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unnecessaryDevDependency = DiagnosticWithArguments(
  name: 'UNNECESSARY_DEV_DEPENDENCY',
  problemMessage:
      "The dev dependency on {0} is unnecessary because there is also a normal "
      "dependency on that package.",
  correctionMessage: "Try removing the dev dependency.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY',
  withArguments: _withArgumentsUnnecessaryDevDependency,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryFinal = DiagnosticWithoutArgumentsImpl(
  name: 'UNNECESSARY_FINAL',
  problemMessage:
      "The keyword 'final' isn't necessary because the parameter is implicitly "
      "'final'.",
  correctionMessage: "Try removing the 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNNECESSARY_FINAL',
  expectedTypes: [],
);

/// Parameters:
/// String p0: the URI that is not necessary
/// String p1: the URI that makes it unnecessary
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
unnecessaryImport = DiagnosticWithArguments(
  name: 'UNNECESSARY_IMPORT',
  problemMessage:
      "The import of '{0}' is unnecessary because all of the used elements are "
      "also provided by the import of '{1}'.",
  correctionMessage: "Try removing the import directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'HintCode.UNNECESSARY_IMPORT',
  withArguments: _withArgumentsUnnecessaryImport,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNanComparisonFalse = DiagnosticWithoutArgumentsImpl(
  name: 'UNNECESSARY_NAN_COMPARISON',
  problemMessage:
      "A double can't equal 'double.nan', so the condition is always 'false'.",
  correctionMessage: "Try using 'double.isNan', or removing the condition.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNNECESSARY_NAN_COMPARISON_FALSE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNanComparisonTrue = DiagnosticWithoutArgumentsImpl(
  name: 'UNNECESSARY_NAN_COMPARISON',
  problemMessage:
      "A double can't equal 'double.nan', so the condition is always 'true'.",
  correctionMessage: "Try using 'double.isNan', or removing the condition.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNNECESSARY_NAN_COMPARISON_TRUE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNonNullAssertion =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NON_NULL_ASSERTION',
      problemMessage:
          "The '!' will have no effect because the receiver can't be null.",
      correctionMessage: "Try removing the '!' operator.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNoSuchMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NO_SUCH_METHOD',
      problemMessage: "Unnecessary 'noSuchMethod' declaration.",
      correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_NO_SUCH_METHOD',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNullAssertPattern = DiagnosticWithoutArgumentsImpl(
  name: 'UNNECESSARY_NULL_ASSERT_PATTERN',
  problemMessage:
      "The null-assert pattern will have no effect because the matched type "
      "isn't nullable.",
  correctionMessage:
      "Try replacing the null-assert pattern with its nested pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.UNNECESSARY_NULL_ASSERT_PATTERN',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNullCheckPattern = DiagnosticWithoutArgumentsImpl(
  name: 'UNNECESSARY_NULL_CHECK_PATTERN',
  problemMessage:
      "The null-check pattern will have no effect because the matched type isn't "
      "nullable.",
  correctionMessage:
      "Try replacing the null-check pattern with its nested pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'StaticWarningCode.UNNECESSARY_NULL_CHECK_PATTERN',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonAlwaysNullFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NULL_COMPARISON',
      problemMessage:
          "The operand must be 'null', so the condition is always 'false'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_FALSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonAlwaysNullTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NULL_COMPARISON',
      problemMessage:
          "The operand must be 'null', so the condition is always 'true'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_NULL_COMPARISON_ALWAYS_NULL_TRUE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonNeverNullFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NULL_COMPARISON',
      problemMessage:
          "The operand can't be 'null', so the condition is always 'false'.",
      correctionMessage:
          "Try removing the condition, an enclosing condition, or the whole "
          "conditional statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_FALSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonNeverNullTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_NULL_COMPARISON',
      problemMessage:
          "The operand can't be 'null', so the condition is always 'true'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_NULL_COMPARISON_NEVER_NULL_TRUE',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unnecessaryQuestionMark = DiagnosticWithArguments(
  name: 'UNNECESSARY_QUESTION_MARK',
  problemMessage:
      "The '?' is unnecessary because '{0}' is nullable without it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNNECESSARY_QUESTION_MARK',
  withArguments: _withArgumentsUnnecessaryQuestionMark,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessarySetLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_SET_LITERAL',
      problemMessage:
          "Braces unnecessarily wrap this expression in a set literal.",
      correctionMessage: "Try removing the set literal around the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_SET_LITERAL',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryTypeCheckFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_TYPE_CHECK',
      problemMessage: "Unnecessary type check; the result is always 'false'.",
      correctionMessage:
          "Try correcting the type check, or removing the type check.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_TYPE_CHECK_FALSE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryTypeCheckTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_TYPE_CHECK',
      problemMessage: "Unnecessary type check; the result is always 'true'.",
      correctionMessage:
          "Try correcting the type check, or removing the type check.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_TYPE_CHECK_TRUE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryWildcardPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNNECESSARY_WILDCARD_PATTERN',
      problemMessage: "Unnecessary wildcard pattern.",
      correctionMessage: "Try removing the wildcard pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNNECESSARY_WILDCARD_PATTERN',
      expectedTypes: [],
    );

/// This is a specialization of [instanceAccessToStaticMember] that is used
/// when we are able to find the name defined in a supertype. It exists to
/// provide a more informative error message.
///
/// Parameters:
/// String p0: the name of the defining type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unqualifiedReferenceToNonLocalStaticMember = DiagnosticWithArguments(
  name: 'UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
  problemMessage:
      "Static members from supertypes must be qualified by the name of the "
      "defining type.",
  correctionMessage: "Try adding '{0}.' before the name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER',
  withArguments: _withArgumentsUnqualifiedReferenceToNonLocalStaticMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the defining type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unqualifiedReferenceToStaticMemberOfExtendedType = DiagnosticWithArguments(
  name: 'UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
  problemMessage:
      "Static members from the extended type or one of its superclasses must be "
      "qualified by the name of the defining type.",
  correctionMessage: "Try adding '{0}.' before the name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE',
  withArguments: _withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unreachableSwitchCase =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNREACHABLE_SWITCH_CASE',
      problemMessage: "This case is covered by the previous cases.",
      correctionMessage:
          "Try removing the case clause, or restructuring the preceding "
          "patterns.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNREACHABLE_SWITCH_CASE',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unreachableSwitchDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNREACHABLE_SWITCH_DEFAULT',
      problemMessage: "This default clause is covered by the previous cases.",
      correctionMessage:
          "Try removing the default clause, or restructuring the preceding "
          "patterns.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'WarningCode.UNREACHABLE_SWITCH_DEFAULT',
      expectedTypes: [],
    );

/// An error code indicating that an unrecognized error code is being used to
/// specify an error filter.
///
/// Parameters:
/// String p0: the unrecognized error code
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unrecognizedErrorCode = DiagnosticWithArguments(
  name: 'UNRECOGNIZED_ERROR_CODE',
  problemMessage: "'{0}' isn't a recognized error code.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNRECOGNIZED_ERROR_CODE',
  withArguments: _withArgumentsUnrecognizedErrorCode,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified feature is not supported on Chrome OS.
///
/// Parameters:
/// String p0: the name of the feature
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unsupportedChromeOsFeature = DiagnosticWithArguments(
  name: 'UNSUPPORTED_CHROME_OS_FEATURE',
  problemMessage:
      "The feature {0} isn't supported on Chrome OS, consider making it "
      "optional.",
  correctionMessage:
      "Try changing to `android:required=\"false\"` for this feature.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.UNSUPPORTED_CHROME_OS_FEATURE',
  withArguments: _withArgumentsUnsupportedChromeOsFeature,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified hardware feature is not supported on
/// Chrome OS.
///
/// Parameters:
/// String p0: the name of the feature
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unsupportedChromeOsHardware = DiagnosticWithArguments(
  name: 'UNSUPPORTED_CHROME_OS_HARDWARE',
  problemMessage:
      "The feature {0} isn't supported on Chrome OS, consider making it "
      "optional.",
  correctionMessage:
      "Try adding `android:required=\"false\"` for this feature.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'ManifestWarningCode.UNSUPPORTED_CHROME_OS_HARDWARE',
  withArguments: _withArgumentsUnsupportedChromeOsHardware,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the unsupported operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unsupportedOperator = DiagnosticWithArguments(
  name: 'UNSUPPORTED_OPERATOR',
  problemMessage: "The '{0}' operator is not supported.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ScannerErrorCode.UNSUPPORTED_OPERATOR',
  withArguments: _withArgumentsUnsupportedOperator,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating that a YAML section is being configured with an
/// unsupported option where there is just one legal value.
///
/// Parameters:
/// String p0: the section name
/// String p1: the unsupported option key
/// String p2: the legal value
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
unsupportedOptionWithLegalValue = DiagnosticWithArguments(
  name: 'UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
  problemMessage:
      "The option '{1}' isn't supported by '{0}'. Try using the only supported "
      "option: '{2}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE',
  withArguments: _withArgumentsUnsupportedOptionWithLegalValue,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// An error code indicating that a YAML section is being configured with an
/// unsupported option and legal options are provided.
///
/// Parameters:
/// String p0: the section name
/// String p1: the unsupported option key
/// String p2: legal values
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required String p1,
    required String p2,
  })
>
unsupportedOptionWithLegalValues = DiagnosticWithArguments(
  name: 'UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
  problemMessage: "The option '{1}' isn't supported by '{0}'.",
  correctionMessage: "Try using one of the supported options: {2}.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUES',
  withArguments: _withArgumentsUnsupportedOptionWithLegalValues,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// An error code indicating that a plugin is being configured with an
/// unsupported option and legal options are provided.
///
/// Parameters:
/// String p0: the plugin name
/// String p1: the unsupported option key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
unsupportedOptionWithoutValues = DiagnosticWithArguments(
  name: 'UNSUPPORTED_OPTION_WITHOUT_VALUES',
  problemMessage: "The option '{1}' isn't supported by '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITHOUT_VALUES',
  withArguments: _withArgumentsUnsupportedOptionWithoutValues,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating that an option entry is being configured with an
/// unsupported value.
///
/// Parameters:
/// String p0: the option name
/// Object p1: the unsupported value
/// String p2: legal values
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required Object p1,
    required String p2,
  })
>
unsupportedValue = DiagnosticWithArguments(
  name: 'UNSUPPORTED_VALUE',
  problemMessage: "The value '{1}' isn't supported by '{0}'.",
  correctionMessage: "Try using one of the supported options: {2}.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'AnalysisOptionsWarningCode.UNSUPPORTED_VALUE',
  withArguments: _withArgumentsUnsupportedValue,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.object,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments unterminatedMultiLineComment =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNTERMINATED_MULTI_LINE_COMMENT',
      problemMessage: "Unterminated multi-line comment.",
      correctionMessage:
          "Try terminating the comment with '*/', or removing any unbalanced "
          "occurrences of '/*' (because comments nest in Dart).",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ScannerErrorCode.UNTERMINATED_MULTI_LINE_COMMENT',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unterminatedStringLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'UNTERMINATED_STRING_LITERAL',
      problemMessage: "Unterminated string literal.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ScannerErrorCode.UNTERMINATED_STRING_LITERAL',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the exception variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedCatchClause = DiagnosticWithArguments(
  name: 'UNUSED_CATCH_CLAUSE',
  problemMessage:
      "The exception variable '{0}' isn't used, so the 'catch' clause can be "
      "removed.",
  correctionMessage: "Try removing the catch clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_CATCH_CLAUSE',
  withArguments: _withArgumentsUnusedCatchClause,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the stack trace variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedCatchStack = DiagnosticWithArguments(
  name: 'UNUSED_CATCH_STACK',
  problemMessage:
      "The stack trace variable '{0}' isn't used and can be removed.",
  correctionMessage: "Try removing the stack trace variable, or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_CATCH_STACK',
  withArguments: _withArgumentsUnusedCatchStack,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name that is declared but not referenced
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedElement = DiagnosticWithArguments(
  name: 'UNUSED_ELEMENT',
  problemMessage: "The declaration '{0}' isn't referenced.",
  correctionMessage: "Try removing the declaration of '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_ELEMENT',
  withArguments: _withArgumentsUnusedElement,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the parameter that is declared but not used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedElementParameter = DiagnosticWithArguments(
  name: 'UNUSED_ELEMENT_PARAMETER',
  problemMessage: "A value for optional parameter '{0}' isn't ever given.",
  correctionMessage: "Try removing the unused parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_ELEMENT_PARAMETER',
  withArguments: _withArgumentsUnusedElementParameter,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// Object p0: the name of the unused field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedField = DiagnosticWithArguments(
  name: 'UNUSED_FIELD',
  problemMessage: "The value of the field '{0}' isn't used.",
  correctionMessage: "Try removing the field, or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_FIELD',
  withArguments: _withArgumentsUnusedField,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the content of the unused import's URI
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unusedImport = DiagnosticWithArguments(
  name: 'UNUSED_IMPORT',
  problemMessage: "Unused import: '{0}'.",
  correctionMessage: "Try removing the import directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_IMPORT',
  withArguments: _withArgumentsUnusedImport,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the label that isn't used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unusedLabel = DiagnosticWithArguments(
  name: 'UNUSED_LABEL',
  problemMessage: "The label '{0}' isn't used.",
  correctionMessage:
      "Try removing the label, or using it in either a 'break' or 'continue' "
      "statement.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_LABEL',
  withArguments: _withArgumentsUnusedLabel,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Object p0: the name of the unused variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0})
>
unusedLocalVariable = DiagnosticWithArguments(
  name: 'UNUSED_LOCAL_VARIABLE',
  problemMessage: "The value of the local variable '{0}' isn't used.",
  correctionMessage: "Try removing the variable or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_LOCAL_VARIABLE',
  withArguments: _withArgumentsUnusedLocalVariable,
  expectedTypes: [ExpectedType.object],
);

/// Parameters:
/// String p0: the name of the annotated method, property or function
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unusedResult = DiagnosticWithArguments(
  name: 'UNUSED_RESULT',
  problemMessage: "The value of '{0}' should be used.",
  correctionMessage:
      "Try using the result by invoking a member, passing it to a function, "
      "or returning it from this function.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_RESULT',
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
unusedResultWithMessage = DiagnosticWithArguments(
  name: 'UNUSED_RESULT',
  problemMessage: "'{0}' should be used. {1}.",
  correctionMessage:
      "Try using the result by invoking a member, passing it to a function, "
      "or returning it from this function.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_RESULT_WITH_MESSAGE',
  withArguments: _withArgumentsUnusedResultWithMessage,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// String p0: the name that is shown but not used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
unusedShownName = DiagnosticWithArguments(
  name: 'UNUSED_SHOWN_NAME',
  problemMessage: "The name {0} is shown, but isn't used.",
  correctionMessage: "Try removing the name from the list of shown members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.UNUSED_SHOWN_NAME',
  withArguments: _withArgumentsUnusedShownName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uriDoesNotExist = DiagnosticWithArguments(
  name: 'URI_DOES_NOT_EXIST',
  problemMessage: "Target of URI doesn't exist: '{0}'.",
  correctionMessage:
      "Try creating the file referenced by the URI, or try using a URI for a "
      "file that does exist.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.URI_DOES_NOT_EXIST',
  withArguments: _withArgumentsUriDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uriDoesNotExistInDocImport = DiagnosticWithArguments(
  name: 'URI_DOES_NOT_EXIST_IN_DOC_IMPORT',
  problemMessage: "Target of URI doesn't exist: '{0}'.",
  correctionMessage:
      "Try creating the file referenced by the URI, or try using a URI for a "
      "file that does exist.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT',
  withArguments: _withArgumentsUriDoesNotExistInDocImport,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String p0: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
uriHasNotBeenGenerated = DiagnosticWithArguments(
  name: 'URI_HAS_NOT_BEEN_GENERATED',
  problemMessage: "Target of URI hasn't been generated: '{0}'.",
  correctionMessage:
      "Try running the generator that will generate the file referenced by "
      "the URI.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED',
  withArguments: _withArgumentsUriHasNotBeenGenerated,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments uriWithInterpolation =
    DiagnosticWithoutArgumentsImpl(
      name: 'URI_WITH_INTERPOLATION',
      problemMessage: "URIs can't use string interpolation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.URI_WITH_INTERPOLATION',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
useOfNativeExtension = DiagnosticWithoutArgumentsImpl(
  name: 'USE_OF_NATIVE_EXTENSION',
  problemMessage:
      "Dart native extensions are deprecated and aren't available in Dart 2.15.",
  correctionMessage: "Try using dart:ffi for C interop.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.USE_OF_NATIVE_EXTENSION',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
useOfVoidResult = DiagnosticWithoutArgumentsImpl(
  name: 'USE_OF_VOID_RESULT',
  problemMessage:
      "This expression has a type of 'void' so its value can't be used.",
  correctionMessage:
      "Try checking to see if you're using the correct API; there might be a "
      "function or call that returns void you didn't expect. Also check type "
      "parameters and variables which might also be void.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.USE_OF_VOID_RESULT',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments valuesDeclarationInEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'VALUES_DECLARATION_IN_ENUM',
      problemMessage: "A member named 'values' can't be declared in an enum.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'CompileTimeErrorCode.VALUES_DECLARATION_IN_ENUM',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments varAndType = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_AND_TYPE',
  problemMessage:
      "Variables can't be declared using both 'var' and a type name.",
  correctionMessage: "Try removing 'var.'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_AND_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varAsTypeName = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_AS_TYPE_NAME',
  problemMessage: "The keyword 'var' can't be used as a type name.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_AS_TYPE_NAME',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varClass = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_CLASS',
  problemMessage: "Classes can't be declared to be 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_CLASS',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varEnum = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_ENUM',
  problemMessage: "Enums can't be declared to be 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_ENUM',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
variableLengthArrayNotLast = DiagnosticWithoutArgumentsImpl(
  name: 'VARIABLE_LENGTH_ARRAY_NOT_LAST',
  problemMessage:
      "Variable length 'Array's must only occur as the last field of Structs.",
  correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'FfiCode.VARIABLE_LENGTH_ARRAY_NOT_LAST',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
variablePatternKeywordInDeclarationContext = DiagnosticWithoutArgumentsImpl(
  name: 'VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
  problemMessage:
      "Variable patterns in declaration context can't specify 'var' or 'final' "
      "keyword.",
  correctionMessage: "Try removing the keyword.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VARIABLE_PATTERN_KEYWORD_IN_DECLARATION_CONTEXT',
  expectedTypes: [],
);

/// Parameters:
/// Object valueType: the type of the object being assigned.
/// Object variableType: the type of the variable being assigned to
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object valueType,
    required Object variableType,
  })
>
variableTypeMismatch = DiagnosticWithArguments(
  name: 'VARIABLE_TYPE_MISMATCH',
  problemMessage:
      "A value of type '{0}' can't be assigned to a const variable of type "
      "'{1}'.",
  correctionMessage: "Try using a subtype, or removing the 'const' keyword",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.VARIABLE_TYPE_MISMATCH',
  withArguments: _withArgumentsVariableTypeMismatch,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments varReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_RETURN_TYPE',
  problemMessage: "The return type can't be 'var'.",
  correctionMessage:
      "Try removing the keyword 'var', or replacing it with the name of the "
      "return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_RETURN_TYPE',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varTypedef = DiagnosticWithoutArgumentsImpl(
  name: 'VAR_TYPEDEF',
  problemMessage: "Typedefs can't be declared to be 'var'.",
  correctionMessage:
      "Try removing the keyword 'var', or replacing it with the name of the "
      "return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.VAR_TYPEDEF',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments voidWithTypeArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'VOID_WITH_TYPE_ARGUMENTS',
      problemMessage: "Type 'void' can't have type arguments.",
      correctionMessage: "Try removing the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.VOID_WITH_TYPE_ARGUMENTS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments withBeforeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'WITH_BEFORE_EXTENDS',
      problemMessage: "The extends clause must be before the with clause.",
      correctionMessage:
          "Try moving the extends clause before the with clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.WITH_BEFORE_EXTENDS',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
workspaceFieldNotList = DiagnosticWithoutArgumentsImpl(
  name: 'WORKSPACE_FIELD_NOT_LIST',
  problemMessage:
      "The value of the 'workspace' field is required to be a list of relative "
      "file paths.",
  correctionMessage:
      "Try converting the value to be a list of relative file paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.WORKSPACE_FIELD_NOT_LIST',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments workspaceValueNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'WORKSPACE_VALUE_NOT_STRING',
      problemMessage:
          "Workspace entries are required to be directory paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'PubspecWarningCode.WORKSPACE_VALUE_NOT_STRING',
      expectedTypes: [],
    );

/// Parameters:
/// String p0: the path of the directory that contains the pubspec.yaml file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0})
>
workspaceValueNotSubdirectory = DiagnosticWithArguments(
  name: 'WORKSPACE_VALUE_NOT_SUBDIRECTORY',
  problemMessage:
      "Workspace values must be a relative path of a subdirectory of '{0}'.",
  correctionMessage:
      "Try using a subdirectory of the directory containing the "
      "'pubspec.yaml' file.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'PubspecWarningCode.WORKSPACE_VALUE_NOT_SUBDIRECTORY',
  withArguments: _withArgumentsWorkspaceValueNotSubdirectory,
  expectedTypes: [ExpectedType.string],
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
    required Object p3,
  })
>
wrongExplicitTypeParameterVarianceInSuperinterface = DiagnosticWithArguments(
  name: 'WRONG_EXPLICIT_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
  problemMessage:
      "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position "
      "in '{3}'.",
  correctionMessage:
      "Try using 'in' type parameters in 'in' positions and 'out' type "
      "parameters in 'out' positions in the superinterface.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required int p1,
    required int p2,
  })
>
wrongNumberOfParametersForOperator = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
  problemMessage:
      "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
  withArguments: _withArgumentsWrongNumberOfParametersForOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// 7.1.1 Operators: It is a compile time error if the arity of the
/// user-declared operator - is not 0 or 1.
///
/// Parameters:
/// int p0: the number of parameters found in the operator declaration
const DiagnosticWithArguments<LocatableDiagnostic Function({required int p0})>
wrongNumberOfParametersForOperatorMinus = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR',
  problemMessage:
      "Operator '-' should declare 0 or 1 parameter, but {0} found.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS',
  withArguments: _withArgumentsWrongNumberOfParametersForOperatorMinus,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments wrongNumberOfParametersForSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
      problemMessage:
          "Setters must declare exactly one required positional parameter.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'ParserErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER',
      expectedTypes: [],
    );

/// Parameters:
/// Object p0: the name of the type being referenced (<i>G</i>)
/// int p1: the number of type parameters that were declared
/// int p2: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required int p1,
    required int p2,
  })
>
wrongNumberOfTypeArguments = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS',
  problemMessage:
      "The type '{0}' is declared with {1} type parameters, but {2} type "
      "arguments were given.",
  correctionMessage:
      "Try adjusting the number of type arguments to match the number of "
      "type parameters.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS',
  withArguments: _withArgumentsWrongNumberOfTypeArguments,
  expectedTypes: [ExpectedType.object, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArgumentsAnonymousFunction = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
  problemMessage:
      "This function is declared with {0} type parameters, but {1} type "
      "arguments were given.",
  correctionMessage:
      "Try adjusting the number of type arguments to match the number of "
      "type parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ANONYMOUS_FUNCTION',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsAnonymousFunction,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String p0: the name of the class being instantiated
/// String p1: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
wrongNumberOfTypeArgumentsConstructor = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
  problemMessage: "The constructor '{0}.{1}' doesn't have type parameters.",
  correctionMessage: "Try moving type arguments to after the type name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String p0: the name of the class being instantiated
/// String p1: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required String p1})
>
wrongNumberOfTypeArgumentsDotShorthandConstructor = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR',
  problemMessage: "The constructor '{0}.{1}` doesn't have type parameters.",
  correctionMessage:
      "Try removing the type arguments, or adding a class name, followed by "
      "the type arguments, then the constructor name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
      'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_DOT_SHORTHAND_CONSTRUCTOR',
  withArguments:
      _withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// int p0: the number of type parameters that were declared
/// int p1: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int p0, required int p1})
>
wrongNumberOfTypeArgumentsEnum = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
  problemMessage:
      "The enum is declared with {0} type parameters, but {1} type arguments "
      "were given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_ENUM',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsEnum,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String p0: the name of the extension being referenced
/// int p1: the number of type parameters that were declared
/// int p2: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String p0,
    required int p1,
    required int p2,
  })
>
wrongNumberOfTypeArgumentsExtension = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
  problemMessage:
      "The extension '{0}' is declared with {1} type parameters, but {2} type "
      "arguments were given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsExtension,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String functionName: the name of the function being referenced
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String functionName,
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArgumentsFunction = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
  problemMessage:
      "The function '{0}' is declared with {1} type parameters, but {2} type "
      "arguments were given.",
  correctionMessage:
      "Try adjusting the number of type arguments to match the number of "
      "type parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_FUNCTION',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsFunction,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// Type p0: the name of the method being referenced (<i>G</i>)
/// int p1: the number of type parameters that were declared
/// int p2: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType p0,
    required int p1,
    required int p2,
  })
>
wrongNumberOfTypeArgumentsMethod = DiagnosticWithArguments(
  name: 'WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
  problemMessage:
      "The method '{0}' is declared with {1} type parameters, but {2} type "
      "arguments are given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsMethod,
  expectedTypes: [ExpectedType.type, ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments
wrongSeparatorForPositionalParameter = DiagnosticWithoutArgumentsImpl(
  name: 'WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
  problemMessage:
      "The default value of a positional parameter should be preceded by '='.",
  correctionMessage: "Try replacing the ':' with '='.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.WRONG_SEPARATOR_FOR_POSITIONAL_PARAMETER',
  expectedTypes: [],
);

/// Parameters:
/// Object p0: the terminator that was expected
/// Object p1: the terminator that was found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Object p0, required Object p1})
>
wrongTerminatorForParameterGroup = DiagnosticWithArguments(
  name: 'WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
  problemMessage: "Expected '{0}' to close parameter group.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'ParserErrorCode.WRONG_TERMINATOR_FOR_PARAMETER_GROUP',
  withArguments: _withArgumentsWrongTerminatorForParameterGroup,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Let `C` be a generic class that declares a formal type parameter `X`, and
/// assume that `T` is a direct superinterface of `C`. It is a compile-time
/// error if `X` occurs contravariantly or invariantly in `T`.
///
/// Parameters:
/// String p0: the name of the type parameter
/// Type p1: the name of the super interface
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String p0, required DartType p1})
>
wrongTypeParameterVarianceInSuperinterface = DiagnosticWithArguments(
  name: 'WRONG_TYPE_PARAMETER_VARIANCE_IN_SUPERINTERFACE',
  problemMessage:
      "'{0}' can't be used contravariantly or invariantly in '{1}'.",
  correctionMessage:
      "Try not using class type parameters in types of formal parameters of "
      "function types, nor in explicitly contravariant or invariant "
      "superinterfaces.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName:
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
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object p0,
    required Object p1,
    required Object p2,
  })
>
wrongTypeParameterVariancePosition = DiagnosticWithArguments(
  name: 'WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
  problemMessage:
      "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
  correctionMessage:
      "Try removing the type parameter or change the explicit variance "
      "modifier declaration for the type parameter to another one of 'in', "
      "'out', or 'inout'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.WRONG_TYPE_PARAMETER_VARIANCE_POSITION',
  withArguments: _withArgumentsWrongTypeParameterVariancePosition,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.object,
    ExpectedType.object,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments
yieldEachInNonGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'YIELD_IN_NON_GENERATOR',
  problemMessage:
      "Yield-each statements must be in a generator function (one marked with "
      "either 'async*' or 'sync*').",
  correctionMessage:
      "Try adding 'async*' or 'sync*' to the enclosing function.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the type of the expression after `yield*`
/// Type p1: the return type of the function containing the `yield*`
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
yieldEachOfInvalidType = DiagnosticWithArguments(
  name: 'YIELD_OF_INVALID_TYPE',
  problemMessage:
      "The type '{0}' implied by the 'yield*' expression must be assignable to "
      "'{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.YIELD_EACH_OF_INVALID_TYPE',
  withArguments: _withArgumentsYieldEachOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// ?? Yield: It is a compile-time error if a yield statement appears in a
/// function that is not a generator function.
///
/// No parameters.
const DiagnosticWithoutArguments
yieldInNonGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'YIELD_IN_NON_GENERATOR',
  problemMessage:
      "Yield statements must be in a generator function (one marked with either "
      "'async*' or 'sync*').",
  correctionMessage:
      "Try adding 'async*' or 'sync*' to the enclosing function.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.YIELD_IN_NON_GENERATOR',
  expectedTypes: [],
);

/// Parameters:
/// Type p0: the type of the expression after `yield`
/// Type p1: the return type of the function containing the `yield`
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType p0, required DartType p1})
>
yieldOfInvalidType = DiagnosticWithArguments(
  name: 'YIELD_OF_INVALID_TYPE',
  problemMessage: "A yielded value of type '{0}' must be assignable to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'CompileTimeErrorCode.YIELD_OF_INVALID_TYPE',
  withArguments: _withArgumentsYieldOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

LocatableDiagnostic _withArgumentsAbiSpecificIntegerMappingUnsupported({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.abiSpecificIntegerMappingUnsupported, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsAbstractSuperMemberReference({
  required String memberKind,
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.abstractSuperMemberReference, [
    memberKind,
    name,
  ]);
}

LocatableDiagnostic _withArgumentsAmbiguousExport({
  required String p0,
  required Uri p1,
  required Uri p2,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousExport, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(
    diag.ambiguousExtensionMemberAccessThreeOrMore,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessTwo({
  required String p0,
  required Element p1,
  required Element p2,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousExtensionMemberAccessTwo, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsAmbiguousImport({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousImport, [p0, p1]);
}

LocatableDiagnostic _withArgumentsAnalysisOptionDeprecated({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.analysisOptionDeprecated, [p0]);
}

LocatableDiagnostic _withArgumentsAnalysisOptionDeprecatedWithReplacement({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.analysisOptionDeprecatedWithReplacement, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsArgumentMustBeAConstant({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.argumentMustBeAConstant, [p0]);
}

LocatableDiagnostic _withArgumentsArgumentTypeNotAssignable({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.argumentTypeNotAssignable, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsArgumentTypeNotAssignableToErrorHandler({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.argumentTypeNotAssignableToErrorHandler, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsAssetDirectoryDoesNotExist({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.assetDirectoryDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsAssetDoesNotExist({required String p0}) {
  return LocatableDiagnosticImpl(diag.assetDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsAssignmentOfDoNotStore({required String p0}) {
  return LocatableDiagnosticImpl(diag.assignmentOfDoNotStore, [p0]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinal({required String p0}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinal, [p0]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinalLocal({required String p0}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinalLocal, [p0]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinalNoSetter({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinalNoSetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsAugmentationModifierExtra({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.augmentationModifierExtra, [p0]);
}

LocatableDiagnostic _withArgumentsAugmentationModifierMissing({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.augmentationModifierMissing, [p0]);
}

LocatableDiagnostic _withArgumentsAugmentationOfDifferentDeclarationKind({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.augmentationOfDifferentDeclarationKind, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsAugmentedExpressionNotOperator({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.augmentedExpressionNotOperator, [p0]);
}

LocatableDiagnostic _withArgumentsBaseClassImplementedOutsideOfLibrary({
  required String implementedClassName,
}) {
  return LocatableDiagnosticImpl(diag.baseClassImplementedOutsideOfLibrary, [
    implementedClassName,
  ]);
}

LocatableDiagnostic _withArgumentsBaseMixinImplementedOutsideOfLibrary({
  required String implementedMixinName,
}) {
  return LocatableDiagnosticImpl(diag.baseMixinImplementedOutsideOfLibrary, [
    implementedMixinName,
  ]);
}

LocatableDiagnostic _withArgumentsBinaryOperatorWrittenOut({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.binaryOperatorWrittenOut, [
    string,
    string2,
  ]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormally({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormally, [p0]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyCatchError({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormallyCatchError, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyNullable({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormallyNullable, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsExtensionName, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionTypeName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsExtensionTypeName, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsPrefixName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsPrefixName, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsType, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypedefName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypedefName, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypeName, [p0]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeParameterName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypeParameterName, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsCaseExpressionTypeImplementsEquals({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.caseExpressionTypeImplementsEquals, [p0]);
}

LocatableDiagnostic
_withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(
    diag.caseExpressionTypeIsNotSwitchExpressionSubtype,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsCastFromNullableAlwaysFails({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.castFromNullableAlwaysFails, [p0]);
}

LocatableDiagnostic _withArgumentsCastToNonType({required String p0}) {
  return LocatableDiagnosticImpl(diag.castToNonType, [p0]);
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToInstanceMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.classInstantiationAccessToInstanceMember,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToStaticMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.classInstantiationAccessToStaticMember, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToUnknownMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.classInstantiationAccessToUnknownMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsClassUsedAsMixin({required String p0}) {
  return LocatableDiagnosticImpl(diag.classUsedAsMixin, [p0]);
}

LocatableDiagnostic _withArgumentsCompoundImplementsFinalizable({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.compoundImplementsFinalizable, [p0]);
}

LocatableDiagnostic _withArgumentsConcreteClassWithAbstractMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.concreteClassWithAbstractMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticField, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticGetter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticGetter, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticMethod({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticMethod, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticSetter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticSetter, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingFieldAndMethod({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingFieldAndMethod, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsConflictingGenericInterfaces({
  required String p0,
  required String p1,
  required String p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(diag.conflictingGenericInterfaces, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingInheritedMethodAndSetter({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingInheritedMethodAndSetter, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingMethodAndField({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingMethodAndField, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsConflictingModifiers({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingModifiers, [string, string2]);
}

LocatableDiagnostic _withArgumentsConflictingStaticAndInstance({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingStaticAndInstance, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndClass({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndClass, [p0]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndEnum({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndEnum, [p0]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtension({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndExtension, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtensionType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndExtensionType, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberClass({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberClass, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberEnum({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberEnum, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberExtension({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.conflictingTypeVariableAndMemberExtension,
    [p0],
  );
}

LocatableDiagnostic
_withArgumentsConflictingTypeVariableAndMemberExtensionType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.conflictingTypeVariableAndMemberExtensionType,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberMixin({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberMixin, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMixin({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMixin, [p0]);
}

LocatableDiagnostic _withArgumentsConstantPatternNeverMatchesValueType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.constantPatternNeverMatchesValueType, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorFieldTypeMismatch({
  required Object valueType,
  required Object fieldName,
  required Object fieldType,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorFieldTypeMismatch, [
    valueType,
    fieldName,
    fieldType,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorParamTypeMismatch({
  required String valueType,
  required String parameterType,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorParamTypeMismatch, [
    valueType,
    parameterType,
  ]);
}

LocatableDiagnostic
_withArgumentsConstConstructorWithFieldInitializedByNonConst({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.constConstructorWithFieldInitializedByNonConst,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithMixinWithField, [p0]);
}

LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithFields({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithMixinWithFields, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorWithNonConstSuper({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithNonConstSuper, [p0]);
}

LocatableDiagnostic _withArgumentsConstEvalAssertionFailureWithMessage({
  required Object message,
}) {
  return LocatableDiagnosticImpl(diag.constEvalAssertionFailureWithMessage, [
    message,
  ]);
}

LocatableDiagnostic _withArgumentsConstEvalPropertyAccess({
  required String propertyName,
  required String type,
}) {
  return LocatableDiagnosticImpl(diag.constEvalPropertyAccess, [
    propertyName,
    type,
  ]);
}

LocatableDiagnostic _withArgumentsConstFieldInitializerNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.constFieldInitializerNotAssignable, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsConstMapKeyNotPrimitiveEquality({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.constMapKeyNotPrimitiveEquality, [p0]);
}

LocatableDiagnostic _withArgumentsConstNotInitialized({required String p0}) {
  return LocatableDiagnosticImpl(diag.constNotInitialized, [p0]);
}

LocatableDiagnostic _withArgumentsConstSetElementNotPrimitiveEquality({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.constSetElementNotPrimitiveEquality, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsConstWithNonType({required String p0}) {
  return LocatableDiagnosticImpl(diag.constWithNonType, [p0]);
}

LocatableDiagnostic _withArgumentsConstWithUndefinedConstructor({
  required Object p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.constWithUndefinedConstructor, [p0, p1]);
}

LocatableDiagnostic _withArgumentsConstWithUndefinedConstructorDefault({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.constWithUndefinedConstructorDefault, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsCouldNotInfer({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.couldNotInfer, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDeadCodeOnCatchSubtype({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.deadCodeOnCatchSubtype, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDefinitelyUnassignedLateLocalVariable({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.definitelyUnassignedLateLocalVariable, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsDependenciesFieldNotMap({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.dependenciesFieldNotMap, [p0]);
}

LocatableDiagnostic _withArgumentsDeprecatedExportUse({required String p0}) {
  return LocatableDiagnosticImpl(diag.deprecatedExportUse, [p0]);
}

LocatableDiagnostic _withArgumentsDeprecatedExtend({required Object typeName}) {
  return LocatableDiagnosticImpl(diag.deprecatedExtend, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedField({required String p0}) {
  return LocatableDiagnosticImpl(diag.deprecatedField, [p0]);
}

LocatableDiagnostic _withArgumentsDeprecatedImplement({
  required Object typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedImplement, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedInstantiate({
  required Object typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedInstantiate, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedLint({required String p0}) {
  return LocatableDiagnosticImpl(diag.deprecatedLint, [p0]);
}

LocatableDiagnostic _withArgumentsDeprecatedLintWithReplacement({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedLintWithReplacement, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDeprecatedMemberUse({required String p0}) {
  return LocatableDiagnosticImpl(diag.deprecatedMemberUse, [p0]);
}

LocatableDiagnostic _withArgumentsDeprecatedMemberUseWithMessage({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedMemberUseWithMessage, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDeprecatedMixin({required Object typeName}) {
  return LocatableDiagnosticImpl(diag.deprecatedMixin, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedOptional({
  required Object parameterName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedOptional, [parameterName]);
}

LocatableDiagnostic _withArgumentsDeprecatedSubclass({
  required Object typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedSubclass, [typeName]);
}

LocatableDiagnostic _withArgumentsDocDirectiveArgumentWrongFormat({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveArgumentWrongFormat, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveHasExtraArguments({
  required String p0,
  required int p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveHasExtraArguments, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveHasUnexpectedNamedArgument({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveHasUnexpectedNamedArgument, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingClosingTag({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingClosingTag, [p0]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingOneArgument({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingOneArgument, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingOpeningTag({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingOpeningTag, [p0]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingThreeArguments({
  required String p0,
  required String p1,
  required String p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingThreeArguments, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingTwoArguments({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingTwoArguments, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveUnknown({required String p0}) {
  return LocatableDiagnosticImpl(diag.docDirectiveUnknown, [p0]);
}

LocatableDiagnostic _withArgumentsDotShorthandUndefinedGetter({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.dotShorthandUndefinedGetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsDotShorthandUndefinedInvocation({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.dotShorthandUndefinedInvocation, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsDuplicateConstructorName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.duplicateConstructorName, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateDefinition({required Object p0}) {
  return LocatableDiagnosticImpl(diag.duplicateDefinition, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateFieldFormalParameter({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.duplicateFieldFormalParameter, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateFieldName({required Object p0}) {
  return LocatableDiagnosticImpl(diag.duplicateFieldName, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateIgnore({required String p0}) {
  return LocatableDiagnosticImpl(diag.duplicateIgnore, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateNamedArgument({required String p0}) {
  return LocatableDiagnosticImpl(diag.duplicateNamedArgument, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicatePart({required Uri p0}) {
  return LocatableDiagnosticImpl(diag.duplicatePart, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicatePatternAssignmentVariable({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.duplicatePatternAssignmentVariable, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicatePatternField({required Object p0}) {
  return LocatableDiagnosticImpl(diag.duplicatePatternField, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateRule({required String p0}) {
  return LocatableDiagnosticImpl(diag.duplicateRule, [p0]);
}

LocatableDiagnostic _withArgumentsDuplicateVariablePattern({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.duplicateVariablePattern, [p0]);
}

LocatableDiagnostic _withArgumentsEmptyStruct({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.emptyStruct, [p0, p1]);
}

LocatableDiagnostic _withArgumentsEnumWithAbstractMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.enumWithAbstractMember, [p0, p1]);
}

LocatableDiagnostic _withArgumentsExpectedInstead({required String string}) {
  return LocatableDiagnosticImpl(diag.expectedInstead, [string]);
}

LocatableDiagnostic _withArgumentsExpectedOneListPatternTypeArguments({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneListPatternTypeArguments, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsExpectedOneListTypeArguments({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneListTypeArguments, [p0]);
}

LocatableDiagnostic _withArgumentsExpectedOneSetTypeArguments({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneSetTypeArguments, [p0]);
}

LocatableDiagnostic _withArgumentsExpectedToken({required String p0}) {
  return LocatableDiagnosticImpl(diag.expectedToken, [p0]);
}

LocatableDiagnostic _withArgumentsExpectedTwoMapPatternTypeArguments({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.expectedTwoMapPatternTypeArguments, [p0]);
}

LocatableDiagnostic _withArgumentsExpectedTwoMapTypeArguments({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.expectedTwoMapTypeArguments, [p0]);
}

LocatableDiagnostic _withArgumentsExperimentalMemberUse({
  required String member,
}) {
  return LocatableDiagnosticImpl(diag.experimentalMemberUse, [member]);
}

LocatableDiagnostic _withArgumentsExperimentNotEnabled({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.experimentNotEnabled, [string, string2]);
}

LocatableDiagnostic _withArgumentsExperimentNotEnabledOffByDefault({
  required String string,
}) {
  return LocatableDiagnosticImpl(diag.experimentNotEnabledOffByDefault, [
    string,
  ]);
}

LocatableDiagnostic _withArgumentsExportInternalLibrary({required String p0}) {
  return LocatableDiagnosticImpl(diag.exportInternalLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsExportOfNonLibrary({required String p0}) {
  return LocatableDiagnosticImpl(diag.exportOfNonLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsExtendsDisallowedClass({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.extendsDisallowedClass, [p0]);
}

LocatableDiagnostic _withArgumentsExtensionAsExpression({required String p0}) {
  return LocatableDiagnosticImpl(diag.extensionAsExpression, [p0]);
}

LocatableDiagnostic _withArgumentsExtensionConflictingStaticAndInstance({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.extensionConflictingStaticAndInstance, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionOverrideArgumentNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.extensionOverrideArgumentNotAssignable, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeImplementsDisallowedType({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeImplementsDisallowedType, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeImplementsNotSupertype({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeImplementsNotSupertype, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic
_withArgumentsExtensionTypeImplementsRepresentationNotSupertype({
  required DartType p0,
  required String p1,
  required DartType p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(
    diag.extensionTypeImplementsRepresentationNotSupertype,
    [p0, p1, p2, p3],
  );
}

LocatableDiagnostic _withArgumentsExtensionTypeInheritedMemberConflict({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeInheritedMemberConflict, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeWithAbstractMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeWithAbstractMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsExtraPositionalArguments({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(diag.extraPositionalArguments, [p0, p1]);
}

LocatableDiagnostic _withArgumentsExtraPositionalArgumentsCouldBeNamed({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(diag.extraPositionalArgumentsCouldBeNamed, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsFfiNativeUnexpectedNumberOfParameters({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(diag.ffiNativeUnexpectedNumberOfParameters, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic
_withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(
    diag.ffiNativeUnexpectedNumberOfParametersWithReceiver,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsFieldInitializedByMultipleInitializers({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializedByMultipleInitializers, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsFieldInitializerNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializerNotAssignable, [p0, p1]);
}

LocatableDiagnostic _withArgumentsFieldInitializingFormalNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializingFormalNotAssignable, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsFinalClassExtendedOutsideOfLibrary({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.finalClassExtendedOutsideOfLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsFinalClassImplementedOutsideOfLibrary({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.finalClassImplementedOutsideOfLibrary, [
    p0,
  ]);
}

LocatableDiagnostic
_withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.finalClassUsedAsMixinConstraintOutsideOfLibrary,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsFinalInitializedInDeclarationAndConstructor({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.finalInitializedInDeclarationAndConstructor,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsFinalNotInitialized({required String p0}) {
  return LocatableDiagnosticImpl(diag.finalNotInitialized, [p0]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor1({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor1, [p0]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor2({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor2, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor3Plus({
  required String p0,
  required String p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor3Plus, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsFixme({required String message}) {
  return LocatableDiagnosticImpl(diag.fixme, [message]);
}

LocatableDiagnostic _withArgumentsForInOfInvalidElementType({
  required DartType p0,
  required String p1,
  required DartType p2,
}) {
  return LocatableDiagnosticImpl(diag.forInOfInvalidElementType, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsForInOfInvalidType({
  required DartType p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.forInOfInvalidType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsGenericStructSubclass({required String p0}) {
  return LocatableDiagnosticImpl(diag.genericStructSubclass, [p0]);
}

LocatableDiagnostic _withArgumentsGetterNotAssignableSetterTypes({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(diag.getterNotAssignableSetterTypes, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic _withArgumentsGetterNotSubtypeSetterTypes({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(diag.getterNotSubtypeSetterTypes, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic _withArgumentsHack({required String message}) {
  return LocatableDiagnosticImpl(diag.hack, [message]);
}

LocatableDiagnostic _withArgumentsIllegalCharacter({required Object p0}) {
  return LocatableDiagnosticImpl(diag.illegalCharacter, [p0]);
}

LocatableDiagnostic _withArgumentsIllegalConcreteEnumMemberDeclaration({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.illegalConcreteEnumMemberDeclaration, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsIllegalConcreteEnumMemberInheritance({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.illegalConcreteEnumMemberInheritance, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsIllegalEnumValuesInheritance({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.illegalEnumValuesInheritance, [p0]);
}

LocatableDiagnostic _withArgumentsIllegalLanguageVersionOverride({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.illegalLanguageVersionOverride, [p0]);
}

LocatableDiagnostic _withArgumentsImplementsDisallowedClass({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.implementsDisallowedClass, [p0]);
}

LocatableDiagnostic _withArgumentsImplementsRepeated({required String p0}) {
  return LocatableDiagnosticImpl(diag.implementsRepeated, [p0]);
}

LocatableDiagnostic _withArgumentsImplementsSuperClass({required Element p0}) {
  return LocatableDiagnosticImpl(diag.implementsSuperClass, [p0]);
}

LocatableDiagnostic _withArgumentsImplicitSuperInitializerMissingArguments({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(
    diag.implicitSuperInitializerMissingArguments,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsImplicitThisReferenceInInitializer({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.implicitThisReferenceInInitializer, [p0]);
}

LocatableDiagnostic _withArgumentsImportInternalLibrary({required String p0}) {
  return LocatableDiagnosticImpl(diag.importInternalLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsImportOfNonLibrary({required String p0}) {
  return LocatableDiagnosticImpl(diag.importOfNonLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsIncludedFileParseError({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(diag.includedFileParseError, [p0, p1, p2, p3]);
}

LocatableDiagnostic _withArgumentsIncludedFileWarning({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(diag.includedFileWarning, [p0, p1, p2, p3]);
}

LocatableDiagnostic _withArgumentsIncludeFileNotFound({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.includeFileNotFound, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsIncompatibleLint({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLint, [p0, p1]);
}

LocatableDiagnostic _withArgumentsIncompatibleLintFiles({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLintFiles, [p0, p1]);
}

LocatableDiagnostic _withArgumentsIncompatibleLintIncluded({
  required String p0,
  required String p1,
  required int p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLintIncluded, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentCaseExpressionTypes({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentCaseExpressionTypes, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentInheritance({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentInheritance, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInconsistentInheritanceGetterAndMethod({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentInheritanceGetterAndMethod, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentPatternVariableLogicalOr({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentPatternVariableLogicalOr, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnCollectionLiteral({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnCollectionLiteral, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnFunctionInvocation({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnFunctionInvocation, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnFunctionReturnType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnFunctionReturnType, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnGenericInvocation({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnGenericInvocation, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnInstanceCreation({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnInstanceCreation, [p0]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnUninitializedVariable({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnUninitializedVariable, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnUntypedParameter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnUntypedParameter, [p0]);
}

LocatableDiagnostic _withArgumentsInitializerForNonExistentField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.initializerForNonExistentField, [p0]);
}

LocatableDiagnostic _withArgumentsInitializerForStaticField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.initializerForStaticField, [p0]);
}

LocatableDiagnostic _withArgumentsInitializingFormalForNonExistentField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.initializingFormalForNonExistentField, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInstanceAccessToStaticMember({
  required String p0,
  required String p1,
  required String p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(diag.instanceAccessToStaticMember, [
    p0,
    p1,
    p2,
    p3,
  ]);
}

LocatableDiagnostic
_withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.instanceAccessToStaticMemberOfUnnamedExtension,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsIntegerLiteralImpreciseAsDouble({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.integerLiteralImpreciseAsDouble, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsIntegerLiteralOutOfRange({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.integerLiteralOutOfRange, [p0]);
}

LocatableDiagnostic _withArgumentsInterfaceClassExtendedOutsideOfLibrary({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.interfaceClassExtendedOutsideOfLibrary, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidAnnotationTarget({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidAnnotationTarget, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidAssignment({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidAssignment, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCastFunction({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastFunction, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsInvalidCastFunctionExpr({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastFunctionExpr, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCastLiteral({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastLiteral, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsInvalidCastLiteralList({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastLiteralList, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCastLiteralMap({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastLiteralMap, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCastLiteralSet({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastLiteralSet, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCastMethod({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastMethod, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsInvalidCastNewExpr({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidCastNewExpr, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidCodePoint({required String p0}) {
  return LocatableDiagnosticImpl(diag.invalidCodePoint, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidDependency({required String p0}) {
  return LocatableDiagnosticImpl(diag.invalidDependency, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidExceptionValue({required String p0}) {
  return LocatableDiagnosticImpl(diag.invalidExceptionValue, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidExportOfInternalElement({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidExportOfInternalElement, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidExportOfInternalElementIndirectly({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidExportOfInternalElementIndirectly,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsInvalidFactoryMethodDecl({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidFactoryMethodDecl, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidFactoryMethodImpl({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidFactoryMethodImpl, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidFieldTypeInStruct({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidFieldTypeInStruct, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidImplementationOverride({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
  required Object p4,
}) {
  return LocatableDiagnosticImpl(diag.invalidImplementationOverride, [
    p0,
    p1,
    p2,
    p3,
    p4,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidImplementationOverrideSetter({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
  required Object p4,
}) {
  return LocatableDiagnosticImpl(diag.invalidImplementationOverrideSetter, [
    p0,
    p1,
    p2,
    p3,
    p4,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidLanguageVersionOverrideGreater({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidLanguageVersionOverrideGreater, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidModifierOnConstructor({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidModifierOnConstructor, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidNullAwareOperator({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidNullAwareOperator, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidNullAwareOperatorAfterShortCircuit({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidNullAwareOperatorAfterShortCircuit,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsInvalidOperatorForSuper({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidOperatorForSuper, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidOption({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidOption, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidOverride({
  required String p0,
  required String p1,
  required DartType p2,
  required String p3,
  required DartType p4,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverride, [p0, p1, p2, p3, p4]);
}

LocatableDiagnostic _withArgumentsInvalidOverrideOfNonVirtualMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverrideOfNonVirtualMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidOverrideSetter({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
  required Object p4,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverrideSetter, [
    p0,
    p1,
    p2,
    p3,
    p4,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidSectionFormat({required String p0}) {
  return LocatableDiagnosticImpl(diag.invalidSectionFormat, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstList({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstList, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstMap({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstMap, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstSet({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstSet, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidUri({required String p0}) {
  return LocatableDiagnosticImpl(diag.invalidUri, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfDoNotSubmitMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfDoNotSubmitMember, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfInternalMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfInternalMember, [p0]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfProtectedMember({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfProtectedMember, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForOverridingMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForOverridingMember, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTemplateMember({
  required String p0,
  required Uri p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForTemplateMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTestingMember({
  required String p0,
  required Uri p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForTestingMember, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidVisibilityAnnotation({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidVisibilityAnnotation, [p0, p1]);
}

LocatableDiagnostic _withArgumentsInvalidWidgetPreviewPrivateArgument({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.invalidWidgetPreviewPrivateArgument, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsInvocationOfExtensionWithoutCall({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invocationOfExtensionWithoutCall, [p0]);
}

LocatableDiagnostic _withArgumentsInvocationOfNonFunction({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.invocationOfNonFunction, [p0]);
}

LocatableDiagnostic _withArgumentsLabelInOuterScope({required String p0}) {
  return LocatableDiagnosticImpl(diag.labelInOuterScope, [p0]);
}

LocatableDiagnostic _withArgumentsLabelUndefined({required String p0}) {
  return LocatableDiagnosticImpl(diag.labelUndefined, [p0]);
}

LocatableDiagnostic _withArgumentsListElementTypeNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.listElementTypeNotAssignable, [p0, p1]);
}

LocatableDiagnostic _withArgumentsListElementTypeNotAssignableNullability({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.listElementTypeNotAssignableNullability, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.mapKeyTypeNotAssignable, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignableNullability({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.mapKeyTypeNotAssignableNullability, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsMapValueTypeNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.mapValueTypeNotAssignable, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMapValueTypeNotAssignableNullability({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.mapValueTypeNotAssignableNullability, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsMissingAnnotationOnStructField({
  required DartType p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.missingAnnotationOnStructField, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMissingDartLibrary({required Object p0}) {
  return LocatableDiagnosticImpl(diag.missingDartLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsMissingDefaultValueForParameter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.missingDefaultValueForParameter, [p0]);
}

LocatableDiagnostic _withArgumentsMissingDefaultValueForParameterPositional({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.missingDefaultValueForParameterPositional,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsMissingDependency({required String p0}) {
  return LocatableDiagnosticImpl(diag.missingDependency, [p0]);
}

LocatableDiagnostic _withArgumentsMissingEnumConstantInSwitch({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.missingEnumConstantInSwitch, [p0]);
}

LocatableDiagnostic _withArgumentsMissingExceptionValue({required String p0}) {
  return LocatableDiagnosticImpl(diag.missingExceptionValue, [p0]);
}

LocatableDiagnostic _withArgumentsMissingOverrideOfMustBeOverriddenOne({
  required String member,
}) {
  return LocatableDiagnosticImpl(diag.missingOverrideOfMustBeOverriddenOne, [
    member,
  ]);
}

LocatableDiagnostic _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus({
  required String firstMember,
  required String secondMember,
  required String additionalCount,
}) {
  return LocatableDiagnosticImpl(
    diag.missingOverrideOfMustBeOverriddenThreePlus,
    [firstMember, secondMember, additionalCount],
  );
}

LocatableDiagnostic _withArgumentsMissingOverrideOfMustBeOverriddenTwo({
  required String firstMember,
  required String secondMember,
}) {
  return LocatableDiagnosticImpl(diag.missingOverrideOfMustBeOverriddenTwo, [
    firstMember,
    secondMember,
  ]);
}

LocatableDiagnostic _withArgumentsMissingRequiredArgument({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.missingRequiredArgument, [p0]);
}

LocatableDiagnostic _withArgumentsMissingRequiredParam({required String p0}) {
  return LocatableDiagnosticImpl(diag.missingRequiredParam, [p0]);
}

LocatableDiagnostic _withArgumentsMissingRequiredParamWithDetails({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.missingRequiredParamWithDetails, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsMissingTerminatorForParameterGroup({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.missingTerminatorForParameterGroup, [p0]);
}

LocatableDiagnostic _withArgumentsMissingVariablePattern({required String p0}) {
  return LocatableDiagnosticImpl(diag.missingVariablePattern, [p0]);
}

LocatableDiagnostic
_withArgumentsMixinApplicationConcreteSuperInvokedMemberType({
  required String p0,
  required DartType p1,
  required DartType p2,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationConcreteSuperInvokedMemberType,
    [p0, p1, p2],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNoConcreteSuperInvokedMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationNoConcreteSuperInvokedMember,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationNoConcreteSuperInvokedSetter,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNotImplementedInterface({
  required DartType p0,
  required DartType p1,
  required DartType p2,
}) {
  return LocatableDiagnosticImpl(diag.mixinApplicationNotImplementedInterface, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsMixinClassDeclarationExtendsNotObject({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.mixinClassDeclarationExtendsNotObject, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsMixinClassDeclaresConstructor({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.mixinClassDeclaresConstructor, [p0]);
}

LocatableDiagnostic _withArgumentsMixinInheritsFromNotObject({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.mixinInheritsFromNotObject, [p0]);
}

LocatableDiagnostic _withArgumentsMixinOfDisallowedClass({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.mixinOfDisallowedClass, [p0]);
}

LocatableDiagnostic _withArgumentsMixinOnSealedClass({required String p0}) {
  return LocatableDiagnosticImpl(diag.mixinOnSealedClass, [p0]);
}

LocatableDiagnostic _withArgumentsMixinsSuperClass({required Element p0}) {
  return LocatableDiagnosticImpl(diag.mixinsSuperClass, [p0]);
}

LocatableDiagnostic _withArgumentsMixinSubtypeOfBaseIsNotBase({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.mixinSubtypeOfBaseIsNotBase, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMixinSubtypeOfFinalIsNotBase({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.mixinSubtypeOfFinalIsNotBase, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMixinSuperClassConstraintDisallowedClass({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinSuperClassConstraintDisallowedClass,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsModifierOutOfOrder({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.modifierOutOfOrder, [string, string2]);
}

LocatableDiagnostic _withArgumentsMultipleClauses({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.multipleClauses, [string, string2]);
}

LocatableDiagnostic _withArgumentsMultiplePlugins({required String p0}) {
  return LocatableDiagnosticImpl(diag.multiplePlugins, [p0]);
}

LocatableDiagnostic _withArgumentsMultipleVariablesInForEach({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.multipleVariablesInForEach, [p0]);
}

LocatableDiagnostic _withArgumentsMustBeANativeFunctionType({
  required Object p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.mustBeANativeFunctionType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsMustBeASubtype({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.mustBeASubtype, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsMustBeImmutable({required String p0}) {
  return LocatableDiagnosticImpl(diag.mustBeImmutable, [p0]);
}

LocatableDiagnostic _withArgumentsMustCallSuper({required String p0}) {
  return LocatableDiagnosticImpl(diag.mustCallSuper, [p0]);
}

LocatableDiagnostic _withArgumentsMustReturnVoid({required DartType p0}) {
  return LocatableDiagnosticImpl(diag.mustReturnVoid, [p0]);
}

LocatableDiagnostic _withArgumentsNativeFieldInvalidType({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.nativeFieldInvalidType, [p0]);
}

LocatableDiagnostic _withArgumentsNewWithNonType({required String p0}) {
  return LocatableDiagnosticImpl(diag.newWithNonType, [p0]);
}

LocatableDiagnostic _withArgumentsNewWithUndefinedConstructor({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.newWithUndefinedConstructor, [p0, p1]);
}

LocatableDiagnostic _withArgumentsNewWithUndefinedConstructorDefault({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.newWithUndefinedConstructorDefault, [p0]);
}

LocatableDiagnostic _withArgumentsNoCombinedSuperSignature({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.noCombinedSuperSignature, [p0, p1]);
}

LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorExplicit({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.noDefaultSuperConstructorExplicit, [p0]);
}

LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorImplicit({
  required DartType p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.noDefaultSuperConstructorImplicit, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsNoGenerativeConstructorsInSuperclass({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.noGenerativeConstructorsInSuperclass, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic
_withArgumentsNonAbstractClassInheritsAbstractMemberFivePlus({
  required String p0,
  required String p1,
  required String p2,
  required String p3,
  required int p4,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberFivePlus,
    [p0, p1, p2, p3, p4],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberFour({
  required String p0,
  required String p1,
  required String p2,
  required String p3,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberFour,
    [p0, p1, p2, p3],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberOne({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberOne,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberThree({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberThree,
    [p0, p1, p2],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberTwo({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberTwo,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsNonBoolOperand({required String p0}) {
  return LocatableDiagnosticImpl(diag.nonBoolOperand, [p0]);
}

LocatableDiagnostic _withArgumentsNonConstantTypeArgument({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.nonConstantTypeArgument, [p0]);
}

LocatableDiagnostic _withArgumentsNonConstArgumentForConstParameter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.nonConstArgumentForConstParameter, [p0]);
}

LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructor({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.nonConstCallToLiteralConstructor, [p0]);
}

LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructorUsingNew({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.nonConstCallToLiteralConstructorUsingNew,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsNonExhaustiveSwitchExpression({
  required DartType type,
  required String unmatchedPattern,
  required String suggestedPattern,
}) {
  return LocatableDiagnosticImpl(diag.nonExhaustiveSwitchExpression, [
    type,
    unmatchedPattern,
    suggestedPattern,
  ]);
}

LocatableDiagnostic _withArgumentsNonExhaustiveSwitchExpressionPrivate({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.nonExhaustiveSwitchExpressionPrivate, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsNonExhaustiveSwitchStatement({
  required DartType type,
  required String unmatchedPattern,
  required String suggestedPattern,
}) {
  return LocatableDiagnosticImpl(diag.nonExhaustiveSwitchStatement, [
    type,
    unmatchedPattern,
    suggestedPattern,
  ]);
}

LocatableDiagnostic _withArgumentsNonExhaustiveSwitchStatementPrivate({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.nonExhaustiveSwitchStatementPrivate, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsNonGenerativeConstructor({
  required Element p0,
}) {
  return LocatableDiagnosticImpl(diag.nonGenerativeConstructor, [p0]);
}

LocatableDiagnostic _withArgumentsNonGenerativeImplicitConstructor({
  required String p0,
  required String p1,
  required Element p2,
}) {
  return LocatableDiagnosticImpl(diag.nonGenerativeImplicitConstructor, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsNonNativeFunctionTypeArgumentToPointer({
  required DartType p0,
}) {
  return LocatableDiagnosticImpl(diag.nonNativeFunctionTypeArgumentToPointer, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsNonSizedTypeArgument({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.nonSizedTypeArgument, [p0, p1]);
}

LocatableDiagnostic _withArgumentsNonTypeAsTypeArgument({required String p0}) {
  return LocatableDiagnosticImpl(diag.nonTypeAsTypeArgument, [p0]);
}

LocatableDiagnostic _withArgumentsNonTypeInCatchClause({required String p0}) {
  return LocatableDiagnosticImpl(diag.nonTypeInCatchClause, [p0]);
}

LocatableDiagnostic _withArgumentsNonUserDefinableOperator({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.nonUserDefinableOperator, [p0]);
}

LocatableDiagnostic
_withArgumentsNotAssignedPotentiallyNonNullableLocalVariable({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.notAssignedPotentiallyNonNullableLocalVariable,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsNotAType({required String p0}) {
  return LocatableDiagnosticImpl(diag.notAType, [p0]);
}

LocatableDiagnostic _withArgumentsNotBinaryOperator({required String p0}) {
  return LocatableDiagnosticImpl(diag.notBinaryOperator, [p0]);
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsNamePlural({
  required int p0,
  required int p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.notEnoughPositionalArgumentsNamePlural, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsNameSingular({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.notEnoughPositionalArgumentsNameSingular,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsPlural({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(diag.notEnoughPositionalArgumentsPlural, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsNotInitializedNonNullableInstanceField({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.notInitializedNonNullableInstanceField, [
    p0,
  ]);
}

LocatableDiagnostic
_withArgumentsNotInitializedNonNullableInstanceFieldConstructor({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.notInitializedNonNullableInstanceFieldConstructor,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsNotInitializedNonNullableVariable({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.notInitializedNonNullableVariable, [p0]);
}

LocatableDiagnostic _withArgumentsNullArgumentToNonNullType({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.nullArgumentToNonNullType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsOnRepeated({required String p0}) {
  return LocatableDiagnosticImpl(diag.onRepeated, [p0]);
}

LocatableDiagnostic _withArgumentsOutOfOrderClauses({
  required String string,
  required String string2,
}) {
  return LocatableDiagnosticImpl(diag.outOfOrderClauses, [string, string2]);
}

LocatableDiagnostic _withArgumentsParseError({required Object p0}) {
  return LocatableDiagnosticImpl(diag.parseError, [p0]);
}

LocatableDiagnostic _withArgumentsPartOfDifferentLibrary({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.partOfDifferentLibrary, [p0, p1]);
}

LocatableDiagnostic _withArgumentsPartOfNonPart({required String p0}) {
  return LocatableDiagnosticImpl(diag.partOfNonPart, [p0]);
}

LocatableDiagnostic _withArgumentsPartOfUnnamedLibrary({required String p0}) {
  return LocatableDiagnosticImpl(diag.partOfUnnamedLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsPathDoesNotExist({required String p0}) {
  return LocatableDiagnosticImpl(diag.pathDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsPathNotPosix({required String p0}) {
  return LocatableDiagnosticImpl(diag.pathNotPosix, [p0]);
}

LocatableDiagnostic _withArgumentsPathPubspecDoesNotExist({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.pathPubspecDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsPatternNeverMatchesValueType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.patternNeverMatchesValueType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsPatternTypeMismatchInIrrefutableContext({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.patternTypeMismatchInIrrefutableContext, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic
_withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.patternVariableSharedCaseScopeDifferentFinalityOrType,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsPatternVariableSharedCaseScopeHasLabel({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.patternVariableSharedCaseScopeHasLabel, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsPatternVariableSharedCaseScopeNotAllCases({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.patternVariableSharedCaseScopeNotAllCases,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsPermissionImpliesUnsupportedHardware({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.permissionImpliesUnsupportedHardware, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsPluginsInInnerOptions({
  required String contextRoot,
}) {
  return LocatableDiagnosticImpl(diag.pluginsInInnerOptions, [contextRoot]);
}

LocatableDiagnostic _withArgumentsPrefixCollidesWithTopLevelMember({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.prefixCollidesWithTopLevelMember, [p0]);
}

LocatableDiagnostic _withArgumentsPrefixIdentifierNotFollowedByDot({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.prefixIdentifierNotFollowedByDot, [p0]);
}

LocatableDiagnostic _withArgumentsPrefixShadowedByLocalDeclaration({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.prefixShadowedByLocalDeclaration, [p0]);
}

LocatableDiagnostic _withArgumentsPrivateCollisionInMixinApplication({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.privateCollisionInMixinApplication, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsPrivateSetter({required String p0}) {
  return LocatableDiagnosticImpl(diag.privateSetter, [p0]);
}

LocatableDiagnostic _withArgumentsReadPotentiallyUnassignedFinal({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.readPotentiallyUnassignedFinal, [p0]);
}

LocatableDiagnostic _withArgumentsRecursiveIncludeFile({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.recursiveIncludeFile, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritance({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritance, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceExtends({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceExtends, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceImplements({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceImplements, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceOn({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceOn, [p0]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceWith({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceWith, [p0]);
}

LocatableDiagnostic _withArgumentsRedeclareOnNonRedeclaringMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.redeclareOnNonRedeclaringMember, [p0]);
}

LocatableDiagnostic _withArgumentsRedirectGenerativeToMissingConstructor({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.redirectGenerativeToMissingConstructor, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToAbstractClassConstructor({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.redirectToAbstractClassConstructor, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToInvalidFunctionType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.redirectToInvalidFunctionType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRedirectToInvalidReturnType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.redirectToInvalidReturnType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRedirectToMissingConstructor({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.redirectToMissingConstructor, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRedirectToNonClass({required String p0}) {
  return LocatableDiagnosticImpl(diag.redirectToNonClass, [p0]);
}

LocatableDiagnostic _withArgumentsReferencedBeforeDeclaration({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.referencedBeforeDeclaration, [p0]);
}

LocatableDiagnostic _withArgumentsRelationalPatternOperandTypeNotAssignable({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(
    diag.relationalPatternOperandTypeNotAssignable,
    [p0, p1, p2],
  );
}

LocatableDiagnostic _withArgumentsRemovedLint({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.removedLint, [p0, p1]);
}

LocatableDiagnostic _withArgumentsRemovedLintUse({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.removedLintUse, [p0, p1]);
}

LocatableDiagnostic _withArgumentsReplacedLint({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.replacedLint, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsReplacedLintUse({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.replacedLintUse, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsReturnOfDoNotStore({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.returnOfDoNotStore, [p0, p1]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromCatchError({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromCatchError, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromClosure({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromClosure, [p0, p1]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromConstructor({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromConstructor, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromFunction({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromFunction, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromMethod({
  required DartType p0,
  required DartType p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromMethod, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsReturnTypeInvalidForCatchError({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.returnTypeInvalidForCatchError, [p0, p1]);
}

LocatableDiagnostic _withArgumentsSdkVersionSince({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.sdkVersionSince, [p0, p1]);
}

LocatableDiagnostic _withArgumentsSealedClassSubtypeOutsideOfLibrary({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.sealedClassSubtypeOutsideOfLibrary, [p0]);
}

LocatableDiagnostic _withArgumentsSetElementTypeNotAssignable({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.setElementTypeNotAssignable, [p0, p1]);
}

LocatableDiagnostic _withArgumentsSetElementTypeNotAssignableNullability({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.setElementTypeNotAssignableNullability, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsStaticAccessToInstanceMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.staticAccessToInstanceMember, [p0]);
}

LocatableDiagnostic _withArgumentsStrictRawType({required DartType p0}) {
  return LocatableDiagnosticImpl(diag.strictRawType, [p0]);
}

LocatableDiagnostic _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfBaseIsNotBaseFinalOrSealed, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfFinalIsNotBaseFinalOrSealed, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfSealedClass({required String p0}) {
  return LocatableDiagnosticImpl(diag.subtypeOfSealedClass, [p0]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInExtends({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInExtends, [p0, p1]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInImplements({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInImplements, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInWith({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInWith, [p0, p1]);
}

LocatableDiagnostic
_withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(
    diag.superFormalParameterTypeIsNotSubtypeOfAssociated,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsSuperInvocationNotLast({required String p0}) {
  return LocatableDiagnosticImpl(diag.superInvocationNotLast, [p0]);
}

LocatableDiagnostic _withArgumentsTextDirectionCodePointInComment({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.textDirectionCodePointInComment, [p0]);
}

LocatableDiagnostic _withArgumentsTextDirectionCodePointInLiteral({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.textDirectionCodePointInLiteral, [p0]);
}

LocatableDiagnostic _withArgumentsThrowOfInvalidType({required DartType p0}) {
  return LocatableDiagnosticImpl(diag.throwOfInvalidType, [p0]);
}

LocatableDiagnostic _withArgumentsTodo({required String message}) {
  return LocatableDiagnosticImpl(diag.todo, [message]);
}

LocatableDiagnostic _withArgumentsTopLevelCycle({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.topLevelCycle, [p0, p1]);
}

LocatableDiagnostic _withArgumentsTypeAnnotationDeferredClass({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.typeAnnotationDeferredClass, [p0]);
}

LocatableDiagnostic _withArgumentsTypeArgumentNotMatchingBounds({
  required DartType p0,
  required String p1,
  required DartType p2,
}) {
  return LocatableDiagnosticImpl(diag.typeArgumentNotMatchingBounds, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsTypeParameterSupertypeOfItsBound({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.typeParameterSupertypeOfItsBound, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsTypeTestWithNonType({required String p0}) {
  return LocatableDiagnosticImpl(diag.typeTestWithNonType, [p0]);
}

LocatableDiagnostic _withArgumentsTypeTestWithUndefinedName({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.typeTestWithUndefinedName, [p0]);
}

LocatableDiagnostic _withArgumentsUnableGetContent({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unableGetContent, [p0]);
}

LocatableDiagnostic _withArgumentsUncheckedMethodInvocationOfNullableValue({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.uncheckedMethodInvocationOfNullableValue,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsUncheckedOperatorInvocationOfNullableValue({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.uncheckedOperatorInvocationOfNullableValue,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsUncheckedPropertyAccessOfNullableValue({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.uncheckedPropertyAccessOfNullableValue, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedAnnotation({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedAnnotation, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedClass({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedClass, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedClassBoolean({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedClassBoolean, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializer({
  required DartType p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedConstructorInInitializer, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializerDefault({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(
    diag.undefinedConstructorInInitializerDefault,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsUndefinedEnumConstant({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedEnumConstant, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedEnumConstructorNamed({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.undefinedEnumConstructorNamed, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionGetter({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionGetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionMethod({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionMethod, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionOperator({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionOperator, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionSetter({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionSetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedFunction({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedFunction, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedGetter({
  required String p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedGetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedGetterOnFunctionType({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedGetterOnFunctionType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedHiddenName({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedHiddenName, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedIdentifier({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedIdentifier, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedLint({required String p0}) {
  return LocatableDiagnosticImpl(diag.undefinedLint, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedMethod({
  required String p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedMethod, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedMethodOnFunctionType({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedMethodOnFunctionType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedNamedParameter({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.undefinedNamedParameter, [p0]);
}

LocatableDiagnostic _withArgumentsUndefinedOperator({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedOperator, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedPrefixedName({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedPrefixedName, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedReferencedParameter({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedReferencedParameter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSetter({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSetterOnFunctionType({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSetterOnFunctionType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedShownName({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedShownName, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperGetter({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperGetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperMethod({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperMethod, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperOperator({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperOperator, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperSetter({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperSetter, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUndone({required String message}) {
  return LocatableDiagnosticImpl(diag.undone, [message]);
}

LocatableDiagnostic _withArgumentsUnexpectedTerminatorForParameterGroup({
  required Object p0,
}) {
  return LocatableDiagnosticImpl(diag.unexpectedTerminatorForParameterGroup, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsUnexpectedToken({required String p0}) {
  return LocatableDiagnosticImpl(diag.unexpectedToken, [p0]);
}

LocatableDiagnostic _withArgumentsUnignorableIgnore({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unignorableIgnore, [p0]);
}

LocatableDiagnostic _withArgumentsUnknownPlatform({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unknownPlatform, [p0]);
}

LocatableDiagnostic _withArgumentsUnnecessaryDevDependency({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryDevDependency, [p0]);
}

LocatableDiagnostic _withArgumentsUnnecessaryImport({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryImport, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUnnecessaryQuestionMark({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryQuestionMark, [p0]);
}

LocatableDiagnostic _withArgumentsUnqualifiedReferenceToNonLocalStaticMember({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.unqualifiedReferenceToNonLocalStaticMember,
    [p0],
  );
}

LocatableDiagnostic
_withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType({
  required String p0,
}) {
  return LocatableDiagnosticImpl(
    diag.unqualifiedReferenceToStaticMemberOfExtendedType,
    [p0],
  );
}

LocatableDiagnostic _withArgumentsUnrecognizedErrorCode({required String p0}) {
  return LocatableDiagnosticImpl(diag.unrecognizedErrorCode, [p0]);
}

LocatableDiagnostic _withArgumentsUnsupportedChromeOsFeature({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedChromeOsFeature, [p0]);
}

LocatableDiagnostic _withArgumentsUnsupportedChromeOsHardware({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedChromeOsHardware, [p0]);
}

LocatableDiagnostic _withArgumentsUnsupportedOperator({required String p0}) {
  return LocatableDiagnosticImpl(diag.unsupportedOperator, [p0]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValue({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithLegalValue, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValues({
  required String p0,
  required String p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithLegalValues, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithoutValues({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithoutValues, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUnsupportedValue({
  required String p0,
  required Object p1,
  required String p2,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedValue, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsUnusedCatchClause({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedCatchClause, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedCatchStack({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedCatchStack, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedElement({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedElement, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedElementParameter({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedElementParameter, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedField({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedField, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedImport({required String p0}) {
  return LocatableDiagnosticImpl(diag.unusedImport, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedLabel({required String p0}) {
  return LocatableDiagnosticImpl(diag.unusedLabel, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedLocalVariable({required Object p0}) {
  return LocatableDiagnosticImpl(diag.unusedLocalVariable, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedResult({required String p0}) {
  return LocatableDiagnosticImpl(diag.unusedResult, [p0]);
}

LocatableDiagnostic _withArgumentsUnusedResultWithMessage({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.unusedResultWithMessage, [p0, p1]);
}

LocatableDiagnostic _withArgumentsUnusedShownName({required String p0}) {
  return LocatableDiagnosticImpl(diag.unusedShownName, [p0]);
}

LocatableDiagnostic _withArgumentsUriDoesNotExist({required String p0}) {
  return LocatableDiagnosticImpl(diag.uriDoesNotExist, [p0]);
}

LocatableDiagnostic _withArgumentsUriDoesNotExistInDocImport({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.uriDoesNotExistInDocImport, [p0]);
}

LocatableDiagnostic _withArgumentsUriHasNotBeenGenerated({required String p0}) {
  return LocatableDiagnosticImpl(diag.uriHasNotBeenGenerated, [p0]);
}

LocatableDiagnostic _withArgumentsVariableTypeMismatch({
  required Object valueType,
  required Object variableType,
}) {
  return LocatableDiagnosticImpl(diag.variableTypeMismatch, [
    valueType,
    variableType,
  ]);
}

LocatableDiagnostic _withArgumentsWorkspaceValueNotSubdirectory({
  required String p0,
}) {
  return LocatableDiagnosticImpl(diag.workspaceValueNotSubdirectory, [p0]);
}

LocatableDiagnostic
_withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface({
  required Object p0,
  required Object p1,
  required Object p2,
  required Object p3,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongExplicitTypeParameterVarianceInSuperinterface,
    [p0, p1, p2, p3],
  );
}

LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperator({
  required String p0,
  required int p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfParametersForOperator, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperatorMinus({
  required int p0,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfParametersForOperatorMinus, [
    p0,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArguments({
  required Object p0,
  required int p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArguments, [p0, p1, p2]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsAnonymousFunction({
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongNumberOfTypeArgumentsAnonymousFunction,
    [typeParameterCount, typeArgumentCount],
  );
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsConstructor({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsConstructor, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic
_withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor({
  required String p0,
  required String p1,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongNumberOfTypeArgumentsDotShorthandConstructor,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsEnum({
  required int p0,
  required int p1,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsEnum, [p0, p1]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsExtension({
  required String p0,
  required int p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsExtension, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsFunction({
  required String functionName,
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsFunction, [
    functionName,
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsMethod({
  required DartType p0,
  required int p1,
  required int p2,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsMethod, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsWrongTerminatorForParameterGroup({
  required Object p0,
  required Object p1,
}) {
  return LocatableDiagnosticImpl(diag.wrongTerminatorForParameterGroup, [
    p0,
    p1,
  ]);
}

LocatableDiagnostic _withArgumentsWrongTypeParameterVarianceInSuperinterface({
  required String p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongTypeParameterVarianceInSuperinterface,
    [p0, p1],
  );
}

LocatableDiagnostic _withArgumentsWrongTypeParameterVariancePosition({
  required Object p0,
  required Object p1,
  required Object p2,
}) {
  return LocatableDiagnosticImpl(diag.wrongTypeParameterVariancePosition, [
    p0,
    p1,
    p2,
  ]);
}

LocatableDiagnostic _withArgumentsYieldEachOfInvalidType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.yieldEachOfInvalidType, [p0, p1]);
}

LocatableDiagnostic _withArgumentsYieldOfInvalidType({
  required DartType p0,
  required DartType p1,
}) {
  return LocatableDiagnosticImpl(diag.yieldOfInvalidType, [p0, p1]);
}
