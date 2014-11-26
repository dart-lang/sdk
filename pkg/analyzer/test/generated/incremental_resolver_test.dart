// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver_test;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'parser_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(DeclarationMatcherTest);
  runReflectiveTests(IncrementalResolverTest);
  runReflectiveTests(PoorMansIncrementalResolutionTest);
  runReflectiveTests(ResolutionContextBuilderTest);
}


class DeclarationMatcherTest extends ResolverTestCase {
  void test_false_class_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B {}
class C {}
''');
  }

  void test_false_class_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_class_typeParameters_bounds_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B<T> {
  T f;
}
''', r'''
class A {}
class B<T extends A> {
  T f;
}
''');
  }

  void test_false_class_typeParameters_bounds_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B<T extends A> {
  T f;
}
''', r'''
class A {}
class B<T> {
  T f;
}
''');
  }

  void test_false_classMemberAccessor_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {
  get a => 1;
  get b => 2;
}
''', r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''');
  }

  void test_false_classMemberAccessor_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''', r'''
class A {
  get a => 1;
  get b => 2;
}
''');
  }

  void test_false_classMemberAccessor_wasGetter() {
    _assertCompilationUnitMatches(false, r'''
class A {
  get a => 1;
}
''', r'''
class A {
  set a(x) {}
}
''');
  }

  void test_false_classMemberAccessor_wasInstance() {
    _assertCompilationUnitMatches(false, r'''
class A {
  get a => 1;
}
''', r'''
class A {
  static get a => 1;
}
''');
  }

  void test_false_classMemberAccessor_wasSetter() {
    _assertCompilationUnitMatches(false, r'''
class A {
  set a(x) {}
}
''', r'''
class A {
  get a => 1;
}
''');
  }

  void test_false_classMemberAccessor_wasStatic() {
    _assertCompilationUnitMatches(false, r'''
class A {
  static get a => 1;
}
''', r'''
class A {
  get a => 1;
}
''');
  }

  void test_false_classTypeAlias_list_add() {
    _assertCompilationUnitMatches(false, r'''
class M {}
class A = Object with M;
''', r'''
class M {}
class A = Object with M;
class B = Object with M;
''');
  }

  void test_false_classTypeAlias_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class M {}
class A = Object with M;
class B = Object with M;
''', r'''
class M {}
class A = Object with M;
''');
  }

  void test_false_classTypeAlias_typeParameters_bounds_add() {
    _assertCompilationUnitMatches(false, r'''
class M<T> {}
class A {}
class B<T> = Object with M<T>;
''', r'''
class M<T> {}
class A {}
class B<T extends A> = Object with M<T>;
''');
  }

  void test_false_classTypeAlias_typeParameters_bounds_remove() {
    _assertCompilationUnitMatches(false, r'''
class M<T> {}
class A {}
class B<T extends A> = Object with M<T>;
''', r'''
class M<T> {}
class A {}
class B<T> = Object with M<T>;
''');
  }

  void test_false_constructor_parameters_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A();
}
''', r'''
class A {
  A(int p);
}
''');
  }

  void test_false_constructor_parameters_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A();
}
''');
  }

  void test_false_constructor_parameters_type_edit() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A(String p);
}
''');
  }

  void test_false_constructor_unnamed_add_hadParameters() {
    _assertCompilationUnitMatches(false, r'''
class A {
}
''', r'''
class A {
  A(int p) {}
}
''');
  }

  void test_false_constructor_unnamed_remove_hadParameters() {
    _assertCompilationUnitMatches(false, r'''
class A {
  A(int p) {}
}
''', r'''
class A {
}
''');
  }

  void test_false_defaultFieldFormalParameterElement_wasSimple() {
    _assertCompilationUnitMatches(false, r'''
class A {
  int field;
  A(int field);
}
''', r'''
class A {
  int field;
  A([this.field = 0]);
}
''');
  }

  void test_false_enum_constants_add() {
    resetWithEnum();
    _assertCompilationUnitMatches(false, r'''
enum E {A, B}
''', r'''
enum E {A, B, C}
''');
  }

  void test_false_enum_constants_remove() {
    resetWithEnum();
    _assertCompilationUnitMatches(false, r'''
enum E {A, B, C}
''', r'''
enum E {A, B}
''');
  }

  void test_false_export_hide_add() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async' hide Future;
''', r'''
export 'dart:async' hide Future, Stream;
''');
  }

  void test_false_export_hide_remove() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async' hide Future, Stream;
''', r'''
export 'dart:async' hide Future;
''');
  }

  void test_false_export_list_add() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async';
''', r'''
export 'dart:async';
export 'dart:math';
''');
  }

  void test_false_export_list_remove() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async';
export 'dart:math';
''', r'''
export 'dart:async';
''');
  }

  void test_false_export_show_add() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async' show Future;
''', r'''
export 'dart:async' show Future, Stream;
''');
  }

  void test_false_export_show_remove() {
    _assertCompilationUnitMatches(false, r'''
export 'dart:async' show Future, Stream;
''', r'''
export 'dart:async' show Future;
''');
  }

  void test_false_extendsClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B extends A {}
''');
  }

  void test_false_extendsClause_different() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C extends A {}
''', r'''
class A {}
class B {}
class C extends B {}
''');
  }

  void test_false_extendsClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B extends A{}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_field_list_add() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_false_field_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int C = 3;
}
''');
  }

  void test_false_field_modifier_isConst() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static final A = 1;
}
''', r'''
class T {
  static const A = 1;
}
''');
  }

  void test_false_field_modifier_isFinal() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
}
''', r'''
class T {
  final int A = 1;
}
''');
  }

  void test_false_field_modifier_isStatic() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A = 1;
}
''', r'''
class T {
  static int A = 1;
}
''');
  }

  void test_false_field_modifier_wasConst() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static const A = 1;
}
''', r'''
class T {
  static final A = 1;
}
''');
  }

  void test_false_field_modifier_wasFinal() {
    _assertCompilationUnitMatches(false, r'''
class T {
  final int A = 1;
}
''', r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_modifier_wasStatic() {
    _assertCompilationUnitMatches(false, r'''
class T {
  static int A = 1;
}
''', r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_type_differentArgs() {
    _assertCompilationUnitMatches(false, r'''
class T {
  List<int> A;
}
''', r'''
class T {
  List<String> A;
}
''');
  }

  void test_false_fieldFormalParameterElement_wasSimple() {
    _assertCompilationUnitMatches(false, r'''
class A {
  int field;
  A(int field);
}
''', r'''
class A {
  int field;
  A(this.field);
}
''');
  }

  void test_false_final_type_different() {
    _assertCompilationUnitMatches(false, r'''
class T {
  int A;
}
''', r'''
class T {
  String A;
}
''');
  }

  void test_false_functionTypeAlias_list_add() {
    _assertCompilationUnitMatches(false, r'''
typedef A(int pa);
typedef B(String pb);
''', r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''');
  }

  void test_false_functionTypeAlias_list_remove() {
    _assertCompilationUnitMatches(false, r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''', r'''
typedef A(int pa);
typedef B(String pb);
''');
  }

  void test_false_functionTypeAlias_parameters_list_add() {
    _assertCompilationUnitMatches(false, r'''
typedef A(a);
''', r'''
typedef A(a, b);
''');
  }

  void test_false_functionTypeAlias_parameters_list_remove() {
    _assertCompilationUnitMatches(false, r'''
typedef A(a, b);
''', r'''
typedef A(a);
''');
  }

  void test_false_functionTypeAlias_parameters_type_edit() {
    _assertCompilationUnitMatches(false, r'''
typedef A(int p);
''', r'''
typedef A(String p);
''');
  }

  void test_false_functionTypeAlias_returnType_edit() {
    _assertCompilationUnitMatches(false, r'''
typedef int A();
''', r'''
typedef String A();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
typedef F<T>();
''', r'''
class A {}
typedef F<T extends A>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_edit() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
typedef F<T extends A>();
''', r'''
class A {}
typedef F<T extends B>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
typedef F<T extends A>();
''', r'''
class A {}
typedef F<T>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_list_add() {
    _assertCompilationUnitMatches(false, r'''
typedef F<A>();
''', r'''
typedef F<A, B>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_list_remove() {
    _assertCompilationUnitMatches(false, r'''
typedef F<A, B>();
''', r'''
typedef F<A>();
''');
  }

  void test_false_implementsClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B implements A {}
''');
  }

  void test_false_implementsClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B implements A {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_implementsClause_reorder() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C implements A, B {}
''', r'''
class A {}
class B {}
class C implements B, A {}
''');
  }

  void test_false_import_hide_add() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' hide Future;
''', r'''
import 'dart:async' hide Future, Stream;
''');
  }

  void test_false_import_hide_remove() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' hide Future, Stream;
''', r'''
import 'dart:async' hide Future;
''');
  }

  void test_false_import_list_add() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async';
''', r'''
import 'dart:async';
import 'dart:math';
''');
  }

  void test_false_import_list_remove() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async';
import 'dart:math';
''', r'''
import 'dart:async';
''');
  }

  void test_false_import_prefix_add() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async';
''', r'''
import 'dart:async' as async;
''');
  }

  void test_false_import_prefix_edit() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' as oldPrefix;
''', r'''
import 'dart:async' as newPrefix;
''');
  }

  void test_false_import_prefix_remove() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' as async;
''', r'''
import 'dart:async';
''');
  }

  void test_false_import_show_add() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' show Future;
''', r'''
import 'dart:async' show Future, Stream;
''');
  }

  void test_false_import_show_remove() {
    _assertCompilationUnitMatches(false, r'''
import 'dart:async' show Future, Stream;
''', r'''
import 'dart:async' show Future;
''');
  }

  void test_false_method_list_add() {
    _assertCompilationUnitMatches(false, r'''
class A {
  a() {}
  b() {}
}
''', r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  void test_false_method_list_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {
  a() {}
  b() {}
  c() {}
}
''', r'''
class A {
  a() {}
  b() {}
}
''');
  }

  void test_false_method_returnType_edit() {
    _assertCompilationUnitMatches(false, r'''
class A {
  int m() {}
}
''', r'''
class A {
  String m() {}
}
''');
  }

  void test_false_part_list_add() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertCompilationUnitMatches(false, r'''
library lib;
part 'unitA.dart';
''', r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
  }

  void test_false_part_list_remove() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertCompilationUnitMatches(false, r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''', r'''
library lib;
part 'unitA.dart';
''');
  }

  void test_false_topLevelAccessor_list_add() {
    _assertCompilationUnitMatches(false, r'''
get a => 1;
get b => 2;
''', r'''
get a => 1;
get b => 2;
get c => 3;
''');
  }

  void test_false_topLevelAccessor_list_remove() {
    _assertCompilationUnitMatches(false, r'''
get a => 1;
get b => 2;
get c => 3;
''', r'''
get a => 1;
get b => 2;
''');
  }

  void test_false_topLevelAccessor_wasGetter() {
    _assertCompilationUnitMatches(false, r'''
get a => 1;
''', r'''
set a(x) {}
''');
  }

  void test_false_topLevelAccessor_wasSetter() {
    _assertCompilationUnitMatches(false, r'''
set a(x) {}
''', r'''
get a => 1;
''');
  }

  void test_false_topLevelFunction_list_add() {
    _assertCompilationUnitMatches(false, r'''
a() {}
b() {}
''', r'''
a() {}
b() {}
c() {}
''');
  }

  void test_false_topLevelFunction_list_remove() {
    _assertCompilationUnitMatches(false, r'''
a() {}
b() {}
c() {}
''', r'''
a() {}
b() {}
''');
  }

  void test_false_topLevelFunction_parameters_list_add() {
    _assertCompilationUnitMatches(false, r'''
main(int a, int b) {
}
''', r'''
main(int a, int b, int c) {
}
''');
  }

  void test_false_topLevelFunction_parameters_list_remove() {
    _assertCompilationUnitMatches(false, r'''
main(int a, int b, int c) {
}
''', r'''
main(int a, int b) {
}
''');
  }

  void test_false_topLevelFunction_parameters_type_edit() {
    _assertCompilationUnitMatches(false, r'''
main(int a, int b, int c) {
}
''', r'''
main(int a, String b, int c) {
}
''');
  }

  void test_false_topLevelFunction_returnType_edit() {
    _assertCompilationUnitMatches(false, r'''
int a() {}
''', r'''
String a() {}
''');
  }

  void test_false_topLevelVariable_list_add() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
const int C = 3;
''', r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_list_remove() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int A = 1;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_modifier_isConst() {
    _assertCompilationUnitMatches(false, r'''
final int A = 1;
''', r'''
const int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_isFinal() {
    _assertCompilationUnitMatches(false, r'''
int A = 1;
''', r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasConst() {
    _assertCompilationUnitMatches(false, r'''
const int A = 1;
''', r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasFinal() {
    _assertCompilationUnitMatches(false, r'''
final int A = 1;
''', r'''
int A = 1;
''');
  }

  void test_false_topLevelVariable_synthetic_wasGetter() {
    _assertCompilationUnitMatches(false, r'''
int get A => 1;
''', r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_type_different() {
    _assertCompilationUnitMatches(false, r'''
int A;
''', r'''
String A;
''');
  }

  void test_false_topLevelVariable_type_differentArgs() {
    _assertCompilationUnitMatches(false, r'''
List<int> A;
''', r'''
List<String> A;
''');
  }

  void test_false_type_noTypeArguments_hadTypeArguments() {
    _assertCompilationUnitMatches(false, r'''
class A<T> {}
A<int> main() {
}
''', r'''
class A<T> {}
A main() {
}
''');
  }

  void test_false_withClause_add() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
''', r'''
class A {}
class B extends Object with A {}
''');
  }

  void test_false_withClause_remove() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B extends Object with A {}
''', r'''
class A {}
class B {}
''');
  }

  void test_false_withClause_reorder() {
    _assertCompilationUnitMatches(false, r'''
class A {}
class B {}
class C extends Object with A, B {}
''', r'''
class A {}
class B {}
class C extends Object with B, A {}
''');
  }

  void test_true_class_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B {}
class C {}
''', r'''
class C {}
class A {}
class B {}
''');
  }

  void test_true_class_list_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B {}
class C {}
''', r'''
class A {}
class B {}
class C {}
''');
  }

  void test_true_class_typeParameters_same() {
    _assertCompilationUnitMatches(true, r'''
class A<T> {}
''', r'''
class A<T> {}
''');
  }

  void test_true_classMemberAccessor_getterSetter() {
    _assertCompilationUnitMatches(true, r'''
class A {
  int _test;
  get test => _test;
  set test(v) {
    _test = v;
  }
}
''', r'''
class A {
  int _test;
  get test => _test;
  set test(v) {
    _test = v;
  }
}
''');
  }

  void test_true_classMemberAccessor_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''', r'''
class A {
  get c => 3;
  get a => 1;
  get b => 2;
}
''');
  }

  void test_true_classMemberAccessor_list_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''', r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''');
  }

  void test_true_classTypeAlias_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''', r'''
class M {}
class C = Object with M;
class A = Object with M;
class B = Object with M;
''');
  }

  void test_true_classTypeAlias_list_same() {
    _assertCompilationUnitMatches(true, r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''', r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''');
  }

  void test_true_classTypeAlias_typeParameters_same() {
    _assertCompilationUnitMatches(true, r'''
class M<T> {}
class A<T> {}
class B<T> = A<T> with M<T>;
''', r'''
class M<T> {}
class A<T> {}
class B<T> = A<T> with M<T>;
''');
  }

  void test_true_constructor_named_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A.name(int p);
}
''', r'''
class A {
  A.name(int p);
}
''');
  }

  void test_true_constructor_unnamed_add_noParameters() {
    _assertCompilationUnitMatches(true, r'''
class A {
}
''', r'''
class A {
  A() {}
}
''');
  }

  void test_true_constructor_unnamed_remove_noParameters() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A() {}
}
''', r'''
class A {
}
''');
  }

  void test_true_constructor_unnamed_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  A(int p);
}
''', r'''
class A {
  A(int p);
}
''');
  }

  void test_true_defaultFieldFormalParameterElement() {
    _assertCompilationUnitMatches(true, r'''
class A {
  int field;
  A([this.field = 0]);
}
''', r'''
class A {
  int field;
  A([this.field = 0]);
}
''');
  }

  void test_true_enum_constants_reorder() {
    resetWithEnum();
    _assertCompilationUnitMatches(true, r'''
enum E {A, B, C}
''', r'''
enum E {C, A, B}
''');
  }

  void test_true_enum_list_reorder() {
    resetWithEnum();
    _assertCompilationUnitMatches(true, r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''', r'''
enum C {C1, C2, C3}
enum A {A1, A2, A3}
enum B {B1, B2, B3}
''');
  }

  void test_true_enum_list_same() {
    resetWithEnum();
    _assertCompilationUnitMatches(true, r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''', r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''');
  }

  void test_true_executable_same_hasLabel() {
    _assertCompilationUnitMatches(true, r'''
main() {
  label: return 42;
}
''', r'''
main() {
  label: return 42;
}
''');
  }

  void test_true_executable_same_hasLocalVariable() {
    _assertCompilationUnitMatches(true, r'''
main() {
  int a = 42;
}
''', r'''
main() {
  int a = 42;
}
''');
  }

  void test_true_export_hide_reorder() {
    _assertCompilationUnitMatches(true, r'''
export 'dart:async' hide Future, Stream;
''', r'''
export 'dart:async' hide Stream, Future;
''');
  }

  void test_true_export_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
export 'dart:async';
export 'dart:math';
''', r'''
export 'dart:math';
export 'dart:async';
''');
  }

  void test_true_export_list_same() {
    _assertCompilationUnitMatches(true, r'''
export 'dart:async';
export 'dart:math';
''', r'''
export 'dart:async';
export 'dart:math';
''');
  }

  void test_true_export_show_reorder() {
    _assertCompilationUnitMatches(true, r'''
export 'dart:async' show Future, Stream;
''', r'''
export 'dart:async' show Stream, Future;
''');
  }

  void test_true_extendsClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B extends A {}
''', r'''
class A {}
class B extends A {}
''');
  }

  void test_true_field_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int C = 3;
  int A = 1;
  int B = 2;
}
''');
  }

  void test_true_field_list_same() {
    _assertCompilationUnitMatches(true, r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''', r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_true_fieldFormalParameterElement() {
    _assertCompilationUnitMatches(true, r'''
class A {
  int field;
  A(this.field);
}
''', r'''
class A {
  int field;
  A(this.field);
}
''');
  }

  void test_true_functionTypeAlias_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''', r'''
typedef C(pc);
typedef A(int pa);
typedef B(String pb);
''');
  }

  void test_true_functionTypeAlias_list_same() {
    _assertCompilationUnitMatches(true, r'''
typedef String A(int pa);
typedef int B(String pb);
typedef C(pc);
''', r'''
typedef String A(int pa);
typedef int B(String pb);
typedef C(pc);
''');
  }

  void test_true_functionTypeAlias_typeParameters_list_same() {
    _assertCompilationUnitMatches(true, r'''
typedef F<A, B, C>();
''', r'''
typedef F<A, B, C>();
''');
  }

  void test_true_implementsClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B implements A {}
''', r'''
class A {}
class B implements A {}
''');
  }

  void test_true_import_hide_reorder() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async' hide Future, Stream;
''', r'''
import 'dart:async' hide Stream, Future;
''');
  }

  void test_true_import_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async';
import 'dart:math';
''', r'''
import 'dart:math';
import 'dart:async';
''');
  }

  void test_true_import_list_same() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async';
import 'dart:math';
''', r'''
import 'dart:async';
import 'dart:math';
''');
  }

  void test_true_import_prefix() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async' as async;
''', r'''
import 'dart:async' as async;
''');
  }

  void test_true_import_show_reorder() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async' show Future, Stream;
''', r'''
import 'dart:async' show Stream, Future;
''');
  }

  void test_true_method_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
class A {
  a() {}
  b() {}
  c() {}
}
''', r'''
class A {
  c() {}
  a() {}
  b() {}
}
''');
  }

  void test_true_method_list_same() {
    _assertCompilationUnitMatches(true, r'''
class A {
  a() {}
  b() {}
  c() {}
}
''', r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  void test_true_method_operator_minus() {
    _assertCompilationUnitMatches(true, r'''
class A {
  operator -(other) {}
}
''', r'''
class A {
  operator -(other) {}
}
''');
  }

  void test_true_method_operator_minusUnary() {
    _assertCompilationUnitMatches(true, r'''
class A {
  operator -() {}
}
''', r'''
class A {
  operator -() {}
}
''');
  }

  void test_true_method_operator_plus() {
    _assertCompilationUnitMatches(true, r'''
class A {
  operator +(other) {}
}
''', r'''
class A {
  operator +(other) {}
}
''');
  }

  void test_true_part_list_reorder() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertCompilationUnitMatches(true, r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''', r'''
library lib;
part 'unitB.dart';
part 'unitA.dart';
''');
  }

  void test_true_part_list_same() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertCompilationUnitMatches(true, r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''', r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
  }

  void test_true_topLevelAccessor_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
set a(x) {}
set b(x) {}
set c(x) {}
''', r'''
set c(x) {}
set a(x) {}
set b(x) {}
''');
  }

  void test_true_topLevelAccessor_list_same() {
    _assertCompilationUnitMatches(true, r'''
get a => 1;
get b => 2;
get c => 3;
''', r'''
get a => 1;
get b => 2;
get c => 3;
''');
  }

  void test_true_topLevelFunction_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
a() {}
b() {}
c() {}
''', r'''
c() {}
a() {}
b() {}
''');
  }

  void test_true_topLevelFunction_list_same() {
    _assertCompilationUnitMatches(true, r'''
a() {}
b() {}
c() {}
''', r'''
a() {}
b() {}
c() {}
''');
  }

  void test_true_topLevelVariable_list_reorder() {
    _assertCompilationUnitMatches(true, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int C = 3;
const int A = 1;
const int B = 2;
''');
  }

  void test_true_topLevelVariable_list_same() {
    _assertCompilationUnitMatches(true, r'''
const int A = 1;
const int B = 2;
const int C = 3;
''', r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_true_topLevelVariable_type_sameArgs() {
    _assertCompilationUnitMatches(true, r'''
Map<int, String> A;
''', r'''
Map<int, String> A;
''');
  }

  void test_true_type_dynamic() {
    _assertCompilationUnitMatches(true, r'''
dynamic a() {}
''', r'''
dynamic a() {}
''');
  }

  void test_true_type_hasImportPrefix() {
    _assertCompilationUnitMatches(true, r'''
import 'dart:async' as async;
async.Future F;
''', r'''
import 'dart:async' as async;
async.Future F;
''');
  }

  void test_true_type_noTypeArguments_implyAllDynamic() {
    _assertCompilationUnitMatches(true, r'''
class A<T> {}
A main() {
}
''', r'''
class A<T> {}
A main() {
}
''');
  }

  void test_true_type_void() {
    _assertCompilationUnitMatches(true, r'''
void a() {}
''', r'''
void a() {}
''');
  }

  void test_true_withClause_same() {
    _assertCompilationUnitMatches(true, r'''
class A {}
class B extends Object with A {}
''', r'''
class A {}
class B extends Object with A {}
''');
  }

  void _assertCompilationUnitMatches(bool expectMatch, String oldContent,
      String newContent) {
    Source source = addSource(oldContent);
    LibraryElement library = resolve(source);
    CompilationUnit oldUnit = resolveCompilationUnit(source, library);
    CompilationUnit newUnit = ParserTestCase.parseCompilationUnit(newContent);
    DeclarationMatcher matcher = new DeclarationMatcher();
    expect(matcher.matches(newUnit, oldUnit.element), expectMatch);
  }
}


class IncrementalResolverTest extends ResolverTestCase {
  Source source;
  String code;
  LibraryElement library;
  CompilationUnit unit;

  void test_constructor_body() {
    _resolveUnit(r'''
class A {
  int f;
  A(int a, int b) {
    f = a + b;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_constructor_fieldInitializer_add() {
    _resolveUnit(r'''
class A {
  int f;
  A(int a, int b);
}''');
    _resolve(_editString(');', ') : f = a + b;'), _isClassMember);
  }

  void test_constructor_fieldInitializer_edit() {
    _resolveUnit(r'''
class A {
  int f;
  A(int a, int b) : f = a + b {
    int a = 42;
  }
}''');
    _resolve(_editString('+', '*'), _isExpression);
  }

  void test_constructor_superConstructorInvocation() {
    _resolveUnit(r'''
class A {
  A(int p);
}
class B extends A {
  B(int a, int b) : super(a + b);
}
''');
    _resolve(_editString('+', '*'), _isExpression);
  }

  void test_functionBody_body() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_functionBody_expression() {
    _resolveUnit(r'''
main(int a, int b) => a + b;
''');
    _resolve(_editString('+', '*'), _isExpression);
  }

  void test_functionBody_statement() {
    _resolveUnit(r'''
main(int a, int b) {
  return a + b;
}''');
    _resolve(_editString('+', '*'), _isStatement);
  }

  void test_method_body() {
    _resolveUnit(r'''
class A {
  m(int a, int b) {
    return a + b;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_method_label_add() {
    _resolveUnit(r'''
class A {
  int m(int a, int b) {
    return a + b;
  }
}
''');
    _resolve(_editString('return', 'label: return'), _isBlock);
  }

  void test_method_localVariable_add() {
    _resolveUnit(r'''
class A {
  int m(int a, int b) {
    return a + b;
  }
}
''');
    _resolve(_editString('    return a + b;', r'''
    int res = a + b;
    return res;
'''), _isBlock);
  }

  void test_method_parameter_rename() {
    _resolveUnit(r'''
class A {
  int m(int a, int b, int c) {
    return a + b + c;
  }
}
''');
    _resolve(_editString(r'''(int a, int b, int c) {
    return a + b + c;''', r'''(int a, int second, int c) {
    return a + second + c;'''), _isDeclaration);
  }

  void test_superInvocation() {
    _resolveUnit(r'''
class A {
  foo(p) {}
}
class B extends A {
  bar() {
    super.foo(1 + 2);
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

  void test_topLevelFunction_label_add() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(_editString('  return', 'label: return a + b;'), _isBlock);
  }

  void test_topLevelFunction_label_remove() {
    _resolveUnit(r'''
int main(int a, int b) {
  label: return a + b;
}
''');
    _resolve(_editString('label: ', ''), _isBlock);
  }

  void test_topLevelFunction_localVariable_add() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(_editString('  return a + b;', r'''
  int res = a + b;
  return res;
'''), _isBlock);
  }

  void test_topLevelFunction_localVariable_remove() {
    _resolveUnit(r'''
int main(int a, int b) {
  int res = a * b;
  return a + b;
}
''');
    _resolve(_editString('int res = a * b;', ''), _isBlock);
  }

  void test_topLevelFunction_parameter_rename() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(_editString(r'''(int a, int b) {
  return a + b;''', r'''(int first, int b) {
  return first + b;'''), _isDeclaration);
  }

  void test_topLevelVariable_initializer() {
    _resolveUnit(r'''
int C = 1 + 2;
''');
    _resolve(_editString('+', '*'), _isExpression);
  }

  void test_updateElementOffset() {
    _resolveUnit(r'''
class A {
  int am(String ap) {
    int av = 1;
    return av;
  }
}
main(int a, int b) {
  return a + b;
}
class B {
  int bm(String bp) {
    int bv = 1;
    return bv;
  }
}
''');
    _resolve(_editString('+', ' + '), _isStatement);
  }

  _Edit _editString(String search, String replacement, [int length]) {
    int offset = code.indexOf(search);
    expect(offset, isNot(-1));
    if (length == null) {
      length = search.length;
    }
    return new _Edit(offset, length, replacement);
  }

  /**
   * Applies [edit] to [code], find the [AstNode] specified by [predicate]
   * and incrementally resolves it.
   *
   * Then resolves the new code from scratch and validates that results of
   * the incremental resolution and non-incremental resolutions are the same.
   */
  void _resolve(_Edit edit, Predicate<AstNode> predicate) {
    int offset = edit.offset;
    // parse "newCode"
    String newCode =
        code.substring(0, offset) +
        edit.replacement +
        code.substring(offset + edit.length);
    CompilationUnit newUnit = _parseUnit(newCode);
    // update tokens
    {
      int delta = edit.replacement.length - edit.length;
      _shiftTokens(unit.beginToken, offset, delta);
    }
    // replace the node
    AstNode oldNode = _findNodeAt(unit, offset, predicate);
    AstNode newNode = _findNodeAt(newUnit, offset, predicate);
    bool success = NodeReplacer.replace(oldNode, newNode);
    expect(success, isTrue);
    // do incremental resolution
    IncrementalResolver resolver = new IncrementalResolver(
        typeProvider,
        library,
        unit.element,
        source,
        edit.offset,
        edit.length,
        edit.replacement.length);
    resolver.resolve(newNode);
    // resolve "newCode" from scratch
    CompilationUnit fullNewUnit;
    {
      source = addSource(newCode);
      LibraryElement library = resolve(source);
      fullNewUnit = resolveCompilationUnit(source, library);
    }
    _SameResolutionValidator.assertSameResolution(unit, fullNewUnit);
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    library = resolve(source);
    unit = resolveCompilationUnit(source, library);
  }

  static AstNode _findNodeAt(CompilationUnit oldUnit, int offset,
      Predicate<AstNode> predicate) {
    NodeLocator locator = new NodeLocator.con1(offset);
    AstNode node = locator.searchWithin(oldUnit);
    return node.getAncestor(predicate);
  }

  static bool _isBlock(AstNode node) => node is Block;

  static bool _isClassMember(AstNode node) => node is ClassMember;

  static bool _isDeclaration(AstNode node) => node is Declaration;

  static bool _isExpression(AstNode node) => node is Expression;

  static bool _isFunctionBody(AstNode node) => node is FunctionBody;

  static bool _isStatement(AstNode node) => node is Statement;

  static CompilationUnit _parseUnit(String code) {
    var errorListener = new BooleanErrorListener();
    var reader = new CharSequenceReader(code);
    var scanner = new Scanner(null, reader, errorListener);
    var token = scanner.tokenize();
    var parser = new Parser(null, errorListener);
    return parser.parseCompilationUnit(token);
  }

  static void _shiftTokens(Token token, int afterOffset, int delta) {
    while (token.type != TokenType.EOF) {
      if (token.offset >= afterOffset) {
        token.applyDelta(delta);
      }
      token = token.next;
    }
  }
}


/**
 * The test for [poorMansIncrementalResolution] function and its integration
 * into [AnalysisContext].
 */
class PoorMansIncrementalResolutionTest extends ResolverTestCase {
  Source source;
  String code;
  LibraryElement oldLibrary;
  CompilationUnit oldUnit;
  CompilationUnitElement oldUnitElement;

  void setUp() {
    super.setUp();
    _resetWithIncremental(true);
  }

  void test_inBody_expression() {
    _resolveUnit(r'''
class A {
  m() {
    print(1);
  }
}
''');
    _updateAndValidate(r'''
class A {
  m() {
    print(2 + 3);
  }
}
''');
  }

  void test_inBody_insertStatement() {
    _resolveUnit(r'''
main() {
  print(1);
}
''');
    _updateAndValidate(r'''
main() {
  print(0);
  print(1);
}
''');
  }

  void test_inBody_tokenToNode() {
    _resolveUnit(r'''
main() {
  var v = 42;
  print(v);
}
''');
    _updateAndValidate(r'''
main() {
  int v = 42;
  print(v);
}
''');
  }

  void test_multiple_emptyLine() {
    _resolveUnit(r'''
class A {
  m() {
    return true;
  }
}''');
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        _updateAndValidate(r'''
class A {
  m() {
    return true;

  }
}''', false);
      } else {
        _updateAndValidate(r'''
class A {
  m() {
    return true;
  }
}''', false);
      }
    }
  }

  void test_multiple_expression() {
    _resolveUnit(r'''
main() {
  print(1);
}''');
    for (int i = 0; i < 6; i++) {
      if (i.isEven) {
        _updateAndValidate(r'''
main() {
  print(12);
}''', false);
      } else {
        _updateAndValidate(r'''
main() {
  print(1);
}''', false);
      }
    }
  }

  void test_true_wholeConstructor() {
    _resolveUnit(r'''
class A {
  A(int a) {
    print(a);
  }
}
''');
    _updateAndValidate(r'''
class A {
  A(int b) {
    print(b);
  }
}
''');
  }

  void test_true_wholeConstructor_addInitializer() {
    _resolveUnit(r'''
class A {
  int field;
  A();
}
''');
    _updateAndValidate(r'''
class A {
  int field;
  A() : field = 5;
}
''');
  }

  void test_true_wholeFunction() {
    _resolveUnit(r'''
foo() {}
main(int a) {
  print(a);
}
''');
    _updateAndValidate(r'''
foo() {}
main(int b) {
  print(b);
}
''');
  }

  void test_true_wholeFunction_firstTokenInUnit() {
    _resolveUnit(r'''
main(int a) {
  print(a);
}
''');
    _updateAndValidate(r'''
main(int b) {
  print(b);
}
''');
  }

  void test_true_wholeMethod() {
    _resolveUnit(r'''
class A {
  main(int a) {
    print(a);
  }
}
''');
    _updateAndValidate(r'''
class A {
  main(int b) {
    print(b);
  }
}
''');
  }

  void test_updateErrors_addNew_hints() {
    _resolveUnit(r'''
main() {
  int v = 0;
  print(v);
}
''');
    _updateAndValidate(r'''
main() {
  int v = 0;
}
''');
  }

  void test_updateErrors_addNew_parse() {
    _resolveUnit(r'''
main() {
  print(42);
}
''');
    _updateAndValidate(r'''
main() {
  print(42)
}
''');
  }

  void test_updateErrors_addNew_resolve() {
    _resolveUnit(r'''
main() {
  foo();
}
foo() {}
''');
    _updateAndValidate(r'''
main() {
  bar();
}
foo() {}
''');
  }

  void test_updateErrors_addNew_scan() {
    _resolveUnit(r'''
main() {
  1;
}
''');
    _updateAndValidate(r'''
main() {
  1e;
}
''');
  }

  void test_updateErrors_addNew_verify() {
    _resolveUnit(r'''
main() {
  foo(0);
}
foo(int p) {}
''');
    _updateAndValidate(r'''
main() {
  foo('abc');
}
foo(int p) {}
''');
  }

  void test_updateErrors_removeExisting() {
    _resolveUnit(r'''
f1() {
  print(1)
}
f2() {
  print(22)
}
f3() {
  print(333)
}
''');
    _updateAndValidate(r'''
f1() {
  print(1)
}
f2() {
  print(22);
}
f3() {
  print(333)
}
''');
  }

  void test_updateErrors_shiftExisting() {
    _resolveUnit(r'''
f1() {
  print(1)
}
f2() {
  print(2);
}
f3() {
  print(333)
}
''');
    _updateAndValidate(r'''
f1() {
  print(1)
}
f2() {
  print(22);
}
f3() {
  print(333)
}
''');
  }

  /**
   * Reset the analysis context to have the 'incremental' option set to the
   * given value.
   */
  void _resetWithIncremental(bool enable) {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.incremental = enable;
    analysisContext2.analysisOptions = analysisOptions;
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    oldLibrary = resolve(source);
    oldUnit = resolveCompilationUnit(source, oldLibrary);
    oldUnitElement = oldUnit.element;
  }

  void _runTasks() {
    AnalysisResult result = analysisContext.performAnalysisTask();
    while (result.changeNotices != null) {
      result = analysisContext.performAnalysisTask();
    }
  }

  void _updateAndValidate(String newCode, [bool compareWithFull = true]) {
    // Run any pending tasks tasks.
    _runTasks();
    // Update the source - currently this may cause incremental resolution.
    // Then request the updated resolved unit.
    _resetWithIncremental(true);
    analysisContext2.setContents(source, newCode);
    CompilationUnit newUnit = resolveCompilationUnit(source, oldLibrary);
    List<AnalysisError> newErrors = analysisContext.getErrors(source).errors;
    // The existing CompilationUnitElement should be updated.
    expect(newUnit.element, same(oldUnitElement));
    // The only expected pending task should return the same resolved
    // "newUnit", so all clients will get it using the usual way.
    AnalysisResult analysisResult = analysisContext.performAnalysisTask();
    ChangeNotice notice = analysisResult.changeNotices[0];
    expect(notice.compilationUnit, same(newUnit));
    // Resolve "newCode" from scratch.
    if (compareWithFull) {
      _resetWithIncremental(false);
      source = addSource(newCode);
      _runTasks();
      LibraryElement library = resolve(source);
      CompilationUnit fullNewUnit = resolveCompilationUnit(source, library);
      // Validate that "incremental" and "full" units have the same resolution.
      _SameResolutionValidator.assertSameResolution(newUnit, fullNewUnit);
      _assertEqualTokens(newUnit, fullNewUnit);
      List<AnalysisError> newFullErrors =
          analysisContext.getErrors(source).errors;
      _assertEqualErrors(newErrors, newFullErrors);
      // TODO(scheglov) check line info
    }
  }

  static void _assertEqualError(AnalysisError incrError,
      AnalysisError fullError) {
    expect(incrError.errorCode, same(fullError.errorCode));
    expect(incrError.source, fullError.source);
    expect(incrError.offset, fullError.offset);
    expect(incrError.length, fullError.length);
    expect(incrError.message, fullError.message);
  }

  static void _assertEqualErrors(List<AnalysisError> incrErrors,
      List<AnalysisError> fullErrors) {
    expect(incrErrors, hasLength(fullErrors.length));
    if (incrErrors.isNotEmpty) {
      incrErrors.sort((a, b) => a.offset - b.offset);
    }
    if (fullErrors.isNotEmpty) {
      fullErrors.sort((a, b) => a.offset - b.offset);
    }
    int length = incrErrors.length;
    for (int i = 0; i < length; i++) {
      AnalysisError incrError = incrErrors[i];
      AnalysisError fullError = fullErrors[i];
      _assertEqualError(incrError, fullError);
    }
  }

  static void _assertEqualToken(Token incrToken, Token fullToken) {
    expect(incrToken.type, fullToken.type);
    expect(incrToken.offset, fullToken.offset);
    expect(incrToken.length, fullToken.length);
    expect(incrToken.lexeme, fullToken.lexeme);
  }

  static void _assertEqualTokens(CompilationUnit incrUnit,
      CompilationUnit fullUnit) {
    Token incrToken = incrUnit.beginToken;
    Token fullToken = fullUnit.beginToken;
    while (incrToken.type != TokenType.EOF && fullToken.type != TokenType.EOF) {
//      print('$incrToken @ ${incrToken.offset}');
//      print('$fullToken @ ${fullToken.offset}');
      _assertEqualToken(incrToken, fullToken);
      incrToken = incrToken.next;
      fullToken = fullToken.next;
    }
  }
}


class ResolutionContextBuilderTest extends EngineTestCase {
  GatheringErrorListener listener = new GatheringErrorListener();

  void test_scopeFor_ClassDeclaration() {
    Scope scope = _scopeFor(_createResolvedClassDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_ClassTypeAlias() {
    Scope scope = _scopeFor(_createResolvedClassTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_CompilationUnit() {
    Scope scope = _scopeFor(_createResolvedCompilationUnit());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_ConstructorDeclaration() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope,
        ClassScope,
        scope);
  }

  void test_scopeFor_ConstructorDeclaration_parameters() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_FunctionDeclaration() {
    Scope scope = _scopeFor(_createResolvedFunctionDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_FunctionDeclaration_parameters() {
    Scope scope =
        _scopeFor(_createResolvedFunctionDeclaration().functionExpression.parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_FunctionTypeAlias() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope,
        LibraryScope,
        scope);
  }

  void test_scopeFor_FunctionTypeAlias_parameters() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionTypeScope,
        FunctionTypeScope,
        scope);
  }

  void test_scopeFor_MethodDeclaration() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope,
        ClassScope,
        scope);
  }

  void test_scopeFor_MethodDeclaration_body() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration().body);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope,
        FunctionScope,
        scope);
  }

  void test_scopeFor_notInCompilationUnit() {
    try {
      _scopeFor(AstFactory.identifier3("x"));
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_scopeFor_null() {
    try {
      _scopeFor(null);
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  void test_scopeFor_unresolved() {
    try {
      _scopeFor(AstFactory.compilationUnit());
      fail("Expected AnalysisException");
    } on AnalysisException catch (exception) {
      // Expected
    }
  }

  ClassDeclaration _createResolvedClassDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassDeclaration classNode = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList(),
        null,
        null,
        null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    return classNode;
  }

  ClassTypeAlias _createResolvedClassTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassTypeAlias classNode = AstFactory.classTypeAlias(
        className,
        AstFactory.typeParameterList(),
        null,
        null,
        null,
        null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types =
        <ClassElement>[classElement];
    return classNode;
  }

  CompilationUnit _createResolvedCompilationUnit() {
    CompilationUnit unit = AstFactory.compilationUnit();
    LibraryElementImpl library =
        ElementFactory.library(AnalysisContextFactory.contextWithCore(), "lib");
    unit.element = library.definingCompilationUnit;
    return unit;
  }

  ConstructorDeclaration _createResolvedConstructorDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String constructorName = "f";
    ConstructorDeclaration constructorNode = AstFactory.constructorDeclaration(
        AstFactory.identifier3(constructorName),
        null,
        AstFactory.formalParameterList(),
        null);
    classNode.members.add(constructorNode);
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classNode.element, null);
    constructorNode.element = constructorElement;
    (classNode.element as ClassElementImpl).constructors =
        <ConstructorElement>[constructorElement];
    return constructorNode;
  }

  FunctionDeclaration _createResolvedFunctionDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String functionName = "f";
    FunctionDeclaration functionNode = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression());
    unit.declarations.add(functionNode);
    FunctionElement functionElement =
        ElementFactory.functionElement(functionName);
    functionNode.name.staticElement = functionElement;
    (unit.element as CompilationUnitElementImpl).functions =
        <FunctionElement>[functionElement];
    return functionNode;
  }

  FunctionTypeAlias _createResolvedFunctionTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        AstFactory.typeName4("A"),
        "F",
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList());
    unit.declarations.add(aliasNode);
    SimpleIdentifier aliasName = aliasNode.name;
    FunctionTypeAliasElement aliasElement =
        new FunctionTypeAliasElementImpl.forNode(aliasName);
    aliasName.staticElement = aliasElement;
    (unit.element as CompilationUnitElementImpl).typeAliases =
        <FunctionTypeAliasElement>[aliasElement];
    return aliasNode;
  }

  MethodDeclaration _createResolvedMethodDeclaration() {
    ClassDeclaration classNode = _createResolvedClassDeclaration();
    String methodName = "f";
    MethodDeclaration methodNode = AstFactory.methodDeclaration(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    classNode.members.add(methodNode);
    MethodElement methodElement =
        ElementFactory.methodElement(methodName, null);
    methodNode.name.staticElement = methodElement;
    (classNode.element as ClassElementImpl).methods =
        <MethodElement>[methodElement];
    return methodNode;
  }

  Scope _scopeFor(AstNode node) {
    return ResolutionContextBuilder.contextFor(node, listener).scope;
  }
}


class _Edit {
  final int offset;
  final int length;
  final String replacement;
  _Edit(this.offset, this.length, this.replacement);
}


class _SameResolutionValidator implements AstVisitor {
  AstNode other;

  _SameResolutionValidator(this.other);

  @override
  visitAdjacentStrings(AdjacentStrings node) {
  }

  @override
  visitAnnotation(Annotation node) {
    Annotation other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.arguments, other.arguments);
    _verifyElement(node.element, other.element);
  }

  @override
  visitArgumentList(ArgumentList node) {
    ArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitAsExpression(AsExpression node) {
    AsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitAssertStatement(AssertStatement node) {
    AssertStatement other = this.other;
    _visitNode(node.condition, other.condition);
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    AssignmentExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftHandSide, other.leftHandSide);
    _visitNode(node.rightHandSide, other.rightHandSide);
  }

  @override
  visitAwaitExpression(AwaitExpression node) {
    AwaitExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    BinaryExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.leftOperand, other.leftOperand);
    _visitNode(node.rightOperand, other.rightOperand);
  }

  @override
  visitBlock(Block node) {
    Block other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    BlockFunctionBody other = this.other;
    _visitNode(node.block, other.block);
  }

  @override
  visitBooleanLiteral(BooleanLiteral node) {
    BooleanLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitBreakStatement(BreakStatement node) {
    BreakStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitCascadeExpression(CascadeExpression node) {
    CascadeExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitList(node.cascadeSections, other.cascadeSections);
  }

  @override
  visitCatchClause(CatchClause node) {
    CatchClause other = this.other;
    _visitNode(node.exceptionType, other.exceptionType);
    _visitNode(node.exceptionParameter, other.exceptionParameter);
    _visitNode(node.stackTraceParameter, other.stackTraceParameter);
    _visitNode(node.body, other.body);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
    ClassDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.extendsClause, other.extendsClause);
    _visitNode(node.implementsClause, other.implementsClause);
    _visitNode(node.withClause, other.withClause);
    _visitList(node.members, other.members);
  }

  @override
  visitClassTypeAlias(ClassTypeAlias node) {
    ClassTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.superclass, other.superclass);
    _visitNode(node.withClause, other.withClause);
  }

  @override
  visitComment(Comment node) {
    Comment other = this.other;
    _visitList(node.references, other.references);
  }

  @override
  visitCommentReference(CommentReference node) {
    CommentReference other = this.other;
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    CompilationUnit other = this.other;
    _verifyElement(node.element, other.element);
    _visitList(node.directives, other.directives);
    _visitList(node.declarations, other.declarations);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    ConditionalExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenExpression, other.thenExpression);
    _visitNode(node.elseExpression, other.elseExpression);
  }

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    ConstructorDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.redirectedConstructor, other.redirectedConstructor);
    _visitList(node.initializers, other.initializers);
  }

  @override
  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    ConstructorFieldInitializer other = this.other;
    _visitNode(node.fieldName, other.fieldName);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitConstructorName(ConstructorName node) {
    ConstructorName other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.type, other.type);
    _visitNode(node.name, other.name);
  }

  @override
  visitContinueStatement(ContinueStatement node) {
    ContinueStatement other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitDeclaredIdentifier(DeclaredIdentifier node) {
    DeclaredIdentifier other = this.other;
    _visitNode(node.type, other.type);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitDefaultFormalParameter(DefaultFormalParameter node) {
    DefaultFormalParameter other = this.other;
    _visitNode(node.parameter, other.parameter);
    _visitNode(node.defaultValue, other.defaultValue);
  }

  @override
  visitDoStatement(DoStatement node) {
    DoStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    DoubleLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitEmptyFunctionBody(EmptyFunctionBody node) {
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
  }

  @override
  visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    EnumConstantDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitEnumDeclaration(EnumDeclaration node) {
    EnumDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitList(node.constants, other.constants);
  }

  @override
  visitExportDirective(ExportDirective node) {
    ExportDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    ExpressionFunctionBody other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    ExpressionStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitExtendsClause(ExtendsClause node) {
    ExtendsClause other = this.other;
    _visitNode(node.superclass, other.superclass);
  }

  @override
  visitFieldDeclaration(FieldDeclaration node) {
    FieldDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.fields, other.fields);
  }

  @override
  visitFieldFormalParameter(FieldFormalParameter node) {
    FieldFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitForEachStatement(ForEachStatement node) {
    ForEachStatement other = this.other;
    _visitNode(node.identifier, other.identifier);
    _visitNode(node.loopVariable, other.loopVariable);
    _visitNode(node.iterable, other.iterable);
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    FormalParameterList other = this.other;
    _visitList(node.parameters, other.parameters);
  }

  @override
  visitForStatement(ForStatement node) {
    ForStatement other = this.other;
    _visitNode(node.variables, other.variables);
    _visitNode(node.initialization, other.initialization);
    _visitNode(node.condition, other.condition);
    _visitList(node.updaters, other.updaters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.functionExpression, other.functionExpression);
  }

  @override
  visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    FunctionDeclarationStatement other = this.other;
    _visitNode(node.functionDeclaration, other.functionDeclaration);
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    FunctionExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.element, other.element);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    FunctionExpressionInvocation other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.function, other.function);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAlias other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.name, other.name);
    _visitNode(node.typeParameters, other.typeParameters);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    FunctionTypedFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.returnType, other.returnType);
    _visitNode(node.parameters, other.parameters);
  }

  @override
  visitHideCombinator(HideCombinator node) {
    HideCombinator other = this.other;
    _visitList(node.hiddenNames, other.hiddenNames);
  }

  @override
  visitIfStatement(IfStatement node) {
    IfStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.thenStatement, other.thenStatement);
    _visitNode(node.elseStatement, other.elseStatement);
  }

  @override
  visitImplementsClause(ImplementsClause node) {
    ImplementsClause other = this.other;
    _visitList(node.interfaces, other.interfaces);
  }

  @override
  visitImportDirective(ImportDirective node) {
    ImportDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.prefix, other.prefix);
    _verifyElement(node.uriElement, other.uriElement);
  }

  @override
  visitIndexExpression(IndexExpression node) {
    IndexExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.target, other.target);
    _visitNode(node.index, other.index);
  }

  @override
  visitInstanceCreationExpression(InstanceCreationExpression node) {
    InstanceCreationExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitIntegerLiteral(IntegerLiteral node) {
    IntegerLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitInterpolationExpression(InterpolationExpression node) {
    InterpolationExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitInterpolationString(InterpolationString node) {
  }

  @override
  visitIsExpression(IsExpression node) {
    IsExpression other = this.other;
    _visitExpression(node, other);
    _visitNode(node.expression, other.expression);
    _visitNode(node.type, other.type);
  }

  @override
  visitLabel(Label node) {
    Label other = this.other;
    _visitNode(node.label, other.label);
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    LabeledStatement other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.statement, other.statement);
  }

  @override
  visitLibraryDirective(LibraryDirective node) {
    LibraryDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.name, other.name);
  }

  @override
  visitLibraryIdentifier(LibraryIdentifier node) {
    LibraryIdentifier other = this.other;
    _visitList(node.components, other.components);
  }

  @override
  visitListLiteral(ListLiteral node) {
    ListLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.elements, other.elements);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    MapLiteral other = this.other;
    _visitExpression(node, other);
    _visitList(node.entries, other.entries);
  }

  @override
  visitMapLiteralEntry(MapLiteralEntry node) {
    MapLiteralEntry other = this.other;
    _visitNode(node.key, other.key);
    _visitNode(node.value, other.value);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    MethodDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.parameters, other.parameters);
    _visitNode(node.body, other.body);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    MethodInvocation other = this.other;
    _visitNode(node.target, other.target);
    _visitNode(node.methodName, other.methodName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitNamedExpression(NamedExpression node) {
    NamedExpression other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.expression, other.expression);
  }

  @override
  visitNativeClause(NativeClause node) {
  }

  @override
  visitNativeFunctionBody(NativeFunctionBody node) {
  }

  @override
  visitNullLiteral(NullLiteral node) {
    NullLiteral other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    ParenthesizedExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitPartDirective(PartDirective node) {
    PartDirective other = this.other;
    _visitDirective(node, other);
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    PartOfDirective other = this.other;
    _visitDirective(node, other);
    _visitNode(node.libraryName, other.libraryName);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    PostfixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    PrefixedIdentifier other = this.other;
    _visitExpression(node, other);
    _visitNode(node.prefix, other.prefix);
    _visitNode(node.identifier, other.identifier);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    PrefixExpression other = this.other;
    _visitExpression(node, other);
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitNode(node.operand, other.operand);
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    PropertyAccess other = this.other;
    _visitExpression(node, other);
    _visitNode(node.target, other.target);
    _visitNode(node.propertyName, other.propertyName);
  }

  @override
  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    RedirectingConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitRethrowExpression(RethrowExpression node) {
    RethrowExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    ReturnStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitScriptTag(ScriptTag node) {
  }

  @override
  visitShowCombinator(ShowCombinator node) {
    ShowCombinator other = this.other;
    _visitList(node.shownNames, other.shownNames);
  }

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    SimpleFormalParameter other = this.other;
    _visitNormalFormalParameter(node, other);
    _visitNode(node.type, other.type);
  }

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    SimpleIdentifier other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _verifyElement(node.propagatedElement, other.propagatedElement);
    _visitExpression(node, other);
  }

  @override
  visitSimpleStringLiteral(SimpleStringLiteral node) {
  }

  @override
  visitStringInterpolation(StringInterpolation node) {
    StringInterpolation other = this.other;
    _visitList(node.elements, other.elements);
  }

  @override
  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SuperConstructorInvocation other = this.other;
    _verifyElement(node.staticElement, other.staticElement);
    _visitNode(node.constructorName, other.constructorName);
    _visitNode(node.argumentList, other.argumentList);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    SuperExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitSwitchCase(SwitchCase node) {
    SwitchCase other = this.other;
    _visitList(node.labels, other.labels);
    _visitNode(node.expression, other.expression);
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchDefault(SwitchDefault node) {
    SwitchDefault other = this.other;
    _visitList(node.statements, other.statements);
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    SwitchStatement other = this.other;
    _visitNode(node.expression, other.expression);
    _visitList(node.members, other.members);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
  }

  @override
  visitThisExpression(ThisExpression node) {
    ThisExpression other = this.other;
    _visitExpression(node, other);
  }

  @override
  visitThrowExpression(ThrowExpression node) {
    ThrowExpression other = this.other;
    _visitNode(node.expression, other.expression);
  }

  @override
  visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    TopLevelVariableDeclaration other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitTryStatement(TryStatement node) {
    TryStatement other = this.other;
    _visitNode(node.body, other.body);
    _visitList(node.catchClauses, other.catchClauses);
    _visitNode(node.finallyBlock, other.finallyBlock);
  }

  @override
  visitTypeArgumentList(TypeArgumentList node) {
    TypeArgumentList other = this.other;
    _visitList(node.arguments, other.arguments);
  }

  @override
  visitTypeName(TypeName node) {
    TypeName other = this.other;
    _verifyType(node.type, other.type);
    _visitNode(node.name, node.name);
    _visitNode(node.typeArguments, other.typeArguments);
  }

  @override
  visitTypeParameter(TypeParameter node) {
    TypeParameter other = this.other;
    _visitNode(node.name, other.name);
    _visitNode(node.bound, other.bound);
  }

  @override
  visitTypeParameterList(TypeParameterList node) {
    TypeParameterList other = this.other;
    _visitList(node.typeParameters, other.typeParameters);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    VariableDeclaration other = this.other;
    _visitDeclaration(node, other);
    _visitNode(node.name, other.name);
    _visitNode(node.initializer, other.initializer);
  }

  @override
  visitVariableDeclarationList(VariableDeclarationList node) {
    VariableDeclarationList other = this.other;
    _visitNode(node.type, other.type);
    _visitList(node.variables, other.variables);
  }

  @override
  visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    VariableDeclarationStatement other = this.other;
    _visitNode(node.variables, other.variables);
  }

  @override
  visitWhileStatement(WhileStatement node) {
    WhileStatement other = this.other;
    _visitNode(node.condition, other.condition);
    _visitNode(node.body, other.body);
  }

  @override
  visitWithClause(WithClause node) {
    WithClause other = this.other;
    _visitList(node.mixinTypes, other.mixinTypes);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    YieldStatement other = this.other;
    _visitNode(node.expression, other.expression);
  }

  void _verifyElement(Element a, Element b) {
    if (a != b) {
      fail('Expected: $b\n  Actual: $a');
    }
    if (a == null && b == null) {
      return;
    }
    if (a.nameOffset != b.nameOffset) {
      fail('Expected: ${b.nameOffset}\n  Actual: ${a.nameOffset}');
    }
  }

  void _verifyType(DartType a, DartType b) {
    expect(a, equals(b));
  }

  void _visitAnnotatedNode(AnnotatedNode node, AnnotatedNode other) {
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
  }

  _visitDeclaration(Declaration node, Declaration other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  _visitDirective(Directive node, Directive other) {
    _verifyElement(node.element, other.element);
    _visitAnnotatedNode(node, other);
  }

  void _visitExpression(Expression a, Expression b) {
    _verifyType(a.staticType, b.staticType);
    _verifyType(a.propagatedType, b.propagatedType);
    _verifyElement(a.staticParameterElement, b.staticParameterElement);
    _verifyElement(a.propagatedParameterElement, b.propagatedParameterElement);
  }

  void _visitList(NodeList nodeList, NodeList otherList) {
    int length = nodeList.length;
    expect(otherList, hasLength(length));
    for (int i = 0; i < length; i++) {
      _visitNode(nodeList[i], otherList[i]);
    }
  }

  void _visitNode(AstNode node, AstNode other) {
    if (node == null) {
      expect(other, isNull);
    } else {
      this.other = other;
      node.accept(this);
    }
  }

  void _visitNormalFormalParameter(NormalFormalParameter node,
      NormalFormalParameter other) {
    _verifyElement(node.element, other.element);
    _visitNode(node.documentationComment, other.documentationComment);
    _visitList(node.metadata, other.metadata);
    _visitNode(node.identifier, other.identifier);
  }

  static void assertSameResolution(CompilationUnit actual,
      CompilationUnit expected) {
    _SameResolutionValidator validator = new _SameResolutionValidator(expected);
    actual.accept(validator);
  }
}
