// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertPartOfToUriNonSiblingTest);
    defineReflectiveTests(ConvertPartOfToUriTest);
  });
}

@reflectiveTest
class ConvertPartOfToUriNonSiblingTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertPartOfToUri;

  @override
  String get testFilePath => convertPath('$testPackageLibPath/src/test.dart');

  Future<void> test_nonSibling() async {
    newFile('$testPackageLibPath/foo.dart', '''
// @dart = 3.4
// preEnhancedParts
library foo;
part 'src/test.dart';
''');

    addTestSource('''
// @dart = 3.4
// preEnhancedParts
part of f^oo;
''');

    await resolveTestFile();
    await assertHasAssist('''
// @dart = 3.4
// preEnhancedParts
part of '../foo.dart';
''');
  }
}

@reflectiveTest
class ConvertPartOfToUriTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertPartOfToUri;

  Future<void> test_sibling() async {
    newFile('$testPackageLibPath/foo.dart', '''
// @dart = 3.4
// preEnhancedParts
library foo;
part 'test.dart';
''');

    addTestSource('''
// @dart = 3.4
// preEnhancedParts
part of f^oo;
''');

    await resolveTestFile();
    await assertHasAssist('''
// @dart = 3.4
// preEnhancedParts
part of 'foo.dart';
''');
  }
}
