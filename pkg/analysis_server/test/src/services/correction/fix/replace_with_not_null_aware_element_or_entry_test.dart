// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithNotNullAwareElementOrEntryBulkTest);
    defineReflectiveTests(ReplaceWithNotNullAwareElementOrEntryTest);
  });
}

@reflectiveTest
class ReplaceWithNotNullAwareElementOrEntryBulkTest
    extends BulkFixProcessorTest {
  Future<void> test_list() async {
    await resolveTestCode('''
void f(int x, int y) {
  [?x, ?y];
}
''');
    await assertHasFix('''
void f(int x, int y) {
  [x, y];
}
''');
  }

  Future<void> test_map_key() async {
    await resolveTestCode('''
Map<int, String> f(int x, int y) {
  var map = {?x: "", ?y: ""};
  return map;
}
''');
    await assertHasFix('''
Map<int, String> f(int x, int y) {
  var map = {x: "", y: ""};
  return map;
}
''');
  }

  Future<void> test_map_nonNullKey_nonNullValue() async {
    await resolveTestCode('''
Map<Symbol, bool> f(Symbol key, bool value) {
  var map = {?key: ?value};
  return map;
}
''');
    await assertHasFix('''
Map<Symbol, bool> f(Symbol key, bool value) {
  var map = {key: value};
  return map;
}
''');
  }

  Future<void> test_map_nonNullKey_nonNullValue_multiple() async {
    await resolveTestCode('''
Map<int, String> f(int key1, String value1, int key2, String value2) {
  var map = {?key1: ?value1, ?key2: ?value2};
  return map;
}
''');
    await assertHasFix('''
Map<int, String> f(int key1, String value1, int key2, String value2) {
  var map = {key1: value1, key2: value2};
  return map;
}
''');
  }

  Future<void> test_map_nonNullKey_nullValue() async {
    await resolveTestCode('''
Map<Symbol, bool> f(Symbol key, bool? value) {
  var map = {?key: ?value};
  return map;
}
''');
    await assertHasFix('''
Map<Symbol, bool> f(Symbol key, bool? value) {
  var map = {key: ?value};
  return map;
}
''');
  }

  Future<void> test_map_nullKey_nonNullValue() async {
    await resolveTestCode('''
Map<Symbol, bool> f(Symbol? key, bool value) {
  var map = {?key: ?value};
  return map;
}
''');
    await assertHasFix('''
Map<Symbol, bool> f(Symbol? key, bool value) {
  var map = {?key: value};
  return map;
}
''');
  }

  Future<void> test_map_nullKey_nullValue() async {
    await resolveTestCode('''
Map<Symbol, bool> f(Symbol? key, bool? value) {
  var map = {?key: ?value};
  return map;
}
''');
    await assertNoFix();
  }

  Future<void> test_map_value() async {
    await resolveTestCode('''
Map<Symbol, String> f(String x, String y) {
  var map = {#key1: ?x, #key2: ?y};
  return map;
}
''');
    await assertHasFix('''
Map<Symbol, String> f(String x, String y) {
  var map = {#key1: x, #key2: y};
  return map;
}
''');
  }

  Future<void> test_set() async {
    await resolveTestCode('''
Set<int> f(int x, int y) {
  var set = {?x, ?y};
  return set;
}
''');
    await assertHasFix('''
Set<int> f(int x, int y) {
  var set = {x, y};
  return set;
}
''');
  }
}

@reflectiveTest
class ReplaceWithNotNullAwareElementOrEntryTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.replaceWithNotNullAwareElementOrEntry;

  Future<void> test_list() async {
    await resolveTestCode('''
void f(int x) {
  [?x];
}
''');
    await assertHasFix('''
void f(int x) {
  [x];
}
''');
  }

  Future<void> test_map_key() async {
    await resolveTestCode('''
Map<int, String> f(int x) {
  var map = {?x: ""};
  return map;
}
''');
    await assertHasFix('''
Map<int, String> f(int x) {
  var map = {x: ""};
  return map;
}
''');
  }

  Future<void> test_map_value() async {
    await resolveTestCode('''
Map<String, num> f(double x) {
  var map = {"key": ?x};
  return map;
}
''');
    await assertHasFix('''
Map<String, num> f(double x) {
  var map = {"key": x};
  return map;
}
''');
  }

  Future<void> test_set() async {
    await resolveTestCode('''
Set<int> f(int x) {
  var set = {?x};
  return set;
}
''');
    await assertHasFix('''
Set<int> f(int x) {
  var set = {x};
  return set;
}
''');
  }
}
