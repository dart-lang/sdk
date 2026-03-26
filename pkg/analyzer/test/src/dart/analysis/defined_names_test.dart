// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/defined_names.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinedNamesTest);
  });
}

@reflectiveTest
class DefinedNamesTest extends ParserDiagnosticsTest {
  test_classMemberNames_class() {
    DefinedNames names = _computeDefinedNames('''
class A {
  int a, b;
  A();
  A.c();
  d() {}
  get e => null;
  set f(_) {}
}
class B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(
      names.classMemberNames,
      unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']),
    );
  }

  test_classMemberNames_class_primaryConstructor_named() {
    DefinedNames names = _computeDefinedNames('''
class A.named(final int a1, int a2, var a3);
''');
    expect(names.topLevelNames, unorderedEquals(['A']));
    expect(names.classMemberNames, unorderedEquals(['a1', 'a3']));
  }

  test_classMemberNames_class_primaryConstructor_unnamed() {
    DefinedNames names = _computeDefinedNames('''
class A(final int a1, int a2, var a3);
''');
    expect(names.topLevelNames, unorderedEquals(['A']));
    expect(names.classMemberNames, unorderedEquals(['a1', 'a3']));
  }

  test_classMemberNames_enum() {
    DefinedNames names = _computeDefinedNames('''
enum E {
  v1, v2;
  final int d = 0;
  void e() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, unorderedEquals(['v1', 'v2', 'd', 'e']));
  }

  test_classMemberNames_enum_empty() {
    DefinedNames names = _computeDefinedNames('''
enum E;
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, isEmpty);
  }

  test_classMemberNames_enum_primaryConstructor_named() {
    DefinedNames names = _computeDefinedNames('''
enum E.named(final int a1, int a2, var a3) {
  v1.named(1, 2, 3), v2.named(4, 5, 6);
}
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, unorderedEquals(['v1', 'v2', 'a1', 'a3']));
  }

  test_classMemberNames_enum_primaryConstructor_unnamed() {
    DefinedNames names = _computeDefinedNames('''
enum E(final int a1, int a2, var a3) {
  v1(1, 2, 3), v2(4, 5, 6);
}
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, unorderedEquals(['v1', 'v2', 'a1', 'a3']));
  }

  test_classMemberNames_extension() {
    DefinedNames names = _computeDefinedNames('''
extension E on int {
  int a;
  void b() {}
  int get c => 0;
  set d(int _) {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, unorderedEquals(['a', 'b', 'c', 'd']));
  }

  test_classMemberNames_extension_empty() {
    DefinedNames names = _computeDefinedNames('''
extension E on int;
''');
    expect(names.topLevelNames, unorderedEquals(['E']));
    expect(names.classMemberNames, isEmpty);
  }

  test_classMemberNames_extensionType_primaryConstructor_multipleFormalParameters() {
    DefinedNames names = _computeDefinedNames('''
extension type A(int it1, final int it2, int it3) {
  void foo() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A']));
    expect(names.classMemberNames, unorderedEquals(['it1', 'it2', 'foo']));
  }

  test_classMemberNames_extensionType_primaryConstructor_named() {
    DefinedNames names = _computeDefinedNames('''
extension type A.named(int it) {
  int a, b;
  A();
  A.other();
  void d() {}
  int get e => 0;
  set f(int _) {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A']));
    expect(
      names.classMemberNames,
      unorderedEquals(['it', 'a', 'b', 'd', 'e', 'f']),
    );
  }

  test_classMemberNames_extensionType_primaryConstructor_unnamed() {
    DefinedNames names = _computeDefinedNames('''
extension type A(int it) {
  void foo() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A']));
    expect(names.classMemberNames, unorderedEquals(['it', 'foo']));
  }

  test_classMemberNames_mixin() {
    DefinedNames names = _computeDefinedNames('''
mixin A {
  int a, b;
  d() {}
  get e => null;
  set f(_) {}
}
mixin B {
  g() {}
}
''');
    expect(names.topLevelNames, unorderedEquals(['A', 'B']));
    expect(
      names.classMemberNames,
      unorderedEquals(['a', 'b', 'd', 'e', 'f', 'g']),
    );
  }

  test_classMemberNames_mixin_empty() {
    DefinedNames names = _computeDefinedNames('''
mixin M;
''');
    expect(names.topLevelNames, unorderedEquals(['M']));
    expect(names.classMemberNames, isEmpty);
  }

  test_topLevelNames() {
    DefinedNames names = _computeDefinedNames('''
class A {}
class B = Object with A;
typedef C();
D() {}
get E => null;
set F(_) {}
var G, H;
mixin M {}
''');
    expect(
      names.topLevelNames,
      unorderedEquals(['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'M']),
    );
    expect(names.classMemberNames, isEmpty);
  }

  DefinedNames _computeDefinedNames(String code, {FeatureSet? featureSet}) {
    var parseResult = parseStringWithErrors(code, featureSet: featureSet);
    var unit = parseResult.unit as CompilationUnitImpl;
    return computeDefinedNames(unit);
  }
}
