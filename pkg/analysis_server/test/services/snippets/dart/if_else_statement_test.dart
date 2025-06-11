// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/if_else_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfElseStatementTest);
  });
}

@reflectiveTest
class IfElseStatementTest extends DartSnippetProducerTest {
  @override
  final generator = IfElseStatement.new;

  @override
  String get label => IfElseStatement.label;

  @override
  String get prefix => IfElseStatement.prefix;

  Future<void> test_ifElse() async {
    var code = r'''
void f() {
  if^
}
''';
    var expectedCode = r'''
void f() {
  if (condition) {
    ^
  } else {
    /**/
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_ifElse_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    if^
  }
}
''';
    var expectedCode = r'''
void f() {
  if (true) {
    if (condition) {
      ^
    } else {
      /**/
    }
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
