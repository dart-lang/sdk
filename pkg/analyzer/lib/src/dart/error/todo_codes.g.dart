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
class TodoCode extends DiagnosticCodeWithExpectedTypes {
  /// A TODO comment marked as FIXME.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
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

  /// A TODO comment marked as HACK.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
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

  /// A standard TODO comment marked as TODO.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
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

  /// A TODO comment marked as UNDONE.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
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

  /// Initialize a newly created error code to have the given [name].
  const TodoCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  }) : super(type: DiagnosticType.TODO);

  static LocatableDiagnostic _withArgumentsFixme({required String message}) {
    return LocatableDiagnosticImpl(TodoCode.fixme, [message]);
  }

  static LocatableDiagnostic _withArgumentsHack({required String message}) {
    return LocatableDiagnosticImpl(TodoCode.hack, [message]);
  }

  static LocatableDiagnostic _withArgumentsTodo({required String message}) {
    return LocatableDiagnosticImpl(TodoCode.todo, [message]);
  }

  static LocatableDiagnostic _withArgumentsUndone({required String message}) {
    return LocatableDiagnosticImpl(TodoCode.undone, [message]);
  }
}
