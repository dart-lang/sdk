// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generation logic for `LinterLintCode` and its static members
/// based on the entries in `pkg/linter/messages.yaml`.
library;

import 'package:analyzer_utilities/tools.dart';

import '../../../analyzer/tool/messages/error_code_info.dart';

Future<void> main() async {
  await GeneratedFile('lib/src/linter_lint_codes.dart', (String pkgPath) async {
    var out = StringBuffer('''
// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/linter/messages.yaml' and run
// 'dart run pkg/linter/tool/codes/generate.dart' to update.

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
      out.writeln(codeInfo.toAnalyzerCode('LinterLintCode', errorName));
      out.writeln();
    }

    out.writeln('''
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
  }).generate(linterPkgPath);
}
