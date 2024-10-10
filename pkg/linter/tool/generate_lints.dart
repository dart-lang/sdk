// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generation logic for `LintNames` and `LinterLintCode` based on
/// the entries in `pkg/linter/messages.yaml`.
library;

import 'package:analyzer_utilities/tools.dart';

import '../../analyzer/tool/messages/error_code_info.dart';
import 'messages_info.dart';
import 'util/path_utils.dart';

void main() async {
  await GeneratedContent.generateAll(linterPackageRoot, [
    generatedNamesFile,
    generatedCodesFile,
  ]);
}

GeneratedFile get generatedCodesFile =>
    GeneratedFile(generatedCodesPath, (String pkgPath) async {
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

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

// Generator currently outputs double quotes for simplicity.
// ignore_for_file: prefer_single_quotes

import 'analyzer.dart';

class LinterLintCode extends LintCode {
''');

      for (var MapEntry(key: errorName, value: codeInfo)
          in lintMessages['LintCode']!.entries) {
        if (codeInfo.isRemoved) continue;
        out.write(codeInfo.toAnalyzerComments(indent: '  '));
        if (codeInfo.deprecatedMessage case var deprecatedMessage?) {
          out.writeln('  @Deprecated("$deprecatedMessage")');
        }
        out.writeln('  static const LintCode $errorName =');
        out.writeln(codeInfo.toAnalyzerCode(
          'LinterLintCode',
          errorName,
          sharedNameReference: 'LintNames.${codeInfo.sharedName ?? errorName}',
        ));
        out.writeln();
      }

      out.writeln('''
  /// A lint code that removed lints can specify as their `lintCode`.
  ///
  /// Avoid other usages as it should be made unnecessary and removed.
  static const LintCode removed_lint = LinterLintCode(
    'removed_lint',
    'Removed lint.',
  );
''');

      out.writeln('''
  const LinterLintCode(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs,
    String? uniqueName,
  }) : super(uniqueName: 'LintCode.\${uniqueName ?? name}');

  @override
  String get url {
    if (hasPublishedDocs) {
      return 'https://dart.dev/diagnostics/\$name';
    }
    return 'https://dart.dev/lints/\$name';
  }
}
''');
      return out.toString();
    });

String get generatedCodesPath =>
    pathRelativeToPackageRoot(const ['lib', 'src', 'lint_codes.g.dart']);

GeneratedFile get generatedNamesFile =>
    GeneratedFile(generatedNamesPath, (String pkgPath) async {
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

String get generatedNamesPath =>
    pathRelativeToPackageRoot(const ['lib', 'src', 'lint_names.g.dart']);
