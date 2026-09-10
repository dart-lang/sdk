// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';
import 'utils/semantic_tokens.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SemanticTokensTest);
  });
}

@reflectiveTest
class SemanticTokensTest extends AbstractLspAnalysisServerTest
    with SemanticTokensTestMixin {
  Future<void> test_annotation() async {
    var content = '''
import 'other_file.dart' as other;

@a
@A()
@A.n()
@B(A())
@other.C()
@other.C.n()
void foo() {}

class A {
  const A();
  const A.n();
}

const a = A();

class B {
  final A a;
  const B(this.a);
}
''';

    var otherContent = '''
class C {
  const C();
  const C.n();
}
''';

    var code = TestCode.parseNormalized(content);
    var otherCode = TestCode.parseNormalized(otherContent);

    var expectedStart = [
      Token('import', .keyword),
      Token("'other_file.dart'", .string),
      Token('as', .keyword),
      Token('other', .variable, [.importPrefix]),
      Token('@', .annotation),
      Token('a', .property, [.annotation]),
      Token('@', .annotation),
      Token('A', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('@', .annotation),
      Token('A', .class_, [.annotation]),
      Token('.', .annotation),
      Token('n', .method, [.constructor, .annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('@', .annotation),
      Token('B', .class_, [.annotation]),
      Token('(', .annotation),
      Token('A', .class_, [.constructor]),
      Token(')', .annotation),
      Token('@', .annotation),
      Token('other', .variable, [.importPrefix]),
      Token('.', .annotation),
      Token('C', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('@', .annotation),
      Token('other', .variable, [.importPrefix]),
      Token('.', .annotation),
      Token('C', .class_, [.annotation]),
      Token('.', .annotation),
      Token('n', .method, [.constructor, .annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('void', .keyword, [.void_]),
      Token('foo', .function, [.declaration, .static]),
    ];

    var otherFilePath = join(projectFolderPath, 'lib', 'other_file.dart');

    newFile(mainFilePath, code.code);
    newFile(otherFilePath, otherCode.code);
    await initialize();

    var tokens = await getSemanticTokens(mainFileUri);
    var decoded = decodeSemanticTokens(code.code, tokens);
    expect(
      // Only check the first expectedStart.length items since the test code
      // is mostly unrelated to the annotations.
      decoded.sublist(0, expectedStart.length),
      equals(expectedStart),
    );
  }

  Future<void> test_annotation_parameter() async {
    var content = '''
class MyAnnotation {
  const MyAnnotation();
}

class A {
  A([!@MyAnnotation() String a!]);
}
''';

    var expected = [
      Token('@', .annotation),
      Token('MyAnnotation', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('String', .class_),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_annotation_parameter_super() async {
    var content = '''
class MyAnnotation {
  const MyAnnotation();
}

class A {
  A(String a);
}

class B extends A {
  B([!@MyAnnotation() super.a!]);
}
''';

    var expected = [
      Token('@', .annotation),
      Token('MyAnnotation', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_annotation_parameter_super_fieldFormal() async {
    var content = '''
class MyAnnotation {
  const MyAnnotation();
}

class A {
  String a;
  A(this.a);
}

class B extends A {
  B([!@MyAnnotation() super.a!]);
}
''';

    var expected = [
      Token('@', .annotation),
      Token('MyAnnotation', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_annotation_parameter_this() async {
    var content = '''
class MyAnnotation {
  const MyAnnotation();
}

class A {
  String a;
  A([!@MyAnnotation() this.a!]);
}
''';

    var expected = [
      Token('@', .annotation),
      Token('MyAnnotation', .class_, [.annotation]),
      Token('(', .annotation),
      Token(')', .annotation),
      Token('this', .keyword),
      Token('a', .variable, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_augmentations() async {
    var mainContent = '''
part 'main_augmentation.dart';

class A {
  void f() {}
  String get g;
}
''';

    var augmentationContent = '''
part of 'main.dart';

augment class A {
  augment void f();
  augment get g => 'augmented';
}
''';

    newFile(mainFilePath, mainContent);
    newFile(mainFileAugmentationPath, augmentationContent);
    await initialize();

    // Main library.
    await _verifyTokens(mainFileUri, mainContent, [
      Token('part', .keyword),
      Token("'main_augmentation.dart'", .string),
      Token('class', .keyword),
      Token('A', .class_, [.declaration]),
      Token('void', .keyword, [.void_]),
      Token('f', .method, [.declaration, .instance]),
      Token('String', .class_),
      Token('get', .keyword),
      Token('g', .property, [.declaration, .instance]),
    ]);

    // Augmentation.
    await _verifyTokens(mainFileAugmentationUri, augmentationContent, [
      Token('part of', .keyword),
      Token("'main.dart'", .string),
      Token('augment', .keyword),
      Token('class', .keyword),
      Token('A', .class_, [.declaration]),
      Token('augment', .keyword),
      Token('void', .keyword, [.void_]),
      Token('f', .method, [.declaration, .instance]),
      Token('augment', .keyword),
      Token('get', .keyword),
      Token('g', .property, [.declaration, .instance]),
      Token("'augmented'", .string),
    ]);
  }

  Future<void> test_class() async {
    var content = '''
/// class docs
class MyClass<T> {
  // class comment
}

// Trailing comment
''';

    var expected = [
      Token('/// class docs', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('T', .typeParameter),
      Token('// class comment', .comment),
      Token('// Trailing comment', .comment),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_constructor_primary_declaration() async {
    var content = r'''
class A { const A(); }
mixin M {}

[!
class const B(final int y) {}
class C<T extends Object>.named(
  var int x, [
  final int y = 0,
]) extends A with M implements B {
  this {}
}
!]
''';

    var expected = [
      Token('class', .keyword),
      Token('const', .keyword),
      Token('B', .class_, [.declaration]),
      Token('final', .keyword),
      Token('int', .class_),
      Token('y', .parameter, [.declaration]),
      Token('class', .keyword),
      Token('C', .class_, [.declaration]),
      Token('T', .typeParameter),
      Token('extends', .keyword),
      Token('Object', .class_),
      Token('var', .keyword),
      Token('int', .class_),
      Token('x', .parameter, [.declaration]),
      Token('final', .keyword),
      Token('int', .class_),
      Token('y', .parameter, [.declaration]),
      Token('0', .number),
      Token('extends', .keyword),
      Token('A', .class_),
      Token('with', .keyword),
      Token('M', .class_),
      Token('implements', .keyword),
      Token('B', .class_),
      Token('this', .keyword),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_class_constructor_primary_invocation() async {
    var content = r'''
class A.named(int a, {int b = 0});

var a = [!A.named(1, b: 2);!]
''';

    var expected = [
      Token('A', .class_, [.constructor]),
      Token('named', .method, [.constructor]),
      Token('1', .number),
      Token('b', .parameter, [.label]),
      Token('2', .number),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_class_constructors() async {
    var content = '''
class MyClass {
  const MyClass();
  MyClass.named();
  factory MyClass.factory() => MyClass();
}

final a = MyClass();
final b = MyClass.named();
final c = MyClass.factory();
final d = MyClass.named;
const e = const MyClass();
''';

    var expected = [
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('const', .keyword),
      Token('MyClass', .class_, [.constructor, .declaration]),
      Token('MyClass', .class_, [.constructor, .declaration]),
      Token('named', .method, [.constructor, .declaration]),
      Token('factory', .keyword),
      Token('MyClass', .class_, [.constructor, .declaration]),
      Token('factory', .method, [.constructor, .declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('final', .keyword),
      Token('a', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('final', .keyword),
      Token('b', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('named', .method, [.constructor]),
      Token('final', .keyword),
      Token('c', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('factory', .method, [.constructor]),
      Token('final', .keyword),
      Token('d', .variable, [.declaration]),
      Token('MyClass', .class_),
      Token('named', .method, [.constructor]),
      Token('const', .keyword),
      Token('e', .variable, [.declaration]),
      Token('const', .keyword),
      Token('MyClass', .class_, [.constructor]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_constructors_factoryKeyword() async {
    var content = r'''
class A {
  A._();
[!
  factory() => A._();
  factory named() => A._();
!]
}
''';

    var expected = [
      Token('factory', .keyword, [.constructor, .declaration]),
      Token('A', .class_, [.constructor]),
      Token('_', .method, [.constructor]),
      Token('factory', .keyword, [.constructor, .declaration]),
      Token('named', .method, [.constructor, .declaration]),
      Token('A', .class_, [.constructor]),
      Token('_', .method, [.constructor]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_class_constructors_newKeyword() async {
    var content = r'''
class A {
  new();
  new named();
}
void f() {
  A.new();
  A.named();
  A.new;
  A.named;
}
''';

    var expected = [
      Token('class', .keyword),
      Token('A', .class_, [.declaration]),
      Token('new', .keyword, [.constructor, .declaration]),
      Token('new', .keyword, [.constructor, .declaration]),
      Token('named', .method, [.constructor, .declaration]),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('A', .class_, [.constructor]),
      Token('new', .method, [.constructor]),
      Token('A', .class_, [.constructor]),
      Token('named', .method, [.constructor]),
      Token('A', .class_),
      Token('new', .method, [.constructor]),
      Token('A', .class_),
      Token('named', .method, [.constructor]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_fields() async {
    var content = '''
class MyClass {
  /// field docs
  String myField = 'FieldVal';
  /// static field docs
  static String myStaticField = 'StaticFieldVal';
}

void f() {
  final a = MyClass();
  print(a.myField);
  MyClass.myStaticField = 'a';
}
''';

    var expected = [
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('/// field docs', .comment, [.documentation]),
      Token('String', .class_),
      Token('myField', .variable, [.declaration, .instance]),
      Token("'FieldVal'", .string),
      Token('/// static field docs', .comment, [.documentation]),
      Token('static', .keyword),
      Token('String', .class_),
      Token('myStaticField', .variable, [.declaration, .static]),
      Token("'StaticFieldVal'", .string),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('final', .keyword),
      Token('a', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('print', .function),
      Token('a', .variable),
      Token('myField', .property, [.instance]),
      Token('MyClass', .class_),
      Token('myStaticField', .property, [.static]),
      Token("'a'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_getterSetter() async {
    var content = '''
class MyClass {
  /// getter docs
  String get myGetter => 'GetterVal';
  /// setter docs
  set mySetter(String v) {}
  /// static getter docs
  static String get myStaticGetter => 'StaticGetterVal';
  /// static setter docs
  static set myStaticSetter(String staticV) {}
}

void f() {
  final a = MyClass();
  print(a.myGetter);
  a.mySetter = 'a';
}
''';

    var expected = [
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('/// getter docs', .comment, [.documentation]),
      Token('String', .class_),
      Token('get', .keyword),
      Token('myGetter', .property, [.declaration, .instance]),
      Token("'GetterVal'", .string),
      Token('/// setter docs', .comment, [.documentation]),
      Token('set', .keyword),
      Token('mySetter', .property, [.declaration, .instance]),
      Token('String', .class_),
      Token('v', .parameter, [.declaration]),
      Token('/// static getter docs', .comment, [.documentation]),
      Token('static', .keyword),
      Token('String', .class_),
      Token('get', .keyword),
      Token('myStaticGetter', .property, [.declaration, .static]),
      Token("'StaticGetterVal'", .string),
      Token('/// static setter docs', .comment, [.documentation]),
      Token('static', .keyword),
      Token('set', .keyword),
      Token('myStaticSetter', .property, [.declaration, .static]),
      Token('String', .class_),
      Token('staticV', .parameter, [.declaration]),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('final', .keyword),
      Token('a', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('print', .function),
      Token('a', .variable),
      Token('myGetter', .property, [.instance]),
      Token('a', .variable),
      Token('mySetter', .property, [.instance]),
      Token("'a'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_method() async {
    var content = '''
class MyClass {
  /// method docs
  @override
  void myMethod() {}
  /// static method docs
  static void myStaticMethod() {
    // static method comment
  }
}

void f() {
  final a = MyClass();
  a.myMethod();
  MyClass.myStaticMethod();
  final b = a.myMethod;
  final c = MyClass.myStaticMethod;
}
''';

    var expected = [
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('/// method docs', .comment, [.documentation]),
      Token('@', .annotation),
      Token('override', .property, [.annotation]),
      Token('void', .keyword, [.void_]),
      Token('myMethod', .method, [.declaration, .instance]),
      Token('/// static method docs', .comment, [.documentation]),
      Token('static', .keyword),
      Token('void', .keyword, [.void_]),
      Token('myStaticMethod', .method, [.declaration, .static]),
      Token('// static method comment', .comment),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('final', .keyword),
      Token('a', .variable, [.declaration]),
      Token('MyClass', .class_, [.constructor]),
      Token('a', .variable),
      Token('myMethod', .method, [.instance]),
      Token('MyClass', .class_),
      Token('myStaticMethod', .method, [.static]),
      Token('final', .keyword),
      Token('b', .variable, [.declaration]),
      Token('a', .variable),
      Token('myMethod', .method, [.instance]),
      Token('final', .keyword),
      Token('c', .variable, [.declaration]),
      Token('MyClass', .class_),
      Token('myStaticMethod', .method, [.static]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_class_super() async {
    var content = '''
class A {
  A(int i) {}
  void f() {}
}

class B extends A {
[!
  B.b() : super(1);
  B(super.i);
  void f() {
    super.f();
  }
!]
}
''';

    var expected = [
      Token('B', .class_, [.constructor, .declaration]),
      Token('b', .method, [.constructor, .declaration]),
      Token('super', .keyword),
      Token('1', .number),
      Token('B', .class_, [.constructor, .declaration]),
      Token('super', .keyword),
      Token('i', .parameter, [.declaration]),
      Token('void', .keyword, [.void_]),
      Token('f', .method, [.declaration, .instance]),
      Token('super', .keyword),
      Token('f', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_class_this() async {
    var content = '''
class A {
  int a;
  [!
  A(this.a);
  A.b() : this(1);
  void f() {
    this.f();
  }
  !]
}
''';

    var expected = [
      Token('A', .class_, [.constructor, .declaration]),
      Token('this', .keyword),
      Token('a', .variable, [.instance]),
      Token('A', .class_, [.constructor, .declaration]),
      Token('b', .method, [.constructor, .declaration]),
      Token('1', .number),
      Token('void', .keyword, [.void_]),
      Token('f', .method, [.declaration, .instance]),
      Token('this', .keyword),
      Token('f', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_dartdoc() async {
    var content = '''
/// before [aaa] after
class MyClass {
  String? aaa;
}

/// before [bbb] after
int double(int bbb) => bbb * 2;
''';

    var expected = [
      Token('/// before [', .comment, [.documentation]),
      Token('aaa', .property, [.instance]),
      Token('] after', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('String', .class_),
      Token('aaa', .variable, [.declaration, .instance]),
      Token('/// before [', .comment, [.documentation]),
      Token('bbb', .parameter),
      Token('] after', .comment, [.documentation]),
      Token('int', .class_),
      Token('double', .function, [.declaration, .static]),
      Token('int', .class_),
      Token('bbb', .parameter, [.declaration]),
      Token('bbb', .parameter),
      Token('2', .number),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_dartdoc_codeBlock_indented() async {
    var content = '''
/// MyClass.
///
///     CODE
class MyClass;
''';

    var expected = [
      Token('/// MyClass.', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token('     CODE', .comment, [.documentation, .source]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_dartdoc_codeBlock_tripleBackticks() async {
    var content = '''
/// MyClass.
///
/// ```
/// CODE
/// ```
class MyClass;
''';

    var expected = [
      Token('/// MyClass.', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token(' ```', .comment, [.documentation, .source]),
      Token('///', .comment, [.documentation]),
      Token(' CODE', .comment, [.documentation, .source]),
      Token('///', .comment, [.documentation]),
      Token(' ```', .comment, [.documentation, .source]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_dartdoc_codeBlock_tripleBackticks_namedLanguage() async {
    var content = '''
/// MyClass.
///
/// ```dart
/// CODE
/// ```
class MyClass;
''';

    var expected = [
      Token('/// MyClass.', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token('///', .comment, [.documentation]),
      Token(' ```dart', .comment, [.documentation, .source]),
      Token('///', .comment, [.documentation]),
      Token(' CODE', .comment, [.documentation, .source]),
      Token('///', .comment, [.documentation]),
      Token(' ```', .comment, [.documentation, .source]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_directives() async {
    failTestOnErrorDiagnostic = false; // Test has invalid imports.

    var content = '''
library foo;

import 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';
import '../file.dart'
  if (dart.library.io) 'file_io.dart'
  if (dart.library.html) 'file_html.dart';
''';

    var expected = [
      Token('library', .keyword),
      Token('foo', .namespace),
      Token('import', .keyword),
      Token("'package:flutter/material.dart'", .string),
      Token('export', .keyword),
      Token("'package:flutter/widgets.dart'", .string),
      Token('import', .keyword),
      Token("'../file.dart'", .string),
      Token('if', .keyword, [.control]),
      Token('dart', .source),
      Token('library', .source),
      Token('io', .source),
      Token("'file_io.dart'", .string),
      Token('if', .keyword, [.control]),
      Token('dart', .source),
      Token('library', .source),
      Token('html', .source),
      Token("'file_html.dart'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_dotShorthand_constructor() async {
    failTestOnErrorDiagnostic = false;

    var content = r'''
class A {
  A();
  A.named(int x);
}
void f() {
  [!
  A a = .new();
  A aa = .named(42);
  A aTearOff = .new;
  A aTearOff = .named;
  !]
}
''';

    var expected = [
      Token('A', .class_),
      Token('a', .variable, [.declaration]),
      Token('new', .method, [.constructor]),
      Token('A', .class_),
      Token('aa', .variable, [.declaration]),
      Token('named', .method, [.constructor]),
      Token('42', .number),
      Token('A', .class_),
      Token('aTearOff', .variable, [.declaration]),
      Token('new', .method, [.constructor]),
      Token('A', .class_),
      Token('aTearOff', .variable, [.declaration]),
      Token('named', .method, [.constructor]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_dotShorthand_getter() async {
    var content = r'''
enum E { a }
class A {
  static A get aGetter => A();
}
extension type B(int x) {
  static B get bGetter => B(1);
}
class C {}
class D extends C with Mixin {}
mixin Mixin on C {
  static Mixin get dGetter => D();
}
void f() {
  [!
  E e = .a;
  A a = .aGetter;
  B b = .bGetter;
  Mixin m = .dGetter;
  !]
}
''';

    var expected = [
      Token('E', .enum_),
      Token('e', .variable, [.declaration]),
      Token('a', .enumMember),
      Token('A', .class_),
      Token('a', .variable, [.declaration]),
      Token('aGetter', .property, [.static]),
      Token('B', .class_),
      Token('b', .variable, [.declaration]),
      Token('bGetter', .property, [.static]),
      Token('Mixin', .class_),
      Token('m', .variable, [.declaration]),
      Token('dGetter', .property, [.static]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_dotShorthand_method() async {
    failTestOnErrorDiagnostic = false;

    var content = r'''
class A {
  static A aMethod() => A();
}
extension type B(int x) {
  static B bMethod() => B(1);
}
class C {}
class D extends C with Mixin {}
mixin Mixin on C {
  static Mixin dMethod() => D();
}
void f() {
  [!
  A a = .aMethod();
  A aa = .aMethod;
  B b = .bMethod();
  B bb = .bMethod;
  Mixin m = .dMethod();
  Mixin mm = .dMethod;
  !]
}
''';

    var expected = [
      Token('A', .class_),
      Token('a', .variable, [.declaration]),
      Token('aMethod', .method, [.static]),
      Token('A', .class_),
      Token('aa', .variable, [.declaration]),
      Token('aMethod', .method, [.static]),
      Token('B', .class_),
      Token('b', .variable, [.declaration]),
      Token('bMethod', .method, [.static]),
      Token('B', .class_),
      Token('bb', .variable, [.declaration]),
      Token('bMethod', .method, [.static]),
      Token('Mixin', .class_),
      Token('m', .variable, [.declaration]),
      Token('dMethod', .method, [.static]),
      Token('Mixin', .class_),
      Token('mm', .variable, [.declaration]),
      Token('dMethod', .method, [.static]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_emptyAnalysisRoots_handlesFileRequestsImmediately() async {
    var content = '''
// test
''';

    var code = TestCode.parseNormalized(content);
    newFile(mainFilePath, code.code);
    await initialize(allowEmptyRootUri: true);

    unawaited(openFile(mainFileUri, code.code));
    var tokens = await getSemanticTokens(mainFileUri);
    expect(tokens.data, isNotEmpty);
  }

  Future<void> test_extension() async {
    var content = '''
extension A on String {}
''';

    var expected = [
      Token('extension', .keyword),
      Token('A', .class_),
      Token('on', .keyword),
      Token('String', .class_),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_extensionType() async {
    var content = '''
extension type E(int i) {}
''';

    var expected = [
      Token('extension', .keyword),
      Token('type', .keyword),
      Token('E', .class_, [.declaration]),
      Token('int', .class_),
      Token('i', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_fromPlugin() async {
    var pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    var pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    var content = 'CLASS STRING VARIABLE';
    var code = TestCode.parseNormalized(content);

    var expected = [
      Token('CLASS', .class_),
      Token('STRING', .string),
      Token('VARIABLE', .variable, [.declaration]),
    ];

    await initialize();
    await openFile(pluginAnalyzedFileUri, code.code);

    var pluginResult = plugin.AnalysisHighlightsParams(pluginAnalyzedFilePath, [
      plugin.HighlightRegion(plugin.HighlightRegionType.CLASS, 0, 5),
      plugin.HighlightRegion(plugin.HighlightRegionType.LITERAL_STRING, 6, 6),
      plugin.HighlightRegion(
        plugin.HighlightRegionType.LOCAL_VARIABLE_DECLARATION,
        13,
        8,
      ),
    ]);
    configureTestPlugin(notification: pluginResult.toNotification());

    var tokens = await getSemanticTokens(pluginAnalyzedFileUri);
    var decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_function_callMethod_invocation() async {
    var content = r'''
f(void Function(int)? x) {
  [!x?.call(2);!]
}
''';

    var expected = [
      Token('x', .parameter),
      Token('call', .method, [.instance]),
      Token('2', .number),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_invocation_extension() async {
    var content = r'''
extension on void Function() {
  m() => [!call()!];
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_propertyAccess() async {
    var content = r'''
extension on void Function()? {
  m() => [!this?.call!];
}
''';

    var expected = <Token>[
      Token('this', .keyword),
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_simpleIdentifier() async {
    var content = r'''
extension on void Function() {
  m() {
    [!call!];
  }
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_simpleIdentifier_argument() async {
    var content = r'''
extension on void Function() {
  m(void Function() f) {
    m([!call!]);
  }
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_simpleIdentifier_assignment() async {
    var content = r'''
extension on void Function() {
  m() {
    var a;
    a = [!call!];
  }
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void>
  test_function_callMethod_simpleIdentifier_expressionFunctionBody() async {
    var content = r'''
extension on void Function() {
  m() => [!call!];
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_simpleIdentifier_return() async {
    var content = r'''
extension on void Function() {
  m() {
    return [!call!];
  }
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void>
  test_function_callMethod_simpleIdentifier_variableDeclaration() async {
    var content = r'''
extension on void Function() {
  m() {
    var _ = [!call!];
  }
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_tearOff() async {
    var content = r'''
f(void Function(int) x) {
  [!x.call!];
}
''';

    var expected = [
      Token('x', .parameter),
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_functionType_callMethod_invocation_extension() async {
    var content = r'''
extension on Function {
  m() => [!call()!];
}
''';

    var expected = <Token>[
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_functionType_callMethod_tearOff() async {
    var content = r'''
f(Function x) {
  [!x.call!];
}
''';

    var expected = [
      Token('x', .parameter),
      Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  /// Verify that sending a semantic token request immediately after an overlay
  /// update (with no delay) does not result in corrupt semantic tokens because
  /// the previous file content was used.
  ///
  /// https://github.com/dart-lang/sdk/issues/55084
  Future<void> test_immediatelyAfterUpdate() async {
    var initialContent = normalizeNewlinesForPlatform('''class A {}
class B {}''');
    var updatedContent = normalizeNewlinesForPlatform('''class Aaaaa {}
class Bbbbb {}''');

    newFile(mainFilePath, initialContent);
    await initialize();

    await openFile(mainFileUri, initialContent);

    // Send an edit (don't await), then fetch the tokens and verify the results
    // were correct for the final content. If the bug occurs, the strings won't
    // match up because the offsets will have been mapped incorrectly.
    unawaited(replaceFile(2, mainFileUri, updatedContent));
    var tokens = await getSemanticTokens(mainFileUri);
    var decoded = decodeSemanticTokens(updatedContent, tokens);
    expect(decoded, [
      Token('class', .keyword),
      Token('Aaaaa', .class_, [.declaration]),
      Token('class', .keyword),
      Token('Bbbbb', .class_, [.declaration]),
    ]);
  }

  Future<void> test_initializer() async {
    var content = '''
class A {
  final String a;
  [!A(String a) : a = a!];
}
''';

    var expected = [
      Token('A', .class_, [.constructor, .declaration]),
      Token('String', .class_),
      Token('a', .parameter, [.declaration]),
      Token('a', .variable, [.instance]),
      Token('a', .parameter),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_invalidSyntax() async {
    failTestOnErrorDiagnostic = false;

    var content = '''
/// class docs
class MyClass {
  // class comment
}

this is not valid code.

/// class docs 2
class MyClass2 {
  // class comment 2
}
''';
    var code = TestCode.parseNormalized(content);

    // Expect the correct tokens for the valid code before/after but don't
    // check the tokens for the invalid code as there are no concrete
    // expectations for them.
    var expected1 = [
      Token('/// class docs', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('// class comment', .comment),
    ];
    var expected2 = [
      Token('/// class docs 2', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass2', .class_, [.declaration]),
      Token('// class comment 2', .comment),
    ];

    await initialize();
    await openFile(mainFileUri, code.code);

    var tokens = await getSemanticTokens(mainFileUri);
    var decoded = decodeSemanticTokens(code.code, tokens);

    // Remove the tokens between the two expected sets.
    decoded.removeRange(expected1.length, decoded.length - expected2.length);

    expect(decoded, equals([...expected1, ...expected2]));
  }

  Future<void> test_keywords() async {
    // "control" keywords should be tagged with a modifier so the client
    // can color them differently to other keywords.
    var content = r'''
void f() async {
  var a = new Object();
  await null;
  if (false) {
    print('test');
  }
  for (var item in []);
  switch (1) {
    case int(:var isEven) when isEven:
  }
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('async', .keyword, [.control]),
      Token('var', .keyword),
      Token('a', .variable, [.declaration]),
      Token('new', .keyword),
      Token('Object', .class_, [.constructor]),
      Token('await', .keyword, [.control]),
      Token('null', .keyword),
      Token('if', .keyword, [.control]),
      Token('false', .boolean),
      Token('print', .function),
      Token("'test'", .string),
      Token('for', .keyword, [.control]),
      Token('var', .keyword),
      Token('item', .variable, [.declaration]),
      Token('in', .keyword, [.control]),
      Token('switch', .keyword, [.control]),
      Token('1', .number),
      Token('case', .keyword, [.control]),
      Token('int', .class_),
      Token('var', .keyword),
      Token('isEven', .variable, [.declaration]),
      Token('when', .keyword, [.control]),
      Token('isEven', .variable),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_label() async {
    var content = '''
void f() {
myLabel:
  while (true) {
    break myLabel;
  }
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('myLabel', .label, [.declaration]),
      Token('while', .keyword, [.control]),
      Token('true', .boolean),
      Token('break', .keyword, [.control]),
      Token('myLabel', .label),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_code() async {
    var content = 'String? bar;';

    var expected = [
      Token('String', .class_),
      Token('bar', .variable, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_comment() async {
    var content = '// Trailing comment';

    var expected = [Token('// Trailing comment', .comment)];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_multilineComment() async {
    var content = '''
/**
 * Trailing comment
 */''';

    var expected = [
      Token('/**$eol', .comment, [.documentation]),
      Token(' * Trailing comment$eol', .comment, [.documentation]),
      Token(' */', .comment, [.documentation]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_local() async {
    var content = '''
void f() {
  func(String a) => print(a);
  final funcTearOff = func;
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('func', .function, [.declaration]),
      Token('String', .class_),
      Token('a', .parameter, [.declaration]),
      Token('print', .function),
      Token('a', .parameter),
      Token('final', .keyword),
      Token('funcTearOff', .variable, [.declaration]),
      Token('func', .function),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_manyBools_bug() async {
    // Similar to test_manyImports_sortBug, this code triggered inconsistent tokens
    // for "false" because tokens were sorted incorrectly (because both boolean and
    // keyword had the same offset and length, which is all that were sorted by).
    var content = '''
class MyTestClass {
/// test
/// test
bool test1 = false;

/// test
/// test
bool test2 = false;

/// test
/// test
bool test3 = false;

/// test
/// test
bool test4 = false;

/// test
/// test
bool test5 = false;

/// test
/// test
bool test6 = false;
}
''';

    var expected = [
      Token('class', .keyword),
      Token('MyTestClass', .class_, [.declaration]),
      for (var i = 1; i <= 6; i++) ...[
        Token('/// test', .comment, [.documentation]),
        Token('/// test', .comment, [.documentation]),
        Token('bool', .class_),
        Token('test$i', .variable, [.declaration, .instance]),
        Token('false', .boolean),
      ],
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_manyImports_sortBug() async {
    // This test is for a bug where some "import" tokens would not be
    // highlighted correctly. Imports are made up of a DIRECTIVE token that
    // spans a KEYWORD ("import") and LITERAL_STRING. The original code sorted
    // by only offset when handling overlapping tokens, which for certain lists
    // (such as the one created for the code below) would result in the KEYWORD
    // coming before the DIRECTIVE, which resulted in the DIRECTIVE overwriting
    // it.
    var content = '''
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
import 'dart:async';
''';

    var expected = [
      for (var i = 0; i < 13; i++) ...[
        Token('import', .keyword),
        Token("'dart:async'", .string),
      ],
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_mixin() async {
    var content = '''
mixin M on C {}
class C {}
''';

    var expected = [
      Token('mixin', .keyword),
      Token('M', .class_),
      Token('on', .keyword),
      Token('C', .class_),
      Token('class', .keyword),
      Token('C', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_multilineRegions() async {
    var content = '''
/**
 * This is my class comment
 *
 * There are
 * multiple lines
 */
class MyClass {}
''';

    var expected = [
      Token('/**$eol', .comment, [.documentation]),
      Token(' * This is my class comment$eol', .comment, [.documentation]),
      Token(' *$eol', .comment, [.documentation]),
      Token(' * There are$eol', .comment, [.documentation]),
      Token(' * multiple lines$eol', .comment, [.documentation]),
      Token(' */', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_namedArguments() async {
    var content = '''
f({String? a, dynamic b}) {
  f(a: a, b: b);
}
''';

    var expected = [
      Token('f', .function, [.declaration, .static]),
      Token('String', .class_),
      Token('a', .parameter, [.declaration]),
      Token('dynamic', .type),
      Token('b', .parameter, [.declaration]),
      Token('f', .function),
      Token('a', .parameter, [.label]),
      Token('a', .parameter),
      Token('b', .parameter, [.label]),
      Token('b', .parameter),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_namedRecordFields_extension() async {
    var content = '''
extension on ({int field,}) {
  get other => field + this.field;
}
''';

    var expected = [
      Token('extension', .keyword),
      Token('on', .keyword),
      Token('int', .class_),
      Token('get', .keyword),
      Token('other', .property, [.declaration, .instance]),
      Token('field', .property, [.instance]),
      Token('this', .keyword),
      Token('field', .property, [.instance]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_never() async {
    var content = '''
Never f() => throw '';
Never? g() => throw '';
''';

    var expected = [
      Token('Never', .type),
      Token('f', .function, [.declaration, .static]),
      Token('throw', .keyword, [.control]),
      Token("''", .string),
      Token('Never', .type),
      Token('g', .function, [.declaration, .static]),
      Token('throw', .keyword, [.control]),
      Token("''", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_parameter_fieldFormal() async {
    var content = '''
class A {
  final String a;
  A([!this.a!]);
}
''';

    var expected = [
      Token('this', .keyword),
      Token('a', .variable, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_super() async {
    var content = '''
class A {
  A({String? a, String? b});
}

class B extends A {
  [!B({super.a}) : super(b: a)!];
}
''';

    var expected = [
      Token('B', .class_, [.constructor, .declaration]),
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
      Token('super', .keyword),
      Token('b', .parameter, [.label]),
      Token('a', .parameter),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_super_fieldFormal() async {
    var content = '''
class A {
  String a;
  A(this.a);
}

class B extends A {
  B([!super.a!]);
}
''';

    var expected = [
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_super_fieldFormal_unresolved() async {
    failTestOnErrorDiagnostic = false;

    var content = '''
class A {
  A(this.a);
}

class B extends A {
  B([!super.a!]);
}
''';

    var expected = [
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_super_unresolved() async {
    failTestOnErrorDiagnostic = false;

    var content = '''
class A {
  A();
}

class B extends A {
  B([!super.a!]);
}
''';

    var expected = [
      Token('super', .keyword),
      Token('a', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_this() async {
    var content = '''
class A {
  String a;
  A([!this.a!]);
}
''';

    var expected = [
      Token('this', .keyword),
      Token('a', .variable, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_parameter_this_unresolved() async {
    failTestOnErrorDiagnostic = false;

    var content = '''
class A {
  A([!this.a!]);
}
''';

    var expected = [
      Token('this', .keyword),
      Token('a', .variable, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_patterns_assignment() async {
    var content = r'''
void f() {
  int a, b;
  <int>[a, b] = [1, 2];
  var [c, d] = [1, 2];
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('int', .class_),
      Token('a', .variable, [.declaration]),
      Token('b', .variable, [.declaration]),
      Token('int', .class_),
      Token('a', .variable),
      Token('b', .variable),
      Token('1', .number),
      Token('2', .number),
      Token('var', .keyword),
      Token('c', .variable, [.declaration]),
      Token('d', .variable, [.declaration]),
      Token('1', .number),
      Token('2', .number),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_list() async {
    var content = r'''
void f() {
  switch (1) {
    case [var c, == 'a'] when c != null:
  }
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('switch', .keyword, [.control]),
      Token('1', .number),
      Token('case', .keyword, [.control]),
      Token('var', .keyword),
      Token('c', .variable, [.declaration]),
      Token("'a'", .string),
      Token('when', .keyword, [.control]),
      Token('c', .variable),
      Token('null', .keyword),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_object() async {
    var content = r'''
void f() {
  switch (1) {
    case int(isEven: var isEven, toString: var toString) when isEven:
      isEven;
      toString;
  }
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('switch', .keyword, [.control]),
      Token('1', .number),
      Token('case', .keyword, [.control]),
      Token('int', .class_),
      Token('isEven', .property, [.instance]),
      Token('var', .keyword),
      Token('isEven', .variable, [.declaration]),
      Token('toString', .method, [.instance]),
      Token('var', .keyword),
      Token('toString', .variable, [.declaration]),
      Token('when', .keyword, [.control]),
      Token('isEven', .variable),
      Token('isEven', .variable),
      Token('toString', .variable),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_object_inferredName() async {
    var content = r'''
void f() {
  switch (1) {
    case int(:var isEven) when isEven:
  }
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('switch', .keyword, [.control]),
      Token('1', .number),
      Token('case', .keyword, [.control]),
      Token('int', .class_),
      Token('var', .keyword),
      Token('isEven', .variable, [.declaration]),
      Token('when', .keyword, [.control]),
      Token('isEven', .variable),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_positionalRecordFields_extension() async {
    var content = r'''
extension on (int field, double,) {
  get other => $1 + $2;
}
''';

    var expected = [
      Token('extension', .keyword),
      Token('on', .keyword),
      Token('int', .class_),
      Token('double', .class_),
      Token('get', .keyword),
      Token('other', .property, [.declaration, .instance]),
      Token(r'$1', .property, [.instance]),
      Token(r'$2', .property, [.instance]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_range() async {
    var content = '''
/// class docs
class [!MyClass<T> {
  // class comment
}!]

// Trailing comment
''';

    var expected = [
      Token('MyClass', .class_, [.declaration]),
      Token('T', .typeParameter),
      Token('// class comment', .comment),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_range_entireFile() async {
    var content = '''[!
/// class docs
class MyClass<T> {
  // class comment
}

// Trailing comment
!]''';

    var expected = [
      Token('/// class docs', .comment, [.documentation]),
      Token('class', .keyword),
      Token('MyClass', .class_, [.declaration]),
      Token('T', .typeParameter),
      Token('// class comment', .comment),
      Token('// Trailing comment', .comment),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_range_multilineRegions() async {
    var content = '''
/**
 * This is my class comment
 *
 * [!There are
 * multiple lines
 */
class!] MyClass {}
''';

    var expected = [
      Token(' * There are$eol', .comment, [.documentation]),
      Token(' * multiple lines$eol', .comment, [.documentation]),
      Token(' */', .comment, [.documentation]),
      Token('class', .keyword),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_record_fields() async {
    failTestOnErrorDiagnostic = false; // Unresolved symbols.

    var content = r'''
void f((int, {int field1}) record) {
  [!
  record.$1;
  record.field1;
  (1,).$1;
  (field1: 1).field1;
  (1,).unresolved;
  !]
}
''';

    var expected = [
      Token('record', .parameter),
      Token(r'$1', .property, [.instance]),
      Token('record', .parameter),
      Token('field1', .property, [.instance]),
      Token('1', .number),
      Token(r'$1', .property, [.instance]),
      Token('field1', .parameter),
      Token('1', .number),
      Token('field1', .property, [.instance]),
      Token('1', .number),
      Token('unresolved', .source),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_sort_sameOffsets() async {
    // This code initially (before merging) produces a String token starting at
    // offset 11 (as it drops out of one interpolated variable) and then a new
    // Interpolatation token.
    // This test is to ensure the assertion in `offsetLengthPrioritySort` does
    // not trigger (as it does if length is ignored, which was a bug).
    var content = r'''
var s = '';
var a = [!'$s$s'!];
''';

    var expected = [
      Token("'", .string),
      Token(r'$', .source, [.interpolation]),
      Token('s', .property),
      Token(r'$', .source, [.interpolation]),
      Token('s', .property),
      Token("'", .string),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_strings() async {
    var content = '''
String foo(String c) => c;
const string1 = 'test';
var string2 = 'test1 \$string1 test2 \${foo('a' + 'b')}';
const string3 = r'\$string1 \${string1.length}';
const string4 = \'\'\'
multi
  line
    string
\'\'\';
''';

    var expected = [
      Token('String', .class_),
      Token('foo', .function, [.declaration, .static]),
      Token('String', .class_),
      Token('c', .parameter, [.declaration]),
      Token('c', .parameter),

      Token('const', .keyword),
      Token('string1', .variable, [.declaration]),
      Token("'test'", .string),

      Token('var', .keyword),
      Token('string2', .variable, [.declaration]),
      Token(r"'test1 ", .string),
      Token(r'$', .source, [.interpolation]),
      Token('string1', .property),
      Token(' test2 ', .string),
      Token(r'${', .source, [.interpolation]),
      Token('foo', .function),
      Token('(', .source, [.interpolation]),
      Token("'a'", .string),
      Token(' + ', .source, [.interpolation]),
      Token("'b'", .string),
      Token(')}', .source, [.interpolation]),
      Token("'", .string),

      // string3 is raw and should be treated as a single string.
      Token('const', .keyword),
      Token('string3', .variable, [.declaration]),
      Token(r"r'$string1 ${string1.length}'", .string),
      Token('const', .keyword),

      Token('string4', .variable, [.declaration]),
      Token("'''$eol", .string),
      Token('multi$eol', .string),
      Token('  line$eol', .string),
      Token('    string$eol', .string),
      Token("'''", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_strings_escape() async {
    failTestOnErrorDiagnostic = false; // Last unicode escape is invalid.

    // The 9's in these strings are not part of the escapes (they make the
    // strings too long).
    var content = r'''
const string1 = 'it\'s escaped\\\n\$';
const string2 = 'hex \x12\x1299';
const string3 = 'unicode \u1234\u123499\u{123456}\u{12345699}';
const string4 = "\"";
''';

    var expected = [
      Token('const', .keyword),
      Token('string1', .variable, [.declaration]),
      Token("'it", .string),
      Token(r"\'", .string, [.escape]),
      Token('s escaped', .string),
      Token(r'\\', .string, [.escape]),
      Token(r'\n', .string, [.escape]),
      Token(r'\$', .string, [.escape]),
      Token(r"'", .string),
      Token('const', .keyword),
      Token('string2', .variable, [.declaration]),
      Token("'hex ", .string),
      Token(r'\x12', .string, [.escape]),
      Token(r'\x12', .string, [.escape]),
      // The 99 is not part of the escape
      Token("99'", .string),
      Token('const', .keyword),
      Token('string3', .variable, [.declaration]),
      Token("'unicode ", .string),
      Token(r'\u1234', .string, [.escape]),
      Token(r'\u1234', .string, [.escape]),
      // The 99 is not part of the escape
      Token('99', .string),
      Token(r'\u{123456}', .string, [.escape]),
      // The 99 makes this invalid so i's not an escape
      Token(r"\u{12345699}'", .string),
      Token('const', .keyword),
      Token('string4', .variable, [.declaration]),
      Token('"', .string),
      Token(r'\"', .string, [.escape]),
      Token('"', .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_strings_escape_interpolation1() async {
    var content = r'''
const value = 1;
const string1 = 'it\'s $value escaped\\\n';
''';

    var expected = [
      Token('const', .keyword),
      Token('value', .variable, [.declaration]),
      Token('1', .number),
      Token('const', .keyword),
      Token('string1', .variable, [.declaration]),
      Token("'it", .string),
      Token(r"\'", .string, [.escape]),
      Token('s ', .string),
      Token(r'$', .source, [.interpolation]),
      Token('value', .property),
      Token(' escaped', .string),
      Token(r'\\', .string, [.escape]),
      Token(r'\n', .string, [.escape]),
      Token(r"'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_strings_escape_interpolation2() async {
    var content = r'''
const value = 1;
const string1 = 'it\'s ${value} escaped\\\n';
''';

    var expected = [
      Token('const', .keyword),
      Token('value', .variable, [.declaration]),
      Token('1', .number),
      Token('const', .keyword),
      Token('string1', .variable, [.declaration]),
      Token("'it", .string),
      Token(r"\'", .string, [.escape]),
      Token('s ', .string),
      Token(r'${', .source, [.interpolation]),
      Token('value', .property),
      Token('}', .source, [.interpolation]),
      Token(' escaped', .string),
      Token(r'\\', .string, [.escape]),
      Token(r'\n', .string, [.escape]),
      Token(r"'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_topLevel() async {
    var content = '''
/// strings docs
const strings = <String>["test", 'test', r'test', \'''test\'''];

/// func docs
func(String a) => print(a);

/// abc docs
bool get abc => true;

final funcTearOff = func;

void f() {
  strings;
  func;
  abc;
  funcTearOff;
}
''';

    var expected = [
      Token('/// strings docs', .comment, [.documentation]),
      Token('const', .keyword),
      Token('strings', .variable, [.declaration]),
      Token('String', .class_),
      Token('"test"', .string),
      Token("'test'", .string),
      Token("r'test'", .string),
      Token("'''test'''", .string),
      Token('/// func docs', .comment, [.documentation]),
      Token('func', .function, [.declaration, .static]),
      Token('String', .class_),
      Token('a', .parameter, [.declaration]),
      Token('print', .function),
      Token('a', .parameter),
      Token('/// abc docs', .comment, [.documentation]),
      Token('bool', .class_),
      Token('get', .keyword),
      Token('abc', .property, [.declaration]),
      Token('true', .boolean),
      Token('final', .keyword),
      Token('funcTearOff', .variable, [.declaration]),
      Token('func', .function),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('strings', .property),
      Token('func', .function),
      Token('abc', .property),
      Token('funcTearOff', .property),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_unresolvedOrInvalid() async {
    failTestOnErrorDiagnostic = false;

    // Unresolved/invalid names should be marked as "source", which is used to
    // mark up code the server thinks should be uncolored (without this, a
    // clients other grammars would show through, losing the benefit from having
    // resolved the code).
    var content = '''
void f() {
  int a;
  a.foo().bar.baz();

  dynamic b;
  b.foo().bar.baz();
}
''';

    var expected = [
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('int', .class_),
      Token('a', .variable, [.declaration]),
      Token('a', .variable),
      Token('foo', .source),
      Token('bar', .source),
      Token('baz', .source),
      Token('dynamic', .type),
      Token('b', .variable, [.declaration]),
      Token('b', .variable),
      Token('foo', .source),
      Token('bar', .source),
      Token('baz', .source),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_wildcard_forInVariable() async {
    var content = r'''
f() {
  for (var [!_!] in []) {}
}
''';

    var expected = [
      Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_forLoopVariable() async {
    var content = r'''
f() {
  for (int [!_!] = 0;;) {}
}
''';

    var expected = [
      Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_localVariable() async {
    var content = r'''
f() {
  var [!_!] = 1;
}
''';

    var expected = [
      Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_memberName() async {
    var content = r'''
class A {
  void [!_!]() {}
}
''';

    var expected = [
      Token('_', .method, [.declaration, .instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_parameter_constructor() async {
    var content = r'''
class A {
  A(String a);
}

class B extends A {
  String _;
  B([!this._, super._!]);
}
''';

    var expected = [
      Token('this', .keyword),
      Token('_', .variable, [.instance]),
      Token('super', .keyword),
      Token('_', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_topLevelFunction() async {
    var content = r'''
void [!_!]() {}
''';

    var expected = [
      Token('_', .function, [.declaration, .static]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_topLevelVariable() async {
    var content = r'''
var [!_!] = 1;
''';

    var expected = [
      Token('_', .variable, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_typeName() async {
    var content = r'''
class [!_!] {}
''';

    var expected = [
      Token('_', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_catchClause() async {
    var content = r'''
f() {
  try {
    throw '!';
  } catch ([!_, _!]) {
    print('oops');
  }
}
''';

    var expected = [
      Token('_', .variable, [.declaration, .wildcard]),
      Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_functionExpression() async {
    var content = r'''
var a = [].where(([!_!]) => true);
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_functionType() async {
    var content = r'''
typedef T = void Function(String [!_!]);
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_instanceMethod() async {
    var content = r'''
class A {
  void f([!_!]) {}
}
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_localFunction() async {
    var content = r'''
void f() {
  void f2([!_!]) {}
}
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_staticMethod() async {
    var content = r'''
class A {
  static void f([!_!]) {}
}
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_topLevelFunction() async {
    var content = r'''
void f([!_!]) {}
''';

    var expected = [
      Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_pattern_assignment() async {
    var content = r'''
f() {
  int a;
([!_!], a) = (1, 2);
}
''';

    var expected = [
      Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_typeParameter() async {
    var content = r'''
class T<_> {}
void genericFunction<_>(Object? _) {}
void f() {
  genericFunction(<_>() => true);
}
''';

    var expected = [
      Token('class', .keyword),
      Token('T', .class_, [.declaration]),
      Token('_', .typeParameter, [.wildcard]),
      Token('void', .keyword, [.void_]),
      Token('genericFunction', .function, [.declaration, .static]),
      Token('_', .typeParameter, [.wildcard]),
      Token('Object', .class_),
      Token('_', .parameter, [.declaration, .wildcard]),
      Token('void', .keyword, [.void_]),
      Token('f', .function, [.declaration, .static]),
      Token('genericFunction', .function),
      Token('_', .typeParameter, [.wildcard]),
      Token('true', .boolean),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  /// Initializes the server with [content] in [uri] and then calls
  /// [_verifyTokens] to check the semantic tokens match [expected].
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _initializeAndVerifyTokens(
    String content,
    List<Token> expected, {
    Uri? uri,
  }) async {
    uri ??= mainFileUri;
    content = normalizeNewlinesForPlatform(content);
    newFile(fromUri(uri), content);
    await initialize();

    await _verifyTokens(uri, content, expected);
  }

  /// Initializes the server with [content] in [uri] and then checks the
  /// semantic tokens for the marked range match [expected].
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _initializeAndVerifyTokensInRange(
    String content,
    List<Token> expected, {
    Uri? uri,
  }) async {
    uri ??= mainFileUri;
    var code = TestCode.parseNormalized(content);
    newFile(fromUri(uri), code.code);
    await initialize();

    var tokens = await getSemanticTokensRange(mainFileUri, code.range.range);
    var decoded = decodeSemanticTokens(code.code, tokens);
    expect(decoded, equals(expected));
  }

  /// Check the semantic tokens for [content] in [uri] match [expected].
  ///
  /// [content] is used to map the offsets in the response to the tokens and
  /// is not sent to the server, so it must already match what the server
  /// believes [uri] to contain.
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _verifyTokens(
    Uri uri,
    String content,
    List<Token> expected,
  ) async {
    content = normalizeNewlinesForPlatform(content);

    var tokens = await getSemanticTokens(uri);
    var decoded = decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }
}
