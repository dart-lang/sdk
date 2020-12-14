// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverCachingTest);
  });
}

@reflectiveTest
class AnalysisDriverCachingTest extends PubPackageResolutionTest {
  List<Set<String>> get _linkedCycles {
    var driver = driverFor(testFilePath);
    return driver.test.libraryContext.linkedCycles;
  }

  test_change_field_staticFinal_hasConstConstructor_changeInitializer() async {
    useEmptyByteStore();

    newFile(testFilePath, content: r'''
class A {
  static const a = 0;
  static const b = 1;
  static final Set<int> f = {a};
  const A {}
}
''');

    await resolveTestFile();
    assertType(findElement.field('f').type, 'Set<int>');

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

    newFile(testFilePath, content: r'''
class A {
  static const a = 0;
  static const b = 1;
  static final Set<int> f = <int>{a, b, 2};
  const A {}
}
''');

    await resolveTestFile();
    assertType(findElement.field('f').type, 'Set<int>');

    // We changed the initializer of the final field. But it is static, so
    // even though the class hsa a constant constructor, we don't need its
    // initializer, so nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_change_functionBody() async {
    useEmptyByteStore();

    newFile(testFilePath, content: r'''
void f() {
  print(0);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('0'), isNotNull);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // Dispose the collection, with its driver.
    // The next analysis will recreate it.
    // We will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

    newFile(testFilePath, content: r'''
void f() {
  print(1);
}
''');

    await resolveTestFile();
    expect(findNode.integerLiteral('1'), isNotNull);

    // We changed only the function body, nothing should be linked.
    _assertNoLinkedCycles();
  }

  test_lints() async {
    useEmptyByteStore();

    newFile(testFilePath, content: r'''
void f() {
  ![0].isEmpty;
}
''');

    // We don't have any lints configured, so no errors.
    await resolveTestFile();
    assertErrorsInResult([]);

    // The summary for the library was linked.
    _assertContainsLinkedCycle({testFilePath}, andClear: true);

    // We will recreate it with new analysis options.
    // But we will reuse the byte store, so can reuse summaries.
    disposeAnalysisContextCollection();

    // Configure to run a lint.
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        lints: ['prefer_is_not_empty'],
      ),
    );

    // Check that the lint was run, and reported.
    await resolveTestFile();
    _assertHasLintReported(result.errors, 'prefer_is_not_empty');

    // Lints don't affect summaries, nothing should be linked.
    _assertNoLinkedCycles();
  }

  void _assertContainsLinkedCycle(Set<String> expectedPosix,
      {bool andClear = false}) {
    var expected = expectedPosix.map(convertPath).toSet();
    expect(_linkedCycles, contains(unorderedEquals(expected)));
    if (andClear) {
      _linkedCycles.clear();
    }
  }

  void _assertHasLintReported(List<AnalysisError> errors, String name) {
    var matching = errors.where((element) {
      var errorCode = element.errorCode;
      return errorCode is LintCode && errorCode.name == name;
    }).toList();
    expect(matching, hasLength(1));
  }

  void _assertNoLinkedCycles() {
    expect(_linkedCycles, isEmpty);
  }
}
