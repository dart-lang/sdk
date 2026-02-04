// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Generation logic for `LintNames` and `LinterLintCode` based on
/// the entries in `pkg/linter/messages.yaml`.
library;

import 'package:analyzer_testing/package_root.dart' as pkg_root;
import 'package:analyzer_utilities/tools.dart';

import 'messages_info.dart';

void main() async {
  await GeneratedContent.generateAll(pkg_root.packageRoot, [
    generatedNamesFile,
  ]);
}

const String generatedNamesPath = 'linter/lib/src/lint_names.g.dart';

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
        var lintNameLowerCase = lintName.toLowerCase();
        out.writeln(
          "  static const String $lintNameLowerCase = '$lintNameLowerCase';",
        );
        out.writeln();
      }

      out.writeln('}');
      return out.toString();
    });
