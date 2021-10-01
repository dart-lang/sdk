// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferCollectionLiteralsTest);
  });
}

@reflectiveTest
class PreferCollectionLiteralsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_collection_literals';

  /// https://github.com/dart-lang/linter/issues/2985
  test_linkedHashSetParameter_named_type_required() async {
    await assertDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void a({required LinkedHashSet<Foo> some}) {}

void c() {
  a(some: LinkedHashSet<Foo>());
}
''', [
      // No lints
    ]);
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
    await assertDiagnostics(r'''
import 'dart:collection';
    
class Foo {}

void b(LinkedHashSet<Foo> some) {}

void c() {
  b(LinkedHashSet());
}
''', [
      // No lints
    ]);
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
}
