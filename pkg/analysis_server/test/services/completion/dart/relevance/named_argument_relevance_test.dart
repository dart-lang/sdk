// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedArgumentRelevanceTest);
    defineReflectiveTests(NamedArgumentRelevanceWithNnbdTest);
  });
}

@reflectiveTest
class NamedArgumentRelevanceTest extends CompletionRelevanceTest
    with PackageMixin {
  @override
  Map<String, List<Folder>> packageMap = {};

  @override
  void setUp() {
    super.setUp();
    newFile('$projectPath/.packages', content: '''
meta:${toUri('/.pub-cache/meta/lib')}
project:${toUri('$projectPath/lib')}
''');
  }

  Future<void> test_requiredAnnotation() async {
    addMetaPackage();
    await addTestFile('''
import 'package:meta/meta.dart';

void f({int a, @required int b}) {}

void g() => f(^);
''');
    assertOrder([
      suggestionWith(completion: 'b: '),
      suggestionWith(completion: 'a: '),
    ]);
  }
}

@reflectiveTest
class NamedArgumentRelevanceWithNnbdTest extends NamedArgumentRelevanceTest {
  @override
  List<String> get enabledExperiments => ['non-nullable'];

  Future<void> test_required() async {
    await addTestFile('''
void f({int a = 0, required int b}) {}

void g() => f(^);
''');
    assertOrder([
      suggestionWith(completion: 'b: '),
      suggestionWith(completion: 'a: '),
    ]);
  }
}
