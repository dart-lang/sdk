// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../completion_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentListCompletionTest);
    defineReflectiveTests(ConstructorCompletionTest);
    defineReflectiveTests(ExtensionCompletionTest);
    defineReflectiveTests(PropertyAccessorCompletionTest);
  });
}

@reflectiveTest
class ArgumentListCompletionTest extends CompletionTestCase {
  Future<void> test_functionWithVoidReturnType() async {
    addTestFile('''
void f(C c) {
  c.m(^);
}

void g() {}

class C {
  void m(void Function() handler) {}
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }
}

@reflectiveTest
class ConstructorCompletionTest extends CompletionTestCase {
  Future<void> test_constructor_abstract() async {
    addTestFile('''
void f() {
  g(^);
}
void g(C c) {}
abstract class C {
  C.c();
}
''');
    await getSuggestions();
    assertHasNoCompletion('C.c');
  }
}

@reflectiveTest
class ExtensionCompletionTest extends CompletionTestCase {
  Future<void> test_explicitTarget_getter_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  int get g => length;
}
''');
    await getSuggestions();
    assertHasCompletion('g');
  }

  Future<void> test_explicitTarget_method_imported() async {
    newFile(convertPath('/project/bin/lib.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
import 'lib.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inLibrary() async {
    newFile(convertPath('/project/bin/lib.dart'), content: '''
part 'test.dart';
extension E on String {
  void m() {}
}
''');
    addTestFile('''
part of 'lib.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_inPart() async {
    newFile(convertPath('/project/bin/part.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
part 'part.dart';
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  @failingTest
  Future<void> test_explicitTarget_method_notImported() async {
    // Available suggestions data doesn't yet have information about extension
    // methods.
    newFile(convertPath('/project/bin/lib.dart'), content: '''
extension E on String {
  void m() {}
}
''');
    addTestFile('''
void f(String s) {
  s.^;
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_method_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  void m() {}
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_explicitTarget_setter_sameUnit() async {
    addTestFile('''
void f(String s) {
  s.^;
}
extension E on String {
  set e(int v) {}
}
''');
    await getSuggestions();
    assertHasCompletion('e');
  }

  Future<void> test_implicitTarget_inClass_method_sameUnit() async {
    addTestFile('''
class C {
  void c() {
    ^
  }
}
extension E on C {
  void m() {}
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }

  Future<void> test_implicitTarget_inExtension_method_sameUnit() async {
    addTestFile('''
extension E on String {
  void m() {
    ^
  }
}
''');
    await getSuggestions();
    assertHasCompletion('m');
  }
}

@reflectiveTest
class PropertyAccessorCompletionTest extends CompletionTestCase {
  Future<void> test_setter_deprecated() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.SETTER, isDeprecated: true);
  }

  Future<void> test_setter_deprecated_withNonDeprecatedGetter() async {
    addTestFile('''
void f(C c) {
  c.^;
}
class C {
  int get x => 0;
  @deprecated
  set x(int x) {}
}
''');
    await getSuggestions();
    assertHasCompletion('x',
        elementKind: ElementKind.GETTER, isDeprecated: false);
  }
}
