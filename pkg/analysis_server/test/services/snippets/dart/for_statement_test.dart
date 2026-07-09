// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/for_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForStatementTest);
  });
}

@reflectiveTest
class ForStatementTest extends DartSnippetProducerTest {
  @override
  final generator = ForStatement.new;

  @override
  String get label => ForStatement.label;

  @override
  String get prefix => ForStatement.prefix;

  Future<void> test_for() async {
    var code = r'''
void f() {
  for^
}
''';
    var expectedCode = r'''
void f() {
  for (var i = 0; i < [!count!]; i++) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
