// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_bound_topLevelVariable_wildcard() async {
    await _testMarkedContent('''
var /*[0*/_/*0]*/ = 1;
void f() {
  var _ = 2;
  print(/*[1*/_/*1]*/);
}
''');
  }

  Future<void> test_catch_error() async {
    await _testMarkedContent(r'''
void foo() {
  try {} catch (/*[0*/error/*0]*/, stackTrace) {
    print('$/*[1*/error/*1]*/, $stackTrace');
  }
}
''');
  }

  Future<void> test_catch_stack() async {
    await _testMarkedContent(r'''
void foo() {
  try {} catch (error, /*[0*/stackTrace/*0]*/) {
    print('$error, $/*[1*/stackTrace/*1]*/');
  }
}
''');
  }

  Future<void> test_class_field_underscore() async {
    await _testMarkedContent('''
class C {
  int /*[0*/_/*0]*/ = 0;
  }

  void f(int _) {
  int _ = 1;
  C()./*[1*/_/*1]*/;
}
''');
  }

  Future<void> test_dartCode_issue5369_field() async {
    await _testMarkedContent('''
class A {
  var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
  List<String> f() {
    return /*[1*/a/*1]*/;
  }
}

var a; // Not a reference
''');
  }

  Future<void> test_dartCode_issue5369_functionType() async {
    await _testMarkedContent('''
class A {
  String m({ required String Function(String input) /*[0*/f/*0]*/ }) {
    return /*[1*/f/*1]*/('');
  }
}

var f; // Not a reference
''');
  }

  Future<void> test_dartCode_issue5369_localVariable() async {
    await _testMarkedContent('''
class A {
  List<String> f() {
    var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
    return /*[1*/a/*1]*/;
  }
}

var a; // Not a reference
''');
  }

  Future<void> test_dartCode_issue5369_topLevelVariable() async {
    await _testMarkedContent('''
var /*[0*/a/*0]*/ = [''].where((_) => true).toList();
var b = /*[1*/a/*1]*/;
''');
  }

  Future<void> test_dotShorthand_class() async {
    await _testMarkedContent('''
A topA = ./*[0*/a/*0]*/;
class A {
  static A get /*[1*/a/*1]*/ => A();
}
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');
  }

  Future<void> test_dotShorthand_enum() async {
    await _testMarkedContent('''
const A constA = ./*[0*/a/*0]*/;
enum A { /*[1*/a/*1]*/ }
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');
  }

  Future<void> test_dotShorthand_extensionType() async {
    await _testMarkedContent('''
A topA = ./*[0*/a/*0]*/;
extension type A(int x) {
  static A get /*[1*/a/*1]*/ => A(1);
}
void fn(A a) => print(a);
void f() {
  A a = ./*[2*/a/*2]*/;
  fn(./*[3*/a/*3]*/);
  A aa = A./*[4*/a/*4]*/;
}
''');
  }

  Future<void> test_enum() async {
    await _testMarkedContent('''
enum /*[0*/E/*0]*/ {
  v;
}

void f(/*[1*/E/*1]*/ e) {
  /*[2*/E/*2]*/.v;
}
''');
  }

  Future<void> test_enum_constant() async {
    await _testMarkedContent('''
enum E {
  /*[0*/v/*0]*/;
}

void f() {
  E./*[1*/v/*1]*/;
}
''');
  }

  Future<void> test_enum_field() async {
    await _testMarkedContent('''
enum E {
  v;
  final int /*[0*/foo/*0]*/ = 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_enum_getter() async {
    await _testMarkedContent('''
enum E {
  v;
  int get /*[0*/foo/*0]*/ => 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_enum_method() async {
    await _testMarkedContent('''
enum E {
  v;
  void /*[0*/foo/*0]*/() {}
}

void f(E e) {
  e./*[1*/foo/*1]*/();
}
''');
  }

  Future<void> test_enum_setter() async {
    await _testMarkedContent('''
enum E {
  v;
  set /*[0*/foo/*0]*/(int _) {}
}

void f(E e) {
  e./*[1*/foo/*1]*/ = 0;
}
''');
  }

  Future<void> test_extension() async {
    await _testMarkedContent('''
void foo(int i) {
  /*[0*/E/*0]*/(i).self;
}

extension /*[1*/E/*1]*/<ThisType> on ThisType {
  ThisType get self => this;
}
''');
  }

  Future<void> test_extensionMember() async {
    await _testMarkedContent('''
extension on int {
  int get /*[0*/foo/*0]*/ => 0;
}

void f(int v) {
  v./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_extensionMember_differentiation() async {
    await _testMarkedContent('''
extension on String {
  int get foo => 0;
}

extension on int {
  int get /*[0*/foo/*0]*/ => 0;
}

void f(int v, String s) {
  v./*[1*/foo/*1]*/;
  s.foo;
}
''');
  }

  Future<void> test_extensionType() async {
    await _testMarkedContent('''
extension type /*[0*/E/*0]*/(int it) {}

void f(/*[1*/E/*1]*/ e) {}
''');
  }

  Future<void> test_extensionType_constructor_primary() async {
    await _testMarkedContent('''
extension type E./*[0*/named/*0]*/(int it) {}

void f() {
  E./*[1*/named/*1]*/(0);
}
''');
  }

  Future<void> test_extensionType_constructor_secondary() async {
    await _testMarkedContent('''
extension type E(int it) {
  E./*[0*/named/*0]*/() : this(0);
}

void f() {
  E./*[1*/named/*1]*/();
}
''');
  }

  Future<void> test_extensionType_getter() async {
    await _testMarkedContent('''
extension type E(int it) {
  int get /*[0*/foo/*0]*/ => 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_extensionType_method() async {
    await _testMarkedContent('''
extension type E(int it) {
  void /*[0*/foo/*0]*/() {}
}

void f(E e) {
  e./*[1*/foo/*1]*/();
}
''');
  }

  Future<void> test_extensionType_setter() async {
    await _testMarkedContent('''
extension type E(int it) {
  set /*[0*/foo/*0]*/(int _) {}
}

void f(E e) {
  e./*[1*/foo/*1]*/ = 0;
}
''');
  }

  Future<void> test_field() async {
    await _testMarkedContent('''
class A {
  int /*[0*/fff/*0]*/;
  A(this./*[1*/fff/*1]*/);
  void f() {
    /*[2*/fff/*2]*/ = 42;
    print(/*[3*/fff/*3]*/);
  }
}
''');
  }

  Future<void> test_field_unresolved() async {
    failTestOnErrorDiagnostic = false;

    // Unresolved fields should not return any highlights (or error).
    await _testMarkedContent('''
class A {
  A(this.noSuc^hField);
}
''');
  }

  Future<void> test_forInLoop() async {
    await _testMarkedContent('''
void f() {
  for (final /*[0*/x/*0]*/ in []) {
    /*[1*/x/*1]*/;
  }
}
''');
  }

  Future<void> test_formalParameters_closure() async {
    await _testMarkedContent('''
void f(void Function(int) _) {}

void g() => f((/*[0*/variable/*0]*/) {
print(/*[1*/variable/*1]*/);
});
''');
  }

  Future<void> test_formalParameters_function() async {
    await _testMarkedContent('''
void f(int /*[0*/parameter/*0]*/) {
  print(/*[1*/parameter/*1]*/);
}
''');
  }

  Future<void> test_formalParameters_method() async {
    await _testMarkedContent('''
class C {
  void m(int /*[0*/parameter/*0]*/) {
    print(/*[1*/parameter/*1]*/);
  }
}
''');
  }

  Future<void> test_functions() async {
    await _testMarkedContent('''
/*[0*/main/*0]*/() {
  /*[1*/main/*1]*/();
}
''');
  }

  Future<void> test_invalidLineByOne() async {
    // Test that requesting a line that's too high by one returns a valid
    // error response instead of throwing.
    const content = '// single line';

    await initialize();
    await openFile(mainFileUri, content);

    // Lines are zero-based so 1 is invalid.
    var pos = Position(line: 1, character: 0);
    var request = getDocumentHighlights(mainFileUri, pos);

    await expectLater(
      request,
      throwsA(isResponseError(ServerErrorCodes.invalidFileLineCol)),
    );
  }

  Future<void> test_keyword_loop_do() => _testLoop('do', '', 'while (true);');

  Future<void> test_keyword_loop_for() => _testLoop('for', '(;;)', '');

  Future<void> test_keyword_loop_while() => _testLoop('while', '(true)', '');

  Future<void> test_keyword_loopWithSwitch_loopExit() async {
    await _testMarkedContent('''
void f(int i) {
  /*[0*/for/*0]*/ (;;) {
    /*[1*/break/*1]*/;
    /*[2*/continue/*2]*/;
    switch (i) {
      case 1:
        break;
        /*[3*/continue/*3]*/;
      case 2:
        break;
        /*[4*/continue/*4]*/;
    }
  }
}
''');
  }

  Future<void> test_keyword_loopWithSwitch_switchExit() async {
    await _testMarkedContent('''
void f(int i) {
  for (;;) {
    break;
    continue;
    /*[0*/switch/*0]*/ (i) {
      case 1:
        /*[1*/break/*1]*/;
        continue;
      case 2:
        /*[2*/break/*2]*/;
        continue;
    }
  }
}
''');
  }

  Future<void> test_keyword_return_function() async {
    await _testMarkedContent('''
int f() {
  if (true) /*[0*/return/*0]*/ 1;
  /*[1*/return/*1]*/ 2;
}
''');
  }

  Future<void> test_keyword_return_insideLoop() async {
    await _testMarkedContent('''
int f(int i) {
  for (;;) {
    switch (i) {
      case 1:
        /*[0*/return/*0]*/ 1;
      case 2:
        /*[1*/return/*1]*/ 2;
        break;
        continue;
    }
  }
  /*[2*/return/*2]*/ 2;
}
''');
  }

  Future<void> test_keyword_return_method() async {
    await _testMarkedContent('''
class C {
  int m() {
    if (true) /*[0*/return/*0]*/ 1;
    /*[1*/return/*1]*/ 2;
  }
}
''');
  }

  Future<void> test_keyword_return_nestedClosure() async {
    await _testMarkedContent('''
int outerFunction() {
  var a = () {
    var b = () {
      var c = () {
        return 1;
      };
      if (true) /*[0*/return/*0]*/ 1;
      /*[1*/return/*1]*/ 0;
    };
    return 1;
  };
  return 1;
}
''');
  }

  Future<void> test_keyword_return_nestedFunction() async {
    await _testMarkedContent('''
int outerFunction() {
  int middleFunction() {
    int innerFunction() {
      return 1;
    }
    if (true) /*[0*/return/*0]*/ 1;
    /*[1*/return/*1]*/ 2;
  }
  return 1;
}
''');
  }

  Future<void> test_keyword_yield_asyncGenerator() async {
    await _testMarkedContent('''
Stream<int> outerFunction() async* {
  Stream<int> middleFunction() async* {
    Stream<int> innerFunction() async* {
      yield 1;
      yield* Stream.value(0);
    }
    if (true) /*[0*/yield/*0]*/ 1;
    if (true) /*[1*/yield/*1]*/* Stream.value(0);
    /*[2*/yield/*2]*/ 2;
    /*[3*/yield/*3]*/* Stream.value(0);
  }
  yield 1;
  yield* Stream.value(0);
}
''');
  }

  Future<void> test_keyword_yield_syncGenerator() async {
    await _testMarkedContent('''
Iterable<int> outerFunction() sync* {
  Iterable<int> middleFunction() sync* {
    Iterable<int> innerFunction() sync* {
      yield 1;
      yield* Iterable.empty();
    }
    if (true) /*[0*/yield/*0]*/ 1;
    if (true) /*[1*/yield/*1]*/* Iterable.empty();
    /*[2*/yield/*2]*/ 2;
    /*[3*/yield/*3]*/* Iterable.empty();
  }
  yield 1;
  yield* Iterable.empty();
}
''');
  }

  Future<void> test_localVariable() async {
    await _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = 2;
}
''');
  }

  Future<void> test_memberField() async {
    await _testMarkedContent('''
class A<T> {
  T /*[0*/fff/*0]*/;
  A(this./*[1*/fff/*1]*/);
}
void f() {
  var a = A<int>(1);
  var b = A<String>('');
  a./*[2*/fff/*2]*/ = 1;
  b./*[3*/fff/*3]*/ = '';
}
''');
  }

  Future<void> test_memberMethod() async {
    await _testMarkedContent('''
class A<T> {
  T /*[0*/mmm/*0]*/() => throw 0;
}
void f() {
  var a = A<int>();
  var b = A<String>();
  a./*[1*/mmm/*1]*/();
  b./*[2*/mmm/*2]*/();
}
''');
  }

  Future<void> test_method_underscore() async {
    await _testMarkedContent('''
class C {
  /*[0*/_/*0]*/() {
    /*[1*/_/*1]*/();
  }
}
''');
  }

  Future<void> test_mixin() async {
    await _testMarkedContent('''
mixin /*[0*/A/*0]*/ {
  void aaa() {}
}
class B with /*[1*/A/*1]*/ {}
''');
  }

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    var highlights = await getDocumentHighlights(pubspecFileUri, startOfDocPos);

    // Non-Dart files should return empty results, not errors.
    expect(highlights, isEmpty);
  }

  Future<void> test_noResult() async {
    await _testMarkedContent('''
void f() {
  // This one is in a ^ comment!
}
''');
  }

  Future<void> test_onlySelf() async {
    await _testMarkedContent('''
void f() {
  /*[0*/print/*0]*/('');
}
''');
  }

  Future<void> test_onlySelf_wildcard() async {
    await _testMarkedContent('''
void f() {
  var /*[0*/_/*0]*/ = '';
}
''');
  }

  Future<void> test_parameter_named() async {
    await _testMarkedContent('''
void f(int aaa, int bbb, {int? /*[0*/ccc/*0]*/, int? ddd}) {
  /*[1*/ccc/*1]*/;
  ddd;
}

void g() {
  f(0, 1, /*[2*/ccc/*2]*/: 2, ddd: 3);
}
''');
  }

  Future<void> test_parameter_privateNamed() async {
    await _testMarkedContent('''
class C {
  int? /*[0*/_aaa/*0]*/;
  C({this./*[1*/_aaa/*1]*/});
}

void f() {
  C(/*[2*/aaa/*2]*/: 123);
}
''');
  }

  Future<void> test_parameter_wildcard() async {
    await _testMarkedContent('''
void f(int /*[0*/_/*0]*/) {}
''');
  }

  Future<void> test_pattern_assignment() async {
    await _testMarkedContent('''
void f(String /*[0*/a/*0]*/, String b) {
  (b, /*[1*/a/*1]*/) = (/*[2*/a/*2]*/, b);
}
''');
  }

  Future<void> test_pattern_assignment_list() async {
    await _testMarkedContent('''
void f(List<int> x, num /*[0*/a/*0]*/) {
  [/*[1*/a/*1]*/] = x;
}
''');
  }

  Future<void> test_pattern_cast_typeName() async {
    await _testMarkedContent('''
/*[0*/String/*0]*/ f((num, /*[1*/String/*1]*/) record) {
  var (i as int, s as /*[2*/String/*2]*/) = record;
  return s;
}
''');
  }

  Future<void> test_pattern_cast_variable() async {
    await _testMarkedContent('''
void f((num, String) record) {
  var (i as int, /*[0*/s/*0]*/ as String) = record;
  print(/*[1*/s/*1]*/);
}
''');
  }

  Future<void> test_pattern_map() async {
    await _testMarkedContent('''
void f(x) {
  switch (x) {
    case {0: String /*[0*/a/*0]*/}:
      print(/*[1*/a/*1]*/);
      break;
  }
}
''');
  }

  Future<void> test_pattern_map_typeArguments() async {
    await _testMarkedContent('''
/*[0*/String/*0]*/ f(x) {
  switch (x) {
    case <int, /*[1*/String/*1]*/>{0: var a}:
      return a;
      break;
  }
  return '';
}
''');
  }

  Future<void> test_pattern_nullAssert() async {
    await _testMarkedContent('''
void f((int?, int?) position) {
  var (x!, /*[0*/y/*0]*/!) = position;
  print(/*[1*/y/*1]*/);
}
''');
  }

  Future<void> test_pattern_nullCheck() async {
    await _testMarkedContent('''
void f(String? maybeString) {
  switch (maybeString) {
    case var /*[0*/s/*0]*/?:
      print(/*[1*/s/*1]*/);
  }
}
''');
  }

  Future<void> test_pattern_object_destructure() async {
    await _testMarkedContent('''
void f() {
  final MapEntry(:/*[0*/key/*0]*/) = const MapEntry<String, int>('a', 1);

  if (const MapEntry('a', 1) case MapEntry(:final /*[1*/ke^y/*1]*/)) {
    /*[2*/key/*2]*/;
  }
}
''');
  }

  Future<void> test_pattern_object_destructure_getter() async {
    await _testMarkedContent('''
class A {
  String? /*[0*/key/*0]*/;
}

void f() {
  final A(:/*[1*/key/*1]*/) = A();
}
''');
  }

  Future<void> test_pattern_object_destructure_variable() async {
    await _testMarkedContent('''
class A {
  String? /*[0*/key/*0]*/;
}

void f() {
  final A(:/*[1*/k^ey/*1]*/) = A();
  /*[2*/key/*2]*/;
}
''');
  }

  Future<void> test_pattern_object_fieldName() async {
    await _testMarkedContent('''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(/*[0*/length/*0]*/: var l) => l * l,
    Shape() => 0.0,
  };

class Shape { }
class Square extends Shape {
  double get /*[1*/length/*1]*/ => 0;
}
''');
  }

  Future<void> test_pattern_object_typeName() async {
    await _testMarkedContent('''
double calculateArea(Shape shape) =>
  switch (shape) {
    /*[0*/Square/*0]*/(length: var l) => l * l,
    Shape() => 0.0,
  };

class Shape { }
class /*[1*/Square/*1]*/ extends Shape {
  double get length => 0;
}
''');
  }

  Future<void> test_pattern_object_variable() async {
    await _testMarkedContent('''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(length: var /*[0*/l/*0]*/) => /*[1*/l/*1]*/ * /*[2*/l/*2]*/,
    Shape() => 0.0,
  };

class Shape { }
class Square extends Shape {
  double get length => 0;
}
''');
  }

  Future<void> test_pattern_record_variable() async {
    await _testMarkedContent('''
void f(({int foo}) x, num /*[0*/a/*0]*/) {
  (foo: /*[1*/a/*1]*/,) = x;
}
''');
  }

  Future<void> test_pattern_relational_variable() async {
    await _testMarkedContent('''
String f(int char) {
  const /*[0*/zero/*0]*/ = 0;
  return switch (char) {
    == /*[1*/zero/*1]*/ => 'zero',
    _ => '',
  };
}
''');
  }

  Future<void> test_patternVariable_ifCase_logicalOr() async {
    await _testMarkedContent('''
void f(Object? x) {
  if (x case int /*[0*/test/*0]*/ || [int /*[1*/test/*1]*/] when /*[2*/test/*2]*/ > 0) {
    /*[3*/test/*3]*/;
    /*[4*/test/*4]*/ = 1;
    /*[5*/test/*5]*/ += 2;
  }
}
''');
  }

  Future<void> test_prefix() async {
    await _testMarkedContent('''
import '' as /*[0*/p/*0]*/;

class A {
  void m() {
    /*[1*/p/*1]*/.foo();
    print(/*[2*/p/*2]*/.a);
    /*[3*/p/*3]*/.A();
  }
}

void foo() {}

/*[4*/p/*4]*/.A? a;
''');
  }

  Future<void> test_prefix_null() async {
    failTestOnErrorDiagnostic = false;

    // Note, we use `core` just to have some prefix.
    // The actual check is no crash on unresolved `prefix`.
    await _testMarkedContent('''
import 'dart:core' as /*[0*/core/*0]*/;
void f(prefix.A? _, /*[1*/core/*1]*/.int _) {}
''');
  }

  Future<void> test_prefix_wildcard() async {
    // Ensure no crash.
    await _testMarkedContent('''
import 'dart:io' as /*[0*/_/*0]*/;
''');
  }

  Future<void> test_prefixed() async {
    await _testMarkedContent('''
import '' as p;

class /*[0*/A/*0]*/ {}

p./*[1*/A/*1]*/? a;
''');
  }

  /// The body/this keyword isn't an occurrence of anything.
  Future<void> test_primaryConstructor_body() async {
    await _testMarkedContent('''
class Aaa() {
  th^is {}
}

Aaa a = Aaa();
''');
  }

  /// The body/this keyword isn't an occurrence of anything.
  Future<void> test_primaryConstructor_named_body() async {
    await _testMarkedContent('''
class Aaa.named() {
  th^is {}
}

Aaa a = Aaa.named();
''');
  }

  Future<void> test_primaryConstructor_named_constructorName() async {
    await _testMarkedContent('''
class Aaa./*[0*/named/*0]*/() {
  this {}
}

Aaa a = Aaa./*[1*/named/*1]*/();
''');
  }

  Future<void> test_primaryConstructor_named_typeName() async {
    await _testMarkedContent('''
class /*[0*/Aaa/*0]*/.named() {
  this {}
}

/*[1*/Aaa/*1]*/ a = /*[2*/Aaa/*2]*/.named();
''');
  }

  Future<void> test_primaryConstructor_typeName() async {
    await _testMarkedContent('''
class /*[0*/Aaa/*0]*/() {
  this {}
}

/*[1*/Aaa/*1]*/ a = Aaa();
''');
  }

  Future<void> test_primaryConstructor_typeName_constructorInvocation() async {
    await _testMarkedContent('''
class Aaa() {
  this {}
}

Aaa a = /*[0*/Aaa/*0]*/();
''');
  }

  Future<void> test_recordType_typeName() async {
    await _testMarkedContent('''
/*[0*/double/*0]*/ f((/*[1*/double/*1]*/, /*[2*/double/*2]*/) param) {
  return 0.0;
}
''');
  }

  Future<void> test_shadow_inner() async {
    await _testMarkedContent('''
void f() {
  var foo = 1;
  func() {
    var /*[0*/foo/*0]*/ = 2;
    print(/*[1*/foo/*1]*/);
  }
}
''');
  }

  Future<void> test_shadow_outer() async {
    await _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  func() {
    var foo = 2;
    print(foo);
  }
  print(/*[1*/foo/*1]*/);
}
''');
  }

  Future<void> test_superFormalParameter_requiredPositional() async {
    await _testMarkedContent('''
class A {
  A(int x);
}

class B extends A {
  int y;

  B(super./*[0*/x/*0]*/) : y = /*[1*/x/*1]*/ * 2;
}
''');
  }

  Future<void> test_topLevelVariable() async {
    await _testMarkedContent('''
String /*[0*/foo/*0]*/ = 'bar';
void f() {
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = '';
}
''');
  }

  Future<void> test_topLevelVariable_underscore() async {
    await _testMarkedContent('''
String /*[0*/_/*0]*/ = 'bar';
void f(int _) {
  int _ = 1;
  print(/*[1*/_/*1]*/);
  /*[2*/_/*2]*/ = '';
}
''');
  }

  Future<void> test_type_class() async {
    await _testMarkedContent('''
void f() {
  /*[0*/int/*0]*/ a = 1;
  /*[1*/int/*1]*/ b = 2;
  /*[2*/int/*2]*/ c = 3;
}
/*[3*/int/*3]*/ VVV = 4;
''');
  }

  Future<void> test_type_class_constructors() async {
    await _testMarkedContent('''
class /*[0*/A/*0]*/ {
  A(); // Unnamed constructor is own entity
  /*[1*/A/*1]*/.named();
}

/*[2*/A/*2]*/ a = A(); // Unnamed constructor is own entity
var b = /*[3*/A/*3]*/.new();
var c = /*[4*/A/*4]*/.new;
''');
  }

  /// The type name in unnamed constructors are their own entity and not
  /// part of the type name.
  Future<void> test_type_class_constructors_unnamed() async {
    await _testMarkedContent('''
class A {
  /*[0*/A/*0]*/();
  A.named();
}

A a = /*[1*/A/*1]*/();
var b = A./*[2*/new/*2]*/();
var c = A./*[3*/new/*3]*/;
''');
  }

  Future<void> test_type_class_definition() async {
    await _testMarkedContent('''
class /*[0*/A/*0]*/ {}
/*[1*/A/*1]*/? a;
''');
  }

  Future<void> test_type_dynamic() async {
    await _testMarkedContent('''
void f() {
  /*[0*/dynamic/*0]*/ a = 1;
  /*[1*/dynamic/*1]*/ b = 2;
}
/*[2*/dynamic/*2]*/ V = 3;
''');
  }

  Future<void> test_type_void() async {
    await _testMarkedContent('''
vo^id f() {}
''');
  }

  Future<void> test_typeAlias_class() async {
    await _testMarkedContent('''
class MyClass {}
mixin MyMixin {}
class /*[0*/MyAlias/*0]*/ = MyClass with MyMixin;
/*[1*/MyAlias/*1]*/? a;
''');
  }

  Future<void> test_typeAlias_function() async {
    await _testMarkedContent('''
typedef /*[0*/myFunc/*0]*/();
/*[1*/myFunc/*1]*/? f;
''');
  }

  Future<void> test_typeAlias_generic() async {
    await _testMarkedContent('''
typedef /*[0*/TD/*0]*/ = String;

/*[1*/TD/*1]*/? a;
''');
  }

  Future<void> test_typeParameter_class() async {
    await _testMarkedContent('''
abstract class A</*[0*/ThisType/*0]*/> {
  /*[1*/ThisType/*1]*/ f();
}
''');
  }

  Future<void> test_typeParameter_enum() async {
    await _testMarkedContent('''
enum E</*[0*/ThisType/*0]*/> {
  a;

  /*[1*/ThisType/*1]*/ get t => throw Error();
}
''');
  }

  Future<void> test_typeParameter_extension() async {
    await _testMarkedContent('''
extension E</*[0*/ThisType/*0]*/> on /*[1*/ThisType/*1]*/ {
  /*[2*/ThisType/*2]*/ f() => this;
}
''');
  }

  Future<void> test_typeParameter_extensionType() async {
    await _testMarkedContent('''
extension type Et</*[0*/ThisType/*0]*/>(/*[1*/ThisType/*1]*/ value) {
  /*[2*/ThisType/*2]*/ get v => value;
}
''');
  }

  Future<void> test_typeParameter_function() async {
    await _testMarkedContent('''
/*[0*/ThisType/*0]*/ f</*[1*/ThisType/*1]*/>() => 0 as /*[2*/ThisType/*2]*/;
''');
  }

  Future<void> test_typeParameter_functionParameter() async {
    await _testMarkedContent('''
void f(/*[0*/ThisType/*0]*/ Function</*[1*/ThisType/*1]*/>() f) => f();
''');
  }

  Future<void> test_typeParameter_mixin() async {
    await _testMarkedContent('''
mixin M</*[0*/ThisType/*0]*/> {
  /*[1*/ThisType/*1]*/ get t;
}
''');
  }

  Future<void> test_typeParameter_typedef() async {
    await _testMarkedContent('''
typedef TypeDef</*[0*/ThisType/*0]*/> = /*[1*/ThisType/*1]*/ Function(/*[2*/ThisType/*2]*/);
''');
  }

  /// Create three nested loops for this [loopKeyword] (outer/middle/inner)
  /// with all combinations of `break`/`continue`  (and with.without labels)
  /// and verify that the middle [loopKeyword] and all exit keywords that
  /// relate to that loop produce mutual ranges including each other.
  Future<void> _testLoop(
    String loopKeyword,
    String loopStart,
    String loopEnd,
  ) async {
    var content =
        '''
void f() {
    outer:
    $loopKeyword $loopStart {
      middle:
      /*[0*/$loopKeyword/*0]*/ $loopStart {
        inner:
        $loopKeyword $loopStart {
          break;
          continue;
          break inner;
          continue inner;
          /*[1*/break/*1]*/ middle;
          /*[2*/continue/*2]*/ middle;
          break outer;
          continue outer;
        } $loopEnd
        /*[3*/break/*3]*/;
        /*[4*/continue/*4]*/;
        /*[5*/break/*5]*/ middle;
        /*[6*/continue/*6]*/ middle;
        break outer;
        continue outer;
      } $loopEnd
      break;
      continue;
      break outer;
      continue outer;
    } $loopEnd
}
''';
    await _testMarkedContent(content);
  }

  /// Tests highlights in a Dart file using the provided content.
  ///
  /// The content should be marked up using the [TestCode] format.
  ///
  /// If the content contains positions, they will be used to fetch highlights
  /// and the resulting ranges verified.
  ///
  /// If the content contains only ranges, then the start and end of every range
  /// will be tested to ensure the full set of ranges are returned mutually for
  /// each.
  Future<void> _testMarkedContent(String content) async {
    var code = TestCode.parse(content);
    expect(
      code.positions.isNotEmpty || code.ranges.isNotEmpty,
      isTrue,
      reason: 'At least one position or range should be marked in the content',
    );

    await initialize();
    await openFile(mainFileUri, code.code);

    var positions = code.positions.isNotEmpty
        ? code.positions.map((position) => position.position)
        : code.ranges.expand((range) => [range.range.start, range.range.end]);

    for (var position in positions) {
      var highlights = await getDocumentHighlights(mainFileUri, position);

      if (code.ranges.isEmpty) {
        expect(highlights, isEmpty);
      } else {
        code.verifyRanges(highlights!.map((highlight) => highlight.range));
      }
    }
  }
}
