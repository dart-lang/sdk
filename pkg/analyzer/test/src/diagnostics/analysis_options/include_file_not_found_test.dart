// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncludeFileNotFoundTest);
  });
}

@reflectiveTest
class IncludeFileNotFoundTest extends AbstractAnalysisOptionsTest {
  Future<void> test_notFound_existent_doubleQuoted() async {
    await assertDiagnosticsInCode('''
include: "./analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_notFound_existent_list_first() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
  - included1.yaml
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_notFound_existent_list_second() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - included1.yaml
  - ./analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_notFound_existent_notQuoted() async {
    await assertDiagnosticsInCode('''
include: ./analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_notFound_existent_singleQuoted() async {
    await assertDiagnosticsInCode('''
include: './analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI './analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_notFound_nonexistent_doubleQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: "package:pedantic/analysis_options.yaml"
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  Future<void> test_notFound_nonexistent_list_first() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
  - included1.yaml
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_notFound_nonexistent_list_second() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
# We don't depend on pedantic, but we should consider adding it.
include:
  - included1.yaml
  - package:pedantic/analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''',
      getFile('/included1.yaml'): '',
    });
  }

  Future<void> test_notFound_nonexistent_notQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: package:pedantic/analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }

  Future<void> test_notFound_nonexistent_singleQuoted() async {
    await assertDiagnosticsInCode('''
# We don't depend on pedantic, but we should consider adding it.
include: 'package:pedantic/analysis_options.yaml'
//       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.includeFileNotFound] The URI 'package:pedantic/analysis_options.yaml' included in '/analysis_options.yaml' can't be found when analyzing '/'.
''');
  }
}
