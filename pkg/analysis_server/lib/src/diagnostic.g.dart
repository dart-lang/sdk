// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Code generation is easier using double quotes (since we can use json.convert
// to quote strings).
// ignore_for_file: prefer_single_quotes

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analysis_server/src/diagnostic.dart";

/// Parameters:
/// String key: the conflicting key
/// String conflictingKey: the key that it conflicts with
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String key,
    required String conflictingKey,
  })
>
conflictingKey = DiagnosticWithArguments(
  name: 'conflicting_key',
  problemMessage: "The key '{0}' can't be used when '{1}' is also used.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'conflicting_key',
  withArguments: _withArgumentsConflictingKey,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments expectedPrimary =
    DiagnosticWithoutArgumentsImpl(
      name: 'expected_primary',
      problemMessage: "Expected either an identifier or a string literal.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'expected_primary',
      expectedTypes: [],
    );

/// Parameters:
/// String oldKind: the old kind
/// String newKind: the new kind
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String oldKind,
    required String newKind,
  })
>
incompatibleElementKind = DiagnosticWithArguments(
  name: 'incompatible_element_kind',
  problemMessage:
      "An element of kind '{0}' can't be replaced by an element of kind '{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'incompatible_element_kind',
  withArguments: _withArgumentsIncompatibleElementKind,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String changeKind: the change kind that is invalid
/// String elementKind: the element kind for the transform
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String changeKind,
    required String elementKind,
  })
>
invalidChangeForKind = DiagnosticWithArguments(
  name: 'invalid_change_for_kind',
  problemMessage:
      "A change of type '{0}' can't be used for an element of kind '{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_change_for_kind',
  withArguments: _withArgumentsInvalidChangeForKind,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String text: the character that is invalid
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String text})
>
invalidCharacter = DiagnosticWithArguments(
  name: 'invalid_character',
  problemMessage: "Invalid character '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_character',
  withArguments: _withArgumentsInvalidCharacter,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String keyType: the actual type of the key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String keyType})
>
invalidKey = DiagnosticWithArguments(
  name: 'invalid_key',
  problemMessage: "Keys must be of type 'String' but found the type '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_key',
  withArguments: _withArgumentsInvalidKey,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String validStyles: the list of valid parameter styles
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String validStyles})
>
invalidParameterStyle = DiagnosticWithArguments(
  name: 'invalid_parameter_style',
  problemMessage: "The parameter style must be one of the following: {0}.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_parameter_style',
  withArguments: _withArgumentsInvalidParameterStyle,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments
invalidRequiredIf = DiagnosticWithoutArgumentsImpl(
  name: 'invalid_required_if',
  problemMessage:
      "The key 'requiredIf' can only be used with optional named parameters.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_required_if',
  expectedTypes: [],
);

/// Parameters:
/// String key: the key with which the value is associated
/// String expectedType: the expected type of the value
/// String actualType: the actual type of the value
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String key,
    required String expectedType,
    required String actualType,
  })
>
invalidValue = DiagnosticWithArguments(
  name: 'invalid_value',
  problemMessage:
      "The value of '{0}' should be of type '{1}' but is of type '{2}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_value',
  withArguments: _withArgumentsInvalidValue,
  expectedTypes: [
    ExpectedType.string,
    ExpectedType.string,
    ExpectedType.string,
  ],
);

/// Parameters:
/// String key: the key with which the value is associated
/// String allowedValues: the allowed values as a comma-separated list
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String key,
    required String allowedValues,
  })
>
invalidValueOneOf = DiagnosticWithArguments(
  name: 'invalid_value_one_of',
  problemMessage: "The value of '{0}' must be one of the following: '{1}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'invalid_value_one_of',
  withArguments: _withArgumentsInvalidValueOneOf,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String key: the missing key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String key})
>
missingKey = DiagnosticWithArguments(
  name: 'missing_key',
  problemMessage: "Missing the required key '{0}'.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_key',
  withArguments: _withArgumentsMissingKey,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String validKeys: the list of valid keys
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String validKeys})
>
missingOneOfMultipleKeys = DiagnosticWithArguments(
  name: 'missing_one_of_multiple_keys',
  problemMessage: "Exactly one of the following keys must be provided: {0}.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_one_of_multiple_keys',
  withArguments: _withArgumentsMissingOneOfMultipleKeys,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingTemplateEnd =
    DiagnosticWithoutArgumentsImpl(
      name: 'missing_template_end',
      problemMessage: "Missing the end brace for the template.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'missing_template_end',
      expectedTypes: [],
    );

/// Parameters:
/// String validKinds: a description of the expected kinds of tokens
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String validKinds})
>
missingToken = DiagnosticWithArguments(
  name: 'missing_token',
  problemMessage: "Expected to find {0}.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_token',
  withArguments: _withArgumentsMissingToken,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments missingUri = DiagnosticWithoutArgumentsImpl(
  name: 'missing_uri',
  problemMessage: "At least one URI must be provided.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'missing_uri',
  expectedTypes: [],
);

/// Parameters:
/// String key: the missing key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String key})
>
undefinedVariable = DiagnosticWithArguments(
  name: 'undefined_variable',
  problemMessage: "The variable '{0}' isn't defined.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'undefined_variable',
  withArguments: _withArgumentsUndefinedVariable,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String tokenKind: the token that was unexpectedly found
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String tokenKind})
>
unexpectedTransformSetToken = DiagnosticWithArguments(
  name: 'unexpected_transform_set_token',
  problemMessage: "Didn't expect to find {0}.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unexpected_transform_set_token',
  withArguments: _withArgumentsUnexpectedTransformSetToken,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String accessor: a description of the expected kind of token
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String accessor})
>
unknownAccessor = DiagnosticWithArguments(
  name: 'unknown_accessor',
  problemMessage: "The accessor '{0}' is invalid.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unknown_accessor',
  withArguments: _withArgumentsUnknownAccessor,
  expectedTypes: [ExpectedType.string],
);

/// Parameters:
/// String key: the unsupported key
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String key})
>
unsupportedKey = DiagnosticWithArguments(
  name: 'unsupported_key',
  problemMessage: "The key '{0}' isn't supported.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'unsupported_key',
  withArguments: _withArgumentsUnsupportedKey,
  expectedTypes: [ExpectedType.string],
);

/// No parameters.
const DiagnosticWithoutArguments unsupportedStatic =
    DiagnosticWithoutArgumentsImpl(
      name: 'unsupported_static',
      problemMessage:
          "The key 'static' is only supported for elements in a class, enum, "
          "extension, or mixin.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'unsupported_static',
      expectedTypes: [],
    );

/// No parameters.
const DiagnosticWithoutArguments unsupportedVersion =
    DiagnosticWithoutArgumentsImpl(
      name: 'unsupported_version',
      problemMessage: "Only version '1' is supported at this time.",
      type: DiagnosticType.COMPILE_TIME_ERROR,
      uniqueName: 'unsupported_version',
      expectedTypes: [],
    );

/// Parameters:
/// String validKinds: a description of the expected kind of token
/// String actualKind: a description of the actual kind of token
const DiagnosticWithArguments<
  LocatableDiagnostic Function({
    required String validKinds,
    required String actualKind,
  })
>
wrongToken = DiagnosticWithArguments(
  name: 'wrong_token',
  problemMessage: "Expected to find {0}, but found {1}.",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'wrong_token',
  withArguments: _withArgumentsWrongToken,
  expectedTypes: [ExpectedType.string, ExpectedType.string],
);

/// Parameters:
/// String message: the message produced by the YAML parser
const DiagnosticWithArguments<
  LocatableDiagnostic Function({required String message})
>
yamlSyntaxError = DiagnosticWithArguments(
  name: 'yaml_syntax_error',
  problemMessage: "Parse error: {0}",
  type: DiagnosticType.COMPILE_TIME_ERROR,
  uniqueName: 'yaml_syntax_error',
  withArguments: _withArgumentsYamlSyntaxError,
  expectedTypes: [ExpectedType.string],
);

LocatableDiagnostic _withArgumentsConflictingKey({
  required String key,
  required String conflictingKey,
}) {
  return LocatableDiagnosticImpl(diag.conflictingKey, [key, conflictingKey]);
}

LocatableDiagnostic _withArgumentsIncompatibleElementKind({
  required String oldKind,
  required String newKind,
}) {
  return LocatableDiagnosticImpl(diag.incompatibleElementKind, [
    oldKind,
    newKind,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidChangeForKind({
  required String changeKind,
  required String elementKind,
}) {
  return LocatableDiagnosticImpl(diag.invalidChangeForKind, [
    changeKind,
    elementKind,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidCharacter({required String text}) {
  return LocatableDiagnosticImpl(diag.invalidCharacter, [text]);
}

LocatableDiagnostic _withArgumentsInvalidKey({required String keyType}) {
  return LocatableDiagnosticImpl(diag.invalidKey, [keyType]);
}

LocatableDiagnostic _withArgumentsInvalidParameterStyle({
  required String validStyles,
}) {
  return LocatableDiagnosticImpl(diag.invalidParameterStyle, [validStyles]);
}

LocatableDiagnostic _withArgumentsInvalidValue({
  required String key,
  required String expectedType,
  required String actualType,
}) {
  return LocatableDiagnosticImpl(diag.invalidValue, [
    key,
    expectedType,
    actualType,
  ]);
}

LocatableDiagnostic _withArgumentsInvalidValueOneOf({
  required String key,
  required String allowedValues,
}) {
  return LocatableDiagnosticImpl(diag.invalidValueOneOf, [key, allowedValues]);
}

LocatableDiagnostic _withArgumentsMissingKey({required String key}) {
  return LocatableDiagnosticImpl(diag.missingKey, [key]);
}

LocatableDiagnostic _withArgumentsMissingOneOfMultipleKeys({
  required String validKeys,
}) {
  return LocatableDiagnosticImpl(diag.missingOneOfMultipleKeys, [validKeys]);
}

LocatableDiagnostic _withArgumentsMissingToken({required String validKinds}) {
  return LocatableDiagnosticImpl(diag.missingToken, [validKinds]);
}

LocatableDiagnostic _withArgumentsUndefinedVariable({required String key}) {
  return LocatableDiagnosticImpl(diag.undefinedVariable, [key]);
}

LocatableDiagnostic _withArgumentsUnexpectedTransformSetToken({
  required String tokenKind,
}) {
  return LocatableDiagnosticImpl(diag.unexpectedTransformSetToken, [tokenKind]);
}

LocatableDiagnostic _withArgumentsUnknownAccessor({required String accessor}) {
  return LocatableDiagnosticImpl(diag.unknownAccessor, [accessor]);
}

LocatableDiagnostic _withArgumentsUnsupportedKey({required String key}) {
  return LocatableDiagnosticImpl(diag.unsupportedKey, [key]);
}

LocatableDiagnostic _withArgumentsWrongToken({
  required String validKinds,
  required String actualKind,
}) {
  return LocatableDiagnosticImpl(diag.wrongToken, [validKinds, actualKind]);
}

LocatableDiagnostic _withArgumentsYamlSyntaxError({required String message}) {
  return LocatableDiagnosticImpl(diag.yamlSyntaxError, [message]);
}
