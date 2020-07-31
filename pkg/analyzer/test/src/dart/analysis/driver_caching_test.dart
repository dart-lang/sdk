// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverCachingTest);
  });
}

@reflectiveTest
class AnalysisDriverCachingTest extends DriverResolutionTest {
  List<Set<String>> get _linkedCycles {
    return driver.test.libraryContext.linkedCycles;
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
  }

  test_lints() async {
    var path = convertPath('/test/lib/test.dart');

    newFile(path, content: r'''
void f() {
  ![0].isEmpty;
}
''');

    // We don't have any lints configured, so no errors.
    assertErrorsInList(
      (await driver.getErrors(path)).errors,
      [],
    );

    // The summary for the library was linked.
    _assertHasLinkedCycle({path}, andClear: true);

    // Configure to run a lint.
    driver.configure(
      analysisOptions: AnalysisOptionsImpl()
        ..lint = true
        ..lintRules = [
          Registry.ruleRegistry.getRule('prefer_is_not_empty'),
        ],
    );

    // Check that the lint was run, and reported.
    _assertHasLintReported(
      (await driver.getErrors(path)).errors,
      'prefer_is_not_empty',
    );

    // Lints don't affect summaries, nothing should be linked.
    _assertNoLinkedCycles();
  }

  void _assertHasLinkedCycle(Set<String> expected, {bool andClear = false}) {
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
