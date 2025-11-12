// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generation logic for `LintNames` and `LinterLintCode` based on
/// the entries in `pkg/linter/messages.yaml`.
library;

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/analyzer_messages.dart';
import 'package:analyzer_utilities/tools.dart';

import 'messages_info.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, [
    generatedNamesFile,
    generatedCodesFile,
  ]);
}

const String generatedNamesPath = 'linter/lib/src/lint_names.g.dart';

GeneratedFile get generatedCodesFile =>
    GeneratedFile(generatedLintCodesPath, (pkgRoot) async {
      var out = StringBuffer('''
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
''');
      var memberAccumulator = MemberAccumulator();
      for (var message in lintMessages) {
        var analyzerCode = message.analyzerCode;
        var lintName = message.sharedName ?? analyzerCode.snakeCaseName;
        if (messagesRuleInfo[lintName]!.removed) continue;
        message.toClassMember(
          sharedNameReference: 'LintNames.$lintName',
          memberAccumulator: memberAccumulator,
        );
      }

      var removedLintName = 'removedLint';
      memberAccumulator.constants[removedLintName] =
          '''
  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode $removedLintName = LinterLintCode(
    name: 'removed_lint',
    problemMessage: 'Removed lint.',
    expectedTypes: [],
    uniqueName: 'LintCode.removed_lint',
  );
''';

      memberAccumulator.constructors[''] = '''
  const LinterLintCode({
    required super.name,
    required super.problemMessage,
    required super.uniqueName,
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
  });
''';

      memberAccumulator.accessors['url'] = '''
  @override
  String get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/\$name';
    }
    return 'https://dart.dev/lints/\$name';
  }
''';
      memberAccumulator.writeTo(out);
      out.writeln('}');

      out.write('''

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
''');
      return out.toString();
    });

GeneratedFile get generatedNamesFile =>
    GeneratedFile(generatedNamesPath, (pkgRoot) async {
      var out = StringBuffer('''
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/generate_lints.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

// An enumeration of the names of the analyzer's built-in lint rules.
abstract final class LintNames {
''');

      for (var lintName in messagesRuleInfo.keys) {
        out.writeln("  static const String $lintName = '$lintName';");
        out.writeln();
      }

      out.writeln('}');
      return out.toString();
    });
