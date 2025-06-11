// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/switch_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementTest);
  });
}

@reflectiveTest
class SwitchStatementTest extends DartSnippetProducerTest {
  @override
  final generator = SwitchStatement.new;

  @override
  String get label => SwitchStatement.label;

  @override
  String get prefix => SwitchStatement.prefix;

  Future<void> test_switch() async {
    var code = r'''
void f() {
  sw^
}
''';
    var expectedCode = r'''
void f() {
  switch (/*[0*/expression/*0]*/) {
    case /*[1*/value/*1]*/:
      ^
      break;
    default:
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_switch_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    sw^
  }
}
''';
    var expectedCode = r'''
void f() {
  if (true) {
    switch (/*[0*/expression/*0]*/) {
      case /*[1*/value/*1]*/:
        ^
        break;
      default:
    }
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
