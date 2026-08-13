// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/class_declaration.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationTest);
  });
}

@reflectiveTest
class ClassDeclarationTest extends DartSnippetProducerTest {
  @override
  final generator = ClassDeclaration.new;

  @override
  String get label => ClassDeclaration.label;

  @override
  String get prefix => ClassDeclaration.prefix;

  Future<void> test_class() async {
    var code = r'''
class A {}

^

class B {}
''';
    var expectedCode = r'''
class A {}

class [!ClassName!] {
  ^
}

class B {}
''';
    await assertSnippetResult(code, expectedCode);
  }
}
