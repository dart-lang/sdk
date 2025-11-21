// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/generate_lints.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

// Generator currently outputs double quotes for simplicity.
// ignore_for_file: prefer_single_quotes

// Generated `withArguments` methods always use block bodies for simplicity.
// ignore_for_file: prefer_expression_function_bodies

part of 'lint_codes.dart';

class LinterLintCode extends LintCodeWithExpectedTypes {
  const LinterLintCode({
    required super.name,
    required super.problemMessage,
    required super.uniqueName,
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
  });

  @override
  String get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/$name';
    }
    return 'https://dart.dev/lints/$name';
  }
}

final class LinterLintTemplate<T extends Function> extends LinterLintCode
    implements DiagnosticWithArguments<T> {
  @override
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const LinterLintTemplate({
    required super.name,
    required super.problemMessage,
    required this.withArguments,
    required super.expectedTypes,
    required super.uniqueName,
    super.correctionMessage,
    super.hasPublishedDocs = false,
  });
}

final class LinterLintWithoutArguments extends LinterLintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const LinterLintWithoutArguments({
    required super.name,
    required super.problemMessage,
    required super.expectedTypes,
    required super.uniqueName,
    super.correctionMessage,
    super.hasPublishedDocs = false,
  });
}
