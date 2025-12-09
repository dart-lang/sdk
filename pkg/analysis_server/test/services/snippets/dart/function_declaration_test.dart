// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/function_declaration.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionDeclarationTest);
  });
}

@reflectiveTest
class FunctionDeclarationTest extends DartSnippetProducerTest {
  @override
  final generator = FunctionDeclaration.new;

  @override
  String get label => FunctionDeclaration.label;

  @override
  String get prefix => FunctionDeclaration.prefix;

  Future<void> test_classMethod() async {
    var code = r'''
class A {
  ^
}
''';
    var expectedCode = r'''
class A {
  /*[0*/void/*0]*/ /*[1*/name/*1]*/(/*[2*/params/*2]*/) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_enum_member() async {
    var code = r'''
enum A {
  a;
  ^
}
''';
    var expectedCode = r'''
enum A {
  a;
  /*[0*/void/*0]*/ /*[1*/name/*1]*/(/*[2*/params/*2]*/) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_nested() async {
    var code = r'''
void a() {
  ^
}
''';
    var expectedCode = r'''
void a() {
  /*[0*/void/*0]*/ /*[1*/name/*1]*/(/*[2*/params/*2]*/) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_topLevel() async {
    var code = r'''
class A {}

^

class B {}
''';
    var expectedCode = r'''
class A {}

/*[0*/void/*0]*/ /*[1*/name/*1]*/(/*[2*/params/*2]*/) {
  ^
}

class B {}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
