// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';
import '../completion_printer.dart' as printer;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeTest);
  });
}

@reflectiveTest
class RecordTypeTest extends AbstractCompletionDriverTest
    with RecordTypeTestCases {}

mixin RecordTypeTestCases on AbstractCompletionDriverTest {
  @override
  Future<void> setUp() async {
    await super.setUp();

    printerConfiguration = printer.Configuration(
      filter: (suggestion) => true,
      withReturnType: true,
    );
  }

  Future<void> test_fromExtension_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on (int,) {
  void foo() {}
}
''');

    await computeSuggestions('''
import 'a.dart';

void f((int,) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  $1
    kind: identifier
    returnType: int
  foo
    kind: methodInvocation
    returnType: void
  toString
    kind: methodInvocation
    returnType: String
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }

  Future<void> test_fromExtension_local() async {
    await computeSuggestions('''
void f((int,) r) {
  r.^
}

extension on (int,) {
  void foo() {}
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  $1
    kind: identifier
    returnType: int
  foo
    kind: methodInvocation
    returnType: void
  toString
    kind: methodInvocation
    returnType: String
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }

  Future<void> test_fromExtension_notImported() async {
    newFile('$testPackageLibPath/a.dart', r'''
extension E on (int,) {
  void foo() {}
}
''');

    await computeSuggestions('''
void f((int,) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  $1
    kind: identifier
    returnType: int
  toString
    kind: methodInvocation
    returnType: String
  foo
    kind: methodInvocation
    returnType: void
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }

  Future<void> test_mixed() async {
    await computeSuggestions('''
void f((int, {String foo02}) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  $1
    kind: identifier
    returnType: int
  foo02
    kind: identifier
    returnType: String
  toString
    kind: methodInvocation
    returnType: String
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }

  Future<void> test_named() async {
    await computeSuggestions('''
void f(({int foo01, String foo02}) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  foo01
    kind: identifier
    returnType: int
  foo02
    kind: identifier
    returnType: String
  toString
    kind: methodInvocation
    returnType: String
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }

  Future<void> test_positional() async {
    await computeSuggestions('''
void f((int, String) r) {
  r.^
}
''');

    assertResponse(r'''
suggestions
  hashCode
    kind: getter
    returnType: int
  runtimeType
    kind: getter
    returnType: Type
  $1
    kind: identifier
    returnType: int
  $2
    kind: identifier
    returnType: String
  toString
    kind: methodInvocation
    returnType: String
  jsify
    kind: methodInvocation
    returnType: JSAny?
  noSuchMethod
    kind: methodInvocation
    returnType: dynamic
''');
  }
}
