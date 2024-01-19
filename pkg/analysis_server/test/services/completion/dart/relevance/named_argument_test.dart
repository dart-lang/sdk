// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../src/utilities/mock_packages.dart';
import 'completion_relevance.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NamedArgumentTest);
  });
}

@reflectiveTest
class NamedArgumentTest extends CompletionRelevanceTest
    with NamedArgumentTestCases {}

mixin NamedArgumentTestCases on CompletionRelevanceTest {
  @override
  Future<void> setUp() async {
    var metaLibFolder = MockPackages.instance.addMeta(resourceProvider);

    writeTestPackageConfig(
      config: PackageConfigFileBuilder()
        ..add(name: 'meta', rootPath: metaLibFolder.parent.path),
    );

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
