// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';
import 'package:test/test.dart';
import 'package:vm/transformations/to_string_transformer.dart'
    show transformComponent;

import '../common_test_utils.dart';

final Uri pkgVmUri = Platform.script.resolve('../..');

runTestCase(List<String> packageUris, String expectationName) async {
  final testCasesUri =
      pkgVmUri.resolve('testcases/transformations/to_string_transformer/');
  final packagesFileUri =
      testCasesUri.resolve('.dart_tool/package_config.json');
  Component component = await compileTestCaseToKernelProgram(
      Uri.parse('package:to_string_transformer_test/main.dart'),
      packagesFileUri: packagesFileUri);

  transformComponent(component, packageUris);
  verifyComponent(component);

  final actual = kernelLibraryToString(component.mainMethod!.enclosingLibrary);

  compareResultWithExpectationsFile(
      testCasesUri.resolve(expectationName), actual);
}

main() {
  group('to-string-transformer', () {
    runTestCase(['package:foo'], 'not_transformed');
    runTestCase(
        ['package:foo', 'package:to_string_transformer_test'], 'transformed');
  });
}
