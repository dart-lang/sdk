// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationOccurrencesTest);
  });
}

@reflectiveTest
class AnalysisNotificationOccurrencesTest extends PubPackageAnalysisServerTest {
  late List<Occurrences> occurrencesList;
  late Occurrences testOccurrences;

  final Completer<void> _resultsAvailable = Completer();

  Future<void> assertOccurrences(
    String content, {
    required ElementKind? kind,
    String? elementName,
  }) async {
    var code = TestCode.parseNormalized(content);
    addTestFile(code.code);

    await prepareOccurrences();
    // Find the result from the first range
    var range = code.ranges.first;
    var sourceRange = range.sourceRange;
    findRegion(
      sourceRange.offset,
      sourceRange.length,
      kind: kind,
      exists: true,
    );

    expect(testOccurrences.element.kind, kind);
    expect(testOccurrences.element.name, elementName ?? range.text);
    expect(
      testOccurrences.offsets,
      unorderedEquals(code.ranges.map((r) => r.sourceRange.offset)),
    );
  }

  /// Finds an [Occurrences] with the given [offset] and [length].
  ///
  /// If [kind] is provided, prefers a response with this kind if there
  /// are multiple matches.
  ///
  /// If [exists] is `true`, then fails if such [Occurrences] does not exist.
  /// Otherwise remembers this it into [testOccurrences].
  ///
  /// If [exists] is `false`, then fails if such [Occurrences] exists.
  void findRegion(int offset, int length, {ElementKind? kind, bool? exists}) {
    var searchDescription =
        '(offset=$offset; length=$length${kind != null ? ', kind=$kind' : ''})';
    for (var occurrences in occurrencesList) {
      if (occurrences.length != length) {
        continue;
      }
      for (var occurrenceOffset in occurrences.offsets) {
        if (occurrenceOffset == offset &&
            (kind == null || kind == occurrences.element.kind)) {
          if (exists == false) {
            fail(
              'Not expected to find ($searchDescription) in\n'
              '${occurrencesList.join('\n')}',
            );
          }
          testOccurrences = occurrences;
          return;
        }
      }
    }
    if (exists == true) {
      fail(
        'Expected to find ($searchDescription) in\n'
        '${occurrencesList.join('\n')}',
      );
    }
  }

  Future<void> prepareOccurrences() async {
    await addAnalysisSubscription(AnalysisService.OCCURRENCES, testFile);
    return _resultsAvailable.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == analysisNotificationOccurrences) {
      var params = AnalysisOccurrencesParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      if (params.file == testFile.path) {
        occurrencesList = params.occurrences;
        _resultsAvailable.complete();
      }
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_afterAnalysis() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f() {
  var /*[0*/vvv/*0]*/ = 42;
  print(/*[1*/vvv/*1]*/);
}
      ''');
  }

  Future<void> test_class_field_underscore() async {
    await assertOccurrences(kind: ElementKind.FIELD, '''
class C {
  int /*[0*/_/*0]*/ = 0;
}

void f(int _) {
  int _ = 1;
  C()./*[1*/_/*1]*/;
}
''');
  }

  Future<void> test_enum() async {
    await assertOccurrences(kind: ElementKind.ENUM, '''
enum /*[0*/E/*0]*/ {
  v;
}

void f(/*[1*/E/*1]*/ e) {
  /*[2*/E/*2]*/.v;
}
      ''');
  }

  Future<void> test_enum_constant() async {
    await assertOccurrences(kind: ElementKind.ENUM_CONSTANT, '''
enum E {
  /*[0*/v/*0]*/;
}

void f() {
  E./*[1*/v/*1]*/;
}
      ''');
  }

  Future<void> test_enum_field() async {
    await assertOccurrences(kind: ElementKind.FIELD, '''
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
    await assertOccurrences(kind: ElementKind.GETTER, '''
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
    await assertOccurrences(kind: ElementKind.METHOD, '''
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
    await assertOccurrences(kind: ElementKind.SETTER, '''
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
    await assertOccurrences(kind: ElementKind.EXTENSION, '''
void foo(int i) {
  /*[0*/E/*0]*/(i).self;
}

extension /*[1*/E/*1]*/<ThisType> on ThisType {
  ThisType get self => this;
}
''');
  }

  Future<void> test_extensionMember() async {
    await assertOccurrences(kind: ElementKind.GETTER, '''
extension on int {
  int get /*[0*/foo/*0]*/ => 0;
}

void f(int v) {
  v./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_extensionMember_diferenciation() async {
    await assertOccurrences(kind: ElementKind.GETTER, '''
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
    await assertOccurrences(kind: ElementKind.EXTENSION_TYPE, '''
extension type /*[0*/E/*0]*/(int it) {}

void f(/*[1*/E/*1]*/ e) {}
''');
  }

  Future<void> test_extensionType_constructor_primary() async {
    await assertOccurrences(
      kind: ElementKind.CONSTRUCTOR,
      elementName: 'E.named',
      '''
extension type E./*[0*/named/*0]*/(int it) {}

void f() {
  E./*[1*/named/*1]*/(0);
}
''',
    );
  }

  Future<void> test_extensionType_constructor_secondary() async {
    await assertOccurrences(
      kind: ElementKind.CONSTRUCTOR,
      elementName: 'E.named',
      '''
extension type E(int it) {
  E./*[0*/named/*0]*/() : this(0);
}

void f() {
  E./*[1*/named/*1]*/();
}
''',
    );
  }

  Future<void> test_extensionType_getter() async {
    await assertOccurrences(kind: ElementKind.GETTER, '''
extension type E(int it) {
  int get /*[0*/foo/*0]*/ => 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
''');
  }

  Future<void> test_extensionType_method() async {
    await assertOccurrences(kind: ElementKind.METHOD, '''
extension type E(int it) {
  void /*[0*/foo/*0]*/() {}
}

void f(E e) {
  e./*[1*/foo/*1]*/();
}
''');
  }

  Future<void> test_extensionType_setter() async {
    await assertOccurrences(kind: ElementKind.SETTER, '''
extension type E(int it) {
  set /*[0*/foo/*0]*/(int _) {}
}

void f(E e) {
  e./*[1*/foo/*1]*/ = 0;
}
''');
  }

  Future<void> test_field() async {
    await assertOccurrences(kind: ElementKind.FIELD, '''
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
    addTestFile('''
class A {
  A(this.noSuchField);
}
''');
    // no checks for occurrences, just ensure that there is no NPE
    await prepareOccurrences();
  }

  Future<void> test_for_in() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f() {
  for (final /*[0*/x^/*0]*/ in []) {
    /*[1*/x/*1]*/;
  }
}
      ''');
  }

  Future<void> test_localVariable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f() {
  var /*[0*/vvv/*0]*/ = 42;
  /*[1*/vvv/*1]*/ += 5;
  print(/*[2*/vvv/*2]*/);
}
      ''');
  }

  Future<void> test_memberField() async {
    await assertOccurrences(kind: ElementKind.FIELD, '''
class A<T> {
  T /*[0*/fff/*0]*/;
}
void f() {
  var a = new A<int>();
  var b = new A<String>();
  a./*[1*/fff/*1]*/ = 1;
  b./*[2*/fff/*2]*/ = '';
}
      ''');
  }

  Future<void> test_memberMethod() async {
    await assertOccurrences(kind: ElementKind.METHOD, '''
class A<T> {
  T /*[0*/mmm/*0]*/() {}
}
void f() {
  var a = new A<int>();
  var b = new A<String>();
  a./*[1*/mmm/*1]*/();
  b./*[2*/mmm/*2]*/();
}
      ''');
  }

  Future<void> test_mixin() async {
    await assertOccurrences(kind: ElementKind.MIXIN, '''
mixin /*[0*/A/*0]*/ {
  void aaa() {}
}
class B with /*[1*/A/*1]*/ {}
      ''');
  }

  Future<void> test_parameter_named1() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(int aaa, int bbb, {int? /*[0*/ccc/*0]*/, int? ddd}) {
  /*[1*/ccc/*1]*/;
  ddd;
}

void g() {
  f(0, /*[2*/ccc/*2]*/: 2, 1, ddd: 3);
}
      ''');
  }

  Future<void> test_parameter_named2() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(int aaa, int bbb, {int? ccc, int? /*[0*/ddd/*0]*/}) {
  ccc;
  /*[1*/ddd/*1]*/;
}

void g() {
  f(0, ccc: 2, 1, /*[2*/ddd/*2]*/: 3);
}
      ''');
  }

  Future<void> test_parameter_privateNamed() async {
    // TODO(rnystrom): The legacy protocol requires all occurrences to have the
    // same length. Since the argument name uses the corresponding public name,
    // it doesn't show up as an occurence for the field element. The LSP
    // implementation doesn't have this problem.
    // https://github.com/dart-lang/sdk/issues/62607
    await assertOccurrences(kind: ElementKind.FIELD, '''
    class C {
      int? /*[0*/_aaa/*0]*/;
      C({this./*[1*/_aaa/*1]*/});
    }

    void f() {
      C(aaa: 123);
    }
      ''');
  }

  Future<void> test_parameter_wildcard() async {
    // Ensure no crash.
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(int /*[0*/_/*0]*/) {}
''');
  }

  Future<void> test_pattern_assignment() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(String /*[0*/a/*0]*/, String b) {
  (b, /*[1*/a/*1]*/) = (/*[2*/a/*2]*/, b);
}
      ''');
  }

  Future<void> test_pattern_assignment_list() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(List<int> x, num /*[0*/a/*0]*/) {
  [/*[1*/a/*1]*/] = x;
}
    );
      ''');
  }

  Future<void> test_pattern_cast_typeName() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
/*[0*/String/*0]*/ f((num, /*[1*/String/*1]*/) record) {
  var (i as int, s as /*[2*/String/*2]*/) = record;
}
    );
     ''');
  }

  Future<void> test_pattern_cast_variable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f((num, String) record) {
  var (i as int, /*[0*/s/*0]*/ as String) = record;
  print(/*[1*/s/*1]*/);
}
    );
      ''');
  }

  Future<void> test_pattern_map() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f(x) {
  switch (x) {
    case {0: String /*[0*/a/*0]*/}:
      print(/*[1*/a/*1]*/);
      break;
  }
}
    );
      ''');
  }

  Future<void> test_pattern_map_typeArguments() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
/*[0*/String/*0]*/ f(x) {
  switch (x) {
    case <int, /*[1*/String/*1]*/>{0: var a}:
      return a;
      break;
  }
}
    );
      ''');
  }

  Future<void> test_pattern_nullAssert() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f((int?, int?) position) {
  var (x!, /*[0*/y/*0]*/!) = position;
  print(/*[1*/y/*1]*/);
}
    );
      ''');
  }

  Future<void> test_pattern_nullCheck() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
void f(String? maybeString) {
  switch (maybeString) {
    case var /*[0*/s/*0]*/?:
      print(/*[1*/s/*1]*/);
  }
}
    );
    ''');
  }

  Future<void> test_pattern_object_destructure_getter() async {
    await assertOccurrences(kind: ElementKind.FIELD, '''
class A {
  String? /*[0*/key/*0]*/;
}

void f() {
  final A(:/*[1*/key/*1]*/) = A();
}
      ''');
  }

  Future<void> test_pattern_object_destructure_variable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
class A {
  String? key;
}

void f() {
  final A(:/*[0*/key/*0]*/) = A();
  /*[1*/key/*1]*/;
}
      ''');
  }

  Future<void> test_pattern_object_fieldName() async {
    await assertOccurrences(kind: ElementKind.GETTER, '''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(/*[0*/length/*0]*/: var l) => l * l,
  };

class Shape { }
class Square extends Shape {
  double get /*[1*/length/*1]*/ => 0;
}
      ''');
  }

  Future<void> test_pattern_object_typeName() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
double calculateArea(Shape shape) =>
  switch (shape) {
    /*[0*/Square/*0]*/(length: var l) => l * l,
  };

class Shape { }
class /*[1*/Square/*1]*/ extends Shape {
  double get length => 0;
}
    );
      ''');
  }

  Future<void> test_pattern_object_variable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
double calculateArea(Shape shape) =>
  switch (shape) {
    Square(length: var /*[0*/l/*0]*/) => /*[1*/l/*1]*/ * /*[2*/l/*2]*/,
  };

class Shape { }
class Square extends Shape {
  double get length => 0;
}
    );
      ''');
  }

  Future<void> test_pattern_record_variable() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
void f(({int foo}) x, num /*[0*/a/*0]*/) {
  (foo: /*[1*/a/*1]*/,) = x;
}
    );
      ''');
  }

  Future<void> test_pattern_relational_variable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
String f(int char) {
  const /*[0*/zero/*0]*/ = 0;
  return switch (char) {
    == /*[1*/zero/*1]*/ => 'zero'
  };
}
    );
      ''');
  }

  Future<void> test_patternVariable_ifCase_logicalOr() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, '''
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
    await assertOccurrences(kind: ElementKind.PREFIX, '''
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
    // Note, we use `core` just to have some prefix.
    // The actual check is no crash on unresolved `prefix`.
    await assertOccurrences(kind: ElementKind.PREFIX, '''
import 'dart:core' as /*[0*/core/*0]*/;
void f(prefix.A? _, /*[1*/core.int/*1]*/ _) {}
''');
  }

  Future<void> test_prefix_wildcard() async {
    // Ensure no crash.
    await assertOccurrences(kind: ElementKind.PREFIX, '''
import 'dart:io' as /*[0*/_/*0]*/;
''');
  }

  Future<void> test_prefixed() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
import '' as p;

class /*[0*/A/*0]*/ {}

p./*[1*/A/*1]*/? a;
''');
  }

  Future<void> test_primaryConstructor_named_constructorName() async {
    await assertOccurrences(
      kind: ElementKind.CONSTRUCTOR,
      elementName: 'Aaa.named',
      '''
class Aaa./*[0*/named/*0]*/() {
  this {}
}

Aaa a = Aaa./*[1*/named/*1]*/();
''',
    );
  }

  Future<void> test_primaryConstructor_named_typeName() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
class /*[0*/Aaa/*0]*/.named() {
  this {}
}

/*[1*/Aaa/*1]*/ a = /*[2*/Aaa/*2]*/.named();
''');
  }

  Future<void> test_primaryConstructor_unnamed_constructorInvocation() async {
    await assertOccurrences(kind: ElementKind.CONSTRUCTOR, '''
class Aaa() {
  this {}
}

Aaa a = /*[0*/Aaa/*0]*/();
''');
  }

  Future<void> test_primaryConstructor_unnamed_typeName() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
class /*[0*/Aaa/*0]*/() {
  this {}
}

/*[1*/Aaa/*1]*/ a = Aaa();
''');
  }

  Future<void> test_recordType_typeName() async {
    await assertOccurrences(kind: ElementKind.CLASS, r'''
/*[0*/double/*0]*/ f((/*[1*/double/*1]*/, /*[2*/double/*2]*/) param) {
}
    );
      ''');
  }

  Future<void> test_superFormalParameter_requiredPositional() async {
    await assertOccurrences(kind: ElementKind.PARAMETER, '''
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
    await assertOccurrences(kind: ElementKind.TOP_LEVEL_VARIABLE, '''
var /*[0*/VVV/*0]*/ = 1;
void f() {
  /*[1*/VVV/*1]*/ = 2;
  print(/*[2*/VVV/*2]*/);
}
      ''');
  }

  Future<void> test_topLevelVariable_underscore() async {
    await assertOccurrences(kind: ElementKind.TOP_LEVEL_VARIABLE, '''
int /*[0*/_/*0]*/ = 0;

void f(int _) {
  int _ = 1;
  /*[1*/_/*1]*/;
}
''');
  }

  Future<void> test_type_class() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
void f() {
  /*[0*/int/*0]*/ a = 1;
  /*[1*/int/*1]*/ b = 2;
  /*[2*/int/*2]*/ c = 3;
}
/*[3*/int/*3]*/ VVV = 4;
      ''');
  }

  Future<void> test_type_class_constructors() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
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
  ///
  /// For the legacy protocol, "new" is not treated as a reference to the
  /// constructor because the protocol currently only supports same-length
  /// occurrences.
  Future<void> test_type_class_constructors_unnamed() async {
    await assertOccurrences(kind: ElementKind.CONSTRUCTOR, '''
class A {
  /*[0*/A/*0]*/();
  A.named();
}

A a = /*[1*/A/*1]*/();
var b = A.new();
var c = A.new;
      ''');
  }

  Future<void> test_type_class_definition() async {
    await assertOccurrences(kind: ElementKind.CLASS, '''
class /*[0*/A/*0]*/ {}
/*[1*/A/*1]*/ a;
      ''');
  }

  Future<void> test_type_dynamic() async {
    await assertOccurrences(kind: ElementKind.UNKNOWN, '''
void f() {
  /*[0*/dynamic/*0]*/ a = 1;
  /*[1*/dynamic/*1]*/ b = 2;
}
/*[2*/dynamic/*2]*/ V = 3;
''');
  }

  Future<void> test_type_void() async {
    addTestFile('''
void f() {
}
''');
    await prepareOccurrences();
    var offset = findOffset('void f()');
    findRegion(offset, 'void'.length, exists: false);
  }

  Future<void> test_typeParameter_class() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
abstract class A</*[0*/ThisType/*0]*/> {
  /*[1*/ThisType/*1]*/ f();
}
''');
  }

  Future<void> test_typeParameter_enum() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
enum E</*[0*/ThisType/*0]*/> {
  a;

  /*[1*/ThisType/*1]*/ get t => throw UnimplementedError();
}
''');
  }

  Future<void> test_typeParameter_extension() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
extension E</*[0*/ThisType/*0]*/> on /*[1*/ThisType/*1]*/ {
  /*[2*/ThisType/*2]*/ f() => this;
}
''');
  }

  Future<void> test_typeParameter_extensionType() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
extension type Et</*[0*/ThisType/*0]*/>(/*[1*/ThisType/*1]*/ value) {
  /*[2*/ThisType/*2]*/ get v => value;
}
''');
  }

  Future<void> test_typeParameter_function() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
/*[0*/ThisType/*0]*/ f</*[1*/ThisType/*1]*/>() => 0 as /*[2*/ThisType/*2]*/;
''');
  }

  Future<void> test_typeParameter_functionParameter() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
void f(/*[0*/ThisType/*0]*/ Function</*[1*/ThisType/*1]*/>() f) => f();
''');
  }

  Future<void> test_typeParameter_mixin() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
mixin M</*[0*/ThisType/*0]*/> {
  /*[1*/ThisType/*1]*/ get t;
}
''');
  }

  Future<void> test_typeParameter_typedef() async {
    await assertOccurrences(kind: ElementKind.TYPE_PARAMETER, '''
typedef TypeDef</*[0*/ThisType/*0]*/> = /*[1*/ThisType/*1]*/ Function(/*[2*/ThisType/*2]*/);
''');
  }
}
