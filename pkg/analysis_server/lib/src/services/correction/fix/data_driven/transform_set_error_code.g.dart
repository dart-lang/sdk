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
// ignore_for_file: prefer_single_quotes
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart";

/// An error code representing a problem in a file containing an encoding of a
/// transform set.
class TransformSetErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// Parameters:
  /// Object p0: the conflicting key
  /// Object p1: the key that it conflicts with
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  conflictingKey = TransformSetErrorTemplate(
    name: 'conflicting_key',
    problemMessage: "The key '{0}' can't be used when '{1}' is also used.",
    withArguments: _withArgumentsConflictingKey,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// No parameters.
  static const TransformSetErrorWithoutArguments expectedPrimary =
      TransformSetErrorWithoutArguments(
        name: 'expected_primary',
        problemMessage: "Expected either an identifier or a string literal.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the old kind
  /// Object p1: the new kind
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  incompatibleElementKind = TransformSetErrorTemplate(
    name: 'incompatible_element_kind',
    problemMessage:
        "An element of kind '{0}' can't be replaced by an element of kind '{1}'.",
    withArguments: _withArgumentsIncompatibleElementKind,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the change kind that is invalid
  /// Object p1: the element kind for the transform
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidChangeForKind = TransformSetErrorTemplate(
    name: 'invalid_change_for_kind',
    problemMessage:
        "A change of type '{0}' can't be used for an element of kind '{1}'.",
    withArguments: _withArgumentsInvalidChangeForKind,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the character that is invalid
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidCharacter = TransformSetErrorTemplate(
    name: 'invalid_character',
    problemMessage: "Invalid character '{0}'.",
    withArguments: _withArgumentsInvalidCharacter,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the actual type of the key
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidKey = TransformSetErrorTemplate(
    name: 'invalid_key',
    problemMessage: "Keys must be of type 'String' but found the type '{0}'.",
    withArguments: _withArgumentsInvalidKey,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the list of valid parameter styles
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidParameterStyle = TransformSetErrorTemplate(
    name: 'invalid_parameter_style',
    problemMessage: "The parameter style must be one of the following: {0}.",
    withArguments: _withArgumentsInvalidParameterStyle,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const TransformSetErrorWithoutArguments
  invalidRequiredIf = TransformSetErrorWithoutArguments(
    name: 'invalid_required_if',
    problemMessage:
        "The key 'requiredIf' can only be used with optional named parameters.",
    expectedTypes: [],
  );

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the expected type of the value
  /// Object p2: the actual type of the value
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidValue = TransformSetErrorTemplate(
    name: 'invalid_value',
    problemMessage:
        "The value of '{0}' should be of type '{1}' but is of type '{2}'.",
    withArguments: _withArgumentsInvalidValue,
    expectedTypes: [
      ExpectedType.object,
      ExpectedType.object,
      ExpectedType.object,
    ],
  );

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the allowed values as a comma-separated list
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidValueOneOf = TransformSetErrorTemplate(
    name: 'invalid_value_one_of',
    problemMessage: "The value of '{0}' must be one of the following: '{1}'.",
    withArguments: _withArgumentsInvalidValueOneOf,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the missing key
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingKey = TransformSetErrorTemplate(
    name: 'missing_key',
    problemMessage: "Missing the required key '{0}'.",
    withArguments: _withArgumentsMissingKey,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the list of valid keys
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingOneOfMultipleKeys = TransformSetErrorTemplate(
    name: 'missing_one_of_multiple_keys',
    problemMessage: "Exactly one of the following keys must be provided: {0}.",
    withArguments: _withArgumentsMissingOneOfMultipleKeys,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const TransformSetErrorWithoutArguments missingTemplateEnd =
      TransformSetErrorWithoutArguments(
        name: 'missing_template_end',
        problemMessage: "Missing the end brace for the template.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: a description of the expected kinds of tokens
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  missingToken = TransformSetErrorTemplate(
    name: 'missing_token',
    problemMessage: "Expected to find {0}.",
    withArguments: _withArgumentsMissingToken,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const TransformSetErrorWithoutArguments missingUri =
      TransformSetErrorWithoutArguments(
        name: 'missing_uri',
        problemMessage: "At least one URI must be provided.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the missing key
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  undefinedVariable = TransformSetErrorTemplate(
    name: 'undefined_variable',
    problemMessage: "The variable '{0}' isn't defined.",
    withArguments: _withArgumentsUndefinedVariable,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the token that was unexpectedly found
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unexpectedTransformSetToken = TransformSetErrorTemplate(
    name: 'unexpected_transform_set_token',
    problemMessage: "Didn't expect to find {0}.",
    withArguments: _withArgumentsUnexpectedTransformSetToken,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unknownAccessor = TransformSetErrorTemplate(
    name: 'unknown_accessor',
    problemMessage: "The accessor '{0}' is invalid.",
    withArguments: _withArgumentsUnknownAccessor,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the unsupported key
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unsupportedKey = TransformSetErrorTemplate(
    name: 'unsupported_key',
    problemMessage: "The key '{0}' isn't supported.",
    withArguments: _withArgumentsUnsupportedKey,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const TransformSetErrorWithoutArguments unsupportedStatic =
      TransformSetErrorWithoutArguments(
        name: 'unsupported_static',
        problemMessage:
            "The key 'static' is only supported for elements in a class, enum, "
            "extension, or mixin.",
        expectedTypes: [],
      );

  /// No parameters.
  static const TransformSetErrorWithoutArguments unsupportedVersion =
      TransformSetErrorWithoutArguments(
        name: 'unsupported_version',
        problemMessage: "Only version '1' is supported at this time.",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  /// Object p1: a description of the actual kind of token
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  wrongToken = TransformSetErrorTemplate(
    name: 'wrong_token',
    problemMessage: "Expected to find {0}, but found {1}.",
    withArguments: _withArgumentsWrongToken,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// Object p0: the message produced by the YAML parser
  static const TransformSetErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  yamlSyntaxError = TransformSetErrorTemplate(
    name: 'yaml_syntax_error',
    problemMessage: "Parse error: {0}",
    withArguments: _withArgumentsYamlSyntaxError,
    expectedTypes: [ExpectedType.object],
  );

  /// Initialize a newly created error code to have the given [name].
  const TransformSetErrorCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         type: DiagnosticType.COMPILE_TIME_ERROR,
         uniqueName: 'TransformSetErrorCode.${uniqueName ?? name}',
       );

  static LocatableDiagnostic _withArgumentsConflictingKey({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.conflictingKey, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsIncompatibleElementKind({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      TransformSetErrorCode.incompatibleElementKind,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidChangeForKind({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.invalidChangeForKind, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidCharacter({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.invalidCharacter, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidKey({required Object p0}) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.invalidKey, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidParameterStyle({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      TransformSetErrorCode.invalidParameterStyle,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsInvalidValue({
    required Object p0,
    required Object p1,
    required Object p2,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.invalidValue, [
      p0,
      p1,
      p2,
    ]);
  }

  static LocatableDiagnostic _withArgumentsInvalidValueOneOf({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.invalidValueOneOf, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsMissingKey({required Object p0}) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.missingKey, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingOneOfMultipleKeys({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      TransformSetErrorCode.missingOneOfMultipleKeys,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsMissingToken({required Object p0}) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.missingToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUndefinedVariable({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.undefinedVariable, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnexpectedTransformSetToken({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(
      TransformSetErrorCode.unexpectedTransformSetToken,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsUnknownAccessor({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.unknownAccessor, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedKey({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.unsupportedKey, [p0]);
  }

  static LocatableDiagnostic _withArgumentsWrongToken({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.wrongToken, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsYamlSyntaxError({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(TransformSetErrorCode.yamlSyntaxError, [p0]);
  }
}

final class TransformSetErrorTemplate<T extends Function>
    extends TransformSetErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const TransformSetErrorTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class TransformSetErrorWithoutArguments extends TransformSetErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const TransformSetErrorWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
