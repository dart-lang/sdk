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
  static const TodoTemplate<
    LocatableDiagnostic Function({required String message})
  >
  fixme = TodoTemplate(
    'FIXME',
    "{0}",
    withArguments: _withArgumentsFixme,
    expectedTypes: [ExpectedType.string],
  );

  /// A TODO comment marked as HACK.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoTemplate<
    LocatableDiagnostic Function({required String message})
  >
  hack = TodoTemplate(
    'HACK',
    "{0}",
    withArguments: _withArgumentsHack,
    expectedTypes: [ExpectedType.string],
  );

  /// A standard TODO comment marked as TODO.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoTemplate<
    LocatableDiagnostic Function({required String message})
  >
  todo = TodoTemplate(
    'TODO',
    "{0}",
    withArguments: _withArgumentsTodo,
    expectedTypes: [ExpectedType.string],
  );

  /// A TODO comment marked as UNDONE.
  ///
  /// Parameters:
  /// String message: the user-supplied problem message
  static const TodoTemplate<
    LocatableDiagnostic Function({required String message})
  >
  undone = TodoTemplate(
    'UNDONE',
    "{0}",
    withArguments: _withArgumentsUndone,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const TodoCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'TodoCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.INFO;

  @override
  DiagnosticType get type => DiagnosticType.TODO;

  static LocatableDiagnostic _withArgumentsFixme({required String message}) {
    return LocatableDiagnosticImpl(fixme, [message]);
  }

  static LocatableDiagnostic _withArgumentsHack({required String message}) {
    return LocatableDiagnosticImpl(hack, [message]);
  }

  static LocatableDiagnostic _withArgumentsTodo({required String message}) {
    return LocatableDiagnosticImpl(todo, [message]);
  }

  static LocatableDiagnostic _withArgumentsUndone({required String message}) {
    return LocatableDiagnosticImpl(undone, [message]);
  }
}

final class TodoTemplate<T extends Function> extends TodoCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const TodoTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class TodoWithoutArguments extends TodoCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const TodoWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
