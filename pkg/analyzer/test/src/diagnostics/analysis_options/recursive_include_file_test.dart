// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveIncludeFileTest);
  });
}

@reflectiveTest
class RecursiveIncludeFileTest extends AbstractAnalysisOptionsTest {
  Future<void> test_itself() async {
    await assertDiagnosticsInCode('''
include: analysis_options.yaml
//       ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_itself_inList() async {
    await assertDiagnosticsInCode('''
include:
  - analysis_options.yaml
//  ^^^^^^^^^^^^^^^^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/analysis_options.yaml' includes '/analysis_options.yaml', creating a circular reference.
''');
  }

  Future<void> test_notRecursive() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - a.yaml
  - b.yaml
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '',
    });
  }

  Future<void> test_notRecursive_included() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: c.yaml
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '',
      getFile('/c.yaml'): '''
include:
  - a.yaml
  - b.yaml
''',
    });
  }

  Future<void> test_recursive() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
    });
  }

  Future<void> test_recursive_itself() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(9..14): The file includes itself recursively.
''',
      getFile('/a.yaml'): '''
include: a.yaml
''',
    });
  }

  Future<void> test_recursive_listAtTop() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include:
  - empty.yaml
  - a.yaml
//  ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('/empty.yaml'): '''
''',
    });
  }

  Future<void> test_recursive_listIncluded() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.recursiveIncludeFile] The URI 'analysis_options.yaml' included in '/b.yaml' includes '/b.yaml', creating a circular reference.
''',
      getFile('/a.yaml'): '''
include:
  - empty.yaml
  - b.yaml
''',
      getFile('/b.yaml'): '''
include: analysis_options.yaml
''',
      getFile('/empty.yaml'): '''
''',
    });
  }

  Future<void> test_recursive_notInBeginning() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(9..14): The file includes itself recursively.
''',
      getFile('/a.yaml'): '''
include: b.yaml
''',
      getFile('/b.yaml'): '''
include: a.yaml
''',
    });
  }
}
