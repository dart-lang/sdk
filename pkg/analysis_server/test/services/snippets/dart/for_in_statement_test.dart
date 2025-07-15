// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/for_in_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForInStatementTest);
  });
}

@reflectiveTest
class ForInStatementTest extends DartSnippetProducerTest {
  @override
  final generator = ForInStatement.new;

  @override
  String get label => ForInStatement.label;

  @override
  String get prefix => ForInStatement.prefix;

  Future<void> test_for() async {
    var code = r'''
void f() {
  forin^
}
''';
    var expectedCode = r'''
void f() {
  for (var /*[0*/element/*0]*/ in /*[1*/collection/*1]*/) {
    ^
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
