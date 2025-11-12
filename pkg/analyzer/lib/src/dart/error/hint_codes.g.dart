// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/hint_codes.dart";

class HintCode {
  /// Note: Since this diagnostic is only produced in pre-3.0 code, we do not
  /// plan to go through the exercise of converting it to a Warning.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments deprecatedColonForDefaultValue =
      diag.deprecatedColonForDefaultValue;

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedMemberUse = diag.deprecatedMemberUse;

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: message details
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  deprecatedMemberUseWithMessage = diag.deprecatedMemberUseWithMessage;

  /// No parameters.
  static const DiagnosticWithoutArguments
  importDeferredLibraryWithLoadFunction =
      diag.importDeferredLibraryWithLoadFunction;

  /// Parameters:
  /// String p0: the URI that is not necessary
  /// String p1: the URI that makes it unnecessary
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  unnecessaryImport = diag.unnecessaryImport;

  /// Do not construct instances of this class.
  HintCode._() : assert(false);
}
