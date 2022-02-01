// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../../../../src/utilities/mock_packages.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedArgumentTest1);
    defineReflectiveTests(NamedArgumentTest2);
  });
}

@reflectiveTest
class NamedArgumentTest1 extends CompletionRelevanceTest
    with NamedArgumentTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class NamedArgumentTest2 extends CompletionRelevanceTest
    with NamedArgumentTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin NamedArgumentTestCases on CompletionRelevanceTest {
  @override
  Future<void> setUp() async {
    var metaLibFolder = MockPackages.instance.addMeta(resourceProvider);

    // TODO(scheglov) Use `writeTestPackageConfig` instead
    newDotPackagesFile(testPackageRootPath, content: '''
meta:${metaLibFolder.toUri()}
project:${toUri(testPackageLibPath)}
''');

    await super.setUp();
  }

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
