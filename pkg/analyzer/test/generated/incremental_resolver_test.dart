// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.incremental_resolver_test;

import 'package:analyzer/src/context/cache.dart' as task;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/incremental_logger.dart' as log;
import 'package:analyzer/src/generated/incremental_resolution_validator.dart';
import 'package:analyzer/src/generated/incremental_resolver.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/task/dart.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'parser_test.dart';
import 'resolver_test.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(DeclarationMatcherTest);
  runReflectiveTests(IncrementalResolverTest);
  runReflectiveTests(PoorMansIncrementalResolutionTest);
  runReflectiveTests(ResolutionContextBuilderTest);
}

void initializeTestEnvironment() {}

void _assertEqualError(AnalysisError incrError, AnalysisError fullError) {
  expect(incrError.errorCode, same(fullError.errorCode));
  expect(incrError.source, fullError.source);
  expect(incrError.offset, fullError.offset);
  expect(incrError.length, fullError.length);
  expect(incrError.message, fullError.message);
}

void _assertEqualErrors(
    List<AnalysisError> incrErrors, List<AnalysisError> fullErrors) {
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

@reflectiveTest
class DeclarationMatcherTest extends ResolverTestCase {
  void setUp() {
    super.setUp();
    test_resolveApiChanges = true;
  }

  void test_false_class_annotation_accessor_edit() {
    _assertDoesNotMatch(
        r'''
const my_annotationA = const Object();
const my_annotationB = const Object();
@my_annotationA
class A {
}
''',
        r'''
const my_annotationA = const Object();
const my_annotationB = const Object();
@my_annotationB
class A {
}
''');
  }

  void test_false_class_annotation_constructor_edit() {
    _assertDoesNotMatch(
        r'''
class MyAnnotationA {
  const MyAnnotationA();
}
class MyAnnotationB {
  const MyAnnotationB();
}
@MyAnnotationA()
class A {
}
''',
        r'''
class MyAnnotationA {
  const MyAnnotationA();
}
class MyAnnotationB {
  const MyAnnotationB();
}
@MyAnnotationB()
class A {
}
''');
  }

  void test_false_class_annotations_add() {
    _assertDoesNotMatch(
        r'''
const my_annotation = const Object();
class A {
}
''',
        r'''
const my_annotation = const Object();
@my_annotation
class A {
}
''');
  }

  void test_false_class_annotations_remove() {
    _assertDoesNotMatch(
        r'''
const my_annotation = const Object();
@my_annotation
class A {
}
''',
        r'''
const my_annotation = const Object();
class A {
}
''');
  }

  void test_false_class_list_add() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B {}
class C {}
''');
  }

  void test_false_class_list_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
class C {}
''',
        r'''
class A {}
class B {}
''');
  }

  void test_false_class_typeParameters_bounds_add() {
    _assertDoesNotMatch(
        r'''
class A {}
class B<T> {
  T f;
}
''',
        r'''
class A {}
class B<T extends A> {
  T f;
}
''');
  }

  void test_false_class_typeParameters_bounds_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
class B<T extends A> {
  T f;
}
''',
        r'''
class A {}
class B<T> {
  T f;
}
''');
  }

  void test_false_classMemberAccessor_list_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  get a => 1;
  get b => 2;
}
''',
        r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''');
  }

  void test_false_classMemberAccessor_list_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''',
        r'''
class A {
  get a => 1;
  get b => 2;
}
''');
  }

  void test_false_classMemberAccessor_wasGetter() {
    _assertDoesNotMatchOK(
        r'''
class A {
  get a => 1;
}
''',
        r'''
class A {
  set a(x) {}
}
''');
  }

  void test_false_classMemberAccessor_wasInstance() {
    _assertDoesNotMatchOK(
        r'''
class A {
  get a => 1;
}
''',
        r'''
class A {
  static get a => 1;
}
''');
  }

  void test_false_classMemberAccessor_wasSetter() {
    _assertDoesNotMatchOK(
        r'''
class A {
  set a(x) {}
}
''',
        r'''
class A {
  get a => 1;
}
''');
  }

  void test_false_classMemberAccessor_wasStatic() {
    _assertDoesNotMatchOK(
        r'''
class A {
  static get a => 1;
}
''',
        r'''
class A {
  get a => 1;
}
''');
  }

  void test_false_classTypeAlias_list_add() {
    _assertDoesNotMatch(
        r'''
class M {}
class A = Object with M;
''',
        r'''
class M {}
class A = Object with M;
class B = Object with M;
''');
  }

  void test_false_classTypeAlias_list_remove() {
    _assertDoesNotMatch(
        r'''
class M {}
class A = Object with M;
class B = Object with M;
''',
        r'''
class M {}
class A = Object with M;
''');
  }

  void test_false_classTypeAlias_typeParameters_bounds_add() {
    _assertDoesNotMatch(
        r'''
class M<T> {}
class A {}
class B<T> = Object with M<T>;
''',
        r'''
class M<T> {}
class A {}
class B<T extends A> = Object with M<T>;
''');
  }

  void test_false_classTypeAlias_typeParameters_bounds_remove() {
    _assertDoesNotMatch(
        r'''
class M<T> {}
class A {}
class B<T extends A> = Object with M<T>;
''',
        r'''
class M<T> {}
class A {}
class B<T> = Object with M<T>;
''');
  }

  void test_false_constructor_keywordConst_add() {
    _assertDoesNotMatch(
        r'''
class A {
  A();
}
''',
        r'''
class A {
  const A();
}
''');
  }

  void test_false_constructor_keywordConst_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  const A();
}
''',
        r'''
class A {
  A();
}
''');
  }

  void test_false_constructor_keywordFactory_add() {
    _assertDoesNotMatch(
        r'''
class A {
  A();
  A.foo() {
    return new A();
  }
}
''',
        r'''
class A {
  A();
  factory A.foo() {
    return new A();
  }
}
''');
  }

  void test_false_constructor_keywordFactory_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  A();
  factory A.foo() {
    return new A();
  }
}
''',
        r'''
class A {
  A();
  A.foo() {
    return new A();
  }
}
''');
  }

  void test_false_constructor_parameters_list_add() {
    _assertDoesNotMatch(
        r'''
class A {
  A();
}
''',
        r'''
class A {
  A(int p);
}
''');
  }

  void test_false_constructor_parameters_list_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  A(int p);
}
''',
        r'''
class A {
  A();
}
''');
  }

  void test_false_constructor_parameters_type_edit() {
    _assertDoesNotMatch(
        r'''
class A {
  A(int p);
}
''',
        r'''
class A {
  A(String p);
}
''');
  }

  void test_false_constructor_unnamed_add_hadParameters() {
    _assertDoesNotMatch(
        r'''
class A {
}
''',
        r'''
class A {
  A(int p) {}
}
''');
  }

  void test_false_constructor_unnamed_remove_hadParameters() {
    _assertDoesNotMatch(
        r'''
class A {
  A(int p) {}
}
''',
        r'''
class A {
}
''');
  }

  void test_false_defaultFieldFormalParameterElement_wasSimple() {
    _assertDoesNotMatch(
        r'''
class A {
  int field;
  A(int field);
}
''',
        r'''
class A {
  int field;
  A([this.field = 0]);
}
''');
  }

  void test_false_enum_constants_add() {
    _assertDoesNotMatch(
        r'''
enum E {A, B}
''',
        r'''
enum E {A, B, C}
''');
  }

  void test_false_enum_constants_remove() {
    _assertDoesNotMatch(
        r'''
enum E {A, B, C}
''',
        r'''
enum E {A, B}
''');
  }

  void test_false_export_hide_add() {
    _assertDoesNotMatch(
        r'''
export 'dart:async' hide Future;
''',
        r'''
export 'dart:async' hide Future, Stream;
''');
  }

  void test_false_export_hide_remove() {
    _assertDoesNotMatch(
        r'''
export 'dart:async' hide Future, Stream;
''',
        r'''
export 'dart:async' hide Future;
''');
  }

  void test_false_export_list_add() {
    _assertDoesNotMatch(
        r'''
export 'dart:async';
''',
        r'''
export 'dart:async';
export 'dart:math';
''');
  }

  void test_false_export_list_remove() {
    _assertDoesNotMatch(
        r'''
export 'dart:async';
export 'dart:math';
''',
        r'''
export 'dart:async';
''');
  }

  void test_false_export_show_add() {
    _assertDoesNotMatch(
        r'''
export 'dart:async' show Future;
''',
        r'''
export 'dart:async' show Future, Stream;
''');
  }

  void test_false_export_show_remove() {
    _assertDoesNotMatch(
        r'''
export 'dart:async' show Future, Stream;
''',
        r'''
export 'dart:async' show Future;
''');
  }

  void test_false_extendsClause_add() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B extends A {}
''');
  }

  void test_false_extendsClause_different() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
class C extends A {}
''',
        r'''
class A {}
class B {}
class C extends B {}
''');
  }

  void test_false_extendsClause_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
class B extends A{}
''',
        r'''
class A {}
class B {}
''');
  }

  void test_false_field_list_add() {
    _assertDoesNotMatch(
        r'''
class T {
  int A = 1;
  int C = 3;
}
''',
        r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_false_field_list_remove() {
    _assertDoesNotMatch(
        r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''',
        r'''
class T {
  int A = 1;
  int C = 3;
}
''');
  }

  void test_false_field_modifier_isConst() {
    _assertDoesNotMatch(
        r'''
class T {
  static final A = 1;
}
''',
        r'''
class T {
  static const A = 1;
}
''');
  }

  void test_false_field_modifier_isFinal() {
    _assertDoesNotMatch(
        r'''
class T {
  int A = 1;
}
''',
        r'''
class T {
  final int A = 1;
}
''');
  }

  void test_false_field_modifier_isStatic() {
    _assertDoesNotMatch(
        r'''
class T {
  int A = 1;
}
''',
        r'''
class T {
  static int A = 1;
}
''');
  }

  void test_false_field_modifier_wasConst() {
    _assertDoesNotMatch(
        r'''
class T {
  static const A = 1;
}
''',
        r'''
class T {
  static final A = 1;
}
''');
  }

  void test_false_field_modifier_wasFinal() {
    _assertDoesNotMatch(
        r'''
class T {
  final int A = 1;
}
''',
        r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_modifier_wasStatic() {
    _assertDoesNotMatch(
        r'''
class T {
  static int A = 1;
}
''',
        r'''
class T {
  int A = 1;
}
''');
  }

  void test_false_field_type_differentArgs() {
    _assertDoesNotMatch(
        r'''
class T {
  List<int> A;
}
''',
        r'''
class T {
  List<String> A;
}
''');
  }

  void test_false_fieldFormalParameter_add() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(field);
}
''',
        r'''
class A {
  final field;
  A(this.field);
}
''');
  }

  void test_false_fieldFormalParameter_add_function() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(field(a));
}
''',
        r'''
class A {
  final field;
  A(this.field(a));
}
''');
  }

  void test_false_fieldFormalParameter_parameters_add() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(this.field(a));
}
''',
        r'''
class A {
  final field;
  A(this.field(a, b));
}
''');
  }

  void test_false_fieldFormalParameter_parameters_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(this.field(a, b));
}
''',
        r'''
class A {
  final field;
  A(this.field(a));
}
''');
  }

  void test_false_fieldFormalParameter_parameters_typeEdit() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(this.field(int p));
}
''',
        r'''
class A {
  final field;
  A(this.field(String p));
}
''');
  }

  void test_false_fieldFormalParameter_remove_default() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A([this.field = 0]);
}
''',
        r'''
class A {
  final field;
  A([field = 0]);
}
''');
  }

  void test_false_fieldFormalParameter_remove_function() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(this.field(a));
}
''',
        r'''
class A {
  final field;
  A(field(a));
}
''');
  }

  void test_false_fieldFormalParameter_remove_normal() {
    _assertDoesNotMatch(
        r'''
class A {
  final field;
  A(this.field);
}
''',
        r'''
class A {
  final field;
  A(field);
}
''');
  }

  void test_false_fieldFormalParameterElement_wasSimple() {
    _assertDoesNotMatch(
        r'''
class A {
  int field;
  A(int field);
}
''',
        r'''
class A {
  int field;
  A(this.field);
}
''');
  }

  void test_false_final_type_different() {
    _assertDoesNotMatch(
        r'''
class T {
  int A;
}
''',
        r'''
class T {
  String A;
}
''');
  }

  void test_false_function_async_add() {
    _assertDoesNotMatch(
        r'''
main() {}
''',
        r'''
main() async {}
''');
  }

  void test_false_function_async_remove() {
    _assertDoesNotMatch(
        r'''
main() async {}
''',
        r'''
main() {}
''');
  }

  void test_false_function_generator_add() {
    _assertDoesNotMatch(
        r'''
main() async {}
''',
        r'''
main() async* {}
''');
  }

  void test_false_function_generator_remove() {
    _assertDoesNotMatch(
        r'''
main() async* {}
''',
        r'''
main() async {}
''');
  }

  void test_false_functionTypeAlias_list_add() {
    _assertDoesNotMatch(
        r'''
typedef A(int pa);
typedef B(String pb);
''',
        r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''');
  }

  void test_false_functionTypeAlias_list_remove() {
    _assertDoesNotMatch(
        r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''',
        r'''
typedef A(int pa);
typedef B(String pb);
''');
  }

  void test_false_functionTypeAlias_parameters_list_add() {
    _assertDoesNotMatch(
        r'''
typedef A(a);
''',
        r'''
typedef A(a, b);
''');
  }

  void test_false_functionTypeAlias_parameters_list_remove() {
    _assertDoesNotMatch(
        r'''
typedef A(a, b);
''',
        r'''
typedef A(a);
''');
  }

  void test_false_functionTypeAlias_parameters_type_edit() {
    _assertDoesNotMatch(
        r'''
typedef A(int p);
''',
        r'''
typedef A(String p);
''');
  }

  void test_false_functionTypeAlias_returnType_edit() {
    _assertDoesNotMatch(
        r'''
typedef int A();
''',
        r'''
typedef String A();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_add() {
    _assertDoesNotMatch(
        r'''
class A {}
typedef F<T>();
''',
        r'''
class A {}
typedef F<T extends A>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_edit() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
typedef F<T extends A>();
''',
        r'''
class A {}
typedef F<T extends B>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_bounds_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
typedef F<T extends A>();
''',
        r'''
class A {}
typedef F<T>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_list_add() {
    _assertDoesNotMatch(
        r'''
typedef F<A>();
''',
        r'''
typedef F<A, B>();
''');
  }

  void test_false_functionTypeAlias_typeParameters_list_remove() {
    _assertDoesNotMatch(
        r'''
typedef F<A, B>();
''',
        r'''
typedef F<A>();
''');
  }

  void test_false_FunctionTypedFormalParameter_parameters_list_add() {
    _assertDoesNotMatch(
        r'''
main(int callback(int a)) {
}
''',
        r'''
main(int callback(int a, String b)) {
}
''');
  }

  void test_false_FunctionTypedFormalParameter_parameters_list_remove() {
    _assertDoesNotMatch(
        r'''
main(int callback(int a, String b)) {
}
''',
        r'''
main(int callback(int a)) {
}
''');
  }

  void test_false_FunctionTypedFormalParameter_parameterType() {
    _assertDoesNotMatch(
        r'''
main(int callback(int p)) {
}
''',
        r'''
main(int callback(String p)) {
}
''');
  }

  void test_false_FunctionTypedFormalParameter_returnType() {
    _assertDoesNotMatch(
        r'''
main(int callback()) {
}
''',
        r'''
main(String callback()) {
}
''');
  }

  void test_false_FunctionTypedFormalParameter_wasSimple() {
    _assertDoesNotMatch(
        r'''
main(int callback) {
}
''',
        r'''
main(int callback(int a, String b)) {
}
''');
  }

  void test_false_getter_body_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  int get foo;
}
''',
        r'''
class A {
  int get foo => 0;
}
''');
  }

  void test_false_getter_body_remove() {
    _assertDoesNotMatchOK(
        r'''
class A {
  int get foo => 0;
}
''',
        r'''
class A {
  int get foo;
}
''');
  }

  void test_false_implementsClause_add() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B implements A {}
''');
  }

  void test_false_implementsClause_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
class B implements A {}
''',
        r'''
class A {}
class B {}
''');
  }

  void test_false_implementsClause_reorder() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
class C implements A, B {}
''',
        r'''
class A {}
class B {}
class C implements B, A {}
''');
  }

  void test_false_import_hide_add() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' hide Future;
''',
        r'''
import 'dart:async' hide Future, Stream;
''');
  }

  void test_false_import_hide_remove() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' hide Future, Stream;
''',
        r'''
import 'dart:async' hide Future;
''');
  }

  void test_false_import_list_add() {
    _assertDoesNotMatch(
        r'''
import 'dart:async';
''',
        r'''
import 'dart:async';
import 'dart:math';
''');
  }

  void test_false_import_list_remove() {
    _assertDoesNotMatch(
        r'''
import 'dart:async';
import 'dart:math';
''',
        r'''
import 'dart:async';
''');
  }

  void test_false_import_prefix_add() {
    _assertDoesNotMatch(
        r'''
import 'dart:async';
''',
        r'''
import 'dart:async' as async;
''');
  }

  void test_false_import_prefix_edit() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' as oldPrefix;
''',
        r'''
import 'dart:async' as newPrefix;
''');
  }

  void test_false_import_prefix_remove() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' as async;
''',
        r'''
import 'dart:async';
''');
  }

  void test_false_import_show_add() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' show Future;
''',
        r'''
import 'dart:async' show Future, Stream;
''');
  }

  void test_false_import_show_remove() {
    _assertDoesNotMatch(
        r'''
import 'dart:async' show Future, Stream;
''',
        r'''
import 'dart:async' show Future;
''');
  }

  void test_false_method_annotation_edit() {
    _assertDoesNotMatchOK(
        r'''
const my_annotationA = const Object();
const my_annotationB = const Object();
class A {
  @my_annotationA
  void m() {}
}
''',
        r'''
const my_annotationA = const Object();
const my_annotationB = const Object();
class A {
  @my_annotationB
  void m() {}
}
''');
  }

  void test_false_method_annotations_add() {
    _assertDoesNotMatchOK(
        r'''
const my_annotation = const Object();
class A {
  void m() {}
}
''',
        r'''
const my_annotation = const Object();
class A {
  @my_annotation
  void m() {}
}
''');
  }

  void test_false_method_annotations_remove() {
    _assertDoesNotMatchOK(
        r'''
const my_annotation = const Object();
class A {
  @my_annotation
  void m() {}
}
''',
        r'''
const my_annotation = const Object();
class A {
  void m() {}
}
''');
  }

  void test_false_method_async_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  m() {}
}
''',
        r'''
class A {
  m() async {}
}
''');
  }

  void test_false_method_async_remove() {
    _assertDoesNotMatchOK(
        r'''
class A {
  m() async {}
}
''',
        r'''
class A {
  m() {}
}
''');
  }

  void test_false_method_body_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  void foo();
}
''',
        r'''
class A {
  void foo() {}
}
''');
  }

  void test_false_method_body_remove() {
    _assertDoesNotMatchOK(
        r'''
class A {
  void foo() {}
}
''',
        r'''
class A {
  void foo();
}
''');
  }

  void test_false_method_generator_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  m() async {}
}
''',
        r'''
class A {
  m() async* {}
}
''');
  }

  void test_false_method_generator_remove() {
    _assertDoesNotMatchOK(
        r'''
class A {
  m() async* {}
}
''',
        r'''
class A {
  m() async {}
}
''');
  }

  void test_false_method_list_add() {
    _assertDoesNotMatchOK(
        r'''
class A {
  a() {}
  b() {}
}
''',
        r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  void test_false_method_list_remove() {
    _assertDoesNotMatch(
        r'''
class A {
  a() {}
  b() {}
  c() {}
}
''',
        r'''
class A {
  a() {}
  b() {}
}
''');
  }

  void test_false_method_parameters_type_edit() {
    _assertDoesNotMatchOK(
        r'''
class A {
  m(int p) {
  }
}
''',
        r'''
class A {
  m(String p) {
  }
}
''');
  }

  void test_false_method_parameters_type_edit_insertImportPrefix() {
    _assertDoesNotMatchOK(
        r'''
import 'dart:async' as a;

class C {
  void foo(Future f) {}
}

class Future {}

bar(C c, a.Future f) {
  c.foo(f);
}
''',
        r'''
import 'dart:async' as a;

class C {
  void foo(a.Future f) {}
}

class Future {}

bar(C c, a.Future f) {
  c.foo(f);
}
''');
  }

  void test_false_method_returnType_edit() {
    _assertDoesNotMatchOK(
        r'''
class A {
  int m() {}
}
''',
        r'''
class A {
  String m() {}
}
''');
  }

  void test_false_part_list_add() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertDoesNotMatch(
        r'''
library lib;
part 'unitA.dart';
''',
        r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
  }

  void test_false_part_list_remove() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertDoesNotMatch(
        r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''',
        r'''
library lib;
part 'unitA.dart';
''');
  }

  void test_false_SimpleFormalParameter_named_differentName() {
    _assertDoesNotMatch(
        r'''
main({int oldName}) {
}
''',
        r'''
main({int newName}) {
}
''');
  }

  void test_false_SimpleFormalParameter_namedDefault_addValue() {
    _assertDoesNotMatch(
        r'''
main({int p}) {
}
''',
        r'''
main({int p: 2}) {
}
''');
  }

  void test_false_SimpleFormalParameter_namedDefault_differentValue() {
    _assertDoesNotMatch(
        r'''
main({int p: 1}) {
}
''',
        r'''
main({int p: 2}) {
}
''');
  }

  void test_false_SimpleFormalParameter_namedDefault_removeValue() {
    _assertDoesNotMatch(
        r'''
main({int p: 1}) {
}
''',
        r'''
main({int p}) {
}
''');
  }

  void test_false_SimpleFormalParameter_optionalDefault_addValue() {
    _assertDoesNotMatch(
        r'''
main([int p]) {
}
''',
        r'''
main([int p = 2]) {
}
''');
  }

  void test_false_SimpleFormalParameter_optionalDefault_differentValue() {
    _assertDoesNotMatch(
        r'''
main([int p = 1]) {
}
''',
        r'''
main([int p = 2]) {
}
''');
  }

  void test_false_SimpleFormalParameter_optionalDefault_removeValue() {
    _assertDoesNotMatch(
        r'''
main([int p = 1]) {
}
''',
        r'''
main([int p]) {
}
''');
  }

  void test_false_topLevelAccessor_list_add() {
    _assertDoesNotMatch(
        r'''
get a => 1;
get b => 2;
''',
        r'''
get a => 1;
get b => 2;
get c => 3;
''');
  }

  void test_false_topLevelAccessor_list_remove() {
    _assertDoesNotMatch(
        r'''
get a => 1;
get b => 2;
get c => 3;
''',
        r'''
get a => 1;
get b => 2;
''');
  }

  void test_false_topLevelAccessor_wasGetter() {
    _assertDoesNotMatch(
        r'''
get a => 1;
''',
        r'''
set a(x) {}
''');
  }

  void test_false_topLevelAccessor_wasSetter() {
    _assertDoesNotMatch(
        r'''
set a(x) {}
''',
        r'''
get a => 1;
''');
  }

  void test_false_topLevelFunction_list_add() {
    _assertDoesNotMatch(
        r'''
a() {}
b() {}
''',
        r'''
a() {}
b() {}
c() {}
''');
  }

  void test_false_topLevelFunction_list_remove() {
    _assertDoesNotMatch(
        r'''
a() {}
b() {}
c() {}
''',
        r'''
a() {}
b() {}
''');
  }

  void test_false_topLevelFunction_parameters_list_add() {
    _assertDoesNotMatch(
        r'''
main(int a, int b) {
}
''',
        r'''
main(int a, int b, int c) {
}
''');
  }

  void test_false_topLevelFunction_parameters_list_remove() {
    _assertDoesNotMatch(
        r'''
main(int a, int b, int c) {
}
''',
        r'''
main(int a, int b) {
}
''');
  }

  void test_false_topLevelFunction_parameters_type_edit() {
    _assertDoesNotMatch(
        r'''
main(int a, int b, int c) {
}
''',
        r'''
main(int a, String b, int c) {
}
''');
  }

  void test_false_topLevelFunction_returnType_edit() {
    _assertDoesNotMatch(
        r'''
int a() {}
''',
        r'''
String a() {}
''');
  }

  void test_false_topLevelVariable_list_add() {
    _assertDoesNotMatch(
        r'''
const int A = 1;
const int C = 3;
''',
        r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_list_remove() {
    _assertDoesNotMatch(
        r'''
const int A = 1;
const int B = 2;
const int C = 3;
''',
        r'''
const int A = 1;
const int C = 3;
''');
  }

  void test_false_topLevelVariable_modifier_isConst() {
    _assertDoesNotMatch(
        r'''
final int A = 1;
''',
        r'''
const int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_isFinal() {
    _assertDoesNotMatch(
        r'''
int A = 1;
''',
        r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasConst() {
    _assertDoesNotMatch(
        r'''
const int A = 1;
''',
        r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_modifier_wasFinal() {
    _assertDoesNotMatch(
        r'''
final int A = 1;
''',
        r'''
int A = 1;
''');
  }

  void test_false_topLevelVariable_synthetic_wasGetter() {
    _assertDoesNotMatch(
        r'''
int get A => 1;
''',
        r'''
final int A = 1;
''');
  }

  void test_false_topLevelVariable_type_different() {
    _assertDoesNotMatch(
        r'''
int A;
''',
        r'''
String A;
''');
  }

  void test_false_topLevelVariable_type_differentArgs() {
    _assertDoesNotMatch(
        r'''
List<int> A;
''',
        r'''
List<String> A;
''');
  }

  void test_false_type_noTypeArguments_hadTypeArguments() {
    _assertDoesNotMatch(
        r'''
class A<T> {}
A<int> main() {
}
''',
        r'''
class A<T> {}
A main() {
}
''');
  }

  void test_false_withClause_add() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
''',
        r'''
class A {}
class B extends Object with A {}
''');
  }

  void test_false_withClause_remove() {
    _assertDoesNotMatch(
        r'''
class A {}
class B extends Object with A {}
''',
        r'''
class A {}
class B {}
''');
  }

  void test_false_withClause_reorder() {
    _assertDoesNotMatch(
        r'''
class A {}
class B {}
class C extends Object with A, B {}
''',
        r'''
class A {}
class B {}
class C extends Object with B, A {}
''');
  }

  void test_true_class_annotations_same() {
    _assertMatches(
        r'''
const my_annotation = const Object();
@my_annotation
class A {
}
''',
        r'''
const my_annotation = const Object();
@my_annotation
class A {
}
''');
  }

  void test_true_class_list_reorder() {
    _assertMatches(
        r'''
class A {}
class B {}
class C {}
''',
        r'''
class C {}
class A {}
class B {}
''');
  }

  void test_true_class_list_same() {
    _assertMatches(
        r'''
class A {}
class B {}
class C {}
''',
        r'''
class A {}
class B {}
class C {}
''');
  }

  void test_true_class_typeParameters_same() {
    _assertMatches(
        r'''
class A<T> {}
''',
        r'''
class A<T> {}
''');
  }

  void test_true_classMemberAccessor_getterSetter() {
    _assertMatches(
        r'''
class A {
  int _test;
  get test => _test;
  set test(v) {
    _test = v;
  }
}
''',
        r'''
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
    _assertMatches(
        r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''',
        r'''
class A {
  get c => 3;
  get a => 1;
  get b => 2;
}
''');
  }

  void test_true_classMemberAccessor_list_same() {
    _assertMatches(
        r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''',
        r'''
class A {
  get a => 1;
  get b => 2;
  get c => 3;
}
''');
  }

  void test_true_classTypeAlias_list_reorder() {
    _assertMatches(
        r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''',
        r'''
class M {}
class C = Object with M;
class A = Object with M;
class B = Object with M;
''');
  }

  void test_true_classTypeAlias_list_same() {
    _assertMatches(
        r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''',
        r'''
class M {}
class A = Object with M;
class B = Object with M;
class C = Object with M;
''');
  }

  void test_true_classTypeAlias_typeParameters_same() {
    _assertMatches(
        r'''
class M<T> {}
class A<T> {}
class B<T> = A<T> with M<T>;
''',
        r'''
class M<T> {}
class A<T> {}
class B<T> = A<T> with M<T>;
''');
  }

  void test_true_constructor_body_add() {
    _assertMatches(
        r'''
class A {
  A(int p);
}
''',
        r'''
class A {
  A(int p) {}
}
''');
  }

  void test_true_constructor_body_remove() {
    _assertMatches(
        r'''
class A {
  A(int p) {}
}
''',
        r'''
class A {
  A(int p);
}
''');
  }

  void test_true_constructor_named_same() {
    _assertMatches(
        r'''
class A {
  A.name(int p);
}
''',
        r'''
class A {
  A.name(int p);
}
''');
  }

  void test_true_constructor_unnamed_add_noParameters() {
    _assertMatches(
        r'''
class A {
}
''',
        r'''
class A {
  A() {}
}
''');
  }

  void test_true_constructor_unnamed_remove_noParameters() {
    _assertMatches(
        r'''
class A {
  A() {}
}
''',
        r'''
class A {
}
''');
  }

  void test_true_constructor_unnamed_same() {
    _assertMatches(
        r'''
class A {
  A(int p);
}
''',
        r'''
class A {
  A(int p);
}
''');
  }

  void test_true_defaultFieldFormalParameterElement() {
    _assertMatches(
        r'''
class A {
  int field;
  A([this.field = 0]);
}
''',
        r'''
class A {
  int field;
  A([this.field = 0]);
}
''');
  }

  void test_true_enum_constants_reorder() {
    _assertMatches(
        r'''
enum E {A, B, C}
''',
        r'''
enum E {C, A, B}
''');
  }

  void test_true_enum_list_reorder() {
    _assertMatches(
        r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''',
        r'''
enum C {C1, C2, C3}
enum A {A1, A2, A3}
enum B {B1, B2, B3}
''');
  }

  void test_true_enum_list_same() {
    _assertMatches(
        r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''',
        r'''
enum A {A1, A2, A3}
enum B {B1, B2, B3}
enum C {C1, C2, C3}
''');
  }

  void test_true_executable_same_hasLabel() {
    _assertMatches(
        r'''
main() {
  label: return 42;
}
''',
        r'''
main() {
  label: return 42;
}
''');
  }

  void test_true_executable_same_hasLocalVariable() {
    _assertMatches(
        r'''
main() {
  int a = 42;
}
''',
        r'''
main() {
  int a = 42;
}
''');
  }

  void test_true_export_hide_reorder() {
    _assertMatches(
        r'''
export 'dart:async' hide Future, Stream;
''',
        r'''
export 'dart:async' hide Stream, Future;
''');
  }

  void test_true_export_list_reorder() {
    _assertMatches(
        r'''
export 'dart:async';
export 'dart:math';
''',
        r'''
export 'dart:math';
export 'dart:async';
''');
  }

  void test_true_export_list_same() {
    _assertMatches(
        r'''
export 'dart:async';
export 'dart:math';
''',
        r'''
export 'dart:async';
export 'dart:math';
''');
  }

  void test_true_export_show_reorder() {
    _assertMatches(
        r'''
export 'dart:async' show Future, Stream;
''',
        r'''
export 'dart:async' show Stream, Future;
''');
  }

  void test_true_extendsClause_same() {
    _assertMatches(
        r'''
class A {}
class B extends A {}
''',
        r'''
class A {}
class B extends A {}
''');
  }

  void test_true_field_list_reorder() {
    _assertMatches(
        r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''',
        r'''
class T {
  int C = 3;
  int A = 1;
  int B = 2;
}
''');
  }

  void test_true_field_list_same() {
    _assertMatches(
        r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''',
        r'''
class T {
  int A = 1;
  int B = 2;
  int C = 3;
}
''');
  }

  void test_true_fieldFormalParameter() {
    _assertMatches(
        r'''
class A {
  int field;
  A(this.field);
}
''',
        r'''
class A {
  int field;
  A(this.field);
}
''');
  }

  void test_true_fieldFormalParameter_function() {
    _assertMatches(
        r'''
class A {
  final field;
  A(this.field(int a, String b));
}
''',
        r'''
class A {
  final field;
  A(this.field(int a, String b));
}
''');
  }

  void test_true_functionTypeAlias_list_reorder() {
    _assertMatches(
        r'''
typedef A(int pa);
typedef B(String pb);
typedef C(pc);
''',
        r'''
typedef C(pc);
typedef A(int pa);
typedef B(String pb);
''');
  }

  void test_true_functionTypeAlias_list_same() {
    _assertMatches(
        r'''
typedef String A(int pa);
typedef int B(String pb);
typedef C(pc);
''',
        r'''
typedef String A(int pa);
typedef int B(String pb);
typedef C(pc);
''');
  }

  void test_true_functionTypeAlias_typeParameters_list_same() {
    _assertMatches(
        r'''
typedef F<A, B, C>();
''',
        r'''
typedef F<A, B, C>();
''');
  }

  void test_true_FunctionTypedFormalParameter() {
    _assertMatches(
        r'''
main(int callback(int a, String b)) {
}
''',
        r'''
main(int callback(int a, String b)) {
}
''');
  }

  void test_true_implementsClause_same() {
    _assertMatches(
        r'''
class A {}
class B implements A {}
''',
        r'''
class A {}
class B implements A {}
''');
  }

  void test_true_import_hide_reorder() {
    _assertMatches(
        r'''
import 'dart:async' hide Future, Stream;
''',
        r'''
import 'dart:async' hide Stream, Future;
''');
  }

  void test_true_import_list_reorder() {
    _assertMatches(
        r'''
import 'dart:async';
import 'dart:math';
''',
        r'''
import 'dart:math';
import 'dart:async';
''');
  }

  void test_true_import_list_same() {
    _assertMatches(
        r'''
import 'dart:async';
import 'dart:math';
''',
        r'''
import 'dart:async';
import 'dart:math';
''');
  }

  void test_true_import_prefix() {
    _assertMatches(
        r'''
import 'dart:async' as async;
''',
        r'''
import 'dart:async' as async;
''');
  }

  void test_true_import_show_reorder() {
    _assertMatches(
        r'''
import 'dart:async' show Future, Stream;
''',
        r'''
import 'dart:async' show Stream, Future;
''');
  }

  void test_true_method_annotation_accessor_same() {
    _assertMatches(
        r'''
const my_annotation = const Object();
class A {
  @my_annotation
  void m() {}
}
''',
        r'''
const my_annotation = const Object();
class A {
  @my_annotation
  void m() {}
}
''');
  }

  void test_true_method_annotation_constructor_same() {
    _assertMatches(
        r'''
class MyAnnotation {
  const MyAnnotation();
}
class A {
  @MyAnnotation()
  void m() {}
}
''',
        r'''
class MyAnnotation {
  const MyAnnotation();
}
class A {
  @MyAnnotation()
  void m() {}
}
''');
  }

  void test_true_method_async() {
    _assertMatches(
        r'''
class A {
  m() async {}
}
''',
        r'''
class A {
  m() async {}
}
''');
  }

  void test_true_method_list_reorder() {
    _assertMatches(
        r'''
class A {
  a() {}
  b() {}
  c() {}
}
''',
        r'''
class A {
  c() {}
  a() {}
  b() {}
}
''');
  }

  void test_true_method_list_same() {
    _assertMatches(
        r'''
class A {
  a() {}
  b() {}
  c() {}
}
''',
        r'''
class A {
  a() {}
  b() {}
  c() {}
}
''');
  }

  void test_true_method_operator_minus() {
    _assertMatches(
        r'''
class A {
  operator -(other) {}
}
''',
        r'''
class A {
  operator -(other) {}
}
''');
  }

  void test_true_method_operator_minusUnary() {
    _assertMatches(
        r'''
class A {
  operator -() {}
}
''',
        r'''
class A {
  operator -() {}
}
''');
  }

  void test_true_method_operator_plus() {
    _assertMatches(
        r'''
class A {
  operator +(other) {}
}
''',
        r'''
class A {
  operator +(other) {}
}
''');
  }

  void test_true_method_parameters_type_functionType() {
    _assertMatches(
        r'''
typedef F();
class A {
  m(F p) {}
}
''',
        r'''
typedef F();
class A {
  m(F p) {}
}
''');
  }

  void test_true_method_parameters_type_sameImportPrefix() {
    _assertMatches(
        r'''
import 'dart:async' as a;

bar(a.Future f) {
  print(f);
}
''',
        r'''
import 'dart:async' as a;

bar(a.Future ff) {
  print(ff);
}
''');
  }

  void test_true_part_list_reorder() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertMatches(
        r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''',
        r'''
library lib;
part 'unitB.dart';
part 'unitA.dart';
''');
  }

  void test_true_part_list_same() {
    addNamedSource('/unitA.dart', 'part of lib; class A {}');
    addNamedSource('/unitB.dart', 'part of lib; class B {}');
    _assertMatches(
        r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''',
        r'''
library lib;
part 'unitA.dart';
part 'unitB.dart';
''');
  }

  void test_true_SimpleFormalParameter_optional_differentName() {
    _assertMatches(
        r'''
main([int oldName]) {
}
''',
        r'''
main([int newName]) {
}
''');
  }

  void test_true_SimpleFormalParameter_optionalDefault_differentName() {
    _assertMatches(
        r'''
main([int oldName = 1]) {
}
''',
        r'''
main([int newName = 1]) {
}
''');
  }

  void test_true_SimpleFormalParameter_required_differentName() {
    _assertMatches(
        r'''
main(int oldName) {
}
''',
        r'''
main(int newName) {
}
''');
  }

  void test_true_topLevelAccessor_list_reorder() {
    _assertMatches(
        r'''
set a(x) {}
set b(x) {}
set c(x) {}
''',
        r'''
set c(x) {}
set a(x) {}
set b(x) {}
''');
  }

  void test_true_topLevelAccessor_list_same() {
    _assertMatches(
        r'''
get a => 1;
get b => 2;
get c => 3;
''',
        r'''
get a => 1;
get b => 2;
get c => 3;
''');
  }

  void test_true_topLevelFunction_list_reorder() {
    _assertMatches(
        r'''
a() {}
b() {}
c() {}
''',
        r'''
c() {}
a() {}
b() {}
''');
  }

  void test_true_topLevelFunction_list_same() {
    _assertMatches(
        r'''
a() {}
b() {}
c() {}
''',
        r'''
a() {}
b() {}
c() {}
''');
  }

  void test_true_topLevelVariable_list_reorder() {
    _assertMatches(
        r'''
const int A = 1;
const int B = 2;
const int C = 3;
''',
        r'''
const int C = 3;
const int A = 1;
const int B = 2;
''');
  }

  void test_true_topLevelVariable_list_same() {
    _assertMatches(
        r'''
const int A = 1;
const int B = 2;
const int C = 3;
''',
        r'''
const int A = 1;
const int B = 2;
const int C = 3;
''');
  }

  void test_true_topLevelVariable_type_sameArgs() {
    _assertMatches(
        r'''
Map<int, String> A;
''',
        r'''
Map<int, String> A;
''');
  }

  void test_true_type_dynamic() {
    _assertMatches(
        r'''
dynamic a() {}
''',
        r'''
dynamic a() {}
''');
  }

  void test_true_type_hasImportPrefix() {
    _assertMatches(
        r'''
import 'dart:async' as async;
async.Future F;
''',
        r'''
import 'dart:async' as async;
async.Future F;
''');
  }

  void test_true_type_noTypeArguments_implyAllDynamic() {
    _assertMatches(
        r'''
class A<T> {}
A main() {
}
''',
        r'''
class A<T> {}
A main() {
}
''');
  }

  void test_true_type_void() {
    _assertMatches(
        r'''
void a() {}
''',
        r'''
void a() {}
''');
  }

  void test_true_withClause_same() {
    _assertMatches(
        r'''
class A {}
class B extends Object with A {}
''',
        r'''
class A {}
class B extends Object with A {}
''');
  }

  void _assertDoesNotMatch(String oldContent, String newContent) {
    _assertMatchKind(DeclarationMatchKind.MISMATCH, oldContent, newContent);
  }

  void _assertDoesNotMatchOK(String oldContent, String newContent) {
    _assertMatchKind(DeclarationMatchKind.MISMATCH_OK, oldContent, newContent);
  }

  void _assertMatches(String oldContent, String newContent) {
    _assertMatchKind(DeclarationMatchKind.MATCH, oldContent, newContent);
  }

  void _assertMatchKind(
      DeclarationMatchKind expectMatch, String oldContent, String newContent) {
    Source source = addSource(oldContent);
    LibraryElement library = resolve2(source);
    CompilationUnit oldUnit = resolveCompilationUnit(source, library);
    // parse
    CompilationUnit newUnit = ParserTestCase.parseCompilationUnit(newContent);
    // build elements
    {
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder = new ElementBuilder(holder);
      newUnit.accept(builder);
    }
    // match
    DeclarationMatcher matcher = new DeclarationMatcher();
    DeclarationMatchKind matchKind = matcher.matches(newUnit, oldUnit.element);
    expect(matchKind, same(expectMatch));
  }
}

@reflectiveTest
class IncrementalResolverTest extends ResolverTestCase {
  Source source;
  String code;
  LibraryElement library;
  CompilationUnit unit;

  @override
  void reset() {
    if (AnalysisEngine.instance.useTaskModel) {
      analysisContext2 = AnalysisContextFactory.contextWithCore();
    } else {
      analysisContext2 = AnalysisContextFactory.oldContextWithCore();
    }
  }

  @override
  void resetWithOptions(AnalysisOptions options) {
    if (AnalysisEngine.instance.useTaskModel) {
      analysisContext2 =
          AnalysisContextFactory.contextWithCoreAndOptions(options);
    } else {
      analysisContext2 =
          AnalysisContextFactory.oldContextWithCoreAndOptions(options);
    }
  }

  void setUp() {
    super.setUp();
    test_resolveApiChanges = true;
    log.logger = log.NULL_LOGGER;
  }

  void test_classMemberAccessor_body() {
    _resolveUnit(r'''
class A {
  int get test {
    return 1 + 2;
  }
}''');
    _resolve(_editString('+', '*'), _isFunctionBody);
  }

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

  void test_constructor_fieldFormalParameter() {
    _resolveUnit(r'''
class A {
  int xy;
  A(this.x);
}''');
    _resolve(_editString('this.x', 'this.xy'), _isDeclaration);
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

  void test_constructor_label_add() {
    _resolveUnit(r'''
class A {
  A() {
    return 42;
  }
}
''');
    _resolve(_editString('return', 'label: return'), _isBlock);
  }

  void test_constructor_localVariable_add() {
    _resolveUnit(r'''
class A {
  A() {
    42;
  }
}
''');
    _resolve(_editString('42;', 'var res = 42;'), _isBlock);
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

  void test_function_localFunction_add() {
    _resolveUnit(r'''
int main() {
  return 0;
}
callIt(f) {}
''');
    _resolve(_editString('return 0;', 'callIt((p) {});'), _isBlock);
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

  void test_method_localFunction_add() {
    _resolveUnit(r'''
class A {
  int m() {
    return 0;
  }
}
callIt(f) {}
''');
    _resolve(_editString('return 0;', 'callIt((p) {});'), _isBlock);
  }

  void test_method_localVariable_add() {
    _resolveUnit(r'''
class A {
  int m(int a, int b) {
    return a + b;
  }
}
''');
    _resolve(
        _editString(
            '    return a + b;',
            r'''
    int res = a + b;
    return res;
'''),
        _isBlock);
  }

  void test_method_parameter_rename() {
    _resolveUnit(r'''
class A {
  int m(int a, int b, int c) {
    return a + b + c;
  }
}
''');
    _resolve(
        _editString(
            r'''(int a, int b, int c) {
    return a + b + c;''',
            r'''(int a, int second, int c) {
    return a + second + c;'''),
        _isDeclaration);
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

  void test_topLevelAccessor_body() {
    _resolveUnit(r'''
int get test {
  return 1 + 2;
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
    _resolve(
        _editString(
            '  return a + b;',
            r'''
  int res = a + b;
  return res;
'''),
        _isBlock);
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

  void test_topLevelFunction_parameter_inFunctionTyped_rename() {
    _resolveUnit(r'''
test(f(int a, int b)) {
}
''');
    _resolve(_editString('test(f(int a', 'test(f2(int a2'), _isDeclaration);
  }

  void test_topLevelFunction_parameter_rename() {
    _resolveUnit(r'''
int main(int a, int b) {
  return a + b;
}
''');
    _resolve(
        _editString(
            r'''(int a, int b) {
  return a + b;''',
            r'''(int first, int b) {
  return first + b;'''),
        _isDeclaration);
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
    String newCode = code.substring(0, offset) +
        edit.replacement +
        code.substring(offset + edit.length);
    CompilationUnit newUnit = _parseUnit(newCode);
    // replace the node
    AstNode oldNode = _findNodeAt(unit, offset, predicate);
    AstNode newNode = _findNodeAt(newUnit, offset, predicate);
    {
      bool success = NodeReplacer.replace(oldNode, newNode);
      expect(success, isTrue);
    }
    // update tokens
    {
      int delta = edit.replacement.length - edit.length;
      _shiftTokens(unit.beginToken, offset, delta);
    }
    // do incremental resolution
    int updateOffset = edit.offset;
    int updateEndOld = updateOffset + edit.length;
    int updateOldNew = updateOffset + edit.replacement.length;
    IncrementalResolver resolver;
    if (AnalysisEngine.instance.useTaskModel) {
      LibrarySpecificUnit lsu = new LibrarySpecificUnit(source, source);
      task.AnalysisCache cache = analysisContext2.analysisCache;
      resolver = new IncrementalResolver(
          null,
          cache.get(source),
          cache.get(lsu),
          unit.element,
          updateOffset,
          updateEndOld,
          updateOldNew);
    } else {
      resolver = new IncrementalResolver(
          (analysisContext2 as AnalysisContextImpl)
              .getReadableSourceEntryOrNull(source),
          null,
          null,
          unit.element,
          updateOffset,
          updateEndOld,
          updateOldNew);
    }
    bool success = resolver.resolve(newNode);
    expect(success, isTrue);
    List<AnalysisError> newErrors = analysisContext.computeErrors(source);
    // resolve "newCode" from scratch
    CompilationUnit fullNewUnit;
    {
      source = addSource(newCode);
      _runTasks();
      LibraryElement library = resolve2(source);
      fullNewUnit = resolveCompilationUnit(source, library);
    }
    try {
      assertSameResolution(unit, fullNewUnit);
    } on IncrementalResolutionMismatch catch (mismatch) {
      fail(mismatch.message);
    }
    // errors
    List<AnalysisError> newFullErrors =
        analysisContext.getErrors(source).errors;
    _assertEqualErrors(newErrors, newFullErrors);
    // prepare for the next cycle
    code = newCode;
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    library = resolve2(source);
    unit = resolveCompilationUnit(source, library);
    _runTasks();
  }

  void _runTasks() {
    AnalysisResult result = analysisContext.performAnalysisTask();
    while (result.changeNotices != null) {
      result = analysisContext.performAnalysisTask();
    }
  }

  static AstNode _findNodeAt(
      CompilationUnit oldUnit, int offset, Predicate<AstNode> predicate) {
    NodeLocator locator = new NodeLocator(offset);
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
@reflectiveTest
class PoorMansIncrementalResolutionTest extends ResolverTestCase {
  Source source;
  String code;
  LibraryElement oldLibrary;
  CompilationUnit oldUnit;
  CompilationUnitElement oldUnitElement;

  void fail_updateErrors_removeExisting_duplicateMethodDeclaration() {
    // TODO(scheglov) We fail to remove the second "foo" declaration.
    // So, we still have the same duplicate declaration problem.
    _resolveUnit(r'''
class A {
  void foo() {}
  void foo() {}
}
''');
    _updateAndValidate(r'''
class A {
  void foo() {}
  void foo2() {}
}
''');
  }

  void setUp() {
    super.setUp();
    _resetWithIncremental(true);
  }

  void test_computeConstants() {
    _resolveUnit(r'''
int f() => 0;
main() {
  const x = f();
  print(x + 1);
}
''');
    _updateAndValidate(r'''
int f() => 0;
main() {
  const x = f();
  print(x + 2);
}
''');
  }

  void test_dartDoc_beforeField() {
    _resolveUnit(r'''
class A {
  /**
   * A field [field] of type [int] in class [A].
   */
  int field;
}
''');
    _updateAndValidate(r'''
class A {
  /**
   * A field [field] of the type [int] in the class [A].
   * Updated, with a reference to the [String] type.
   */
  int field;
}
''');
  }

  void test_dartDoc_clumsy_addReference() {
    _resolveUnit(r'''
/**
 * aaa bbbb
 */
main() {
}
''');
    _updateAndValidate(r'''
/**
 * aaa [main] bbbb
 */
main() {
}
''');
  }

  void test_dartDoc_clumsy_removeReference() {
    _resolveUnit(r'''
/**
 * aaa [main] bbbb
 */
main() {
}
''');
    _updateAndValidate(r'''
/**
 * aaa bbbb
 */
main() {
}
''');
  }

  void test_dartDoc_clumsy_updateText_beforeKeywordToken() {
    _resolveUnit(r'''
/**
 * A comment with the [int] type reference.
 */
class A {}
''');
    _updateAndValidate(r'''
/**
 * A comment with the [int] type reference.
 * Plus reference to [A] itself.
 */
class A {}
''');
  }

  void test_dartDoc_clumsy_updateText_insert() {
    _resolveUnit(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 */
main(int p) {
  unresolvedFunctionProblem();
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
    _updateAndValidate(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 * Inserted text with [String] reference.
 */
main(int p) {
  unresolvedFunctionProblem();
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
  }

  void test_dartDoc_clumsy_updateText_remove() {
    _resolveUnit(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 * Some text with [String] reference to remove.
 */
main(int p) {
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
    _updateAndValidate(r'''
/**
 * A function [main] with a parameter [p] of type [int].
 */
main(int p) {
}
/**
 * Other comment with [int] reference.
 */
foo() {}
''');
  }

  void test_dartDoc_elegant_addReference() {
    _resolveUnit(r'''
/// aaa bbb
main() {
  return 1;
}
''');
    _updateAndValidate(r'''
/// aaa [main] bbb
/// ccc [int] ddd
main() {
  return 1;
}
''');
  }

  void test_dartDoc_elegant_removeReference() {
    _resolveUnit(r'''
/// aaa [main] bbb
/// ccc [int] ddd
main() {
  return 1;
}
''');
    _updateAndValidate(r'''
/// aaa bbb
main() {
  return 1;
}
''');
  }

  void test_dartDoc_elegant_updateText_insertToken() {
    _resolveUnit(r'''
/// A
/// [int]
class Test {
}
''');
    _updateAndValidate(r'''
/// A
///
/// [int]
class Test {
}
''');
  }

  void test_dartDoc_elegant_updateText_removeToken() {
    _resolveUnit(r'''
/// A
///
/// [int]
class Test {
}
''');
    _updateAndValidate(r'''
/// A
/// [int]
class Test {
}
''');
  }

  void test_endOfLineComment_add_beforeKeywordToken() {
    _resolveUnit(r'''
main() {
  var v = 42;
}
''');
    _updateAndValidate(r'''
main() {
  // some comment
  var v = 42;
}
''');
  }

  void test_endOfLineComment_add_beforeStringToken() {
    _resolveUnit(r'''
main() {
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  // some comment
  print(0);
}
''');
  }

  void test_endOfLineComment_edit() {
    _resolveUnit(r'''
main() {
  // some comment
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  // edited comment text
  print(0);
}
''');
  }

  void test_endOfLineComment_localFunction_inTopLevelVariable() {
    _resolveUnit(r'''
typedef int Binary(one, two, three);

int Global = f((a, b, c) {
  return 0; // Some comment
});
''');
    _updateAndValidate(r'''
typedef int Binary(one, two, three);

int Global = f((a, b, c) {
  return 0; // Some  comment
});
''');
  }

  void test_endOfLineComment_outBody_add() {
    _resolveUnit(r'''
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
// 000
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_outBody_remove() {
    _resolveUnit(r'''
// 000
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_outBody_update() {
    _resolveUnit(r'''
// 000
main() {
  Object x;
  x.foo();
}
''');
    _updateAndValidate(
        r'''
// 10
main() {
  Object x;
  x.foo();
}
''',
        expectedSuccess: false);
  }

  void test_endOfLineComment_remove() {
    _resolveUnit(r'''
main() {
  // some comment
  print(0);
}
''');
    _updateAndValidate(r'''
main() {
  print(0);
}
''');
  }

  void test_false_constConstructor_initializer() {
    _resolveUnit(r'''
class C {
  final int x;
  const C(this.x);
  const C.foo() : x = 0;
}
main() {
  const {const C(0): 0, const C.foo(): 1};
}
''');
    _updateAndValidate(
        r'''
class C {
  final int x;
  const C(this.x);
  const C.foo() : x = 1;
}
main() {
  const {const C(0): 0, const C.foo(): 1};
}
''',
        expectedSuccess: false);
  }

  void test_false_expressionBody() {
    _resolveUnit(r'''
class A {
  final f = (() => 1)();
}
''');
    _updateAndValidate(
        r'''
class A {
  final f = (() => 2)();
}
''',
        expectedSuccess: false);
  }

  void test_false_topLevelFunction_name() {
    _resolveUnit(r'''
a() {}
b() {}
''');
    _updateAndValidate(
        r'''
a() {}
bb() {}
''',
        expectedSuccess: false);
  }

  void test_false_unbalancedCurlyBrackets_inNew() {
    _resolveUnit(r'''
class A {
  aaa() {
    if (true) {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''');
    _updateAndValidate(
        r'''
class A {
  aaa() {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''',
        expectedSuccess: false);
  }

  void test_false_unbalancedCurlyBrackets_inOld() {
    _resolveUnit(r'''
class A {
  aaa() {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''');
    _updateAndValidate(
        r'''
class A {
  aaa() {
    if (true) {
      1;
    }
  }

  bbb() {
    print(0123456789);
  }
}''',
        expectedSuccess: false);
  }

  void test_fieldClassField_propagatedType() {
    _resolveUnit(r'''
class A {
  static const A b = const B();
  const A();
}

class B extends A {
  const B();
}

main() {
  print(12);
  A.b;
}
''');
    _updateAndValidate(r'''
class A {
  static const A b = const B();
  const A();
}

class B extends A {
  const B();
}

main() {
  print(123);
  A.b;
}
''');
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
        _updateAndValidate(
            r'''
class A {
  m() {
    return true;

  }
}''',
            compareWithFull: false);
      } else {
        _updateAndValidate(
            r'''
class A {
  m() {
    return true;
  }
}''',
            compareWithFull: false);
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
        _updateAndValidate(
            r'''
main() {
  print(12);
}''',
            compareWithFull: false);
      } else {
        _updateAndValidate(
            r'''
main() {
  print(1);
}''',
            compareWithFull: false);
      }
    }
  }

  void test_true_emptyLine_betweenClassMembers_insert() {
    _resolveUnit(r'''
class A {
  a() {}
  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}

  b() {}
}
''');
  }

  void test_true_emptyLine_betweenClassMembers_remove() {
    _resolveUnit(r'''
class A {
  a() {}

  b() {}
}
''');
    _updateAndValidate(r'''
class A {
  a() {}
  b() {}
}
''');
  }

  void test_true_emptyLine_betweenCompilationUnitMembers_insert() {
    _resolveUnit(r'''
a() {}
b() {}
''');
    _updateAndValidate(r'''
a() {}

b() {}
''');
  }

  void test_true_emptyLine_betweenCompilationUnitMembers_remove() {
    _resolveUnit(r'''
a() {
  print(1)
}

b() {
  foo(42);
}
foo(String p) {}
''');
    _updateAndValidate(r'''
a() {
  print(1)
}
b() {
  foo(42);
}
foo(String p) {}
''');
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

  void test_unusedHint_add_wasUsedOnlyInPart() {
    Source partSource = addNamedSource(
        '/my_unit.dart',
        r'''
part of lib;

f(A a) {
  a._foo();
}
''');
    _resolveUnit(r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(1);
  }
}
''');
    _runTasks();
    // perform incremental resolution
    _resetWithIncremental(true);
    analysisContext2.setContents(
        partSource,
        r'''
part of lib;

f(A a) {
//  a._foo();
}
''');
    // no hints right now, because we delay hints computing
    {
      List<AnalysisError> errors = analysisContext.getErrors(source).errors;
      expect(errors, isEmpty);
    }
    // a new hint should be added
    List<AnalysisError> errors = analysisContext.computeErrors(source);
    expect(errors, hasLength(1));
    expect(errors[0].errorCode.type, ErrorType.HINT);
    // the same hint should be reported using a ChangeNotice
    bool noticeFound = false;
    AnalysisResult result = analysisContext2.performAnalysisTask();
    for (ChangeNotice notice in result.changeNotices) {
      if (notice.source == source) {
        expect(notice.errors, contains(errors[0]));
        noticeFound = true;
      }
    }
    expect(noticeFound, isTrue);
  }

  void test_unusedHint_false_stillUsedInPart() {
    addNamedSource(
        '/my_unit.dart',
        r'''
part of lib;

f(A a) {
  a._foo();
}
''');
    _resolveUnit(r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(1);
  }
}
''');
    // perform incremental resolution
    _resetWithIncremental(true);
    analysisContext2.setContents(
        source,
        r'''
library lib;
part 'my_unit.dart';
class A {
  _foo() {
    print(12);
  }
}
''');
    // no hints
    List<AnalysisError> errors = analysisContext.getErrors(source).errors;
    expect(errors, isEmpty);
  }

  void test_updateErrors_addNew_hint1() {
    _resolveUnit(r'''
int main() {
  return 42;
}
''');
    _updateAndValidate(r'''
int main() {
}
''');
  }

  void test_updateErrors_addNew_hint2() {
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

  void test_updateErrors_addNew_resolve2() {
    _resolveUnit(r'''
// this comment is important to reproduce the problem
main() {
  int vvv = 42;
  print(vvv);
}
''');
    _updateAndValidate(r'''
// this comment is important to reproduce the problem
main() {
  int vvv = 42;
  print(vvv2);
}
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

  void test_updateErrors_removeExisting_hint() {
    _resolveUnit(r'''
int main() {
}
''');
    _updateAndValidate(r'''
int main() {
  return 42;
}
''');
  }

  void test_updateErrors_removeExisting_verify() {
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

  void _assertEqualLineInfo(LineInfo incrLineInfo, LineInfo fullLineInfo) {
    for (int offset = 0; offset < 1000; offset++) {
      LineInfo_Location incrLocation = incrLineInfo.getLocation(offset);
      LineInfo_Location fullLocation = fullLineInfo.getLocation(offset);
      if (incrLocation.lineNumber != fullLocation.lineNumber ||
          incrLocation.columnNumber != fullLocation.columnNumber) {
        fail('At offset $offset ' +
            '(${incrLocation.lineNumber}, ${incrLocation.columnNumber})' +
            ' != ' +
            '(${fullLocation.lineNumber}, ${fullLocation.columnNumber})');
      }
    }
  }

  /**
   * Reset the analysis context to have the 'incremental' option set to the
   * given value.
   */
  void _resetWithIncremental(bool enable) {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.incremental = enable;
    analysisOptions.incrementalApi = enable;
//    log.logger = log.PRINT_LOGGER;
    log.logger = log.NULL_LOGGER;
    analysisContext2.analysisOptions = analysisOptions;
  }

  void _resolveUnit(String code) {
    this.code = code;
    source = addSource(code);
    oldLibrary = resolve2(source);
    oldUnit = resolveCompilationUnit(source, oldLibrary);
    oldUnitElement = oldUnit.element;
  }

  void _runTasks() {
    AnalysisResult result = analysisContext.performAnalysisTask();
    while (result.changeNotices != null) {
      result = analysisContext.performAnalysisTask();
    }
  }

  void _updateAndValidate(String newCode,
      {bool expectedSuccess: true, bool compareWithFull: true}) {
    // Run any pending tasks tasks.
    _runTasks();
    // Update the source - currently this may cause incremental resolution.
    // Then request the updated resolved unit.
    _resetWithIncremental(true);
    analysisContext2.setContents(source, newCode);
    CompilationUnit newUnit = resolveCompilationUnit(source, oldLibrary);
    List<AnalysisError> newErrors = analysisContext.computeErrors(source);
    LineInfo newLineInfo = analysisContext.getLineInfo(source);
    // check for expected failure
    if (!expectedSuccess) {
      expect(newUnit.element, isNot(same(oldUnitElement)));
      return;
    }
    // The existing CompilationUnitElement should be updated.
    expect(newUnit.element, same(oldUnitElement));
    // The only expected pending task should return the same resolved
    // "newUnit", so all clients will get it using the usual way.
    AnalysisResult analysisResult = analysisContext.performAnalysisTask();
    ChangeNotice notice = analysisResult.changeNotices[0];
    expect(notice.resolvedDartUnit, same(newUnit));
    // Resolve "newCode" from scratch.
    if (compareWithFull) {
      _resetWithIncremental(false);
      source = addSource(newCode + ' ');
      source = addSource(newCode);
      _runTasks();
      LibraryElement library = resolve2(source);
      CompilationUnit fullNewUnit = resolveCompilationUnit(source, library);
      // Validate tokens.
      _assertEqualTokens(newUnit, fullNewUnit);
      // Validate LineInfo
      _assertEqualLineInfo(newLineInfo, analysisContext.getLineInfo(source));
      // Validate that "incremental" and "full" units have the same resolution.
      try {
        assertSameResolution(newUnit, fullNewUnit, validateTypes: true);
      } on IncrementalResolutionMismatch catch (mismatch) {
        fail(mismatch.message);
      }
      List<AnalysisError> newFullErrors =
          analysisContext.getErrors(source).errors;
      _assertEqualErrors(newErrors, newFullErrors);
    }
  }

  static void _assertEqualToken(Token incrToken, Token fullToken) {
//    print('[${incrToken.offset}] |$incrToken| vs. [${fullToken.offset}] |$fullToken|');
    expect(incrToken.type, fullToken.type);
    expect(incrToken.offset, fullToken.offset);
    expect(incrToken.length, fullToken.length);
    expect(incrToken.lexeme, fullToken.lexeme);
  }

  static void _assertEqualTokens(
      CompilationUnit incrUnit, CompilationUnit fullUnit) {
    Token incrToken = incrUnit.beginToken;
    Token fullToken = fullUnit.beginToken;
    while (incrToken.type != TokenType.EOF && fullToken.type != TokenType.EOF) {
      _assertEqualToken(incrToken, fullToken);
      // comments
      {
        Token incrComment = incrToken.precedingComments;
        Token fullComment = fullToken.precedingComments;
        while (true) {
          if (fullComment == null) {
            expect(incrComment, isNull);
            break;
          }
          expect(incrComment, isNotNull);
          _assertEqualToken(incrComment, fullComment);
          incrComment = incrComment.next;
          fullComment = fullComment.next;
        }
      }
      // next tokens
      incrToken = incrToken.next;
      fullToken = fullToken.next;
    }
  }
}

@reflectiveTest
class ResolutionContextBuilderTest extends EngineTestCase {
  GatheringErrorListener listener = new GatheringErrorListener();

  void test_scopeFor_ClassDeclaration() {
    Scope scope = _scopeFor(_createResolvedClassDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_ClassTypeAlias() {
    Scope scope = _scopeFor(_createResolvedClassTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_CompilationUnit() {
    Scope scope = _scopeFor(_createResolvedCompilationUnit());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_ConstructorDeclaration() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope, ClassScope, scope);
  }

  void test_scopeFor_ConstructorDeclaration_parameters() {
    Scope scope = _scopeFor(_createResolvedConstructorDeclaration().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_FunctionDeclaration() {
    Scope scope = _scopeFor(_createResolvedFunctionDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_FunctionDeclaration_parameters() {
    Scope scope = _scopeFor(
        _createResolvedFunctionDeclaration().functionExpression.parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_FunctionTypeAlias() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryScope, LibraryScope, scope);
  }

  void test_scopeFor_FunctionTypeAlias_parameters() {
    Scope scope = _scopeFor(_createResolvedFunctionTypeAlias().parameters);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionTypeScope, FunctionTypeScope, scope);
  }

  void test_scopeFor_MethodDeclaration() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration());
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassScope, ClassScope, scope);
  }

  void test_scopeFor_MethodDeclaration_body() {
    Scope scope = _scopeFor(_createResolvedMethodDeclaration().body);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionScope, FunctionScope, scope);
  }

  void test_scopeFor_notInCompilationUnit() {
    try {
      _scopeFor(AstFactory.identifier3("x"));
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void test_scopeFor_null() {
    try {
      _scopeFor(null);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void test_scopeFor_unresolved() {
    try {
      _scopeFor(AstFactory.compilationUnit());
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  ClassDeclaration _createResolvedClassDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassDeclaration classNode = AstFactory.classDeclaration(
        null, className, AstFactory.typeParameterList(), null, null, null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types = <ClassElement>[
      classElement
    ];
    return classNode;
  }

  ClassTypeAlias _createResolvedClassTypeAlias() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String className = "C";
    ClassTypeAlias classNode = AstFactory.classTypeAlias(
        className, AstFactory.typeParameterList(), null, null, null, null);
    unit.declarations.add(classNode);
    ClassElement classElement = ElementFactory.classElement2(className);
    classNode.name.staticElement = classElement;
    (unit.element as CompilationUnitElementImpl).types = <ClassElement>[
      classElement
    ];
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
    (classNode.element as ClassElementImpl).constructors = <ConstructorElement>[
      constructorElement
    ];
    return constructorNode;
  }

  FunctionDeclaration _createResolvedFunctionDeclaration() {
    CompilationUnit unit = _createResolvedCompilationUnit();
    String functionName = "f";
    FunctionDeclaration functionNode = AstFactory.functionDeclaration(
        null, null, functionName, AstFactory.functionExpression());
    unit.declarations.add(functionNode);
    FunctionElement functionElement =
        ElementFactory.functionElement(functionName);
    functionNode.name.staticElement = functionElement;
    (unit.element as CompilationUnitElementImpl).functions = <FunctionElement>[
      functionElement
    ];
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
    (classNode.element as ClassElementImpl).methods = <MethodElement>[
      methodElement
    ];
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
