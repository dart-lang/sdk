// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/do_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DoStatementTest);
  });
}

@reflectiveTest
class DoStatementTest extends DartSnippetProducerTest {
  @override
  final generator = DoStatement.new;

  @override
  String get label => DoStatement.label;

  @override
  String get prefix => DoStatement.prefix;

  Future<void> test_do() async {
    var code = r'''
void f() {
  do^
}
''';
    var expectedCode = r'''
void f() {
  do {
    ^
  } while ([!condition!]);
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
