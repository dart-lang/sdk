// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_options_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IncludeFileWarningTest);
  });
}

@reflectiveTest
class IncludeFileWarningTest extends AbstractAnalysisOptionsTest {
  Future<void> test_fileWarning() async {
    await assertDiagnosticsInFiles({
      analysisOptionsFile: '''
include: a.yaml
//       ^^^^^^
// [diag.includedFileWarning] Warning in the included options file /a.yaml(12..20): The option 'something' isn't supported by 'analyzer'.
''',
      getFile('/a.yaml'): '''
analyzer:
  something: bad
''',
    });
  }
}
