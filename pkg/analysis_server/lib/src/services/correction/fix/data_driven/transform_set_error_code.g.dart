// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
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

part of "package:analysis_server/src/services/correction/fix/data_driven/transform_set_error_code.dart";

/// An error code representing a problem in a file containing an encoding of a
/// transform set.
class TransformSetErrorCode {
  /// Parameters:
  /// Object p0: the conflicting key
  /// Object p1: the key that it conflicts with
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  conflictingKey = diag.conflictingKey;

  /// No parameters.
  static const DiagnosticWithoutArguments expectedPrimary =
      diag.expectedPrimary;

  /// Parameters:
  /// Object p0: the old kind
  /// Object p1: the new kind
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  incompatibleElementKind = diag.incompatibleElementKind;

  /// Parameters:
  /// Object p0: the change kind that is invalid
  /// Object p1: the element kind for the transform
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidChangeForKind = diag.invalidChangeForKind;

  /// Parameters:
  /// Object p0: the character that is invalid
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidCharacter = diag.invalidCharacter;

  /// Parameters:
  /// Object p0: the actual type of the key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidKey = diag.invalidKey;

  /// Parameters:
  /// Object p0: the list of valid parameter styles
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  invalidParameterStyle = diag.invalidParameterStyle;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidRequiredIf =
      diag.invalidRequiredIf;

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the expected type of the value
  /// Object p2: the actual type of the value
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({
      required Object p0,
      required Object p1,
      required Object p2,
    })
  >
  invalidValue = diag.invalidValue;

  /// Parameters:
  /// Object p0: the key with which the value is associated
  /// Object p1: the allowed values as a comma-separated list
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  invalidValueOneOf = diag.invalidValueOneOf;

  /// Parameters:
  /// Object p0: the missing key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingKey = diag.missingKey;

  /// Parameters:
  /// Object p0: the list of valid keys
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingOneOfMultipleKeys = diag.missingOneOfMultipleKeys;

  /// No parameters.
  static const DiagnosticWithoutArguments missingTemplateEnd =
      diag.missingTemplateEnd;

  /// Parameters:
  /// Object p0: a description of the expected kinds of tokens
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  missingToken = diag.missingToken;

  /// No parameters.
  static const DiagnosticWithoutArguments missingUri = diag.missingUri;

  /// Parameters:
  /// Object p0: the missing key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  undefinedVariable = diag.undefinedVariable;

  /// Parameters:
  /// Object p0: the token that was unexpectedly found
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unexpectedTransformSetToken = diag.unexpectedTransformSetToken;

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unknownAccessor = diag.unknownAccessor;

  /// Parameters:
  /// Object p0: the unsupported key
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unsupportedKey = diag.unsupportedKey;

  /// No parameters.
  static const DiagnosticWithoutArguments unsupportedStatic =
      diag.unsupportedStatic;

  /// No parameters.
  static const DiagnosticWithoutArguments unsupportedVersion =
      diag.unsupportedVersion;

  /// Parameters:
  /// Object p0: a description of the expected kind of token
  /// Object p1: a description of the actual kind of token
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  wrongToken = diag.wrongToken;

  /// Parameters:
  /// Object p0: the message produced by the YAML parser
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  yamlSyntaxError = diag.yamlSyntaxError;

  /// Do not construct instances of this class.
  TransformSetErrorCode._() : assert(false);
}
