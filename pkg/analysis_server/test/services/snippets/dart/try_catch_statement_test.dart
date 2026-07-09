// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/try_catch_statement.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryCatchStatementTest);
  });
}

@reflectiveTest
class TryCatchStatementTest extends DartSnippetProducerTest {
  @override
  final generator = TryCatchStatement.new;

  @override
  String get label => TryCatchStatement.label;

  @override
  String get prefix => TryCatchStatement.prefix;

  Future<void> test_tryCatch() async {
    var code = r'''
void f() {
  tr^
}
''';
    var expectedCode = r'''
void f() {
  try {
    ^
  } catch ([!e!]) {
    /**/
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }

  Future<void> test_tryCatch_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    tr^
  }
}
''';
    var expectedCode = r'''
void f() {
  if (true) {
    try {
      ^
    } catch ([!e!]) {
      /**/
    }
  }
}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
