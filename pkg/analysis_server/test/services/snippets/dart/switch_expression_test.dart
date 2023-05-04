// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/switch_expression.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchExpressionTest);
  });
}

@reflectiveTest
class SwitchExpressionTest extends DartSnippetProducerTest {
  @override
  final generator = SwitchExpression.new;

  @override
  String get label => SwitchExpression.label;

  @override
  String get prefix => SwitchExpression.prefix;

  Future<void> test_switch() async {
    final code = r'''
void f() {
  var a = sw^
}
    ''';
    final expectedCode = '''
void f() {
  var a = switch (/*[0*/expression/*0]*/) {
    /*[1*/pattern/*1]*/ => /*[2*/value/*2]*/,^
  }
}
    ''';
    await assertSnippet(code, expectedCode);
  }

  Future<void> test_switch_nested() async {
    final code = r'''
int f(String a, int b) {
  return switch (a) {
    _ => sw^
  };
}
    ''';
    final expectedCode = '''
int f(String a, int b) {
  return switch (a) {
    _ => switch (/*[0*/expression/*0]*/) {
      /*[1*/pattern/*1]*/ => /*[2*/value/*2]*/,^
    }
  };
}
    ''';
    await assertSnippet(code, expectedCode);
  }
}
