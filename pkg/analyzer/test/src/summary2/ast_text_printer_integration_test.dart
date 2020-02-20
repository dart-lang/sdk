// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:test/test.dart';

import '../dart/ast/parse_base.dart';
import '../../utils/package_root.dart' as package_root;
import 'ast_text_printer_test.dart';

main() {
  group('Parse and print AST |', () {
    _buildTests();
  });
}

void _buildTests() {
  var provider = PhysicalResourceProvider.INSTANCE;
  var pathContext = provider.pathContext;

  var packageRoot = pathContext.normalize(package_root.packageRoot);
  var dartFiles = Directory(packageRoot)
      .listSync(recursive: true)
      .whereType<File>()
      .where((e) => e.path.endsWith('.dart'))
      .toList();

  var base = ParseBase();
  for (var file in dartFiles) {
    var relPath = pathContext.relative(file.path, from: packageRoot);
    test(relPath, () {
      var code = file.readAsStringSync();
      assertParseCodeAndPrintAst(base, code, mightHasParseErrors: true);
    }, skip: tempSkiped(file));
  }
}

dynamic tempSkiped(File file) {
  String uriString = file.uri.toString();
  if (uriString.endsWith(
          "front_end/parser_testcases/nnbd/issue_40267_case_02.dart") ||
      uriString.endsWith(
          "front_end/parser_testcases/nnbd/issue_40267_case_05.dart")) {
    return "Temporarily skipped because of "
        "https://dart-review.googlesource.com/c/sdk/+/135903";
  }
  return false;
}
