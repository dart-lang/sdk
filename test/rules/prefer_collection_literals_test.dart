// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferCollectionLiteralsPreNNBDTest);
    defineReflectiveTests(PreferCollectionLiteralsTest);
  });
}

@reflectiveTest
class PreferCollectionLiteralsPreNNBDTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_collection_literals';

  test_list_empty() async {
    await assertDiagnostics(r'''
// @dart=2.9    
var list = List(); 
''', [
      lint('prefer_collection_literals', 28, 6),
    ]);
  }

  test_list_inList() async {
    await assertDiagnostics(r'''
// @dart=2.9    
var list = [[], List()];
''', [
      lint('prefer_collection_literals', 33, 6),
    ]);
  }

  test_list_sized() async {
    await assertNoDiagnostics(r'''
// @dart=2.9    
var list = List(5);
''');
  }
}

@reflectiveTest
class PreferCollectionLiteralsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_collection_literals';

  /// https://github.com/dart-lang/linter/issues/2985
  test_linkedHashSetParameter_named_type_required() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void a({required LinkedHashSet<Foo> some}) {}

void c() {
  a(some: LinkedHashSet<Foo>());
}
''');
  }

  test_linkedHashSetParameter_named_type_unrequired() async {
    await assertDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void a({required Set<Foo> some}) {}

void c() {
  a(some: LinkedHashSet<Foo>());
}
''', [
      lint('prefer_collection_literals', 103, 20),
    ]);
  }

  test_linkedHashSetParameter_type_required() async {
    await assertNoDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void b(LinkedHashSet<Foo> some) {}

void c() {
  b(LinkedHashSet());
}
''');
  }

  test_linkedHashSetParameter_type_unrequired() async {
    await assertDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void b(Set<Foo> some) {}

void c() {
  b(LinkedHashSet<Foo>());
}
''', [
      lint('prefer_collection_literals', 86, 20),
    ]);
  }

  test_undefinedFunction() async {
    await assertDiagnostics(r'''
import 'dart:collection';
    
void f() {
  printUnresolved(LinkedHashSet<int>());
}
''', [
      // No lints.
      error(CompileTimeErrorCode.UNDEFINED_FUNCTION, 44, 15),
    ]);
  }
}
