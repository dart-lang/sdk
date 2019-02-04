// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfElementTest);
  });
}

@reflectiveTest
class ConvertToIfElementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_IF_ELEMENT;

  void setUp() {
    createAnalysisOptionsFile(experiments: [
      EnableString.control_flow_collections,
      EnableString.set_literals
    ]);
    super.setUp();
  }

  test_conditional_list() async {
    await resolveTestUnit('''
f(bool b) {
  return ['a', b /*caret*/? 'c' : 'd', 'e'];
}
''');
    await assertHasAssist('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  test_conditional_list_withParentheses() async {
    await resolveTestUnit('''
f(bool b) {
  return ['a', (b /*caret*/? 'c' : 'd'), 'e'];
}
''');
    await assertHasAssist('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  test_conditional_map() async {
    await resolveTestUnit('''
f(bool b) {
  return {'a' : 1, b /*caret*/? 'c' : 'd' : 2, 'e' : 3};
}
''');
    await assertNoAssist();
  }

  test_conditional_notConditional() async {
    await resolveTestUnit('''
f(bool b) {
  return {'/*caret*/a', b ? 'c' : 'd', 'e'};
}
''');
    await assertNoAssist();
  }

  test_conditional_notInLiteral() async {
    await resolveTestUnit('''
f(bool b) {
  return b /*caret*/? 'c' : 'd';
}
''');
    await assertNoAssist();
  }

  test_conditional_set() async {
    await resolveTestUnit('''
f(bool b) {
  return {'a', b /*caret*/? 'c' : 'd', 'e'};
}
''');
    await assertHasAssist('''
f(bool b) {
  return {'a', if (b) 'c' else 'd', 'e'};
}
''');
  }

  test_conditional_set_withParentheses() async {
    await resolveTestUnit('''
f(bool b) {
  return {'a', ((b /*caret*/? 'c' : 'd')), 'e'};
}
''');
    await assertHasAssist('''
f(bool b) {
  return {'a', if (b) 'c' else 'd', 'e'};
}
''');
  }

  test_mapFromIterable_complexKey() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) {
    var result = e * 2;
    return result;
  }, value: (e) => e + 3);
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_complexValue() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) => e * 2, value: (e) {
    var result = e  + 3;
    return result;
  });
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_differentParameterNames_usedInKey_conflictInValue() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_differentParameterNames_usedInKey_noConflictInValue() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_differentParameterNames_usedInKeyAndValue_conflictWithDefault() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_differentParameterNames_usedInKeyAndValue_noConflictWithDefault() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_differentParameterNames_usedInValue_conflictInKey() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_differentParameterNames_usedInValue_noConflictInKey() async {
    await resolveTestUnit('''
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

  test_mapFromIterable_missingKey() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, value: (e) => e + 3);
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_missingKeyAndValue() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i);
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_missingValue() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return Map.fromIt/*caret*/erable(i, key: (e) => e * 2);
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_notMapFromIterable() async {
    await resolveTestUnit('''
f(Iterable<int> i) {
  return A.fromIt/*caret*/erable(i, key: (e) => e * 2, value: (e) => e + 3);
}
class A {
  A.fromIterable(i, {key, value});
}
''');
    await assertNoAssist();
  }

  test_mapFromIterable_sameParameterNames() async {
    await resolveTestUnit('''
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
}
