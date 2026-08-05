// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionMethodsUnrelatedTypeIterableTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeListTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeMapTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeQueueTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeSetTest);
  });
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeIterableTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.collection_methods_unrelated_type;

  @override
  void setUp() {
    newPackage('protobuf').addFile('lib/src/protobuf/protobuf_enum.dart', r'''
class ProtobufEnum {}
''');
    super.setUp();
  }

  test_contains_related_dynamic() async {
    await assertNoDiagnostics('''var x = <num>[].contains('1' as dynamic);''');
  }

  test_contains_related_implicitTarget() async {
    await assertNoDiagnostics('''
abstract class C implements List<num> {
  void f() {
    contains(1);
  }
}
''');
  }

  test_contains_related_ListOfDynamic() async {
    await assertNoDiagnostics('var x = [].contains(1);');
  }

  test_contains_related_mixedInto() async {
    await assertNoDiagnostics('''
mixin M {}
class C with M {}
late M m;
var x = <C>[].contains(m);
''');
  }

  test_contains_related_mixesIn() async {
    await assertNoDiagnostics('''
mixin M {}
class C with M {}
var x = <M>[].contains(C());
''');
  }

  test_contains_related_null() async {
    await assertNoDiagnostics('var x = <num?>[].contains(null);');
  }

  test_contains_related_null_genericNullable() async {
    await assertNoDiagnostics('''
bool f<T extends Object?>() {
  return <T>[].contains(null);
}
''');
  }

  test_contains_related_null_genericNullable2() async {
    await assertNoDiagnostics('''
bool f<T extends Object>() {
  return <T?>[].contains(null);
}
''');
  }

  test_contains_related_Object() async {
    await assertNoDiagnostics('var x = <num>[].contains(Object());');
  }

  test_contains_related_records() async {
    await assertNoDiagnostics('var x = <(num, num)>[].contains((1, 2));');
  }

  test_contains_related_sameEnum() async {
    await assertNoDiagnostics('''
var x = <E>[].contains(E.a);
enum E { a, b }
''');
  }

  test_contains_related_sameProtobufEnum() async {
    await assertNoDiagnostics('''
import 'package:protobuf/src/protobuf/protobuf_enum.dart';
var x = <E>[].contains(E());
class E extends ProtobufEnum {}
''');
  }

  test_contains_related_subclassOfList() async {
    await assertNoDiagnostics('''
abstract class C implements List<num> {}
void f(C c) {
  c.contains(1);
}
''');
  }

  test_contains_related_subtype() async {
    await assertNoDiagnostics('var x = <num>[].contains(1);');
  }

  test_contains_related_thisTarget() async {
    await assertNoDiagnostics('''
abstract class C implements List<num> {
  void f() {
    this.contains(1);
  }
}
''');
  }

  test_contains_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num>[].contains([!'1'!]);''');
  }

  test_contains_unrelated_cascade() async {
    await assertDiagnosticsFromMarkup('''
var x = <num>[]..contains([!'1'!]);''');
  }

  test_contains_unrelated_differentEnums() async {
    await assertDiagnosticsFromMarkup('''
var x = <E1>[].contains([!E2.c!]);
enum E1 { a, b }
enum E2 { c, d }
''');
  }

  test_contains_unrelated_differentProtobufEnums() async {
    await assertDiagnosticsFromMarkup('''
import 'package:protobuf/src/protobuf/protobuf_enum.dart';
var x = <E1>[].contains([!E2()!]);
class E1 extends ProtobufEnum {}
class E2 extends ProtobufEnum {}
''');
  }

  test_contains_unrelated_implicitTarget() async {
    await assertDiagnosticsFromMarkup('''
abstract class C implements List<num> {
  void f() {
    contains([!'1'!]);
  }
}
''');
  }

  test_contains_unrelated_null() async {
    await assertDiagnosticsFromMarkup('var x = <num>[].contains([!null!]);');
  }

  test_contains_unrelated_null_generic() async {
    await assertDiagnosticsFromMarkup('''
bool f<T extends Object>() {
  return <T>[].contains([!null!]);
}
''');
  }

  test_contains_unrelated_recordAndNonRecord() async {
    await assertDiagnosticsFromMarkup(
      "var x = <(int, int)>[].contains([!'hi'!]);",
    );
  }

  test_contains_unrelated_records() async {
    await assertDiagnosticsFromMarkup(
      "var x = <(int, int)>[].contains([!('hi', 'hey')!]);",
    );
  }

  test_contains_unrelated_subclassOfList() async {
    await assertDiagnosticsFromMarkup('''
abstract class C implements List<num> {}
void f(C c) {
  c.contains([!'1'!]);
}
''');
  }

  test_contains_unrelated_thisTarget() async {
    await assertDiagnosticsFromMarkup('''
abstract class C implements List<num> {
  void f() {
    this.contains([!'1'!]);
  }
}
''');
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeListTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.collection_methods_unrelated_type;

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num>[].remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num>[].remove([!'1'!]);''');
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeMapTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.collection_methods_unrelated_type;

  test_containsKey_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}.containsKey(1);');
  }

  test_containsKey_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num, String>{}.containsKey([!'1'!]);''');
  }

  test_containsValue_related_subtype() async {
    await assertNoDiagnostics('var x = <String, num>{}.containsValue(1);');
  }

  test_containsValue_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <String, num>{}.containsValue([!'1'!]);''');
  }

  test_index_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}[1];');
  }

  test_index_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num, String>{}[[!'1'!]];''');
  }

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}.remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num, String>{}.remove([!'1'!]);''');
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeQueueTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.collection_methods_unrelated_type;

  test_remove_related_subtype() async {
    await assertNoDiagnostics('''
import 'dart:collection';
void f(Queue<num> queue) {
  queue.remove(1);
}
''');
  }

  test_remove_unrelated() async {
    await assertDiagnosticsFromMarkup('''
import 'dart:collection';
void f(Queue<num> queue) {
  queue.remove([!'1'!]);
}
''');
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeSetTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.collection_methods_unrelated_type;

  test_contains_extensionType_different_sameRepresentationType() async {
    await assertNoDiagnostics(r'''
void m(Set<E1> s, E2 e) {
  s.contains(e);
}
extension type E1(int value) {}
extension type E2(int value) {}
''');
  }

  test_contains_extensionType_different_unrelatedRepresentationType() async {
    await assertDiagnosticsFromMarkup(r'''
void m(Set<E1> s, E2 e) {
  s.contains([!e!]);
}
extension type E1(int value) {}
extension type E2(String value) {}
''');
  }

  test_contains_extensionType_representationType() async {
    await assertNoDiagnostics(r'''
void m(Set<int> s, E e) {
  s.contains(e);
}
extension type E(int value) {}
''');
  }

  test_contains_extensionType_same() async {
    await assertNoDiagnostics(r'''
void m(Set<E> s, E e) {
  s.contains(e);
}
extension type E(int value) {}
''');
  }

  test_lookup_related_subtype() async {
    await assertNoDiagnostics('var x = <num>{}.lookup(1);');
  }

  test_lookup_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num>{}.lookup([!'1'!]);''');
  }

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num>{}.remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnosticsFromMarkup('''
var x = <num>{}.remove([!'1'!]);''');
  }
}
