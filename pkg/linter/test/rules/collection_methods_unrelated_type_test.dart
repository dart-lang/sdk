// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:linter/src/util/dart_type_utilities.dart';
import 'package:linter/src/util/unrelated_types_visitor.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CollectionMethodsUnrelatedTypeIterableTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeListTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeMapTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeQueueTest);
    defineReflectiveTests(CollectionMethodsUnrelatedTypeSetTest);
  });
}

/// This test has the most coverage of the various [UnrelatedTypesProcessors]
/// subclasses. 99% of the complexity in each "interface/method" case is found
/// in [UnrelatedTypesProcessors] and [typesAreUnrelated], so we do not
/// duplicate all of the test cases for [Iterable.contains] in the test cases
/// for [List.remove], etc.
@reflectiveTest
class CollectionMethodsUnrelatedTypeIterableTest extends LintRuleTest {
  @override
  String get lintRule => 'collection_methods_unrelated_type';

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
    await assertNoDiagnostics('var x = <num>[].contains(null);');
  }

  test_contains_related_Object() async {
    await assertNoDiagnostics('var x = <num>[].contains(Object());');
  }

  test_contains_related_records() async {
    await assertNoDiagnostics('var x = <(num, num)>[].contains((1, 2));');
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
    await assertDiagnostics(
      '''var x = <num>[].contains('1');''',
      [lint(25, 3)],
    );
  }

  test_contains_unrelated_cascade() async {
    await assertDiagnostics(
      '''var x = <num>[]..contains('1');''',
      [lint(26, 3)],
    );
  }

  test_contains_unrelated_implicitTarget() async {
    await assertDiagnostics('''
abstract class C implements List<num> {
  void f() {
    contains('1');
  }
}
''', [lint(66, 3)]);
  }

  test_contains_unrelated_recordAndNonRecord() async {
    await assertDiagnostics("var x = <(int, int)>[].contains('hi');", [
      lint(32, 4),
    ]);
  }

  test_contains_unrelated_records() async {
    await assertDiagnostics("var x = <(int, int)>[].contains(('hi', 'hey'));", [
      lint(32, 13),
    ]);
  }

  test_contains_unrelated_subclassOfList() async {
    await assertDiagnostics('''
abstract class C implements List<num> {}
void f(C c) {
  c.contains('1');
}
''', [lint(68, 3)]);
  }

  test_contains_unrelated_thisTarget() async {
    await assertDiagnostics('''
abstract class C implements List<num> {
  void f() {
    this.contains('1');
  }
}
''', [lint(71, 3)]);
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeListTest extends LintRuleTest {
  @override
  String get lintRule => 'collection_methods_unrelated_type';

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num>[].remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnostics(
      '''var x = <num>[].remove('1');''',
      [lint(23, 3)],
    );
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeMapTest extends LintRuleTest {
  @override
  String get lintRule => 'collection_methods_unrelated_type';

  test_containsKey_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}.containsKey(1);');
  }

  test_containsKey_unrelated() async {
    await assertDiagnostics(
      '''var x = <num, String>{}.containsKey('1');''',
      [lint(36, 3)],
    );
  }

  test_containsValue_related_subtype() async {
    await assertNoDiagnostics('var x = <String, num>{}.containsValue(1);');
  }

  test_containsValue_unrelated() async {
    await assertDiagnostics(
      '''var x = <String, num>{}.containsValue('1');''',
      [lint(38, 3)],
    );
  }

  test_index_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}[1];');
  }

  test_index_unrelated() async {
    await assertDiagnostics(
      '''var x = <num, String>{}['1'];''',
      [lint(24, 3)],
    );
  }

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num, String>{}.remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnostics(
      '''var x = <num, String>{}.remove('1');''',
      [lint(31, 3)],
    );
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeQueueTest extends LintRuleTest {
  @override
  String get lintRule => 'collection_methods_unrelated_type';

  test_remove_related_subtype() async {
    await assertNoDiagnostics('''
import 'dart:collection';
void f(Queue<num> queue) {
  queue.remove(1);
}
''');
  }

  test_remove_unrelated() async {
    await assertDiagnostics('''
import 'dart:collection';
void f(Queue<num> queue) {
  queue.remove('1');
}
''', [lint(68, 3)]);
  }
}

@reflectiveTest
class CollectionMethodsUnrelatedTypeSetTest extends LintRuleTest {
  @override
  String get lintRule => 'collection_methods_unrelated_type';

  test_lookup_related_subtype() async {
    await assertNoDiagnostics('var x = <num>{}.lookup(1);');
  }

  test_lookup_unrelated() async {
    await assertDiagnostics(
      '''var x = <num>{}.lookup('1');''',
      [lint(23, 3)],
    );
  }

  test_remove_related_subtype() async {
    await assertNoDiagnostics('var x = <num>{}.remove(1);');
  }

  test_remove_unrelated() async {
    await assertDiagnostics(
      '''var x = <num>{}.remove('1');''',
      [lint(23, 3)],
    );
  }
}
