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
class TodoCode extends DiagnosticCodeWithExpectedTypes {
  /// A TODO comment marked as FIXME.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String message})
  >
  fixme = TodoTemplate(
    name: 'FIXME',
    problemMessage: "{0}",
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
  hack = TodoTemplate(
    name: 'HACK',
    problemMessage: "{0}",
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
  todo = TodoTemplate(
    name: 'TODO',
    problemMessage: "{0}",
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
  undone = TodoTemplate(
    name: 'UNDONE',
    problemMessage: "{0}",
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

final class TodoTemplate<T extends Function> extends TodoCode
    implements DiagnosticWithArguments<T> {
  @override
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const TodoTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class TodoWithoutArguments extends TodoCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const TodoWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  });
}
