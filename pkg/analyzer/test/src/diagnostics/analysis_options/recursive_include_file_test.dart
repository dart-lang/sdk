// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/analysis_options/error/option_codes.dart';
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
    await assertErrorsInCode(
      '''
include: analysis_options.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.recursiveIncludeFile,
          9,
          21,
          text:
              "The include file 'analysis_options.yaml' "
              "in '${convertPath('/analysis_options.yaml')}' includes itself "
              'recursively.',
        ),
      ],
    );
  }

  Future<void> test_itself_inList() async {
    await assertErrorsInCode(
      '''
include:
  - analysis_options.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.recursiveIncludeFile,
          13,
          21,
          text:
              "The include file 'analysis_options.yaml' "
              "in '${convertPath('/analysis_options.yaml')}' includes itself "
              'recursively.',
        ),
      ],
    );
  }

  Future<void> test_notRecursive() async {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '');
    await assertNoErrorsInCode('''
include:
  - a.yaml
  - b.yaml
''');
  }

  Future<void> test_recursive() async {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '''
include: analysis_options.yaml
''');
    await assertErrorsInCode(
      '''
include: a.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.recursiveIncludeFile,
          9,
          6,
          text:
              "The include file 'analysis_options.yaml' "
              "in '${convertPath('/b.yaml')}' includes itself recursively.",
        ),
      ],
    );
  }

  Future<void> test_recursive_itself() async {
    newFile('/a.yaml', '''
include: a.yaml
''');
    await assertErrorsInCode(
      '''
include: a.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.includedFileWarning,
          9,
          6,
          messageContains: [
            "Warning in the included options file ${convertPath('/a.yaml')}",
            ": The file includes itself recursively.",
          ],
        ),
      ],
    );
  }

  Future<void> test_recursive_listAtTop() async {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '''
include: analysis_options.yaml
''');
    newFile('/empty.yaml', '''
''');
    await assertErrorsInCode(
      '''
include:
  - empty.yaml
  - a.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.recursiveIncludeFile,
          28,
          6,
          text:
              "The include file 'analysis_options.yaml' "
              "in '${convertPath('/b.yaml')}' includes itself recursively.",
        ),
      ],
    );
  }

  Future<void> test_recursive_listIncluded() async {
    newFile('/a.yaml', '''
include:
  - empty.yaml
  - b.yaml
''');
    newFile('/b.yaml', '''
include: analysis_options.yaml
''');
    newFile('/empty.yaml', '''
''');
    await assertErrorsInCode(
      '''
include: a.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.recursiveIncludeFile,
          9,
          6,
          text:
              "The include file 'analysis_options.yaml' "
              "in '${convertPath('/b.yaml')}' includes itself recursively.",
        ),
      ],
    );
  }

  Future<void> test_recursive_notInBeginning() async {
    newFile('/a.yaml', '''
include: b.yaml
''');
    newFile('/b.yaml', '''
include: a.yaml
''');
    await assertErrorsInCode(
      '''
include: a.yaml
''',
      [
        error(
          AnalysisOptionsWarningCode.includedFileWarning,
          9,
          6,
          messageContains: [
            "Warning in the included options file ${convertPath('/a.yaml')}",
            ": The file includes itself recursively.",
          ],
        ),
      ],
    );
  }
}
