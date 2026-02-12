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
      name: 'abi_specific_integer_invalid',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one const "
          "constructor, no other members, and no type parameters.",
      correctionMessage:
          "Try removing all type parameters, removing all members, and adding "
          "one const constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'abi_specific_integer_invalid',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abiSpecificIntegerMappingExtra =
    DiagnosticWithoutArgumentsImpl(
      name: 'abi_specific_integer_mapping_extra',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one "
          "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
          "ABI to a 'NativeType' integer with a fixed size.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'abi_specific_integer_mapping_extra',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abiSpecificIntegerMappingMissing =
    DiagnosticWithoutArgumentsImpl(
      name: 'abi_specific_integer_mapping_missing',
      problemMessage:
          "Classes extending 'AbiSpecificInteger' must have exactly one "
          "'AbiSpecificIntegerMapping' annotation specifying the mapping from "
          "ABI to a 'NativeType' integer with a fixed size.",
      correctionMessage: "Try adding an annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'abi_specific_integer_mapping_missing',
      expectedTypes: [],
    );

/// Parameters:
/// String mappingName: the value of the invalid mapping
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String mappingName})
>
abiSpecificIntegerMappingUnsupported = DiagnosticWithArguments(
  name: 'abi_specific_integer_mapping_unsupported',
  problemMessage:
      "Invalid mapping to '{0}'; only mappings to 'Int8', 'Int16', 'Int32', "
      "'Int64', 'Uint8', 'Uint16', 'UInt32', and 'Uint64' are supported.",
  correctionMessage:
      "Try changing the value to 'Int8', 'Int16', 'Int32', 'Int64', 'Uint8', "
      "'Uint16', 'UInt32', or 'Uint64'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'abi_specific_integer_mapping_unsupported',
  withArguments: _withArgumentsAbiSpecificIntegerMappingUnsupported,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments abstractClassMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_class_member',
      problemMessage: "Members of classes can't be declared to be 'abstract'.",
      correctionMessage:
          "Try removing the 'abstract' keyword. You can add the 'abstract' "
          "keyword before the class declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_class_member',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractExternalField =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_external_field',
      problemMessage:
          "Fields can't be declared both 'abstract' and 'external'.",
      correctionMessage: "Try removing the 'abstract' or 'external' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_external_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
abstractFieldConstructorInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'abstract_field_initializer',
  problemMessage: "Abstract fields can't have initializers.",
  correctionMessage:
      "Try removing the field initializer or the 'abstract' keyword from the "
      "field declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'abstract_field_constructor_initializer',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments abstractFieldInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_field_initializer',
      problemMessage: "Abstract fields can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'abstract' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'abstract_field_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractFinalBaseClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_final_base_class',
      problemMessage:
          "An 'abstract' class can't be declared as both 'final' and 'base'.",
      correctionMessage: "Try removing either the 'final' or 'base' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_final_base_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
abstractFinalInterfaceClass = DiagnosticWithoutArgumentsImpl(
  name: 'abstract_final_interface_class',
  problemMessage:
      "An 'abstract' class can't be declared as both 'final' and 'interface'.",
  correctionMessage: "Try removing either the 'final' or 'interface' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'abstract_final_interface_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments abstractLateField =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_late_field',
      problemMessage: "Abstract fields cannot be late.",
      correctionMessage: "Try removing the 'abstract' or 'late' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_late_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractSealedClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_sealed_class',
      problemMessage:
          "A 'sealed' class can't be marked 'abstract' because it's already "
          "implicitly abstract.",
      correctionMessage: "Try removing the 'abstract' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_sealed_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractStaticField =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_static_field',
      problemMessage: "Static fields can't be declared 'abstract'.",
      correctionMessage: "Try removing the 'abstract' or 'static' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_static_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments abstractStaticMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'abstract_static_method',
      problemMessage: "Static methods can't be declared to be 'abstract'.",
      correctionMessage: "Try removing the keyword 'abstract'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'abstract_static_method',
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
  name: 'abstract_super_member_reference',
  problemMessage: "The {0} '{1}' is always abstract in the supertype.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'abstract_super_member_reference',
  withArguments: _withArgumentsAbstractSuperMemberReference,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
addressPosition = DiagnosticWithoutArgumentsImpl(
  name: 'address_position',
  problemMessage:
      "The '.address' expression can only be used as argument to a leaf native "
      "external call.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'address_position',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
addressReceiver = DiagnosticWithoutArgumentsImpl(
  name: 'address_receiver',
  problemMessage:
      "The receiver of '.address' must be a concrete 'TypedData', a concrete "
      "'TypedData' '[]', an 'Array', an 'Array' '[]', a Struct field, or a "
      "Union field.",
  correctionMessage:
      "Change the receiver of '.address' to one of the allowed kinds.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'address_receiver',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the ambiguous element
/// Uri firstUri: the name of the first library in which the type is found
/// Uri secondUri: the name of the second library in which the type is found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required Uri firstUri,
    required Uri secondUri,
  })
>
ambiguousExport = DiagnosticWithArguments(
  name: 'ambiguous_export',
  problemMessage: "The name '{0}' is defined in the libraries '{1}' and '{2}'.",
  correctionMessage:
      "Try removing the export of one of the libraries, or explicitly hiding "
      "the name in one of the export directives.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_export',
  withArguments: _withArgumentsAmbiguousExport,
  expectedTypes: [ExpectedType.string, ExpectedType.uri, ExpectedType.uri],
);

/// Parameters:
/// String name: the name of the member
/// String extensions: the names of the declaring extensions
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required String extensions,
  })
>
ambiguousExtensionMemberAccessThreeOrMore = DiagnosticWithArguments(
  name: 'ambiguous_extension_member_access',
  problemMessage:
      "A member named '{0}' is defined in {1}, and none are more specific.",
  correctionMessage:
      "Try using an extension override to specify the extension you want to "
      "be chosen.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_extension_member_access_three_or_more',
  withArguments: _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the member
/// Element firstExtension: the name of the first declaring extension
/// Element secondExtension: the names of the second declaring extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required Element firstExtension,
    required Element secondExtension,
  })
>
ambiguousExtensionMemberAccessTwo = DiagnosticWithArguments(
  name: 'ambiguous_extension_member_access',
  problemMessage:
      "A member named '{0}' is defined in '{1}' and '{2}', and neither is more "
      "specific.",
  correctionMessage:
      "Try using an extension override to specify the extension you want to "
      "be chosen.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_extension_member_access_two',
  withArguments: _withArgumentsAmbiguousExtensionMemberAccessTwo,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.element,
    ExpectedType.element,
  ],
);

/// Parameters:
/// String name: the name of the ambiguous type
/// String libraries: the names of the libraries that the type is found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required String libraries,
  })
>
ambiguousImport = DiagnosticWithArguments(
  name: 'ambiguous_import',
  problemMessage: "The name '{0}' is defined in the libraries {1}.",
  correctionMessage:
      "Try using 'as prefix' for one of the import directives, or hiding the "
      "name from all but one of the imports.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_import',
  withArguments: _withArgumentsAmbiguousImport,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
ambiguousSetOrMapLiteralBoth = DiagnosticWithoutArgumentsImpl(
  name: 'ambiguous_set_or_map_literal_both',
  problemMessage:
      "The literal can't be either a map or a set because it contains at least "
      "one literal map entry or a spread operator spreading a 'Map', and at "
      "least one element which is neither of these.",
  correctionMessage:
      "Try removing or changing some of the elements so that all of the "
      "elements are consistent.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_set_or_map_literal_both',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
ambiguousSetOrMapLiteralEither = DiagnosticWithoutArgumentsImpl(
  name: 'ambiguous_set_or_map_literal_either',
  problemMessage:
      "This literal must be either a map or a set, but the elements don't have "
      "enough information for type inference to work.",
  correctionMessage:
      "Try adding type arguments to the literal (one for sets, two for "
      "maps).",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ambiguous_set_or_map_literal_either',
  expectedTypes: [],
);

/// An error code indicating that the given option is deprecated.
///
/// Parameters:
/// String optionName: the option name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String optionName})
>
analysisOptionDeprecated = DiagnosticWithArguments(
  name: 'analysis_option_deprecated',
  problemMessage: "The option '{0}' is no longer supported.",
  correctionMessage: "Try removing the option.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'analysis_option_deprecated',
  withArguments: _withArgumentsAnalysisOptionDeprecated,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating that the given option is deprecated.
///
/// Parameters:
/// Object optionName: the option name
/// Object replacementOptionName: the replacement option name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object optionName,
    required Object replacementOptionName,
  })
>
analysisOptionDeprecatedWithReplacement = DiagnosticWithArguments(
  name: 'analysis_option_deprecated',
  problemMessage: "The option '{0}' is no longer supported.",
  correctionMessage: "Try using the new '{1}' option.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'analysis_option_deprecated_with_replacement',
  withArguments: _withArgumentsAnalysisOptionDeprecatedWithReplacement,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// No parameters.
const DiagnosticWithoutArguments annotationOnPointerField =
    DiagnosticWithoutArgumentsImpl(
      name: 'annotation_on_pointer_field',
      problemMessage:
          "Fields in a struct class whose type is 'Pointer' shouldn't have any "
          "annotations.",
      correctionMessage: "Try removing the annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'annotation_on_pointer_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
annotationOnTypeArgument = DiagnosticWithoutArgumentsImpl(
  name: 'annotation_on_type_argument',
  problemMessage:
      "Type arguments can't have annotations because they aren't declarations.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'annotation_on_type_argument',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments annotationSpaceBeforeParenthesis =
    DiagnosticWithoutArgumentsImpl(
      name: 'annotation_space_before_parenthesis',
      problemMessage:
          "Annotations can't have spaces or comments before the parenthesis.",
      correctionMessage:
          "Remove any spaces or comments before the parenthesis.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'annotation_space_before_parenthesis',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments annotationWithTypeArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'annotation_with_type_arguments',
      problemMessage: "An annotation can't use type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'annotation_with_type_arguments',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
annotationWithTypeArgumentsUninstantiated = DiagnosticWithoutArgumentsImpl(
  name: 'annotation_with_type_arguments_uninstantiated',
  problemMessage:
      "An annotation with type arguments must be followed by an argument list.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'annotation_with_type_arguments_uninstantiated',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
anonymousMethodWrongParameterList = DiagnosticWithoutArgumentsImpl(
  name: 'anonymous_method_wrong_parameter_list',
  problemMessage:
      "An anonymous method with a parameter list must have exactly one required, "
      "positional parameter.",
  correctionMessage:
      "Try removing the parameter list, or changing it to have exactly one "
      "required positional parameter.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'anonymous_method_wrong_parameter_list',
  expectedTypes: [],
);

/// Parameters:
/// String argumentName: the name of the argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String argumentName})
>
argumentMustBeAConstant = DiagnosticWithArguments(
  name: 'argument_must_be_a_constant',
  problemMessage: "Argument '{0}' must be a constant.",
  correctionMessage: "Try replacing the value with a literal or const.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'argument_must_be_a_constant',
  withArguments: _withArgumentsArgumentMustBeAConstant,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments argumentMustBeNative =
    DiagnosticWithoutArgumentsImpl(
      name: 'argument_must_be_native',
      problemMessage:
          "Argument to 'Native.addressOf' must be annotated with @Native",
      correctionMessage:
          "Try passing a static function or field annotated with '@Native'",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'argument_must_be_native',
      expectedTypes: [],
    );

/// Parameters:
/// Type actualStaticType: the name of the actual argument type
/// Type expectedStaticType: the name of the expected type
/// String additionalInfo: additional information, if any, when problem is
///                        associated with records
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualStaticType,
    required DartType expectedStaticType,
    required String additionalInfo,
  })
>
argumentTypeNotAssignable = DiagnosticWithArguments(
  name: 'argument_type_not_assignable',
  problemMessage:
      "The argument type '{0}' can't be assigned to the parameter type '{1}'. "
      "{2}",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'argument_type_not_assignable',
  withArguments: _withArgumentsArgumentTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type actualType: the name of the actual argument type
/// Type expectedType: the name of the expected function return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
argumentTypeNotAssignableToErrorHandler = DiagnosticWithArguments(
  name: 'argument_type_not_assignable_to_error_handler',
  problemMessage:
      "The argument type '{0}' can't be assigned to the parameter type '{1} "
      "Function(Object)' or '{1} Function(Object, StackTrace)'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'argument_type_not_assignable_to_error_handler',
  withArguments: _withArgumentsArgumentTypeNotAssignableToErrorHandler,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments assertInRedirectingConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'assert_in_redirecting_constructor',
      problemMessage:
          "A redirecting constructor can't have an 'assert' initializer.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'assert_in_redirecting_constructor',
      expectedTypes: [],
    );

/// Parameters:
/// String path: the path to the asset directory as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
assetDirectoryDoesNotExist = DiagnosticWithArguments(
  name: 'asset_directory_does_not_exist',
  problemMessage: "The asset directory '{0}' doesn't exist.",
  correctionMessage:
      "Try creating the directory or fixing the path to the directory.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'asset_directory_does_not_exist',
  withArguments: _withArgumentsAssetDirectoryDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String path: the path to the asset as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
assetDoesNotExist = DiagnosticWithArguments(
  name: 'asset_does_not_exist',
  problemMessage: "The asset file '{0}' doesn't exist.",
  correctionMessage: "Try creating the file or fixing the path to the file.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'asset_does_not_exist',
  withArguments: _withArgumentsAssetDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
assetFieldNotList = DiagnosticWithoutArgumentsImpl(
  name: 'asset_field_not_list',
  problemMessage:
      "The value of the 'assets' field is expected to be a list of relative file "
      "paths.",
  correctionMessage:
      "Try converting the value to be a list of relative file paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'asset_field_not_list',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments assetMissingPath =
    DiagnosticWithoutArgumentsImpl(
      name: 'asset_missing_path',
      problemMessage: "Asset map entry must contain a 'path' field.",
      correctionMessage: "Try adding a 'path' field.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'asset_missing_path',
      expectedTypes: [],
    );

/// This code is deprecated in favor of the
/// 'ASSET_NOT_STRING_OR_MAP' code, and will be removed.
///
/// No parameters.
const DiagnosticWithoutArguments assetNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'asset_not_string',
      problemMessage: "Assets are required to be file paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'asset_not_string',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assetNotStringOrMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'asset_not_string_or_map',
      problemMessage:
          "An asset value is required to be a file path (string) or map.",
      correctionMessage: "Try converting the value to be a string or map.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'asset_not_string_or_map',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assetPathNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'asset_path_not_string',
      problemMessage: "Asset paths are required to be file paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'asset_path_not_string',
      expectedTypes: [],
    );

/// Users should not assign values marked `@doNotStore`.
///
/// Parameters:
/// String name: the name of the field or variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
assignmentOfDoNotStore = DiagnosticWithArguments(
  name: 'assignment_of_do_not_store',
  problemMessage:
      "'{0}' is marked 'doNotStore' and shouldn't be assigned to a field or "
      "top-level variable.",
  correctionMessage: "Try removing the assignment.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'assignment_of_do_not_store',
  withArguments: _withArgumentsAssignmentOfDoNotStore,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
assignmentToConst = DiagnosticWithoutArgumentsImpl(
  name: 'assignment_to_const',
  problemMessage:
      "Constant variables can't be assigned a value after initialization.",
  correctionMessage:
      "Try removing the assignment, or remove the modifier 'const' from the "
      "variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'assignment_to_const',
  expectedTypes: [],
);

/// Parameters:
/// String variableName: the name of the final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String variableName})
>
assignmentToFinal = DiagnosticWithArguments(
  name: 'assignment_to_final',
  problemMessage: "'{0}' can't be used as a setter because it's final.",
  correctionMessage:
      "Try finding a different setter, or making '{0}' non-final.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'assignment_to_final',
  withArguments: _withArgumentsAssignmentToFinal,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String variableName: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String variableName})
>
assignmentToFinalLocal = DiagnosticWithArguments(
  name: 'assignment_to_final_local',
  problemMessage: "The final variable '{0}' can only be set once.",
  correctionMessage: "Try making '{0}' non-final.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'assignment_to_final_local',
  withArguments: _withArgumentsAssignmentToFinalLocal,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String variableName: the name of the reference
/// String className: the name of the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String variableName,
    required String className,
  })
>
assignmentToFinalNoSetter = DiagnosticWithArguments(
  name: 'assignment_to_final_no_setter',
  problemMessage: "There isn't a setter named '{0}' in class '{1}'.",
  correctionMessage:
      "Try correcting the name to reference an existing setter, or declare "
      "the setter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'assignment_to_final_no_setter',
  withArguments: _withArgumentsAssignmentToFinalNoSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments assignmentToFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'assignment_to_function',
      problemMessage: "Functions can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'assignment_to_function',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assignmentToMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'assignment_to_method',
      problemMessage: "Methods can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'assignment_to_method',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments assignmentToType =
    DiagnosticWithoutArgumentsImpl(
      name: 'assignment_to_type',
      problemMessage: "Types can't be assigned a value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'assignment_to_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments asyncForInWrongContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'async_for_in_wrong_context',
      problemMessage:
          "The async for-in loop can only be used in an async function.",
      correctionMessage:
          "Try marking the function body with either 'async' or 'async*', or "
          "removing the 'await' before the for-in loop.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'async_for_in_wrong_context',
      expectedTypes: [],
    );

/// 16.32 Identifier Reference: It is a compile-time error if any of the
/// identifiers async, await, or yield is used as an identifier in a function
/// body marked with either async, async, or sync.
///
/// No parameters.
const DiagnosticWithoutArguments asyncKeywordUsedAsIdentifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'async_keyword_used_as_identifier',
      problemMessage:
          "The keywords 'await' and 'yield' can't be used as identifiers in an "
          "asynchronous or generator function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'async_keyword_used_as_identifier',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentationExtendsClauseAlreadyPresent = DiagnosticWithoutArgumentsImpl(
  name: 'augmentation_extends_clause_already_present',
  problemMessage:
      "The augmentation has an 'extends' clause, but an augmentation target "
      "already includes an 'extends' clause and it isn't allowed to be "
      "repeated or changed.",
  correctionMessage:
      "Try removing the 'extends' clause, either here or in the augmentation "
      "target.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmentation_extends_clause_already_present',
  expectedTypes: [],
);

/// Parameters:
/// String modifier: the lexeme of the modifier.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String modifier})
>
augmentationModifierExtra = DiagnosticWithArguments(
  name: 'augmentation_modifier_extra',
  problemMessage:
      "The augmentation has the '{0}' modifier that the declaration doesn't "
      "have.",
  correctionMessage:
      "Try removing the '{0}' modifier, or adding it to the declaration.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmentation_modifier_extra',
  withArguments: _withArgumentsAugmentationModifierExtra,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String modifier: the lexeme of the modifier.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String modifier})
>
augmentationModifierMissing = DiagnosticWithArguments(
  name: 'augmentation_modifier_missing',
  problemMessage:
      "The augmentation is missing the '{0}' modifier that the declaration has.",
  correctionMessage:
      "Try adding the '{0}' modifier, or removing it from the declaration.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmentation_modifier_missing',
  withArguments: _withArgumentsAugmentationModifierMissing,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String declarationKind: the name of the declaration kind.
/// String augmentationKind: the name of the augmentation kind.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String declarationKind,
    required String augmentationKind,
  })
>
augmentationOfDifferentDeclarationKind = DiagnosticWithArguments(
  name: 'augmentation_of_different_declaration_kind',
  problemMessage: "Can't augment a {0} with a {1}.",
  correctionMessage:
      "Try changing the augmentation to match the declaration kind.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmentation_of_different_declaration_kind',
  withArguments: _withArgumentsAugmentationOfDifferentDeclarationKind,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments augmentationTypeParameterBound =
    DiagnosticWithoutArgumentsImpl(
      name: 'augmentation_type_parameter_bound',
      problemMessage:
          "The augmentation type parameter must have the same bound as the "
          "corresponding type parameter of the declaration.",
      correctionMessage:
          "Try changing the augmentation to match the declaration type "
          "parameters.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'augmentation_type_parameter_bound',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentationTypeParameterCount = DiagnosticWithoutArgumentsImpl(
  name: 'augmentation_type_parameter_count',
  problemMessage:
      "The augmentation must have the same number of type parameters as the "
      "declaration.",
  correctionMessage:
      "Try changing the augmentation to match the declaration type "
      "parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmentation_type_parameter_count',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments augmentationTypeParameterName =
    DiagnosticWithoutArgumentsImpl(
      name: 'augmentation_type_parameter_name',
      problemMessage:
          "The augmentation type parameter must have the same name as the "
          "corresponding type parameter of the declaration.",
      correctionMessage:
          "Try changing the augmentation to match the declaration type "
          "parameters.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'augmentation_type_parameter_name',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments augmentationWithoutDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'augmentation_without_declaration',
      problemMessage: "The declaration being augmented doesn't exist.",
      correctionMessage:
          "Try changing the augmentation to match an existing declaration.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'augmentation_without_declaration',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
augmentedExpressionIsNotSetter = DiagnosticWithoutArgumentsImpl(
  name: 'augmented_expression_is_not_setter',
  problemMessage:
      "The augmented declaration is not a setter, it can't be used to write a "
      "value.",
  correctionMessage: "Try assigning a value to a setter.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmented_expression_is_not_setter',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
augmentedExpressionIsSetter = DiagnosticWithoutArgumentsImpl(
  name: 'augmented_expression_is_setter',
  problemMessage:
      "The augmented declaration is a setter, it can't be used to read a value.",
  correctionMessage: "Try assigning a value to the augmented setter.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmented_expression_is_setter',
  expectedTypes: [],
);

/// Parameters:
/// String operator: the lexeme of the operator.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String operator})
>
augmentedExpressionNotOperator = DiagnosticWithArguments(
  name: 'augmented_expression_not_operator',
  problemMessage:
      "The enclosing augmentation doesn't augment the operator '{0}'.",
  correctionMessage: "Try augmenting or invoking the correct operator.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'augmented_expression_not_operator',
  withArguments: _withArgumentsAugmentedExpressionNotOperator,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments awaitInLateLocalVariableInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'await_in_late_local_variable_initializer',
      problemMessage:
          "The 'await' expression can't be used in a 'late' local variable's "
          "initializer.",
      correctionMessage:
          "Try removing the 'late' modifier, or rewriting the initializer "
          "without using the 'await' expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'await_in_late_local_variable_initializer',
      expectedTypes: [],
    );

/// 16.30 Await Expressions: It is a compile-time error if the function
/// immediately enclosing _a_ is not declared asynchronous. (Where _a_ is the
/// await expression.)
///
/// No parameters.
const DiagnosticWithoutArguments awaitInWrongContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'await_in_wrong_context',
      problemMessage:
          "The await expression can only be used in an async function.",
      correctionMessage:
          "Try marking the function body with either 'async' or 'async*'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'await_in_wrong_context',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
awaitOfIncompatibleType = DiagnosticWithoutArgumentsImpl(
  name: 'await_of_incompatible_type',
  problemMessage:
      "The 'await' expression can't be used for an expression with an extension "
      "type that is not a subtype of 'Future'.",
  correctionMessage:
      "Try removing the `await`, or updating the extension type to implement "
      "'Future'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'await_of_incompatible_type',
  expectedTypes: [],
);

/// Parameters:
/// String implementedClassName: the name of the base class being implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String implementedClassName})
>
baseClassImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be implemented outside of its library because it's "
      "a base class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'base_class_implemented_outside_of_library',
  withArguments: _withArgumentsBaseClassImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments baseEnum = DiagnosticWithoutArgumentsImpl(
  name: 'base_enum',
  problemMessage: "Enums can't be declared to be 'base'.",
  correctionMessage: "Try removing the keyword 'base'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'base_enum',
  expectedTypes: [],
);

/// Parameters:
/// String implementedMixinName: the name of the base mixin being implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String implementedMixinName})
>
baseMixinImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The mixin '{0}' can't be implemented outside of its library because it's "
      "a base mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'base_mixin_implemented_outside_of_library',
  withArguments: _withArgumentsBaseMixinImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String actualOperator: The binary operator that was seen.
/// String expectedOperator: The binary operator that was expected.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String actualOperator,
    required String expectedOperator,
  })
>
binaryOperatorWrittenOut = DiagnosticWithArguments(
  name: 'binary_operator_written_out',
  problemMessage:
      "Binary operator '{0}' is written as '{1}' instead of the written out "
      "word.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'binary_operator_written_out',
  withArguments: _withArgumentsBinaryOperatorWrittenOut,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type returnType: the name of the return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType returnType})
>
bodyMightCompleteNormally = DiagnosticWithArguments(
  name: 'body_might_complete_normally',
  problemMessage:
      "The body might complete normally, causing 'null' to be returned, but the "
      "return type, '{0}', is a potentially non-nullable type.",
  correctionMessage:
      "Try adding either a return or a throw statement at the end.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'body_might_complete_normally',
  withArguments: _withArgumentsBodyMightCompleteNormally,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type type: the return type as derived by the type of the [Future].
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
bodyMightCompleteNormallyCatchError = DiagnosticWithArguments(
  name: 'body_might_complete_normally_catch_error',
  problemMessage:
      "This 'onError' handler must return a value assignable to '{0}', but ends "
      "without returning a value.",
  correctionMessage: "Try adding a return statement.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'body_might_complete_normally_catch_error',
  withArguments: _withArgumentsBodyMightCompleteNormallyCatchError,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type returnType: the name of the declared return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType returnType})
>
bodyMightCompleteNormallyNullable = DiagnosticWithArguments(
  name: 'body_might_complete_normally_nullable',
  problemMessage:
      "This function has a nullable return type of '{0}', but ends without "
      "returning a value.",
  correctionMessage:
      "Try adding a return statement, or if no value is ever returned, try "
      "changing the return type to 'void'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'body_might_complete_normally_nullable',
  withArguments: _withArgumentsBodyMightCompleteNormallyNullable,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments breakLabelOnSwitchMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'break_label_on_switch_member',
      problemMessage:
          "A break label resolves to the 'case' or 'default' statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'break_label_on_switch_member',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
breakOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
  name: 'break_outside_of_loop',
  problemMessage:
      "A break statement can't be used outside of a loop or switch statement.",
  correctionMessage: "Try removing the break statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'break_outside_of_loop',
  expectedTypes: [],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsExtensionName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage:
      "The built-in identifier '{0}' can't be used as an extension name.",
  correctionMessage: "Try choosing a different name for the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_extension_name',
  withArguments: _withArgumentsBuiltInIdentifierAsExtensionName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsExtensionTypeName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage:
      "The built-in identifier '{0}' can't be used as an extension type name.",
  correctionMessage: "Try choosing a different name for the extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_extension_type_name',
  withArguments: _withArgumentsBuiltInIdentifierAsExtensionTypeName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsPrefixName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a prefix name.",
  correctionMessage: "Try choosing a different name for the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_prefix_name',
  withArguments: _withArgumentsBuiltInIdentifierAsPrefixName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String token: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String token})
>
builtInIdentifierAsType = DiagnosticWithArguments(
  name: 'built_in_identifier_as_type',
  problemMessage: "The built-in identifier '{0}' can't be used as a type.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_type',
  withArguments: _withArgumentsBuiltInIdentifierAsType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsTypedefName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a typedef name.",
  correctionMessage: "Try choosing a different name for the typedef.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_typedef_name',
  withArguments: _withArgumentsBuiltInIdentifierAsTypedefName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsTypeName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage: "The built-in identifier '{0}' can't be used as a type name.",
  correctionMessage: "Try choosing a different name for the type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_type_name',
  withArguments: _withArgumentsBuiltInIdentifierAsTypeName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the built-in identifier that is being used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
builtInIdentifierAsTypeParameterName = DiagnosticWithArguments(
  name: 'built_in_identifier_in_declaration',
  problemMessage:
      "The built-in identifier '{0}' can't be used as a type parameter name.",
  correctionMessage: "Try choosing a different name for the type parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'built_in_identifier_as_type_parameter_name',
  withArguments: _withArgumentsBuiltInIdentifierAsTypeParameterName,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that the camera permissions is not supported on Chrome
/// OS.
///
/// No parameters.
const DiagnosticWithoutArguments
cameraPermissionsIncompatible = DiagnosticWithoutArgumentsImpl(
  name: 'camera_permissions_incompatible',
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
  uniqueName: 'camera_permissions_incompatible',
  expectedTypes: [],
);

/// Parameters:
/// Type type: the type of the switch case expression
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
caseExpressionTypeImplementsEquals = DiagnosticWithArguments(
  name: 'case_expression_type_implements_equals',
  problemMessage:
      "The switch case expression type '{0}' can't override the '==' operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'case_expression_type_implements_equals',
  withArguments: _withArgumentsCaseExpressionTypeImplementsEquals,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type caseExpressionType: the type of the case expression
/// Type scrutineeType: the type of the switch expression
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType caseExpressionType,
    required DartType scrutineeType,
  })
>
caseExpressionTypeIsNotSwitchExpressionSubtype = DiagnosticWithArguments(
  name: 'case_expression_type_is_not_switch_expression_subtype',
  problemMessage:
      "The switch case expression type '{0}' must be a subtype of the switch "
      "expression type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'case_expression_type_is_not_switch_expression_subtype',
  withArguments: _withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String name: the name of the unassigned variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
castFromNullableAlwaysFails = DiagnosticWithArguments(
  name: 'cast_from_nullable_always_fails',
  problemMessage:
      "This cast will always throw an exception because the nullable local "
      "variable '{0}' is not assigned.",
  correctionMessage:
      "Try giving it an initializer expression, or ensure that it's assigned "
      "on every execution path.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'cast_from_nullable_always_fails',
  withArguments: _withArgumentsCastFromNullableAlwaysFails,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments castFromNullAlwaysFails =
    DiagnosticWithoutArgumentsImpl(
      name: 'cast_from_null_always_fails',
      problemMessage:
          "This cast always throws an exception because the expression always "
          "evaluates to 'null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'cast_from_null_always_fails',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
castToNonType = DiagnosticWithArguments(
  name: 'cast_to_non_type',
  problemMessage:
      "The name '{0}' isn't a type, so it can't be used in an 'as' expression.",
  correctionMessage:
      "Try changing the name to the name of an existing type, or creating a "
      "type with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'cast_to_non_type',
  withArguments: _withArgumentsCastToNonType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments catchSyntax = DiagnosticWithoutArgumentsImpl(
  name: 'catch_syntax',
  problemMessage:
      "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
  correctionMessage:
      "No types are needed, the first is given by 'on', the second is always "
      "'StackTrace'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'catch_syntax',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
catchSyntaxExtraParameters = DiagnosticWithoutArgumentsImpl(
  name: 'catch_syntax_extra_parameters',
  problemMessage:
      "'catch' must be followed by '(identifier)' or '(identifier, identifier)'.",
  correctionMessage:
      "No types are needed, the first is given by 'on', the second is always "
      "'StackTrace'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'catch_syntax_extra_parameters',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments classInClass = DiagnosticWithoutArgumentsImpl(
  name: 'class_in_class',
  problemMessage: "Classes can't be declared inside other classes.",
  correctionMessage: "Try moving the class to the top-level.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'class_in_class',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
classInstantiationAccessToInstanceMember = DiagnosticWithArguments(
  name: 'class_instantiation_access_to_member',
  problemMessage:
      "The instance member '{0}' can't be accessed on a class instantiation.",
  correctionMessage:
      "Try changing the member name to the name of a constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'class_instantiation_access_to_instance_member',
  withArguments: _withArgumentsClassInstantiationAccessToInstanceMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
classInstantiationAccessToStaticMember = DiagnosticWithArguments(
  name: 'class_instantiation_access_to_member',
  problemMessage:
      "The static member '{0}' can't be accessed on a class instantiation.",
  correctionMessage:
      "Try removing the type arguments from the class name, or changing the "
      "member name to the name of a constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'class_instantiation_access_to_static_member',
  withArguments: _withArgumentsClassInstantiationAccessToStaticMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String className: the name of the class
/// String memberName: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String memberName,
  })
>
classInstantiationAccessToUnknownMember = DiagnosticWithArguments(
  name: 'class_instantiation_access_to_member',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try invoking a different constructor, or defining a constructor named "
      "'{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'class_instantiation_access_to_unknown_member',
  withArguments: _withArgumentsClassInstantiationAccessToUnknownMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the class being used as a mixin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
classUsedAsMixin = DiagnosticWithArguments(
  name: 'class_used_as_mixin',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it's neither a mixin "
      "class nor a mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'class_used_as_mixin',
  withArguments: _withArgumentsClassUsedAsMixin,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments colonInPlaceOfIn =
    DiagnosticWithoutArgumentsImpl(
      name: 'colon_in_place_of_in',
      problemMessage: "For-in loops use 'in' rather than a colon.",
      correctionMessage: "Try replacing the colon with the keyword 'in'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'colon_in_place_of_in',
      expectedTypes: [],
    );

/// Parameters:
/// String className: the name of the struct or union class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
compoundImplementsFinalizable = DiagnosticWithArguments(
  name: 'compound_implements_finalizable',
  problemMessage: "The class '{0}' can't implement Finalizable.",
  correctionMessage: "Try removing the implements clause from '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'compound_implements_finalizable',
  withArguments: _withArgumentsCompoundImplementsFinalizable,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments concreteClassHasEnumSuperinterface =
    DiagnosticWithoutArgumentsImpl(
      name: 'concrete_class_has_enum_superinterface',
      problemMessage: "Concrete classes can't have 'Enum' as a superinterface.",
      correctionMessage:
          "Try specifying a different interface, or remove it from the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'concrete_class_has_enum_superinterface',
      expectedTypes: [],
    );

/// Parameters:
/// String methodName: the name of the abstract method
/// String enclosingClass: the name of the enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String enclosingClass,
  })
>
concreteClassWithAbstractMember = DiagnosticWithArguments(
  name: 'concrete_class_with_abstract_member',
  problemMessage: "'{0}' must have a method body because '{1}' isn't abstract.",
  correctionMessage: "Try making '{1}' abstract, or adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'concrete_class_with_abstract_member',
  withArguments: _withArgumentsConcreteClassWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the constructor and field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
conflictingConstructorAndStaticField = DiagnosticWithArguments(
  name: 'conflicting_constructor_and_static_member',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static field in this "
      "class.",
  correctionMessage: "Try renaming either the constructor or the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_constructor_and_static_field',
  withArguments: _withArgumentsConflictingConstructorAndStaticField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the constructor and getter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
conflictingConstructorAndStaticGetter = DiagnosticWithArguments(
  name: 'conflicting_constructor_and_static_member',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static getter in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the getter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_constructor_and_static_getter',
  withArguments: _withArgumentsConflictingConstructorAndStaticGetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
conflictingConstructorAndStaticMethod = DiagnosticWithArguments(
  name: 'conflicting_constructor_and_static_member',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static method in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the method.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_constructor_and_static_method',
  withArguments: _withArgumentsConflictingConstructorAndStaticMethod,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the constructor and setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
conflictingConstructorAndStaticSetter = DiagnosticWithArguments(
  name: 'conflicting_constructor_and_static_member',
  problemMessage:
      "'{0}' can't be used to name both a constructor and a static setter in "
      "this class.",
  correctionMessage: "Try renaming either the constructor or the setter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_constructor_and_static_setter',
  withArguments: _withArgumentsConflictingConstructorAndStaticSetter,
  expectedTypes: [ExpectedType.string],
);

/// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
/// error if `C` declares a getter or a setter with basename `n`, and has a
/// method named `n`.
///
/// Parameters:
/// String className: the name of the class defining the conflicting field
/// String fieldName: the name of the conflicting field
/// String conflictingClassName: the name of the class defining the method
///                              with which the field conflicts
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String fieldName,
    required String conflictingClassName,
  })
>
conflictingFieldAndMethod = DiagnosticWithArguments(
  name: 'conflicting_field_and_method',
  problemMessage:
      "Class '{0}' can't define field '{1}' and have method '{2}.{1}' with the "
      "same name.",
  correctionMessage:
      "Try converting the getter to a method, or renaming the field to a "
      "name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_field_and_method',
  withArguments: _withArgumentsConflictingFieldAndMethod,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String kind: the name of the kind of the element implementing the
///              conflicting interface
/// String element: the name of the element implementing the conflicting
///                 interface
/// String type1: the first conflicting type
/// String type2: the second conflicting type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String kind,
    required String element,
    required String type1,
    required String type2,
  })
>
conflictingGenericInterfaces = DiagnosticWithArguments(
  name: 'conflicting_generic_interfaces',
  problemMessage:
      "The {0} '{1}' can't implement both '{2}' and '{3}' because the type "
      "arguments are different.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_generic_interfaces',
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
/// String enclosingElementKind: the name of the enclosing element kind -
///                              class, extension type, etc
/// String enclosingElementName: the name of the enclosing element
/// String memberName: the name of the conflicting method / setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String enclosingElementKind,
    required String enclosingElementName,
    required String memberName,
  })
>
conflictingInheritedMethodAndSetter = DiagnosticWithArguments(
  name: 'conflicting_inherited_method_and_setter',
  problemMessage:
      "The {0} '{1}' can't inherit both a method and a setter named '{2}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_inherited_method_and_setter',
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
/// String className: the name of the class defining the conflicting method
/// String methodName: the name of the conflicting method
/// String conflictingClassName: the name of the class defining the field with
///                              which the method conflicts
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String methodName,
    required String conflictingClassName,
  })
>
conflictingMethodAndField = DiagnosticWithArguments(
  name: 'conflicting_method_and_field',
  problemMessage:
      "Class '{0}' can't define method '{1}' and have field '{2}.{1}' with the "
      "same name.",
  correctionMessage:
      "Try converting the method to a getter, or renaming the method to a "
      "name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_method_and_field',
  withArguments: _withArgumentsConflictingMethodAndField,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String modifier: The problematic modifier.
/// String earlierModifier: The earlier modifier that conflicts.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String modifier,
    required String earlierModifier,
  })
>
conflictingModifiers = DiagnosticWithArguments(
  name: 'conflicting_modifiers',
  problemMessage: "Members can't be declared to be both '{0}' and '{1}'.",
  correctionMessage: "Try removing one of the keywords.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'conflicting_modifiers',
  withArguments: _withArgumentsConflictingModifiers,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 10.11 Class Member Conflicts: Let `C` be a class. It is a compile-time
/// error if `C` declares a static member with basename `n`, and has an
/// instance member with basename `n`.
///
/// Parameters:
/// String className: the name of the class defining the conflicting member
/// String memberName: the name of the conflicting static member
/// String conflictingClassName: the name of the class defining the field with
///                              which the method conflicts
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String memberName,
    required String conflictingClassName,
  })
>
conflictingStaticAndInstance = DiagnosticWithArguments(
  name: 'conflicting_static_and_instance',
  problemMessage:
      "Class '{0}' can't define static member '{1}' and have instance member "
      "'{2}.{1}' with the same name.",
  correctionMessage: "Try renaming the member to a name that doesn't conflict.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_static_and_instance',
  withArguments: _withArgumentsConflictingStaticAndInstance,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndClass = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_container',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the class in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_class',
  withArguments: _withArgumentsConflictingTypeVariableAndClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndEnum = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_container',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the enum in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the enum.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_enum',
  withArguments: _withArgumentsConflictingTypeVariableAndEnum,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndExtension = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_container',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the extension in "
      "which the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_extension',
  withArguments: _withArgumentsConflictingTypeVariableAndExtension,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndExtensionType = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_container',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the extension type "
      "in which the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_extension_type',
  withArguments: _withArgumentsConflictingTypeVariableAndExtensionType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMemberClass = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_member',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "class.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_member_class',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMemberEnum = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_member',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "enum.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_member_enum',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberEnum,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMemberExtension = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_member',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "extension.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_member_extension',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberExtension,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMemberExtensionType = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_member',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "extension type.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_member_extension_type',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberExtensionType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMemberMixin = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_member',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and a member in this "
      "mixin.",
  correctionMessage: "Try renaming either the type parameter or the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_member_mixin',
  withArguments: _withArgumentsConflictingTypeVariableAndMemberMixin,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameterName})
>
conflictingTypeVariableAndMixin = DiagnosticWithArguments(
  name: 'conflicting_type_variable_and_container',
  problemMessage:
      "'{0}' can't be used to name both a type parameter and the mixin in which "
      "the type parameter is defined.",
  correctionMessage: "Try renaming either the type parameter or the mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_type_variable_and_mixin',
  withArguments: _withArgumentsConflictingTypeVariableAndMixin,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constAndFinal = DiagnosticWithoutArgumentsImpl(
  name: 'const_and_final',
  problemMessage: "Members can't be declared to be both 'const' and 'final'.",
  correctionMessage: "Try removing either the 'const' or 'final' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'const_and_final',
  expectedTypes: [],
);

/// Parameters:
/// Type matchedType: the matched value type
/// Type constantType: the constant value type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType matchedType,
    required DartType constantType,
  })
>
constantPatternNeverMatchesValueType = DiagnosticWithArguments(
  name: 'constant_pattern_never_matches_value_type',
  problemMessage:
      "The matched value type '{0}' can never be equal to this constant of type "
      "'{1}'.",
  correctionMessage:
      "Try a constant of the same type as the matched value type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'constant_pattern_never_matches_value_type',
  withArguments: _withArgumentsConstantPatternNeverMatchesValueType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constantPatternWithNonConstantExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'constant_pattern_with_non_constant_expression',
      problemMessage:
          "The expression of a constant pattern must be a valid constant.",
      correctionMessage: "Try making the expression a valid constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'constant_pattern_with_non_constant_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constClass = DiagnosticWithoutArgumentsImpl(
  name: 'const_class',
  problemMessage: "Classes can't be declared to be 'const'.",
  correctionMessage:
      "Try removing the 'const' keyword. If you're trying to indicate that "
      "instances of the class can be constants, place the 'const' keyword on "
      " the class' constructor(s).",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'const_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
constConstructorConstantFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'collection_element_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' constructor.",
  correctionMessage:
      "Try removing the keyword 'const' from the constructor or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_constant_from_deferred_library',
  expectedTypes: [],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// Parameters:
/// String valueType: the type of the runtime value of the argument
/// String fieldName: the name of the field
/// String fieldType: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String valueType,
    required String fieldName,
    required String fieldType,
  })
>
constConstructorFieldTypeMismatch = DiagnosticWithArguments(
  name: 'const_constructor_field_type_mismatch',
  problemMessage:
      "In a const constructor, a value of type '{0}' can't be assigned to the "
      "field '{1}', which has type '{2}'.",
  correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_field_type_mismatch',
  withArguments: _withArgumentsConstConstructorFieldTypeMismatch,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
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
  name: 'const_constructor_param_type_mismatch',
  problemMessage:
      "A value of type '{0}' can't be assigned to a parameter of type '{1}' in a "
      "const constructor.",
  correctionMessage: "Try using a subtype, or removing the keyword 'const'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_param_type_mismatch',
  withArguments: _withArgumentsConstConstructorParamTypeMismatch,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constConstructorThrowsException =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_constructor_throws_exception',
      problemMessage: "Const constructors can't throw exceptions.",
      correctionMessage:
          "Try removing the throw statement, or removing the keyword 'const'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_constructor_throws_exception',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constConstructorWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_constructor_with_body',
      problemMessage: "Const constructors can't have a body.",
      correctionMessage: "Try removing either the 'const' keyword or the body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'const_constructor_with_body',
      expectedTypes: [],
    );

/// Parameters:
/// String fieldName: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldName})
>
constConstructorWithFieldInitializedByNonConst = DiagnosticWithArguments(
  name: 'const_constructor_with_field_initialized_by_non_const',
  problemMessage:
      "Can't define the 'const' constructor because the field '{0}' is "
      "initialized with a non-constant value.",
  correctionMessage:
      "Try initializing the field to a constant value, or removing the "
      "keyword 'const' from the constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_with_field_initialized_by_non_const',
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
/// String fieldName: the name of the instance field.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldName})
>
constConstructorWithMixinWithField = DiagnosticWithArguments(
  name: 'const_constructor_with_mixin_with_field',
  problemMessage:
      "This constructor can't be declared 'const' because a mixin adds the "
      "instance field: {0}.",
  correctionMessage:
      "Try removing the 'const' keyword or removing the 'with' clause from "
      "the class declaration, or removing the field from the mixin class.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_with_mixin_with_field',
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
/// String fieldNames: the names of the instance fields.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldNames})
>
constConstructorWithMixinWithFields = DiagnosticWithArguments(
  name: 'const_constructor_with_mixin_with_field',
  problemMessage:
      "This constructor can't be declared 'const' because the mixins add the "
      "instance fields: {0}.",
  correctionMessage:
      "Try removing the 'const' keyword or removing the 'with' clause from "
      "the class declaration, or removing the fields from the mixin classes.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_with_mixin_with_fields',
  withArguments: _withArgumentsConstConstructorWithMixinWithFields,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String superclassName: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String superclassName})
>
constConstructorWithNonConstSuper = DiagnosticWithArguments(
  name: 'const_constructor_with_non_const_super',
  problemMessage:
      "A constant constructor can't call a non-constant super constructor of "
      "'{0}'.",
  correctionMessage:
      "Try calling a constant constructor in the superclass, or removing the "
      "keyword 'const' from the constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_constructor_with_non_const_super',
  withArguments: _withArgumentsConstConstructorWithNonConstSuper,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constConstructorWithNonFinalField =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_constructor_with_non_final_field',
      problemMessage:
          "Can't define a const constructor for a class with non-final fields.",
      correctionMessage:
          "Try making all of the fields final, or removing the keyword 'const' "
          "from the constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_constructor_with_non_final_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
constDeferredClass = DiagnosticWithoutArgumentsImpl(
  name: 'const_deferred_class',
  problemMessage: "Deferred classes can't be created with 'const'.",
  correctionMessage:
      "Try using 'new' to create the instance, or changing the import to not "
      "be deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_deferred_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalAssertionFailure =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_assertion_failure',
      problemMessage: "The assertion in this constant expression failed.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_assertion_failure',
      expectedTypes: [],
    );

/// Parameters:
/// String message: the message of the assertion
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
constEvalAssertionFailureWithMessage = DiagnosticWithArguments(
  name: 'const_eval_assertion_failure_with_message',
  problemMessage: "An assertion failed with message '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_assertion_failure_with_message',
  withArguments: _withArgumentsConstEvalAssertionFailureWithMessage,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalExtensionMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_extension_method',
      problemMessage:
          "Extension methods can't be used in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_extension_method',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalExtensionTypeMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_extension_type_method',
      problemMessage:
          "Extension type methods can't be used in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_extension_type_method',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalForElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_for_element',
      problemMessage: "Constant expressions don't support 'for' elements.",
      correctionMessage:
          "Try replacing the 'for' element with a spread, or removing 'const'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_for_element',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalMethodInvocation =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_method_invocation',
      problemMessage: "Methods can't be invoked in constant expressions.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_method_invocation',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 == e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalPrimitiveEquality = DiagnosticWithoutArgumentsImpl(
  name: 'const_eval_primitive_equality',
  problemMessage:
      "In constant expressions, operands of the equality operator must have "
      "primitive equality.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_primitive_equality',
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
  name: 'const_eval_property_access',
  problemMessage:
      "The property '{0}' can't be accessed on the type '{1}' in a constant "
      "expression.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_property_access',
  withArguments: _withArgumentsConstEvalPropertyAccess,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constEvalThrowsException =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_throws_exception',
      problemMessage:
          "Evaluation of this constant expression throws an exception.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_throws_exception',
      expectedTypes: [],
    );

/// 16.12.2 Const: It is a compile-time error if evaluation of a constant
/// object results in an uncaught exception being thrown.
///
/// No parameters.
const DiagnosticWithoutArguments constEvalThrowsIdbze =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_throws_idbze',
      problemMessage:
          "Evaluation of this constant expression throws an "
          "IntegerDivisionByZeroException.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_throws_idbze',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form !e1", "An expression of the form
/// e1 && e2", and "An expression of the form e1 || e2".
///
/// No parameters.
const DiagnosticWithoutArguments constEvalTypeBool =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_type_bool',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'bool'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_type_bool',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 & e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeBoolInt = DiagnosticWithoutArgumentsImpl(
  name: 'const_eval_type_bool_int',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'bool' "
      "or 'int'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_type_bool_int',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "A literal string".
///
/// No parameters.
const DiagnosticWithoutArguments constEvalTypeBoolNumString =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_type_bool_num_string',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'bool', 'num', 'String' or 'null'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_type_bool_num_string',
      expectedTypes: [],
    );

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form ~e1", "An expression of one of
/// the forms e1 >> e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeInt = DiagnosticWithoutArgumentsImpl(
  name: 'const_eval_type_int',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'int'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_type_int',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 - e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeNum = DiagnosticWithoutArgumentsImpl(
  name: 'const_eval_type_num',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'num'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_type_num',
  expectedTypes: [],
);

/// See https://spec.dart.dev/DartLangSpecDraft.pdf#constants, "Constants",
/// for text about "An expression of the form e1 + e2".
///
/// No parameters.
const DiagnosticWithoutArguments
constEvalTypeNumString = DiagnosticWithoutArgumentsImpl(
  name: 'const_eval_type_num_string',
  problemMessage:
      "In constant expressions, operands of this operator must be of type 'num' "
      "or 'String'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_eval_type_num_string',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constEvalTypeString =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_type_string',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'String'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_type_string',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constEvalTypeType =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_eval_type_type',
      problemMessage:
          "In constant expressions, operands of this operator must be of type "
          "'Type'.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_eval_type_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constFactory = DiagnosticWithoutArgumentsImpl(
  name: 'const_factory',
  problemMessage:
      "Only redirecting factory constructors can be declared to be 'const'.",
  correctionMessage:
      "Try removing the 'const' keyword, or replacing the body with '=' "
      "followed by a valid target.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'const_factory',
  expectedTypes: [],
);

/// Parameters:
/// Type initializerExpressionType: the name of the type of the initializer
///                                 expression
/// Type fieldType: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType initializerExpressionType,
    required DartType fieldType,
  })
>
constFieldInitializerNotAssignable = DiagnosticWithArguments(
  name: 'field_initializer_not_assignable',
  problemMessage:
      "The initializer type '{0}' can't be assigned to the field type '{1}' in a "
      "const constructor.",
  correctionMessage: "Try using a subtype, or removing the 'const' keyword",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_field_initializer_not_assignable',
  withArguments: _withArgumentsConstFieldInitializerNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constInitializedWithNonConstantValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_initialized_with_non_constant_value',
      problemMessage:
          "Const variables must be initialized with a constant value.",
      correctionMessage:
          "Try changing the initializer to be a constant expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_initialized_with_non_constant_value',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
constInitializedWithNonConstantValueFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_initialized_with_non_constant_value_from_deferred_library',
      problemMessage:
          "Constant values from a deferred library can't be used to initialize a "
          "'const' variable.",
      correctionMessage:
          "Try initializing the variable without referencing members of the "
          "deferred library, or changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'const_initialized_with_non_constant_value_from_deferred_library',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_instance_field',
      problemMessage: "Only static fields can be declared as const.",
      correctionMessage:
          "Try declaring the field as final, or adding the keyword 'static'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_instance_field',
      expectedTypes: [],
    );

/// Parameters:
/// Type keyType: the type of the entry's key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType keyType})
>
constMapKeyNotPrimitiveEquality = DiagnosticWithArguments(
  name: 'const_map_key_not_primitive_equality',
  problemMessage:
      "The type of a key in a constant map can't override the '==' operator, or "
      "'hashCode', but the class '{0}' does.",
  correctionMessage:
      "Try using a different value for the key, or removing the keyword "
      "'const' from the map.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_map_key_not_primitive_equality',
  withArguments: _withArgumentsConstMapKeyNotPrimitiveEquality,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constMethod = DiagnosticWithoutArgumentsImpl(
  name: 'const_method',
  problemMessage:
      "Getters, setters and methods can't be declared to be 'const'.",
  correctionMessage: "Try removing the 'const' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'const_method',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
constNotInitialized = DiagnosticWithArguments(
  name: 'const_not_initialized',
  problemMessage: "The constant '{0}' must be initialized.",
  correctionMessage: "Try adding an initialization to the declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_not_initialized',
  withArguments: _withArgumentsConstNotInitialized,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments constructorWithReturnType =
    DiagnosticWithoutArgumentsImpl(
      name: 'constructor_with_return_type',
      problemMessage: "Constructors can't have a return type.",
      correctionMessage: "Try removing the return type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'constructor_with_return_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
constructorWithTypeArguments = DiagnosticWithoutArgumentsImpl(
  name: 'constructor_with_type_arguments',
  problemMessage:
      "A constructor invocation can't have type arguments after the constructor "
      "name.",
  correctionMessage:
      "Try removing the type arguments or placing them after the class name.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'constructor_with_type_arguments',
  expectedTypes: [],
);

/// Parameters:
/// Type type: the type of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
constSetElementNotPrimitiveEquality = DiagnosticWithArguments(
  name: 'const_set_element_not_primitive_equality',
  problemMessage:
      "An element in a constant set can't override the '==' operator, or "
      "'hashCode', but the type '{0}' does.",
  correctionMessage:
      "Try using a different value for the element, or removing the keyword "
      "'const' from the set.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_set_element_not_primitive_equality',
  withArguments: _withArgumentsConstSetElementNotPrimitiveEquality,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments constSpreadExpectedListOrSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_spread_expected_list_or_set',
      problemMessage: "A list or a set is expected in this spread.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_spread_expected_list_or_set',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constSpreadExpectedMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_spread_expected_map',
      problemMessage: "A map is expected in this spread.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_spread_expected_map',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_type_parameter',
      problemMessage: "Type parameters can't be used in a constant expression.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_type_parameter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithNonConst =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_with_non_const',
      problemMessage: "The constructor being called isn't a const constructor.",
      correctionMessage:
          "Try removing 'const' from the constructor invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_with_non_const',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithNonConstantArgument =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_with_non_constant_argument',
      problemMessage:
          "Arguments of a constant creation must be constant expressions.",
      correctionMessage:
          "Try making the argument a valid constant, or use 'new' to call the "
          "constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_with_non_constant_argument',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
constWithNonType = DiagnosticWithArguments(
  name: 'creation_with_non_type',
  problemMessage: "The name '{0}' isn't a class.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_with_non_type',
  withArguments: _withArgumentsConstWithNonType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
constWithoutPrimaryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'const_without_primary_constructor',
  problemMessage:
      "'const' can only be used together with a primary constructor declaration.",
  correctionMessage:
      "Try removing the 'const' keyword or adding a primary constructor "
      "declaration.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'const_without_primary_constructor',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_with_type_parameters',
      problemMessage:
          "A constant creation can't use a type parameter as a type argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_with_type_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParametersConstructorTearoff =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_with_type_parameters',
      problemMessage:
          "A constant constructor tearoff can't use a type parameter as a type "
          "argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_with_type_parameters_constructor_tearoff',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments constWithTypeParametersFunctionTearoff =
    DiagnosticWithoutArgumentsImpl(
      name: 'const_with_type_parameters',
      problemMessage:
          "A constant function tearoff can't use a type parameter as a type "
          "argument.",
      correctionMessage:
          "Try replacing the type parameter with a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'const_with_type_parameters_function_tearoff',
      expectedTypes: [],
    );

/// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
/// a constant constructor declared by the type <i>T</i>.
///
/// Parameters:
/// String className: the name of the type
/// String constructorName: the name of the requested constant constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String constructorName,
  })
>
constWithUndefinedConstructor = DiagnosticWithArguments(
  name: 'const_with_undefined_constructor',
  problemMessage: "The class '{0}' doesn't have a constant constructor '{1}'.",
  correctionMessage: "Try calling a different constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_with_undefined_constructor',
  withArguments: _withArgumentsConstWithUndefinedConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// 16.12.2 Const: It is a compile-time error if <i>T.id</i> is not the name of
/// a constant constructor declared by the type <i>T</i>.
///
/// Parameters:
/// String className: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
constWithUndefinedConstructorDefault = DiagnosticWithArguments(
  name: 'const_with_undefined_constructor_default',
  problemMessage:
      "The class '{0}' doesn't have an unnamed constant constructor.",
  correctionMessage: "Try calling a different constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'const_with_undefined_constructor_default',
  withArguments: _withArgumentsConstWithUndefinedConstructorDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
continueLabelInvalid = DiagnosticWithoutArgumentsImpl(
  name: 'continue_label_invalid',
  problemMessage:
      "The label used in a 'continue' statement must be defined on either a loop "
      "or a switch member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'continue_label_invalid',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
continueOutsideOfLoop = DiagnosticWithoutArgumentsImpl(
  name: 'continue_outside_of_loop',
  problemMessage:
      "A continue statement can't be used outside of a loop or switch statement.",
  correctionMessage: "Try removing the continue statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'continue_outside_of_loop',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
continueWithoutLabelInCase = DiagnosticWithoutArgumentsImpl(
  name: 'continue_without_label_in_case',
  problemMessage:
      "A continue statement in a switch statement must have a label as a target.",
  correctionMessage:
      "Try adding a label associated with one of the case clauses to the "
      "continue statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'continue_without_label_in_case',
  expectedTypes: [],
);

/// Parameters:
/// String typeParameterName: the name of the type parameter
/// String detailText: detail text explaining why the type could not be
///                    inferred
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String typeParameterName,
    required String detailText,
  })
>
couldNotInfer = DiagnosticWithArguments(
  name: 'could_not_infer',
  problemMessage: "Couldn't infer type parameter '{0}'.{1}",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'could_not_infer',
  withArguments: _withArgumentsCouldNotInfer,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments covariantAndStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'covariant_and_static',
      problemMessage:
          "Members can't be declared to be both 'covariant' and 'static'.",
      correctionMessage:
          "Try removing either the 'covariant' or 'static' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'covariant_and_static',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments covariantConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'covariant_constructor',
      problemMessage: "A constructor can't be declared to be 'covariant'.",
      correctionMessage: "Try removing the keyword 'covariant'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'covariant_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments covariantMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'covariant_member',
      problemMessage:
          "Getters, setters and methods can't be declared to be 'covariant'.",
      correctionMessage: "Try removing the 'covariant' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'covariant_member',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
creationOfStructOrUnion = DiagnosticWithoutArgumentsImpl(
  name: 'creation_of_struct_or_union',
  problemMessage:
      "Subclasses of 'Struct' and 'Union' are backed by native memory, and can't "
      "be instantiated by a generative constructor.",
  correctionMessage:
      "Try allocating it via allocation, or load from a 'Pointer'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'creation_of_struct_or_union',
  expectedTypes: [],
);

/// Dead code is code that is never reached, this can happen for instance if a
/// statement follows a return statement.
///
/// No parameters.
const DiagnosticWithoutArguments deadCode = DiagnosticWithoutArgumentsImpl(
  name: 'dead_code',
  problemMessage: "Dead code.",
  correctionMessage:
      "Try removing the code, or fixing the code before it so that it can be "
      "reached.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dead_code',
  expectedTypes: [],
);

/// Dead code is code that is never reached. This case covers cases where the
/// user has catch clauses after `catch (e)` or `on Object catch (e)`.
///
/// No parameters.
const DiagnosticWithoutArguments
deadCodeCatchFollowingCatch = DiagnosticWithoutArgumentsImpl(
  name: 'dead_code_catch_following_catch',
  problemMessage:
      "Dead code: Catch clauses after a 'catch (e)' or an 'on Object catch (e)' "
      "are never reached.",
  correctionMessage:
      "Try reordering the catch clauses so that they can be reached, or "
      "removing the unreachable catch clauses.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dead_code_catch_following_catch',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
deadCodeLateWildcardVariableInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'dead_code',
  problemMessage:
      "Dead code: The assigned-to wildcard variable is marked late and can never "
      "be referenced so this initializer will never be evaluated.",
  correctionMessage:
      "Try removing the code, removing the late modifier or changing the "
      "variable to a non-wildcard.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dead_code_late_wildcard_variable_initializer',
  expectedTypes: [],
);

/// Dead code is code that is never reached. This case covers cases where the
/// user has an on-catch clause such as `on A catch (e)`, where a supertype of
/// `A` was already caught.
///
/// Parameters:
/// Type subtype: name of the subtype
/// Type supertype: name of the supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType subtype,
    required DartType supertype,
  })
>
deadCodeOnCatchSubtype = DiagnosticWithArguments(
  name: 'dead_code_on_catch_subtype',
  problemMessage:
      "Dead code: This on-catch block won't be executed because '{0}' is a "
      "subtype of '{1}' and hence will have been caught already.",
  correctionMessage:
      "Try reordering the catch clauses so that this block can be reached, "
      "or removing the unreachable catch clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dead_code_on_catch_subtype',
  withArguments: _withArgumentsDeadCodeOnCatchSubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
deadNullAwareExpression = DiagnosticWithoutArgumentsImpl(
  name: 'dead_null_aware_expression',
  problemMessage:
      "The left operand can't be null, so the right operand is never executed.",
  correctionMessage: "Try removing the operator and the right operand.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dead_null_aware_expression',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments defaultInSwitchExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'default_in_switch_expression',
      problemMessage: "A switch expression may not use the `default` keyword.",
      correctionMessage: "Try replacing `default` with `_`.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'default_in_switch_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments defaultValueInFunctionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'default_value_in_function_type',
      problemMessage:
          "Parameters in a function type can't have default values.",
      correctionMessage: "Try removing the default value.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'default_value_in_function_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
defaultValueInRedirectingFactoryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'default_value_in_redirecting_factory_constructor',
  problemMessage:
      "Default values aren't allowed in factory constructors that redirect to "
      "another constructor.",
  correctionMessage: "Try removing the default value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'default_value_in_redirecting_factory_constructor',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments defaultValueOnRequiredParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'default_value_on_required_parameter',
      problemMessage: "Required named parameters can't have a default value.",
      correctionMessage:
          "Try removing either the default value or the 'required' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'default_value_on_required_parameter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
deferredAfterPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'deferred_after_prefix',
  problemMessage:
      "The deferred keyword should come immediately before the prefix ('as' "
      "clause).",
  correctionMessage: "Try moving the deferred keyword before the prefix.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'deferred_after_prefix',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments deferredImportOfExtension =
    DiagnosticWithoutArgumentsImpl(
      name: 'deferred_import_of_extension',
      problemMessage: "Imports of deferred libraries must hide all extensions.",
      correctionMessage:
          "Try adding either a show combinator listing the names you need to "
          "reference or a hide combinator listing all of the extensions.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'deferred_import_of_extension',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
definitelyUnassignedLateLocalVariable = DiagnosticWithArguments(
  name: 'definitely_unassigned_late_local_variable',
  problemMessage:
      "The late local variable '{0}' is definitely unassigned at this point.",
  correctionMessage: "Ensure that it is assigned on necessary execution paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'definitely_unassigned_late_local_variable',
  withArguments: _withArgumentsDefinitelyUnassignedLateLocalVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String fieldName: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldName})
>
dependenciesFieldNotMap = DiagnosticWithArguments(
  name: 'dependencies_field_not_map',
  problemMessage: "The value of the '{0}' field is expected to be a map.",
  correctionMessage: "Try converting the value to be a map.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'dependencies_field_not_map',
  withArguments: _withArgumentsDependenciesFieldNotMap,
  expectedTypes: [ExpectedType.string],
);

/// Note: Since this diagnostic is only produced in pre-3.0 code, we do not
/// plan to go through the exercise of converting it to a Warning.
///
/// No parameters.
const DiagnosticWithoutArguments
deprecatedColonForDefaultValue = DiagnosticWithoutArgumentsImpl(
  name: 'deprecated_colon_for_default_value',
  problemMessage:
      "Using a colon as the separator before a default value is deprecated and "
      "will not be supported in language version 3.0 and later.",
  correctionMessage: "Try replacing the colon with an equal sign.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'deprecated_colon_for_default_value',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
deprecatedExportUse = DiagnosticWithArguments(
  name: 'deprecated_export_use',
  problemMessage: "The ability to import '{0}' indirectly is deprecated.",
  correctionMessage: "Try importing '{0}' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_export_use',
  withArguments: _withArgumentsDeprecatedExportUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
deprecatedExtend = DiagnosticWithArguments(
  name: 'deprecated_extend',
  problemMessage: "Extending '{0}' is deprecated.",
  correctionMessage: "Try removing the 'extends' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_extend',
  withArguments: _withArgumentsDeprecatedExtend,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedExtendsFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'deprecated_subtype_of_function',
      problemMessage: "Extending 'Function' is deprecated.",
      correctionMessage: "Try removing 'Function' from the 'extends' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'deprecated_extends_function',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments deprecatedFactoryMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'deprecated_factory_method',
      problemMessage:
          "Methods named 'factory' will become constructors when the "
          "primary_constructors feature is enabled.",
      correctionMessage:
          "Try adding a return type or modifier before the method's name, or "
          "change the name of the method.",
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'deprecated_factory_method',
      expectedTypes: [],
    );

/// Parameters:
/// String fieldName: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldName})
>
deprecatedField = DiagnosticWithArguments(
  name: 'deprecated_field',
  problemMessage: "The '{0}' field is no longer used and can be removed.",
  correctionMessage: "Try removing the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_field',
  withArguments: _withArgumentsDeprecatedField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
deprecatedImplement = DiagnosticWithArguments(
  name: 'deprecated_implement',
  problemMessage: "Implementing '{0}' is deprecated.",
  correctionMessage: "Try removing '{0}' from the 'implements' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_implement',
  withArguments: _withArgumentsDeprecatedImplement,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedImplementsFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'deprecated_subtype_of_function',
      problemMessage: "Implementing 'Function' has no effect.",
      correctionMessage:
          "Try removing 'Function' from the 'implements' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'deprecated_implements_function',
      expectedTypes: [],
    );

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
deprecatedInstantiate = DiagnosticWithArguments(
  name: 'deprecated_instantiate',
  problemMessage: "Instantiating '{0}' is deprecated.",
  correctionMessage: "Try instantiating a non-abstract class.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_instantiate',
  withArguments: _withArgumentsDeprecatedInstantiate,
  expectedTypes: [ExpectedType.string],
);

/// A hint code indicating reference to a deprecated lint.
///
/// Parameters:
/// String ruleName: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String ruleName})
>
deprecatedLint = DiagnosticWithArguments(
  name: 'deprecated_lint',
  problemMessage: "The lint rule '{0}' is deprecated and shouldn't be enabled.",
  correctionMessage: "Try removing '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_lint',
  withArguments: _withArgumentsDeprecatedLint,
  expectedTypes: [ExpectedType.string],
);

/// A hint code indicating reference to a deprecated lint.
///
/// Parameters:
/// String deprecatedRuleName: the deprecated lint name
/// String replacementRuleName: the replacing rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String deprecatedRuleName,
    required String replacementRuleName,
  })
>
deprecatedLintWithReplacement = DiagnosticWithArguments(
  name: 'deprecated_lint_with_replacement',
  problemMessage: "The lint rule '{0}' is deprecated and replaced by '{1}'.",
  correctionMessage: "Try replacing '{0}' with '{1}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_lint_with_replacement',
  withArguments: _withArgumentsDeprecatedLintWithReplacement,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
deprecatedMemberUse = DiagnosticWithArguments(
  name: 'deprecated_member_use',
  problemMessage: "'{0}' is deprecated and shouldn't be used.",
  correctionMessage:
      "Try replacing the use of the deprecated member with the replacement.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'deprecated_member_use',
  withArguments: _withArgumentsDeprecatedMemberUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the member
/// String details: message details
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name, required String details})
>
deprecatedMemberUseWithMessage = DiagnosticWithArguments(
  name: 'deprecated_member_use',
  problemMessage: "'{0}' is deprecated and shouldn't be used. {1}",
  correctionMessage:
      "Try replacing the use of the deprecated member with the replacement.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'deprecated_member_use_with_message',
  withArguments: _withArgumentsDeprecatedMemberUseWithMessage,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
deprecatedMixin = DiagnosticWithArguments(
  name: 'deprecated_mixin',
  problemMessage: "Mixing in '{0}' is deprecated.",
  correctionMessage: "Try removing '{0}' from the 'with' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_mixin',
  withArguments: _withArgumentsDeprecatedMixin,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments deprecatedMixinFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'deprecated_subtype_of_function',
      problemMessage: "Mixing in 'Function' is deprecated.",
      correctionMessage: "Try removing 'Function' from the 'with' clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'deprecated_mixin_function',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments deprecatedNewInCommentReference =
    DiagnosticWithoutArgumentsImpl(
      name: 'deprecated_new_in_comment_reference',
      problemMessage:
          "Using the 'new' keyword in a comment reference is deprecated.",
      correctionMessage: "Try referring to a constructor by its name.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'deprecated_new_in_comment_reference',
      expectedTypes: [],
    );

/// Parameters:
/// String parameterName: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String parameterName})
>
deprecatedOptional = DiagnosticWithArguments(
  name: 'deprecated_optional',
  problemMessage: "Omitting an argument for the '{0}' parameter is deprecated.",
  correctionMessage: "Try passing an argument for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_optional',
  withArguments: _withArgumentsDeprecatedOptional,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
deprecatedSubclass = DiagnosticWithArguments(
  name: 'deprecated_subclass',
  problemMessage: "Subclassing '{0}' is deprecated.",
  correctionMessage:
      "Try removing the 'extends' clause, or removing '{0}' from the "
      "'implements' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'deprecated_subclass',
  withArguments: _withArgumentsDeprecatedSubclass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments directiveAfterDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'directive_after_declaration',
      problemMessage: "Directives must appear before any declarations.",
      correctionMessage: "Try moving the directive before any declarations.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'directive_after_declaration',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments disallowedTypeInstantiationExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'disallowed_type_instantiation_expression',
      problemMessage:
          "Only a generic type, generic function, generic instance method, or "
          "generic constructor can have type arguments.",
      correctionMessage:
          "Try removing the type arguments, or instantiating the type(s) of a "
          "generic type, generic function, generic instance method, or generic "
          "constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'disallowed_type_instantiation_expression',
      expectedTypes: [],
    );

/// Parameters:
/// String argumentName: the name of the doc directive argument
/// String expectedFormat: the expected format
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String argumentName,
    required String expectedFormat,
  })
>
docDirectiveArgumentWrongFormat = DiagnosticWithArguments(
  name: 'doc_directive_argument_wrong_format',
  problemMessage: "The '{0}' argument must be formatted as {1}.",
  correctionMessage: "Try formatting '{0}' as {1}.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_argument_wrong_format',
  withArguments: _withArgumentsDocDirectiveArgumentWrongFormat,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String directive: the name of the doc directive
/// int actualCount: the actual number of arguments
/// int expectedCount: the expected number of arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String directive,
    required int actualCount,
    required int expectedCount,
  })
>
docDirectiveHasExtraArguments = DiagnosticWithArguments(
  name: 'doc_directive_has_extra_arguments',
  problemMessage:
      "The '{0}' directive has '{1}' arguments, but only '{2}' are expected.",
  correctionMessage: "Try removing the extra arguments.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_has_extra_arguments',
  withArguments: _withArgumentsDocDirectiveHasExtraArguments,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String directive: the name of the doc directive
/// String argumentName: the name of the unexpected argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String directive,
    required String argumentName,
  })
>
docDirectiveHasUnexpectedNamedArgument = DiagnosticWithArguments(
  name: 'doc_directive_has_unexpected_named_argument',
  problemMessage:
      "The '{0}' directive has an unexpected named argument, '{1}'.",
  correctionMessage: "Try removing the unexpected argument.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_has_unexpected_named_argument',
  withArguments: _withArgumentsDocDirectiveHasUnexpectedNamedArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments docDirectiveMissingClosingBrace =
    DiagnosticWithoutArgumentsImpl(
      name: 'doc_directive_missing_closing_brace',
      problemMessage: "Doc directive is missing a closing curly brace ('}').",
      correctionMessage: "Try closing the directive with a curly brace.",
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'doc_directive_missing_closing_brace',
      expectedTypes: [],
    );

/// Parameters:
/// String tagName: the name of the corresponding doc directive tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String tagName})
>
docDirectiveMissingClosingTag = DiagnosticWithArguments(
  name: 'doc_directive_missing_closing_tag',
  problemMessage: "Doc directive is missing a closing tag.",
  correctionMessage:
      "Try closing the directive with the appropriate closing tag, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_missing_closing_tag',
  withArguments: _withArgumentsDocDirectiveMissingClosingTag,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String directive: the name of the doc directive
/// String argumentName: the name of the missing argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String directive,
    required String argumentName,
  })
>
docDirectiveMissingOneArgument = DiagnosticWithArguments(
  name: 'doc_directive_missing_argument',
  problemMessage: "The '{0}' directive is missing a '{1}' argument.",
  correctionMessage: "Try adding a '{1}' argument before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_missing_one_argument',
  withArguments: _withArgumentsDocDirectiveMissingOneArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String tagName: the name of the corresponding doc directive tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String tagName})
>
docDirectiveMissingOpeningTag = DiagnosticWithArguments(
  name: 'doc_directive_missing_opening_tag',
  problemMessage: "Doc directive is missing an opening tag.",
  correctionMessage:
      "Try opening the directive with the appropriate opening tag, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_missing_opening_tag',
  withArguments: _withArgumentsDocDirectiveMissingOpeningTag,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String directive: the name of the doc directive
/// String argument1: the name of the first missing argument
/// String argument2: the name of the second missing argument
/// String argument3: the name of the third missing argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String directive,
    required String argument1,
    required String argument2,
    required String argument3,
  })
>
docDirectiveMissingThreeArguments = DiagnosticWithArguments(
  name: 'doc_directive_missing_argument',
  problemMessage:
      "The '{0}' directive is missing a '{1}', a '{2}', and a '{3}' argument.",
  correctionMessage: "Try adding the missing arguments before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_missing_three_arguments',
  withArguments: _withArgumentsDocDirectiveMissingThreeArguments,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String directive: the name of the doc directive
/// String argument1: the name of the first missing argument
/// String argument2: the name of the second missing argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String directive,
    required String argument1,
    required String argument2,
  })
>
docDirectiveMissingTwoArguments = DiagnosticWithArguments(
  name: 'doc_directive_missing_argument',
  problemMessage:
      "The '{0}' directive is missing a '{1}' and a '{2}' argument.",
  correctionMessage: "Try adding the missing arguments before the closing '}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_missing_two_arguments',
  withArguments: _withArgumentsDocDirectiveMissingTwoArguments,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String directive: the name of the unknown doc directive.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String directive})
>
docDirectiveUnknown = DiagnosticWithArguments(
  name: 'doc_directive_unknown',
  problemMessage: "Doc directive '{0}' is unknown.",
  correctionMessage: "Try using one of the supported doc directives.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'doc_directive_unknown',
  withArguments: _withArgumentsDocDirectiveUnknown,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments docImportCannotBeDeferred =
    DiagnosticWithoutArgumentsImpl(
      name: 'doc_import_cannot_be_deferred',
      problemMessage: "Doc imports can't be deferred.",
      correctionMessage: "Try removing the 'deferred' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'doc_import_cannot_be_deferred',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHaveCombinators =
    DiagnosticWithoutArgumentsImpl(
      name: 'doc_import_cannot_have_combinators',
      problemMessage: "Doc imports can't have show or hide combinators.",
      correctionMessage: "Try removing the combinator.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'doc_import_cannot_have_combinators',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHaveConfigurations =
    DiagnosticWithoutArgumentsImpl(
      name: 'doc_import_cannot_have_configurations',
      problemMessage: "Doc imports can't have configurations.",
      correctionMessage: "Try removing the configurations.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'doc_import_cannot_have_configurations',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments docImportCannotHavePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'doc_import_cannot_have_prefix',
      problemMessage: "Doc imports can't have prefixes.",
      correctionMessage: "Try removing the prefix.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'doc_import_cannot_have_prefix',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments dotShorthandMissingContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'dot_shorthand_missing_context',
      problemMessage:
          "A dot shorthand can't be used where there is no context type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'dot_shorthand_missing_context',
      expectedTypes: [],
    );

/// Parameters:
/// String getterName: the name of the static getter
/// String typeName: the name of the enclosing type where the getter is being
///                  looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String getterName,
    required String typeName,
  })
>
dotShorthandUndefinedGetter = DiagnosticWithArguments(
  name: 'dot_shorthand_undefined_member',
  problemMessage:
      "The static getter '{0}' isn't defined for the context type '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing static getter, or "
      "defining a getter or field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'dot_shorthand_undefined_getter',
  withArguments: _withArgumentsDotShorthandUndefinedGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the static method or constructor
/// String contextType: the name of the enclosing type where the method or
///                     constructor is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required String contextType,
  })
>
dotShorthandUndefinedInvocation = DiagnosticWithArguments(
  name: 'dot_shorthand_undefined_member',
  problemMessage:
      "The static method or constructor '{0}' isn't defined for the context type "
      "'{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing static method or "
      "constructor, or defining a static method or constructor named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'dot_shorthand_undefined_invocation',
  withArguments: _withArgumentsDotShorthandUndefinedInvocation,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateConstructorDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_constructor',
      problemMessage: "The unnamed constructor is already defined.",
      correctionMessage: "Try giving one of the constructors a name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'duplicate_constructor_default',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the duplicate entity
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateConstructorName = DiagnosticWithArguments(
  name: 'duplicate_constructor',
  problemMessage: "The constructor with name '{0}' is already defined.",
  correctionMessage: "Try renaming one of the constructors.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_constructor_name',
  withArguments: _withArgumentsDuplicateConstructorName,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateDeferred =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_deferred',
      problemMessage:
          "An import directive can only have one 'deferred' keyword.",
      correctionMessage: "Try removing all but one 'deferred' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'duplicate_deferred',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the duplicate entity
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateDefinition = DiagnosticWithArguments(
  name: 'duplicate_definition',
  problemMessage: "The name '{0}' is already defined.",
  correctionMessage: "Try renaming one of the declarations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_definition',
  withArguments: _withArgumentsDuplicateDefinition,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// 0: the modifier that was duplicated
///
/// Parameters:
/// Token lexeme: THe token that was found.
const DiagnosticCode duplicatedModifier = DiagnosticCodeWithExpectedTypes(
  name: 'duplicated_modifier',
  problemMessage: "The modifier '{0}' was already specified.",
  correctionMessage: "Try removing all but one occurrence of the modifier.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'duplicated_modifier',
  expectedTypes: [ExpectedType.token],
);

/// Duplicate exports.
///
/// No parameters.
const DiagnosticWithoutArguments duplicateExport =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_export',
      problemMessage: "Duplicate export.",
      correctionMessage: "Try removing all but one export of the library.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'duplicate_export',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateFieldFormalParameter = DiagnosticWithArguments(
  name: 'duplicate_field_formal_parameter',
  problemMessage:
      "The field '{0}' can't be initialized by multiple parameters in the same "
      "constructor.",
  correctionMessage:
      "Try removing one of the parameters, or using different fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_field_formal_parameter',
  withArguments: _withArgumentsDuplicateFieldFormalParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the duplicated name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateFieldName = DiagnosticWithArguments(
  name: 'duplicate_field_name',
  problemMessage: "The field name '{0}' is already used in this record.",
  correctionMessage: "Try renaming the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_field_name',
  withArguments: _withArgumentsDuplicateFieldName,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateHiddenName =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_hidden_name',
      problemMessage: "Duplicate hidden name.",
      correctionMessage:
          "Try removing the repeated name from the list of hidden members.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'duplicate_hidden_name',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the diagnostic being ignored
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateIgnore = DiagnosticWithArguments(
  name: 'duplicate_ignore',
  problemMessage:
      "The diagnostic '{0}' doesn't need to be ignored here because it's already "
      "being ignored.",
  correctionMessage:
      "Try removing the name from the list, or removing the whole comment if "
      "this is the only name in the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'duplicate_ignore',
  withArguments: _withArgumentsDuplicateIgnore,
  expectedTypes: [ExpectedType.string],
);

/// Duplicate imports.
///
/// No parameters.
const DiagnosticWithoutArguments duplicateImport =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_import',
      problemMessage: "Duplicate import.",
      correctionMessage: "Try removing all but one import of the library.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'duplicate_import',
      expectedTypes: [],
    );

/// Parameters:
/// 0: the label that was duplicated
///
/// Parameters:
/// Name labelName: The name of the label that was already used.
const DiagnosticCode duplicateLabelInSwitchStatement =
    DiagnosticCodeWithExpectedTypes(
      name: 'duplicate_label_in_switch_statement',
      problemMessage:
          "The label '{0}' was already used in this switch statement.",
      correctionMessage: "Try choosing a different name for this label.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'duplicate_label_in_switch_statement',
      expectedTypes: [ExpectedType.name],
    );

/// Parameters:
/// String name: the name of the parameter that was duplicated
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateNamedArgument = DiagnosticWithArguments(
  name: 'duplicate_named_argument',
  problemMessage:
      "The argument for the named parameter '{0}' was already specified.",
  correctionMessage:
      "Try removing one of the named arguments, or correcting one of the "
      "names to reference a different named parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_named_argument',
  withArguments: _withArgumentsDuplicateNamedArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Uri uri: the URI of the duplicate part
const DiagnosticWithArguments<LocatableDiagnostic Function({required Uri uri})>
duplicatePart = DiagnosticWithArguments(
  name: 'duplicate_part',
  problemMessage: "The library already contains a part with the URI '{0}'.",
  correctionMessage:
      "Try removing all except one of the duplicated part directives.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_part',
  withArguments: _withArgumentsDuplicatePart,
  expectedTypes: [ExpectedType.uri],
);

/// Parameters:
/// String name: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicatePatternAssignmentVariable = DiagnosticWithArguments(
  name: 'duplicate_pattern_assignment_variable',
  problemMessage: "The variable '{0}' is already assigned in this pattern.",
  correctionMessage: "Try renaming the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_pattern_assignment_variable',
  withArguments: _withArgumentsDuplicatePatternAssignmentVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicatePatternField = DiagnosticWithArguments(
  name: 'duplicate_pattern_field',
  problemMessage: "The field '{0}' is already matched in this pattern.",
  correctionMessage: "Try removing the duplicate field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_pattern_field',
  withArguments: _withArgumentsDuplicatePatternField,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicatePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_prefix',
      problemMessage:
          "An import directive can only have one prefix ('as' clause).",
      correctionMessage: "Try removing all but one prefix.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'duplicate_prefix',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments duplicateRestElementInPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_rest_element_in_pattern',
      problemMessage:
          "At most one rest element is allowed in a list or map pattern.",
      correctionMessage: "Try removing the duplicate rest element.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'duplicate_rest_element_in_pattern',
      expectedTypes: [],
    );

/// Duplicate rules.
///
/// Parameters:
/// String ruleName: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String ruleName})
>
duplicateRule = DiagnosticWithArguments(
  name: 'duplicate_rule',
  problemMessage:
      "The rule '{0}' is already enabled and doesn't need to be enabled again.",
  correctionMessage: "Try removing all but one occurrence of the rule.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'duplicate_rule',
  withArguments: _withArgumentsDuplicateRule,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments duplicateShownName =
    DiagnosticWithoutArgumentsImpl(
      name: 'duplicate_shown_name',
      problemMessage: "Duplicate shown name.",
      correctionMessage:
          "Try removing the repeated name from the list of shown members.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'duplicate_shown_name',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
duplicateVariablePattern = DiagnosticWithArguments(
  name: 'duplicate_variable_pattern',
  problemMessage: "The variable '{0}' is already defined in this pattern.",
  correctionMessage: "Try renaming the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'duplicate_variable_pattern',
  withArguments: _withArgumentsDuplicateVariablePattern,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments emptyEnumBody = DiagnosticWithoutArgumentsImpl(
  name: 'empty_enum_body',
  problemMessage: "An enum must declare at least one constant name.",
  correctionMessage: "Try declaring a constant.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'empty_enum_body',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments emptyMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'empty_map_pattern',
      problemMessage: "A map pattern must have at least one entry.",
      correctionMessage: "Try replacing it with an object pattern 'Map()'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'empty_map_pattern',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordLiteralWithComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'empty_record_literal_with_comma',
      problemMessage:
          "A record literal without fields can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'empty_record_literal_with_comma',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordTypeNamedFieldsList =
    DiagnosticWithoutArgumentsImpl(
      name: 'empty_record_type_named_fields_list',
      problemMessage:
          "The list of named fields in a record type can't be empty.",
      correctionMessage: "Try adding a named field to the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'empty_record_type_named_fields_list',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments emptyRecordTypeWithComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'empty_record_type_with_comma',
      problemMessage:
          "A record type without fields can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'empty_record_type_with_comma',
      expectedTypes: [],
    );

/// Parameters:
/// String subclassName: the name of the subclass
/// String superclassName: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subclassName,
    required String superclassName,
  })
>
emptyStruct = DiagnosticWithArguments(
  name: 'empty_struct',
  problemMessage:
      "The class '{0}' can't be empty because it's a subclass of '{1}'.",
  correctionMessage:
      "Try adding a field to '{0}' or use a different superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'empty_struct',
  withArguments: _withArgumentsEmptyStruct,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments encoding = DiagnosticWithoutArgumentsImpl(
  name: 'encoding',
  problemMessage: "Unable to decode bytes as UTF-8.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'encoding',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments enumConstantInvokesFactoryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_constant_invokes_factory_constructor',
      problemMessage: "An enum value can't invoke a factory constructor.",
      correctionMessage: "Try using a generative constructor.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_constant_invokes_factory_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumConstantSameNameAsEnclosing =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_constant_same_name_as_enclosing',
      problemMessage:
          "The name of the enum value can't be the same as the enum's name.",
      correctionMessage: "Try renaming the constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_constant_same_name_as_enclosing',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumInClass = DiagnosticWithoutArgumentsImpl(
  name: 'enum_in_class',
  problemMessage: "Enums can't be declared inside classes.",
  correctionMessage: "Try moving the enum to the top-level.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'enum_in_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments enumInstantiatedToBoundsIsNotWellBounded =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_instantiated_to_bounds_is_not_well_bounded',
      problemMessage:
          "The result of instantiating the enum to bounds is not well-bounded.",
      correctionMessage: "Try using different bounds for type parameters.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_instantiated_to_bounds_is_not_well_bounded',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumMixinWithInstanceVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_mixin_with_instance_variable',
      problemMessage: "Mixins applied to enums can't have instance variables.",
      correctionMessage: "Try replacing the instance variables with getters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_mixin_with_instance_variable',
      expectedTypes: [],
    );

/// Parameters:
/// String methodName: the name of the abstract method
/// String enclosingClass: the name of the enclosing enum
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String enclosingClass,
  })
>
enumWithAbstractMember = DiagnosticWithArguments(
  name: 'enum_with_abstract_member',
  problemMessage: "'{0}' must have a method body because '{1}' is an enum.",
  correctionMessage: "Try adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'enum_with_abstract_member',
  withArguments: _withArgumentsEnumWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments enumWithNameValues =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_with_name_values',
      problemMessage: "The name 'values' is not a valid name for an enum.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_with_name_values',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments enumWithoutConstants =
    DiagnosticWithoutArgumentsImpl(
      name: 'enum_without_constants',
      problemMessage: "The enum must have at least one enum constant.",
      correctionMessage: "Try declaring an enum constant.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'enum_without_constants',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalElementsInConstSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'equal_elements_in_const_set',
      problemMessage: "Two elements in a constant set literal can't be equal.",
      correctionMessage: "Change or remove the duplicate element.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'equal_elements_in_const_set',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalElementsInSet =
    DiagnosticWithoutArgumentsImpl(
      name: 'equal_elements_in_set',
      problemMessage: "Two elements in a set literal shouldn't be equal.",
      correctionMessage: "Change or remove the duplicate element.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'equal_elements_in_set',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalityCannotBeEqualityOperand =
    DiagnosticWithoutArgumentsImpl(
      name: 'equality_cannot_be_equality_operand',
      problemMessage:
          "A comparison expression can't be an operand of another comparison "
          "expression.",
      correctionMessage:
          "Try putting parentheses around one of the comparisons.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'equality_cannot_be_equality_operand',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInConstMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'equal_keys_in_const_map',
      problemMessage: "Two keys in a constant map literal can't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'equal_keys_in_const_map',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'equal_keys_in_map',
      problemMessage: "Two keys in a map literal shouldn't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'equal_keys_in_map',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments equalKeysInMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'equal_keys_in_map_pattern',
      problemMessage: "Two keys in a map pattern can't be equal.",
      correctionMessage: "Change or remove the duplicate key.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'equal_keys_in_map_pattern',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedCaseOrDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_case_or_default',
      problemMessage: "Expected 'case' or 'default'.",
      correctionMessage: "Try placing this code inside a case clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_case_or_default',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedCatchClauseBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage: "A catch clause must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_catch_clause_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedClassBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage:
          "A class declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_class_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedClassMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_class_member',
      problemMessage: "Expected a class member.",
      correctionMessage: "Try placing this code inside a class member.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_class_member',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedElseOrComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_else_or_comma',
      problemMessage: "Expected 'else' or comma.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_else_or_comma',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
expectedExecutable = DiagnosticWithoutArgumentsImpl(
  name: 'expected_executable',
  problemMessage: "Expected a method, getter, setter or operator declaration.",
  correctionMessage:
      "This appears to be incomplete code. Try removing it or completing it.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'expected_executable',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments expectedExtensionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage:
          "An extension declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_extension_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
expectedExtensionTypeBody = DiagnosticWithoutArgumentsImpl(
  name: 'expected_body',
  problemMessage:
      "An extension type declaration must have a body, even if it is empty.",
  correctionMessage: "Try adding an empty body.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'expected_extension_type_body',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments expectedFinallyClauseBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage: "A finally clause must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_finally_clause_body',
      expectedTypes: [],
    );

/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode expectedIdentifierButGotKeyword =
    DiagnosticCodeWithExpectedTypes(
      name: 'expected_identifier_but_got_keyword',
      problemMessage:
          "'{0}' can't be used as an identifier because it's a keyword.",
      correctionMessage:
          "Try renaming this to be an identifier that isn't a keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_identifier_but_got_keyword',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// String expected: What was expected.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String expected})
>
expectedInstead = DiagnosticWithArguments(
  name: 'expected_instead',
  problemMessage: "Expected '{0}' instead of this.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'expected_instead',
  withArguments: _withArgumentsExpectedInstead,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expectedListOrMapLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_list_or_map_literal',
      problemMessage: "Expected a list or map literal.",
      correctionMessage:
          "Try inserting a list or map literal, or remove the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_list_or_map_literal',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedMixinBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage:
          "A mixin declaration must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_mixin_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_named_type',
      problemMessage: "Expected a class name.",
      correctionMessage:
          "Try using a class name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_named_type_extends',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeImplements =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_named_type',
      problemMessage: "Expected the name of a class or mixin.",
      correctionMessage:
          "Try using a class or mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_named_type_implements',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeOn =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_named_type',
      problemMessage: "Expected the name of a class or mixin.",
      correctionMessage:
          "Try using a class or mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_named_type_on',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedNamedTypeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_named_type',
      problemMessage: "Expected a mixin name.",
      correctionMessage:
          "Try using a mixin name, possibly with type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_named_type_with',
      expectedTypes: [],
    );

/// Parameters:
/// int count: the number of provided type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int count})
>
expectedOneListPatternTypeArguments = DiagnosticWithArguments(
  name: 'expected_one_list_pattern_type_arguments',
  problemMessage:
      "List patterns require one type argument or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'expected_one_list_pattern_type_arguments',
  withArguments: _withArgumentsExpectedOneListPatternTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int count: the number of provided type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int count})
>
expectedOneListTypeArguments = DiagnosticWithArguments(
  name: 'expected_one_list_type_arguments',
  problemMessage:
      "List literals require one type argument or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'expected_one_list_type_arguments',
  withArguments: _withArgumentsExpectedOneListTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int count: the number of provided type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int count})
>
expectedOneSetTypeArguments = DiagnosticWithArguments(
  name: 'expected_one_set_type_arguments',
  problemMessage:
      "Set literals require one type argument or none, but {0} were found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'expected_one_set_type_arguments',
  withArguments: _withArgumentsExpectedOneSetTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments expectedRepresentationField =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_representation_field',
      problemMessage: "Expected a representation field.",
      correctionMessage:
          "Try providing the representation field for this extension type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_representation_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedRepresentationType =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_representation_type',
      problemMessage: "Expected a representation type.",
      correctionMessage:
          "Try providing the representation type for this extension type.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_representation_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedStringLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_string_literal',
      problemMessage: "Expected a string literal.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_string_literal',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedSwitchExpressionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage:
          "A switch expression must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_switch_expression_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments expectedSwitchStatementBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage:
          "A switch statement must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_switch_statement_body',
      expectedTypes: [],
    );

/// Parameters:
/// String token: the token that was expected but not found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String token})
>
expectedToken = DiagnosticWithArguments(
  name: 'expected_token',
  problemMessage: "Expected to find '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'expected_token',
  withArguments: _withArgumentsExpectedToken,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expectedTryStatementBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_body',
      problemMessage: "A try statement must have a body, even if it is empty.",
      correctionMessage: "Try adding an empty body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_try_statement_body',
      expectedTypes: [],
    );

/// Parameters:
/// int count: the number of provided type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int count})
>
expectedTwoMapPatternTypeArguments = DiagnosticWithArguments(
  name: 'expected_two_map_pattern_type_arguments',
  problemMessage:
      "Map patterns require two type arguments or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'expected_two_map_pattern_type_arguments',
  withArguments: _withArgumentsExpectedTwoMapPatternTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// int count: the number of provided type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int count})
>
expectedTwoMapTypeArguments = DiagnosticWithArguments(
  name: 'expected_two_map_type_arguments',
  problemMessage:
      "Map literals require two type arguments or none, but {0} found.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'expected_two_map_type_arguments',
  withArguments: _withArgumentsExpectedTwoMapTypeArguments,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments expectedTypeName =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_type_name',
      problemMessage: "Expected a type name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'expected_type_name',
      expectedTypes: [],
    );

/// Parameters:
/// String member: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String member})
>
experimentalMemberUse = DiagnosticWithArguments(
  name: 'experimental_member_use',
  problemMessage:
      "'{0}' is experimental and could be removed or changed at any time.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'experimental_member_use',
  withArguments: _withArgumentsExperimentalMemberUse,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String featureName: The name of of the language feature.
/// String enabledVersion: The language version in which the language feature
///                        was enabled.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String featureName,
    required String enabledVersion,
  })
>
experimentNotEnabled = DiagnosticWithArguments(
  name: 'experiment_not_enabled',
  problemMessage: "This requires the '{0}' language feature to be enabled.",
  correctionMessage:
      "Try updating your pubspec.yaml to set the minimum SDK constraint to "
      "{1} or higher, and running 'pub get'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'experiment_not_enabled',
  withArguments: _withArgumentsExperimentNotEnabled,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String featureName: The name of the language feature.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String featureName})
>
experimentNotEnabledOffByDefault = DiagnosticWithArguments(
  name: 'experiment_not_enabled_off_by_default',
  problemMessage:
      "This requires the experimental '{0}' language feature to be enabled.",
  correctionMessage:
      "Try passing the '--enable-experiment={0}' command line option.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'experiment_not_enabled_off_by_default',
  withArguments: _withArgumentsExperimentNotEnabledOffByDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments exportDirectiveAfterPartDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'export_directive_after_part_directive',
      problemMessage: "Export directives must precede part directives.",
      correctionMessage:
          "Try moving the export directives before the part directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'export_directive_after_part_directive',
      expectedTypes: [],
    );

/// Parameters:
/// String uri: the URI pointing to a library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uri})
>
exportInternalLibrary = DiagnosticWithArguments(
  name: 'export_internal_library',
  problemMessage: "The library '{0}' is internal and can't be exported.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'export_internal_library',
  withArguments: _withArgumentsExportInternalLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String uri: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uri})
>
exportOfNonLibrary = DiagnosticWithArguments(
  name: 'export_of_non_library',
  problemMessage: "The exported library '{0}' can't have a part-of directive.",
  correctionMessage: "Try exporting the library that the part is a part of.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'export_of_non_library',
  withArguments: _withArgumentsExportOfNonLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expressionInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'expression_in_map',
      problemMessage: "Expressions can't be used in a map literal.",
      correctionMessage:
          "Try removing the expression or converting it to be a map entry.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'expression_in_map',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extendsDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'subtype_of_deferred_class',
      problemMessage: "Classes can't extend deferred classes.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extends_deferred_class',
      expectedTypes: [],
    );

/// Parameters:
/// Type disallowedType: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType disallowedType})
>
extendsDisallowedClass = DiagnosticWithArguments(
  name: 'subtype_of_disallowed_type',
  problemMessage: "Classes can't extend '{0}'.",
  correctionMessage:
      "Try specifying a different superclass, or removing the extends "
      "clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extends_disallowed_class',
  withArguments: _withArgumentsExtendsDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments extendsNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'extends_non_class',
      problemMessage: "Classes can only extend other classes.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      isUnresolvedIdentifier: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extends_non_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extendsTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'supertype_expands_to_type_parameter',
      problemMessage:
          "A type alias that expands to a type parameter can't be used as a "
          "superclass.",
      correctionMessage:
          "Try specifying a different superclass, or removing the extends "
          "clause.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extends_type_alias_expands_to_type_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
extensionAsExpression = DiagnosticWithArguments(
  name: 'extension_as_expression',
  problemMessage: "Extension '{0}' can't be used as an expression.",
  correctionMessage: "Try replacing it with a valid expression.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_as_expression',
  withArguments: _withArgumentsExtensionAsExpression,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionAugmentationHasOnClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_augmentation_has_on_clause',
      problemMessage: "Extension augmentations can't have 'on' clauses.",
      correctionMessage: "Try removing the 'on' clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extension_augmentation_has_on_clause',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the conflicting static member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
extensionConflictingStaticAndInstance = DiagnosticWithArguments(
  name: 'extension_conflicting_static_and_instance',
  problemMessage:
      "An extension can't define static member '{0}' and an instance member with "
      "the same name.",
  correctionMessage: "Try renaming the member to a name that doesn't conflict.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_conflicting_static_and_instance',
  withArguments: _withArgumentsExtensionConflictingStaticAndInstance,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresAbstractMember =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_declares_abstract_member',
      problemMessage: "Extensions can't declare abstract members.",
      correctionMessage: "Try providing an implementation for the member.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extension_declares_abstract_member',
      expectedTypes: [],
    );

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_declares_constructor',
      problemMessage: "Extensions can't declare constructors.",
      correctionMessage: "Try removing the constructor declaration.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extension_declares_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionDeclaresInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_declares_instance_field',
      problemMessage: "Extensions can't declare instance fields.",
      correctionMessage: "Try replacing the field with a getter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_declares_instance_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionDeclaresMemberOfObject = DiagnosticWithoutArgumentsImpl(
  name: 'extension_declares_member_of_object',
  problemMessage:
      "Extensions can't declare members with the same name as a member declared "
      "by 'Object'.",
  correctionMessage: "Try specifying a different name for the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_declares_member_of_object',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionOverrideAccessToStaticMember = DiagnosticWithoutArgumentsImpl(
  name: 'extension_override_access_to_static_member',
  problemMessage:
      "An extension override can't be used to access a static member from an "
      "extension.",
  correctionMessage: "Try using just the name of the extension.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_override_access_to_static_member',
  expectedTypes: [],
);

/// Parameters:
/// Type argumentType: the type of the argument
/// Type extendedType: the extended type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType argumentType,
    required DartType extendedType,
  })
>
extensionOverrideArgumentNotAssignable = DiagnosticWithArguments(
  name: 'extension_override_argument_not_assignable',
  problemMessage:
      "The type of the argument to the extension override '{0}' isn't assignable "
      "to the extended type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_override_argument_not_assignable',
  withArguments: _withArgumentsExtensionOverrideArgumentNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionOverrideWithCascade = DiagnosticWithoutArgumentsImpl(
  name: 'extension_override_with_cascade',
  problemMessage:
      "Extension overrides have no value so they can't be used as the receiver "
      "of a cascade expression.",
  correctionMessage: "Try using '.' instead of '..'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_override_with_cascade',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionOverrideWithoutAccess =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_override_without_access',
      problemMessage:
          "An extension override can only be used to access instance members.",
      correctionMessage: "Consider adding an access to an instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_override_without_access',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeConstructorWithSuperFormalParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_constructor_with_super_formal_parameter',
      problemMessage:
          "Extension type constructors can't declare super formal parameters.",
      correctionMessage: "Try removing the super formal parameter declaration.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_type_constructor_with_super_formal_parameter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionTypeConstructorWithSuperInvocation =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_constructor_with_super_invocation',
      problemMessage:
          "Extension type constructors can't include super initializers.",
      correctionMessage: "Try removing the super constructor invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_type_constructor_with_super_invocation',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionTypeDeclaresInstanceField =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_declares_instance_field',
      problemMessage: "Extension types can't declare instance fields.",
      correctionMessage: "Try replacing the field with a getter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_type_declares_instance_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeDeclaresMemberOfObject = DiagnosticWithoutArgumentsImpl(
  name: 'extension_type_declares_member_of_object',
  problemMessage:
      "Extension types can't declare members with the same name as a member "
      "declared by 'Object'.",
  correctionMessage: "Try specifying a different name for the member.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_declares_member_of_object',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments extensionTypeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_extends',
      problemMessage:
          "An extension type declaration can't have an 'extends' clause.",
      correctionMessage:
          "Try removing the 'extends' clause or replacing the 'extends' with "
          "'implements'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extension_type_extends',
      expectedTypes: [],
    );

/// Parameters:
/// Type type: the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
extensionTypeImplementsDisallowedType = DiagnosticWithArguments(
  name: 'extension_type_implements_disallowed_type',
  problemMessage: "Extension types can't implement '{0}'.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_implements_disallowed_type',
  withArguments: _withArgumentsExtensionTypeImplementsDisallowedType,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
extensionTypeImplementsItself = DiagnosticWithoutArgumentsImpl(
  name: 'extension_type_implements_itself',
  problemMessage: "The extension type can't implement itself.",
  correctionMessage:
      "Try removing the superinterface that references this extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_implements_itself',
  expectedTypes: [],
);

/// Parameters:
/// Type type: the implemented not extension type
/// Type representationType: the ultimate representation type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required DartType representationType,
  })
>
extensionTypeImplementsNotSupertype = DiagnosticWithArguments(
  name: 'extension_type_implements_not_supertype',
  problemMessage: "'{0}' is not a supertype of '{1}', the representation type.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_implements_not_supertype',
  withArguments: _withArgumentsExtensionTypeImplementsNotSupertype,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type implementedRepresentationType: the representation type of the
///                                     implemented extension type
/// String implementedExtensionTypeName: the name of the implemented extension
///                                      type
/// Type representationType: the representation type of the this extension
///                          type
/// String extensionTypeName: the name of the this extension type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType implementedRepresentationType,
    required String implementedExtensionTypeName,
    required DartType representationType,
    required String extensionTypeName,
  })
>
extensionTypeImplementsRepresentationNotSupertype = DiagnosticWithArguments(
  name: 'extension_type_implements_representation_not_supertype',
  problemMessage:
      "'{0}', the representation type of '{1}', is not a supertype of '{2}', the "
      "representation type of '{3}'.",
  correctionMessage:
      "Try specifying a different type, or remove the type from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_implements_representation_not_supertype',
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
/// String extensionTypeName: the name of the extension type
/// String memberName: the name of the conflicting member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String extensionTypeName,
    required String memberName,
  })
>
extensionTypeInheritedMemberConflict = DiagnosticWithArguments(
  name: 'extension_type_inherited_member_conflict',
  problemMessage:
      "The extension type '{0}' has more than one distinct member named '{1}' "
      "from implemented types.",
  correctionMessage:
      "Try redeclaring the corresponding member in this extension type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_inherited_member_conflict',
  withArguments: _withArgumentsExtensionTypeInheritedMemberConflict,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments extensionTypeRepresentationDependsOnItself =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_representation_depends_on_itself',
      problemMessage:
          "The extension type representation can't depend on itself.",
      correctionMessage: "Try specifying a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_type_representation_depends_on_itself',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionTypeRepresentationTypeBottom =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_representation_type_bottom',
      problemMessage: "The representation type can't be a bottom type.",
      correctionMessage: "Try specifying a different type.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extension_type_representation_type_bottom',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments extensionTypeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'extension_type_with',
      problemMessage:
          "An extension type declaration can't have a 'with' clause.",
      correctionMessage:
          "Try removing the 'with' clause or replacing the 'with' with "
          "'implements'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extension_type_with',
      expectedTypes: [],
    );

/// Parameters:
/// String methodName: the name of the abstract method
/// String extensionTypeName: the name of the enclosing extension type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String extensionTypeName,
  })
>
extensionTypeWithAbstractMember = DiagnosticWithArguments(
  name: 'extension_type_with_abstract_member',
  problemMessage:
      "'{0}' must have a method body because '{1}' is an extension type.",
  correctionMessage: "Try adding a body to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extension_type_with_abstract_member',
  withArguments: _withArgumentsExtensionTypeWithAbstractMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments externalClass = DiagnosticWithoutArgumentsImpl(
  name: 'external_class',
  problemMessage: "Classes can't be declared to be 'external'.",
  correctionMessage: "Try removing the keyword 'external'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'external_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalConstructorWithFieldInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_constructor_with_field_initializers',
      problemMessage: "An external constructor can't initialize fields.",
      correctionMessage:
          "Try removing the field initializers, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_constructor_with_field_initializers',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalConstructorWithInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_constructor_with_initializer',
      problemMessage: "An external constructor can't have any initializers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_constructor_with_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalEnum = DiagnosticWithoutArgumentsImpl(
  name: 'external_enum',
  problemMessage: "Enums can't be declared to be 'external'.",
  correctionMessage: "Try removing the keyword 'external'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'external_enum',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalFactoryRedirection =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_factory_redirection',
      problemMessage: "A redirecting factory can't be external.",
      correctionMessage: "Try removing the 'external' modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_factory_redirection',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalFactoryWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_factory_with_body',
      problemMessage: "External factories can't have a body.",
      correctionMessage:
          "Try removing the body of the factory, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_factory_with_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
externalFieldConstructorInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'external_with_initializer',
  problemMessage: "External fields can't have initializers.",
  correctionMessage:
      "Try removing the field initializer or the 'external' keyword from the "
      "field declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'external_field_constructor_initializer',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments externalFieldInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_with_initializer',
      problemMessage: "External fields can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'external' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'external_field_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalGetterWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_getter_with_body',
      problemMessage: "External getters can't have a body.",
      correctionMessage:
          "Try removing the body of the getter, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_getter_with_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalLateField =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_late_field',
      problemMessage: "External fields cannot be late.",
      correctionMessage: "Try removing the 'external' or 'late' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_late_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalMethodWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_method_with_body',
      problemMessage: "An external or native method can't have a body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_method_with_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalOperatorWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_operator_with_body',
      problemMessage: "External operators can't have a body.",
      correctionMessage:
          "Try removing the body of the operator, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_operator_with_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalSetterWithBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_setter_with_body',
      problemMessage: "External setters can't have a body.",
      correctionMessage:
          "Try removing the body of the setter, or removing the keyword "
          "'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_setter_with_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalTypedef =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_typedef',
      problemMessage: "Typedefs can't be declared to be 'external'.",
      correctionMessage: "Try removing the keyword 'external'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'external_typedef',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments externalVariableInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'external_with_initializer',
      problemMessage: "External variables can't have initializers.",
      correctionMessage:
          "Try removing the initializer or the 'external' keyword.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'external_variable_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
extraAnnotationOnStructField = DiagnosticWithoutArgumentsImpl(
  name: 'extra_annotation_on_struct_field',
  problemMessage:
      "Fields in a struct class must have exactly one annotation indicating the "
      "native type.",
  correctionMessage: "Try removing the extra annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extra_annotation_on_struct_field',
  expectedTypes: [],
);

/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode extraneousModifier = DiagnosticCodeWithExpectedTypes(
  name: 'extraneous_modifier',
  problemMessage: "Can't have modifier '{0}' here.",
  correctionMessage: "Try removing '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'extraneous_modifier',
  expectedTypes: [ExpectedType.token],
);

/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode extraneousModifierInExtensionType =
    DiagnosticCodeWithExpectedTypes(
      name: 'extraneous_modifier_in_extension_type',
      problemMessage: "Can't have modifier '{0}' in an extension type.",
      correctionMessage: "Try removing '{0}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extraneous_modifier_in_extension_type',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode extraneousModifierInPrimaryConstructor =
    DiagnosticCodeWithExpectedTypes(
      name: 'extraneous_modifier_in_primary_constructor',
      problemMessage: "Can't have modifier '{0}' in a primary constructor.",
      correctionMessage: "Try removing '{0}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'extraneous_modifier_in_primary_constructor',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// int expected: the maximum number of positional arguments
/// int found: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int expected, required int found})
>
extraPositionalArguments = DiagnosticWithArguments(
  name: 'extra_positional_arguments',
  problemMessage: "Too many positional arguments: {0} expected, but {1} found.",
  correctionMessage: "Try removing the extra arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extra_positional_arguments',
  withArguments: _withArgumentsExtraPositionalArguments,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// int expected: the maximum number of positional arguments
/// int found: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int expected, required int found})
>
extraPositionalArgumentsCouldBeNamed = DiagnosticWithArguments(
  name: 'extra_positional_arguments_could_be_named',
  problemMessage: "Too many positional arguments: {0} expected, but {1} found.",
  correctionMessage:
      "Try removing the extra positional arguments, or specifying the name "
      "for named arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'extra_positional_arguments_could_be_named',
  withArguments: _withArgumentsExtraPositionalArgumentsCouldBeNamed,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments extraSizeAnnotationCarray =
    DiagnosticWithoutArgumentsImpl(
      name: 'extra_size_annotation_carray',
      problemMessage: "'Array's must have exactly one 'Array' annotation.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'extra_size_annotation_carray',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryConstructorNewName =
    DiagnosticWithoutArgumentsImpl(
      name: 'factory_constructor_new_name',
      problemMessage: "Factory constructors can't be named 'new'.",
      correctionMessage:
          "Try removing the 'new' keyword or changing it to a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'factory_constructor_new_name',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryTopLevelDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'factory_top_level_declaration',
      problemMessage:
          "Top-level declarations can't be declared to be 'factory'.",
      correctionMessage: "Try removing the keyword 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'factory_top_level_declaration',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryWithInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'factory_with_initializers',
      problemMessage: "A 'factory' constructor can't have initializers.",
      correctionMessage:
          "Try removing the 'factory' keyword to make this a generative "
          "constructor, or removing the initializers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'factory_with_initializers',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments factoryWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'factory_without_body',
      problemMessage:
          "A non-redirecting 'factory' constructor must have a body.",
      correctionMessage: "Try adding a body to the constructor.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'factory_without_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments ffiNativeInvalidDuplicateDefaultAsset =
    DiagnosticWithoutArgumentsImpl(
      name: 'ffi_native_invalid_duplicate_default_asset',
      problemMessage:
          "There may be at most one @DefaultAsset annotation on a library.",
      correctionMessage: "Try removing the extra annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'ffi_native_invalid_duplicate_default_asset',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
ffiNativeInvalidMultipleAnnotations = DiagnosticWithoutArgumentsImpl(
  name: 'ffi_native_invalid_multiple_annotations',
  problemMessage:
      "Native functions and fields must have exactly one `@Native` annotation.",
  correctionMessage: "Try removing the extra annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ffi_native_invalid_multiple_annotations',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments ffiNativeMustBeExternal =
    DiagnosticWithoutArgumentsImpl(
      name: 'ffi_native_must_be_external',
      problemMessage: "Native functions must be declared external.",
      correctionMessage: "Add the `external` keyword to the function.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'ffi_native_must_be_external',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
ffiNativeOnlyClassesExtendingNativefieldwrapperclass1CanBePointer =
    DiagnosticWithoutArgumentsImpl(
      name:
          'ffi_native_only_classes_extending_nativefieldwrapperclass1_can_be_pointer',
      problemMessage:
          "Only classes extending NativeFieldWrapperClass1 can be passed as Pointer.",
      correctionMessage: "Pass as Handle instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'ffi_native_only_classes_extending_nativefieldwrapperclass1_can_be_pointer',
      expectedTypes: [],
    );

/// Parameters:
/// int expected: the expected number of parameters
/// int actual: the actual number of parameters
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int expected, required int actual})
>
ffiNativeUnexpectedNumberOfParameters = DiagnosticWithArguments(
  name: 'ffi_native_unexpected_number_of_parameters',
  problemMessage:
      "Unexpected number of Native annotation parameters. Expected {0} but has "
      "{1}.",
  correctionMessage: "Make sure parameters match the function annotated.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ffi_native_unexpected_number_of_parameters',
  withArguments: _withArgumentsFfiNativeUnexpectedNumberOfParameters,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// int expected: the expected number of parameters
/// int actual: the actual number of parameters
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int expected, required int actual})
>
ffiNativeUnexpectedNumberOfParametersWithReceiver = DiagnosticWithArguments(
  name: 'ffi_native_unexpected_number_of_parameters_with_receiver',
  problemMessage:
      "Unexpected number of Native annotation parameters. Expected {0} but has "
      "{1}. Native instance method annotation must have receiver as first "
      "argument.",
  correctionMessage:
      "Make sure parameters match the function annotated, including an extra "
      "first parameter for the receiver.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'ffi_native_unexpected_number_of_parameters_with_receiver',
  withArguments:
      _withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String name: the name of the field being initialized multiple times
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
fieldInitializedByMultipleInitializers = DiagnosticWithArguments(
  name: 'field_initialized_by_multiple_initializers',
  problemMessage:
      "The field '{0}' can't be initialized twice in the same constructor.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'field_initialized_by_multiple_initializers',
  withArguments: _withArgumentsFieldInitializedByMultipleInitializers,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializedInDeclarationAndInitializerOfPrimaryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name:
          'field_initialized_in_declaration_and_initializer_of_primary_constructor',
      problemMessage:
          "Fields can't be initialized in both the primary constructor and at their "
          "declaration.",
      correctionMessage: "Try removing one of the initializations.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'field_initialized_in_declaration_and_initializer_of_primary_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializedInDeclarationAndParameterOfPrimaryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name:
          'field_initialized_in_declaration_and_parameter_of_primary_constructor',
      problemMessage:
          "Fields can't be initialized in both the primary constructor parameter "
          "list and at their declaration.",
      correctionMessage: "Try removing one of the initializations.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'field_initialized_in_declaration_and_parameter_of_primary_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializedInInitializerAndDeclaration = DiagnosticWithoutArgumentsImpl(
  name: 'field_initialized_in_initializer_and_declaration',
  problemMessage:
      "Fields can't be initialized in the constructor if they are final and were "
      "already initialized at their declaration.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'field_initialized_in_initializer_and_declaration',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments fieldInitializedInParameterAndInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'field_initialized_in_parameter_and_initializer',
      problemMessage:
          "Fields can't be initialized in both the parameter list and the "
          "initializers.",
      correctionMessage: "Try removing one of the initializations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'field_initialized_in_parameter_and_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments fieldInitializedOutsideDeclaringClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'field_initialized_outside_declaring_class',
      problemMessage: "A field can only be initialized in its declaring class",
      correctionMessage:
          "Try passing a value into the superclass constructor, or moving the "
          "initialization into the constructor body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'field_initialized_outside_declaring_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
fieldInitializerFactoryConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'field_initializer_factory_constructor',
  problemMessage:
      "Initializing formal parameters can't be used in factory constructors.",
  correctionMessage: "Try using a normal parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'field_initializer_factory_constructor',
  expectedTypes: [],
);

/// Parameters:
/// Type initializerExpressionType: the name of the type of the initializer
///                                 expression
/// Type fieldType: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType initializerExpressionType,
    required DartType fieldType,
  })
>
fieldInitializerNotAssignable = DiagnosticWithArguments(
  name: 'field_initializer_not_assignable',
  problemMessage:
      "The initializer type '{0}' can't be assigned to the field type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'field_initializer_not_assignable',
  withArguments: _withArgumentsFieldInitializerNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments fieldInitializerOutsideConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'field_initializer_outside_constructor',
      problemMessage:
          "Field formal parameters can only be used in a constructor.",
      correctionMessage: "Try removing 'this.'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'field_initializer_outside_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments fieldInitializerRedirectingConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'field_initializer_redirecting_constructor',
      problemMessage:
          "The redirecting constructor can't have a field initializer.",
      correctionMessage:
          "Try initializing the field in the constructor being redirected to.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'field_initializer_redirecting_constructor',
      expectedTypes: [],
    );

/// Parameters:
/// Type formalParameterType: the name of the type of the field formal
///                           parameter
/// Type fieldType: the name of the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType formalParameterType,
    required DartType fieldType,
  })
>
fieldInitializingFormalNotAssignable = DiagnosticWithArguments(
  name: 'field_initializing_formal_not_assignable',
  problemMessage:
      "The parameter type '{0}' is incompatible with the field type '{1}'.",
  correctionMessage:
      "Try changing or removing the parameter's type, or changing the "
      "field's type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'field_initializing_formal_not_assignable',
  withArguments: _withArgumentsFieldInitializingFormalNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments fieldMustBeExternalInStruct =
    DiagnosticWithoutArgumentsImpl(
      name: 'field_must_be_external_in_struct',
      problemMessage:
          "Fields of 'Struct' and 'Union' subclasses must be marked external.",
      correctionMessage: "Try adding the 'external' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'field_must_be_external_in_struct',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments finalAndCovariant =
    DiagnosticWithoutArgumentsImpl(
      name: 'final_and_covariant',
      problemMessage:
          "Members can't be declared to be both 'final' and 'covariant'.",
      correctionMessage:
          "Try removing either the 'final' or 'covariant' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'final_and_covariant',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
finalAndCovariantLateWithInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'final_and_covariant_late_with_initializer',
  problemMessage:
      "Members marked 'late' with an initializer can't be declared to be both "
      "'final' and 'covariant'.",
  correctionMessage:
      "Try removing either the 'final' or 'covariant' keyword, or removing "
      "the initializer.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'final_and_covariant_late_with_initializer',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalAndVar = DiagnosticWithoutArgumentsImpl(
  name: 'final_and_var',
  problemMessage: "Members can't be declared to be both 'final' and 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'final_and_var',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the final class being extended.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalClassExtendedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be extended outside of its library because it's a "
      "final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_class_extended_outside_of_library',
  withArguments: _withArgumentsFinalClassExtendedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the final class being implemented.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalClassImplementedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be implemented outside of its library because it's "
      "a final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_class_implemented_outside_of_library',
  withArguments: _withArgumentsFinalClassImplementedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the final class being used as a mixin superclass
///              constraint.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalClassUsedAsMixinConstraintOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be used as a mixin superclass constraint outside of "
      "its library because it's a final class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_class_used_as_mixin_constraint_outside_of_library',
  withArguments: _withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments finalConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'final_constructor',
      problemMessage: "A constructor can't be declared to be 'final'.",
      correctionMessage: "Try removing the keyword 'final'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'final_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments finalEnum = DiagnosticWithoutArgumentsImpl(
  name: 'final_enum',
  problemMessage: "Enums can't be declared to be 'final'.",
  correctionMessage: "Try removing the keyword 'final'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'final_enum',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the field in question
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalInitializedInDeclarationAndConstructor = DiagnosticWithArguments(
  name: 'final_initialized_in_declaration_and_constructor',
  problemMessage:
      "'{0}' is final and was given a value when it was declared, so it can't be "
      "set to a new value.",
  correctionMessage: "Try removing one of the initializations.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_initialized_in_declaration_and_constructor',
  withArguments: _withArgumentsFinalInitializedInDeclarationAndConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments finalMethod = DiagnosticWithoutArgumentsImpl(
  name: 'final_method',
  problemMessage:
      "Getters, setters and methods can't be declared to be 'final'.",
  correctionMessage: "Try removing the keyword 'final'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'final_method',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalMixin = DiagnosticWithoutArgumentsImpl(
  name: 'final_mixin',
  problemMessage: "A mixin can't be declared 'final'.",
  correctionMessage: "Try removing the 'final' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'final_mixin',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments finalMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'final_mixin_class',
      problemMessage: "A mixin class can't be declared 'final'.",
      correctionMessage: "Try removing the 'final' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'final_mixin_class',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalNotInitialized = DiagnosticWithArguments(
  name: 'final_not_initialized',
  problemMessage: "The final variable '{0}' must be initialized.",
  correctionMessage: "Try initializing the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_not_initialized',
  withArguments: _withArgumentsFinalNotInitialized,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
finalNotInitializedConstructor1 = DiagnosticWithArguments(
  name: 'final_not_initialized_constructor',
  problemMessage: "All final variables must be initialized, but '{0}' isn't.",
  correctionMessage: "Try adding an initializer for the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_not_initialized_constructor_1',
  withArguments: _withArgumentsFinalNotInitializedConstructor1,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name1: the name of the first uninitialized final variable
/// String name2: the name of the second uninitialized final variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name1, required String name2})
>
finalNotInitializedConstructor2 = DiagnosticWithArguments(
  name: 'final_not_initialized_constructor',
  problemMessage:
      "All final variables must be initialized, but '{0}' and '{1}' aren't.",
  correctionMessage: "Try adding initializers for the fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_not_initialized_constructor_2',
  withArguments: _withArgumentsFinalNotInitializedConstructor2,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name1: the name of the first uninitialized final variable
/// String name2: the name of the second uninitialized final variable
/// int remainingCount: the number of additional not initialized variables
///                     that aren't listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name1,
    required String name2,
    required int remainingCount,
  })
>
finalNotInitializedConstructor3Plus = DiagnosticWithArguments(
  name: 'final_not_initialized_constructor',
  problemMessage:
      "All final variables must be initialized, but '{0}', '{1}', and {2} others "
      "aren't.",
  correctionMessage: "Try adding initializers for the fields.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'final_not_initialized_constructor_3_plus',
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
  name: 'fixme',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'fixme',
  withArguments: _withArgumentsFixme,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments flutterFieldNotMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'flutter_field_not_map',
      problemMessage:
          "The value of the 'flutter' field is expected to be a map.",
      correctionMessage: "Try converting the value to be a map.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'flutter_field_not_map',
      expectedTypes: [],
    );

/// Parameters:
/// Type iterableType: the type of the iterable expression.
/// String expectedTypeName: the sequence type -- Iterable for `for` or Stream
///                          for `await for`.
/// Type loopVariableType: the loop variable type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType iterableType,
    required String expectedTypeName,
    required DartType loopVariableType,
  })
>
forInOfInvalidElementType = DiagnosticWithArguments(
  name: 'for_in_of_invalid_element_type',
  problemMessage:
      "The type '{0}' used in the 'for' loop must implement '{1}' with a type "
      "argument that can be assigned to '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'for_in_of_invalid_element_type',
  withArguments: _withArgumentsForInOfInvalidElementType,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// Type expressionType: the type of the iterable expression.
/// String expectedType: the sequence type -- Iterable for `for` or Stream for
///                      `await for`.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType expressionType,
    required String expectedType,
  })
>
forInOfInvalidType = DiagnosticWithArguments(
  name: 'for_in_of_invalid_type',
  problemMessage: "The type '{0}' used in the 'for' loop must implement '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'for_in_of_invalid_type',
  withArguments: _withArgumentsForInOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments forInWithConstVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'for_in_with_const_variable',
      problemMessage: "A for-in loop variable can't be a 'const'.",
      correctionMessage:
          "Try removing the 'const' modifier from the variable, or use a "
          "different variable.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'for_in_with_const_variable',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
functionTypedParameterVar = DiagnosticWithoutArgumentsImpl(
  name: 'function_typed_parameter_var',
  problemMessage:
      "Function-typed parameters can't specify 'const', 'final' or 'var' in "
      "place of a return type.",
  correctionMessage: "Try replacing the keyword with a return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'function_typed_parameter_var',
  expectedTypes: [],
);

/// It is a compile-time error if a generic function type is used as a bound
/// for a formal type parameter of a class or a function.
///
/// No parameters.
const DiagnosticWithoutArguments
genericFunctionTypeCannotBeBound = DiagnosticWithoutArgumentsImpl(
  name: 'generic_function_type_cannot_be_bound',
  problemMessage:
      "Generic function types can't be used as type parameter bounds.",
  correctionMessage:
      "Try making the free variable in the function type part of the larger "
      "declaration signature.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'generic_function_type_cannot_be_bound',
  expectedTypes: [],
);

/// It is a compile-time error if a generic function type is used as an actual
/// type argument.
///
/// No parameters.
const DiagnosticWithoutArguments
genericFunctionTypeCannotBeTypeArgument = DiagnosticWithoutArgumentsImpl(
  name: 'generic_function_type_cannot_be_type_argument',
  problemMessage: "A generic function type can't be a type argument.",
  correctionMessage:
      "Try removing type parameters from the generic function type, or using "
      "'dynamic' as the type argument here.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'generic_function_type_cannot_be_type_argument',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
genericMethodTypeInstantiationOnDynamic = DiagnosticWithoutArgumentsImpl(
  name: 'generic_method_type_instantiation_on_dynamic',
  problemMessage:
      "A method tear-off on a receiver whose type is 'dynamic' can't have type "
      "arguments.",
  correctionMessage:
      "Specify the type of the receiver, or remove the type arguments from "
      "the method tear-off.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'generic_method_type_instantiation_on_dynamic',
  expectedTypes: [],
);

/// Parameters:
/// String className: the name of the struct class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
genericStructSubclass = DiagnosticWithArguments(
  name: 'generic_struct_subclass',
  problemMessage:
      "The class '{0}' can't extend 'Struct' or 'Union' because '{0}' is "
      "generic.",
  correctionMessage: "Try removing the type parameters from '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'generic_struct_subclass',
  withArguments: _withArgumentsGenericStructSubclass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments getterConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'getter_constructor',
      problemMessage: "Constructors can't be a getter.",
      correctionMessage: "Try removing 'get'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'getter_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments getterInFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'getter_in_function',
      problemMessage: "Getters can't be defined within methods or functions.",
      correctionMessage:
          "Try moving the getter outside the method or function, or converting "
          "the getter to a function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'getter_in_function',
      expectedTypes: [],
    );

/// Parameters:
/// String getterName: the name of the getter
/// Type getterType: the type of the getter
/// Type setterType: the type of the setter
/// String setterName: the name of the setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String getterName,
    required DartType getterType,
    required DartType setterType,
    required String setterName,
  })
>
getterNotSubtypeSetterTypes = DiagnosticWithArguments(
  name: 'getter_not_subtype_setter_types',
  problemMessage:
      "The return type of getter '{0}' is '{1}' which isn't a subtype of the "
      "type '{2}' of its setter '{3}'.",
  correctionMessage: "Try changing the types so that they are compatible.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'getter_not_subtype_setter_types',
  withArguments: _withArgumentsGetterNotSubtypeSetterTypes,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.type,
    ExpectedType.type,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments getterWithParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'getter_with_parameters',
      problemMessage: "Getters must be declared without a parameter list.",
      correctionMessage:
          "Try removing the parameter list, or removing the keyword 'get' to "
          "define a method rather than a getter.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'getter_with_parameters',
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
  name: 'hack',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'hack',
  withArguments: _withArgumentsHack,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
ifElementConditionFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'if_element_condition_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as values in an if "
      "condition inside a const collection literal.",
  correctionMessage: "Try making the deferred import non-deferred.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'if_element_condition_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments illegalAssignmentToNonAssignable =
    DiagnosticWithoutArgumentsImpl(
      name: 'illegal_assignment_to_non_assignable',
      problemMessage: "Illegal assignment to non-assignable expression.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'illegal_assignment_to_non_assignable',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
illegalAsyncGeneratorReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'illegal_async_generator_return_type',
  problemMessage:
      "Functions marked 'async*' must have a return type that is a supertype of "
      "'Stream<T>' for some type 'T'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'async*' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_async_generator_return_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
illegalAsyncReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'illegal_async_return_type',
  problemMessage:
      "Functions marked 'async' must have a return type which is a supertype of "
      "'Future'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'async' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_async_return_type',
  expectedTypes: [],
);

/// Parameters:
/// int codePoint: the illegal character
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int codePoint})
>
illegalCharacter = DiagnosticWithArguments(
  name: 'illegal_character',
  problemMessage: "Illegal character '{0}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'illegal_character',
  withArguments: _withArgumentsIllegalCharacter,
  expectedTypes: [ExpectedType.int],
);

/// Parameters:
/// String name: the name of member that cannot be declared
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
illegalConcreteEnumMemberDeclaration = DiagnosticWithArguments(
  name: 'illegal_concrete_enum_member',
  problemMessage:
      "A concrete instance member named '{0}' can't be declared in a class that "
      "implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_concrete_enum_member_declaration',
  withArguments: _withArgumentsIllegalConcreteEnumMemberDeclaration,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of member that cannot be inherited
/// String className: the name of the class that declares the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String className,
  })
>
illegalConcreteEnumMemberInheritance = DiagnosticWithArguments(
  name: 'illegal_concrete_enum_member',
  problemMessage:
      "A concrete instance member named '{0}' can't be inherited from '{1}' in a "
      "class that implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_concrete_enum_member_inheritance',
  withArguments: _withArgumentsIllegalConcreteEnumMemberInheritance,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments illegalEnumValuesDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'illegal_enum_values',
      problemMessage:
          "An instance member named 'values' can't be declared in a class that "
          "implements 'Enum'.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'illegal_enum_values_declaration',
      expectedTypes: [],
    );

/// Parameters:
/// String className: the name of the class that declares 'values'
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
illegalEnumValuesInheritance = DiagnosticWithArguments(
  name: 'illegal_enum_values',
  problemMessage:
      "An instance member named 'values' can't be inherited from '{0}' in a "
      "class that implements 'Enum'.",
  correctionMessage: "Try using a different name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_enum_values_inheritance',
  withArguments: _withArgumentsIllegalEnumValuesInheritance,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String requiredVersion: the required language version
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String requiredVersion})
>
illegalLanguageVersionOverride = DiagnosticWithArguments(
  name: 'illegal_language_version_override',
  problemMessage: "The language version must be {0}.",
  correctionMessage:
      "Try removing the language version override and migrating the code.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_language_version_override',
  withArguments: _withArgumentsIllegalLanguageVersionOverride,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token variableName: The name that can't be used as the name of a variable
///                     assigned by a pattern assignment.
const DiagnosticCode illegalPatternAssignmentVariableName =
    DiagnosticCodeWithExpectedTypes(
      name: 'illegal_pattern_assignment_variable_name',
      problemMessage:
          "A variable assigned by a pattern assignment can't be named '{0}'.",
      correctionMessage: "Choose a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'illegal_pattern_assignment_variable_name',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token identifier: The identifier that can't be referred to.
const DiagnosticCode illegalPatternIdentifierName =
    DiagnosticCodeWithExpectedTypes(
      name: 'illegal_pattern_identifier_name',
      problemMessage: "A pattern can't refer to an identifier named '{0}'.",
      correctionMessage: "Match the identifier using '==",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'illegal_pattern_identifier_name',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// 0: the illegal name
///
/// Parameters:
/// Token variableName: The name that can't be used as a pattern variable
///                     name.
const DiagnosticCode illegalPatternVariableName =
    DiagnosticCodeWithExpectedTypes(
      name: 'illegal_pattern_variable_name',
      problemMessage:
          "The variable declared by a variable pattern can't be named '{0}'.",
      correctionMessage: "Choose a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'illegal_pattern_variable_name',
      expectedTypes: [ExpectedType.token],
    );

/// No parameters.
const DiagnosticWithoutArguments
illegalSyncGeneratorReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'illegal_sync_generator_return_type',
  problemMessage:
      "Functions marked 'sync*' must have a return type that is a supertype of "
      "'Iterable<T>' for some type 'T'.",
  correctionMessage:
      "Try fixing the return type of the function, or removing the modifier "
      "'sync*' from the function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'illegal_sync_generator_return_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'implements_before_extends',
      problemMessage:
          "The extends clause must be before the implements clause.",
      correctionMessage:
          "Try moving the extends clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'implements_before_extends',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeOn =
    DiagnosticWithoutArgumentsImpl(
      name: 'implements_before_on',
      problemMessage: "The on clause must be before the implements clause.",
      correctionMessage:
          "Try moving the on clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'implements_before_on',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsBeforeWith =
    DiagnosticWithoutArgumentsImpl(
      name: 'implements_before_with',
      problemMessage: "The with clause must be before the implements clause.",
      correctionMessage:
          "Try moving the with clause before the implements clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'implements_before_with',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments implementsDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'subtype_of_deferred_class',
      problemMessage: "Classes and mixins can't implement deferred classes.",
      correctionMessage:
          "Try specifying a different interface, removing the class from the "
          "list, or changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'implements_deferred_class',
      expectedTypes: [],
    );

/// Parameters:
/// Type disallowedType: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType disallowedType})
>
implementsDisallowedClass = DiagnosticWithArguments(
  name: 'subtype_of_disallowed_type',
  problemMessage: "Classes and mixins can't implement '{0}'.",
  correctionMessage:
      "Try specifying a different interface, or remove the class from the "
      "list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'implements_disallowed_class',
  withArguments: _withArgumentsImplementsDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments implementsNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'implements_non_class',
      problemMessage:
          "Classes and mixins can only implement other classes and mixins.",
      correctionMessage:
          "Try specifying a class or mixin, or remove the name from the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'implements_non_class',
      expectedTypes: [],
    );

/// Parameters:
/// String interfaceName: the name of the interface that is implemented more
///                       than once
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String interfaceName})
>
implementsRepeated = DiagnosticWithArguments(
  name: 'implements_repeated',
  problemMessage: "'{0}' can only be implemented once.",
  correctionMessage: "Try removing all but one occurrence of the class name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'implements_repeated',
  withArguments: _withArgumentsImplementsRepeated,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Element superElement: the name of the class that appears in both "extends"
///                       and "implements" clauses
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element superElement})
>
implementsSuperClass = DiagnosticWithArguments(
  name: 'implements_super_class',
  problemMessage:
      "'{0}' can't be used in both the 'extends' and 'implements' clauses.",
  correctionMessage: "Try removing one of the occurrences.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'implements_super_class',
  withArguments: _withArgumentsImplementsSuperClass,
  expectedTypes: [ExpectedType.element],
);

/// No parameters.
const DiagnosticWithoutArguments implementsTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'supertype_expands_to_type_parameter',
      problemMessage:
          "A type alias that expands to a type parameter can't be implemented.",
      correctionMessage:
          "Try specifying a class or mixin, or removing the list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'implements_type_alias_expands_to_type_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// Type superType: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType superType})
>
implicitSuperInitializerMissingArguments = DiagnosticWithArguments(
  name: 'implicit_super_initializer_missing_arguments',
  problemMessage:
      "The implicitly invoked unnamed constructor from '{0}' has required "
      "parameters.",
  correctionMessage:
      "Try adding an explicit super parameter with the required arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'implicit_super_initializer_missing_arguments',
  withArguments: _withArgumentsImplicitSuperInitializerMissingArguments,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// String memberName: the name of the instance member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String memberName})
>
implicitThisReferenceInInitializer = DiagnosticWithArguments(
  name: 'implicit_this_reference_in_initializer',
  problemMessage:
      "The instance member '{0}' can't be accessed in an initializer.",
  correctionMessage:
      "Try replacing the reference to the instance member with a different "
      "expression",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'implicit_this_reference_in_initializer',
  withArguments: _withArgumentsImplicitThisReferenceInInitializer,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
importDeferredLibraryWithLoadFunction = DiagnosticWithoutArgumentsImpl(
  name: 'import_deferred_library_with_load_function',
  problemMessage:
      "The imported library defines a top-level function named 'loadLibrary' "
      "that is hidden by deferring this library.",
  correctionMessage:
      "Try changing the import to not be deferred, or rename the function in "
      "the imported library.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'import_deferred_library_with_load_function',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments importDirectiveAfterPartDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'import_directive_after_part_directive',
      problemMessage: "Import directives must precede part directives.",
      correctionMessage:
          "Try moving the import directives before the part directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'import_directive_after_part_directive',
      expectedTypes: [],
    );

/// Parameters:
/// String uri: the URI pointing to a library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uri})
>
importInternalLibrary = DiagnosticWithArguments(
  name: 'import_internal_library',
  problemMessage: "The library '{0}' is internal and can't be imported.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'import_internal_library',
  withArguments: _withArgumentsImportInternalLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String uri: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uri})
>
importOfNonLibrary = DiagnosticWithArguments(
  name: 'import_of_non_library',
  problemMessage: "The imported library '{0}' can't have a part-of directive.",
  correctionMessage: "Try importing the library that the part is a part of.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'import_of_non_library',
  withArguments: _withArgumentsImportOfNonLibrary,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating that there is a syntactic error in the included
/// file.
///
/// Parameters:
/// String includingFilePath: the path of the file containing the error
/// int startOffset: the starting offset of the text in the file that contains
///                  the error
/// int endOffset: the ending offset of the text in the file that contains the
///                error
/// String errorMessage: the error message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String includingFilePath,
    required int startOffset,
    required int endOffset,
    required String errorMessage,
  })
>
includedFileParseError = DiagnosticWithArguments(
  name: 'included_file_parse_error',
  problemMessage: "{3} in {0}({1}..{2})",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'included_file_parse_error',
  withArguments: _withArgumentsIncludedFileParseError,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.int,
    ExpectedType.int,
    ExpectedType.string,
  ],
);

/// An error code indicating a specified include file has a warning.
///
/// Parameters:
/// Object includingFilePath: the path of the file containing the warnings
/// int startOffset: the starting offset of the text in the file that contains
///                  the warning
/// int endOffset: the ending offset of the text in the file that contains the
///                warning
/// String warningMessage: the warning message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object includingFilePath,
    required int startOffset,
    required int endOffset,
    required String warningMessage,
  })
>
includedFileWarning = DiagnosticWithArguments(
  name: 'included_file_warning',
  problemMessage: "Warning in the included options file {0}({1}..{2}): {3}",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'included_file_warning',
  withArguments: _withArgumentsIncludedFileWarning,
  expectedTypes: [
    ExpectedType.object,
    ExpectedType.int,
    ExpectedType.int,
    ExpectedType.string,
  ],
);

/// An error code indicating a specified include file could not be found.
///
/// Parameters:
/// String includedUri: the URI of the file to be included
/// String includingFilePath: the path of the file containing the include
///                           directive
/// String contextRootPath: the path of the context being analyzed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String includedUri,
    required String includingFilePath,
    required String contextRootPath,
  })
>
includeFileNotFound = DiagnosticWithArguments(
  name: 'include_file_not_found',
  problemMessage:
      "The URI '{0}' included in '{1}' can't be found when analyzing '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'include_file_not_found',
  withArguments: _withArgumentsIncludeFileNotFound,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// An error code indicating an incompatible rule.
///
/// The incompatible rules must be included by context messages.
///
/// Parameters:
/// String ruleName: the rule name
/// String incompatibleRules: the incompatible rules
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String incompatibleRules,
  })
>
incompatibleLint = DiagnosticWithArguments(
  name: 'incompatible_lint',
  problemMessage: "The rule '{0}' is incompatible with '{1}'.",
  correctionMessage: "Try removing all but one of the incompatible rules.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'incompatible_lint',
  withArguments: _withArgumentsIncompatibleLint,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating an incompatible rule.
///
/// The files that enable the referenced rules must be included by context messages.
///
/// Parameters:
/// String ruleName: the rule name
/// String incompatibleRules: the incompatible rules
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String incompatibleRules,
  })
>
incompatibleLintFiles = DiagnosticWithArguments(
  name: 'incompatible_lint',
  problemMessage: "The rule '{0}' is incompatible with {1}.",
  correctionMessage:
      "Try locally disabling all but one of the conflicting rules or "
      "removing one of the incompatible files.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'incompatible_lint_files',
  withArguments: _withArgumentsIncompatibleLintFiles,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating an incompatible rule.
///
/// Parameters:
/// String ruleName: the rule name
/// String incompatibleRules: the incompatible rules
/// int numIncludingFiles: the number of files that include the incompatible
///                        rule
/// String pluralSuffix: plural suffix for the word "file"
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String incompatibleRules,
    required int numIncludingFiles,
    required String pluralSuffix,
  })
>
incompatibleLintIncluded = DiagnosticWithArguments(
  name: 'incompatible_lint',
  problemMessage:
      "The rule '{0}' is incompatible with {1}, which is included from {2} "
      "file{3}.",
  correctionMessage:
      "Try locally disabling all but one of the conflicting rules or "
      "removing one of the incompatible files.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'incompatible_lint_included',
  withArguments: _withArgumentsIncompatibleLintIncluded,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.int,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String name: the name of the instance member with inconsistent
///              inheritance.
/// String inheritedSignatures: the list of all inherited signatures for this
///                             member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required String inheritedSignatures,
  })
>
inconsistentInheritance = DiagnosticWithArguments(
  name: 'inconsistent_inheritance',
  problemMessage: "Superinterfaces don't have a valid override for '{0}': {1}.",
  correctionMessage:
      "Try adding an explicit override that is consistent with all of the "
      "inherited members.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'inconsistent_inheritance',
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
/// String memberName: the name of the instance member with inconsistent
///                    inheritance.
/// String getterInterface: the name of the superinterface that declares the
///                         name as a getter.
/// String methodInterface: the name of the superinterface that declares the
///                         name as a method.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String getterInterface,
    required String methodInterface,
  })
>
inconsistentInheritanceGetterAndMethod = DiagnosticWithArguments(
  name: 'inconsistent_inheritance_getter_and_method',
  problemMessage:
      "'{0}' is inherited as a getter (from '{1}') and also a method (from "
      "'{2}').",
  correctionMessage:
      "Try adjusting the supertypes of this class to remove the "
      "inconsistency.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'inconsistent_inheritance_getter_and_method',
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
      name: 'inconsistent_language_version_override',
      problemMessage:
          "Parts must have exactly the same language version override as the "
          "library.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'inconsistent_language_version_override',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
inconsistentPatternVariableLogicalOr = DiagnosticWithArguments(
  name: 'inconsistent_pattern_variable_logical_or',
  problemMessage:
      "The variable '{0}' has a different type and/or finality in this branch of "
      "the logical-or pattern.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "both branches.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'inconsistent_pattern_variable_logical_or',
  withArguments: _withArgumentsInconsistentPatternVariableLogicalOr,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, collection literal types must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String collection: the name of the collection
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String collection})
>
inferenceFailureOnCollectionLiteral = DiagnosticWithArguments(
  name: 'inference_failure_on_collection_literal',
  problemMessage: "The type argument(s) of '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_collection_literal',
  withArguments: _withArgumentsInferenceFailureOnCollectionLiteral,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in function invocations must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String function: the name of the function
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String function})
>
inferenceFailureOnFunctionInvocation = DiagnosticWithArguments(
  name: 'inference_failure_on_function_invocation',
  problemMessage:
      "The type argument(s) of the function '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_function_invocation',
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
/// String function: the name of the function or method whose return type
///                  can't be inferred
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String function})
>
inferenceFailureOnFunctionReturnType = DiagnosticWithArguments(
  name: 'inference_failure_on_function_return_type',
  problemMessage: "The return type of '{0}' can't be inferred.",
  correctionMessage: "Declare the return type of '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_function_return_type',
  withArguments: _withArgumentsInferenceFailureOnFunctionReturnType,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in function invocations must be
/// inferred via the context type, or have type arguments.
///
/// Parameters:
/// String function: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String function})
>
inferenceFailureOnGenericInvocation = DiagnosticWithArguments(
  name: 'inference_failure_on_generic_invocation',
  problemMessage:
      "The type argument(s) of the generic function type '{0}' can't be "
      "inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_generic_invocation',
  withArguments: _withArgumentsInferenceFailureOnGenericInvocation,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" is enabled, types in instance creation
/// (constructor calls) must be inferred via the context type, or have type
/// arguments.
///
/// Parameters:
/// String function: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String function})
>
inferenceFailureOnInstanceCreation = DiagnosticWithArguments(
  name: 'inference_failure_on_instance_creation',
  problemMessage:
      "The type argument(s) of the constructor '{0}' can't be inferred.",
  correctionMessage: "Use explicit type argument(s) for '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_instance_creation',
  withArguments: _withArgumentsInferenceFailureOnInstanceCreation,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" in enabled, uninitialized variables must be
/// declared with a specific type.
///
/// Parameters:
/// String variable: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String variable})
>
inferenceFailureOnUninitializedVariable = DiagnosticWithArguments(
  name: 'inference_failure_on_uninitialized_variable',
  problemMessage:
      "The type of '{0}' can't be inferred without either a type or initializer.",
  correctionMessage: "Try specifying the type of the variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_uninitialized_variable',
  withArguments: _withArgumentsInferenceFailureOnUninitializedVariable,
  expectedTypes: [ExpectedType.string],
);

/// When "strict-inference" in enabled, function parameters must be
/// declared with a specific type, or inherit a type.
///
/// Parameters:
/// String parameter: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String parameter})
>
inferenceFailureOnUntypedParameter = DiagnosticWithArguments(
  name: 'inference_failure_on_untyped_parameter',
  problemMessage:
      "The type of '{0}' can't be inferred; a type must be explicitly provided.",
  correctionMessage: "Try specifying the type of the parameter.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'inference_failure_on_untyped_parameter',
  withArguments: _withArgumentsInferenceFailureOnUntypedParameter,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments initializedVariableInForEach =
    DiagnosticWithoutArgumentsImpl(
      name: 'initialized_variable_in_for_each',
      problemMessage:
          "The loop variable in a for-each loop can't be initialized.",
      correctionMessage:
          "Try removing the initializer, or using a different kind of loop.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'initialized_variable_in_for_each',
      expectedTypes: [],
    );

/// Parameters:
/// String formalName: the name of the initializing formal that is not an
///                    instance variable in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String formalName})
>
initializerForNonExistentField = DiagnosticWithArguments(
  name: 'initializer_for_non_existent_field',
  problemMessage: "'{0}' isn't a field in the enclosing class.",
  correctionMessage:
      "Try correcting the name to match an existing field, or defining a "
      "field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'initializer_for_non_existent_field',
  withArguments: _withArgumentsInitializerForNonExistentField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String formalName: the name of the initializing formal that is a static
///                    variable in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String formalName})
>
initializerForStaticField = DiagnosticWithArguments(
  name: 'initializer_for_static_field',
  problemMessage:
      "'{0}' is a static field in the enclosing class. Fields initialized in a "
      "constructor can't be static.",
  correctionMessage: "Try removing the initialization.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'initializer_for_static_field',
  withArguments: _withArgumentsInitializerForStaticField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String formalName: the name of the initializing formal that is not an
///                    instance variable in the immediately enclosing class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String formalName})
>
initializingFormalForNonExistentField = DiagnosticWithArguments(
  name: 'initializing_formal_for_non_existent_field',
  problemMessage: "'{0}' isn't a field in the enclosing class.",
  correctionMessage:
      "Try correcting the name to match an existing field, or defining a "
      "field named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'initializing_formal_for_non_existent_field',
  withArguments: _withArgumentsInitializingFormalForNonExistentField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of the static member
/// String memberKind: the kind of the static member (field, getter, setter,
///                    or method)
/// String enclosingElementName: the name of the static member's enclosing
///                              element
/// String enclosingElementKind: the kind of the static member's enclosing
///                              element (class, mixin, or extension)
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String memberKind,
    required String enclosingElementName,
    required String enclosingElementKind,
  })
>
instanceAccessToStaticMember = DiagnosticWithArguments(
  name: 'instance_access_to_static_member',
  problemMessage: "The static {1} '{0}' can't be accessed through an instance.",
  correctionMessage: "Try using the {3} '{2}' to access the {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'instance_access_to_static_member',
  withArguments: _withArgumentsInstanceAccessToStaticMember,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String name: the name of the static member
/// String kind: the kind of the static member (field, getter, setter, or
///              method)
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name, required String kind})
>
instanceAccessToStaticMemberOfUnnamedExtension = DiagnosticWithArguments(
  name: 'instance_access_to_static_member',
  problemMessage: "The static {1} '{0}' can't be accessed through an instance.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'instance_access_to_static_member_of_unnamed_extension',
  withArguments: _withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments instanceMemberAccessFromFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'instance_member_access_from_factory',
      problemMessage:
          "Instance members can't be accessed from a factory constructor.",
      correctionMessage: "Try removing the reference to the instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'instance_member_access_from_factory',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instanceMemberAccessFromStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'instance_member_access_from_static',
      problemMessage:
          "Instance members can't be accessed from a static method.",
      correctionMessage:
          "Try removing the reference to the instance member, or removing the "
          "keyword 'static' from the method.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'instance_member_access_from_static',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instantiateAbstractClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'instantiate_abstract_class',
      problemMessage: "Abstract classes can't be instantiated.",
      correctionMessage: "Try creating an instance of a concrete subtype.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'instantiate_abstract_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instantiateEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'instantiate_enum',
      problemMessage: "Enums can't be instantiated.",
      correctionMessage: "Try using one of the defined constants.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'instantiate_enum',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments instantiateTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'instantiate_type_alias_expands_to_type_parameter',
      problemMessage:
          "Type aliases that expand to a type parameter can't be instantiated.",
      correctionMessage: "Try replacing it with a class.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'instantiate_type_alias_expands_to_type_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// String literal: the lexeme of the integer
/// String closestDouble: the closest valid double
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String literal,
    required String closestDouble,
  })
>
integerLiteralImpreciseAsDouble = DiagnosticWithArguments(
  name: 'integer_literal_imprecise_as_double',
  problemMessage:
      "The integer literal is being used as a double, but can't be represented "
      "as a 64-bit double without overflow or loss of precision: '{0}'.",
  correctionMessage:
      "Try using the class 'BigInt', or switch to the closest valid double: "
      "'{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'integer_literal_imprecise_as_double',
  withArguments: _withArgumentsIntegerLiteralImpreciseAsDouble,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String literal: the value of the literal
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String literal})
>
integerLiteralOutOfRange = DiagnosticWithArguments(
  name: 'integer_literal_out_of_range',
  problemMessage: "The integer literal {0} can't be represented in 64 bits.",
  correctionMessage:
      "Try using the 'BigInt' class if you need an integer larger than "
      "9,223,372,036,854,775,807 or less than -9,223,372,036,854,775,808.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'integer_literal_out_of_range',
  withArguments: _withArgumentsIntegerLiteralOutOfRange,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the interface class being extended.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
interfaceClassExtendedOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be extended outside of its library because it's an "
      "interface class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'interface_class_extended_outside_of_library',
  withArguments: _withArgumentsInterfaceClassExtendedOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments interfaceEnum = DiagnosticWithoutArgumentsImpl(
  name: 'interface_enum',
  problemMessage: "Enums can't be declared to be 'interface'.",
  correctionMessage: "Try removing the keyword 'interface'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'interface_enum',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments interfaceMixin =
    DiagnosticWithoutArgumentsImpl(
      name: 'interface_mixin',
      problemMessage: "A mixin can't be declared 'interface'.",
      correctionMessage: "Try removing the 'interface' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'interface_mixin',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments interfaceMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'interface_mixin_class',
      problemMessage: "A mixin class can't be declared 'interface'.",
      correctionMessage: "Try removing the 'interface' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'interface_mixin_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_annotation',
  problemMessage:
      "Annotation must be either a const variable reference or const constructor "
      "invocation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotationConstantValueFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_annotation_constant_value_from_deferred_library',
      problemMessage:
          "Constant values from a deferred library can't be used in annotations.",
      correctionMessage:
          "Try moving the constant from the deferred library, or removing "
          "'deferred' from the import.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_annotation_constant_value_from_deferred_library',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidAnnotationFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_annotation_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as annotations.",
  correctionMessage:
      "Try removing the annotation, or changing the import to not be "
      "deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_annotation_from_deferred_library',
  expectedTypes: [],
);

/// Parameters:
/// String annotationName: the name of the annotation
/// String validTargets: the list of valid targets
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String annotationName,
    required String validTargets,
  })
>
invalidAnnotationTarget = DiagnosticWithArguments(
  name: 'invalid_annotation_target',
  problemMessage: "The annotation '{0}' can only be used on {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_annotation_target',
  withArguments: _withArgumentsInvalidAnnotationTarget,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type actualStaticType: the name of the right hand side type
/// Type expectedStaticType: the name of the left hand side type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualStaticType,
    required DartType expectedStaticType,
  })
>
invalidAssignment = DiagnosticWithArguments(
  name: 'invalid_assignment',
  problemMessage:
      "A value of type '{0}' can't be assigned to a variable of type '{1}'.",
  correctionMessage:
      "Try changing the type of the variable, or casting the right-hand type "
      "to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_assignment',
  withArguments: _withArgumentsInvalidAssignment,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments invalidAwaitInFor =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_await_in_for',
      problemMessage:
          "The keyword 'await' isn't allowed for a normal 'for' statement.",
      correctionMessage:
          "Try removing the keyword, or use a for-each statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_await_in_for',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidAwaitNotRequiredAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_await_not_required_annotation',
      problemMessage:
          "The annotation 'awaitNotRequired' can only be applied to a "
          "Future-returning function, or a Future-typed field.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_await_not_required_annotation',
      expectedTypes: [],
    );

/// Parameters:
/// String escapeSequence: the invalid escape sequence
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String escapeSequence})
>
invalidCodePoint = DiagnosticWithArguments(
  name: 'invalid_code_point',
  problemMessage: "The escape sequence '{0}' isn't a valid code point.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_code_point',
  withArguments: _withArgumentsInvalidCodePoint,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidCommentReference = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_comment_reference',
  problemMessage:
      "Comment references should contain a possibly prefixed identifier and can "
      "start with 'new', but shouldn't contain anything else.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_comment_reference',
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
      name: 'invalid_constant',
      problemMessage: "Invalid constant value.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_constant',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstantConstPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_constant_const_prefix',
  problemMessage:
      "The expression can't be prefixed by 'const' to form a constant pattern.",
  correctionMessage: "Try wrapping the expression in 'const ( ... )' instead.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_constant_const_prefix',
  expectedTypes: [],
);

/// Parameters:
/// Name operatorName: The name of the unsupported operator.
const DiagnosticCode invalidConstantPatternBinary =
    DiagnosticCodeWithExpectedTypes(
      name: 'invalid_constant_pattern_binary',
      problemMessage:
          "The binary operator {0} is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_constant_pattern_binary',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternDuplicateConst =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_constant_pattern_duplicate_const',
      problemMessage: "Duplicate 'const' keyword in constant expression.",
      correctionMessage: "Try removing one of the 'const' keywords.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_constant_pattern_duplicate_const',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternEmptyRecordLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_constant_pattern_empty_record_literal',
      problemMessage:
          "The empty record literal is not supported as a constant pattern.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_constant_pattern_empty_record_literal',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidConstantPatternGeneric =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_constant_pattern_generic',
      problemMessage: "This expression is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_constant_pattern_generic',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstantPatternNegation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_constant_pattern_negation',
  problemMessage:
      "Only negation of a numeric literal is supported as a constant pattern.",
  correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_constant_pattern_negation',
  expectedTypes: [],
);

/// Parameters:
/// Name operatorName: The name of the unsupported operator.
const DiagnosticCode invalidConstantPatternUnary =
    DiagnosticCodeWithExpectedTypes(
      name: 'invalid_constant_pattern_unary',
      problemMessage:
          "The unary operator {0} is not supported as a constant pattern.",
      correctionMessage: "Try wrapping the expression in 'const ( ... )'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_constant_pattern_unary',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidConstructorName = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_constructor_name',
  problemMessage:
      "The name of a constructor must match the name of the enclosing class.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_constructor_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidCovariantModifierInPrimaryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_covariant_modifier_in_primary_constructor',
      problemMessage:
          "The 'covariant' modifier can only be used on non-final declaring "
          "parameters.",
      correctionMessage: "Try removing 'covariant'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_covariant_modifier_in_primary_constructor',
      expectedTypes: [],
    );

/// Parameters:
/// String kind: the kind of dependency.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String kind})
>
invalidDependency = DiagnosticWithArguments(
  name: 'invalid_dependency',
  problemMessage: "Publishable packages can't have '{0}' dependencies.",
  correctionMessage:
      "Try adding a 'publish_to: none' entry to mark the package as not for "
      "publishing or remove the {0} dependency.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_dependency',
  withArguments: _withArgumentsInvalidDependency,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedExtendAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_deprecated_extend_annotation',
  problemMessage:
      "The annotation '@Deprecated.extend' can only be applied to extendable "
      "classes.",
  correctionMessage: "Try removing the '@Deprecated.extend' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_deprecated_extend_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidDeprecatedImplementAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_deprecated_implement_annotation',
      problemMessage:
          "The annotation '@Deprecated.implement' can only be applied to "
          "implementable classes.",
      correctionMessage: "Try removing the '@Deprecated.implement' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_deprecated_implement_annotation',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedInstantiateAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_deprecated_instantiate_annotation',
  problemMessage:
      "The annotation '@Deprecated.instantiate' can only be applied to classes.",
  correctionMessage: "Try removing the '@Deprecated.instantiate' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_deprecated_instantiate_annotation',
  expectedTypes: [],
);

/// This warning is generated anywhere where `@Deprecated.mixin` annotates
/// something other than a mixin class.
///
/// No parameters.
const DiagnosticWithoutArguments invalidDeprecatedMixinAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_deprecated_mixin_annotation',
      problemMessage:
          "The annotation '@Deprecated.mixin' can only be applied to classes.",
      correctionMessage: "Try removing the '@Deprecated.mixin' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_deprecated_mixin_annotation',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@Deprecated.optional`
/// annotates something other than an optional parameter.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedOptionalAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_deprecated_optional_annotation',
  problemMessage:
      "The annotation '@Deprecated.optional' can only be applied to optional "
      "parameters.",
  correctionMessage: "Try removing the '@Deprecated.optional' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_deprecated_optional_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidDeprecatedSubclassAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_deprecated_subclass_annotation',
  problemMessage:
      "The annotation '@Deprecated.subclass' can only be applied to subclassable "
      "classes and mixins.",
  correctionMessage: "Try removing the '@Deprecated.subclass' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_deprecated_subclass_annotation',
  expectedTypes: [],
);

/// Parameters:
/// String methodName: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String methodName})
>
invalidExceptionValue = DiagnosticWithArguments(
  name: 'invalid_exception_value',
  problemMessage:
      "The method {0} can't have an exceptional return value (the second "
      "argument) when the return type of the function is either 'void', "
      "'Handle' or 'Pointer'.",
  correctionMessage: "Try removing the exceptional return value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_exception_value',
  withArguments: _withArgumentsInvalidExceptionValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidExportOfInternalElement = DiagnosticWithArguments(
  name: 'invalid_export_of_internal_element',
  problemMessage:
      "The member '{0}' can't be exported as a part of a package's public API.",
  correctionMessage: "Try using a hide clause to hide '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_export_of_internal_element',
  withArguments: _withArgumentsInvalidExportOfInternalElement,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String internalElementName: the name of the internal element
/// String exportedElementName: the name of the exported element that
///                             indirectly exposes the internal element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String internalElementName,
    required String exportedElementName,
  })
>
invalidExportOfInternalElementIndirectly = DiagnosticWithArguments(
  name: 'invalid_export_of_internal_element_indirectly',
  problemMessage:
      "The member '{0}' can't be exported as a part of a package's public API, "
      "but is indirectly exported as part of the signature of '{1}'.",
  correctionMessage: "Try using a hide clause to hide '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_export_of_internal_element_indirectly',
  withArguments: _withArgumentsInvalidExportOfInternalElementIndirectly,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidExtensionArgumentCount = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_extension_argument_count',
  problemMessage:
      "Extension overrides must have exactly one argument: the value of 'this' "
      "in the extension method.",
  correctionMessage: "Try specifying exactly one argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_extension_argument_count',
  expectedTypes: [],
);

/// Parameters:
/// String name: The name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidFactoryMethodDecl = DiagnosticWithArguments(
  name: 'invalid_factory_method_decl',
  problemMessage: "Factory method '{0}' must have a return type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_factory_method_decl',
  withArguments: _withArgumentsInvalidFactoryMethodDecl,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidFactoryMethodImpl = DiagnosticWithArguments(
  name: 'invalid_factory_method_impl',
  problemMessage:
      "Factory method '{0}' doesn't return a newly allocated object.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_factory_method_impl',
  withArguments: _withArgumentsInvalidFactoryMethodImpl,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidFactoryNameNotAClass = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_factory_name_not_a_class',
  problemMessage:
      "The name of a factory constructor must be the same as the name of the "
      "immediately enclosing class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_factory_name_not_a_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidFieldNameFromObject =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_field_name',
      problemMessage:
          "Record field names can't be the same as a member from 'Object'.",
      correctionMessage: "Try using a different name for the field.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_field_name_from_object',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidFieldNamePositional = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_field_name',
  problemMessage:
      "Record field names can't be a dollar sign followed by an integer when the "
      "integer is the index of a positional field.",
  correctionMessage: "Try using a different name for the field.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_field_name_positional',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidFieldNamePrivate =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_field_name',
      problemMessage: "Record field names can't be private.",
      correctionMessage: "Try removing the leading underscore.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_field_name_private',
      expectedTypes: [],
    );

/// Parameters:
/// String type: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String type})
>
invalidFieldTypeInStruct = DiagnosticWithArguments(
  name: 'invalid_field_type_in_struct',
  problemMessage:
      "Fields in struct classes can't have the type '{0}'. They can only be "
      "declared as 'int', 'double', 'Array', 'Pointer', or subtype of "
      "'Struct' or 'Union'.",
  correctionMessage:
      "Try using 'int', 'double', 'Array', 'Pointer', or subtype of 'Struct' "
      "or 'Union'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_field_type_in_struct',
  withArguments: _withArgumentsInvalidFieldTypeInStruct,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidGenericFunctionType = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_generic_function_type',
  problemMessage: "Invalid generic function type.",
  correctionMessage:
      "Try using a generic function type (returnType 'Function(' parameters "
      "')').",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_generic_function_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidHexEscape = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_hex_escape',
  problemMessage:
      "An escape sequence starting with '\\x' must be followed by 2 hexadecimal "
      "digits.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_hex_escape',
  expectedTypes: [],
);

/// The parameters of this error code must be kept in sync with those of
/// [diag.invalidOverride].
///
/// Parameters:
/// String memberName: the name of the declared member that is not a valid
///                    override.
/// String declaringInterfaceName: the name of the interface that declares the
///                                member.
/// Type typeInDeclaringInterface: the type of the declared member in the
///                                interface.
/// String overriddenInterfaceName: the name of the interface with the
///                                 overridden member.
/// Type typeInOverriddenInterface: the type of the overridden member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String declaringInterfaceName,
    required DartType typeInDeclaringInterface,
    required String overriddenInterfaceName,
    required DartType typeInOverriddenInterface,
  })
>
invalidImplementationOverride = DiagnosticWithArguments(
  name: 'invalid_implementation_override',
  problemMessage:
      "'{1}.{0}' ('{2}') isn't a valid concrete implementation of '{3}.{0}' "
      "('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_implementation_override',
  withArguments: _withArgumentsInvalidImplementationOverride,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.type,
    ExpectedType.string,
    ExpectedType.type,
  ],
);

/// The parameters of this error code must be kept in sync with those of
/// [diag.invalidOverride].
///
/// Parameters:
/// String memberName: the name of the declared setter that is not a valid
///                    override.
/// String declaringInterfaceName: the name of the interface that declares the
///                                setter.
/// Type typeInDeclaringInterface: the type of the declared setter in the
///                                interface.
/// String overriddenInterfaceName: the name of the interface with the
///                                 overridden setter.
/// Type typeInOverriddenInterface: the type of the overridden setter.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String declaringInterfaceName,
    required DartType typeInDeclaringInterface,
    required String overriddenInterfaceName,
    required DartType typeInOverriddenInterface,
  })
>
invalidImplementationOverrideSetter = DiagnosticWithArguments(
  name: 'invalid_implementation_override',
  problemMessage:
      "The setter '{1}.{0}' ('{2}') isn't a valid concrete implementation of "
      "'{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_implementation_override_setter',
  withArguments: _withArgumentsInvalidImplementationOverrideSetter,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.type,
    ExpectedType.string,
    ExpectedType.type,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments invalidInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_initializer',
      problemMessage: "Not a valid initializer.",
      correctionMessage:
          "To initialize a field, use the syntax 'name = value'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidInlineFunctionType = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_inline_function_type',
  problemMessage:
      "Inline function types can't be used for parameters in a generic function "
      "type.",
  correctionMessage:
      "Try using a generic function type (returnType 'Function(' parameters "
      "')').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_inline_function_type',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidInsideUnaryPattern = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_inside_unary_pattern',
  problemMessage:
      "This pattern cannot appear inside a unary pattern (cast pattern, null "
      "check pattern, or null assert pattern) without parentheses.",
  correctionMessage:
      "Try combining into a single pattern if possible, or enclose the inner "
      "pattern in parentheses.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_inside_unary_pattern',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidInternalAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_internal_annotation',
  problemMessage:
      "Only public elements in a package's private API can be annotated as being "
      "internal.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_internal_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverrideAtSign =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_language_version_override',
      problemMessage:
          "The Dart language version override number must begin with '@dart'.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_language_version_override_at_sign',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideEquals = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_language_version_override',
  problemMessage:
      "The Dart language version override comment must be specified with an '=' "
      "character.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_language_version_override_equals',
  expectedTypes: [],
);

/// Parameters:
/// int latestMajor: the latest major version
/// int latestMinor: the latest minor version
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required int latestMajor,
    required int latestMinor,
  })
>
invalidLanguageVersionOverrideGreater = DiagnosticWithArguments(
  name: 'invalid_language_version_override',
  problemMessage:
      "The language version override can't specify a version greater than the "
      "latest known language version: {0}.{1}.",
  correctionMessage: "Try removing the language version override.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_language_version_override_greater',
  withArguments: _withArgumentsInvalidLanguageVersionOverrideGreater,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideLocation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_language_version_override',
  problemMessage:
      "The language version override must be specified before any declaration or "
      "directive.",
  correctionMessage:
      "Try moving the language version override to the top of the file.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_language_version_override_location',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideLowerCase = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_language_version_override',
  problemMessage:
      "The Dart language version override comment must be specified with the "
      "word 'dart' in all lower case.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_language_version_override_lower_case',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverrideNumber =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_language_version_override',
      problemMessage:
          "The Dart language version override comment must be specified with a "
          "version number, like '2.0', after the '=' character.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_language_version_override_number',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidLanguageVersionOverridePrefix =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_language_version_override',
      problemMessage:
          "The Dart language version override number can't be prefixed with a "
          "letter.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_language_version_override_prefix',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideTrailingCharacters =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_language_version_override',
      problemMessage:
          "The Dart language version override comment can't be followed by any "
          "non-whitespace characters.",
      correctionMessage:
          "Specify a Dart language version override with a comment like '// "
          "@dart = 2.0'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_language_version_override_trailing_characters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidLanguageVersionOverrideTwoSlashes = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_language_version_override',
  problemMessage:
      "The Dart language version override comment must be specified with exactly "
      "two slashes.",
  correctionMessage:
      "Specify a Dart language version override with a comment like '// "
      "@dart = 2.0'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_language_version_override_two_slashes',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidLiteralAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_literal_annotation',
      problemMessage:
          "Only const constructors can have the `@literal` annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_literal_annotation',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidLiteralInConfiguration =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_literal_in_configuration',
      problemMessage:
          "The literal in a configuration can't contain interpolation.",
      correctionMessage: "Try removing the interpolation expressions.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_literal_in_configuration',
      expectedTypes: [],
    );

/// Parameters:
/// String modifier: the invalid modifier
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String modifier})
>
invalidModifierOnConstructor = DiagnosticWithArguments(
  name: 'invalid_modifier_on_constructor',
  problemMessage:
      "The modifier '{0}' can't be applied to the body of a constructor.",
  correctionMessage: "Try removing the modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_modifier_on_constructor',
  withArguments: _withArgumentsInvalidModifierOnConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidModifierOnSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_modifier_on_setter',
      problemMessage: "Setters can't use 'async', 'async*', or 'sync*'.",
      correctionMessage: "Try removing the modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_modifier_on_setter',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@nonVirtual` annotates something
/// other than a non-abstract instance member in a class or mixin.
///
/// No parameters.
const DiagnosticWithoutArguments
invalidNonVirtualAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_non_virtual_annotation',
  problemMessage:
      "The annotation '@nonVirtual' can only be applied to a concrete instance "
      "member.",
  correctionMessage: "Try removing '@nonVirtual'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_non_virtual_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidNullAwareElement = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_null_aware_operator',
  problemMessage:
      "The element can't be null, so the null-aware operator '?' is unnecessary.",
  correctionMessage: "Try removing the operator '?'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_null_aware_element',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidNullAwareMapEntryKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_null_aware_operator',
      problemMessage:
          "The map entry key can't be null, so the null-aware operator '?' is "
          "unnecessary.",
      correctionMessage: "Try removing the operator '?'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_null_aware_map_entry_key',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidNullAwareMapEntryValue = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_null_aware_operator',
  problemMessage:
      "The map entry value can't be null, so the null-aware operator '?' is "
      "unnecessary.",
  correctionMessage: "Try removing the operator '?'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_null_aware_map_entry_value',
  expectedTypes: [],
);

/// Parameters:
/// String operator: the null-aware operator that is invalid
/// String replacement: the non-null-aware operator that can replace the
///                     invalid operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String operator,
    required String replacement,
  })
>
invalidNullAwareOperator = DiagnosticWithArguments(
  name: 'invalid_null_aware_operator',
  problemMessage:
      "The receiver can't be null, so the null-aware operator '{0}' is "
      "unnecessary.",
  correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_null_aware_operator',
  withArguments: _withArgumentsInvalidNullAwareOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String operator: the null-aware operator that is invalid
/// String replacement: the non-null-aware operator that can replace the
///                     invalid operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String operator,
    required String replacement,
  })
>
invalidNullAwareOperatorAfterShortCircuit = DiagnosticWithArguments(
  name: 'invalid_null_aware_operator',
  problemMessage:
      "The receiver can't be 'null' because of short-circuiting, so the "
      "null-aware operator '{0}' can't be used.",
  correctionMessage: "Try replacing the operator '{0}' with '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_null_aware_operator_after_short_circuit',
  withArguments: _withArgumentsInvalidNullAwareOperatorAfterShortCircuit,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// 0: the operator that is invalid
///
/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode invalidOperator = DiagnosticCodeWithExpectedTypes(
  name: 'invalid_operator',
  problemMessage: "The string '{0}' isn't a user-definable operator.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_operator',
  expectedTypes: [ExpectedType.token],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidOperatorQuestionmarkPeriodForSuper = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_operator_questionmark_period_for_super',
  problemMessage:
      "The operator '?.' cannot be used with 'super' because 'super' cannot be "
      "null.",
  correctionMessage: "Try replacing '?.' with '.'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_operator_questionmark_period_for_super',
  expectedTypes: [],
);

/// An error code indicating that a plugin is being configured with an invalid
/// value for an option and a detail message is provided.
///
/// Parameters:
/// String optionName: the option name
/// String detailMessage: the detail message
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String optionName,
    required String detailMessage,
  })
>
invalidOption = DiagnosticWithArguments(
  name: 'invalid_option',
  problemMessage: "Invalid option specified for '{0}': {1}",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_option',
  withArguments: _withArgumentsInvalidOption,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of the declared member that is not a valid
///                    override.
/// String declaringInterfaceName: the name of the interface that declares the
///                                member.
/// Type typeInDeclaringInterface: the type of the declared member in the
///                                interface.
/// String overriddenInterfaceName: the name of the interface with the
///                                 overridden member.
/// Type typeInOverriddenInterface: the type of the overridden member.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String declaringInterfaceName,
    required DartType typeInDeclaringInterface,
    required String overriddenInterfaceName,
    required DartType typeInOverriddenInterface,
  })
>
invalidOverride = DiagnosticWithArguments(
  name: 'invalid_override',
  problemMessage:
      "'{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_override',
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
/// String memberName: the name of the member
/// String definingClass: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String definingClass,
  })
>
invalidOverrideOfNonVirtualMember = DiagnosticWithArguments(
  name: 'invalid_override_of_non_virtual_member',
  problemMessage:
      "The member '{0}' is declared non-virtual in '{1}' and can't be overridden "
      "in subclasses.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_override_of_non_virtual_member',
  withArguments: _withArgumentsInvalidOverrideOfNonVirtualMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of the declared setter that is not a valid
///                    override.
/// String declaringInterfaceName: the name of the interface that declares the
///                                setter.
/// Type typeInDeclaringInterface: the type of the declared setter in the
///                                interface.
/// String overriddenInterfaceName: the name of the interface with the
///                                 overridden setter.
/// Type typeInOverriddenInterface: the type of the overridden setter.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String declaringInterfaceName,
    required DartType typeInDeclaringInterface,
    required String overriddenInterfaceName,
    required DartType typeInOverriddenInterface,
  })
>
invalidOverrideSetter = DiagnosticWithArguments(
  name: 'invalid_override',
  problemMessage:
      "The setter '{1}.{0}' ('{2}') isn't a valid override of '{3}.{0}' ('{4}').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_override_setter',
  withArguments: _withArgumentsInvalidOverrideSetter,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.type,
    ExpectedType.string,
    ExpectedType.type,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments invalidPlatformsField =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_platforms_field',
      problemMessage:
          "The 'platforms' field must be a map with platforms as keys.",
      correctionMessage:
          "Try changing the 'platforms' field to a map with platforms as keys.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_platforms_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidReferenceToGenerativeEnumConstructor = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_reference_to_generative_enum_constructor',
  problemMessage:
      "Generative enum constructors can only be used to create an enum constant.",
  correctionMessage: "Try using an enum value, or a factory constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_reference_to_generative_enum_constructor',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidReferenceToGenerativeEnumConstructorTearoff =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_reference_to_generative_enum_constructor',
      problemMessage: "Generative enum constructors can't be torn off.",
      correctionMessage: "Try using an enum value, or a factory constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_reference_to_generative_enum_constructor_tearoff',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidReferenceToThis =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_reference_to_this',
      problemMessage: "Invalid reference to 'this' expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_reference_to_this',
      expectedTypes: [],
    );

/// This warning is generated anywhere where `@reopen` annotates a class which
/// did not reopen any type.
///
/// No parameters.
const DiagnosticWithoutArguments invalidReopenAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_reopen_annotation',
      problemMessage:
          "The annotation '@reopen' can only be applied to a class that opens "
          "capabilities that the supertype intentionally disallows.",
      correctionMessage: "Try removing the '@reopen' annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'invalid_reopen_annotation',
      expectedTypes: [],
    );

/// An error code indicating an invalid format for an options file section.
///
/// Parameters:
/// String sectionName: the section name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String sectionName})
>
invalidSectionFormat = DiagnosticWithArguments(
  name: 'invalid_section_format',
  problemMessage: "Invalid format for the '{0}' section.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_section_format',
  withArguments: _withArgumentsInvalidSectionFormat,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidStarAfterAsync = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_star_after_async',
  problemMessage:
      "The modifier 'async*' isn't allowed for an expression function body.",
  correctionMessage: "Try converting the body to a block.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_star_after_async',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidSuperFormalParameterLocation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_super_formal_parameter_location',
  problemMessage:
      "Super parameters can only be used in non-redirecting generative "
      "constructors.",
  correctionMessage:
      "Try removing the 'super' modifier, or changing the constructor to be "
      "non-redirecting and generative.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_super_formal_parameter_location',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments invalidSuperInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_super_in_initializer',
      problemMessage:
          "Can only use 'super' in an initializer for calling the superclass "
          "constructor (e.g. 'super()' or 'super.namedConstructor()')",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_super_in_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidSync = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_sync',
  problemMessage:
      "The modifier 'sync' isn't allowed for an expression function body.",
  correctionMessage: "Try converting the body to a block.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_sync',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidThisInInitializer = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_this_in_initializer',
  problemMessage:
      "Can only use 'this' in an initializer for field initialization (e.g. "
      "'this.x = something') and constructor redirection (e.g. 'this()' or "
      "'this.namedConstructor())",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_this_in_initializer',
  expectedTypes: [],
);

/// Parameters:
/// String typeParameter: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameter})
>
invalidTypeArgumentInConstList = DiagnosticWithArguments(
  name: 'invalid_type_argument_in_const_literal',
  problemMessage:
      "Constant list literals can't use a type parameter in a type argument, "
      "such as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_type_argument_in_const_list',
  withArguments: _withArgumentsInvalidTypeArgumentInConstList,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameter: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameter})
>
invalidTypeArgumentInConstMap = DiagnosticWithArguments(
  name: 'invalid_type_argument_in_const_literal',
  problemMessage:
      "Constant map literals can't use a type parameter in a type argument, such "
      "as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_type_argument_in_const_map',
  withArguments: _withArgumentsInvalidTypeArgumentInConstMap,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String typeParameter: the name of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeParameter})
>
invalidTypeArgumentInConstSet = DiagnosticWithArguments(
  name: 'invalid_type_argument_in_const_literal',
  problemMessage:
      "Constant set literals can't use a type parameter in a type argument, such "
      "as '{0}'.",
  correctionMessage: "Try replacing the type parameter with a different type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_type_argument_in_const_set',
  withArguments: _withArgumentsInvalidTypeArgumentInConstSet,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidUnicodeEscapeStarted =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_unicode_escape_started',
      problemMessage: "The string '\\' can't stand alone.",
      correctionMessage:
          "Try adding another backslash (\\) to escape the '\\'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_unicode_escape_started',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments invalidUnicodeEscapeUBracket =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_unicode_escape_u_bracket',
      problemMessage:
          "An escape sequence starting with '\\u{' must be followed by 1 to 6 "
          "hexadecimal digits followed by a '}'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_unicode_escape_u_bracket',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
invalidUnicodeEscapeUNoBracket = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_unicode_escape_u_no_bracket',
  problemMessage:
      "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
      "digits.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_unicode_escape_u_no_bracket',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidUnicodeEscapeUStarted = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_unicode_escape_u_started',
  problemMessage:
      "An escape sequence starting with '\\u' must be followed by 4 hexadecimal "
      "digits or from 1 to 6 digits between '{' and '}'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_unicode_escape_u_started',
  expectedTypes: [],
);

/// Parameters:
/// String uri: the URI that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uri})
>
invalidUri = DiagnosticWithArguments(
  name: 'invalid_uri',
  problemMessage: "Invalid URI syntax: '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_uri',
  withArguments: _withArgumentsInvalidUri,
  expectedTypes: [ExpectedType.string],
);

/// The 'covariant' keyword was found in an inappropriate location.
///
/// No parameters.
const DiagnosticWithoutArguments invalidUseOfCovariant =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_use_of_covariant',
      problemMessage:
          "The 'covariant' keyword can only be used for parameters in instance "
          "methods or before non-final instance fields.",
      correctionMessage: "Try removing the 'covariant' keyword.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_use_of_covariant',
      expectedTypes: [],
    );

/// No parameters.
///
/// Parameters:
/// Token lexeme: The token that was found.
const DiagnosticCode invalidUseOfCovariantInExtension =
    DiagnosticCodeWithExpectedTypes(
      name: 'invalid_use_of_covariant_in_extension',
      problemMessage: "Can't have modifier '{0}' in an extension.",
      correctionMessage: "Try removing '{0}'.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'invalid_use_of_covariant_in_extension',
      expectedTypes: [ExpectedType.token],
    );

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidUseOfDoNotSubmitMember = DiagnosticWithArguments(
  name: 'invalid_use_of_do_not_submit_member',
  problemMessage: "Uses of '{0}' should not be submitted to source control.",
  correctionMessage: "Try removing the reference to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_do_not_submit_member',
  withArguments: _withArgumentsInvalidUseOfDoNotSubmitMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidUseOfIdentifierAugmented = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_use_of_identifier_augmented',
  problemMessage:
      "The identifier 'augmented' can only be used to reference the augmented "
      "declaration inside an augmentation.",
  correctionMessage: "Try using a different identifier.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'invalid_use_of_identifier_augmented',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidUseOfInternalMember = DiagnosticWithArguments(
  name: 'invalid_use_of_internal_member',
  problemMessage: "The member '{0}' can only be used within its package.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_internal_member',
  withArguments: _withArgumentsInvalidUseOfInternalMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments invalidUseOfNullValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'invalid_use_of_null_value',
      problemMessage:
          "An expression whose value is always 'null' can't be dereferenced.",
      correctionMessage: "Try changing the type of the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'invalid_use_of_null_value',
      expectedTypes: [],
    );

/// This warning is generated anywhere where a member annotated with
/// `@protected` is used outside of an instance member of a subclass.
///
/// Parameters:
/// String memberName: the name of the member
/// String definingClass: the name of the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String definingClass,
  })
>
invalidUseOfProtectedMember = DiagnosticWithArguments(
  name: 'invalid_use_of_protected_member',
  problemMessage:
      "The member '{0}' can only be used within instance members of subclasses "
      "of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_protected_member',
  withArguments: _withArgumentsInvalidUseOfProtectedMember,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invalidUseOfVisibleForOverridingMember = DiagnosticWithArguments(
  name: 'invalid_use_of_visible_for_overriding_member',
  problemMessage: "The member '{0}' can only be used for overriding.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_visible_for_overriding_member',
  withArguments: _withArgumentsInvalidUseOfVisibleForOverridingMember,
  expectedTypes: [ExpectedType.string],
);

/// This warning is generated anywhere where a member annotated with
/// `@visibleForTemplate` is used outside of a "template" Dart file.
///
/// Parameters:
/// String memberName: the name of the member
/// Uri uri: the uri of the file containing the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String memberName, required Uri uri})
>
invalidUseOfVisibleForTemplateMember = DiagnosticWithArguments(
  name: 'invalid_use_of_visible_for_template_member',
  problemMessage:
      "The member '{0}' can only be used within '{1}' or a template library.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_visible_for_template_member',
  withArguments: _withArgumentsInvalidUseOfVisibleForTemplateMember,
  expectedTypes: [ExpectedType.string, ExpectedType.uri],
);

/// This warning is generated anywhere where a member annotated with
/// `@visibleForTesting` is used outside the defining library, or a test.
///
/// Parameters:
/// String memberName: the name of the member
/// Uri uri: the uri of the file containing the defining class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String memberName, required Uri uri})
>
invalidUseOfVisibleForTestingMember = DiagnosticWithArguments(
  name: 'invalid_use_of_visible_for_testing_member',
  problemMessage: "The member '{0}' can only be used within '{1}' or a test.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_use_of_visible_for_testing_member',
  withArguments: _withArgumentsInvalidUseOfVisibleForTestingMember,
  expectedTypes: [ExpectedType.string, ExpectedType.uri],
);

/// This warning is generated anywhere where a private declaration is
/// annotated with `@visibleForTemplate` or `@visibleForTesting`.
///
/// Parameters:
/// String memberName: the name of the member
/// String annotationName: the name of the annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String annotationName,
  })
>
invalidVisibilityAnnotation = DiagnosticWithArguments(
  name: 'invalid_visibility_annotation',
  problemMessage:
      "The member '{0}' is annotated with '{1}', but this annotation is only "
      "meaningful on declarations of public members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_visibility_annotation',
  withArguments: _withArgumentsInvalidVisibilityAnnotation,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidVisibleOutsideTemplateAnnotation = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_visible_outside_template_annotation',
  problemMessage:
      "The annotation 'visibleOutsideTemplate' can only be applied to a member "
      "of a class, enum, or mixin that is annotated with "
      "'visibleForTemplate'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_visible_outside_template_annotation',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidWidgetPreviewApplication = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_widget_preview_application',
  problemMessage:
      "The '@Preview(...)' annotation can only be applied to public, statically "
      "accessible constructors and functions.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_widget_preview_application',
  expectedTypes: [],
);

/// Parameters:
/// String privateSymbolName: the name of the private symbol
/// String suggestedName: the name of the proposed public symbol equivalent
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String privateSymbolName,
    required String suggestedName,
  })
>
invalidWidgetPreviewPrivateArgument = DiagnosticWithArguments(
  name: 'invalid_widget_preview_private_argument',
  problemMessage:
      "'@Preview(...)' can only accept arguments that consist of literals and "
      "public symbols.",
  correctionMessage: "Rename private symbol '{0}' to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'invalid_widget_preview_private_argument',
  withArguments: _withArgumentsInvalidWidgetPreviewPrivateArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the extension
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invocationOfExtensionWithoutCall = DiagnosticWithArguments(
  name: 'invocation_of_extension_without_call',
  problemMessage:
      "The extension '{0}' doesn't define a 'call' method so the override can't "
      "be used in an invocation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invocation_of_extension_without_call',
  withArguments: _withArgumentsInvocationOfExtensionWithoutCall,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the identifier that is not a function type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
invocationOfNonFunction = DiagnosticWithArguments(
  name: 'invocation_of_non_function',
  problemMessage: "'{0}' isn't a function.",
  correctionMessage:
      "Try correcting the name to match an existing function, or define a "
      "method or function named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invocation_of_non_function',
  withArguments: _withArgumentsInvocationOfNonFunction,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invocationOfNonFunctionExpression = DiagnosticWithoutArgumentsImpl(
  name: 'invocation_of_non_function_expression',
  problemMessage:
      "The expression doesn't evaluate to a function, so it can't be invoked.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invocation_of_non_function_expression',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the unresolvable label
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
labelInOuterScope = DiagnosticWithArguments(
  name: 'label_in_outer_scope',
  problemMessage: "Can't reference label '{0}' declared in an outer method.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'label_in_outer_scope',
  withArguments: _withArgumentsLabelInOuterScope,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the unresolvable label
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
labelUndefined = DiagnosticWithArguments(
  name: 'label_undefined',
  problemMessage: "Can't reference an undefined label '{0}'.",
  correctionMessage:
      "Try defining the label, or correcting the name to match an existing "
      "label.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'label_undefined',
  withArguments: _withArgumentsLabelUndefined,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments lateFinalFieldWithConstConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'late_final_field_with_const_constructor',
      problemMessage:
          "Can't have a late final field in a class with a generative const "
          "constructor.",
      correctionMessage:
          "Try removing the 'late' modifier, or don't declare 'const' "
          "constructors.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'late_final_field_with_const_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments lateFinalLocalAlreadyAssigned =
    DiagnosticWithoutArgumentsImpl(
      name: 'late_final_local_already_assigned',
      problemMessage: "The late final local variable is already assigned.",
      correctionMessage:
          "Try removing the 'final' modifier, or don't reassign the value.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'late_final_local_already_assigned',
      expectedTypes: [],
    );

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments latePatternVariableDeclaration =
    DiagnosticWithoutArgumentsImpl(
      name: 'late_pattern_variable_declaration',
      problemMessage:
          "A pattern variable declaration may not use the `late` keyword.",
      correctionMessage: "Try removing the keyword `late`.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'late_pattern_variable_declaration',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments leafCallMustNotReturnHandle =
    DiagnosticWithoutArgumentsImpl(
      name: 'leaf_call_must_not_return_handle',
      problemMessage: "FFI leaf call can't return a 'Handle'.",
      correctionMessage: "Try changing the return type to primitive or struct.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'leaf_call_must_not_return_handle',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments leafCallMustNotTakeHandle =
    DiagnosticWithoutArgumentsImpl(
      name: 'leaf_call_must_not_take_handle',
      problemMessage: "FFI leaf call can't take arguments of type 'Handle'.",
      correctionMessage:
          "Try changing the argument type to primitive or struct.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'leaf_call_must_not_take_handle',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments libraryDirectiveNotFirst =
    DiagnosticWithoutArgumentsImpl(
      name: 'library_directive_not_first',
      problemMessage:
          "The library directive must appear before all other directives.",
      correctionMessage:
          "Try moving the library directive before any other directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'library_directive_not_first',
      expectedTypes: [],
    );

/// Parameters:
/// Type actualType: the actual type of the list element
/// Type expectedType: the expected type of the list element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
listElementTypeNotAssignable = DiagnosticWithArguments(
  name: 'list_element_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the list type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'list_element_type_not_assignable',
  withArguments: _withArgumentsListElementTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualType: the actual type of the list element
/// Type expectedType: the expected type of the list element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
listElementTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'list_element_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the list type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'list_element_type_not_assignable_nullability',
  withArguments: _withArgumentsListElementTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String kind: The literal kind.
/// Token lexeme: The lexeme between `new` and the literal.
const DiagnosticCode literalWithClass = DiagnosticCodeWithExpectedTypes(
  name: 'literal_with_class',
  problemMessage: "A {0} literal can't be prefixed by '{1}'.",
  correctionMessage: "Try removing '{1}'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'literal_with_class',
  expectedTypes: [ExpectedType.string, ExpectedType.token],
);

/// Parameters:
/// String kind: The literal kind
/// Token lexeme: The lexeme between `new` and the literal.
const DiagnosticCode literalWithClassAndNew = DiagnosticCodeWithExpectedTypes(
  name: 'literal_with_class_and_new',
  problemMessage: "A {0} literal can't be prefixed by 'new {1}'.",
  correctionMessage: "Try removing 'new' and '{1}'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'literal_with_class_and_new',
  expectedTypes: [ExpectedType.string, ExpectedType.token],
);

/// No parameters.
const DiagnosticWithoutArguments literalWithNew =
    DiagnosticWithoutArgumentsImpl(
      name: 'literal_with_new',
      problemMessage: "A literal can't be prefixed by 'new'.",
      correctionMessage: "Try removing 'new'",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'literal_with_new',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments localFunctionDeclarationModifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'local_function_declaration_modifier',
      problemMessage:
          "Local function declarations can't specify any modifiers.",
      correctionMessage: "Try removing the modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'local_function_declaration_modifier',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
mainFirstPositionalParameterType = DiagnosticWithoutArgumentsImpl(
  name: 'main_first_positional_parameter_type',
  problemMessage:
      "The type of the first positional parameter of the 'main' function must be "
      "a supertype of 'List<String>'.",
  correctionMessage: "Try changing the type of the parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'main_first_positional_parameter_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments mainHasRequiredNamedParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'main_has_required_named_parameters',
      problemMessage:
          "The function 'main' can't have any required named parameters.",
      correctionMessage:
          "Try using a different name for the function, or removing the "
          "'required' modifier.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'main_has_required_named_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mainHasTooManyRequiredPositionalParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'main_has_too_many_required_positional_parameters',
      problemMessage:
          "The function 'main' can't have more than two required positional "
          "parameters.",
      correctionMessage:
          "Try using a different name for the function, or removing extra "
          "parameters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'main_has_too_many_required_positional_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mainIsNotFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'main_is_not_function',
      problemMessage: "The declaration named 'main' must be a function.",
      correctionMessage: "Try using a different name for this declaration.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'main_is_not_function',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mapEntryNotInMap =
    DiagnosticWithoutArgumentsImpl(
      name: 'map_entry_not_in_map',
      problemMessage: "Map entries can only be used in a map literal.",
      correctionMessage:
          "Try converting the collection to a map or removing the map entry.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'map_entry_not_in_map',
      expectedTypes: [],
    );

/// Parameters:
/// Type actualType: the type of the expression being used as a key
/// Type expectedType: the type of keys declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mapKeyTypeNotAssignable = DiagnosticWithArguments(
  name: 'map_key_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the map key type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'map_key_type_not_assignable',
  withArguments: _withArgumentsMapKeyTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualType: the type of the expression being used as a key
/// Type expectedType: the type of keys declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mapKeyTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'map_key_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the map key type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'map_key_type_not_assignable_nullability',
  withArguments: _withArgumentsMapKeyTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualType: the type of the expression being used as a value
/// Type expectedType: the type of values declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mapValueTypeNotAssignable = DiagnosticWithArguments(
  name: 'map_value_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the map value type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'map_value_type_not_assignable',
  withArguments: _withArgumentsMapValueTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualType: the type of the expression being used as a value
/// Type expectedType: the type of values declared for the map
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
mapValueTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'map_value_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the map value type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'map_value_type_not_assignable_nullability',
  withArguments: _withArgumentsMapValueTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments memberWithClassName =
    DiagnosticWithoutArgumentsImpl(
      name: 'member_with_class_name',
      problemMessage:
          "A class member can't have the same name as the enclosing class.",
      correctionMessage: "Try renaming the member.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'member_with_class_name',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mismatchedAnnotationOnStructField =
    DiagnosticWithoutArgumentsImpl(
      name: 'mismatched_annotation_on_struct_field',
      problemMessage:
          "The annotation doesn't match the declared type of the field.",
      correctionMessage:
          "Try using a different annotation or changing the declared type to "
          "match.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mismatched_annotation_on_struct_field',
      expectedTypes: [],
    );

/// Parameters:
/// Type type: the type that is missing a native type annotation
/// String superclassName: the superclass which is extended by this field's
///                        class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required String superclassName,
  })
>
missingAnnotationOnStructField = DiagnosticWithArguments(
  name: 'missing_annotation_on_struct_field',
  problemMessage:
      "Fields of type '{0}' in a subclass of '{1}' must have an annotation "
      "indicating the native type.",
  correctionMessage: "Try adding an annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_annotation_on_struct_field',
  withArguments: _withArgumentsMissingAnnotationOnStructField,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingAssignableSelector =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_assignable_selector',
      problemMessage: "Missing selector such as '.identifier' or '[0]'.",
      correctionMessage: "Try adding a selector.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_assignable_selector',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingAssignmentInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_assignment_in_initializer',
      problemMessage: "Expected an assignment after the field name.",
      correctionMessage:
          "To initialize a field, use the syntax 'name = value'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_assignment_in_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingCatchOrFinally = DiagnosticWithoutArgumentsImpl(
  name: 'missing_catch_or_finally',
  problemMessage:
      "A try block must be followed by an 'on', 'catch', or 'finally' clause.",
  correctionMessage:
      "Try adding either a catch or finally clause, or remove the try "
      "statement.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_catch_or_finally',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingClosingParenthesis =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_closing_parenthesis',
      problemMessage: "The closing parenthesis is missing.",
      correctionMessage: "Try adding the closing parenthesis.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_closing_parenthesis',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingConstFinalVarOrType = DiagnosticWithoutArgumentsImpl(
  name: 'missing_const_final_var_or_type',
  problemMessage:
      "Variables must be declared using the keywords 'const', 'final', 'var' or "
      "a type name.",
  correctionMessage:
      "Try adding the name of the type of the variable or the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_const_final_var_or_type',
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
      name: 'missing_const_in_list_literal',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_const_in_list_literal',
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
      name: 'missing_const_in_map_literal',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_const_in_map_literal',
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
      name: 'missing_const_in_set_literal',
      problemMessage:
          "Seeing this message constitutes a bug. Please report it.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_const_in_set_literal',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
missingDefaultValueForParameter = DiagnosticWithArguments(
  name: 'missing_default_value_for_parameter',
  problemMessage:
      "The parameter '{0}' can't have a value of 'null' because of its type, but "
      "the implicit default value is 'null'.",
  correctionMessage:
      "Try adding either an explicit non-'null' default value or the "
      "'required' modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_default_value_for_parameter',
  withArguments: _withArgumentsMissingDefaultValueForParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
missingDefaultValueForParameterPositional = DiagnosticWithArguments(
  name: 'missing_default_value_for_parameter',
  problemMessage:
      "The parameter '{0}' can't have a value of 'null' because of its type, but "
      "the implicit default value is 'null'.",
  correctionMessage: "Try adding an explicit non-'null' default value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_default_value_for_parameter_positional',
  withArguments: _withArgumentsMissingDefaultValueForParameterPositional,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingDefaultValueForParameterWithAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_default_value_for_parameter',
      problemMessage:
          "With null safety, use the 'required' keyword, not the '@required' "
          "annotation.",
      correctionMessage: "Try removing the '@'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_default_value_for_parameter_with_annotation',
      expectedTypes: [],
    );

/// Parameters:
/// String missing: description of the missing packages, and which section of
///                 the pubspec file they are missing from.
/// String fix: description of what to fix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String missing, required String fix})
>
missingDependency = DiagnosticWithArguments(
  name: 'missing_dependency',
  problemMessage: "Missing a dependency on imported {0}.",
  correctionMessage: "Try adding {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_dependency',
  withArguments: _withArgumentsMissingDependency,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingDigit = DiagnosticWithoutArgumentsImpl(
  name: 'missing_digit',
  problemMessage: "Decimal digit expected.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_digit',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingEnumBody = DiagnosticWithoutArgumentsImpl(
  name: 'missing_enum_body',
  problemMessage:
      "An enum definition must have a body with at least one constant name.",
  correctionMessage: "Try adding a body and defining at least one constant.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_enum_body',
  expectedTypes: [],
);

/// Parameters:
/// String constant: the name of the constant that is missing
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String constant})
>
missingEnumConstantInSwitch = DiagnosticWithArguments(
  name: 'missing_enum_constant_in_switch',
  problemMessage: "Missing case clause for '{0}'.",
  correctionMessage:
      "Try adding a case clause for the missing constant, or adding a "
      "default clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_enum_constant_in_switch',
  withArguments: _withArgumentsMissingEnumConstantInSwitch,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String methodName: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String methodName})
>
missingExceptionValue = DiagnosticWithArguments(
  name: 'missing_exception_value',
  problemMessage:
      "The method {0} must have an exceptional return value (the second "
      "argument) when the return type of the function is neither 'void', "
      "'Handle', nor 'Pointer'.",
  correctionMessage: "Try adding an exceptional return value.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_exception_value',
  withArguments: _withArgumentsMissingExceptionValue,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingExpressionInInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_expression_in_initializer',
      problemMessage: "Expected an expression after the assignment operator.",
      correctionMessage:
          "Try adding the value to be assigned, or remove the assignment "
          "operator.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_expression_in_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingExpressionInThrow =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_expression_in_throw',
      problemMessage: "Missing expression after 'throw'.",
      correctionMessage:
          "Add an expression after 'throw' or use 'rethrow' to throw a caught "
          "exception",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_expression_in_throw',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingFieldTypeInStruct = DiagnosticWithoutArgumentsImpl(
  name: 'missing_field_type_in_struct',
  problemMessage:
      "Fields in struct classes must have an explicitly declared type of 'int', "
      "'double' or 'Pointer'.",
  correctionMessage: "Try using 'int', 'double' or 'Pointer'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_field_type_in_struct',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingFunctionBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_function_body',
      problemMessage: "A function body must be provided.",
      correctionMessage: "Try adding a function body.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_function_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingFunctionKeyword = DiagnosticWithoutArgumentsImpl(
  name: 'missing_function_keyword',
  problemMessage:
      "Function types must have the keyword 'Function' before the parameter "
      "list.",
  correctionMessage: "Try adding the keyword 'Function'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_function_keyword',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingFunctionParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_function_parameters',
      problemMessage: "Functions must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_function_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingGet = DiagnosticWithoutArgumentsImpl(
  name: 'missing_get',
  problemMessage: "Getters must have the keyword 'get' before the getter name.",
  correctionMessage: "Try adding the keyword 'get'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_get',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingHexDigit =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_hex_digit',
      problemMessage: "Hexadecimal digit expected.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_hex_digit',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingIdentifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_identifier',
      problemMessage: "Expected an identifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_identifier',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingInitializer =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_initializer',
      problemMessage: "Expected an initializer.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_initializer',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingKeywordOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_keyword_operator',
      problemMessage:
          "Operator declarations must be preceded by the keyword 'operator'.",
      correctionMessage: "Try adding the keyword 'operator'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_keyword_operator',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingMethodParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_method_parameters',
      problemMessage: "Methods must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_method_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingName = DiagnosticWithoutArgumentsImpl(
  name: 'missing_name',
  problemMessage: "The 'name' field is required but missing.",
  correctionMessage: "Try adding a field named 'name'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNamedPatternFieldName = DiagnosticWithoutArgumentsImpl(
  name: 'missing_named_pattern_field_name',
  problemMessage:
      "The getter name is not specified explicitly, and the pattern is not a "
      "variable.",
  correctionMessage:
      "Try specifying the getter name explicitly, or using a variable "
      "pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_named_pattern_field_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNameForNamedParameter = DiagnosticWithoutArgumentsImpl(
  name: 'missing_name_for_named_parameter',
  problemMessage: "Named parameters in a function type must have a name",
  correctionMessage:
      "Try providing a name for the parameter or removing the curly braces.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_name_for_named_parameter',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
missingNameInLibraryDirective = DiagnosticWithoutArgumentsImpl(
  name: 'missing_name_in_library_directive',
  problemMessage: "Library directives must include a library name.",
  correctionMessage:
      "Try adding a library name after the keyword 'library', or remove the "
      "library directive if the library doesn't have any parts.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_name_in_library_directive',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments missingNameInPartOfDirective =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_name_in_part_of_directive',
      problemMessage: "Part-of directives must include a library name.",
      correctionMessage: "Try adding a library name after the 'of'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_name_in_part_of_directive',
      expectedTypes: [],
    );

/// Parameters:
/// String member: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String member})
>
missingOverrideOfMustBeOverriddenOne = DiagnosticWithArguments(
  name: 'missing_override_of_must_be_overridden',
  problemMessage: "Missing a required override of '{0}'.",
  correctionMessage: "Try overriding the missing member.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_override_of_must_be_overridden_one',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenOne,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String firstMember: the name of the first member
/// String secondMember: the name of the second member
/// int additionalCount: the number of additional missing members that aren't
///                      listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String firstMember,
    required String secondMember,
    required int additionalCount,
  })
>
missingOverrideOfMustBeOverriddenThreePlus = DiagnosticWithArguments(
  name: 'missing_override_of_must_be_overridden',
  problemMessage: "Missing a required override of '{0}', '{1}', and {2} more.",
  correctionMessage: "Try overriding the missing members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_override_of_must_be_overridden_three_plus',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenThreePlus,
  expectedTypes: [ExpectedType.string, ExpectedType.string, ExpectedType.int],
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
  name: 'missing_override_of_must_be_overridden',
  problemMessage: "Missing a required override of '{0}' and '{1}'.",
  correctionMessage: "Try overriding the missing members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_override_of_must_be_overridden_two',
  withArguments: _withArgumentsMissingOverrideOfMustBeOverriddenTwo,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingPrefixInDeferredImport =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_prefix_in_deferred_import',
      problemMessage: "Deferred imports should have a prefix.",
      correctionMessage:
          "Try adding a prefix to the import by adding an 'as' clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_prefix_in_deferred_import',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingPrimaryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_primary_constructor',
      problemMessage:
          "An extension type declaration must have a primary constructor "
          "declaration.",
      correctionMessage:
          "Try adding a primary constructor to the extension type declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_primary_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingPrimaryConstructorParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_primary_constructor_parameters',
      problemMessage:
          "A primary constructor declaration must have formal parameters.",
      correctionMessage:
          "Try adding formal parameters after the primary constructor name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_primary_constructor_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingQuote = DiagnosticWithoutArgumentsImpl(
  name: 'missing_quote',
  problemMessage: "Expected quote (' or \").",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_quote',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
missingRequiredArgument = DiagnosticWithArguments(
  name: 'missing_required_argument',
  problemMessage:
      "The named parameter '{0}' is required, but there's no corresponding "
      "argument.",
  correctionMessage: "Try adding the required argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_required_argument',
  withArguments: _withArgumentsMissingRequiredArgument,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for a constructor, function or method invocation where
/// a required parameter is missing.
///
/// Parameters:
/// String name: the name of the parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
missingRequiredParam = DiagnosticWithArguments(
  name: 'missing_required_param',
  problemMessage: "The parameter '{0}' is required.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_required_param',
  withArguments: _withArgumentsMissingRequiredParam,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for a constructor, function or method invocation where
/// a required parameter is missing.
///
/// Parameters:
/// String name: the name of the parameter
/// String details: message details
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name, required String details})
>
missingRequiredParamWithDetails = DiagnosticWithArguments(
  name: 'missing_required_param',
  problemMessage: "The parameter '{0}' is required. {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'missing_required_param_with_details',
  withArguments: _withArgumentsMissingRequiredParamWithDetails,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingSizeAnnotationCarray =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_size_annotation_carray',
      problemMessage:
          "Fields of type 'Array' must have exactly one 'Array' annotation.",
      correctionMessage:
          "Try adding an 'Array' annotation, or removing all but one of the "
          "annotations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_size_annotation_carray',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingStarAfterSync =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_star_after_sync',
      problemMessage: "The modifier 'sync' must be followed by a star ('*').",
      correctionMessage: "Try removing the modifier, or add a star.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_star_after_sync',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingStatement =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_statement',
      problemMessage: "Expected a statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_statement',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments missingTypedefParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_typedef_parameters',
      problemMessage: "Typedefs must have an explicit list of parameters.",
      correctionMessage: "Try adding a parameter list.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'missing_typedef_parameters',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
missingVariableInForEach = DiagnosticWithoutArgumentsImpl(
  name: 'missing_variable_in_for_each',
  problemMessage:
      "A loop variable must be declared in a for-each loop before the 'in', but "
      "none was found.",
  correctionMessage: "Try declaring a loop variable.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'missing_variable_in_for_each',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the variable pattern
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
missingVariablePattern = DiagnosticWithArguments(
  name: 'missing_variable_pattern',
  problemMessage:
      "Variable pattern '{0}' is missing in this branch of the logical-or "
      "pattern.",
  correctionMessage: "Try declaring this variable pattern in the branch.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_variable_pattern',
  withArguments: _withArgumentsMissingVariablePattern,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
mixedParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'mixed_parameter_groups',
  problemMessage:
      "Can't have both positional and named parameters in a single parameter "
      "list.",
  correctionMessage: "Try choosing a single style of optional parameters.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'mixed_parameter_groups',
  expectedTypes: [],
);

/// Parameters:
/// String memberName: the name of the super-invoked member
/// Type mixinMemberType: the display name of the type of the super-invoked
///                       member in the mixin
/// Type concreteMemberType: the display name of the type of the concrete
///                          member in the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required DartType mixinMemberType,
    required DartType concreteMemberType,
  })
>
mixinApplicationConcreteSuperInvokedMemberType = DiagnosticWithArguments(
  name: 'mixin_application_concrete_super_invoked_member_type',
  problemMessage:
      "The super-invoked member '{0}' has the type '{1}', and the concrete "
      "member in the class has the type '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_application_concrete_super_invoked_member_type',
  withArguments: _withArgumentsMixinApplicationConcreteSuperInvokedMemberType,
  expectedTypes: [ExpectedType.string, ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String name: the display name of the member without a concrete
///              implementation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
mixinApplicationNoConcreteSuperInvokedMember = DiagnosticWithArguments(
  name: 'mixin_application_no_concrete_super_invoked_member',
  problemMessage:
      "The class doesn't have a concrete implementation of the super-invoked "
      "member '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_application_no_concrete_super_invoked_member',
  withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the display name of the setter without a concrete
///              implementation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
mixinApplicationNoConcreteSuperInvokedSetter = DiagnosticWithArguments(
  name: 'mixin_application_no_concrete_super_invoked_member',
  problemMessage:
      "The class doesn't have a concrete implementation of the super-invoked "
      "setter '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_application_no_concrete_super_invoked_setter',
  withArguments: _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type mixinType: the type of the mixin
/// Type superType: the supertype
/// Type notImplementedType: the type that is not implemented
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType mixinType,
    required DartType superType,
    required DartType notImplementedType,
  })
>
mixinApplicationNotImplementedInterface = DiagnosticWithArguments(
  name: 'mixin_application_not_implemented_interface',
  problemMessage:
      "'{0}' can't be mixed onto '{1}' because '{1}' doesn't implement '{2}'.",
  correctionMessage: "Try extending the class '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_application_not_implemented_interface',
  withArguments: _withArgumentsMixinApplicationNotImplementedInterface,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String name: the name of the mixin class that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
mixinClassDeclarationExtendsNotObject = DiagnosticWithArguments(
  name: 'mixin_class_declaration_extends_not_object',
  problemMessage:
      "The class '{0}' can't be declared a mixin because it extends a class "
      "other than 'Object'.",
  correctionMessage:
      "Try removing the 'mixin' modifier or changing the superclass to "
      "'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_class_declaration_extends_not_object',
  withArguments: _withArgumentsMixinClassDeclarationExtendsNotObject,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String className: the name of the mixin that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
mixinClassDeclaresConstructor = DiagnosticWithArguments(
  name: 'mixin_class_declares_constructor',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it declares a "
      "constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_class_declares_constructor',
  withArguments: _withArgumentsMixinClassDeclaresConstructor,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinDeclaresConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_declares_constructor',
      problemMessage: "Mixins can't declare constructors.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'mixin_declares_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'subtype_of_deferred_class',
      problemMessage: "Classes can't mixin deferred classes.",
      correctionMessage: "Try changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_deferred_class',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the mixin that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
mixinInheritsFromNotObject = DiagnosticWithArguments(
  name: 'mixin_inherits_from_not_object',
  problemMessage:
      "The class '{0}' can't be used as a mixin because it extends a class other "
      "than 'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_inherits_from_not_object',
  withArguments: _withArgumentsMixinInheritsFromNotObject,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinInstantiate =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_instantiate',
      problemMessage: "Mixins can't be instantiated.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_instantiate',
      expectedTypes: [],
    );

/// Parameters:
/// Type disallowedType: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType disallowedType})
>
mixinOfDisallowedClass = DiagnosticWithArguments(
  name: 'subtype_of_disallowed_type',
  problemMessage: "Classes can't mixin '{0}'.",
  correctionMessage:
      "Try specifying a different class or mixin, or remove the class or "
      "mixin from the list.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_of_disallowed_class',
  withArguments: _withArgumentsMixinOfDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments mixinOfNonClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_of_non_class',
      problemMessage: "Classes can only mix in mixins and classes.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_of_non_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinOfTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'supertype_expands_to_type_parameter',
      problemMessage:
          "A type alias that expands to a type parameter can't be mixed in.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_of_type_alias_expands_to_type_parameter',
      expectedTypes: [],
    );

/// This warning is generated anywhere where a `@sealed` class is used as a
/// a superclass constraint of a mixin.
///
/// Parameters:
/// String name: the name of the sealed class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
mixinOnSealedClass = DiagnosticWithArguments(
  name: 'mixin_on_sealed_class',
  problemMessage:
      "The class '{0}' shouldn't be used as a mixin constraint because it is "
      "sealed, and any class mixing in this mixin must have '{0}' as a "
      "superclass.",
  correctionMessage:
      "Try composing with this class, or refer to its documentation for more "
      "information.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'mixin_on_sealed_class',
  withArguments: _withArgumentsMixinOnSealedClass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinOnTypeAliasExpandsToTypeParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'supertype_expands_to_type_parameter',
      problemMessage:
          "A type alias that expands to a type parameter can't be used as a "
          "superclass constraint.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_on_type_alias_expands_to_type_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// Element referencedClass: the class that appears in both "extends" and
///                          "with" clauses
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element referencedClass})
>
mixinsSuperClass = DiagnosticWithArguments(
  name: 'implements_super_class',
  problemMessage:
      "'{0}' can't be used in both the 'extends' and 'with' clauses.",
  correctionMessage: "Try removing one of the occurrences.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixins_super_class',
  withArguments: _withArgumentsMixinsSuperClass,
  expectedTypes: [ExpectedType.element],
);

/// Parameters:
/// String subtypeName: the name of the mixin that is not 'base'
/// String supertypeName: the name of the 'base' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subtypeName,
    required String supertypeName,
  })
>
mixinSubtypeOfBaseIsNotBase = DiagnosticWithArguments(
  name: 'subtype_of_base_or_final_is_not_base_final_or_sealed',
  problemMessage:
      "The mixin '{0}' must be 'base' because the supertype '{1}' is 'base'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_subtype_of_base_is_not_base',
  withArguments: _withArgumentsMixinSubtypeOfBaseIsNotBase,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String subtypeName: the name of the mixin that is not 'final'
/// String supertypeName: the name of the 'final' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subtypeName,
    required String supertypeName,
  })
>
mixinSubtypeOfFinalIsNotBase = DiagnosticWithArguments(
  name: 'subtype_of_base_or_final_is_not_base_final_or_sealed',
  problemMessage:
      "The mixin '{0}' must be 'base' because the supertype '{1}' is 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_subtype_of_final_is_not_base',
  withArguments: _withArgumentsMixinSubtypeOfFinalIsNotBase,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments mixinSuperClassConstraintDeferredClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_super_class_constraint_deferred_class',
      problemMessage:
          "Deferred classes can't be used as superclass constraints.",
      correctionMessage: "Try changing the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_super_class_constraint_deferred_class',
      expectedTypes: [],
    );

/// Parameters:
/// Type disallowedType: the name of the disallowed type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType disallowedType})
>
mixinSuperClassConstraintDisallowedClass = DiagnosticWithArguments(
  name: 'subtype_of_disallowed_type',
  problemMessage: "'{0}' can't be used as a superclass constraint.",
  correctionMessage:
      "Try specifying a different super-class constraint, or remove the 'on' "
      "clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'mixin_super_class_constraint_disallowed_class',
  withArguments: _withArgumentsMixinSuperClassConstraintDisallowedClass,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments mixinSuperClassConstraintNonInterface =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_super_class_constraint_non_interface',
      problemMessage:
          "Only classes and mixins can be used as superclass constraints.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_super_class_constraint_non_interface',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments mixinWithClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_with_clause',
      problemMessage: "A mixin can't have a with clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'mixin_with_clause',
      expectedTypes: [],
    );

/// 9.1 Mixin Application: It is a compile-time error if <i>S</i> does not
/// denote a class available in the immediately enclosing scope.
///
/// No parameters.
const DiagnosticWithoutArguments mixinWithNonClassSuperclass =
    DiagnosticWithoutArgumentsImpl(
      name: 'mixin_with_non_class_superclass',
      problemMessage: "Mixin can only be applied to class.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'mixin_with_non_class_superclass',
      expectedTypes: [],
    );

/// Parameters:
/// String modifier: The problematic modifier.
/// String expectedLaterModifier: The modifier that should come later.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String modifier,
    required String expectedLaterModifier,
  })
>
modifierOutOfOrder = DiagnosticWithArguments(
  name: 'modifier_out_of_order',
  problemMessage: "The modifier '{0}' should be before the modifier '{1}'.",
  correctionMessage: "Try re-ordering the modifiers.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'modifier_out_of_order',
  withArguments: _withArgumentsModifierOutOfOrder,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String definitionKind: The kind of definition that has multiple clauses.
/// String clauseKind: The kind of clause of which there are multiple.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String definitionKind,
    required String clauseKind,
  })
>
multipleClauses = DiagnosticWithArguments(
  name: 'multiple_clauses',
  problemMessage: "Each '{0}' definition can have at most one '{1}' clause.",
  correctionMessage:
      "Try combining all of the '{1}' clauses into a single clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'multiple_clauses',
  withArguments: _withArgumentsMultipleClauses,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
multipleCombinators = DiagnosticWithoutArgumentsImpl(
  name: 'multiple_combinators',
  problemMessage:
      "Using multiple 'hide' or 'show' combinators is never necessary and often "
      "produces surprising results.",
  correctionMessage: "Try using a single combinator.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'multiple_combinators',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleExtendsClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_extends_clauses',
      problemMessage:
          "Each class definition can have at most one extends clause.",
      correctionMessage:
          "Try choosing one superclass and define your class to implement (or "
          "mix in) the others.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_extends_clauses',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
multipleImplementsClauses = DiagnosticWithoutArgumentsImpl(
  name: 'multiple_implements_clauses',
  problemMessage:
      "Each class or mixin definition can have at most one implements clause.",
  correctionMessage:
      "Try combining all of the implements clauses into a single clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'multiple_implements_clauses',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleLibraryDirectives =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_library_directives',
      problemMessage: "Only one library directive may be declared in a file.",
      correctionMessage: "Try removing all but one of the library directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_library_directives',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
multipleNamedParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'multiple_named_parameter_groups',
  problemMessage:
      "Can't have multiple groups of named parameters in a single parameter "
      "list.",
  correctionMessage: "Try combining all of the groups into a single group.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'multiple_named_parameter_groups',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multipleOnClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_on_clauses',
      problemMessage: "Each mixin definition can have at most one on clause.",
      correctionMessage:
          "Try combining all of the on clauses into a single clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_on_clauses',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multiplePartOfDirectives =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_part_of_directives',
      problemMessage: "Only one part-of directive may be declared in a file.",
      correctionMessage: "Try removing all but one of the part-of directives.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_part_of_directives',
      expectedTypes: [],
    );

/// An error code indicating multiple plugins have been specified as enabled.
///
/// Parameters:
/// String firstPluginName: the name of the first plugin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String firstPluginName})
>
multiplePlugins = DiagnosticWithArguments(
  name: 'multiple_plugins',
  problemMessage: "Multiple plugins can't be enabled.",
  correctionMessage: "Remove all plugins following the first, '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'multiple_plugins',
  withArguments: _withArgumentsMultiplePlugins,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
multiplePositionalParameterGroups = DiagnosticWithoutArgumentsImpl(
  name: 'multiple_positional_parameter_groups',
  problemMessage:
      "Can't have multiple groups of positional parameters in a single parameter "
      "list.",
  correctionMessage: "Try combining all of the groups into a single group.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'multiple_positional_parameter_groups',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments multiplePrimaryConstructorBodyDeclarations =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_primary_constructor_body_declarations',
      problemMessage:
          "Only one primary constructor body declaration is allowed.",
      correctionMessage:
          "Try removing all but one of the primary constructor body "
          "declarations.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'multiple_primary_constructor_body_declarations',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleRedirectingConstructorInvocations =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_redirecting_constructor_invocations',
      problemMessage:
          "Constructors can have only one 'this' redirection, at most.",
      correctionMessage: "Try removing all but one of the redirections.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'multiple_redirecting_constructor_invocations',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleRepresentationFields =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_representation_fields',
      problemMessage:
          "Each extension type should have exactly one representation field.",
      correctionMessage:
          "Try combining fields into a record, or removing extra fields.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_representation_fields',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleSuperInitializers =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_super_initializers',
      problemMessage: "A constructor can have at most one 'super' initializer.",
      correctionMessage:
          "Try removing all but one of the 'super' initializers.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'multiple_super_initializers',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleVarianceModifiers =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_variance_modifiers',
      problemMessage:
          "Each type parameter can have at most one variance modifier.",
      correctionMessage:
          "Use at most one of the 'in', 'out', or 'inout' modifiers.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_variance_modifiers',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments multipleWithClauses =
    DiagnosticWithoutArgumentsImpl(
      name: 'multiple_with_clauses',
      problemMessage: "Each class definition can have at most one with clause.",
      correctionMessage:
          "Try combining all of the with clauses into a single clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'multiple_with_clauses',
      expectedTypes: [],
    );

/// Parameters:
/// Type type: the type that should be a valid dart:ffi native type.
/// String functionName: the name of the function whose invocation depends on
///                      this relationship
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required String functionName,
  })
>
mustBeANativeFunctionType = DiagnosticWithArguments(
  name: 'must_be_a_native_function_type',
  problemMessage:
      "The type '{0}' given to '{1}' must be a valid 'dart:ffi' native function "
      "type.",
  correctionMessage:
      "Try changing the type to only use members for 'dart:ffi'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'must_be_a_native_function_type',
  withArguments: _withArgumentsMustBeANativeFunctionType,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type subtype: the type that should be a subtype
/// Type supertype: the supertype that the subtype is compared to
/// String name: the name of the function whose invocation depends on this
///              relationship
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType subtype,
    required DartType supertype,
    required String name,
  })
>
mustBeASubtype = DiagnosticWithArguments(
  name: 'must_be_a_subtype',
  problemMessage: "The type '{0}' must be a subtype of '{1}' for '{2}'.",
  correctionMessage: "Try changing one or both of the type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'must_be_a_subtype',
  withArguments: _withArgumentsMustBeASubtype,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Generates a warning for classes that inherit from classes annotated with
/// `@immutable` but that are not immutable.
///
/// Parameters:
/// String fieldNames: the names of the non-final field names, joined with
///                    commas
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldNames})
>
mustBeImmutable = DiagnosticWithArguments(
  name: 'must_be_immutable',
  problemMessage:
      "This class (or a class that this class inherits from) is marked as "
      "'@immutable', but one or more of its instance fields aren't final: "
      "{0}",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'must_be_immutable',
  withArguments: _withArgumentsMustBeImmutable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String className: the name of the class declaring the overridden method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
mustCallSuper = DiagnosticWithArguments(
  name: 'must_call_super',
  problemMessage:
      "This method overrides a method annotated as '@mustCallSuper' in '{0}', "
      "but doesn't invoke the overridden method.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'must_call_super',
  withArguments: _withArgumentsMustCallSuper,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type type: the return type that should be 'void'.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
mustReturnVoid = DiagnosticWithArguments(
  name: 'must_return_void',
  problemMessage:
      "The return type of the function passed to 'NativeCallable.listener' must "
      "be 'void' rather than '{0}'.",
  correctionMessage: "Try changing the return type to 'void'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'must_return_void',
  withArguments: _withArgumentsMustReturnVoid,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments namedFunctionExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'named_function_expression',
      problemMessage: "Function expressions can't be named.",
      correctionMessage:
          "Try removing the name, or moving the function expression to a "
          "function declaration statement.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'named_function_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments namedFunctionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'named_function_type',
      problemMessage: "Function types can't be named.",
      correctionMessage: "Try replacing the name with the keyword 'Function'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'named_function_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments namedParameterOutsideGroup =
    DiagnosticWithoutArgumentsImpl(
      name: 'named_parameter_outside_group',
      problemMessage:
          "Named parameters must be enclosed in curly braces ('{' and '}').",
      correctionMessage:
          "Try surrounding the named parameters in curly braces.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'named_parameter_outside_group',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nameNotString = DiagnosticWithoutArgumentsImpl(
  name: 'name_not_string',
  problemMessage: "The value of the 'name' field is required to be a string.",
  correctionMessage: "Try converting the value to be a string.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'name_not_string',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nativeClauseInNonSdkCode = DiagnosticWithoutArgumentsImpl(
  name: 'native_clause_in_non_sdk_code',
  problemMessage:
      "Native clause can only be used in the SDK and code that is loaded through "
      "native extensions.",
  correctionMessage: "Try removing the native clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'native_clause_in_non_sdk_code',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeClauseShouldBeAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'native_clause_should_be_annotation',
      problemMessage: "Native clause in this form is deprecated.",
      correctionMessage:
          "Try removing this native clause and adding @native() or "
          "@native('native-name') before the declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'native_clause_should_be_annotation',
      expectedTypes: [],
    );

/// Parameters:
/// Type type: The invalid type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nativeFieldInvalidType = DiagnosticWithArguments(
  name: 'native_field_invalid_type',
  problemMessage:
      "'{0}' is an unsupported type for native fields. Native fields only "
      "support pointers, arrays or numeric and compound types.",
  correctionMessage:
      "Try changing the type in the `@Native` annotation to a numeric FFI "
      "type, a pointer, array, or a compound class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'native_field_invalid_type',
  withArguments: _withArgumentsNativeFieldInvalidType,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
nativeFieldMissingType = DiagnosticWithoutArgumentsImpl(
  name: 'native_field_missing_type',
  problemMessage:
      "The native type of this field could not be inferred and must be specified "
      "in the annotation.",
  correctionMessage:
      "Try adding a type parameter extending `NativeType` to the `@Native` "
      "annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'native_field_missing_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeFieldNotStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'native_field_not_static',
      problemMessage: "Native fields must be static.",
      correctionMessage: "Try adding the modifier 'static' to this field.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'native_field_not_static',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nativeFunctionBodyInNonSdkCode = DiagnosticWithoutArgumentsImpl(
  name: 'native_function_body_in_non_sdk_code',
  problemMessage:
      "Native functions can only be declared in the SDK and code that is loaded "
      "through native extensions.",
  correctionMessage: "Try removing the word 'native'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'native_function_body_in_non_sdk_code',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nativeFunctionMissingType =
    DiagnosticWithoutArgumentsImpl(
      name: 'native_function_missing_type',
      problemMessage:
          "The native type of this function couldn't be inferred so it must be "
          "specified in the annotation.",
      correctionMessage:
          "Try adding a type parameter extending `NativeType` to the `@Native` "
          "annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'native_function_missing_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
negativeVariableDimension = DiagnosticWithoutArgumentsImpl(
  name: 'negative_variable_dimension',
  problemMessage:
      "The variable dimension of a variable-length array must be non-negative.",
  correctionMessage: "Try using a value that is zero or greater.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'negative_variable_dimension',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
newConstructorDotName = DiagnosticWithoutArgumentsImpl(
  name: 'new_constructor_dot_name',
  problemMessage:
      "Constructors declared with the 'new' keyword can't use '.' before the "
      "constructor name.",
  correctionMessage: "Try replacing the '.' with a space.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'new_constructor_dot_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments newConstructorNewName =
    DiagnosticWithoutArgumentsImpl(
      name: 'new_constructor_new_name',
      problemMessage:
          "Constructors declared with the 'new' keyword can't be named 'new'.",
      correctionMessage:
          "Try removing the second 'new' or changing it to a different name.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'new_constructor_new_name',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
newConstructorQualifiedName = DiagnosticWithoutArgumentsImpl(
  name: 'new_constructor_qualified_name',
  problemMessage:
      "Constructors declared with the 'new' keyword can't have qualified names.",
  correctionMessage:
      "Try removing the class name prefix from the qualified name or "
      "removing the 'new' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'new_constructor_qualified_name',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
newWithNonType = DiagnosticWithArguments(
  name: 'creation_with_non_type',
  problemMessage: "The name '{0}' isn't a class.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'new_with_non_type',
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
/// String typeName: the name of the class being instantiated
/// String constructorName: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String typeName,
    required String constructorName,
  })
>
newWithUndefinedConstructor = DiagnosticWithArguments(
  name: 'new_with_undefined_constructor',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try invoking a different constructor, or define a constructor named "
      "'{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'new_with_undefined_constructor',
  withArguments: _withArgumentsNewWithUndefinedConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String className: the name of the class being instantiated
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
newWithUndefinedConstructorDefault = DiagnosticWithArguments(
  name: 'new_with_undefined_constructor_default',
  problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
  correctionMessage:
      "Try using one of the named constructors defined in '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'new_with_undefined_constructor_default',
  withArguments: _withArgumentsNewWithUndefinedConstructorDefault,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments noAnnotationConstructorArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'no_annotation_constructor_arguments',
      problemMessage: "Annotation creation must have arguments.",
      correctionMessage: "Try adding an empty argument list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'no_annotation_constructor_arguments',
      expectedTypes: [],
    );

/// Parameters:
/// String className: the name of the class where override error was detected
/// String candidateSignatures: the list of candidate signatures which cannot
///                             be combined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String candidateSignatures,
  })
>
noCombinedSuperSignature = DiagnosticWithArguments(
  name: 'no_combined_super_signature',
  problemMessage:
      "Can't infer missing types in '{0}' from overridden methods: {1}.",
  correctionMessage:
      "Try providing explicit types for this method's parameters and return "
      "type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'no_combined_super_signature',
  withArguments: _withArgumentsNoCombinedSuperSignature,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type supertype: the supertype that does not define an implicitly invoked
///                 constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType supertype})
>
noDefaultSuperConstructorExplicit = DiagnosticWithArguments(
  name: 'no_default_super_constructor',
  problemMessage:
      "The superclass '{0}' doesn't have a zero argument constructor.",
  correctionMessage:
      "Try declaring a zero argument constructor in '{0}', or explicitly "
      "invoking a different constructor in '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'no_default_super_constructor_explicit',
  withArguments: _withArgumentsNoDefaultSuperConstructorExplicit,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// Type superclassType: the name of the superclass that does not define an
///                      implicitly invoked constructor
/// String subclassName: the name of the subclass that does not contain any
///                      explicit constructors
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType superclassType,
    required String subclassName,
  })
>
noDefaultSuperConstructorImplicit = DiagnosticWithArguments(
  name: 'no_default_super_constructor',
  problemMessage:
      "The superclass '{0}' doesn't have a zero argument constructor.",
  correctionMessage:
      "Try declaring a zero argument constructor in '{0}', or declaring a "
      "constructor in {1} that explicitly invokes a constructor in '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'no_default_super_constructor_implicit',
  withArguments: _withArgumentsNoDefaultSuperConstructorImplicit,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// String subclassName: the name of the subclass
/// String superclassName: the name of the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subclassName,
    required String superclassName,
  })
>
noGenerativeConstructorsInSuperclass = DiagnosticWithArguments(
  name: 'no_generative_constructors_in_superclass',
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
  uniqueName: 'no_generative_constructors_in_superclass',
  withArguments: _withArgumentsNoGenerativeConstructorsInSuperclass,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name1: the name of the first member
/// String name2: the name of the second member
/// String name3: the name of the third member
/// String name4: the name of the fourth member
/// int remainingCount: the number of additional missing members that aren't
///                     listed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name1,
    required String name2,
    required String name3,
    required String name4,
    required int remainingCount,
  })
>
nonAbstractClassInheritsAbstractMemberFivePlus = DiagnosticWithArguments(
  name: 'non_abstract_class_inherits_abstract_member',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', '{2}', '{3}', and {4} "
      "more.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_abstract_class_inherits_abstract_member_five_plus',
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
/// String name1: the name of the first member
/// String name2: the name of the second member
/// String name3: the name of the third member
/// String name4: the name of the fourth member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name1,
    required String name2,
    required String name3,
    required String name4,
  })
>
nonAbstractClassInheritsAbstractMemberFour = DiagnosticWithArguments(
  name: 'non_abstract_class_inherits_abstract_member',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', '{2}', and '{3}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_abstract_class_inherits_abstract_member_four',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberFour,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String name: the name of the member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
nonAbstractClassInheritsAbstractMemberOne = DiagnosticWithArguments(
  name: 'non_abstract_class_inherits_abstract_member',
  problemMessage: "Missing concrete implementation of '{0}'.",
  correctionMessage:
      "Try implementing the missing method, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_abstract_class_inherits_abstract_member_one',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberOne,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name1: the name of the first member
/// String name2: the name of the second member
/// String name3: the name of the third member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name1,
    required String name2,
    required String name3,
  })
>
nonAbstractClassInheritsAbstractMemberThree = DiagnosticWithArguments(
  name: 'non_abstract_class_inherits_abstract_member',
  problemMessage:
      "Missing concrete implementations of '{0}', '{1}', and '{2}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_abstract_class_inherits_abstract_member_three',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberThree,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String name1: the name of the first member
/// String name2: the name of the second member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name1, required String name2})
>
nonAbstractClassInheritsAbstractMemberTwo = DiagnosticWithArguments(
  name: 'non_abstract_class_inherits_abstract_member',
  problemMessage: "Missing concrete implementations of '{0}' and '{1}'.",
  correctionMessage:
      "Try implementing the missing methods, or make the class abstract.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_abstract_class_inherits_abstract_member_two',
  withArguments: _withArgumentsNonAbstractClassInheritsAbstractMemberTwo,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonBoolCondition =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_bool_condition',
      problemMessage: "Conditions must have a static type of 'bool'.",
      correctionMessage: "Try changing the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_bool_condition',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonBoolExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_bool_expression',
      problemMessage: "The expression in an assert must be of type 'bool'.",
      correctionMessage: "Try changing the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_bool_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonBoolNegationExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_bool_negation_expression',
      problemMessage: "A negation operand must have a static type of 'bool'.",
      correctionMessage: "Try changing the operand to the '!' operator.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_bool_negation_expression',
      expectedTypes: [],
    );

/// Parameters:
/// String operator: the lexeme of the logical operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String operator})
>
nonBoolOperand = DiagnosticWithArguments(
  name: 'non_bool_operand',
  problemMessage:
      "The operands of the operator '{0}' must be assignable to 'bool'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_bool_operand',
  withArguments: _withArgumentsNonBoolOperand,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantAnnotationConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_annotation_constructor',
      problemMessage: "Annotation creation can only call a const constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_annotation_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantCaseExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_case_expression',
      problemMessage: "Case expressions must be constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_case_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantCaseExpressionFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_case_expression_from_deferred_library',
      problemMessage:
          "Constant values from a deferred library can't be used as a case "
          "expression.",
      correctionMessage:
          "Try re-writing the switch as a series of if statements, or changing "
          "the import to not be deferred.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_case_expression_from_deferred_library',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantDefaultValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_default_value',
      problemMessage:
          "The default value of an optional parameter must be constant.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_default_value',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantDefaultValueFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_default_value_from_deferred_library',
      problemMessage:
          "Constant values from a deferred library can't be used as a default "
          "parameter value.",
      correctionMessage:
          "Try leaving the default as 'null' and initializing the parameter "
          "inside the function body.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_default_value_from_deferred_library',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantListElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_list_element',
      problemMessage: "The values in a const list literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the list literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_list_element',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantListElementFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'collection_element_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' list literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the list literal or removing "
      "the keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_constant_list_element_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_map_element',
      problemMessage: "The elements in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_map_element',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_map_key',
      problemMessage: "The keys in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_map_key',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantMapKeyFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'collection_element_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as keys in a "
      "'const' map literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the map literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_constant_map_key_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapPatternKey =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_map_pattern_key',
      problemMessage: "Key expressions in map patterns must be constants.",
      correctionMessage: "Try using constants instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_map_pattern_key',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantMapValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_map_value',
      problemMessage: "The values in a const map literal must be constant.",
      correctionMessage:
          "Try removing the keyword 'const' from the map literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_map_value',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantMapValueFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'collection_element_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' map literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the map literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_constant_map_value_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantRecordField =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_record_field',
      problemMessage: "The fields in a const record literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the record literal.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_record_field',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonConstantRecordFieldFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'non_constant_record_field_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as fields in a "
      "'const' record literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the record literal or removing "
      "the keyword 'deferred' from the import.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_constant_record_field_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstantRelationalPatternExpression =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_relational_pattern_expression',
      problemMessage: "The relational pattern expression must be a constant.",
      correctionMessage: "Try using a constant instead.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_relational_pattern_expression',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonConstantSetElement =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constant_set_element',
      problemMessage: "The values in a const set literal must be constants.",
      correctionMessage:
          "Try removing the keyword 'const' from the set literal.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_constant_set_element',
      expectedTypes: [],
    );

/// Parameters:
/// String executableName: the name of the function, method, or constructor
///                        having type arguments
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String executableName})
>
nonConstantTypeArgument = DiagnosticWithArguments(
  name: 'non_constant_type_argument',
  problemMessage:
      "The type arguments to '{0}' must be known at compile time, so they can't "
      "be type parameters.",
  correctionMessage: "Try changing the type argument to be a constant type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_constant_type_argument',
  withArguments: _withArgumentsNonConstantTypeArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the argument
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
nonConstArgumentForConstParameter = DiagnosticWithArguments(
  name: 'non_const_argument_for_const_parameter',
  problemMessage: "Argument '{0}' must be a constant.",
  correctionMessage: "Try replacing the argument with a constant.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'non_const_argument_for_const_parameter',
  withArguments: _withArgumentsNonConstArgumentForConstParameter,
  expectedTypes: [ExpectedType.string],
);

/// Generates a warning for non-const instance creation using a constructor
/// annotated with `@literal`.
///
/// Parameters:
/// String constructorName: the name of the annotated constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String constructorName})
>
nonConstCallToLiteralConstructor = DiagnosticWithArguments(
  name: 'non_const_call_to_literal_constructor',
  problemMessage:
      "This instance creation must be 'const', because the {0} constructor is "
      "marked as '@literal'.",
  correctionMessage: "Try adding a 'const' keyword.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'non_const_call_to_literal_constructor',
  withArguments: _withArgumentsNonConstCallToLiteralConstructor,
  expectedTypes: [ExpectedType.string],
);

/// Generate a warning for non-const instance creation (with the `new` keyword)
/// using a constructor annotated with `@literal`.
///
/// Parameters:
/// String constructorName: the name of the annotated constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String constructorName})
>
nonConstCallToLiteralConstructorUsingNew = DiagnosticWithArguments(
  name: 'non_const_call_to_literal_constructor',
  problemMessage:
      "This instance creation must be 'const', because the {0} constructor is "
      "marked as '@literal'.",
  correctionMessage: "Try replacing the 'new' keyword with 'const'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'non_const_call_to_literal_constructor_using_new',
  withArguments: _withArgumentsNonConstCallToLiteralConstructorUsingNew,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstGenerativeEnumConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_const_generative_enum_constructor',
      problemMessage: "Generative enum constructors must be 'const'.",
      correctionMessage: "Try adding the keyword 'const'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_const_generative_enum_constructor',
      expectedTypes: [],
    );

/// 13.2 Expression Statements: It is a compile-time error if a non-constant
/// map literal that has no explicit type arguments appears in a place where a
/// statement is expected.
///
/// No parameters.
const DiagnosticWithoutArguments
nonConstMapAsExpressionStatement = DiagnosticWithoutArgumentsImpl(
  name: 'non_const_map_as_expression_statement',
  problemMessage:
      "A non-constant map or set literal without type arguments can't be used as "
      "an expression statement.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_const_map_as_expression_statement',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonConstructorFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_constructor_factory',
      problemMessage: "Only a constructor can be declared to be a factory.",
      correctionMessage: "Try removing the keyword 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'non_constructor_factory',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonCovariantTypeParameterPositionInRepresentationType =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_covariant_type_parameter_position_in_representation_type',
      problemMessage:
          "An extension type parameter can't be used in a non-covariant position of "
          "its representation type.",
      correctionMessage:
          "Try removing the type parameters from function parameter types and "
          "type parameter bounds.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'non_covariant_type_parameter_position_in_representation_type',
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
  name: 'non_exhaustive_switch_expression',
  problemMessage:
      "The type '{0}' isn't exhaustively matched by the switch cases since it "
      "doesn't match the pattern '{1}'.",
  correctionMessage: "Try adding a wildcard pattern or cases that match '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_exhaustive_switch_expression',
  withArguments: _withArgumentsNonExhaustiveSwitchExpression,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nonExhaustiveSwitchExpressionPrivate = DiagnosticWithArguments(
  name: 'non_exhaustive_switch_expression',
  problemMessage:
      "The enum '{0}' isn't exhaustively matched by the switch cases because "
      "some of the enum constants are private.",
  correctionMessage: "Try adding a wildcard pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_exhaustive_switch_expression_private',
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
  name: 'non_exhaustive_switch_statement',
  problemMessage:
      "The type '{0}' isn't exhaustively matched by the switch cases since it "
      "doesn't match the pattern '{1}'.",
  correctionMessage: "Try adding a default case or cases that match '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_exhaustive_switch_statement',
  withArguments: _withArgumentsNonExhaustiveSwitchStatement,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type type: the type of the switch scrutinee
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nonExhaustiveSwitchStatementPrivate = DiagnosticWithArguments(
  name: 'non_exhaustive_switch_statement',
  problemMessage:
      "The enum '{0}' isn't exhaustively matched by the switch cases because "
      "some of the enum constants are private.",
  correctionMessage: "Try adding a default case.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_exhaustive_switch_statement_private',
  withArguments: _withArgumentsNonExhaustiveSwitchStatementPrivate,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonFinalFieldInEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_final_field_in_enum',
      problemMessage: "Enums can only declare final fields.",
      correctionMessage: "Try making the field final.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_final_field_in_enum',
      expectedTypes: [],
    );

/// Parameters:
/// Element constructor: the non-generative constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required Element constructor})
>
nonGenerativeConstructor = DiagnosticWithArguments(
  name: 'non_generative_constructor',
  problemMessage:
      "The generative constructor '{0}' is expected, but a factory was found.",
  correctionMessage:
      "Try calling a different constructor of the superclass, or making the "
      "called constructor not be a factory constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_generative_constructor',
  withArguments: _withArgumentsNonGenerativeConstructor,
  expectedTypes: [ExpectedType.element],
);

/// Parameters:
/// String superclassName: the name of the superclass
/// String className: the name of the current class
/// Element factoryConstructor: the implicitly called factory constructor of
///                             the superclass
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String superclassName,
    required String className,
    required Element factoryConstructor,
  })
>
nonGenerativeImplicitConstructor = DiagnosticWithArguments(
  name: 'non_generative_implicit_constructor',
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
  uniqueName: 'non_generative_implicit_constructor',
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
      name: 'non_identifier_library_name',
      problemMessage: "The name of a library must be an identifier.",
      correctionMessage: "Try using an identifier as the name of the library.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'non_identifier_library_name',
      expectedTypes: [],
    );

/// Parameters:
/// Type type: the type that should be a valid dart:ffi native type.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
nonNativeFunctionTypeArgumentToPointer = DiagnosticWithArguments(
  name: 'non_native_function_type_argument_to_pointer',
  problemMessage:
      "Can't invoke 'asFunction' because the function signature '{0}' for the "
      "pointer isn't a valid C function signature.",
  correctionMessage:
      "Try changing the function argument in 'NativeFunction' to only use "
      "NativeTypes.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_native_function_type_argument_to_pointer',
  withArguments: _withArgumentsNonNativeFunctionTypeArgumentToPointer,
  expectedTypes: [ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonNullableEqualsParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_nullable_equals_parameter',
      problemMessage:
          "The parameter type of '==' operators should be non-nullable.",
      correctionMessage: "Try using a non-nullable type.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'non_nullable_equals_parameter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonPartOfDirectiveInPart = DiagnosticWithoutArgumentsImpl(
  name: 'non_part_of_directive_in_part',
  problemMessage: "The part-of directive must be the only directive in a part.",
  correctionMessage:
      "Try removing the other directives, or moving them to the library for "
      "which this is a part.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'non_part_of_directive_in_part',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nonPositiveArrayDimension =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_positive_array_dimension',
      problemMessage: "Array dimensions must be positive numbers.",
      correctionMessage: "Try changing the input to a positive number.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_positive_array_dimension',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
nonRedirectingGenerativeConstructorWithPrimary = DiagnosticWithoutArgumentsImpl(
  name: 'non_redirecting_generative_constructor_with_primary',
  problemMessage:
      "Classes with primary constructors can't have non-redirecting generative "
      "constructors.",
  correctionMessage:
      "Try making the constructor redirect to the primary constructor, or "
      "remove the primary constructor.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_redirecting_generative_constructor_with_primary',
  expectedTypes: [],
);

/// A code indicating that the activity is set to be non resizable.
///
/// No parameters.
const DiagnosticWithoutArguments
nonResizableActivity = DiagnosticWithoutArgumentsImpl(
  name: 'non_resizable_activity',
  problemMessage:
      "The `<activity>` element should be allowed to be resized to allow users "
      "to take advantage of the multi-window environment on Chrome OS",
  correctionMessage:
      "Consider declaring the corresponding activity element with "
      "`resizableActivity=\"true\"` attribute.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'non_resizable_activity',
  expectedTypes: [],
);

/// Parameters:
/// String fieldName: the name of the field
/// Type type: the type of the field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String fieldName,
    required DartType type,
  })
>
nonSizedTypeArgument = DiagnosticWithArguments(
  name: 'non_sized_type_argument',
  problemMessage:
      "The type '{1}' isn't a valid type argument for '{0}'. The type argument "
      "must be a native integer, 'Float', 'Double', 'Pointer', or subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try using a native integer, 'Float', 'Double', 'Pointer', or subtype "
      "of 'Struct', 'Union', or 'AbiSpecificInteger'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_sized_type_argument',
  withArguments: _withArgumentsNonSizedTypeArgument,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments nonStringLiteralAsUri =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_string_literal_as_uri',
      problemMessage: "The URI must be a string literal.",
      correctionMessage:
          "Try enclosing the URI in either single or double quotes.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'non_string_literal_as_uri',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonSyncFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_sync_factory',
      problemMessage: "Factory bodies can't use 'async', 'async*', or 'sync*'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_sync_factory',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name appearing where a type is expected
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
nonTypeAsTypeArgument = DiagnosticWithArguments(
  name: 'non_type_as_type_argument',
  problemMessage:
      "The name '{0}' isn't a type, so it can't be used as a type argument.",
  correctionMessage:
      "Try correcting the name to an existing type, or defining a type named "
      "'{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_type_as_type_argument',
  withArguments: _withArgumentsNonTypeAsTypeArgument,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the non-type element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
nonTypeInCatchClause = DiagnosticWithArguments(
  name: 'non_type_in_catch_clause',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in an on-catch clause.",
  correctionMessage: "Try correcting the name to match an existing class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'non_type_in_catch_clause',
  withArguments: _withArgumentsNonTypeInCatchClause,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments nonVoidReturnForOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_void_return_for_operator',
      problemMessage: "The return type of the operator []= must be 'void'.",
      correctionMessage: "Try changing the return type to 'void'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_void_return_for_operator',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nonVoidReturnForSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'non_void_return_for_setter',
      problemMessage: "The return type of the setter must be 'void' or absent.",
      correctionMessage:
          "Try removing the return type, or define a method rather than a "
          "setter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'non_void_return_for_setter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments normalBeforeOptionalParameters =
    DiagnosticWithoutArgumentsImpl(
      name: 'normal_before_optional_parameters',
      problemMessage:
          "Normal parameters must occur before optional parameters.",
      correctionMessage:
          "Try moving all of the normal parameters before the optional "
          "parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'normal_before_optional_parameters',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notAssignedPotentiallyNonNullableLocalVariable = DiagnosticWithArguments(
  name: 'not_assigned_potentially_non_nullable_local_variable',
  problemMessage:
      "The non-nullable local variable '{0}' must be assigned before it can be "
      "used.",
  correctionMessage:
      "Try giving it an initializer expression, or ensure that it's assigned "
      "on every execution path.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_assigned_potentially_non_nullable_local_variable',
  withArguments: _withArgumentsNotAssignedPotentiallyNonNullableLocalVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name that is not a type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notAType = DiagnosticWithArguments(
  name: 'not_a_type',
  problemMessage: "{0} isn't a type.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_a_type',
  withArguments: _withArgumentsNotAType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the operator that is not a binary operator.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notBinaryOperator = DiagnosticWithArguments(
  name: 'not_binary_operator',
  problemMessage: "'{0}' isn't a binary operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_binary_operator',
  withArguments: _withArgumentsNotBinaryOperator,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// int requiredParameterCount: the expected number of required arguments
/// int actualArgumentCount: the actual number of positional arguments given
/// String name: name of the function or method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required int requiredParameterCount,
    required int actualArgumentCount,
    required String name,
  })
>
notEnoughPositionalArgumentsNamePlural = DiagnosticWithArguments(
  name: 'not_enough_positional_arguments',
  problemMessage: "{0} positional arguments expected by '{2}', but {1} found.",
  correctionMessage: "Try adding the missing arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_enough_positional_arguments_name_plural',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsNamePlural,
  expectedTypes: [ExpectedType.int, ExpectedType.int, ExpectedType.string],
);

/// Parameters:
/// String name: name of the function or method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notEnoughPositionalArgumentsNameSingular = DiagnosticWithArguments(
  name: 'not_enough_positional_arguments',
  problemMessage: "1 positional argument expected by '{0}', but 0 found.",
  correctionMessage: "Try adding the missing argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_enough_positional_arguments_name_singular',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsNameSingular,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// int requiredParameterCount: the expected number of required arguments
/// int actualArgumentCount: the actual number of positional arguments given
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required int requiredParameterCount,
    required int actualArgumentCount,
  })
>
notEnoughPositionalArgumentsPlural = DiagnosticWithArguments(
  name: 'not_enough_positional_arguments',
  problemMessage: "{0} positional arguments expected, but {1} found.",
  correctionMessage: "Try adding the missing arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_enough_positional_arguments_plural',
  withArguments: _withArgumentsNotEnoughPositionalArgumentsPlural,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments notEnoughPositionalArgumentsSingular =
    DiagnosticWithoutArgumentsImpl(
      name: 'not_enough_positional_arguments',
      problemMessage: "1 positional argument expected, but 0 found.",
      correctionMessage: "Try adding the missing argument.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'not_enough_positional_arguments_singular',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the field that is not initialized
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notInitializedNonNullableInstanceField = DiagnosticWithArguments(
  name: 'not_initialized_non_nullable_instance_field',
  problemMessage: "Non-nullable instance field '{0}' must be initialized.",
  correctionMessage:
      "Try adding an initializer expression, or a generative constructor "
      "that initializes it, or mark it 'late'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_initialized_non_nullable_instance_field',
  withArguments: _withArgumentsNotInitializedNonNullableInstanceField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the field that is not initialized
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notInitializedNonNullableInstanceFieldConstructor = DiagnosticWithArguments(
  name: 'not_initialized_non_nullable_instance_field',
  problemMessage: "Non-nullable instance field '{0}' must be initialized.",
  correctionMessage:
      "Try adding an initializer expression, or add a field initializer in "
      "this constructor, or mark it 'late'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_initialized_non_nullable_instance_field_constructor',
  withArguments:
      _withArgumentsNotInitializedNonNullableInstanceFieldConstructor,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the variable that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
notInitializedNonNullableVariable = DiagnosticWithArguments(
  name: 'not_initialized_non_nullable_variable',
  problemMessage: "The non-nullable variable '{0}' must be initialized.",
  correctionMessage: "Try adding an initializer expression.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_initialized_non_nullable_variable',
  withArguments: _withArgumentsNotInitializedNonNullableVariable,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments notInstantiatedBound =
    DiagnosticWithoutArgumentsImpl(
      name: 'not_instantiated_bound',
      problemMessage: "Type parameter bound types must be instantiated.",
      correctionMessage:
          "Try adding type arguments to the type parameter bound.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'not_instantiated_bound',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments notIterableSpread =
    DiagnosticWithoutArgumentsImpl(
      name: 'not_iterable_spread',
      problemMessage:
          "Spread elements in list or set literals must implement 'Iterable'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'not_iterable_spread',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments notMapSpread = DiagnosticWithoutArgumentsImpl(
  name: 'not_map_spread',
  problemMessage: "Spread elements in map literals must implement 'Map'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_map_spread',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
notNullAwareNullSpread = DiagnosticWithoutArgumentsImpl(
  name: 'not_null_aware_null_spread',
  problemMessage:
      "The Null-typed expression can't be used with a non-null-aware spread.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'not_null_aware_null_spread',
  expectedTypes: [],
);

/// A code indicating that the touchscreen feature is not specified in the
/// manifest.
///
/// No parameters.
const DiagnosticWithoutArguments
noTouchscreenFeature = DiagnosticWithoutArgumentsImpl(
  name: 'no_touchscreen_feature',
  problemMessage:
      "The default \"android.hardware.touchscreen\" needs to be optional for "
      "Chrome OS.",
  correctionMessage:
      "Consider adding <uses-feature "
      "android:name=\"android.hardware.touchscreen\" android:required=\"false\" "
      "/> to the manifest.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'no_touchscreen_feature',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nullableTypeInCatchClause = DiagnosticWithoutArgumentsImpl(
  name: 'nullable_type_in_catch_clause',
  problemMessage:
      "A potentially nullable type can't be used in an 'on' clause because it "
      "isn't valid to throw a nullable expression.",
  correctionMessage: "Try using a non-nullable type.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'nullable_type_in_catch_clause',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInExtendsClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'nullable_type_in_extends_clause',
      problemMessage: "A class can't extend a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'nullable_type_in_extends_clause',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInImplementsClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'nullable_type_in_implements_clause',
      problemMessage:
          "A class, mixin, or extension type can't implement a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'nullable_type_in_implements_clause',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInOnClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'nullable_type_in_on_clause',
      problemMessage:
          "A mixin can't have a nullable type as a superclass constraint.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'nullable_type_in_on_clause',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments nullableTypeInWithClause =
    DiagnosticWithoutArgumentsImpl(
      name: 'nullable_type_in_with_clause',
      problemMessage: "A class or mixin can't mix in a nullable type.",
      correctionMessage: "Try removing the question mark.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'nullable_type_in_with_clause',
      expectedTypes: [],
    );

/// Parameters:
/// String memberName: the name of the member being invoked
/// String typeArgumentName: the type argument associated with the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required String typeArgumentName,
  })
>
nullArgumentToNonNullType = DiagnosticWithArguments(
  name: 'null_argument_to_non_null_type',
  problemMessage:
      "'{0}' shouldn't be called with a 'null' argument for the non-nullable "
      "type argument '{1}'.",
  correctionMessage: "Try adding a non-null argument.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'null_argument_to_non_null_type',
  withArguments: _withArgumentsNullArgumentToNonNullType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
nullAwareCascadeOutOfOrder = DiagnosticWithoutArgumentsImpl(
  name: 'null_aware_cascade_out_of_order',
  problemMessage:
      "The '?..' cascade operator must be first in the cascade sequence.",
  correctionMessage:
      "Try moving the '?..' operator to be the first cascade operator in the "
      "sequence.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'null_aware_cascade_out_of_order',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
nullCheckAlwaysFails = DiagnosticWithoutArgumentsImpl(
  name: 'null_check_always_fails',
  problemMessage:
      "This null-check will always throw an exception because the expression "
      "will always evaluate to 'null'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'null_check_always_fails',
  expectedTypes: [],
);

/// 7.9 Superclasses: It is a compile-time error to specify an extends clause
/// for class Object.
///
/// No parameters.
const DiagnosticWithoutArguments objectCannotExtendAnotherClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'object_cannot_extend_another_class',
      problemMessage: "The class 'Object' can't extend any other class.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'object_cannot_extend_another_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments obsoleteColonForDefaultValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'obsolete_colon_for_default_value',
      problemMessage:
          "Using a colon as the separator before a default value is no longer "
          "supported.",
      correctionMessage: "Try replacing the colon with an equal sign.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'obsolete_colon_for_default_value',
      expectedTypes: [],
    );

/// Parameters:
/// String interfaceName: the name of the interface that is implemented more
///                       than once
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String interfaceName})
>
onRepeated = DiagnosticWithArguments(
  name: 'on_repeated',
  problemMessage:
      "The type '{0}' can be included in the superclass constraints only once.",
  correctionMessage: "Try removing all except one occurrence of the type name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'on_repeated',
  withArguments: _withArgumentsOnRepeated,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments optionalParameterInOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'optional_parameter_in_operator',
      problemMessage:
          "Optional parameters aren't allowed when defining an operator.",
      correctionMessage: "Try removing the optional parameters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'optional_parameter_in_operator',
      expectedTypes: [],
    );

/// Parameters:
/// String expectedEarlierClause: The kind of clause that must come earlier.
/// String expectedLaterClause: The kind of clause that must come later.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String expectedEarlierClause,
    required String expectedLaterClause,
  })
>
outOfOrderClauses = DiagnosticWithArguments(
  name: 'out_of_order_clauses',
  problemMessage: "The '{0}' clause must come before the '{1}' clause.",
  correctionMessage: "Try moving the '{0}' clause before the '{1}' clause.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'out_of_order_clauses',
  withArguments: _withArgumentsOutOfOrderClauses,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// A field with the override annotation does not override a getter or setter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingField =
    DiagnosticWithoutArgumentsImpl(
      name: 'override_on_non_overriding_member',
      problemMessage:
          "The field doesn't override an inherited getter or setter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'override_on_non_overriding_field',
      expectedTypes: [],
    );

/// A getter with the override annotation does not override an existing getter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingGetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'override_on_non_overriding_member',
      problemMessage: "The getter doesn't override an inherited getter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'override_on_non_overriding_getter',
      expectedTypes: [],
    );

/// A method with the override annotation does not override an existing method.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'override_on_non_overriding_member',
      problemMessage: "The method doesn't override an inherited method.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'override_on_non_overriding_method',
      expectedTypes: [],
    );

/// A setter with the override annotation does not override an existing setter.
///
/// No parameters.
const DiagnosticWithoutArguments overrideOnNonOverridingSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'override_on_non_overriding_member',
      problemMessage: "The setter doesn't override an inherited setter.",
      correctionMessage:
          "Try updating this class to match the superclass, or removing the "
          "override annotation.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'override_on_non_overriding_setter',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments packedAnnotation =
    DiagnosticWithoutArgumentsImpl(
      name: 'packed_annotation',
      problemMessage: "Structs must have at most one 'Packed' annotation.",
      correctionMessage: "Try removing extra 'Packed' annotations.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'packed_annotation',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
packedAnnotationAlignment = DiagnosticWithoutArgumentsImpl(
  name: 'packed_annotation_alignment',
  problemMessage: "Only packing to 1, 2, 4, 8, and 16 bytes is supported.",
  correctionMessage:
      "Try changing the 'Packed' annotation alignment to 1, 2, 4, 8, or 16.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'packed_annotation_alignment',
  expectedTypes: [],
);

/// An error code indicating that there is a syntactic error in the file.
///
/// Parameters:
/// String errorMessage: the error message from the parse error
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String errorMessage})
>
parseError = DiagnosticWithArguments(
  name: 'parse_error',
  problemMessage: "{0}",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'parse_error',
  withArguments: _withArgumentsParseError,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String expectedName: the name of expected library name
/// String actualName: the non-matching actual library name from the "part of"
///                    declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String expectedName,
    required String actualName,
  })
>
partOfDifferentLibrary = DiagnosticWithArguments(
  name: 'part_of_different_library',
  problemMessage: "Expected this library to be part of '{0}', not '{1}'.",
  correctionMessage:
      "Try including a different part, or changing the name of the library "
      "in the part's part-of directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'part_of_different_library',
  withArguments: _withArgumentsPartOfDifferentLibrary,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments partOfName = DiagnosticWithoutArgumentsImpl(
  name: 'part_of_name',
  problemMessage:
      "The 'part of' directive can't use a name with the enhanced-parts feature.",
  correctionMessage: "Try using 'part of' with a URI instead.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'part_of_name',
  expectedTypes: [],
);

/// Parameters:
/// String uriStr: the URI pointing to a non-library declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uriStr})
>
partOfNonPart = DiagnosticWithArguments(
  name: 'part_of_non_part',
  problemMessage: "The included part '{0}' must have a part-of directive.",
  correctionMessage: "Try adding a part-of directive to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'part_of_non_part',
  withArguments: _withArgumentsPartOfNonPart,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String libraryName: the non-matching actual library name from the "part
///                     of" declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String libraryName})
>
partOfUnnamedLibrary = DiagnosticWithArguments(
  name: 'part_of_unnamed_library',
  problemMessage:
      "The library is unnamed. A URI is expected, not a library name '{0}', in "
      "the part-of directive.",
  correctionMessage:
      "Try changing the part-of directive to a URI, or try including a "
      "different part.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'part_of_unnamed_library',
  withArguments: _withArgumentsPartOfUnnamedLibrary,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String path: the path to the dependency as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
pathDoesNotExist = DiagnosticWithArguments(
  name: 'path_does_not_exist',
  problemMessage: "The path '{0}' doesn't exist.",
  correctionMessage:
      "Try creating the referenced path or using a path that exists.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'path_does_not_exist',
  withArguments: _withArgumentsPathDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String path: the path as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
pathNotPosix = DiagnosticWithArguments(
  name: 'path_not_posix',
  problemMessage: "The path '{0}' isn't a POSIX-style path.",
  correctionMessage: "Try converting the value to a POSIX-style path.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'path_not_posix',
  withArguments: _withArgumentsPathNotPosix,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String path: the path to the dependency as given in the file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
pathPubspecDoesNotExist = DiagnosticWithArguments(
  name: 'path_pubspec_does_not_exist',
  problemMessage: "The directory '{0}' doesn't contain a pubspec.",
  correctionMessage:
      "Try creating a pubspec in the referenced directory or using a path "
      "that has a pubspec.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'path_pubspec_does_not_exist',
  withArguments: _withArgumentsPathPubspecDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Name variableName: The name of the variable that was erroneously declared.
const DiagnosticCode patternAssignmentDeclaresVariable =
    DiagnosticCodeWithExpectedTypes(
      name: 'pattern_assignment_declares_variable',
      problemMessage:
          "Variable '{0}' can't be declared in a pattern assignment.",
      correctionMessage:
          "Try using a preexisting variable or changing the assignment to a "
          "pattern variable declaration.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'pattern_assignment_declares_variable',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments patternAssignmentNotLocalVariable =
    DiagnosticWithoutArgumentsImpl(
      name: 'pattern_assignment_not_local_variable',
      problemMessage:
          "Only local variables can be assigned in pattern assignments.",
      correctionMessage: "Try assigning to a local variable.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'pattern_assignment_not_local_variable',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments patternConstantFromDeferredLibrary =
    DiagnosticWithoutArgumentsImpl(
      name: 'pattern_constant_from_deferred_library',
      problemMessage:
          "Constant values from a deferred library can't be used in patterns.",
      correctionMessage: "Try removing the keyword 'deferred' from the import.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'pattern_constant_from_deferred_library',
      expectedTypes: [],
    );

/// Parameters:
/// Type matchedValueType: the matched value type
/// Type requiredType: the required pattern type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType matchedValueType,
    required DartType requiredType,
  })
>
patternNeverMatchesValueType = DiagnosticWithArguments(
  name: 'pattern_never_matches_value_type',
  problemMessage:
      "The matched value type '{0}' can never match the required type '{1}'.",
  correctionMessage: "Try using a different pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'pattern_never_matches_value_type',
  withArguments: _withArgumentsPatternNeverMatchesValueType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type matchedType: the matched type
/// Type requiredType: the required type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType matchedType,
    required DartType requiredType,
  })
>
patternTypeMismatchInIrrefutableContext = DiagnosticWithArguments(
  name: 'pattern_type_mismatch_in_irrefutable_context',
  problemMessage:
      "The matched value of type '{0}' isn't assignable to the required type "
      "'{1}'.",
  correctionMessage:
      "Try changing the required type of the pattern, or the matched value "
      "type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'pattern_type_mismatch_in_irrefutable_context',
  withArguments: _withArgumentsPatternTypeMismatchInIrrefutableContext,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments
patternVariableAssignmentInsideGuard = DiagnosticWithoutArgumentsImpl(
  name: 'pattern_variable_assignment_inside_guard',
  problemMessage:
      "Pattern variables can't be assigned inside the guard of the enclosing "
      "guarded pattern.",
  correctionMessage: "Try assigning to a different variable.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'pattern_variable_assignment_inside_guard',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
patternVariableDeclarationOutsideFunctionOrMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'pattern_variable_declaration_outside_function_or_method',
      problemMessage:
          "A pattern variable declaration may not appear outside a function or "
          "method.",
      correctionMessage:
          "Try declaring ordinary variables and assigning from within a function "
          "or method.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'pattern_variable_declaration_outside_function_or_method',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
patternVariableSharedCaseScopeDifferentFinalityOrType = DiagnosticWithArguments(
  name: 'invalid_pattern_variable_in_shared_case_scope',
  problemMessage:
      "The variable '{0}' doesn't have the same type and/or finality in all "
      "cases that share this body.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "all cases.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'pattern_variable_shared_case_scope_different_finality_or_type',
  withArguments:
      _withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
patternVariableSharedCaseScopeHasLabel = DiagnosticWithArguments(
  name: 'invalid_pattern_variable_in_shared_case_scope',
  problemMessage:
      "The variable '{0}' is not available because there is a label or 'default' "
      "case.",
  correctionMessage:
      "Try removing the label, or providing the 'default' case with its own "
      "body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'pattern_variable_shared_case_scope_has_label',
  withArguments: _withArgumentsPatternVariableSharedCaseScopeHasLabel,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the pattern variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
patternVariableSharedCaseScopeNotAllCases = DiagnosticWithArguments(
  name: 'invalid_pattern_variable_in_shared_case_scope',
  problemMessage:
      "The variable '{0}' is available in some, but not all cases that share "
      "this body.",
  correctionMessage:
      "Try declaring the variable pattern with the same type and finality in "
      "all cases.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'pattern_variable_shared_case_scope_not_all_cases',
  withArguments: _withArgumentsPatternVariableSharedCaseScopeNotAllCases,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified permission is not supported on Chrome
/// OS.
///
/// Parameters:
/// String name: the name of the feature tag
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
permissionImpliesUnsupportedHardware = DiagnosticWithArguments(
  name: 'permission_implies_unsupported_hardware',
  problemMessage:
      "Permission makes app incompatible for Chrome OS, consider adding optional "
      "{0} feature tag,",
  correctionMessage:
      " Try adding `<uses-feature android:name=\"{0}\"  "
      "android:required=\"false\">`.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'permission_implies_unsupported_hardware',
  withArguments: _withArgumentsPermissionImpliesUnsupportedHardware,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments platformValueDisallowed =
    DiagnosticWithoutArgumentsImpl(
      name: 'platform_value_disallowed',
      problemMessage: "Keys in the `platforms` field can't have values.",
      correctionMessage: "Try removing the value, while keeping the key.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'platform_value_disallowed',
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
  name: 'plugins_in_inner_options',
  problemMessage:
      "Plugins can only be specified in the root of a pub workspace or the root "
      "of a package that isn't in a workspace.",
  correctionMessage:
      "Try specifying plugins in an analysis options file at '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'plugins_in_inner_options',
  withArguments: _withArgumentsPluginsInInnerOptions,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments positionalAfterNamedArgument =
    DiagnosticWithoutArgumentsImpl(
      name: 'positional_after_named_argument',
      problemMessage: "Positional arguments must occur before named arguments.",
      correctionMessage:
          "Try moving all of the positional arguments before the named "
          "arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'positional_after_named_argument',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments positionalFieldInObjectPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'positional_field_in_object_pattern',
      problemMessage: "Object patterns can only use named fields.",
      correctionMessage: "Try specifying the field name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'positional_field_in_object_pattern',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
positionalParameterOutsideGroup = DiagnosticWithoutArgumentsImpl(
  name: 'positional_parameter_outside_group',
  problemMessage:
      "Positional parameters must be enclosed in square brackets ('[' and ']').",
  correctionMessage:
      "Try surrounding the positional parameters in square brackets.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'positional_parameter_outside_group',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
positionalSuperFormalParameterWithPositionalArgument =
    DiagnosticWithoutArgumentsImpl(
      name: 'positional_super_formal_parameter_with_positional_argument',
      problemMessage:
          "Positional super parameters can't be used when the super constructor "
          "invocation has a positional argument.",
      correctionMessage:
          "Try making all the positional parameters passed to the super "
          "constructor be either all super parameters or all normal parameters.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'positional_super_formal_parameter_with_positional_argument',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
prefixAfterCombinator = DiagnosticWithoutArgumentsImpl(
  name: 'prefix_after_combinator',
  problemMessage:
      "The prefix ('as' clause) should come before any show/hide combinators.",
  correctionMessage: "Try moving the prefix before the combinators.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'prefix_after_combinator',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
prefixCollidesWithTopLevelMember = DiagnosticWithArguments(
  name: 'prefix_collides_with_top_level_member',
  problemMessage:
      "The name '{0}' is already used as an import prefix and can't be used to "
      "name a top-level element.",
  correctionMessage: "Try renaming either the top-level element or the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'prefix_collides_with_top_level_member',
  withArguments: _withArgumentsPrefixCollidesWithTopLevelMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
prefixIdentifierNotFollowedByDot = DiagnosticWithArguments(
  name: 'prefix_identifier_not_followed_by_dot',
  problemMessage:
      "The name '{0}' refers to an import prefix, so it must be followed by '.'.",
  correctionMessage:
      "Try correcting the name to refer to something other than a prefix, or "
      "renaming the prefix.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'prefix_identifier_not_followed_by_dot',
  withArguments: _withArgumentsPrefixIdentifierNotFollowedByDot,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String prefix: the prefix being shadowed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String prefix})
>
prefixShadowedByLocalDeclaration = DiagnosticWithArguments(
  name: 'prefix_shadowed_by_local_declaration',
  problemMessage:
      "The prefix '{0}' can't be used here because it's shadowed by a local "
      "declaration.",
  correctionMessage: "Try renaming either the prefix or the local declaration.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'prefix_shadowed_by_local_declaration',
  withArguments: _withArgumentsPrefixShadowedByLocalDeclaration,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
primaryConstructorBodyWithoutDeclaration = DiagnosticWithoutArgumentsImpl(
  name: 'primary_constructor_body_without_declaration',
  problemMessage:
      "A primary constructor body requires a primary constructor declaration.",
  correctionMessage: "Try adding the primary constructor declaration.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'primary_constructor_body_without_declaration',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments primaryConstructorCannotRedirect =
    DiagnosticWithoutArgumentsImpl(
      name: 'primary_constructor_cannot_redirect',
      problemMessage:
          "A primary constructor can't be a redirecting constructor.",
      correctionMessage: "Try removing the redirect.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'primary_constructor_cannot_redirect',
      expectedTypes: [],
    );

/// Parameters:
/// String collidingName: the private name that collides
/// String mixin1: the name of the first mixin
/// String mixin2: the name of the second mixin
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String collidingName,
    required String mixin1,
    required String mixin2,
  })
>
privateCollisionInMixinApplication = DiagnosticWithArguments(
  name: 'private_collision_in_mixin_application',
  problemMessage:
      "The private name '{0}', defined by '{1}', conflicts with the same name "
      "defined by '{2}'.",
  correctionMessage: "Try removing '{1}' from the 'with' clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'private_collision_in_mixin_application',
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
  name: 'private_named_non_field_parameter',
  problemMessage:
      "Named parameters that don't refer to instance variables can't start with "
      "underscore.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'private_named_non_field_parameter',
  expectedTypes: [],
);

/// Parameters:
/// String name: the corresponding public name of private named parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
privateNamedParameterDuplicatePublicName = DiagnosticWithArguments(
  name: 'private_named_parameter_duplicate_public_name',
  problemMessage:
      "The corresponding public name '{0}' is already the name of another "
      "parameter.",
  correctionMessage: "Try renaming one of the parameters.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'private_named_parameter_duplicate_public_name',
  withArguments: _withArgumentsPrivateNamedParameterDuplicatePublicName,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
privateNamedParameterWithoutPublicName = DiagnosticWithoutArgumentsImpl(
  name: 'private_named_parameter_without_public_name',
  problemMessage:
      "A private named parameter must be a public identifier after removing the "
      "leading underscore.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'private_named_parameter_without_public_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments privateOptionalParameter =
    DiagnosticWithoutArgumentsImpl(
      name: 'private_optional_parameter',
      problemMessage: "Named parameters can't start with an underscore.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'private_optional_parameter',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the setter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
privateSetter = DiagnosticWithArguments(
  name: 'private_setter',
  problemMessage:
      "The setter '{0}' is private and can't be accessed outside the library "
      "that declares it.",
  correctionMessage: "Try making it public.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'private_setter',
  withArguments: _withArgumentsPrivateSetter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
readPotentiallyUnassignedFinal = DiagnosticWithArguments(
  name: 'read_potentially_unassigned_final',
  problemMessage:
      "The final variable '{0}' can't be read because it's potentially "
      "unassigned at this point.",
  correctionMessage: "Ensure that it is assigned on necessary execution paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'read_potentially_unassigned_final',
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
  name: 'receiver_of_type_never',
  problemMessage:
      "The receiver is of type 'Never', and will never complete with a value.",
  correctionMessage:
      "Try checking for throw expressions or type errors in the receiver",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'receiver_of_type_never',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
recordLiteralOnePositionalNoTrailingComma = DiagnosticWithoutArgumentsImpl(
  name: 'record_literal_one_positional_no_trailing_comma',
  problemMessage:
      "A record literal with exactly one positional field requires a trailing "
      "comma.",
  correctionMessage: "Try adding a trailing comma.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'record_literal_one_positional_no_trailing_comma',
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
  name: 'record_literal_one_positional_no_trailing_comma',
  problemMessage:
      "A record literal with exactly one positional field requires a trailing "
      "comma.",
  correctionMessage: "Try adding a trailing comma.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'record_literal_one_positional_no_trailing_comma_by_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments recordTypeOnePositionalNoTrailingComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'record_type_one_positional_no_trailing_comma',
      problemMessage:
          "A record type with exactly one positional field requires a trailing "
          "comma.",
      correctionMessage: "Try adding a trailing comma.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'record_type_one_positional_no_trailing_comma',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments recursiveCompileTimeConstant =
    DiagnosticWithoutArgumentsImpl(
      name: 'recursive_compile_time_constant',
      problemMessage: "The compile-time constant expression depends on itself.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'recursive_compile_time_constant',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments recursiveConstantConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'recursive_constant_constructor',
      problemMessage: "The constant constructor depends on itself.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'recursive_constant_constructor',
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
  name: 'recursive_constructor_redirect',
  problemMessage:
      "Constructors can't redirect to themselves either directly or indirectly.",
  correctionMessage:
      "Try changing one of the constructors in the loop to not redirect.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_constructor_redirect',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
recursiveFactoryRedirect = DiagnosticWithoutArgumentsImpl(
  name: 'recursive_constructor_redirect',
  problemMessage:
      "Constructors can't redirect to themselves either directly or indirectly.",
  correctionMessage:
      "Try changing one of the constructors in the loop to not redirect.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_factory_redirect',
  expectedTypes: [],
);

/// An error code indicating a specified include file includes itself recursively.
///
/// Parameters:
/// Object includedUri: the URI of the file to be included
/// Object includingFilePath: the path of the file containing the include
///                           directive
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required Object includedUri,
    required Object includingFilePath,
  })
>
recursiveIncludeFile = DiagnosticWithArguments(
  name: 'recursive_include_file',
  problemMessage:
      "The URI '{0}' included in '{1}' includes '{1}', creating a circular "
      "reference.",
  correctionMessage:
      "Try changing the chain of 'include's to break the circularity.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'recursive_include_file',
  withArguments: _withArgumentsRecursiveIncludeFile,
  expectedTypes: [ExpectedType.object, ExpectedType.object],
);

/// Parameters:
/// String className: the name of the class that implements itself recursively
/// String loop: a string representation of the implements loop
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String loop,
  })
>
recursiveInterfaceInheritance = DiagnosticWithArguments(
  name: 'recursive_interface_inheritance',
  problemMessage: "'{0}' can't be a superinterface of itself: {1}.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_interface_inheritance',
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
/// String className: the name of the class that implements itself recursively
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
recursiveInterfaceInheritanceExtends = DiagnosticWithArguments(
  name: 'recursive_interface_inheritance',
  problemMessage: "'{0}' can't extend itself.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_interface_inheritance_extends',
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
/// String className: the name of the class that implements itself recursively
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
recursiveInterfaceInheritanceImplements = DiagnosticWithArguments(
  name: 'recursive_interface_inheritance',
  problemMessage: "'{0}' can't implement itself.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_interface_inheritance_implements',
  withArguments: _withArgumentsRecursiveInterfaceInheritanceImplements,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String mixinName: the name of the mixin that constraints itself
///                   recursively
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String mixinName})
>
recursiveInterfaceInheritanceOn = DiagnosticWithArguments(
  name: 'recursive_interface_inheritance',
  problemMessage: "'{0}' can't use itself as a superclass constraint.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_interface_inheritance_on',
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
/// String className: the name of the class that implements itself recursively
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
recursiveInterfaceInheritanceWith = DiagnosticWithArguments(
  name: 'recursive_interface_inheritance',
  problemMessage: "'{0}' can't use itself as a mixin.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'recursive_interface_inheritance_with',
  withArguments: _withArgumentsRecursiveInterfaceInheritanceWith,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating the use of a redeclare annotation on a member that does not redeclare.
///
/// Parameters:
/// String kind: the kind of member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String kind})
>
redeclareOnNonRedeclaringMember = DiagnosticWithArguments(
  name: 'redeclare_on_non_redeclaring_member',
  problemMessage:
      "The {0} doesn't redeclare a {0} declared in a superinterface.",
  correctionMessage:
      "Try updating this member to match a declaration in a superinterface, "
      "or removing the redeclare annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'redeclare_on_non_redeclaring_member',
  withArguments: _withArgumentsRedeclareOnNonRedeclaringMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String constructorName: the name of the constructor
/// String className: the name of the class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String constructorName,
    required String className,
  })
>
redirectGenerativeToMissingConstructor = DiagnosticWithArguments(
  name: 'redirect_generative_to_missing_constructor',
  problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
  correctionMessage:
      "Try redirecting to a different constructor, or defining the "
      "constructor named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_generative_to_missing_constructor',
  withArguments: _withArgumentsRedirectGenerativeToMissingConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments redirectGenerativeToNonGenerativeConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'redirect_generative_to_non_generative_constructor',
      problemMessage:
          "Generative constructors can't redirect to a factory constructor.",
      correctionMessage: "Try redirecting to a different constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'redirect_generative_to_non_generative_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
redirectingConstructorWithBody = DiagnosticWithoutArgumentsImpl(
  name: 'redirecting_constructor_with_body',
  problemMessage: "Redirecting constructors can't have a body.",
  correctionMessage:
      "Try removing the body, or not making this a redirecting constructor.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'redirecting_constructor_with_body',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments redirectionInNonFactoryConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'redirection_in_non_factory_constructor',
      problemMessage: "Only factory constructor can specify '=' redirection.",
      correctionMessage:
          "Try making this a factory constructor, or remove the redirection.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'redirection_in_non_factory_constructor',
      expectedTypes: [],
    );

/// Parameters:
/// String redirectingConstructorName: the name of the redirecting constructor
/// String abstractClass: the name of the abstract class defining the
///                       constructor being redirected to
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String redirectingConstructorName,
    required String abstractClass,
  })
>
redirectToAbstractClassConstructor = DiagnosticWithArguments(
  name: 'redirect_to_abstract_class_constructor',
  problemMessage:
      "The redirecting constructor '{0}' can't redirect to a constructor of the "
      "abstract class '{1}'.",
  correctionMessage: "Try redirecting to a constructor of a different class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_abstract_class_constructor',
  withArguments: _withArgumentsRedirectToAbstractClassConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type redirectedType: the name of the redirected constructor
/// Type redirectingType: the name of the redirecting constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType redirectedType,
    required DartType redirectingType,
  })
>
redirectToInvalidFunctionType = DiagnosticWithArguments(
  name: 'redirect_to_invalid_function_type',
  problemMessage:
      "The redirected constructor '{0}' has incompatible parameters with '{1}'.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_invalid_function_type',
  withArguments: _withArgumentsRedirectToInvalidFunctionType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type redirectedReturnType: the name of the redirected constructor's return
///                            type
/// Type redirectingReturnType: the name of the redirecting constructor's
///                             return type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType redirectedReturnType,
    required DartType redirectingReturnType,
  })
>
redirectToInvalidReturnType = DiagnosticWithArguments(
  name: 'redirect_to_invalid_return_type',
  problemMessage:
      "The return type '{0}' of the redirected constructor isn't a subtype of "
      "'{1}'.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_invalid_return_type',
  withArguments: _withArgumentsRedirectToInvalidReturnType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// String constructorName: the name of the constructor
/// Type redirectedType: the type being redirected to
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String constructorName,
    required DartType redirectedType,
  })
>
redirectToMissingConstructor = DiagnosticWithArguments(
  name: 'redirect_to_missing_constructor',
  problemMessage: "The constructor '{0}' couldn't be found in '{1}'.",
  correctionMessage:
      "Try redirecting to a different constructor, or define the constructor "
      "named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_missing_constructor',
  withArguments: _withArgumentsRedirectToMissingConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String name: the name of the non-type referenced in the redirect
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
redirectToNonClass = DiagnosticWithArguments(
  name: 'redirect_to_non_class',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in a redirected "
      "constructor.",
  correctionMessage: "Try redirecting to a different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_non_class',
  withArguments: _withArgumentsRedirectToNonClass,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments redirectToNonConstConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'redirect_to_non_const_constructor',
      problemMessage:
          "A constant redirecting constructor can't redirect to a non-constant "
          "constructor.",
      correctionMessage: "Try redirecting to a different constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'redirect_to_non_const_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
redirectToTypeAliasExpandsToTypeParameter = DiagnosticWithoutArgumentsImpl(
  name: 'redirect_to_type_alias_expands_to_type_parameter',
  problemMessage:
      "A redirecting constructor can't redirect to a type alias that expands to "
      "a type parameter.",
  correctionMessage: "Try replacing it with a class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'redirect_to_type_alias_expands_to_type_parameter',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
referencedBeforeDeclaration = DiagnosticWithArguments(
  name: 'referenced_before_declaration',
  problemMessage:
      "Local variable '{0}' can't be referenced before it is declared.",
  correctionMessage:
      "Try moving the declaration to before the first use, or renaming the "
      "local variable so that it doesn't hide a name from an enclosing "
      "scope.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'referenced_before_declaration',
  withArguments: _withArgumentsReferencedBeforeDeclaration,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
refutablePatternInIrrefutableContext = DiagnosticWithoutArgumentsImpl(
  name: 'refutable_pattern_in_irrefutable_context',
  problemMessage: "Refutable patterns can't be used in an irrefutable context.",
  correctionMessage:
      "Try using an if-case, a 'switch' statement, or a 'switch' expression "
      "instead.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'refutable_pattern_in_irrefutable_context',
  expectedTypes: [],
);

/// Parameters:
/// Type operandType: the operand type
/// Type parameterType: the parameter type of the invoked operator
/// String operator: the name of the invoked operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType operandType,
    required DartType parameterType,
    required String operator,
  })
>
relationalPatternOperandTypeNotAssignable = DiagnosticWithArguments(
  name: 'relational_pattern_operand_type_not_assignable',
  problemMessage:
      "The constant expression type '{0}' is not assignable to the parameter "
      "type '{1}' of the '{2}' operator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'relational_pattern_operand_type_not_assignable',
  withArguments: _withArgumentsRelationalPatternOperandTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
relationalPatternOperatorReturnTypeNotAssignableToBool =
    DiagnosticWithoutArgumentsImpl(
      name: 'relational_pattern_operator_return_type_not_assignable_to_bool',
      problemMessage:
          "The return type of operators used in relational patterns must be "
          "assignable to 'bool'.",
      correctionMessage:
          "Try updating the operator declaration to return 'bool'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName:
          'relational_pattern_operator_return_type_not_assignable_to_bool',
      expectedTypes: [],
    );

/// An error code indicating a removed lint rule.
///
/// Parameters:
/// String ruleName: the rule name
/// String sdkVersion: the SDK version in which the lint was removed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String sdkVersion,
  })
>
removedLint = DiagnosticWithArguments(
  name: 'removed_lint',
  problemMessage: "'{0}' was removed in Dart '{1}'",
  correctionMessage: "Try removing the reference to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'removed_lint',
  withArguments: _withArgumentsRemovedLint,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating use of a removed lint rule.
///
/// Parameters:
/// String ruleName: the rule name
/// String since: the SDK version in which the lint was removed
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String since,
  })
>
removedLintUse = DiagnosticWithArguments(
  name: 'removed_lint_use',
  problemMessage: "'{0}' was removed in Dart '{1}'",
  correctionMessage: "Remove the reference to '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'removed_lint_use',
  withArguments: _withArgumentsRemovedLintUse,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating a removed lint rule.
///
/// Parameters:
/// String ruleName: the rule name
/// String sdkVersion: the SDK version in which the lint was removed
/// String replacingLintName: the name of a replacing lint
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String sdkVersion,
    required String replacingLintName,
  })
>
replacedLint = DiagnosticWithArguments(
  name: 'replaced_lint',
  problemMessage: "'{0}' was replaced by '{2}' in Dart '{1}'.",
  correctionMessage: "Replace '{0}' with '{2}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'replaced_lint',
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
/// String ruleName: the rule name
/// String since: the SDK version in which the lint was removed
/// String replacement: the name of a replacing lint
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String ruleName,
    required String since,
    required String replacement,
  })
>
replacedLintUse = DiagnosticWithArguments(
  name: 'replaced_lint_use',
  problemMessage: "'{0}' was replaced by '{2}' in Dart '{1}'.",
  correctionMessage: "Replace '{0}' with '{2}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'replaced_lint_use',
  withArguments: _withArgumentsReplacedLintUse,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments representationFieldModifier =
    DiagnosticWithoutArgumentsImpl(
      name: 'representation_field_modifier',
      problemMessage: "Representation fields can't have modifiers.",
      correctionMessage: "Try removing the modifier.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'representation_field_modifier',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments representationFieldTrailingComma =
    DiagnosticWithoutArgumentsImpl(
      name: 'representation_field_trailing_comma',
      problemMessage: "The representation field can't have a trailing comma.",
      correctionMessage: "Try removing the trailing comma.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'representation_field_trailing_comma',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments restElementInMapPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'rest_element_in_map_pattern',
      problemMessage: "A map pattern can't contain a rest pattern.",
      correctionMessage: "Try removing the rest pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'rest_element_in_map_pattern',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments rethrowOutsideCatch =
    DiagnosticWithoutArgumentsImpl(
      name: 'rethrow_outside_catch',
      problemMessage: "A rethrow must be inside of a catch clause.",
      correctionMessage:
          "Try moving the expression into a catch clause, or using a 'throw' "
          "expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'rethrow_outside_catch',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments returnInGenerativeConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'return_in_generative_constructor',
      problemMessage: "Constructors can't return values.",
      correctionMessage:
          "Try removing the return statement or using a factory constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'return_in_generative_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
returnInGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'return_in_generator',
  problemMessage:
      "Can't return a value from a generator function that uses the 'async*' or "
      "'sync*' modifier.",
  correctionMessage:
      "Try replacing 'return' with 'yield', using a block function body, or "
      "changing the method body modifier.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'return_in_generator',
  expectedTypes: [],
);

/// Parameters:
/// String invokedFunction: the name of the annotated function being invoked
/// String returningFunction: the name of the function containing the return
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String invokedFunction,
    required String returningFunction,
  })
>
returnOfDoNotStore = DiagnosticWithArguments(
  name: 'return_of_do_not_store',
  problemMessage:
      "'{0}' is annotated with 'doNotStore' and shouldn't be returned unless "
      "'{1}' is also annotated.",
  correctionMessage: "Annotate '{1}' with 'doNotStore'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'return_of_do_not_store',
  withArguments: _withArgumentsReturnOfDoNotStore,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type actualType: the return type as declared in the return statement
/// Type expectedType: the expected return type as defined by the type of the
///                    Future
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
returnOfInvalidTypeFromCatchError = DiagnosticWithArguments(
  name: 'invalid_return_type_for_catch_error',
  problemMessage:
      "A value of type '{0}' can't be returned by the 'onError' handler because "
      "it must be assignable to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'return_of_invalid_type_from_catch_error',
  withArguments: _withArgumentsReturnOfInvalidTypeFromCatchError,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualReturnType: the return type as declared in the return statement
/// Type expectedReturnType: the expected return type as defined by the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualReturnType,
    required DartType expectedReturnType,
  })
>
returnOfInvalidTypeFromClosure = DiagnosticWithArguments(
  name: 'return_of_invalid_type_from_closure',
  problemMessage:
      "The returned type '{0}' isn't returnable from a '{1}' function, as "
      "required by the closure's context.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'return_of_invalid_type_from_closure',
  withArguments: _withArgumentsReturnOfInvalidTypeFromClosure,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualReturnType: the return type as declared in the return statement
/// Type expectedReturnType: the expected return type as defined by the
///                          enclosing class
/// String constructorName: the name of the constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualReturnType,
    required DartType expectedReturnType,
    required String constructorName,
  })
>
returnOfInvalidTypeFromConstructor = DiagnosticWithArguments(
  name: 'return_of_invalid_type',
  problemMessage:
      "A value of type '{0}' can't be returned from the constructor '{2}' "
      "because it has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'return_of_invalid_type_from_constructor',
  withArguments: _withArgumentsReturnOfInvalidTypeFromConstructor,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type actualReturnType: the return type as declared in the return statement
/// Type expectedReturnType: the expected return type as defined by the method
/// String methodName: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualReturnType,
    required DartType expectedReturnType,
    required String methodName,
  })
>
returnOfInvalidTypeFromFunction = DiagnosticWithArguments(
  name: 'return_of_invalid_type',
  problemMessage:
      "A value of type '{0}' can't be returned from the function '{2}' because "
      "it has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'return_of_invalid_type_from_function',
  withArguments: _withArgumentsReturnOfInvalidTypeFromFunction,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type actualReturnType: the type of the expression in the return statement
/// Type expectedReturnType: the expected return type as defined by the method
/// String methodName: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualReturnType,
    required DartType expectedReturnType,
    required String methodName,
  })
>
returnOfInvalidTypeFromMethod = DiagnosticWithArguments(
  name: 'return_of_invalid_type',
  problemMessage:
      "A value of type '{0}' can't be returned from the method '{2}' because it "
      "has a return type of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'return_of_invalid_type_from_method',
  withArguments: _withArgumentsReturnOfInvalidTypeFromMethod,
  expectedTypes: [ExpectedType.type, ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// Type actualType: the return type of the function
/// Type expectedType: the expected return type as defined by the type of the
///                    Future
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
returnTypeInvalidForCatchError = DiagnosticWithArguments(
  name: 'invalid_return_type_for_catch_error',
  problemMessage:
      "The return type '{0}' isn't assignable to '{1}', as required by "
      "'Future.catchError'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'return_type_invalid_for_catch_error',
  withArguments: _withArgumentsReturnTypeInvalidForCatchError,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments returnWithoutValue =
    DiagnosticWithoutArgumentsImpl(
      name: 'return_without_value',
      problemMessage: "The return value is missing after 'return'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'return_without_value',
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
  name: 'sdk_version_constructor_tearoffs',
  problemMessage:
      "Tearing off a constructor requires the 'constructor-tearoffs' language "
      "feature.",
  correctionMessage:
      "Try updating your 'pubspec.yaml' to set the minimum SDK constraint to "
      "2.15 or higher, and running 'pub get'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'sdk_version_constructor_tearoffs',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sdkVersionGtGtGtOperator = DiagnosticWithoutArgumentsImpl(
  name: 'sdk_version_gt_gt_gt_operator',
  problemMessage:
      "The operator '>>>' wasn't supported until version 2.14.0, but this code "
      "is required to be able to run on earlier versions.",
  correctionMessage: "Try updating the SDK constraints.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'sdk_version_gt_gt_gt_operator',
  expectedTypes: [],
);

/// Parameters:
/// String availableVersion: the version specified in the `@Since()`
///                          annotation
/// String versionConstraints: the SDK version constraints
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String availableVersion,
    required String versionConstraints,
  })
>
sdkVersionSince = DiagnosticWithArguments(
  name: 'sdk_version_since',
  problemMessage:
      "This API is available since SDK {0}, but constraints '{1}' don't "
      "guarantee it.",
  correctionMessage: "Try updating the SDK constraints.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'sdk_version_since',
  withArguments: _withArgumentsSdkVersionSince,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String sealedClassName: the name of the sealed class being extended,
///                         implemented, or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String sealedClassName})
>
sealedClassSubtypeOutsideOfLibrary = DiagnosticWithArguments(
  name: 'invalid_use_of_type_outside_library',
  problemMessage:
      "The class '{0}' can't be extended, implemented, or mixed in outside of "
      "its library because it's a sealed class.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'sealed_class_subtype_outside_of_library',
  withArguments: _withArgumentsSealedClassSubtypeOutsideOfLibrary,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments sealedEnum = DiagnosticWithoutArgumentsImpl(
  name: 'sealed_enum',
  problemMessage: "Enums can't be declared to be 'sealed'.",
  correctionMessage: "Try removing the keyword 'sealed'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'sealed_enum',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments sealedMixin = DiagnosticWithoutArgumentsImpl(
  name: 'sealed_mixin',
  problemMessage: "A mixin can't be declared 'sealed'.",
  correctionMessage: "Try removing the 'sealed' keyword.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'sealed_mixin',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments sealedMixinClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'sealed_mixin_class',
      problemMessage: "A mixin class can't be declared 'sealed'.",
      correctionMessage: "Try removing the 'sealed' keyword.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'sealed_mixin_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
setElementFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'collection_element_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be used as values in a "
      "'const' set literal.",
  correctionMessage:
      "Try removing the keyword 'const' from the set literal or removing the "
      "keyword 'deferred' from the import.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'set_element_from_deferred_library',
  expectedTypes: [],
);

/// Parameters:
/// Type actualType: the actual type of the set element
/// Type expectedType: the expected type of the set element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
setElementTypeNotAssignable = DiagnosticWithArguments(
  name: 'set_element_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the set type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'set_element_type_not_assignable',
  withArguments: _withArgumentsSetElementTypeNotAssignable,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// Parameters:
/// Type actualType: the actual type of the set element
/// Type expectedType: the expected type of the set element
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
setElementTypeNotAssignableNullability = DiagnosticWithArguments(
  name: 'set_element_type_not_assignable',
  problemMessage:
      "The element type '{0}' can't be assigned to the set type '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'set_element_type_not_assignable_nullability',
  withArguments: _withArgumentsSetElementTypeNotAssignableNullability,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments setterConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'setter_constructor',
      problemMessage: "Constructors can't be a setter.",
      correctionMessage: "Try removing 'set'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'setter_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments setterInFunction =
    DiagnosticWithoutArgumentsImpl(
      name: 'setter_in_function',
      problemMessage: "Setters can't be defined within methods or functions.",
      correctionMessage:
          "Try moving the setter outside the method or function.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'setter_in_function',
      expectedTypes: [],
    );

/// A code indicating that the activity is locked to an orientation.
///
/// No parameters.
const DiagnosticWithoutArguments
settingOrientationOnActivity = DiagnosticWithoutArgumentsImpl(
  name: 'setting_orientation_on_activity',
  problemMessage:
      "The `<activity>` element should not be locked to any orientation so that "
      "users can take advantage of the multi-window environments and larger "
      "screens on Chrome OS",
  correctionMessage:
      "Consider declaring the corresponding activity element with "
      "`screenOrientation=\"unspecified\"` or `\"fullSensor\"` attribute.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'setting_orientation_on_activity',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sharedDeferredPrefix = DiagnosticWithoutArgumentsImpl(
  name: 'shared_deferred_prefix',
  problemMessage:
      "The prefix of a deferred import can't be used in other import directives.",
  correctionMessage: "Try renaming one of the prefixes.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'shared_deferred_prefix',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
sizeAnnotationDimensions = DiagnosticWithoutArgumentsImpl(
  name: 'size_annotation_dimensions',
  problemMessage:
      "'Array's must have an 'Array' annotation that matches the dimensions.",
  correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'size_annotation_dimensions',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
spreadExpressionFromDeferredLibrary = DiagnosticWithoutArgumentsImpl(
  name: 'spread_expression_from_deferred_library',
  problemMessage:
      "Constant values from a deferred library can't be spread into a const "
      "literal.",
  correctionMessage: "Try making the deferred import non-deferred.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'spread_expression_from_deferred_library',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments stackOverflow = DiagnosticWithoutArgumentsImpl(
  name: 'stack_overflow',
  problemMessage: "The file has too many nested expressions or statements.",
  correctionMessage: "Try simplifying the code.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'stack_overflow',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the instance member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
staticAccessToInstanceMember = DiagnosticWithArguments(
  name: 'static_access_to_instance_member',
  problemMessage:
      "Instance member '{0}' can't be accessed using static access.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'static_access_to_instance_member',
  withArguments: _withArgumentsStaticAccessToInstanceMember,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments staticConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'static_constructor',
      problemMessage: "Constructors can't be static.",
      correctionMessage: "Try removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'static_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticGetterWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'static_getter_without_body',
      problemMessage: "A 'static' getter must have a body.",
      correctionMessage:
          "Try adding a body to the getter, or removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'static_getter_without_body',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'static_operator',
      problemMessage: "Operators can't be static.",
      correctionMessage: "Try removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'static_operator',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments staticSetterWithoutBody =
    DiagnosticWithoutArgumentsImpl(
      name: 'static_setter_without_body',
      problemMessage: "A 'static' setter must have a body.",
      correctionMessage:
          "Try adding a body to the setter, or removing the keyword 'static'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'static_setter_without_body',
      expectedTypes: [],
    );

/// When "strict-raw-types" is enabled, "raw types" must have type arguments.
///
/// A "raw type" is a type name that does not use inference to fill in missing
/// type arguments; instead, each type argument is instantiated to its bound.
///
/// Parameters:
/// Type type: the name of the generic type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
strictRawType = DiagnosticWithArguments(
  name: 'strict_raw_type',
  problemMessage:
      "The generic type '{0}' should have explicit type arguments but doesn't.",
  correctionMessage: "Use explicit type arguments for '{0}'.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'strict_raw_type',
  withArguments: _withArgumentsStrictRawType,
  expectedTypes: [ExpectedType.type],
);

/// Parameters:
/// String subtypeName: the name of the subtype that is not 'base', 'final',
///                     or 'sealed'
/// String supertypeName: the name of the 'base' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subtypeName,
    required String supertypeName,
  })
>
subtypeOfBaseIsNotBaseFinalOrSealed = DiagnosticWithArguments(
  name: 'subtype_of_base_or_final_is_not_base_final_or_sealed',
  problemMessage:
      "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
      "'{1}' is 'base'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'subtype_of_base_is_not_base_final_or_sealed',
  withArguments: _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String subtypeName: the name of the subtype that is not 'base', 'final',
///                     or 'sealed'
/// String supertypeName: the name of the 'final' supertype
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subtypeName,
    required String supertypeName,
  })
>
subtypeOfFinalIsNotBaseFinalOrSealed = DiagnosticWithArguments(
  name: 'subtype_of_base_or_final_is_not_base_final_or_sealed',
  problemMessage:
      "The type '{0}' must be 'base', 'final' or 'sealed' because the supertype "
      "'{1}' is 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'subtype_of_final_is_not_base_final_or_sealed',
  withArguments: _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the sealed class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
subtypeOfSealedClass = DiagnosticWithArguments(
  name: 'subtype_of_sealed_class',
  problemMessage:
      "The class '{0}' shouldn't be extended, mixed in, or implemented because "
      "it's sealed.",
  correctionMessage:
      "Try composing instead of inheriting, or refer to the documentation of "
      "'{0}' for more information.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'subtype_of_sealed_class',
  withArguments: _withArgumentsSubtypeOfSealedClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String subclassName: the name of the subclass
/// String superclassName: the name of the class being extended, implemented,
///                        or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subclassName,
    required String superclassName,
  })
>
subtypeOfStructClassInExtends = DiagnosticWithArguments(
  name: 'subtype_of_struct_class',
  problemMessage:
      "The class '{0}' can't extend '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'subtype_of_struct_class_in_extends',
  withArguments: _withArgumentsSubtypeOfStructClassInExtends,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String subclassName: the name of the subclass
/// String superclassName: the name of the class being extended, implemented,
///                        or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subclassName,
    required String superclassName,
  })
>
subtypeOfStructClassInImplements = DiagnosticWithArguments(
  name: 'subtype_of_struct_class',
  problemMessage:
      "The class '{0}' can't implement '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'subtype_of_struct_class_in_implements',
  withArguments: _withArgumentsSubtypeOfStructClassInImplements,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String subclassName: the name of the subclass
/// String superclassName: the name of the class being extended, implemented,
///                        or mixed in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String subclassName,
    required String superclassName,
  })
>
subtypeOfStructClassInWith = DiagnosticWithArguments(
  name: 'subtype_of_struct_class',
  problemMessage:
      "The class '{0}' can't mix in '{1}' because '{1}' is a subtype of "
      "'Struct', 'Union', or 'AbiSpecificInteger'.",
  correctionMessage:
      "Try extending 'Struct', 'Union', or 'AbiSpecificInteger' directly.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'subtype_of_struct_class_in_with',
  withArguments: _withArgumentsSubtypeOfStructClassInWith,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// Type parameterType: the type of super-parameter
/// Type superParameterType: the type of associated super-constructor
///                          parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType parameterType,
    required DartType superParameterType,
  })
>
superFormalParameterTypeIsNotSubtypeOfAssociated = DiagnosticWithArguments(
  name: 'super_formal_parameter_type_is_not_subtype_of_associated',
  problemMessage:
      "The type '{0}' of this parameter isn't a subtype of the type '{1}' of the "
      "associated super constructor parameter.",
  correctionMessage:
      "Try removing the explicit type annotation from the parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'super_formal_parameter_type_is_not_subtype_of_associated',
  withArguments: _withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// No parameters.
const DiagnosticWithoutArguments superFormalParameterWithoutAssociatedNamed =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_formal_parameter_without_associated_named',
      problemMessage: "No associated named super constructor parameter.",
      correctionMessage:
          "Try changing the name to the name of an existing named super "
          "constructor parameter, or creating such named parameter.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_formal_parameter_without_associated_named',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
superFormalParameterWithoutAssociatedPositional = DiagnosticWithoutArgumentsImpl(
  name: 'super_formal_parameter_without_associated_positional',
  problemMessage: "No associated positional super constructor parameter.",
  correctionMessage:
      "Try using a normal parameter, or adding more positional parameters to "
      "the super constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'super_formal_parameter_without_associated_positional',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments superInEnumConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_in_enum_constructor',
      problemMessage: "The enum constructor can't have a 'super' initializer.",
      correctionMessage: "Try removing the 'super' invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_in_enum_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
superInExtension = DiagnosticWithoutArgumentsImpl(
  name: 'super_in_extension',
  problemMessage:
      "The 'super' keyword can't be used in an extension because an extension "
      "doesn't have a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'super_in_extension',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments superInExtensionType =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_in_extension_type',
      problemMessage:
          "The 'super' keyword can't be used in an extension type because an "
          "extension type doesn't have a superclass.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_in_extension_type',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments superInInvalidContext =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_in_invalid_context',
      problemMessage: "Invalid context for 'super' invocation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_in_invalid_context',
      expectedTypes: [],
    );

/// 7.6.1 Generative Constructors: Let <i>k</i> be a generative constructor. It
/// is a compile-time error if a generative constructor of class Object
/// includes a superinitializer.
///
/// No parameters.
const DiagnosticWithoutArguments superInitializerInObject =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_initializer_in_object',
      problemMessage:
          "The class 'Object' can't invoke a constructor from a superclass.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_initializer_in_object',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments superInRedirectingConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_in_redirecting_constructor',
      problemMessage:
          "The redirecting constructor can't have a 'super' initializer.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_in_redirecting_constructor',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments superInvocationNotLast =
    DiagnosticWithoutArgumentsImpl(
      name: 'super_invocation_not_last',
      problemMessage:
          "The superconstructor call must be last in an initializer list.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'super_invocation_not_last',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments switchCaseCompletesNormally =
    DiagnosticWithoutArgumentsImpl(
      name: 'switch_case_completes_normally',
      problemMessage: "The 'case' shouldn't complete normally.",
      correctionMessage: "Try adding 'break', 'return', or 'throw'.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'switch_case_completes_normally',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments switchHasCaseAfterDefaultCase =
    DiagnosticWithoutArgumentsImpl(
      name: 'switch_has_case_after_default_case',
      problemMessage:
          "The default case should be the last case in a switch statement.",
      correctionMessage:
          "Try moving the default case after the other case clauses.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'switch_has_case_after_default_case',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments switchHasMultipleDefaultCases =
    DiagnosticWithoutArgumentsImpl(
      name: 'switch_has_multiple_default_cases',
      problemMessage: "The 'default' case can only be declared once.",
      correctionMessage: "Try removing all but one default case.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'switch_has_multiple_default_cases',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments tearoffOfGenerativeConstructorOfAbstractClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'tearoff_of_generative_constructor_of_abstract_class',
      problemMessage:
          "A generative constructor of an abstract class can't be torn off.",
      correctionMessage:
          "Try tearing off a constructor of a concrete class, or a "
          "non-generative constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'tearoff_of_generative_constructor_of_abstract_class',
      expectedTypes: [],
    );

/// Parameters:
/// String codePoint: the unicode sequence of the code point.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String codePoint})
>
textDirectionCodePointInComment = DiagnosticWithArguments(
  name: 'text_direction_code_point_in_comment',
  problemMessage:
      "The Unicode code point 'U+{0}' changes the appearance of text from how "
      "it's interpreted by the compiler.",
  correctionMessage:
      "Try removing the code point or using the Unicode escape sequence "
      "'\\u{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'text_direction_code_point_in_comment',
  withArguments: _withArgumentsTextDirectionCodePointInComment,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String codePoint: the unicode sequence of the code point.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String codePoint})
>
textDirectionCodePointInLiteral = DiagnosticWithArguments(
  name: 'text_direction_code_point_in_literal',
  problemMessage:
      "The Unicode code point 'U+{0}' changes the appearance of text from how "
      "it's interpreted by the compiler.",
  correctionMessage:
      "Try removing the code point or using the Unicode escape sequence "
      "'\\u{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'text_direction_code_point_in_literal',
  withArguments: _withArgumentsTextDirectionCodePointInLiteral,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type type: the type that can't be thrown
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required DartType type})
>
throwOfInvalidType = DiagnosticWithArguments(
  name: 'throw_of_invalid_type',
  problemMessage:
      "The type '{0}' of the thrown expression must be assignable to 'Object'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'throw_of_invalid_type',
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
  name: 'todo',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'todo',
  withArguments: _withArgumentsTodo,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the element whose type could not be inferred.
/// String cycle: The names of the elements in the cycle (sorted and
///               comma-separated).
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name, required String cycle})
>
topLevelCycle = DiagnosticWithArguments(
  name: 'top_level_cycle',
  problemMessage:
      "The type of '{0}' can't be inferred because it depends on itself through "
      "the cycle: {1}.",
  correctionMessage:
      "Try adding an explicit type to one or more of the variables in the "
      "cycle in order to break the cycle.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'top_level_cycle',
  withArguments: _withArgumentsTopLevelCycle,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
topLevelOperator = DiagnosticWithoutArgumentsImpl(
  name: 'top_level_operator',
  problemMessage: "Operators must be declared within a class.",
  correctionMessage:
      "Try removing the operator, moving it to a class, or converting it to "
      "be a function.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'top_level_operator',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
typeAliasCannotReferenceItself = DiagnosticWithoutArgumentsImpl(
  name: 'type_alias_cannot_reference_itself',
  problemMessage:
      "Typedefs can't reference themselves directly or recursively via another "
      "typedef.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_alias_cannot_reference_itself',
  expectedTypes: [],
);

/// Parameters:
/// String typeName: the name of the type that is deferred and being used in a
///                  type annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
typeAnnotationDeferredClass = DiagnosticWithArguments(
  name: 'type_annotation_deferred_class',
  problemMessage:
      "The deferred type '{0}' can't be used in a declaration, cast, or type "
      "test.",
  correctionMessage:
      "Try using a different type, or changing the import to not be "
      "deferred.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_annotation_deferred_class',
  withArguments: _withArgumentsTypeAnnotationDeferredClass,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type nonConformingType: the name of the type used in the instance creation
///                         that should be limited by the bound as specified
///                         in the class declaration
/// String typeParameterName: the name of the type parameter
/// Type bound: the substituted bound of the type parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType nonConformingType,
    required String typeParameterName,
    required DartType bound,
  })
>
typeArgumentNotMatchingBounds = DiagnosticWithArguments(
  name: 'type_argument_not_matching_bounds',
  problemMessage:
      "'{0}' doesn't conform to the bound '{2}' of the type parameter '{1}'.",
  correctionMessage: "Try using a type that is or is a subclass of '{2}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_argument_not_matching_bounds',
  withArguments: _withArgumentsTypeArgumentNotMatchingBounds,
  expectedTypes: [ExpectedType.type, ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// Name typeVariableName: The name of the type variable.
const DiagnosticCode typeArgumentsOnTypeVariable =
    DiagnosticCodeWithExpectedTypes(
      name: 'type_arguments_on_type_variable',
      problemMessage: "Can't use type arguments with type variable '{0}'.",
      correctionMessage: "Try removing the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'type_arguments_on_type_variable',
      expectedTypes: [ExpectedType.name],
    );

/// No parameters.
const DiagnosticWithoutArguments typeBeforeFactory =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_before_factory',
      problemMessage: "Factory constructors cannot have a return type.",
      correctionMessage: "Try removing the type appearing before 'factory'.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'type_before_factory',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeCheckIsNotNull =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_check_with_null',
      problemMessage: "Tests for non-null should be done with '!= null'.",
      correctionMessage: "Try replacing the 'is! Null' check with '!= null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'type_check_is_not_null',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeCheckIsNull =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_check_with_null',
      problemMessage: "Tests for null should be done with '== null'.",
      correctionMessage: "Try replacing the 'is Null' check with '== null'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'type_check_is_null',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typedefInClass =
    DiagnosticWithoutArgumentsImpl(
      name: 'typedef_in_class',
      problemMessage: "Typedefs can't be declared inside classes.",
      correctionMessage: "Try moving the typedef to the top-level.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'typedef_in_class',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeParameterOnConstructor =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_parameter_on_constructor',
      problemMessage: "Constructors can't have type parameters.",
      correctionMessage: "Try removing the type parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'type_parameter_on_constructor',
      expectedTypes: [],
    );

/// 7.1.1 Operators: Type parameters are not syntactically supported on an
/// operator.
///
/// No parameters.
const DiagnosticWithoutArguments typeParameterOnOperator =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_parameter_on_operator',
      problemMessage:
          "Types parameters aren't allowed when defining an operator.",
      correctionMessage: "Try removing the type parameters.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'type_parameter_on_operator',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments typeParameterReferencedByStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'type_parameter_referenced_by_static',
      problemMessage:
          "Static members can't reference type parameters of the class.",
      correctionMessage:
          "Try removing the reference to the type parameter, or making the "
          "member an instance member.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'type_parameter_referenced_by_static',
      expectedTypes: [],
    );

/// See [diag.typeArgumentNotMatchingBounds].
///
/// Parameters:
/// String typeParameterName: the name of the type parameter
/// Type bound: the name of the bounding type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String typeParameterName,
    required DartType bound,
  })
>
typeParameterSupertypeOfItsBound = DiagnosticWithArguments(
  name: 'type_parameter_supertype_of_its_bound',
  problemMessage: "'{0}' can't be a supertype of its upper bound.",
  correctionMessage:
      "Try using a type that is the same as or a subclass of '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_parameter_supertype_of_its_bound',
  withArguments: _withArgumentsTypeParameterSupertypeOfItsBound,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String name: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
typeTestWithNonType = DiagnosticWithArguments(
  name: 'type_test_with_non_type',
  problemMessage:
      "The name '{0}' isn't a type and can't be used in an 'is' expression.",
  correctionMessage: "Try correcting the name to match an existing type.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_test_with_non_type',
  withArguments: _withArgumentsTypeTestWithNonType,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
typeTestWithUndefinedName = DiagnosticWithArguments(
  name: 'type_test_with_undefined_name',
  problemMessage:
      "The name '{0}' isn't defined, so it can't be used in an 'is' expression.",
  correctionMessage:
      "Try changing the name to the name of an existing type, or creating a "
      "type with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'type_test_with_undefined_name',
  withArguments: _withArgumentsTypeTestWithUndefinedName,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
uncheckedInvocationOfNullableValue = DiagnosticWithoutArgumentsImpl(
  name: 'unchecked_use_of_nullable_value',
  problemMessage:
      "The function can't be unconditionally invoked because it can be 'null'.",
  correctionMessage: "Try adding a null check ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_invocation_of_nullable_value',
  expectedTypes: [],
);

/// Parameters:
/// String name: the name of the method
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
uncheckedMethodInvocationOfNullableValue = DiagnosticWithArguments(
  name: 'unchecked_use_of_nullable_value',
  problemMessage:
      "The method '{0}' can't be unconditionally invoked because the receiver "
      "can be 'null'.",
  correctionMessage:
      "Try making the call conditional (using '?.') or adding a null check "
      "to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_method_invocation_of_nullable_value',
  withArguments: _withArgumentsUncheckedMethodInvocationOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String operator: the name of the operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String operator})
>
uncheckedOperatorInvocationOfNullableValue = DiagnosticWithArguments(
  name: 'unchecked_use_of_nullable_value',
  problemMessage:
      "The operator '{0}' can't be unconditionally invoked because the receiver "
      "can be 'null'.",
  correctionMessage: "Try adding a null check to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_operator_invocation_of_nullable_value',
  withArguments: _withArgumentsUncheckedOperatorInvocationOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the property
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
uncheckedPropertyAccessOfNullableValue = DiagnosticWithArguments(
  name: 'unchecked_use_of_nullable_value',
  problemMessage:
      "The property '{0}' can't be unconditionally accessed because the receiver "
      "can be 'null'.",
  correctionMessage:
      "Try making the access conditional (using '?.') or adding a null check "
      "to the target ('!').",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_property_access_of_nullable_value',
  withArguments: _withArgumentsUncheckedPropertyAccessOfNullableValue,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments uncheckedUseOfNullableValueAsCondition =
    DiagnosticWithoutArgumentsImpl(
      name: 'unchecked_use_of_nullable_value',
      problemMessage: "A nullable expression can't be used as a condition.",
      correctionMessage:
          "Try checking that the value isn't 'null' before using it as a "
          "condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'unchecked_use_of_nullable_value_as_condition',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
uncheckedUseOfNullableValueAsIterator = DiagnosticWithoutArgumentsImpl(
  name: 'unchecked_use_of_nullable_value',
  problemMessage:
      "A nullable expression can't be used as an iterator in a for-in loop.",
  correctionMessage:
      "Try checking that the value isn't 'null' before using it as an "
      "iterator.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_use_of_nullable_value_as_iterator',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
uncheckedUseOfNullableValueInSpread = DiagnosticWithoutArgumentsImpl(
  name: 'unchecked_use_of_nullable_value',
  problemMessage: "A nullable expression can't be used in a spread.",
  correctionMessage:
      "Try checking that the value isn't 'null' before using it in a spread, "
      "or use a null-aware spread.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unchecked_use_of_nullable_value_in_spread',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments uncheckedUseOfNullableValueInYieldEach =
    DiagnosticWithoutArgumentsImpl(
      name: 'unchecked_use_of_nullable_value',
      problemMessage:
          "A nullable expression can't be used in a yield-each statement.",
      correctionMessage:
          "Try checking that the value isn't 'null' before using it in a "
          "yield-each statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'unchecked_use_of_nullable_value_in_yield_each',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the annotation
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedAnnotation = DiagnosticWithArguments(
  name: 'undefined_annotation',
  problemMessage: "Undefined name '{0}' used as an annotation.",
  correctionMessage:
      "Try defining the name or importing it from another library.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_annotation',
  withArguments: _withArgumentsUndefinedAnnotation,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the undefined class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedClass = DiagnosticWithArguments(
  name: 'undefined_class',
  problemMessage: "Undefined class '{0}'.",
  correctionMessage:
      "Try changing the name to the name of an existing class, or creating a "
      "class with the name '{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_class',
  withArguments: _withArgumentsUndefinedClass,
  expectedTypes: [ExpectedType.string],
);

/// Same as [diag.undefinedClass], but to catch using
/// "boolean" instead of "bool" in order to improve the correction message.
///
/// Parameters:
/// String name: the name of the undefined class
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedClassBoolean = DiagnosticWithArguments(
  name: 'undefined_class',
  problemMessage: "Undefined class '{0}'.",
  correctionMessage: "Try using the type 'bool'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_class_boolean',
  withArguments: _withArgumentsUndefinedClassBoolean,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// Type type: the type that does not define the invoked constructor
/// String constructorName: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required String constructorName,
  })
>
undefinedConstructorInInitializer = DiagnosticWithArguments(
  name: 'undefined_constructor_in_initializer',
  problemMessage: "The class '{0}' doesn't have a constructor named '{1}'.",
  correctionMessage:
      "Try defining a constructor named '{1}' in '{0}', or invoking a "
      "different constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_constructor_in_initializer',
  withArguments: _withArgumentsUndefinedConstructorInInitializer,
  expectedTypes: [ExpectedType.type, ExpectedType.string],
);

/// Parameters:
/// String className: the name of the superclass that does not define the
///                   invoked constructor
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String className})
>
undefinedConstructorInInitializerDefault = DiagnosticWithArguments(
  name: 'undefined_constructor_in_initializer',
  problemMessage: "The class '{0}' doesn't have an unnamed constructor.",
  correctionMessage:
      "Try defining an unnamed constructor in '{0}', or invoking a different "
      "constructor.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_constructor_in_initializer_default',
  withArguments: _withArgumentsUndefinedConstructorInInitializerDefault,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of the enum value that is not defined
/// Type type: the type of the enum used to access the constant
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required DartType type,
  })
>
undefinedEnumConstant = DiagnosticWithArguments(
  name: 'undefined_enum_constant',
  problemMessage: "There's no constant named '{0}' in '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing constant, or "
      "defining a constant named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_enum_constant',
  withArguments: _withArgumentsUndefinedEnumConstant,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String name: the name of the constructor that is undefined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedEnumConstructorNamed = DiagnosticWithArguments(
  name: 'undefined_enum_constructor',
  problemMessage: "The enum doesn't have a constructor named '{0}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing constructor, or "
      "defining constructor with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_enum_constructor_named',
  withArguments: _withArgumentsUndefinedEnumConstructorNamed,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments undefinedEnumConstructorUnnamed =
    DiagnosticWithoutArgumentsImpl(
      name: 'undefined_enum_constructor',
      problemMessage: "The enum doesn't have an unnamed constructor.",
      correctionMessage:
          "Try adding the name of an existing constructor, or defining an "
          "unnamed constructor.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'undefined_enum_constructor_unnamed',
      expectedTypes: [],
    );

/// Parameters:
/// String getterName: the name of the getter that is undefined
/// String extensionName: the name of the extension that was explicitly
///                       specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String getterName,
    required String extensionName,
  })
>
undefinedExtensionGetter = DiagnosticWithArguments(
  name: 'undefined_extension_getter',
  problemMessage: "The getter '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing getter, or "
      "defining a getter named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_extension_getter',
  withArguments: _withArgumentsUndefinedExtensionGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String methodName: the name of the method that is undefined
/// String extensionName: the name of the extension that was explicitly
///                       specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String extensionName,
  })
>
undefinedExtensionMethod = DiagnosticWithArguments(
  name: 'undefined_extension_method',
  problemMessage: "The method '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_extension_method',
  withArguments: _withArgumentsUndefinedExtensionMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String operator: the name of the operator that is undefined
/// String extensionName: the name of the extension that was explicitly
///                       specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String operator,
    required String extensionName,
  })
>
undefinedExtensionOperator = DiagnosticWithArguments(
  name: 'undefined_extension_operator',
  problemMessage: "The operator '{0}' isn't defined for the extension '{1}'.",
  correctionMessage: "Try defining the operator '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_extension_operator',
  withArguments: _withArgumentsUndefinedExtensionOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String setterName: the name of the setter that is undefined
/// String extensionName: the name of the extension that was explicitly
///                       specified
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String setterName,
    required String extensionName,
  })
>
undefinedExtensionSetter = DiagnosticWithArguments(
  name: 'undefined_extension_setter',
  problemMessage: "The setter '{0}' isn't defined for the extension '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing setter, or "
      "defining a setter named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_extension_setter',
  withArguments: _withArgumentsUndefinedExtensionSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the method that is undefined
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedFunction = DiagnosticWithArguments(
  name: 'undefined_function',
  problemMessage: "The function '{0}' isn't defined.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing function, or defining a function named '{0}'.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_function',
  withArguments: _withArgumentsUndefinedFunction,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String memberName: the name of the getter
/// Type type: the type where the getter is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String memberName,
    required DartType type,
  })
>
undefinedGetter = DiagnosticWithArguments(
  name: 'undefined_getter',
  problemMessage: "The getter '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing getter, or defining a getter or field named "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_getter',
  withArguments: _withArgumentsUndefinedGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String getterName: the name of the getter
/// String functionTypeAliasName: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String getterName,
    required String functionTypeAliasName,
  })
>
undefinedGetterOnFunctionType = DiagnosticWithArguments(
  name: 'undefined_getter',
  problemMessage: "The getter '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension getter on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_getter_on_function_type',
  withArguments: _withArgumentsUndefinedGetterOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String library: the name of the library being imported
/// String name: the name in the hide clause that isn't defined in the library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String library, required String name})
>
undefinedHiddenName = DiagnosticWithArguments(
  name: 'undefined_hidden_name',
  problemMessage:
      "The library '{0}' doesn't export a member with the hidden name '{1}'.",
  correctionMessage: "Try removing the name from the list of hidden members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'undefined_hidden_name',
  withArguments: _withArgumentsUndefinedHiddenName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the identifier
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedIdentifier = DiagnosticWithArguments(
  name: 'undefined_identifier',
  problemMessage: "Undefined name '{0}'.",
  correctionMessage:
      "Try correcting the name to one that is defined, or defining the name.",
  hasPublishedDocs: true,
  isUnresolvedIdentifier: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_identifier',
  withArguments: _withArgumentsUndefinedIdentifier,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
undefinedIdentifierAwait = DiagnosticWithoutArgumentsImpl(
  name: 'undefined_identifier_await',
  problemMessage:
      "Undefined name 'await' in function body not marked with 'async'.",
  correctionMessage:
      "Try correcting the name to one that is defined, defining the name, or "
      "adding 'async' to the enclosing function body.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_identifier_await',
  expectedTypes: [],
);

/// An error code indicating an undefined lint rule.
///
/// Parameters:
/// String ruleName: the rule name
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String ruleName})
>
undefinedLint = DiagnosticWithArguments(
  name: 'undefined_lint',
  problemMessage: "'{0}' isn't a recognized lint rule.",
  correctionMessage: "Try using the name of a recognized lint rule.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'undefined_lint',
  withArguments: _withArgumentsUndefinedLint,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String methodName: the name of the method that is undefined
/// String typeName: the resolved type name that the method lookup is
///                  happening on
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String typeName,
  })
>
undefinedMethod = DiagnosticWithArguments(
  name: 'undefined_method',
  problemMessage: "The method '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_method',
  withArguments: _withArgumentsUndefinedMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String methodName: the name of the method
/// String functionTypeAliasName: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String functionTypeAliasName,
  })
>
undefinedMethodOnFunctionType = DiagnosticWithArguments(
  name: 'undefined_method',
  problemMessage: "The method '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension method on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_method_on_function_type',
  withArguments: _withArgumentsUndefinedMethodOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name of the requested named parameter
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
undefinedNamedParameter = DiagnosticWithArguments(
  name: 'undefined_named_parameter',
  problemMessage: "The named parameter '{0}' isn't defined.",
  correctionMessage:
      "Try correcting the name to an existing named parameter's name, or "
      "defining a named parameter with the name '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_named_parameter',
  withArguments: _withArgumentsUndefinedNamedParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String operator: the name of the operator
/// Type type: the type where the operator is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String operator,
    required DartType type,
  })
>
undefinedOperator = DiagnosticWithArguments(
  name: 'undefined_operator',
  problemMessage: "The operator '{0}' isn't defined for the type '{1}'.",
  correctionMessage: "Try defining the operator '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_operator',
  withArguments: _withArgumentsUndefinedOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String referenceName: the name of the reference
/// String prefixName: the name of the prefix
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String referenceName,
    required String prefixName,
  })
>
undefinedPrefixedName = DiagnosticWithArguments(
  name: 'undefined_prefixed_name',
  problemMessage:
      "The name '{0}' is being referenced through the prefix '{1}', but it isn't "
      "defined in any of the libraries imported using that prefix.",
  correctionMessage:
      "Try correcting the prefix or importing the library that defines "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_prefixed_name',
  withArguments: _withArgumentsUndefinedPrefixedName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String undefinedParameterName: the name of the undefined parameter
/// String targetedMemberName: the name of the targeted member
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String undefinedParameterName,
    required String targetedMemberName,
  })
>
undefinedReferencedParameter = DiagnosticWithArguments(
  name: 'undefined_referenced_parameter',
  problemMessage: "The parameter '{0}' isn't defined by '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'undefined_referenced_parameter',
  withArguments: _withArgumentsUndefinedReferencedParameter,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String setterName: the name of the setter
/// Type type: the enclosing type where the setter is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String setterName,
    required DartType type,
  })
>
undefinedSetter = DiagnosticWithArguments(
  name: 'undefined_setter',
  problemMessage: "The setter '{0}' isn't defined for the type '{1}'.",
  correctionMessage:
      "Try importing the library that defines '{0}', correcting the name to "
      "the name of an existing setter, or defining a setter or field named "
      "'{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_setter',
  withArguments: _withArgumentsUndefinedSetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String setterName: the name of the setter
/// String functionTypeAliasName: the name of the function type alias
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String setterName,
    required String functionTypeAliasName,
  })
>
undefinedSetterOnFunctionType = DiagnosticWithArguments(
  name: 'undefined_setter',
  problemMessage: "The setter '{0}' isn't defined for the '{1}' function type.",
  correctionMessage:
      "Try wrapping the function type alias in parentheses in order to "
      "access '{0}' as an extension getter on 'Type'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_setter_on_function_type',
  withArguments: _withArgumentsUndefinedSetterOnFunctionType,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String library: the name of the library being imported
/// String name: the name in the show clause that isn't defined in the library
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String library, required String name})
>
undefinedShownName = DiagnosticWithArguments(
  name: 'undefined_shown_name',
  problemMessage:
      "The library '{0}' doesn't export a member with the shown name '{1}'.",
  correctionMessage: "Try removing the name from the list of shown members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'undefined_shown_name',
  withArguments: _withArgumentsUndefinedShownName,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String getterName: the name of the getter
/// Type type: the enclosing type where the getter is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String getterName,
    required DartType type,
  })
>
undefinedSuperGetter = DiagnosticWithArguments(
  name: 'undefined_super_member',
  problemMessage: "The getter '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing getter, or "
      "defining a getter or field named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_super_getter',
  withArguments: _withArgumentsUndefinedSuperGetter,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String methodName: the name of the method that is undefined
/// String typeName: the resolved type name that the method lookup is
///                  happening on
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String methodName,
    required String typeName,
  })
>
undefinedSuperMethod = DiagnosticWithArguments(
  name: 'undefined_super_member',
  problemMessage: "The method '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing method, or "
      "defining a method named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_super_method',
  withArguments: _withArgumentsUndefinedSuperMethod,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String operator: the name of the operator
/// Type type: the type where the operator is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String operator,
    required DartType type,
  })
>
undefinedSuperOperator = DiagnosticWithArguments(
  name: 'undefined_super_member',
  problemMessage: "The operator '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage: "Try defining the operator '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_super_operator',
  withArguments: _withArgumentsUndefinedSuperOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.type],
);

/// Parameters:
/// String setterName: the name of the setter
/// Type type: the enclosing type where the setter is being looked for
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String setterName,
    required DartType type,
  })
>
undefinedSuperSetter = DiagnosticWithArguments(
  name: 'undefined_super_member',
  problemMessage: "The setter '{0}' isn't defined in a superclass of '{1}'.",
  correctionMessage:
      "Try correcting the name to the name of an existing setter, or "
      "defining a setter or field named '{0}' in a superclass.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_super_setter',
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
  name: 'undone',
  problemMessage: "{0}",
  type: DiagnosticType.TODO,
  uniqueName: 'undone',
  withArguments: _withArgumentsUndone,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unexpectedDollarInString = DiagnosticWithoutArgumentsImpl(
  name: 'unexpected_dollar_in_string',
  problemMessage:
      "A '\$' has special meaning inside a string, and must be followed by an "
      "identifier or an expression in curly braces ({}).",
  correctionMessage: "Try adding a backslash (\\) to escape the '\$'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'unexpected_dollar_in_string',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unexpectedSeparatorInNumber = DiagnosticWithoutArgumentsImpl(
  name: 'unexpected_separator_in_number',
  problemMessage:
      "Digit separators ('_') in a number literal can only be placed between two "
      "digits.",
  correctionMessage: "Try removing the '_'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'unexpected_separator_in_number',
  expectedTypes: [],
);

/// Parameters:
/// String text: the unexpected text that was found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String text})
>
unexpectedToken = DiagnosticWithArguments(
  name: 'unexpected_token',
  problemMessage: "Unexpected text '{0}'.",
  correctionMessage: "Try removing the text.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'unexpected_token',
  withArguments: _withArgumentsUnexpectedToken,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unexpectedTokens =
    DiagnosticWithoutArgumentsImpl(
      name: 'unexpected_tokens',
      problemMessage: "Unexpected tokens.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'unexpected_tokens',
      expectedTypes: [],
    );

/// Parameters:
/// String diagnosticName: the name of the non-diagnostic being ignored
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String diagnosticName})
>
unignorableIgnore = DiagnosticWithArguments(
  name: 'unignorable_ignore',
  problemMessage: "The diagnostic '{0}' can't be ignored.",
  correctionMessage:
      "Try removing the name from the list, or removing the whole comment if "
      "this is the only name in the list.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unignorable_ignore',
  withArguments: _withArgumentsUnignorableIgnore,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String platform: the unknown platform.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String platform})
>
unknownPlatform = DiagnosticWithArguments(
  name: 'unknown_platform',
  problemMessage: "The platform '{0}' is not a recognized platform.",
  correctionMessage: "Try correcting the platform name or removing it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unknown_platform',
  withArguments: _withArgumentsUnknownPlatform,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryCast =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_cast',
      problemMessage: "Unnecessary cast.",
      correctionMessage: "Try removing the cast.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_cast',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryCastPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_cast_pattern',
      problemMessage: "Unnecessary cast pattern.",
      correctionMessage: "Try removing the cast pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_cast_pattern',
      expectedTypes: [],
    );

/// Parameters:
/// String package: the name of the package in the dev_dependency list.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String package})
>
unnecessaryDevDependency = DiagnosticWithArguments(
  name: 'unnecessary_dev_dependency',
  problemMessage:
      "The dev dependency on {0} is unnecessary because there is also a normal "
      "dependency on that package.",
  correctionMessage: "Try removing the dev dependency.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_dev_dependency',
  withArguments: _withArgumentsUnnecessaryDevDependency,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryFinal = DiagnosticWithoutArgumentsImpl(
  name: 'unnecessary_final',
  problemMessage:
      "The keyword 'final' isn't necessary because the parameter is implicitly "
      "'final'.",
  correctionMessage: "Try removing the 'final'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_final',
  expectedTypes: [],
);

/// Parameters:
/// String unnecessaryUri: the URI that is not necessary
/// String reasonUri: the URI that makes it unnecessary
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String unnecessaryUri,
    required String reasonUri,
  })
>
unnecessaryImport = DiagnosticWithArguments(
  name: 'unnecessary_import',
  problemMessage:
      "The import of '{0}' is unnecessary because all of the used elements are "
      "also provided by the import of '{1}'.",
  correctionMessage: "Try removing the import directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.HINT,
  uniqueName: 'unnecessary_import',
  withArguments: _withArgumentsUnnecessaryImport,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNanComparisonFalse = DiagnosticWithoutArgumentsImpl(
  name: 'unnecessary_nan_comparison',
  problemMessage:
      "A double can't equal 'double.nan', so the condition is always 'false'.",
  correctionMessage: "Try using 'double.isNan', or removing the condition.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_nan_comparison_false',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNanComparisonTrue = DiagnosticWithoutArgumentsImpl(
  name: 'unnecessary_nan_comparison',
  problemMessage:
      "A double can't equal 'double.nan', so the condition is always 'true'.",
  correctionMessage: "Try using 'double.isNan', or removing the condition.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_nan_comparison_true',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNonNullAssertion =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_non_null_assertion',
      problemMessage:
          "The '!' will have no effect because the receiver can't be null.",
      correctionMessage: "Try removing the '!' operator.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_non_null_assertion',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNoSuchMethod =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_no_such_method',
      problemMessage: "Unnecessary 'noSuchMethod' declaration.",
      correctionMessage: "Try removing the declaration of 'noSuchMethod'.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_no_such_method',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNullAssertPattern = DiagnosticWithoutArgumentsImpl(
  name: 'unnecessary_null_assert_pattern',
  problemMessage:
      "The null-assert pattern will have no effect because the matched type "
      "isn't nullable.",
  correctionMessage:
      "Try replacing the null-assert pattern with its nested pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_null_assert_pattern',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
unnecessaryNullCheckPattern = DiagnosticWithoutArgumentsImpl(
  name: 'unnecessary_null_check_pattern',
  problemMessage:
      "The null-check pattern will have no effect because the matched type isn't "
      "nullable.",
  correctionMessage:
      "Try replacing the null-check pattern with its nested pattern.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_null_check_pattern',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonAlwaysNullFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_null_comparison',
      problemMessage:
          "The operand must be 'null', so the condition is always 'false'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_null_comparison_always_null_false',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonAlwaysNullTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_null_comparison',
      problemMessage:
          "The operand must be 'null', so the condition is always 'true'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_null_comparison_always_null_true',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonNeverNullFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_null_comparison',
      problemMessage:
          "The operand can't be 'null', so the condition is always 'false'.",
      correctionMessage:
          "Try removing the condition, an enclosing condition, or the whole "
          "conditional statement.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_null_comparison_never_null_false',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryNullComparisonNeverNullTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_null_comparison',
      problemMessage:
          "The operand can't be 'null', so the condition is always 'true'.",
      correctionMessage: "Remove the condition.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_null_comparison_never_null_true',
      expectedTypes: [],
    );

/// Parameters:
/// String typeName: the name of the type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String typeName})
>
unnecessaryQuestionMark = DiagnosticWithArguments(
  name: 'unnecessary_question_mark',
  problemMessage:
      "The '?' is unnecessary because '{0}' is nullable without it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unnecessary_question_mark',
  withArguments: _withArgumentsUnnecessaryQuestionMark,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unnecessarySetLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_set_literal',
      problemMessage:
          "Braces unnecessarily wrap this expression in a set literal.",
      correctionMessage: "Try removing the set literal around the expression.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_set_literal',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryTypeCheckFalse =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_type_check',
      problemMessage: "Unnecessary type check; the result is always 'false'.",
      correctionMessage:
          "Try correcting the type check, or removing the type check.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_type_check_false',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryTypeCheckTrue =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_type_check',
      problemMessage: "Unnecessary type check; the result is always 'true'.",
      correctionMessage:
          "Try correcting the type check, or removing the type check.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_type_check_true',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unnecessaryWildcardPattern =
    DiagnosticWithoutArgumentsImpl(
      name: 'unnecessary_wildcard_pattern',
      problemMessage: "Unnecessary wildcard pattern.",
      correctionMessage: "Try removing the wildcard pattern.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unnecessary_wildcard_pattern',
      expectedTypes: [],
    );

/// This is a specialization of [instanceAccessToStaticMember] that is used
/// when we are able to find the name defined in a supertype. It exists to
/// provide a more informative error message.
///
/// Parameters:
/// String name: the name of the defining type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unqualifiedReferenceToNonLocalStaticMember = DiagnosticWithArguments(
  name: 'unqualified_reference_to_non_local_static_member',
  problemMessage:
      "Static members from supertypes must be qualified by the name of the "
      "defining type.",
  correctionMessage: "Try adding '{0}.' before the name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unqualified_reference_to_non_local_static_member',
  withArguments: _withArgumentsUnqualifiedReferenceToNonLocalStaticMember,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the defining type
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unqualifiedReferenceToStaticMemberOfExtendedType = DiagnosticWithArguments(
  name: 'unqualified_reference_to_static_member_of_extended_type',
  problemMessage:
      "Static members from the extended type or one of its superclasses must be "
      "qualified by the name of the defining type.",
  correctionMessage: "Try adding '{0}.' before the name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unqualified_reference_to_static_member_of_extended_type',
  withArguments: _withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unreachableSwitchCase =
    DiagnosticWithoutArgumentsImpl(
      name: 'unreachable_switch_case',
      problemMessage: "This case is covered by the previous cases.",
      correctionMessage:
          "Try removing the case clause, or restructuring the preceding "
          "patterns.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unreachable_switch_case',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unreachableSwitchDefault =
    DiagnosticWithoutArgumentsImpl(
      name: 'unreachable_switch_default',
      problemMessage: "This default clause is covered by the previous cases.",
      correctionMessage:
          "Try removing the default clause, or restructuring the preceding "
          "patterns.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'unreachable_switch_default',
      expectedTypes: [],
    );

/// An error code indicating that an unrecognized error code is being used to
/// specify an error filter.
///
/// Parameters:
/// String codeName: the unrecognized error code
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String codeName})
>
unrecognizedErrorCode = DiagnosticWithArguments(
  name: 'unrecognized_error_code',
  problemMessage: "'{0}' isn't a recognized diagnostic code.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unrecognized_error_code',
  withArguments: _withArgumentsUnrecognizedErrorCode,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified feature is not supported on Chrome OS.
///
/// Parameters:
/// String name: the name of the feature
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unsupportedChromeOsFeature = DiagnosticWithArguments(
  name: 'unsupported_chrome_os_feature',
  problemMessage:
      "The feature {0} isn't supported on Chrome OS, consider making it "
      "optional.",
  correctionMessage:
      "Try changing to `android:required=\"false\"` for this feature.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_chrome_os_feature',
  withArguments: _withArgumentsUnsupportedChromeOsFeature,
  expectedTypes: [ExpectedType.string],
);

/// A code indicating that a specified hardware feature is not supported on
/// Chrome OS.
///
/// Parameters:
/// String name: the name of the feature
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unsupportedChromeOsHardware = DiagnosticWithArguments(
  name: 'unsupported_chrome_os_hardware',
  problemMessage:
      "The feature {0} isn't supported on Chrome OS, consider making it "
      "optional.",
  correctionMessage:
      "Try adding `android:required=\"false\"` for this feature.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_chrome_os_hardware',
  withArguments: _withArgumentsUnsupportedChromeOsHardware,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String lexeme: the unsupported operator
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String lexeme})
>
unsupportedOperator = DiagnosticWithArguments(
  name: 'unsupported_operator',
  problemMessage: "The '{0}' operator is not supported.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'unsupported_operator',
  withArguments: _withArgumentsUnsupportedOperator,
  expectedTypes: [ExpectedType.string],
);

/// An error code indicating that a YAML section is being configured with an
/// unsupported option where there is just one legal value.
///
/// Parameters:
/// String sectionName: the section name
/// String optionKey: the unsupported option key
/// String legalValue: the legal value
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String sectionName,
    required String optionKey,
    required String legalValue,
  })
>
unsupportedOptionWithLegalValue = DiagnosticWithArguments(
  name: 'unsupported_option',
  problemMessage: "The option '{1}' isn't supported by '{0}'.",
  correctionMessage:
      "Try using the only supported option: '{2}', or removing the option.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_option_with_legal_value',
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
/// String sectionName: the section name
/// String optionKey: the unsupported option key
/// String legalValues: legal values
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String sectionName,
    required String optionKey,
    required String legalValues,
  })
>
unsupportedOptionWithLegalValues = DiagnosticWithArguments(
  name: 'unsupported_option',
  problemMessage: "The option '{1}' isn't supported by '{0}'.",
  correctionMessage: "Try using one of the supported options: {2}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_option_with_legal_values',
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
/// String sectionName: the section name
/// String optionKey: the unsupported option key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String sectionName,
    required String optionKey,
  })
>
unsupportedOptionWithoutValues = DiagnosticWithArguments(
  name: 'unsupported_option',
  problemMessage: "The option '{1}' isn't supported by '{0}'.",
  correctionMessage: "Try removing the option.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_option_without_values',
  withArguments: _withArgumentsUnsupportedOptionWithoutValues,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// An error code indicating that an option entry is being configured with an
/// unsupported value.
///
/// Parameters:
/// String optionName: the option name
/// Object invalidValue: the unsupported value
/// String legalValues: legal values
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String optionName,
    required Object invalidValue,
    required String legalValues,
  })
>
unsupportedValue = DiagnosticWithArguments(
  name: 'unsupported_value',
  problemMessage: "The value '{1}' isn't supported by '{0}'.",
  correctionMessage: "Try using one of the supported values: {2}.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unsupported_value',
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
      name: 'unterminated_multi_line_comment',
      problemMessage: "Unterminated multi-line comment.",
      correctionMessage:
          "Try terminating the comment with '*/', or removing any unbalanced "
          "occurrences of '/*' (because comments nest in Dart).",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'unterminated_multi_line_comment',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unterminatedStringLiteral =
    DiagnosticWithoutArgumentsImpl(
      name: 'unterminated_string_literal',
      problemMessage: "Unterminated string literal.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'unterminated_string_literal',
      expectedTypes: [],
    );

/// Parameters:
/// String name: the name of the exception variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedCatchClause = DiagnosticWithArguments(
  name: 'unused_catch_clause',
  problemMessage:
      "The exception variable '{0}' isn't used, so the 'catch' clause can be "
      "removed.",
  correctionMessage: "Try removing the catch clause.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_catch_clause',
  withArguments: _withArgumentsUnusedCatchClause,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the stack trace variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedCatchStack = DiagnosticWithArguments(
  name: 'unused_catch_stack',
  problemMessage:
      "The stack trace variable '{0}' isn't used and can be removed.",
  correctionMessage: "Try removing the stack trace variable, or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_catch_stack',
  withArguments: _withArgumentsUnusedCatchStack,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name that is declared but not referenced
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedElement = DiagnosticWithArguments(
  name: 'unused_element',
  problemMessage: "The declaration '{0}' isn't referenced.",
  correctionMessage: "Try removing the declaration of '{0}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_element',
  withArguments: _withArgumentsUnusedElement,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the parameter that is declared but not used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedElementParameter = DiagnosticWithArguments(
  name: 'unused_element_parameter',
  problemMessage: "A value for optional parameter '{0}' isn't ever given.",
  correctionMessage: "Try removing the unused parameter.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_element_parameter',
  withArguments: _withArgumentsUnusedElementParameter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String fieldName: the name of the unused field
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String fieldName})
>
unusedField = DiagnosticWithArguments(
  name: 'unused_field',
  problemMessage: "The value of the field '{0}' isn't used.",
  correctionMessage: "Try removing the field, or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_field',
  withArguments: _withArgumentsUnusedField,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String fieldName: the name of the unused field
/// String keyword: the keyword to remove
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String fieldName,
    required String keyword,
  })
>
unusedFieldFromPrimaryConstructor = DiagnosticWithArguments(
  name: 'unused_field_from_primary_constructor',
  problemMessage: "The value of the field '{0}' isn't used.",
  correctionMessage:
      "Try removing the '{1}' keyword to avoid declaring a field, or try "
      "using the field, or removing it.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_field_from_primary_constructor',
  withArguments: _withArgumentsUnusedFieldFromPrimaryConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String uriStr: the content of the unused import's URI
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uriStr})
>
unusedImport = DiagnosticWithArguments(
  name: 'unused_import',
  problemMessage: "Unused import: '{0}'.",
  correctionMessage: "Try removing the import directive.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_import',
  withArguments: _withArgumentsUnusedImport,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the label that isn't used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedLabel = DiagnosticWithArguments(
  name: 'unused_label',
  problemMessage: "The label '{0}' isn't used.",
  correctionMessage:
      "Try removing the label, or using it in either a 'break' or 'continue' "
      "statement.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_label',
  withArguments: _withArgumentsUnusedLabel,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the unused variable
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedLocalVariable = DiagnosticWithArguments(
  name: 'unused_local_variable',
  problemMessage: "The value of the local variable '{0}' isn't used.",
  correctionMessage: "Try removing the variable or using it.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_local_variable',
  withArguments: _withArgumentsUnusedLocalVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String name: the name of the annotated method, property or function
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedResult = DiagnosticWithArguments(
  name: 'unused_result',
  problemMessage: "The value of '{0}' should be used.",
  correctionMessage:
      "Try using the result by invoking a member, passing it to a function, "
      "or returning it from this function.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_result',
  withArguments: _withArgumentsUnusedResult,
  expectedTypes: [ExpectedType.string],
);

/// The result of invoking a method, property, or function annotated with
/// `@useResult` must be used (assigned, passed to a function as an argument,
/// or returned by a function).
///
/// Parameters:
/// String name: the name of the annotated method, property or function
/// String message: message details
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name, required String message})
>
unusedResultWithMessage = DiagnosticWithArguments(
  name: 'unused_result',
  problemMessage: "'{0}' should be used. {1}.",
  correctionMessage:
      "Try using the result by invoking a member, passing it to a function, "
      "or returning it from this function.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_result_with_message',
  withArguments: _withArgumentsUnusedResultWithMessage,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String name: the name that is shown but not used
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String name})
>
unusedShownName = DiagnosticWithArguments(
  name: 'unused_shown_name',
  problemMessage: "The name {0} is shown, but isn't used.",
  correctionMessage: "Try removing the name from the list of shown members.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'unused_shown_name',
  withArguments: _withArgumentsUnusedShownName,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String uriStr: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uriStr})
>
uriDoesNotExist = DiagnosticWithArguments(
  name: 'uri_does_not_exist',
  problemMessage: "Target of URI doesn't exist: '{0}'.",
  correctionMessage:
      "Try creating the file referenced by the URI, or try using a URI for a "
      "file that does exist.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'uri_does_not_exist',
  withArguments: _withArgumentsUriDoesNotExist,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String uriStr: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uriStr})
>
uriDoesNotExistInDocImport = DiagnosticWithArguments(
  name: 'uri_does_not_exist_in_doc_import',
  problemMessage: "Target of URI doesn't exist: '{0}'.",
  correctionMessage:
      "Try creating the file referenced by the URI, or try using a URI for a "
      "file that does exist.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'uri_does_not_exist_in_doc_import',
  withArguments: _withArgumentsUriDoesNotExistInDocImport,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String uriStr: the URI pointing to a nonexistent file
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String uriStr})
>
uriHasNotBeenGenerated = DiagnosticWithArguments(
  name: 'uri_has_not_been_generated',
  problemMessage: "Target of URI hasn't been generated: '{0}'.",
  correctionMessage:
      "Try running the generator that will generate the file referenced by "
      "the URI.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'uri_has_not_been_generated',
  withArguments: _withArgumentsUriHasNotBeenGenerated,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments uriWithInterpolation =
    DiagnosticWithoutArgumentsImpl(
      name: 'uri_with_interpolation',
      problemMessage: "URIs can't use string interpolation.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'uri_with_interpolation',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
useOfNativeExtension = DiagnosticWithoutArgumentsImpl(
  name: 'use_of_native_extension',
  problemMessage:
      "Dart native extensions are deprecated and aren't available in Dart 2.15.",
  correctionMessage: "Try using dart:ffi for C interop.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'use_of_native_extension',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
useOfVoidResult = DiagnosticWithoutArgumentsImpl(
  name: 'use_of_void_result',
  problemMessage:
      "This expression has a type of 'void' so its value can't be used.",
  correctionMessage:
      "Try checking to see if you're using the correct API; there might be a "
      "function or call that returns void you didn't expect. Also check type "
      "parameters and variables which might also be void.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'use_of_void_result',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments valuesDeclarationInEnum =
    DiagnosticWithoutArgumentsImpl(
      name: 'values_declaration_in_enum',
      problemMessage: "A member named 'values' can't be declared in an enum.",
      correctionMessage: "Try using a different name.",
      hasPublishedDocs: true,
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'values_declaration_in_enum',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments varAndType = DiagnosticWithoutArgumentsImpl(
  name: 'var_and_type',
  problemMessage:
      "Variables can't be declared using both 'var' and a type name.",
  correctionMessage: "Try removing 'var.'",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_and_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varAsTypeName = DiagnosticWithoutArgumentsImpl(
  name: 'var_as_type_name',
  problemMessage: "The keyword 'var' can't be used as a type name.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_as_type_name',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varClass = DiagnosticWithoutArgumentsImpl(
  name: 'var_class',
  problemMessage: "Classes can't be declared to be 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_class',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varEnum = DiagnosticWithoutArgumentsImpl(
  name: 'var_enum',
  problemMessage: "Enums can't be declared to be 'var'.",
  correctionMessage: "Try removing the keyword 'var'.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_enum',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments
variableLengthArrayNotLast = DiagnosticWithoutArgumentsImpl(
  name: 'variable_length_array_not_last',
  problemMessage:
      "Variable length 'Array's must only occur as the last field of Structs.",
  correctionMessage: "Try adjusting the arguments in the 'Array' annotation.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'variable_length_array_not_last',
  expectedTypes: [],
);

/// No parameters.
///
/// No parameters.
const DiagnosticWithoutArguments
variablePatternKeywordInDeclarationContext = DiagnosticWithoutArgumentsImpl(
  name: 'variable_pattern_keyword_in_declaration_context',
  problemMessage:
      "Variable patterns in declaration context can't specify 'var' or 'final' "
      "keyword.",
  correctionMessage: "Try removing the keyword.",
  hasPublishedDocs: true,
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'variable_pattern_keyword_in_declaration_context',
  expectedTypes: [],
);

/// Parameters:
/// String valueType: the type of the object being assigned.
/// String variableType: the type of the variable being assigned to
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String valueType,
    required String variableType,
  })
>
variableTypeMismatch = DiagnosticWithArguments(
  name: 'variable_type_mismatch',
  problemMessage:
      "A value of type '{0}' can't be assigned to a const variable of type "
      "'{1}'.",
  correctionMessage: "Try using a subtype, or removing the 'const' keyword",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'variable_type_mismatch',
  withArguments: _withArgumentsVariableTypeMismatch,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments varReturnType = DiagnosticWithoutArgumentsImpl(
  name: 'var_return_type',
  problemMessage: "The return type can't be 'var'.",
  correctionMessage:
      "Try removing the keyword 'var', or replacing it with the name of the "
      "return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_return_type',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments varTypedef = DiagnosticWithoutArgumentsImpl(
  name: 'var_typedef',
  problemMessage: "Typedefs can't be declared to be 'var'.",
  correctionMessage:
      "Try removing the keyword 'var', or replacing it with the name of the "
      "return type.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'var_typedef',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments voidWithTypeArguments =
    DiagnosticWithoutArgumentsImpl(
      name: 'void_with_type_arguments',
      problemMessage: "Type 'void' can't have type arguments.",
      correctionMessage: "Try removing the type arguments.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'void_with_type_arguments',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments withBeforeExtends =
    DiagnosticWithoutArgumentsImpl(
      name: 'with_before_extends',
      problemMessage: "The extends clause must be before the with clause.",
      correctionMessage:
          "Try moving the extends clause before the with clause.",
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'with_before_extends',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments
workspaceFieldNotList = DiagnosticWithoutArgumentsImpl(
  name: 'workspace_field_not_list',
  problemMessage:
      "The value of the 'workspace' field is required to be a list of relative "
      "file paths.",
  correctionMessage:
      "Try converting the value to be a list of relative file paths.",
  hasPublishedDocs: true,
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'workspace_field_not_list',
  expectedTypes: [],
);

/// No parameters.
const DiagnosticWithoutArguments workspaceValueNotString =
    DiagnosticWithoutArgumentsImpl(
      name: 'workspace_value_not_string',
      problemMessage:
          "Workspace entries are required to be directory paths (strings).",
      correctionMessage: "Try converting the value to be a string.",
      hasPublishedDocs: true,
      type: DiagnosticType.STATIC_WARNING,
      uniqueName: 'workspace_value_not_string',
      expectedTypes: [],
    );

/// Parameters:
/// String path: the path of the directory that contains the pubspec.yaml
///              file.
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String path})
>
workspaceValueNotSubdirectory = DiagnosticWithArguments(
  name: 'workspace_value_not_subdirectory',
  problemMessage:
      "Workspace values must be a relative path of a subdirectory of '{0}'.",
  correctionMessage:
      "Try using a subdirectory of the directory containing the "
      "'pubspec.yaml' file.",
  type: DiagnosticType.STATIC_WARNING,
  uniqueName: 'workspace_value_not_subdirectory',
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
/// String typeParameterName: the name of the type parameter
/// String varianceModifier: the variance modifier defined for the type
///                          parameter
/// String variancePosition: the variance position of the type parameter in
///                          the superinterface
/// Type superInterface: the type of the superinterface
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String typeParameterName,
    required String varianceModifier,
    required String variancePosition,
    required DartType superInterface,
  })
>
wrongExplicitTypeParameterVarianceInSuperinterface = DiagnosticWithArguments(
  name: 'wrong_explicit_type_parameter_variance_in_superinterface',
  problemMessage:
      "'{0}' is an '{1}' type parameter and can't be used in an '{2}' position "
      "in '{3}'.",
  correctionMessage:
      "Try using 'in' type parameters in 'in' positions and 'out' type "
      "parameters in 'out' positions in the superinterface.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_explicit_type_parameter_variance_in_superinterface',
  withArguments:
      _withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.type,
  ],
);

/// Parameters:
/// String name: the name of the declared operator
/// int expectedCount: the number of parameters expected
/// int actualCount: the number of parameters found in the operator
///                  declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String name,
    required int expectedCount,
    required int actualCount,
  })
>
wrongNumberOfParametersForOperator = DiagnosticWithArguments(
  name: 'wrong_number_of_parameters_for_operator',
  problemMessage:
      "Operator '{0}' should declare exactly {1} parameters, but {2} found.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_parameters_for_operator',
  withArguments: _withArgumentsWrongNumberOfParametersForOperator,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// 7.1.1 Operators: It is a compile time error if the arity of the
/// user-declared operator - is not 0 or 1.
///
/// Parameters:
/// int actualCount: the number of parameters found in the operator
///                  declaration
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required int actualCount})
>
wrongNumberOfParametersForOperatorMinus = DiagnosticWithArguments(
  name: 'wrong_number_of_parameters_for_operator',
  problemMessage:
      "Operator '-' should declare 0 or 1 parameter, but {0} found.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_parameters_for_operator_minus',
  withArguments: _withArgumentsWrongNumberOfParametersForOperatorMinus,
  expectedTypes: [ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments wrongNumberOfParametersForSetter =
    DiagnosticWithoutArgumentsImpl(
      name: 'wrong_number_of_parameters_for_setter',
      problemMessage:
          "Setters must declare exactly one required positional parameter.",
      hasPublishedDocs: true,
      type: DiagnosticType.SYNTACTIC_ERROR,
      uniqueName: 'wrong_number_of_parameters_for_setter',
      expectedTypes: [],
    );

/// Parameters:
/// String type: the name of the type being referenced
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String type,
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArguments = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments',
  problemMessage:
      "The type '{0}' is declared with {1} type parameters, but {2} type "
      "arguments were given.",
  correctionMessage:
      "Try adjusting the number of type arguments to match the number of "
      "type parameters.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments',
  withArguments: _withArgumentsWrongNumberOfTypeArguments,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String className: the name of the class being instantiated
/// String constructorName: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String constructorName,
  })
>
wrongNumberOfTypeArgumentsConstructor = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_constructor',
  problemMessage: "The constructor '{0}.{1}' doesn't have type parameters.",
  correctionMessage: "Try moving type arguments to after the type name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_constructor',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String className: the name of the class being instantiated
/// String constructorName: the name of the constructor being invoked
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String className,
    required String constructorName,
  })
>
wrongNumberOfTypeArgumentsDotShorthandConstructor = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_constructor',
  problemMessage:
      "The dot shorthand resolves to the constructor '{0}.{1}', and type "
      "parameters can't be applied to dot shorthand constructor invocations.",
  correctionMessage:
      "Try removing the type arguments, or adding a class name, followed by "
      "the type arguments, then the constructor name.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_dot_shorthand_constructor',
  withArguments:
      _withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String kind: the name of the kind of the element being referenced
/// String element: the name of the element being referenced
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String kind,
    required String element,
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArgumentsElement = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_element',
  problemMessage:
      "The {0} '{1}' is declared with {2} type parameters, but {3} type "
      "arguments are given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_element',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsElement,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.int,
    ExpectedType.int,
  ],
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
wrongNumberOfTypeArgumentsEnum = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_enum',
  problemMessage:
      "The enum is declared with {0} type parameters, but {1} type arguments "
      "were given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_enum',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsEnum,
  expectedTypes: [ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// String extensionName: the name of the extension being referenced
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String extensionName,
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArgumentsExtension = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_extension',
  problemMessage:
      "The extension '{0}' is declared with {1} type parameters, but {2} type "
      "arguments were given.",
  correctionMessage: "Try adjusting the number of type arguments.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_extension',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsExtension,
  expectedTypes: [ExpectedType.string, ExpectedType.int, ExpectedType.int],
);

/// Parameters:
/// Type type: the function type
/// int typeParameterCount: the number of type parameters that were declared
/// int typeArgumentCount: the number of type arguments provided
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType type,
    required int typeParameterCount,
    required int typeArgumentCount,
  })
>
wrongNumberOfTypeArgumentsFunction = DiagnosticWithArguments(
  name: 'wrong_number_of_type_arguments_function',
  problemMessage:
      "The type of this function is '{0}', which has {1} type parameters, but "
      "{2} type arguments were given.",
  correctionMessage:
      "Try adjusting the number of type arguments to match the number of "
      "type parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_number_of_type_arguments_function',
  withArguments: _withArgumentsWrongNumberOfTypeArgumentsFunction,
  expectedTypes: [ExpectedType.type, ExpectedType.int, ExpectedType.int],
);

/// No parameters.
const DiagnosticWithoutArguments
wrongSeparatorForPositionalParameter = DiagnosticWithoutArgumentsImpl(
  name: 'wrong_separator_for_positional_parameter',
  problemMessage:
      "The default value of a positional parameter should be preceded by '='.",
  correctionMessage: "Try replacing the ':' with '='.",
  type: DiagnosticType.SYNTACTIC_ERROR,
  uniqueName: 'wrong_separator_for_positional_parameter',
  expectedTypes: [],
);

/// Let `C` be a generic class that declares a formal type parameter `X`, and
/// assume that `T` is a direct superinterface of `C`. It is a compile-time
/// error if `X` occurs contravariantly or invariantly in `T`.
///
/// Parameters:
/// String typeParameterName: the name of the type parameter
/// Type superInterfaceType: the name of the super interface
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String typeParameterName,
    required DartType superInterfaceType,
  })
>
wrongTypeParameterVarianceInSuperinterface = DiagnosticWithArguments(
  name: 'wrong_type_parameter_variance_in_superinterface',
  problemMessage:
      "'{0}' can't be used contravariantly or invariantly in '{1}'.",
  correctionMessage:
      "Try not using class type parameters in types of formal parameters of "
      "function types, nor in explicitly contravariant or invariant "
      "superinterfaces.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_type_parameter_variance_in_superinterface',
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
/// String modifier: the variance modifier
/// String typeParameterName: the name of the type parameter
/// String variancePosition: the variance position that the type parameter is
///                          in
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String modifier,
    required String typeParameterName,
    required String variancePosition,
  })
>
wrongTypeParameterVariancePosition = DiagnosticWithArguments(
  name: 'wrong_type_parameter_variance_position',
  problemMessage:
      "The '{0}' type parameter '{1}' can't be used in an '{2}' position.",
  correctionMessage:
      "Try removing the type parameter or change the explicit variance "
      "modifier declaration for the type parameter to another one of 'in', "
      "'out', or 'inout'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_type_parameter_variance_position',
  withArguments: _withArgumentsWrongTypeParameterVariancePosition,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// No parameters.
const DiagnosticWithoutArguments
yieldEachInNonGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'yield_in_non_generator',
  problemMessage:
      "Yield-each statements must be in a generator function (one marked with "
      "either 'async*' or 'sync*').",
  correctionMessage:
      "Try adding 'async*' or 'sync*' to the enclosing function.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'yield_each_in_non_generator',
  expectedTypes: [],
);

/// Parameters:
/// Type actualType: the type of the expression after `yield*`
/// Type expectedType: the return type of the function containing the `yield*`
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
yieldEachOfInvalidType = DiagnosticWithArguments(
  name: 'yield_of_invalid_type',
  problemMessage:
      "The type '{0}' implied by the 'yield*' expression must be assignable to "
      "'{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'yield_each_of_invalid_type',
  withArguments: _withArgumentsYieldEachOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

/// ?? Yield: It is a compile-time error if a yield statement appears in a
/// function that is not a generator function.
///
/// No parameters.
const DiagnosticWithoutArguments
yieldInNonGenerator = DiagnosticWithoutArgumentsImpl(
  name: 'yield_in_non_generator',
  problemMessage:
      "Yield statements must be in a generator function (one marked with either "
      "'async*' or 'sync*').",
  correctionMessage:
      "Try adding 'async*' or 'sync*' to the enclosing function.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'yield_in_non_generator',
  expectedTypes: [],
);

/// Parameters:
/// Type actualType: the type of the expression after `yield`
/// Type expectedType: the return type of the function containing the `yield`
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required DartType actualType,
    required DartType expectedType,
  })
>
yieldOfInvalidType = DiagnosticWithArguments(
  name: 'yield_of_invalid_type',
  problemMessage: "A yielded value of type '{0}' must be assignable to '{1}'.",
  hasPublishedDocs: true,
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'yield_of_invalid_type',
  withArguments: _withArgumentsYieldOfInvalidType,
  expectedTypes: [ExpectedType.type, ExpectedType.type],
);

LocatableDiagnostic _withArgumentsAbiSpecificIntegerMappingUnsupported({
  required String mappingName,
}) {
  return LocatableDiagnosticImpl(diag.abiSpecificIntegerMappingUnsupported, [
    mappingName,
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
  required String name,
  required Uri firstUri,
  required Uri secondUri,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousExport, [
    name,
    firstUri,
    secondUri,
  ]);
}

LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessThreeOrMore({
  required String name,
  required String extensions,
}) {
  return LocatableDiagnosticImpl(
    diag.ambiguousExtensionMemberAccessThreeOrMore,
    [name, extensions],
  );
}

LocatableDiagnostic _withArgumentsAmbiguousExtensionMemberAccessTwo({
  required String name,
  required Element firstExtension,
  required Element secondExtension,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousExtensionMemberAccessTwo, [
    name,
    firstExtension,
    secondExtension,
  ]);
}

LocatableDiagnostic _withArgumentsAmbiguousImport({
  required String name,
  required String libraries,
}) {
  return LocatableDiagnosticImpl(diag.ambiguousImport, [name, libraries]);
}

LocatableDiagnostic _withArgumentsAnalysisOptionDeprecated({
  required String optionName,
}) {
  return LocatableDiagnosticImpl(diag.analysisOptionDeprecated, [optionName]);
}

LocatableDiagnostic _withArgumentsAnalysisOptionDeprecatedWithReplacement({
  required Object optionName,
  required Object replacementOptionName,
}) {
  return LocatableDiagnosticImpl(diag.analysisOptionDeprecatedWithReplacement, [
    optionName,
    replacementOptionName,
  ]);
}

LocatableDiagnostic _withArgumentsArgumentMustBeAConstant({
  required String argumentName,
}) {
  return LocatableDiagnosticImpl(diag.argumentMustBeAConstant, [argumentName]);
}

LocatableDiagnostic _withArgumentsArgumentTypeNotAssignable({
  required DartType actualStaticType,
  required DartType expectedStaticType,
  required String additionalInfo,
}) {
  return LocatableDiagnosticImpl(diag.argumentTypeNotAssignable, [
    actualStaticType,
    expectedStaticType,
    additionalInfo,
  ]);
}

LocatableDiagnostic _withArgumentsArgumentTypeNotAssignableToErrorHandler({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.argumentTypeNotAssignableToErrorHandler, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsAssetDirectoryDoesNotExist({
  required String path,
}) {
  return LocatableDiagnosticImpl(diag.assetDirectoryDoesNotExist, [path]);
}

LocatableDiagnostic _withArgumentsAssetDoesNotExist({required String path}) {
  return LocatableDiagnosticImpl(diag.assetDoesNotExist, [path]);
}

LocatableDiagnostic _withArgumentsAssignmentOfDoNotStore({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.assignmentOfDoNotStore, [name]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinal({
  required String variableName,
}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinal, [variableName]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinalLocal({
  required String variableName,
}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinalLocal, [variableName]);
}

LocatableDiagnostic _withArgumentsAssignmentToFinalNoSetter({
  required String variableName,
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.assignmentToFinalNoSetter, [
    variableName,
    className,
  ]);
}

LocatableDiagnostic _withArgumentsAugmentationModifierExtra({
  required String modifier,
}) {
  return LocatableDiagnosticImpl(diag.augmentationModifierExtra, [modifier]);
}

LocatableDiagnostic _withArgumentsAugmentationModifierMissing({
  required String modifier,
}) {
  return LocatableDiagnosticImpl(diag.augmentationModifierMissing, [modifier]);
}

LocatableDiagnostic _withArgumentsAugmentationOfDifferentDeclarationKind({
  required String declarationKind,
  required String augmentationKind,
}) {
  return LocatableDiagnosticImpl(diag.augmentationOfDifferentDeclarationKind, [
    declarationKind,
    augmentationKind,
  ]);
}

LocatableDiagnostic _withArgumentsAugmentedExpressionNotOperator({
  required String operator,
}) {
  return LocatableDiagnosticImpl(diag.augmentedExpressionNotOperator, [
    operator,
  ]);
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
  required String actualOperator,
  required String expectedOperator,
}) {
  return LocatableDiagnosticImpl(diag.binaryOperatorWrittenOut, [
    actualOperator,
    expectedOperator,
  ]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormally({
  required DartType returnType,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormally, [returnType]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyCatchError({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormallyCatchError, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsBodyMightCompleteNormallyNullable({
  required DartType returnType,
}) {
  return LocatableDiagnosticImpl(diag.bodyMightCompleteNormallyNullable, [
    returnType,
  ]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsExtensionName, [name]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsExtensionTypeName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsExtensionTypeName, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsPrefixName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsPrefixName, [name]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsType({
  required String token,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsType, [token]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypedefName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypedefName, [name]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypeName, [name]);
}

LocatableDiagnostic _withArgumentsBuiltInIdentifierAsTypeParameterName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.builtInIdentifierAsTypeParameterName, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsCaseExpressionTypeImplementsEquals({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.caseExpressionTypeImplementsEquals, [
    type,
  ]);
}

LocatableDiagnostic
_withArgumentsCaseExpressionTypeIsNotSwitchExpressionSubtype({
  required DartType caseExpressionType,
  required DartType scrutineeType,
}) {
  return LocatableDiagnosticImpl(
    diag.caseExpressionTypeIsNotSwitchExpressionSubtype,
    [caseExpressionType, scrutineeType],
  );
}

LocatableDiagnostic _withArgumentsCastFromNullableAlwaysFails({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.castFromNullableAlwaysFails, [name]);
}

LocatableDiagnostic _withArgumentsCastToNonType({required String name}) {
  return LocatableDiagnosticImpl(diag.castToNonType, [name]);
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToInstanceMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.classInstantiationAccessToInstanceMember,
    [name],
  );
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToStaticMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.classInstantiationAccessToStaticMember, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsClassInstantiationAccessToUnknownMember({
  required String className,
  required String memberName,
}) {
  return LocatableDiagnosticImpl(diag.classInstantiationAccessToUnknownMember, [
    className,
    memberName,
  ]);
}

LocatableDiagnostic _withArgumentsClassUsedAsMixin({required String name}) {
  return LocatableDiagnosticImpl(diag.classUsedAsMixin, [name]);
}

LocatableDiagnostic _withArgumentsCompoundImplementsFinalizable({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.compoundImplementsFinalizable, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsConcreteClassWithAbstractMember({
  required String methodName,
  required String enclosingClass,
}) {
  return LocatableDiagnosticImpl(diag.concreteClassWithAbstractMember, [
    methodName,
    enclosingClass,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticField({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticField, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticGetter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticGetter, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticMethod({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticMethod, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingConstructorAndStaticSetter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.conflictingConstructorAndStaticSetter, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingFieldAndMethod({
  required String className,
  required String fieldName,
  required String conflictingClassName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingFieldAndMethod, [
    className,
    fieldName,
    conflictingClassName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingGenericInterfaces({
  required String kind,
  required String element,
  required String type1,
  required String type2,
}) {
  return LocatableDiagnosticImpl(diag.conflictingGenericInterfaces, [
    kind,
    element,
    type1,
    type2,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingInheritedMethodAndSetter({
  required String enclosingElementKind,
  required String enclosingElementName,
  required String memberName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingInheritedMethodAndSetter, [
    enclosingElementKind,
    enclosingElementName,
    memberName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingMethodAndField({
  required String className,
  required String methodName,
  required String conflictingClassName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingMethodAndField, [
    className,
    methodName,
    conflictingClassName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingModifiers({
  required String modifier,
  required String earlierModifier,
}) {
  return LocatableDiagnosticImpl(diag.conflictingModifiers, [
    modifier,
    earlierModifier,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingStaticAndInstance({
  required String className,
  required String memberName,
  required String conflictingClassName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingStaticAndInstance, [
    className,
    memberName,
    conflictingClassName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndClass({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndClass, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndEnum({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndEnum, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtension({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndExtension, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndExtensionType({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndExtensionType, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberClass({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberClass, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberEnum({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberEnum, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberExtension({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(
    diag.conflictingTypeVariableAndMemberExtension,
    [typeParameterName],
  );
}

LocatableDiagnostic
_withArgumentsConflictingTypeVariableAndMemberExtensionType({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(
    diag.conflictingTypeVariableAndMemberExtensionType,
    [typeParameterName],
  );
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMemberMixin({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMemberMixin, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConflictingTypeVariableAndMixin({
  required String typeParameterName,
}) {
  return LocatableDiagnosticImpl(diag.conflictingTypeVariableAndMixin, [
    typeParameterName,
  ]);
}

LocatableDiagnostic _withArgumentsConstantPatternNeverMatchesValueType({
  required DartType matchedType,
  required DartType constantType,
}) {
  return LocatableDiagnosticImpl(diag.constantPatternNeverMatchesValueType, [
    matchedType,
    constantType,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorFieldTypeMismatch({
  required String valueType,
  required String fieldName,
  required String fieldType,
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
  required String fieldName,
}) {
  return LocatableDiagnosticImpl(
    diag.constConstructorWithFieldInitializedByNonConst,
    [fieldName],
  );
}

LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithField({
  required String fieldName,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithMixinWithField, [
    fieldName,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorWithMixinWithFields({
  required String fieldNames,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithMixinWithFields, [
    fieldNames,
  ]);
}

LocatableDiagnostic _withArgumentsConstConstructorWithNonConstSuper({
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.constConstructorWithNonConstSuper, [
    superclassName,
  ]);
}

LocatableDiagnostic _withArgumentsConstEvalAssertionFailureWithMessage({
  required String message,
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
  required DartType initializerExpressionType,
  required DartType fieldType,
}) {
  return LocatableDiagnosticImpl(diag.constFieldInitializerNotAssignable, [
    initializerExpressionType,
    fieldType,
  ]);
}

LocatableDiagnostic _withArgumentsConstMapKeyNotPrimitiveEquality({
  required DartType keyType,
}) {
  return LocatableDiagnosticImpl(diag.constMapKeyNotPrimitiveEquality, [
    keyType,
  ]);
}

LocatableDiagnostic _withArgumentsConstNotInitialized({required String name}) {
  return LocatableDiagnosticImpl(diag.constNotInitialized, [name]);
}

LocatableDiagnostic _withArgumentsConstSetElementNotPrimitiveEquality({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.constSetElementNotPrimitiveEquality, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsConstWithNonType({required String name}) {
  return LocatableDiagnosticImpl(diag.constWithNonType, [name]);
}

LocatableDiagnostic _withArgumentsConstWithUndefinedConstructor({
  required String className,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.constWithUndefinedConstructor, [
    className,
    constructorName,
  ]);
}

LocatableDiagnostic _withArgumentsConstWithUndefinedConstructorDefault({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.constWithUndefinedConstructorDefault, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsCouldNotInfer({
  required String typeParameterName,
  required String detailText,
}) {
  return LocatableDiagnosticImpl(diag.couldNotInfer, [
    typeParameterName,
    detailText,
  ]);
}

LocatableDiagnostic _withArgumentsDeadCodeOnCatchSubtype({
  required DartType subtype,
  required DartType supertype,
}) {
  return LocatableDiagnosticImpl(diag.deadCodeOnCatchSubtype, [
    subtype,
    supertype,
  ]);
}

LocatableDiagnostic _withArgumentsDefinitelyUnassignedLateLocalVariable({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.definitelyUnassignedLateLocalVariable, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsDependenciesFieldNotMap({
  required String fieldName,
}) {
  return LocatableDiagnosticImpl(diag.dependenciesFieldNotMap, [fieldName]);
}

LocatableDiagnostic _withArgumentsDeprecatedExportUse({required String name}) {
  return LocatableDiagnosticImpl(diag.deprecatedExportUse, [name]);
}

LocatableDiagnostic _withArgumentsDeprecatedExtend({required String typeName}) {
  return LocatableDiagnosticImpl(diag.deprecatedExtend, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedField({required String fieldName}) {
  return LocatableDiagnosticImpl(diag.deprecatedField, [fieldName]);
}

LocatableDiagnostic _withArgumentsDeprecatedImplement({
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedImplement, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedInstantiate({
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedInstantiate, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedLint({required String ruleName}) {
  return LocatableDiagnosticImpl(diag.deprecatedLint, [ruleName]);
}

LocatableDiagnostic _withArgumentsDeprecatedLintWithReplacement({
  required String deprecatedRuleName,
  required String replacementRuleName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedLintWithReplacement, [
    deprecatedRuleName,
    replacementRuleName,
  ]);
}

LocatableDiagnostic _withArgumentsDeprecatedMemberUse({required String name}) {
  return LocatableDiagnosticImpl(diag.deprecatedMemberUse, [name]);
}

LocatableDiagnostic _withArgumentsDeprecatedMemberUseWithMessage({
  required String name,
  required String details,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedMemberUseWithMessage, [
    name,
    details,
  ]);
}

LocatableDiagnostic _withArgumentsDeprecatedMixin({required String typeName}) {
  return LocatableDiagnosticImpl(diag.deprecatedMixin, [typeName]);
}

LocatableDiagnostic _withArgumentsDeprecatedOptional({
  required String parameterName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedOptional, [parameterName]);
}

LocatableDiagnostic _withArgumentsDeprecatedSubclass({
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.deprecatedSubclass, [typeName]);
}

LocatableDiagnostic _withArgumentsDocDirectiveArgumentWrongFormat({
  required String argumentName,
  required String expectedFormat,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveArgumentWrongFormat, [
    argumentName,
    expectedFormat,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveHasExtraArguments({
  required String directive,
  required int actualCount,
  required int expectedCount,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveHasExtraArguments, [
    directive,
    actualCount,
    expectedCount,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveHasUnexpectedNamedArgument({
  required String directive,
  required String argumentName,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveHasUnexpectedNamedArgument, [
    directive,
    argumentName,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingClosingTag({
  required String tagName,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingClosingTag, [tagName]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingOneArgument({
  required String directive,
  required String argumentName,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingOneArgument, [
    directive,
    argumentName,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingOpeningTag({
  required String tagName,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingOpeningTag, [tagName]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingThreeArguments({
  required String directive,
  required String argument1,
  required String argument2,
  required String argument3,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingThreeArguments, [
    directive,
    argument1,
    argument2,
    argument3,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveMissingTwoArguments({
  required String directive,
  required String argument1,
  required String argument2,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveMissingTwoArguments, [
    directive,
    argument1,
    argument2,
  ]);
}

LocatableDiagnostic _withArgumentsDocDirectiveUnknown({
  required String directive,
}) {
  return LocatableDiagnosticImpl(diag.docDirectiveUnknown, [directive]);
}

LocatableDiagnostic _withArgumentsDotShorthandUndefinedGetter({
  required String getterName,
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.dotShorthandUndefinedGetter, [
    getterName,
    typeName,
  ]);
}

LocatableDiagnostic _withArgumentsDotShorthandUndefinedInvocation({
  required String name,
  required String contextType,
}) {
  return LocatableDiagnosticImpl(diag.dotShorthandUndefinedInvocation, [
    name,
    contextType,
  ]);
}

LocatableDiagnostic _withArgumentsDuplicateConstructorName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicateConstructorName, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateDefinition({required String name}) {
  return LocatableDiagnosticImpl(diag.duplicateDefinition, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateFieldFormalParameter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicateFieldFormalParameter, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateFieldName({required String name}) {
  return LocatableDiagnosticImpl(diag.duplicateFieldName, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateIgnore({required String name}) {
  return LocatableDiagnosticImpl(diag.duplicateIgnore, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateNamedArgument({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicateNamedArgument, [name]);
}

LocatableDiagnostic _withArgumentsDuplicatePart({required Uri uri}) {
  return LocatableDiagnosticImpl(diag.duplicatePart, [uri]);
}

LocatableDiagnostic _withArgumentsDuplicatePatternAssignmentVariable({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicatePatternAssignmentVariable, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsDuplicatePatternField({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicatePatternField, [name]);
}

LocatableDiagnostic _withArgumentsDuplicateRule({required String ruleName}) {
  return LocatableDiagnosticImpl(diag.duplicateRule, [ruleName]);
}

LocatableDiagnostic _withArgumentsDuplicateVariablePattern({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.duplicateVariablePattern, [name]);
}

LocatableDiagnostic _withArgumentsEmptyStruct({
  required String subclassName,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.emptyStruct, [
    subclassName,
    superclassName,
  ]);
}

LocatableDiagnostic _withArgumentsEnumWithAbstractMember({
  required String methodName,
  required String enclosingClass,
}) {
  return LocatableDiagnosticImpl(diag.enumWithAbstractMember, [
    methodName,
    enclosingClass,
  ]);
}

LocatableDiagnostic _withArgumentsExpectedInstead({required String expected}) {
  return LocatableDiagnosticImpl(diag.expectedInstead, [expected]);
}

LocatableDiagnostic _withArgumentsExpectedOneListPatternTypeArguments({
  required int count,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneListPatternTypeArguments, [
    count,
  ]);
}

LocatableDiagnostic _withArgumentsExpectedOneListTypeArguments({
  required int count,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneListTypeArguments, [count]);
}

LocatableDiagnostic _withArgumentsExpectedOneSetTypeArguments({
  required int count,
}) {
  return LocatableDiagnosticImpl(diag.expectedOneSetTypeArguments, [count]);
}

LocatableDiagnostic _withArgumentsExpectedToken({required String token}) {
  return LocatableDiagnosticImpl(diag.expectedToken, [token]);
}

LocatableDiagnostic _withArgumentsExpectedTwoMapPatternTypeArguments({
  required int count,
}) {
  return LocatableDiagnosticImpl(diag.expectedTwoMapPatternTypeArguments, [
    count,
  ]);
}

LocatableDiagnostic _withArgumentsExpectedTwoMapTypeArguments({
  required int count,
}) {
  return LocatableDiagnosticImpl(diag.expectedTwoMapTypeArguments, [count]);
}

LocatableDiagnostic _withArgumentsExperimentalMemberUse({
  required String member,
}) {
  return LocatableDiagnosticImpl(diag.experimentalMemberUse, [member]);
}

LocatableDiagnostic _withArgumentsExperimentNotEnabled({
  required String featureName,
  required String enabledVersion,
}) {
  return LocatableDiagnosticImpl(diag.experimentNotEnabled, [
    featureName,
    enabledVersion,
  ]);
}

LocatableDiagnostic _withArgumentsExperimentNotEnabledOffByDefault({
  required String featureName,
}) {
  return LocatableDiagnosticImpl(diag.experimentNotEnabledOffByDefault, [
    featureName,
  ]);
}

LocatableDiagnostic _withArgumentsExportInternalLibrary({required String uri}) {
  return LocatableDiagnosticImpl(diag.exportInternalLibrary, [uri]);
}

LocatableDiagnostic _withArgumentsExportOfNonLibrary({required String uri}) {
  return LocatableDiagnosticImpl(diag.exportOfNonLibrary, [uri]);
}

LocatableDiagnostic _withArgumentsExtendsDisallowedClass({
  required DartType disallowedType,
}) {
  return LocatableDiagnosticImpl(diag.extendsDisallowedClass, [disallowedType]);
}

LocatableDiagnostic _withArgumentsExtensionAsExpression({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.extensionAsExpression, [name]);
}

LocatableDiagnostic _withArgumentsExtensionConflictingStaticAndInstance({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.extensionConflictingStaticAndInstance, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionOverrideArgumentNotAssignable({
  required DartType argumentType,
  required DartType extendedType,
}) {
  return LocatableDiagnosticImpl(diag.extensionOverrideArgumentNotAssignable, [
    argumentType,
    extendedType,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeImplementsDisallowedType({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeImplementsDisallowedType, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeImplementsNotSupertype({
  required DartType type,
  required DartType representationType,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeImplementsNotSupertype, [
    type,
    representationType,
  ]);
}

LocatableDiagnostic
_withArgumentsExtensionTypeImplementsRepresentationNotSupertype({
  required DartType implementedRepresentationType,
  required String implementedExtensionTypeName,
  required DartType representationType,
  required String extensionTypeName,
}) {
  return LocatableDiagnosticImpl(
    diag.extensionTypeImplementsRepresentationNotSupertype,
    [
      implementedRepresentationType,
      implementedExtensionTypeName,
      representationType,
      extensionTypeName,
    ],
  );
}

LocatableDiagnostic _withArgumentsExtensionTypeInheritedMemberConflict({
  required String extensionTypeName,
  required String memberName,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeInheritedMemberConflict, [
    extensionTypeName,
    memberName,
  ]);
}

LocatableDiagnostic _withArgumentsExtensionTypeWithAbstractMember({
  required String methodName,
  required String extensionTypeName,
}) {
  return LocatableDiagnosticImpl(diag.extensionTypeWithAbstractMember, [
    methodName,
    extensionTypeName,
  ]);
}

LocatableDiagnostic _withArgumentsExtraPositionalArguments({
  required int expected,
  required int found,
}) {
  return LocatableDiagnosticImpl(diag.extraPositionalArguments, [
    expected,
    found,
  ]);
}

LocatableDiagnostic _withArgumentsExtraPositionalArgumentsCouldBeNamed({
  required int expected,
  required int found,
}) {
  return LocatableDiagnosticImpl(diag.extraPositionalArgumentsCouldBeNamed, [
    expected,
    found,
  ]);
}

LocatableDiagnostic _withArgumentsFfiNativeUnexpectedNumberOfParameters({
  required int expected,
  required int actual,
}) {
  return LocatableDiagnosticImpl(diag.ffiNativeUnexpectedNumberOfParameters, [
    expected,
    actual,
  ]);
}

LocatableDiagnostic
_withArgumentsFfiNativeUnexpectedNumberOfParametersWithReceiver({
  required int expected,
  required int actual,
}) {
  return LocatableDiagnosticImpl(
    diag.ffiNativeUnexpectedNumberOfParametersWithReceiver,
    [expected, actual],
  );
}

LocatableDiagnostic _withArgumentsFieldInitializedByMultipleInitializers({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializedByMultipleInitializers, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsFieldInitializerNotAssignable({
  required DartType initializerExpressionType,
  required DartType fieldType,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializerNotAssignable, [
    initializerExpressionType,
    fieldType,
  ]);
}

LocatableDiagnostic _withArgumentsFieldInitializingFormalNotAssignable({
  required DartType formalParameterType,
  required DartType fieldType,
}) {
  return LocatableDiagnosticImpl(diag.fieldInitializingFormalNotAssignable, [
    formalParameterType,
    fieldType,
  ]);
}

LocatableDiagnostic _withArgumentsFinalClassExtendedOutsideOfLibrary({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.finalClassExtendedOutsideOfLibrary, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsFinalClassImplementedOutsideOfLibrary({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.finalClassImplementedOutsideOfLibrary, [
    name,
  ]);
}

LocatableDiagnostic
_withArgumentsFinalClassUsedAsMixinConstraintOutsideOfLibrary({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.finalClassUsedAsMixinConstraintOutsideOfLibrary,
    [name],
  );
}

LocatableDiagnostic _withArgumentsFinalInitializedInDeclarationAndConstructor({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.finalInitializedInDeclarationAndConstructor,
    [name],
  );
}

LocatableDiagnostic _withArgumentsFinalNotInitialized({required String name}) {
  return LocatableDiagnosticImpl(diag.finalNotInitialized, [name]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor1({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor1, [name]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor2({
  required String name1,
  required String name2,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor2, [
    name1,
    name2,
  ]);
}

LocatableDiagnostic _withArgumentsFinalNotInitializedConstructor3Plus({
  required String name1,
  required String name2,
  required int remainingCount,
}) {
  return LocatableDiagnosticImpl(diag.finalNotInitializedConstructor3Plus, [
    name1,
    name2,
    remainingCount,
  ]);
}

LocatableDiagnostic _withArgumentsFixme({required String message}) {
  return LocatableDiagnosticImpl(diag.fixme, [message]);
}

LocatableDiagnostic _withArgumentsForInOfInvalidElementType({
  required DartType iterableType,
  required String expectedTypeName,
  required DartType loopVariableType,
}) {
  return LocatableDiagnosticImpl(diag.forInOfInvalidElementType, [
    iterableType,
    expectedTypeName,
    loopVariableType,
  ]);
}

LocatableDiagnostic _withArgumentsForInOfInvalidType({
  required DartType expressionType,
  required String expectedType,
}) {
  return LocatableDiagnosticImpl(diag.forInOfInvalidType, [
    expressionType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsGenericStructSubclass({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.genericStructSubclass, [className]);
}

LocatableDiagnostic _withArgumentsGetterNotSubtypeSetterTypes({
  required String getterName,
  required DartType getterType,
  required DartType setterType,
  required String setterName,
}) {
  return LocatableDiagnosticImpl(diag.getterNotSubtypeSetterTypes, [
    getterName,
    getterType,
    setterType,
    setterName,
  ]);
}

LocatableDiagnostic _withArgumentsHack({required String message}) {
  return LocatableDiagnosticImpl(diag.hack, [message]);
}

LocatableDiagnostic _withArgumentsIllegalCharacter({required int codePoint}) {
  return LocatableDiagnosticImpl(diag.illegalCharacter, [codePoint]);
}

LocatableDiagnostic _withArgumentsIllegalConcreteEnumMemberDeclaration({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.illegalConcreteEnumMemberDeclaration, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsIllegalConcreteEnumMemberInheritance({
  required String memberName,
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.illegalConcreteEnumMemberInheritance, [
    memberName,
    className,
  ]);
}

LocatableDiagnostic _withArgumentsIllegalEnumValuesInheritance({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.illegalEnumValuesInheritance, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsIllegalLanguageVersionOverride({
  required String requiredVersion,
}) {
  return LocatableDiagnosticImpl(diag.illegalLanguageVersionOverride, [
    requiredVersion,
  ]);
}

LocatableDiagnostic _withArgumentsImplementsDisallowedClass({
  required DartType disallowedType,
}) {
  return LocatableDiagnosticImpl(diag.implementsDisallowedClass, [
    disallowedType,
  ]);
}

LocatableDiagnostic _withArgumentsImplementsRepeated({
  required String interfaceName,
}) {
  return LocatableDiagnosticImpl(diag.implementsRepeated, [interfaceName]);
}

LocatableDiagnostic _withArgumentsImplementsSuperClass({
  required Element superElement,
}) {
  return LocatableDiagnosticImpl(diag.implementsSuperClass, [superElement]);
}

LocatableDiagnostic _withArgumentsImplicitSuperInitializerMissingArguments({
  required DartType superType,
}) {
  return LocatableDiagnosticImpl(
    diag.implicitSuperInitializerMissingArguments,
    [superType],
  );
}

LocatableDiagnostic _withArgumentsImplicitThisReferenceInInitializer({
  required String memberName,
}) {
  return LocatableDiagnosticImpl(diag.implicitThisReferenceInInitializer, [
    memberName,
  ]);
}

LocatableDiagnostic _withArgumentsImportInternalLibrary({required String uri}) {
  return LocatableDiagnosticImpl(diag.importInternalLibrary, [uri]);
}

LocatableDiagnostic _withArgumentsImportOfNonLibrary({required String uri}) {
  return LocatableDiagnosticImpl(diag.importOfNonLibrary, [uri]);
}

LocatableDiagnostic _withArgumentsIncludedFileParseError({
  required String includingFilePath,
  required int startOffset,
  required int endOffset,
  required String errorMessage,
}) {
  return LocatableDiagnosticImpl(diag.includedFileParseError, [
    includingFilePath,
    startOffset,
    endOffset,
    errorMessage,
  ]);
}

LocatableDiagnostic _withArgumentsIncludedFileWarning({
  required Object includingFilePath,
  required int startOffset,
  required int endOffset,
  required String warningMessage,
}) {
  return LocatableDiagnosticImpl(diag.includedFileWarning, [
    includingFilePath,
    startOffset,
    endOffset,
    warningMessage,
  ]);
}

LocatableDiagnostic _withArgumentsIncludeFileNotFound({
  required String includedUri,
  required String includingFilePath,
  required String contextRootPath,
}) {
  return LocatableDiagnosticImpl(diag.includeFileNotFound, [
    includedUri,
    includingFilePath,
    contextRootPath,
  ]);
}

LocatableDiagnostic _withArgumentsIncompatibleLint({
  required String ruleName,
  required String incompatibleRules,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLint, [
    ruleName,
    incompatibleRules,
  ]);
}

LocatableDiagnostic _withArgumentsIncompatibleLintFiles({
  required String ruleName,
  required String incompatibleRules,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLintFiles, [
    ruleName,
    incompatibleRules,
  ]);
}

LocatableDiagnostic _withArgumentsIncompatibleLintIncluded({
  required String ruleName,
  required String incompatibleRules,
  required int numIncludingFiles,
  required String pluralSuffix,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleLintIncluded, [
    ruleName,
    incompatibleRules,
    numIncludingFiles,
    pluralSuffix,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentInheritance({
  required String name,
  required String inheritedSignatures,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentInheritance, [
    name,
    inheritedSignatures,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentInheritanceGetterAndMethod({
  required String memberName,
  required String getterInterface,
  required String methodInterface,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentInheritanceGetterAndMethod, [
    memberName,
    getterInterface,
    methodInterface,
  ]);
}

LocatableDiagnostic _withArgumentsInconsistentPatternVariableLogicalOr({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.inconsistentPatternVariableLogicalOr, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnCollectionLiteral({
  required String collection,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnCollectionLiteral, [
    collection,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnFunctionInvocation({
  required String function,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnFunctionInvocation, [
    function,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnFunctionReturnType({
  required String function,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnFunctionReturnType, [
    function,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnGenericInvocation({
  required String function,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnGenericInvocation, [
    function,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnInstanceCreation({
  required String function,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnInstanceCreation, [
    function,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnUninitializedVariable({
  required String variable,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnUninitializedVariable, [
    variable,
  ]);
}

LocatableDiagnostic _withArgumentsInferenceFailureOnUntypedParameter({
  required String parameter,
}) {
  return LocatableDiagnosticImpl(diag.inferenceFailureOnUntypedParameter, [
    parameter,
  ]);
}

LocatableDiagnostic _withArgumentsInitializerForNonExistentField({
  required String formalName,
}) {
  return LocatableDiagnosticImpl(diag.initializerForNonExistentField, [
    formalName,
  ]);
}

LocatableDiagnostic _withArgumentsInitializerForStaticField({
  required String formalName,
}) {
  return LocatableDiagnosticImpl(diag.initializerForStaticField, [formalName]);
}

LocatableDiagnostic _withArgumentsInitializingFormalForNonExistentField({
  required String formalName,
}) {
  return LocatableDiagnosticImpl(diag.initializingFormalForNonExistentField, [
    formalName,
  ]);
}

LocatableDiagnostic _withArgumentsInstanceAccessToStaticMember({
  required String memberName,
  required String memberKind,
  required String enclosingElementName,
  required String enclosingElementKind,
}) {
  return LocatableDiagnosticImpl(diag.instanceAccessToStaticMember, [
    memberName,
    memberKind,
    enclosingElementName,
    enclosingElementKind,
  ]);
}

LocatableDiagnostic
_withArgumentsInstanceAccessToStaticMemberOfUnnamedExtension({
  required String name,
  required String kind,
}) {
  return LocatableDiagnosticImpl(
    diag.instanceAccessToStaticMemberOfUnnamedExtension,
    [name, kind],
  );
}

LocatableDiagnostic _withArgumentsIntegerLiteralImpreciseAsDouble({
  required String literal,
  required String closestDouble,
}) {
  return LocatableDiagnosticImpl(diag.integerLiteralImpreciseAsDouble, [
    literal,
    closestDouble,
  ]);
}

LocatableDiagnostic _withArgumentsIntegerLiteralOutOfRange({
  required String literal,
}) {
  return LocatableDiagnosticImpl(diag.integerLiteralOutOfRange, [literal]);
}

LocatableDiagnostic _withArgumentsInterfaceClassExtendedOutsideOfLibrary({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.interfaceClassExtendedOutsideOfLibrary, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidAnnotationTarget({
  required String annotationName,
  required String validTargets,
}) {
  return LocatableDiagnosticImpl(diag.invalidAnnotationTarget, [
    annotationName,
    validTargets,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidAssignment({
  required DartType actualStaticType,
  required DartType expectedStaticType,
}) {
  return LocatableDiagnosticImpl(diag.invalidAssignment, [
    actualStaticType,
    expectedStaticType,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidCodePoint({
  required String escapeSequence,
}) {
  return LocatableDiagnosticImpl(diag.invalidCodePoint, [escapeSequence]);
}

LocatableDiagnostic _withArgumentsInvalidDependency({required String kind}) {
  return LocatableDiagnosticImpl(diag.invalidDependency, [kind]);
}

LocatableDiagnostic _withArgumentsInvalidExceptionValue({
  required String methodName,
}) {
  return LocatableDiagnosticImpl(diag.invalidExceptionValue, [methodName]);
}

LocatableDiagnostic _withArgumentsInvalidExportOfInternalElement({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidExportOfInternalElement, [name]);
}

LocatableDiagnostic _withArgumentsInvalidExportOfInternalElementIndirectly({
  required String internalElementName,
  required String exportedElementName,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidExportOfInternalElementIndirectly,
    [internalElementName, exportedElementName],
  );
}

LocatableDiagnostic _withArgumentsInvalidFactoryMethodDecl({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidFactoryMethodDecl, [name]);
}

LocatableDiagnostic _withArgumentsInvalidFactoryMethodImpl({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidFactoryMethodImpl, [name]);
}

LocatableDiagnostic _withArgumentsInvalidFieldTypeInStruct({
  required String type,
}) {
  return LocatableDiagnosticImpl(diag.invalidFieldTypeInStruct, [type]);
}

LocatableDiagnostic _withArgumentsInvalidImplementationOverride({
  required String memberName,
  required String declaringInterfaceName,
  required DartType typeInDeclaringInterface,
  required String overriddenInterfaceName,
  required DartType typeInOverriddenInterface,
}) {
  return LocatableDiagnosticImpl(diag.invalidImplementationOverride, [
    memberName,
    declaringInterfaceName,
    typeInDeclaringInterface,
    overriddenInterfaceName,
    typeInOverriddenInterface,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidImplementationOverrideSetter({
  required String memberName,
  required String declaringInterfaceName,
  required DartType typeInDeclaringInterface,
  required String overriddenInterfaceName,
  required DartType typeInOverriddenInterface,
}) {
  return LocatableDiagnosticImpl(diag.invalidImplementationOverrideSetter, [
    memberName,
    declaringInterfaceName,
    typeInDeclaringInterface,
    overriddenInterfaceName,
    typeInOverriddenInterface,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidLanguageVersionOverrideGreater({
  required int latestMajor,
  required int latestMinor,
}) {
  return LocatableDiagnosticImpl(diag.invalidLanguageVersionOverrideGreater, [
    latestMajor,
    latestMinor,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidModifierOnConstructor({
  required String modifier,
}) {
  return LocatableDiagnosticImpl(diag.invalidModifierOnConstructor, [modifier]);
}

LocatableDiagnostic _withArgumentsInvalidNullAwareOperator({
  required String operator,
  required String replacement,
}) {
  return LocatableDiagnosticImpl(diag.invalidNullAwareOperator, [
    operator,
    replacement,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidNullAwareOperatorAfterShortCircuit({
  required String operator,
  required String replacement,
}) {
  return LocatableDiagnosticImpl(
    diag.invalidNullAwareOperatorAfterShortCircuit,
    [operator, replacement],
  );
}

LocatableDiagnostic _withArgumentsInvalidOption({
  required String optionName,
  required String detailMessage,
}) {
  return LocatableDiagnosticImpl(diag.invalidOption, [
    optionName,
    detailMessage,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidOverride({
  required String memberName,
  required String declaringInterfaceName,
  required DartType typeInDeclaringInterface,
  required String overriddenInterfaceName,
  required DartType typeInOverriddenInterface,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverride, [
    memberName,
    declaringInterfaceName,
    typeInDeclaringInterface,
    overriddenInterfaceName,
    typeInOverriddenInterface,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidOverrideOfNonVirtualMember({
  required String memberName,
  required String definingClass,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverrideOfNonVirtualMember, [
    memberName,
    definingClass,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidOverrideSetter({
  required String memberName,
  required String declaringInterfaceName,
  required DartType typeInDeclaringInterface,
  required String overriddenInterfaceName,
  required DartType typeInOverriddenInterface,
}) {
  return LocatableDiagnosticImpl(diag.invalidOverrideSetter, [
    memberName,
    declaringInterfaceName,
    typeInDeclaringInterface,
    overriddenInterfaceName,
    typeInOverriddenInterface,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidSectionFormat({
  required String sectionName,
}) {
  return LocatableDiagnosticImpl(diag.invalidSectionFormat, [sectionName]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstList({
  required String typeParameter,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstList, [
    typeParameter,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstMap({
  required String typeParameter,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstMap, [
    typeParameter,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidTypeArgumentInConstSet({
  required String typeParameter,
}) {
  return LocatableDiagnosticImpl(diag.invalidTypeArgumentInConstSet, [
    typeParameter,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUri({required String uri}) {
  return LocatableDiagnosticImpl(diag.invalidUri, [uri]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfDoNotSubmitMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfDoNotSubmitMember, [name]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfInternalMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfInternalMember, [name]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfProtectedMember({
  required String memberName,
  required String definingClass,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfProtectedMember, [
    memberName,
    definingClass,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForOverridingMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForOverridingMember, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTemplateMember({
  required String memberName,
  required Uri uri,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForTemplateMember, [
    memberName,
    uri,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidUseOfVisibleForTestingMember({
  required String memberName,
  required Uri uri,
}) {
  return LocatableDiagnosticImpl(diag.invalidUseOfVisibleForTestingMember, [
    memberName,
    uri,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidVisibilityAnnotation({
  required String memberName,
  required String annotationName,
}) {
  return LocatableDiagnosticImpl(diag.invalidVisibilityAnnotation, [
    memberName,
    annotationName,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidWidgetPreviewPrivateArgument({
  required String privateSymbolName,
  required String suggestedName,
}) {
  return LocatableDiagnosticImpl(diag.invalidWidgetPreviewPrivateArgument, [
    privateSymbolName,
    suggestedName,
  ]);
}

LocatableDiagnostic _withArgumentsInvocationOfExtensionWithoutCall({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invocationOfExtensionWithoutCall, [name]);
}

LocatableDiagnostic _withArgumentsInvocationOfNonFunction({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.invocationOfNonFunction, [name]);
}

LocatableDiagnostic _withArgumentsLabelInOuterScope({required String name}) {
  return LocatableDiagnosticImpl(diag.labelInOuterScope, [name]);
}

LocatableDiagnostic _withArgumentsLabelUndefined({required String name}) {
  return LocatableDiagnosticImpl(diag.labelUndefined, [name]);
}

LocatableDiagnostic _withArgumentsListElementTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.listElementTypeNotAssignable, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsListElementTypeNotAssignableNullability({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.listElementTypeNotAssignableNullability, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.mapKeyTypeNotAssignable, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsMapKeyTypeNotAssignableNullability({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.mapKeyTypeNotAssignableNullability, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsMapValueTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.mapValueTypeNotAssignable, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsMapValueTypeNotAssignableNullability({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.mapValueTypeNotAssignableNullability, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsMissingAnnotationOnStructField({
  required DartType type,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.missingAnnotationOnStructField, [
    type,
    superclassName,
  ]);
}

LocatableDiagnostic _withArgumentsMissingDefaultValueForParameter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.missingDefaultValueForParameter, [name]);
}

LocatableDiagnostic _withArgumentsMissingDefaultValueForParameterPositional({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.missingDefaultValueForParameterPositional,
    [name],
  );
}

LocatableDiagnostic _withArgumentsMissingDependency({
  required String missing,
  required String fix,
}) {
  return LocatableDiagnosticImpl(diag.missingDependency, [missing, fix]);
}

LocatableDiagnostic _withArgumentsMissingEnumConstantInSwitch({
  required String constant,
}) {
  return LocatableDiagnosticImpl(diag.missingEnumConstantInSwitch, [constant]);
}

LocatableDiagnostic _withArgumentsMissingExceptionValue({
  required String methodName,
}) {
  return LocatableDiagnosticImpl(diag.missingExceptionValue, [methodName]);
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
  required int additionalCount,
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
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.missingRequiredArgument, [name]);
}

LocatableDiagnostic _withArgumentsMissingRequiredParam({required String name}) {
  return LocatableDiagnosticImpl(diag.missingRequiredParam, [name]);
}

LocatableDiagnostic _withArgumentsMissingRequiredParamWithDetails({
  required String name,
  required String details,
}) {
  return LocatableDiagnosticImpl(diag.missingRequiredParamWithDetails, [
    name,
    details,
  ]);
}

LocatableDiagnostic _withArgumentsMissingVariablePattern({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.missingVariablePattern, [name]);
}

LocatableDiagnostic
_withArgumentsMixinApplicationConcreteSuperInvokedMemberType({
  required String memberName,
  required DartType mixinMemberType,
  required DartType concreteMemberType,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationConcreteSuperInvokedMemberType,
    [memberName, mixinMemberType, concreteMemberType],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNoConcreteSuperInvokedMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationNoConcreteSuperInvokedMember,
    [name],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNoConcreteSuperInvokedSetter({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinApplicationNoConcreteSuperInvokedSetter,
    [name],
  );
}

LocatableDiagnostic _withArgumentsMixinApplicationNotImplementedInterface({
  required DartType mixinType,
  required DartType superType,
  required DartType notImplementedType,
}) {
  return LocatableDiagnosticImpl(diag.mixinApplicationNotImplementedInterface, [
    mixinType,
    superType,
    notImplementedType,
  ]);
}

LocatableDiagnostic _withArgumentsMixinClassDeclarationExtendsNotObject({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.mixinClassDeclarationExtendsNotObject, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsMixinClassDeclaresConstructor({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.mixinClassDeclaresConstructor, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsMixinInheritsFromNotObject({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.mixinInheritsFromNotObject, [name]);
}

LocatableDiagnostic _withArgumentsMixinOfDisallowedClass({
  required DartType disallowedType,
}) {
  return LocatableDiagnosticImpl(diag.mixinOfDisallowedClass, [disallowedType]);
}

LocatableDiagnostic _withArgumentsMixinOnSealedClass({required String name}) {
  return LocatableDiagnosticImpl(diag.mixinOnSealedClass, [name]);
}

LocatableDiagnostic _withArgumentsMixinsSuperClass({
  required Element referencedClass,
}) {
  return LocatableDiagnosticImpl(diag.mixinsSuperClass, [referencedClass]);
}

LocatableDiagnostic _withArgumentsMixinSubtypeOfBaseIsNotBase({
  required String subtypeName,
  required String supertypeName,
}) {
  return LocatableDiagnosticImpl(diag.mixinSubtypeOfBaseIsNotBase, [
    subtypeName,
    supertypeName,
  ]);
}

LocatableDiagnostic _withArgumentsMixinSubtypeOfFinalIsNotBase({
  required String subtypeName,
  required String supertypeName,
}) {
  return LocatableDiagnosticImpl(diag.mixinSubtypeOfFinalIsNotBase, [
    subtypeName,
    supertypeName,
  ]);
}

LocatableDiagnostic _withArgumentsMixinSuperClassConstraintDisallowedClass({
  required DartType disallowedType,
}) {
  return LocatableDiagnosticImpl(
    diag.mixinSuperClassConstraintDisallowedClass,
    [disallowedType],
  );
}

LocatableDiagnostic _withArgumentsModifierOutOfOrder({
  required String modifier,
  required String expectedLaterModifier,
}) {
  return LocatableDiagnosticImpl(diag.modifierOutOfOrder, [
    modifier,
    expectedLaterModifier,
  ]);
}

LocatableDiagnostic _withArgumentsMultipleClauses({
  required String definitionKind,
  required String clauseKind,
}) {
  return LocatableDiagnosticImpl(diag.multipleClauses, [
    definitionKind,
    clauseKind,
  ]);
}

LocatableDiagnostic _withArgumentsMultiplePlugins({
  required String firstPluginName,
}) {
  return LocatableDiagnosticImpl(diag.multiplePlugins, [firstPluginName]);
}

LocatableDiagnostic _withArgumentsMustBeANativeFunctionType({
  required DartType type,
  required String functionName,
}) {
  return LocatableDiagnosticImpl(diag.mustBeANativeFunctionType, [
    type,
    functionName,
  ]);
}

LocatableDiagnostic _withArgumentsMustBeASubtype({
  required DartType subtype,
  required DartType supertype,
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.mustBeASubtype, [
    subtype,
    supertype,
    name,
  ]);
}

LocatableDiagnostic _withArgumentsMustBeImmutable({
  required String fieldNames,
}) {
  return LocatableDiagnosticImpl(diag.mustBeImmutable, [fieldNames]);
}

LocatableDiagnostic _withArgumentsMustCallSuper({required String className}) {
  return LocatableDiagnosticImpl(diag.mustCallSuper, [className]);
}

LocatableDiagnostic _withArgumentsMustReturnVoid({required DartType type}) {
  return LocatableDiagnosticImpl(diag.mustReturnVoid, [type]);
}

LocatableDiagnostic _withArgumentsNativeFieldInvalidType({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.nativeFieldInvalidType, [type]);
}

LocatableDiagnostic _withArgumentsNewWithNonType({required String name}) {
  return LocatableDiagnosticImpl(diag.newWithNonType, [name]);
}

LocatableDiagnostic _withArgumentsNewWithUndefinedConstructor({
  required String typeName,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.newWithUndefinedConstructor, [
    typeName,
    constructorName,
  ]);
}

LocatableDiagnostic _withArgumentsNewWithUndefinedConstructorDefault({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.newWithUndefinedConstructorDefault, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsNoCombinedSuperSignature({
  required String className,
  required String candidateSignatures,
}) {
  return LocatableDiagnosticImpl(diag.noCombinedSuperSignature, [
    className,
    candidateSignatures,
  ]);
}

LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorExplicit({
  required DartType supertype,
}) {
  return LocatableDiagnosticImpl(diag.noDefaultSuperConstructorExplicit, [
    supertype,
  ]);
}

LocatableDiagnostic _withArgumentsNoDefaultSuperConstructorImplicit({
  required DartType superclassType,
  required String subclassName,
}) {
  return LocatableDiagnosticImpl(diag.noDefaultSuperConstructorImplicit, [
    superclassType,
    subclassName,
  ]);
}

LocatableDiagnostic _withArgumentsNoGenerativeConstructorsInSuperclass({
  required String subclassName,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.noGenerativeConstructorsInSuperclass, [
    subclassName,
    superclassName,
  ]);
}

LocatableDiagnostic
_withArgumentsNonAbstractClassInheritsAbstractMemberFivePlus({
  required String name1,
  required String name2,
  required String name3,
  required String name4,
  required int remainingCount,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberFivePlus,
    [name1, name2, name3, name4, remainingCount],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberFour({
  required String name1,
  required String name2,
  required String name3,
  required String name4,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberFour,
    [name1, name2, name3, name4],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberOne({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberOne,
    [name],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberThree({
  required String name1,
  required String name2,
  required String name3,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberThree,
    [name1, name2, name3],
  );
}

LocatableDiagnostic _withArgumentsNonAbstractClassInheritsAbstractMemberTwo({
  required String name1,
  required String name2,
}) {
  return LocatableDiagnosticImpl(
    diag.nonAbstractClassInheritsAbstractMemberTwo,
    [name1, name2],
  );
}

LocatableDiagnostic _withArgumentsNonBoolOperand({required String operator}) {
  return LocatableDiagnosticImpl(diag.nonBoolOperand, [operator]);
}

LocatableDiagnostic _withArgumentsNonConstantTypeArgument({
  required String executableName,
}) {
  return LocatableDiagnosticImpl(diag.nonConstantTypeArgument, [
    executableName,
  ]);
}

LocatableDiagnostic _withArgumentsNonConstArgumentForConstParameter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.nonConstArgumentForConstParameter, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructor({
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.nonConstCallToLiteralConstructor, [
    constructorName,
  ]);
}

LocatableDiagnostic _withArgumentsNonConstCallToLiteralConstructorUsingNew({
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(
    diag.nonConstCallToLiteralConstructorUsingNew,
    [constructorName],
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
  required Element constructor,
}) {
  return LocatableDiagnosticImpl(diag.nonGenerativeConstructor, [constructor]);
}

LocatableDiagnostic _withArgumentsNonGenerativeImplicitConstructor({
  required String superclassName,
  required String className,
  required Element factoryConstructor,
}) {
  return LocatableDiagnosticImpl(diag.nonGenerativeImplicitConstructor, [
    superclassName,
    className,
    factoryConstructor,
  ]);
}

LocatableDiagnostic _withArgumentsNonNativeFunctionTypeArgumentToPointer({
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.nonNativeFunctionTypeArgumentToPointer, [
    type,
  ]);
}

LocatableDiagnostic _withArgumentsNonSizedTypeArgument({
  required String fieldName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.nonSizedTypeArgument, [fieldName, type]);
}

LocatableDiagnostic _withArgumentsNonTypeAsTypeArgument({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.nonTypeAsTypeArgument, [name]);
}

LocatableDiagnostic _withArgumentsNonTypeInCatchClause({required String name}) {
  return LocatableDiagnosticImpl(diag.nonTypeInCatchClause, [name]);
}

LocatableDiagnostic
_withArgumentsNotAssignedPotentiallyNonNullableLocalVariable({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.notAssignedPotentiallyNonNullableLocalVariable,
    [name],
  );
}

LocatableDiagnostic _withArgumentsNotAType({required String name}) {
  return LocatableDiagnosticImpl(diag.notAType, [name]);
}

LocatableDiagnostic _withArgumentsNotBinaryOperator({required String name}) {
  return LocatableDiagnosticImpl(diag.notBinaryOperator, [name]);
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsNamePlural({
  required int requiredParameterCount,
  required int actualArgumentCount,
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.notEnoughPositionalArgumentsNamePlural, [
    requiredParameterCount,
    actualArgumentCount,
    name,
  ]);
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsNameSingular({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.notEnoughPositionalArgumentsNameSingular,
    [name],
  );
}

LocatableDiagnostic _withArgumentsNotEnoughPositionalArgumentsPlural({
  required int requiredParameterCount,
  required int actualArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.notEnoughPositionalArgumentsPlural, [
    requiredParameterCount,
    actualArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsNotInitializedNonNullableInstanceField({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.notInitializedNonNullableInstanceField, [
    name,
  ]);
}

LocatableDiagnostic
_withArgumentsNotInitializedNonNullableInstanceFieldConstructor({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.notInitializedNonNullableInstanceFieldConstructor,
    [name],
  );
}

LocatableDiagnostic _withArgumentsNotInitializedNonNullableVariable({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.notInitializedNonNullableVariable, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsNullArgumentToNonNullType({
  required String memberName,
  required String typeArgumentName,
}) {
  return LocatableDiagnosticImpl(diag.nullArgumentToNonNullType, [
    memberName,
    typeArgumentName,
  ]);
}

LocatableDiagnostic _withArgumentsOnRepeated({required String interfaceName}) {
  return LocatableDiagnosticImpl(diag.onRepeated, [interfaceName]);
}

LocatableDiagnostic _withArgumentsOutOfOrderClauses({
  required String expectedEarlierClause,
  required String expectedLaterClause,
}) {
  return LocatableDiagnosticImpl(diag.outOfOrderClauses, [
    expectedEarlierClause,
    expectedLaterClause,
  ]);
}

LocatableDiagnostic _withArgumentsParseError({required String errorMessage}) {
  return LocatableDiagnosticImpl(diag.parseError, [errorMessage]);
}

LocatableDiagnostic _withArgumentsPartOfDifferentLibrary({
  required String expectedName,
  required String actualName,
}) {
  return LocatableDiagnosticImpl(diag.partOfDifferentLibrary, [
    expectedName,
    actualName,
  ]);
}

LocatableDiagnostic _withArgumentsPartOfNonPart({required String uriStr}) {
  return LocatableDiagnosticImpl(diag.partOfNonPart, [uriStr]);
}

LocatableDiagnostic _withArgumentsPartOfUnnamedLibrary({
  required String libraryName,
}) {
  return LocatableDiagnosticImpl(diag.partOfUnnamedLibrary, [libraryName]);
}

LocatableDiagnostic _withArgumentsPathDoesNotExist({required String path}) {
  return LocatableDiagnosticImpl(diag.pathDoesNotExist, [path]);
}

LocatableDiagnostic _withArgumentsPathNotPosix({required String path}) {
  return LocatableDiagnosticImpl(diag.pathNotPosix, [path]);
}

LocatableDiagnostic _withArgumentsPathPubspecDoesNotExist({
  required String path,
}) {
  return LocatableDiagnosticImpl(diag.pathPubspecDoesNotExist, [path]);
}

LocatableDiagnostic _withArgumentsPatternNeverMatchesValueType({
  required DartType matchedValueType,
  required DartType requiredType,
}) {
  return LocatableDiagnosticImpl(diag.patternNeverMatchesValueType, [
    matchedValueType,
    requiredType,
  ]);
}

LocatableDiagnostic _withArgumentsPatternTypeMismatchInIrrefutableContext({
  required DartType matchedType,
  required DartType requiredType,
}) {
  return LocatableDiagnosticImpl(diag.patternTypeMismatchInIrrefutableContext, [
    matchedType,
    requiredType,
  ]);
}

LocatableDiagnostic
_withArgumentsPatternVariableSharedCaseScopeDifferentFinalityOrType({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.patternVariableSharedCaseScopeDifferentFinalityOrType,
    [name],
  );
}

LocatableDiagnostic _withArgumentsPatternVariableSharedCaseScopeHasLabel({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.patternVariableSharedCaseScopeHasLabel, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsPatternVariableSharedCaseScopeNotAllCases({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.patternVariableSharedCaseScopeNotAllCases,
    [name],
  );
}

LocatableDiagnostic _withArgumentsPermissionImpliesUnsupportedHardware({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.permissionImpliesUnsupportedHardware, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsPluginsInInnerOptions({
  required String contextRoot,
}) {
  return LocatableDiagnosticImpl(diag.pluginsInInnerOptions, [contextRoot]);
}

LocatableDiagnostic _withArgumentsPrefixCollidesWithTopLevelMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.prefixCollidesWithTopLevelMember, [name]);
}

LocatableDiagnostic _withArgumentsPrefixIdentifierNotFollowedByDot({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.prefixIdentifierNotFollowedByDot, [name]);
}

LocatableDiagnostic _withArgumentsPrefixShadowedByLocalDeclaration({
  required String prefix,
}) {
  return LocatableDiagnosticImpl(diag.prefixShadowedByLocalDeclaration, [
    prefix,
  ]);
}

LocatableDiagnostic _withArgumentsPrivateCollisionInMixinApplication({
  required String collidingName,
  required String mixin1,
  required String mixin2,
}) {
  return LocatableDiagnosticImpl(diag.privateCollisionInMixinApplication, [
    collidingName,
    mixin1,
    mixin2,
  ]);
}

LocatableDiagnostic _withArgumentsPrivateNamedParameterDuplicatePublicName({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.privateNamedParameterDuplicatePublicName,
    [name],
  );
}

LocatableDiagnostic _withArgumentsPrivateSetter({required String name}) {
  return LocatableDiagnosticImpl(diag.privateSetter, [name]);
}

LocatableDiagnostic _withArgumentsReadPotentiallyUnassignedFinal({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.readPotentiallyUnassignedFinal, [name]);
}

LocatableDiagnostic _withArgumentsRecursiveIncludeFile({
  required Object includedUri,
  required Object includingFilePath,
}) {
  return LocatableDiagnosticImpl(diag.recursiveIncludeFile, [
    includedUri,
    includingFilePath,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritance({
  required String className,
  required String loop,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritance, [
    className,
    loop,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceExtends({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceExtends, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceImplements({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceImplements, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceOn({
  required String mixinName,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceOn, [
    mixinName,
  ]);
}

LocatableDiagnostic _withArgumentsRecursiveInterfaceInheritanceWith({
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.recursiveInterfaceInheritanceWith, [
    className,
  ]);
}

LocatableDiagnostic _withArgumentsRedeclareOnNonRedeclaringMember({
  required String kind,
}) {
  return LocatableDiagnosticImpl(diag.redeclareOnNonRedeclaringMember, [kind]);
}

LocatableDiagnostic _withArgumentsRedirectGenerativeToMissingConstructor({
  required String constructorName,
  required String className,
}) {
  return LocatableDiagnosticImpl(diag.redirectGenerativeToMissingConstructor, [
    constructorName,
    className,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToAbstractClassConstructor({
  required String redirectingConstructorName,
  required String abstractClass,
}) {
  return LocatableDiagnosticImpl(diag.redirectToAbstractClassConstructor, [
    redirectingConstructorName,
    abstractClass,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToInvalidFunctionType({
  required DartType redirectedType,
  required DartType redirectingType,
}) {
  return LocatableDiagnosticImpl(diag.redirectToInvalidFunctionType, [
    redirectedType,
    redirectingType,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToInvalidReturnType({
  required DartType redirectedReturnType,
  required DartType redirectingReturnType,
}) {
  return LocatableDiagnosticImpl(diag.redirectToInvalidReturnType, [
    redirectedReturnType,
    redirectingReturnType,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToMissingConstructor({
  required String constructorName,
  required DartType redirectedType,
}) {
  return LocatableDiagnosticImpl(diag.redirectToMissingConstructor, [
    constructorName,
    redirectedType,
  ]);
}

LocatableDiagnostic _withArgumentsRedirectToNonClass({required String name}) {
  return LocatableDiagnosticImpl(diag.redirectToNonClass, [name]);
}

LocatableDiagnostic _withArgumentsReferencedBeforeDeclaration({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.referencedBeforeDeclaration, [name]);
}

LocatableDiagnostic _withArgumentsRelationalPatternOperandTypeNotAssignable({
  required DartType operandType,
  required DartType parameterType,
  required String operator,
}) {
  return LocatableDiagnosticImpl(
    diag.relationalPatternOperandTypeNotAssignable,
    [operandType, parameterType, operator],
  );
}

LocatableDiagnostic _withArgumentsRemovedLint({
  required String ruleName,
  required String sdkVersion,
}) {
  return LocatableDiagnosticImpl(diag.removedLint, [ruleName, sdkVersion]);
}

LocatableDiagnostic _withArgumentsRemovedLintUse({
  required String ruleName,
  required String since,
}) {
  return LocatableDiagnosticImpl(diag.removedLintUse, [ruleName, since]);
}

LocatableDiagnostic _withArgumentsReplacedLint({
  required String ruleName,
  required String sdkVersion,
  required String replacingLintName,
}) {
  return LocatableDiagnosticImpl(diag.replacedLint, [
    ruleName,
    sdkVersion,
    replacingLintName,
  ]);
}

LocatableDiagnostic _withArgumentsReplacedLintUse({
  required String ruleName,
  required String since,
  required String replacement,
}) {
  return LocatableDiagnosticImpl(diag.replacedLintUse, [
    ruleName,
    since,
    replacement,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfDoNotStore({
  required String invokedFunction,
  required String returningFunction,
}) {
  return LocatableDiagnosticImpl(diag.returnOfDoNotStore, [
    invokedFunction,
    returningFunction,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromCatchError({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromCatchError, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromClosure({
  required DartType actualReturnType,
  required DartType expectedReturnType,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromClosure, [
    actualReturnType,
    expectedReturnType,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromConstructor({
  required DartType actualReturnType,
  required DartType expectedReturnType,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromConstructor, [
    actualReturnType,
    expectedReturnType,
    constructorName,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromFunction({
  required DartType actualReturnType,
  required DartType expectedReturnType,
  required String methodName,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromFunction, [
    actualReturnType,
    expectedReturnType,
    methodName,
  ]);
}

LocatableDiagnostic _withArgumentsReturnOfInvalidTypeFromMethod({
  required DartType actualReturnType,
  required DartType expectedReturnType,
  required String methodName,
}) {
  return LocatableDiagnosticImpl(diag.returnOfInvalidTypeFromMethod, [
    actualReturnType,
    expectedReturnType,
    methodName,
  ]);
}

LocatableDiagnostic _withArgumentsReturnTypeInvalidForCatchError({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.returnTypeInvalidForCatchError, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsSdkVersionSince({
  required String availableVersion,
  required String versionConstraints,
}) {
  return LocatableDiagnosticImpl(diag.sdkVersionSince, [
    availableVersion,
    versionConstraints,
  ]);
}

LocatableDiagnostic _withArgumentsSealedClassSubtypeOutsideOfLibrary({
  required String sealedClassName,
}) {
  return LocatableDiagnosticImpl(diag.sealedClassSubtypeOutsideOfLibrary, [
    sealedClassName,
  ]);
}

LocatableDiagnostic _withArgumentsSetElementTypeNotAssignable({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.setElementTypeNotAssignable, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsSetElementTypeNotAssignableNullability({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.setElementTypeNotAssignableNullability, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsStaticAccessToInstanceMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.staticAccessToInstanceMember, [name]);
}

LocatableDiagnostic _withArgumentsStrictRawType({required DartType type}) {
  return LocatableDiagnosticImpl(diag.strictRawType, [type]);
}

LocatableDiagnostic _withArgumentsSubtypeOfBaseIsNotBaseFinalOrSealed({
  required String subtypeName,
  required String supertypeName,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfBaseIsNotBaseFinalOrSealed, [
    subtypeName,
    supertypeName,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfFinalIsNotBaseFinalOrSealed({
  required String subtypeName,
  required String supertypeName,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfFinalIsNotBaseFinalOrSealed, [
    subtypeName,
    supertypeName,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfSealedClass({required String name}) {
  return LocatableDiagnosticImpl(diag.subtypeOfSealedClass, [name]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInExtends({
  required String subclassName,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInExtends, [
    subclassName,
    superclassName,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInImplements({
  required String subclassName,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInImplements, [
    subclassName,
    superclassName,
  ]);
}

LocatableDiagnostic _withArgumentsSubtypeOfStructClassInWith({
  required String subclassName,
  required String superclassName,
}) {
  return LocatableDiagnosticImpl(diag.subtypeOfStructClassInWith, [
    subclassName,
    superclassName,
  ]);
}

LocatableDiagnostic
_withArgumentsSuperFormalParameterTypeIsNotSubtypeOfAssociated({
  required DartType parameterType,
  required DartType superParameterType,
}) {
  return LocatableDiagnosticImpl(
    diag.superFormalParameterTypeIsNotSubtypeOfAssociated,
    [parameterType, superParameterType],
  );
}

LocatableDiagnostic _withArgumentsTextDirectionCodePointInComment({
  required String codePoint,
}) {
  return LocatableDiagnosticImpl(diag.textDirectionCodePointInComment, [
    codePoint,
  ]);
}

LocatableDiagnostic _withArgumentsTextDirectionCodePointInLiteral({
  required String codePoint,
}) {
  return LocatableDiagnosticImpl(diag.textDirectionCodePointInLiteral, [
    codePoint,
  ]);
}

LocatableDiagnostic _withArgumentsThrowOfInvalidType({required DartType type}) {
  return LocatableDiagnosticImpl(diag.throwOfInvalidType, [type]);
}

LocatableDiagnostic _withArgumentsTodo({required String message}) {
  return LocatableDiagnosticImpl(diag.todo, [message]);
}

LocatableDiagnostic _withArgumentsTopLevelCycle({
  required String name,
  required String cycle,
}) {
  return LocatableDiagnosticImpl(diag.topLevelCycle, [name, cycle]);
}

LocatableDiagnostic _withArgumentsTypeAnnotationDeferredClass({
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.typeAnnotationDeferredClass, [typeName]);
}

LocatableDiagnostic _withArgumentsTypeArgumentNotMatchingBounds({
  required DartType nonConformingType,
  required String typeParameterName,
  required DartType bound,
}) {
  return LocatableDiagnosticImpl(diag.typeArgumentNotMatchingBounds, [
    nonConformingType,
    typeParameterName,
    bound,
  ]);
}

LocatableDiagnostic _withArgumentsTypeParameterSupertypeOfItsBound({
  required String typeParameterName,
  required DartType bound,
}) {
  return LocatableDiagnosticImpl(diag.typeParameterSupertypeOfItsBound, [
    typeParameterName,
    bound,
  ]);
}

LocatableDiagnostic _withArgumentsTypeTestWithNonType({required String name}) {
  return LocatableDiagnosticImpl(diag.typeTestWithNonType, [name]);
}

LocatableDiagnostic _withArgumentsTypeTestWithUndefinedName({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.typeTestWithUndefinedName, [name]);
}

LocatableDiagnostic _withArgumentsUncheckedMethodInvocationOfNullableValue({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.uncheckedMethodInvocationOfNullableValue,
    [name],
  );
}

LocatableDiagnostic _withArgumentsUncheckedOperatorInvocationOfNullableValue({
  required String operator,
}) {
  return LocatableDiagnosticImpl(
    diag.uncheckedOperatorInvocationOfNullableValue,
    [operator],
  );
}

LocatableDiagnostic _withArgumentsUncheckedPropertyAccessOfNullableValue({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.uncheckedPropertyAccessOfNullableValue, [
    name,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedAnnotation({required String name}) {
  return LocatableDiagnosticImpl(diag.undefinedAnnotation, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedClass({required String name}) {
  return LocatableDiagnosticImpl(diag.undefinedClass, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedClassBoolean({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.undefinedClassBoolean, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializer({
  required DartType type,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedConstructorInInitializer, [
    type,
    constructorName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedConstructorInInitializerDefault({
  required String className,
}) {
  return LocatableDiagnosticImpl(
    diag.undefinedConstructorInInitializerDefault,
    [className],
  );
}

LocatableDiagnostic _withArgumentsUndefinedEnumConstant({
  required String memberName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedEnumConstant, [
    memberName,
    type,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedEnumConstructorNamed({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.undefinedEnumConstructorNamed, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionGetter({
  required String getterName,
  required String extensionName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionGetter, [
    getterName,
    extensionName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionMethod({
  required String methodName,
  required String extensionName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionMethod, [
    methodName,
    extensionName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionOperator({
  required String operator,
  required String extensionName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionOperator, [
    operator,
    extensionName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedExtensionSetter({
  required String setterName,
  required String extensionName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedExtensionSetter, [
    setterName,
    extensionName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedFunction({required String name}) {
  return LocatableDiagnosticImpl(diag.undefinedFunction, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedGetter({
  required String memberName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedGetter, [memberName, type]);
}

LocatableDiagnostic _withArgumentsUndefinedGetterOnFunctionType({
  required String getterName,
  required String functionTypeAliasName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedGetterOnFunctionType, [
    getterName,
    functionTypeAliasName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedHiddenName({
  required String library,
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.undefinedHiddenName, [library, name]);
}

LocatableDiagnostic _withArgumentsUndefinedIdentifier({required String name}) {
  return LocatableDiagnosticImpl(diag.undefinedIdentifier, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedLint({required String ruleName}) {
  return LocatableDiagnosticImpl(diag.undefinedLint, [ruleName]);
}

LocatableDiagnostic _withArgumentsUndefinedMethod({
  required String methodName,
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedMethod, [methodName, typeName]);
}

LocatableDiagnostic _withArgumentsUndefinedMethodOnFunctionType({
  required String methodName,
  required String functionTypeAliasName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedMethodOnFunctionType, [
    methodName,
    functionTypeAliasName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedNamedParameter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.undefinedNamedParameter, [name]);
}

LocatableDiagnostic _withArgumentsUndefinedOperator({
  required String operator,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedOperator, [operator, type]);
}

LocatableDiagnostic _withArgumentsUndefinedPrefixedName({
  required String referenceName,
  required String prefixName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedPrefixedName, [
    referenceName,
    prefixName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedReferencedParameter({
  required String undefinedParameterName,
  required String targetedMemberName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedReferencedParameter, [
    undefinedParameterName,
    targetedMemberName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedSetter({
  required String setterName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSetter, [setterName, type]);
}

LocatableDiagnostic _withArgumentsUndefinedSetterOnFunctionType({
  required String setterName,
  required String functionTypeAliasName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSetterOnFunctionType, [
    setterName,
    functionTypeAliasName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedShownName({
  required String library,
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.undefinedShownName, [library, name]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperGetter({
  required String getterName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperGetter, [getterName, type]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperMethod({
  required String methodName,
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperMethod, [
    methodName,
    typeName,
  ]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperOperator({
  required String operator,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperOperator, [operator, type]);
}

LocatableDiagnostic _withArgumentsUndefinedSuperSetter({
  required String setterName,
  required DartType type,
}) {
  return LocatableDiagnosticImpl(diag.undefinedSuperSetter, [setterName, type]);
}

LocatableDiagnostic _withArgumentsUndone({required String message}) {
  return LocatableDiagnosticImpl(diag.undone, [message]);
}

LocatableDiagnostic _withArgumentsUnexpectedToken({required String text}) {
  return LocatableDiagnosticImpl(diag.unexpectedToken, [text]);
}

LocatableDiagnostic _withArgumentsUnignorableIgnore({
  required String diagnosticName,
}) {
  return LocatableDiagnosticImpl(diag.unignorableIgnore, [diagnosticName]);
}

LocatableDiagnostic _withArgumentsUnknownPlatform({required String platform}) {
  return LocatableDiagnosticImpl(diag.unknownPlatform, [platform]);
}

LocatableDiagnostic _withArgumentsUnnecessaryDevDependency({
  required String package,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryDevDependency, [package]);
}

LocatableDiagnostic _withArgumentsUnnecessaryImport({
  required String unnecessaryUri,
  required String reasonUri,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryImport, [
    unnecessaryUri,
    reasonUri,
  ]);
}

LocatableDiagnostic _withArgumentsUnnecessaryQuestionMark({
  required String typeName,
}) {
  return LocatableDiagnosticImpl(diag.unnecessaryQuestionMark, [typeName]);
}

LocatableDiagnostic _withArgumentsUnqualifiedReferenceToNonLocalStaticMember({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.unqualifiedReferenceToNonLocalStaticMember,
    [name],
  );
}

LocatableDiagnostic
_withArgumentsUnqualifiedReferenceToStaticMemberOfExtendedType({
  required String name,
}) {
  return LocatableDiagnosticImpl(
    diag.unqualifiedReferenceToStaticMemberOfExtendedType,
    [name],
  );
}

LocatableDiagnostic _withArgumentsUnrecognizedErrorCode({
  required String codeName,
}) {
  return LocatableDiagnosticImpl(diag.unrecognizedErrorCode, [codeName]);
}

LocatableDiagnostic _withArgumentsUnsupportedChromeOsFeature({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedChromeOsFeature, [name]);
}

LocatableDiagnostic _withArgumentsUnsupportedChromeOsHardware({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedChromeOsHardware, [name]);
}

LocatableDiagnostic _withArgumentsUnsupportedOperator({
  required String lexeme,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOperator, [lexeme]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValue({
  required String sectionName,
  required String optionKey,
  required String legalValue,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithLegalValue, [
    sectionName,
    optionKey,
    legalValue,
  ]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithLegalValues({
  required String sectionName,
  required String optionKey,
  required String legalValues,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithLegalValues, [
    sectionName,
    optionKey,
    legalValues,
  ]);
}

LocatableDiagnostic _withArgumentsUnsupportedOptionWithoutValues({
  required String sectionName,
  required String optionKey,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedOptionWithoutValues, [
    sectionName,
    optionKey,
  ]);
}

LocatableDiagnostic _withArgumentsUnsupportedValue({
  required String optionName,
  required Object invalidValue,
  required String legalValues,
}) {
  return LocatableDiagnosticImpl(diag.unsupportedValue, [
    optionName,
    invalidValue,
    legalValues,
  ]);
}

LocatableDiagnostic _withArgumentsUnusedCatchClause({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedCatchClause, [name]);
}

LocatableDiagnostic _withArgumentsUnusedCatchStack({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedCatchStack, [name]);
}

LocatableDiagnostic _withArgumentsUnusedElement({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedElement, [name]);
}

LocatableDiagnostic _withArgumentsUnusedElementParameter({
  required String name,
}) {
  return LocatableDiagnosticImpl(diag.unusedElementParameter, [name]);
}

LocatableDiagnostic _withArgumentsUnusedField({required String fieldName}) {
  return LocatableDiagnosticImpl(diag.unusedField, [fieldName]);
}

LocatableDiagnostic _withArgumentsUnusedFieldFromPrimaryConstructor({
  required String fieldName,
  required String keyword,
}) {
  return LocatableDiagnosticImpl(diag.unusedFieldFromPrimaryConstructor, [
    fieldName,
    keyword,
  ]);
}

LocatableDiagnostic _withArgumentsUnusedImport({required String uriStr}) {
  return LocatableDiagnosticImpl(diag.unusedImport, [uriStr]);
}

LocatableDiagnostic _withArgumentsUnusedLabel({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedLabel, [name]);
}

LocatableDiagnostic _withArgumentsUnusedLocalVariable({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedLocalVariable, [name]);
}

LocatableDiagnostic _withArgumentsUnusedResult({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedResult, [name]);
}

LocatableDiagnostic _withArgumentsUnusedResultWithMessage({
  required String name,
  required String message,
}) {
  return LocatableDiagnosticImpl(diag.unusedResultWithMessage, [name, message]);
}

LocatableDiagnostic _withArgumentsUnusedShownName({required String name}) {
  return LocatableDiagnosticImpl(diag.unusedShownName, [name]);
}

LocatableDiagnostic _withArgumentsUriDoesNotExist({required String uriStr}) {
  return LocatableDiagnosticImpl(diag.uriDoesNotExist, [uriStr]);
}

LocatableDiagnostic _withArgumentsUriDoesNotExistInDocImport({
  required String uriStr,
}) {
  return LocatableDiagnosticImpl(diag.uriDoesNotExistInDocImport, [uriStr]);
}

LocatableDiagnostic _withArgumentsUriHasNotBeenGenerated({
  required String uriStr,
}) {
  return LocatableDiagnosticImpl(diag.uriHasNotBeenGenerated, [uriStr]);
}

LocatableDiagnostic _withArgumentsVariableTypeMismatch({
  required String valueType,
  required String variableType,
}) {
  return LocatableDiagnosticImpl(diag.variableTypeMismatch, [
    valueType,
    variableType,
  ]);
}

LocatableDiagnostic _withArgumentsWorkspaceValueNotSubdirectory({
  required String path,
}) {
  return LocatableDiagnosticImpl(diag.workspaceValueNotSubdirectory, [path]);
}

LocatableDiagnostic
_withArgumentsWrongExplicitTypeParameterVarianceInSuperinterface({
  required String typeParameterName,
  required String varianceModifier,
  required String variancePosition,
  required DartType superInterface,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongExplicitTypeParameterVarianceInSuperinterface,
    [typeParameterName, varianceModifier, variancePosition, superInterface],
  );
}

LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperator({
  required String name,
  required int expectedCount,
  required int actualCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfParametersForOperator, [
    name,
    expectedCount,
    actualCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfParametersForOperatorMinus({
  required int actualCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfParametersForOperatorMinus, [
    actualCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArguments({
  required String type,
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArguments, [
    type,
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsConstructor({
  required String className,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsConstructor, [
    className,
    constructorName,
  ]);
}

LocatableDiagnostic
_withArgumentsWrongNumberOfTypeArgumentsDotShorthandConstructor({
  required String className,
  required String constructorName,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongNumberOfTypeArgumentsDotShorthandConstructor,
    [className, constructorName],
  );
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsElement({
  required String kind,
  required String element,
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsElement, [
    kind,
    element,
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsEnum({
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsEnum, [
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsExtension({
  required String extensionName,
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsExtension, [
    extensionName,
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongNumberOfTypeArgumentsFunction({
  required DartType type,
  required int typeParameterCount,
  required int typeArgumentCount,
}) {
  return LocatableDiagnosticImpl(diag.wrongNumberOfTypeArgumentsFunction, [
    type,
    typeParameterCount,
    typeArgumentCount,
  ]);
}

LocatableDiagnostic _withArgumentsWrongTypeParameterVarianceInSuperinterface({
  required String typeParameterName,
  required DartType superInterfaceType,
}) {
  return LocatableDiagnosticImpl(
    diag.wrongTypeParameterVarianceInSuperinterface,
    [typeParameterName, superInterfaceType],
  );
}

LocatableDiagnostic _withArgumentsWrongTypeParameterVariancePosition({
  required String modifier,
  required String typeParameterName,
  required String variancePosition,
}) {
  return LocatableDiagnosticImpl(diag.wrongTypeParameterVariancePosition, [
    modifier,
    typeParameterName,
    variancePosition,
  ]);
}

LocatableDiagnostic _withArgumentsYieldEachOfInvalidType({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.yieldEachOfInvalidType, [
    actualType,
    expectedType,
  ]);
}

LocatableDiagnostic _withArgumentsYieldOfInvalidType({
  required DartType actualType,
  required DartType expectedType,
}) {
  return LocatableDiagnosticImpl(diag.yieldOfInvalidType, [
    actualType,
    expectedType,
  ]);
}
