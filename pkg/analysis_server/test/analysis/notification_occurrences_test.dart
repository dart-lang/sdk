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

import '../analysis_abstract.dart';
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

  /// Asserts that there is an offset of [search] in [testOccurrences].
  void assertHasOffset(String search) {
    var offset = findOffset(search);
    expect(testOccurrences.offsets, contains(offset));
  }

  /// Validates that there is a region at the offset of [search] in [testFile].
  /// If [length] is not specified explicitly, then length of an identifier
  /// from [search] is used.
  void assertHasRegion(String search, [int length = -1]) {
    var offset = findOffset(search);
    if (length == -1) {
      length = findIdentifierLength(search);
    }
    findRegion(offset, length, true);
  }

  Future<void> assertOccurrences(
    String content, {
    ElementKind? kind,
    String? name,
  }) async {
    final code = TestCode.parse(content);
    addTestFile(code.code);

    await prepareOccurrences();
    // Find the result from the first range
    final range = code.ranges.first.sourceRange;
    findRegion(range.offset, range.length, true);

    expect(testOccurrences.element.kind, kind);
    expect(testOccurrences.element.name, name);
    expect(testOccurrences.offsets,
        containsAll(code.ranges.map((r) => r.sourceRange.offset)));
  }

  /// Finds an [Occurrences] with the given [offset] and [length].
  ///
  /// If [exists] is `true`, then fails if such [Occurrences] does not exist.
  /// Otherwise remembers this it into [testOccurrences].
  ///
  /// If [exists] is `false`, then fails if such [Occurrences] exists.
  void findRegion(int offset, int length, [bool? exists]) {
    for (var occurrences in occurrencesList) {
      if (occurrences.length != length) {
        continue;
      }
      for (var occurrenceOffset in occurrences.offsets) {
        if (occurrenceOffset == offset) {
          if (exists == false) {
            fail('Not expected to find (offset=$offset; length=$length) in\n'
                '${occurrencesList.join('\n')}');
          }
          testOccurrences = occurrences;
          return;
        }
      }
    }
    if (exists == true) {
      fail('Expected to find (offset=$offset; length=$length) in\n'
          '${occurrencesList.join('\n')}');
    }
  }

  Future<void> prepareOccurrences() async {
    await addAnalysisSubscription(AnalysisService.OCCURRENCES, testFile);
    return _resultsAvailable.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_OCCURRENCES) {
      var params = AnalysisOccurrencesParams.fromNotification(notification);
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
    await assertOccurrences(
      kind: ElementKind.LOCAL_VARIABLE,
      name: 'vvv',
      '''
void f() {
  var /*[0*/vvv/*0]*/ = 42;
  print(/*[1*/vvv/*1]*/);
}
      ''',
    );
  }

  Future<void> test_enum() async {
    await assertOccurrences(
      kind: ElementKind.ENUM,
      name: 'E',
      '''
enum /*[0*/E/*0]*/ {
  v;
}

void f(/*[1*/E/*1]*/ e) {
  /*[2*/E/*2]*/.v;
}
      ''',
    );
  }

  Future<void> test_enum_constant() async {
    await assertOccurrences(
      kind: ElementKind.ENUM_CONSTANT,
      name: 'v',
      '''
enum E {
  /*[0*/v/*0]*/;
}

void f() {
  E./*[1*/v/*1]*/;
}
      ''',
    );
  }

  Future<void> test_enum_field() async {
    await assertOccurrences(
      kind: ElementKind.FIELD,
      name: 'foo',
      '''
enum E {
  v;
  final int /*[0*/foo/*0]*/ = 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
      ''',
    );
  }

  Future<void> test_enum_getter() async {
    await assertOccurrences(
      kind: ElementKind.FIELD,
      name: 'foo',
      '''
enum E {
  v;
  int get /*[0*/foo/*0]*/ => 0;
}

void f(E e) {
  e./*[1*/foo/*1]*/;
}
      ''',
    );
  }

  Future<void> test_enum_method() async {
    await assertOccurrences(
      kind: ElementKind.METHOD,
      name: 'foo',
      '''
enum E {
  v;
  void /*[0*/foo/*0]*/() {}
}

void f(E e) {
  e./*[1*/foo/*1]*/();
}
      ''',
    );
  }

  Future<void> test_enum_setter() async {
    await assertOccurrences(
      kind: ElementKind.FIELD,
      name: 'foo',
      '''
enum E {
  v;
  set /*[0*/foo/*0]*/(int _) {}
}

void f(E e) {
  e./*[1*/foo/*1]*/ = 0;
}
      ''',
    );
  }

  Future<void> test_field() async {
    await assertOccurrences(
      kind: ElementKind.FIELD,
      name: 'fff',
      '''
class A {
  int /*[0*/fff/*0]*/;
  A(this./*[1*/fff/*1]*/);
  void f() {
    /*[2*/fff/*2]*/ = 42;
    print(/*[3*/fff/*3]*/);
  }
}
      ''',
    );
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

  Future<void> test_localVariable() async {
    await assertOccurrences(kind: ElementKind.LOCAL_VARIABLE, name: 'vvv', '''
void f() {
  var /*[0*/vvv/*0]*/ = 42;
  /*[1*/vvv/*1]*/ += 5;
  print(/*[2*/vvv/*2]*/);
}
''');
    assertHasRegion('vvv =');
    assertHasOffset('vvv = 42');
    assertHasOffset('vvv += 5');
    assertHasOffset('vvv);');
  }

  Future<void> test_memberField() async {
    await assertOccurrences(
      kind: ElementKind.FIELD,
      name: 'fff',
      '''
class A<T> {
  T /*[0*/fff/*0]*/;
}
void f() {
  var a = new A<int>();
  var b = new A<String>();
  a./*[1*/fff/*1]*/ = 1;
  b./*[2*/fff/*2]*/ = 2;
}
      ''',
    );
  }

  Future<void> test_memberMethod() async {
    await assertOccurrences(
      kind: ElementKind.METHOD,
      name: 'mmm',
      '''
class A<T> {
  T /*[0*/mmm/*0]*/() {}
}
void f() {
  var a = new A<int>();
  var b = new A<String>();
  a./*[1*/mmm/*1]*/();
  b./*[2*/mmm/*2]*/();
}
      ''',
    );
  }

  Future<void> test_mixin() async {
    await assertOccurrences(
      kind: ElementKind.MIXIN,
      name: 'A',
      '''
mixin /*[0*/A/*0]*/ {
  void aaa() {}
}
class B with /*[1*/A/*1]*/ {}
      ''',
    );
  }

  Future<void> test_parameter_named1() async {
    await assertOccurrences(
      kind: ElementKind.PARAMETER,
      name: 'ccc',
      '''
void f(int aaa, int bbb, {int? /*[0*/ccc/*0]*/, int? ddd}) {
  /*[1*/ccc/*1]*/;
  ddd;
}

void g() {
  f(0, /*[2*/ccc/*2]*/: 2, 1, ddd: 3);
}
      ''',
    );
  }

  Future<void> test_parameter_named2() async {
    await assertOccurrences(
      kind: ElementKind.PARAMETER,
      name: 'ddd',
      '''
void f(int aaa, int bbb, {int? ccc, int? /*[0*/ddd/*0]*/}) {
  ccc;
  /*[1*/ddd/*1]*/;
}

void g() {
  f(0, ccc: 2, 1, /*[2*/ddd/*2]*/: 3);
}
      ''',
    );
  }

  Future<void> test_superFormalParameter_requiredPositional() async {
    await assertOccurrences(
      kind: ElementKind.PARAMETER,
      name: 'x',
      '''
class A {
  A(int x);
}

class B extends A {
  int y;

  B(super./*[0*/x/*0]*/) : y = /*[1*/x/*1]*/ * 2;
}
      ''',
    );
  }

  Future<void> test_topLevelVariable() async {
    await assertOccurrences(
      kind: ElementKind.TOP_LEVEL_VARIABLE,
      name: 'VVV',
      '''
var /*[0*/VVV/*0]*/ = 1;
void f() {
  /*[1*/VVV/*1]*/ = 2;
  print(/*[2*/VVV/*2]*/);
}
      ''',
    );
  }

  Future<void> test_type_class() async {
    await assertOccurrences(
      kind: ElementKind.CLASS,
      name: 'int',
      '''
void f() {
  /*[0*/int/*0]*/ a = 1;
  /*[1*/int/*1]*/ b = 2;
  /*[2*/int/*2]*/ c = 3;
}
/*[3*/int/*3]*/ VVV = 4;
      ''',
    );
  }

  Future<void> test_type_class_definition() async {
    await assertOccurrences(
      kind: ElementKind.CLASS,
      name: 'A',
      '''
class /*[0*/A/*0]*/ {}
/*[1*/A/*1]*/ a;
      ''',
    );
  }

  Future<void> test_type_dynamic() async {
    addTestFile('''
void f() {
  dynamic a = 1;
  dynamic b = 2;
}
dynamic V = 3;
''');
    await prepareOccurrences();
    var offset = findOffset('dynamic a');
    findRegion(offset, 'dynamic'.length, false);
  }

  Future<void> test_type_void() async {
    addTestFile('''
void f() {
}
''');
    await prepareOccurrences();
    var offset = findOffset('void f()');
    findRegion(offset, 'void'.length, false);
  }
}
