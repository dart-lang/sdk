// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/if_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementTest);
  });
}

@reflectiveTest
class IfStatementTest extends DartSnippetProducerTest {
  @override
  final generator = IfStatement.new;

  @override
  String get label => IfStatement.label;

  @override
  String get prefix => IfStatement.prefix;

  Future<void> test_if() async {
    var code = r'''
void f() {
  if^
}
''';
    var expectedCode = r'''
void f() {
  if ([!condition!]) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_if_indentedInsideBlock() async {
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
    if ([!condition!]) {
      ^
    }
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
