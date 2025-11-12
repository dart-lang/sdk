// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/dart/error/todo_codes.dart";

/// The error code indicating a marker in code for work that needs to be finished
/// or revisited.
class TodoCode {
  /// A TODO comment marked as FIXME.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String message})
  >
  fixme = diag.fixme;

  /// A TODO comment marked as HACK.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String message})
  >
  hack = diag.hack;

  /// A standard TODO comment marked as TODO.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String message})
  >
  todo = diag.todo;

  /// A TODO comment marked as UNDONE.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String message})
  >
  undone = diag.undone;

  /// Do not construct instances of this class.
  TodoCode._() : assert(false);
}
