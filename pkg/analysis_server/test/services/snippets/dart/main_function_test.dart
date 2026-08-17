// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/main_function.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainFunctionBinFolderTest);
    defineReflectiveTests(MainFunctionProjectRootTest);
    defineReflectiveTests(MainFunctionTest);
    defineReflectiveTests(MainFunctionTestFolderTest);
    defineReflectiveTests(MainFunctionToolFolderTest);
  });
}

@reflectiveTest
class MainFunctionBinFolderTest extends MainFunctionTest {
  @override
  String get testFilePath => convertPath('$testPackageLibPath/bin/main.dart');

  Future<void> test_noPrefix() async {
    await assertSnippetResult('^', '''
void main(List<String> args) {
  ^
}''');
  }

  Future<void> test_typedPrefix() async {
    await assertSnippetResult('$prefix^', '''
void main(List<String> args) {
  ^
}''');
  }
}

@reflectiveTest
class MainFunctionProjectRootTest extends MainFunctionTest {
  @override
  String get testFilePath => convertPath('$testPackageRootPath/foo.dart');

  Future<void> test_noPrefix() async {
    await assertSnippetResult('^', '''
void main(List<String> args) {
  ^
}''');
  }

  Future<void> test_typedPrefix() async {
    await assertSnippetResult('$prefix^', '''
void main(List<String> args) {
  ^
}''');
  }
}

@reflectiveTest
class MainFunctionTest extends DartSnippetProducerTest {
  @override
  final generator = MainFunction.new;

  @override
  String get label => MainFunction.label;

  @override
  String get prefix => MainFunction.prefix;
}

@reflectiveTest
class MainFunctionTestFolderTest extends MainFunctionTest {
  @override
  String get testFilePath => convertPath('$testPackageTestPath/foo_test.dart');

  Future<void> test_noPrefix() async {
    await assertSnippetResult('^', '''
void main() {
  ^
}''');
  }

  Future<void> test_typedPrefix() async {
    await assertSnippetResult('$prefix^', '''
void main() {
  ^
}''');
  }
}

@reflectiveTest
class MainFunctionToolFolderTest extends MainFunctionTest {
  @override
  String get testFilePath => convertPath('$testPackageLibPath/tool/tool.dart');

  Future<void> test_noPrefix() async {
    await assertSnippetResult('^', '''
void main(List<String> args) {
  ^
}''');
  }

  Future<void> test_typedPrefix() async {
    await assertSnippetResult('$prefix^', '''
void main(List<String> args) {
  ^
}''');
  }
}
