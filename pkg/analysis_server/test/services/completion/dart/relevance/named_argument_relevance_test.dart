// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../src/utilities/mock_packages.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedArgumentRelevanceTest);
    defineReflectiveTests(NamedArgumentRelevanceWithNullSafetyTest);
  });
}

@reflectiveTest
class NamedArgumentRelevanceTest extends CompletionRelevanceTest {
  @override
  void setUp() {
    super.setUp();

    var metaLibFolder = MockPackages.instance.addMeta(resourceProvider);

    newFile('$projectPath/.packages', content: '''
meta:${metaLibFolder.toUri()}
project:${toUri('$projectPath/lib')}
''');
  }

  Future<void> test_requiredAnnotation() async {
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
class NamedArgumentRelevanceWithNullSafetyTest
    extends NamedArgumentRelevanceTest {
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
