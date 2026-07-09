// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/while_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhileStatementTest);
  });
}

@reflectiveTest
class WhileStatementTest extends DartSnippetProducerTest {
  @override
  final generator = WhileStatement.new;

  @override
  String get label => WhileStatement.label;

  @override
  String get prefix => WhileStatement.prefix;

  Future<void> test_while() async {
    var code = r'''
void f() {
  while^
}
''';
    var expectedCode = r'''
void f() {
  while ([!condition!]) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
