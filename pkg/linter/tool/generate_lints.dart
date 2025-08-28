// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generation logic for `LintNames` and `LinterLintCode` based on
/// the entries in `pkg/linter/messages.yaml`.
library;

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';

import '../../analyzer/tool/messages/error_code_info.dart';
import 'messages_info.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, [
    generatedNamesFile,
    generatedCodesFile,
  ]);
}

const String generatedCodesPath = 'linter/lib/src/lint_codes.g.dart';

const String generatedNamesPath = 'linter/lib/src/lint_names.g.dart';

const lintCodesFile = GeneratedErrorCodeFile(
  path: generatedCodesPath,
  parentLibrary: 'package:linter/src/lint_codes.dart',
);

const linterLintCodeInfo = ErrorClassInfo(
  file: lintCodesFile,
  name: 'LinterLintCode',
  type: 'LINT',
);

GeneratedFile get generatedCodesFile =>
    GeneratedFile(generatedCodesPath, (pkgRoot) async {
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
''');
      if (literateApiEnabled) {
        out.write('''

// Generated `withArguments` methods always use block bodies for simplicity.
// ignore_for_file: prefer_expression_function_bodies
''');
      }
      out.write('''

part of 'lint_codes.dart';

class LinterLintCode extends LintCodeWithExpectedTypes {
''');
      var memberAccumulator = MemberAccumulator();
      for (var MapEntry(key: errorName, value: codeInfo)
          in lintMessages['LintCode']!.entries) {
        var lintName = codeInfo.sharedName ?? errorName;
        if (messagesRuleInfo[lintName]!.removed) continue;
        codeInfo.toAnalyzerCode(
          linterLintCodeInfo,
          errorName,
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
    'removed_lint',
    'Removed lint.',
    expectedTypes: [],
  );
''';

      memberAccumulator.constructors[''] = '''
  const LinterLintCode(
    super.name,
    super.problemMessage, {
    super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
  }) : super(uniqueName: 'LintCode.\${uniqueName ?? name}');
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

      if (literateApiEnabled) {
        out.write('''

final class LinterLintTemplate<T extends Function> extends LinterLintCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const LinterLintTemplate(
    super.name,
    super.problemMessage, {
    required this.withArguments,
    required super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.uniqueName,
  });
}

final class LinterLintWithoutArguments extends LinterLintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const LinterLintWithoutArguments(
    super.name,
    super.problemMessage, {
    required super.expectedTypes,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.uniqueName,
  });
}
''');
      }
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
