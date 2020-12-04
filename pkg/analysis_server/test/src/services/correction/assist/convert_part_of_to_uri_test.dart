// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertPartOfToUriTest);
  });
}

@reflectiveTest
class ConvertPartOfToUriTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_PART_OF_TO_URI;

  Future<void> test_nonSibling() async {
    addSource('/home/test/lib/foo.dart', '''
library foo;
part 'src/bar.dart';
''');

    testFile = convertPath('/home/test/lib/src/bar.dart');
    addTestSource('''
part of foo;
''');

    await analyzeTestPackageFiles();
    await resolveTestFile();
    await assertHasAssistAt('foo', '''
part of '../foo.dart';
''');
  }

  Future<void> test_sibling() async {
    addSource('/home/test/lib/foo.dart', '''
library foo;
part 'bar.dart';
''');

    testFile = convertPath('/home/test/lib/bar.dart');
    addTestSource('''
part of foo;
''');

    await analyzeTestPackageFiles();
    await resolveTestFile();
    await assertHasAssistAt('foo', '''
part of 'foo.dart';
''');
  }
}
