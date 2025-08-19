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

part of "package:analyzer/src/dart/error/todo_codes.dart";

/// The error code indicating a marker in code for work that needs to be finished
/// or revisited.
class TodoCode extends DiagnosticCode {
  /// A TODO comment marked as FIXME.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoCode fixme = TodoCode('FIXME', "{0}");

  /// A TODO comment marked as HACK.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoCode hack = TodoCode('HACK', "{0}");

  /// A standard TODO comment marked as TODO.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoCode todo = TodoCode('TODO', "{0}");

  /// A TODO comment marked as UNDONE.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoCode undone = TodoCode('UNDONE', "{0}");

  /// Initialize a newly created error code to have the given [name].
  const TodoCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'TodoCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.INFO;

  @override
  DiagnosticType get type => DiagnosticType.TODO;
}
