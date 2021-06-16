// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToForElementTest);
  });
}

@reflectiveTest
class ConvertToForElementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_FOR_ELEMENT;

  Future<void> test_mapFromIterable_complexKey() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) {
    var result = e * 2;
    return result;
  }, value: (e) => e + 3);
}
''');
    await assertNoAssist();
  }

  Future<void> test_mapFromIterable_complexValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) => e * 2, value: (e) {
    var result = e  + 3;
    return result;
  });
}
''');
    await assertNoAssist();
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKey_conflictInValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  var k = 3;
  return Map.fromIt/*caret*/erable(i, key: (k) => k * 2, value: (v) => k);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  var k = 3;
  return { for (var e in i) e * 2 : k };
}
''');
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKey_conflictInValue_noAssistWithLint() async {
    createAnalysisOptionsFile(
        lints: [LintNames.prefer_for_elements_to_map_fromIterable]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
f(Iterable<int> i) {
  var k = 3;
  return Map.fromIt/*caret*/erable(i, key: (k) => k * 2, value: (v) => k);
}
''');
    await assertNoAssist();
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKey_noConflictInValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (k) => k * 2, value: (v) => 0);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  return { for (var k in i) k * 2 : 0 };
}
''');
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKeyAndValue_conflictWithDefault() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  var e = 2;
  return Map.fromIt/*caret*/erable(i, key: (k) => k * e, value: (v) => v + e);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  var e = 2;
  return { for (var e1 in i) e1 * e : e1 + e };
}
''');
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInKeyAndValue_noConflictWithDefault() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (k) => k * 2, value: (v) => v + 3);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  return { for (var e in i) e * 2 : e + 3 };
}
''');
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInValue_conflictInKey() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  int v = 0;
  return Map.fromIt/*caret*/erable(i, key: (k) => v++, value: (v) => v * 10);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  int v = 0;
  return { for (var e in i) v++ : e * 10 };
}
''');
  }

  Future<void>
      test_mapFromIterable_differentParameterNames_usedInValue_noConflictInKey() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  int index = 0;
  return Map.fromIt/*caret*/erable(i, key: (k) => index++, value: (v) => v * 10);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  int index = 0;
  return { for (var v in i) index++ : v * 10 };
}
''');
  }

  Future<void> test_mapFromIterable_missingKey() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, value: (e) => e + 3);
}
''');
    await assertNoAssist();
  }

  Future<void> test_mapFromIterable_missingKeyAndValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i);
}
''');
    await assertNoAssist();
  }

  Future<void> test_mapFromIterable_missingValue() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) => e * 2);
}
''');
    await assertNoAssist();
  }

  Future<void> test_mapFromIterable_notMapFromIterable() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return A.fromIt/*caret*/erable(i, key: (e) => e * 2, value: (e) => e + 3);
}
class A {
  A.fromIterable(i, {key, value});
}
''');
    await assertNoAssist();
  }

  Future<void> test_mapFromIterable_sameParameterNames() async {
    await resolveTestCode('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) => e * 2, value: (e) => e + 3);
}
''');
    await assertHasAssist('''
f(Iterable<int> i) {
  return { for (var e in i) e * 2 : e + 3 };
}
''');
  }

  Future<void> test_undefinedConstructor() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
f() {
  return new Unde/*caret*/fined();
}
''');
    await assertNoAssist();
  }
}
