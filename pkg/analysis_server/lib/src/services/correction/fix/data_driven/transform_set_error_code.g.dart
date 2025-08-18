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
class TransformSetErrorCode extends DiagnosticCode {
  /// Parameters:
  /// Object p0: the conflicting key
  /// Object p1: the key that it conflicts with
  static const TransformSetErrorCode conflictingKey = TransformSetErrorCode(
    'conflicting_key',
    "The key '{0}' can't be used when '{1}' is also used.",
  );

  /// No parameters.
  static const TransformSetErrorCode expectedPrimary = TransformSetErrorCode(
    'expected_primary',
    "Expected either an identifier or a string literal.",
  );

  /// Parameters:
  /// Object p0: the old kind
  /// Object p1: the new kind
  static const TransformSetErrorCode
  incompatibleElementKind = TransformSetErrorCode(
    'incompatible_element_kind',
    "An element of kind '{0}' can't be replaced by an element of kind '{1}'.",
  );

  /// Parameters:
  /// Object p0: the change kind that is invalid
  /// Object p1: the element kind for the transform
  static const TransformSetErrorCode invalidChangeForKind =
      TransformSetErrorCode(
        'invalid_change_for_kind',
        "A change of type '{0}' can't be used for an element of kind '{1}'.",
      );

  /// Parameters:
  /// Object p0: the character that is invalid
  static const TransformSetErrorCode invalidCharacter = TransformSetErrorCode(
    'invalid_character',
    "Invalid character '{0}'.",
  );

  /// Parameters:
  /// Object p0: the actual type of the key
  static const TransformSetErrorCode invalidKey = TransformSetErrorCode(
    'invalid_key',
    "Keys must be of type 'String' but found the type '{0}'.",
  );

  /// Parameters:
  /// Object p0: the list of valid parameter styles
  static const TransformSetErrorCode invalidParameterStyle =
      TransformSetErrorCode(
        'invalid_parameter_style',
        "The parameter style must be one of the following: {0}.",
      );

  /// No parameters.
  static const TransformSetErrorCode invalidRequiredIf = TransformSetErrorCode(
    'invalid_required_if',
    "The key 'requiredIf' can only be used with optional named parameters.",
  );

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the expected type of the value
  /// Object p2: the actual type of the value
  static const TransformSetErrorCode invalidValue = TransformSetErrorCode(
    'invalid_value',
    "The value of '{0}' should be of type '{1}' but is of type '{2}'.",
  );

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the allowed values as a comma-separated list
  static const TransformSetErrorCode invalidValueOneOf = TransformSetErrorCode(
    'invalid_value_one_of',
    "The value of '{0}' must be one of the following: '{1}'.",
  );

  /// Parameters:
  /// Object p0: the missing key
  static const TransformSetErrorCode missingKey = TransformSetErrorCode(
    'missing_key',
    "Missing the required key '{0}'.",
  );

  /// Parameters:
  /// Object p0: the list of valid keys
  static const TransformSetErrorCode missingOneOfMultipleKeys =
      TransformSetErrorCode(
        'missing_one_of_multiple_keys',
        "Exactly one of the following keys must be provided: {0}.",
      );

  /// No parameters.
  static const TransformSetErrorCode missingTemplateEnd = TransformSetErrorCode(
    'missing_template_end',
    "Missing the end brace for the template.",
  );

  /// Parameters:
  /// Object p0: a description of the expected kinds of tokens
  static const TransformSetErrorCode missingToken = TransformSetErrorCode(
    'missing_token',
    "Expected to find {0}.",
  );

  /// No parameters.
  static const TransformSetErrorCode missingUri = TransformSetErrorCode(
    'missing_uri',
    "At least one URI must be provided.",
  );

  /// Parameters:
  /// Object p0: the missing key
  static const TransformSetErrorCode undefinedVariable = TransformSetErrorCode(
    'undefined_variable',
    "The variable '{0}' isn't defined.",
  );

  /// Parameters:
  /// Object p0: the token that was unexpectedly found
  static const TransformSetErrorCode unexpectedToken = TransformSetErrorCode(
    'unexpected_token',
    "Didn't expect to find {0}.",
  );

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  static const TransformSetErrorCode unknownAccessor = TransformSetErrorCode(
    'unknown_accessor',
    "The accessor '{0}' is invalid.",
  );

  /// Parameters:
  /// Object p0: the unsupported key
  static const TransformSetErrorCode unsupportedKey = TransformSetErrorCode(
    'unsupported_key',
    "The key '{0}' isn't supported.",
  );

  /// No parameters.
  static const TransformSetErrorCode unsupportedStatic = TransformSetErrorCode(
    'unsupported_static',
    "The key 'static' is only supported for elements in a class, enum, "
        "extension, or mixin.",
  );

  /// No parameters.
  static const TransformSetErrorCode unsupportedVersion = TransformSetErrorCode(
    'unsupported_version',
    "Only version '1' is supported at this time.",
  );

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  /// Object p1: a description of the actual kind of token
  static const TransformSetErrorCode wrongToken = TransformSetErrorCode(
    'wrong_token',
    "Expected to find {0}, but found {1}.",
  );

  /// Parameters:
  /// Object p0: the message produced by the YAML parser
  static const TransformSetErrorCode yamlSyntaxError = TransformSetErrorCode(
    'yaml_syntax_error',
    "Parse error: {0}",
  );

  /// Initialize a newly created error code to have the given [name].
  const TransformSetErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'TransformSetErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.ERROR;

  @override
  DiagnosticType get type => DiagnosticType.COMPILE_TIME_ERROR;
}
