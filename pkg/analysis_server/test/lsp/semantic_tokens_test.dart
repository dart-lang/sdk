// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SemanticTokensTest);
  });
}

@reflectiveTest
class SemanticTokensTest extends AbstractLspAnalysisServerTest {
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
      _Token('import', .keyword),
      _Token("'other_file.dart'", .string),
      _Token('as', .keyword),
      _Token('other', .variable, [.importPrefix]),
      _Token('@', .annotation),
      _Token('a', .property, [.annotation]),
      _Token('@', .annotation),
      _Token('A', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('@', .annotation),
      _Token('A', .class_, [.annotation]),
      _Token('.', .annotation),
      _Token('n', .method, [.constructor, .annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('@', .annotation),
      _Token('B', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token('A', .class_, [.constructor]),
      _Token(')', .annotation),
      _Token('@', .annotation),
      _Token('other', .variable, [.importPrefix]),
      _Token('.', .annotation),
      _Token('C', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('@', .annotation),
      _Token('other', .variable, [.importPrefix]),
      _Token('.', .annotation),
      _Token('C', .class_, [.annotation]),
      _Token('.', .annotation),
      _Token('n', .method, [.constructor, .annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('void', .keyword, [.void_]),
      _Token('foo', .function, [.declaration, .static]),
    ];

    var otherFilePath = join(projectFolderPath, 'lib', 'other_file.dart');

    newFile(mainFilePath, code.code);
    newFile(otherFilePath, otherCode.code);
    await initialize();

    var tokens = await getSemanticTokens(mainFileUri);
    var decoded = _decodeSemanticTokens(code.code, tokens);
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
      _Token('@', .annotation),
      _Token('MyAnnotation', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('String', .class_),
      _Token('a', .parameter, [.declaration]),
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
      _Token('@', .annotation),
      _Token('MyAnnotation', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
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
      _Token('@', .annotation),
      _Token('MyAnnotation', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
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
      _Token('@', .annotation),
      _Token('MyAnnotation', .class_, [.annotation]),
      _Token('(', .annotation),
      _Token(')', .annotation),
      _Token('this', .keyword),
      _Token('a', .variable, [.instance]),
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
      _Token('part', .keyword),
      _Token("'main_augmentation.dart'", .string),
      _Token('class', .keyword),
      _Token('A', .class_, [.declaration]),
      _Token('void', .keyword, [.void_]),
      _Token('f', .method, [.declaration, .instance]),
      _Token('String', .class_),
      _Token('get', .keyword),
      _Token('g', .property, [.declaration, .instance]),
    ]);

    // Augmentation.
    await _verifyTokens(mainFileAugmentationUri, augmentationContent, [
      _Token('part of', .keyword),
      _Token("'main.dart'", .string),
      _Token('augment', .keyword),
      _Token('class', .keyword),
      _Token('A', .class_, [.declaration]),
      _Token('augment', .keyword),
      _Token('void', .keyword, [.void_]),
      _Token('f', .method, [.declaration, .instance]),
      _Token('augment', .keyword),
      _Token('get', .keyword),
      _Token('g', .property, [.declaration, .instance]),
      _Token("'augmented'", .string),
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
      _Token('/// class docs', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('T', .typeParameter),
      _Token('// class comment', .comment),
      _Token('// Trailing comment', .comment),
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
      _Token('class', .keyword),
      _Token('const', .keyword),
      _Token('B', .class_, [.declaration]),
      _Token('final', .keyword),
      _Token('int', .class_),
      _Token('y', .parameter, [.declaration]),
      _Token('class', .keyword),
      _Token('C', .class_, [.declaration]),
      _Token('T', .typeParameter),
      _Token('extends', .keyword),
      _Token('Object', .class_),
      _Token('var', .keyword),
      _Token('int', .class_),
      _Token('x', .parameter, [.declaration]),
      _Token('final', .keyword),
      _Token('int', .class_),
      _Token('y', .parameter, [.declaration]),
      _Token('0', .number),
      _Token('extends', .keyword),
      _Token('A', .class_),
      _Token('with', .keyword),
      _Token('M', .class_),
      _Token('implements', .keyword),
      _Token('B', .class_),
      _Token('this', .keyword),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_class_constructor_primary_invocation() async {
    var content = r'''
class A.named(int a, {int b = 0});

var a = [!A.named(1, b: 2);!]
''';

    var expected = [
      _Token('A', .class_, [.constructor]),
      _Token('named', .method, [.constructor]),
      _Token('1', .number),
      _Token('b', .parameter, [.label]),
      _Token('2', .number),
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
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('const', .keyword),
      _Token('MyClass', .class_, [.constructor, .declaration]),
      _Token('MyClass', .class_, [.constructor, .declaration]),
      _Token('named', .method, [.constructor, .declaration]),
      _Token('factory', .keyword),
      _Token('MyClass', .class_, [.constructor, .declaration]),
      _Token('factory', .method, [.constructor, .declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('final', .keyword),
      _Token('a', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('final', .keyword),
      _Token('b', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('named', .method, [.constructor]),
      _Token('final', .keyword),
      _Token('c', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('factory', .method, [.constructor]),
      _Token('final', .keyword),
      _Token('d', .variable, [.declaration]),
      _Token('MyClass', .class_),
      _Token('named', .method, [.constructor]),
      _Token('const', .keyword),
      _Token('e', .variable, [.declaration]),
      _Token('const', .keyword),
      _Token('MyClass', .class_, [.constructor]),
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
      _Token('factory', .keyword, [.constructor, .declaration]),
      _Token('A', .class_, [.constructor]),
      _Token('_', .method, [.constructor]),
      _Token('factory', .keyword, [.constructor, .declaration]),
      _Token('named', .method, [.constructor, .declaration]),
      _Token('A', .class_, [.constructor]),
      _Token('_', .method, [.constructor]),
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
      _Token('class', .keyword),
      _Token('A', .class_, [.declaration]),
      _Token('new', .keyword, [.constructor, .declaration]),
      _Token('new', .keyword, [.constructor, .declaration]),
      _Token('named', .method, [.constructor, .declaration]),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('A', .class_, [.constructor]),
      _Token('new', .method, [.constructor]),
      _Token('A', .class_, [.constructor]),
      _Token('named', .method, [.constructor]),
      _Token('A', .class_),
      _Token('new', .method, [.constructor]),
      _Token('A', .class_),
      _Token('named', .method, [.constructor]),
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
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('/// field docs', .comment, [.documentation]),
      _Token('String', .class_),
      _Token('myField', .variable, [.declaration, .instance]),
      _Token("'FieldVal'", .string),
      _Token('/// static field docs', .comment, [.documentation]),
      _Token('static', .keyword),
      _Token('String', .class_),
      _Token('myStaticField', .variable, [.declaration, .static]),
      _Token("'StaticFieldVal'", .string),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('final', .keyword),
      _Token('a', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('print', .function),
      _Token('a', .variable),
      _Token('myField', .property, [.instance]),
      _Token('MyClass', .class_),
      _Token('myStaticField', .property, [.static]),
      _Token("'a'", .string),
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
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('/// getter docs', .comment, [.documentation]),
      _Token('String', .class_),
      _Token('get', .keyword),
      _Token('myGetter', .property, [.declaration, .instance]),
      _Token("'GetterVal'", .string),
      _Token('/// setter docs', .comment, [.documentation]),
      _Token('set', .keyword),
      _Token('mySetter', .property, [.declaration, .instance]),
      _Token('String', .class_),
      _Token('v', .parameter, [.declaration]),
      _Token('/// static getter docs', .comment, [.documentation]),
      _Token('static', .keyword),
      _Token('String', .class_),
      _Token('get', .keyword),
      _Token('myStaticGetter', .property, [.declaration, .static]),
      _Token("'StaticGetterVal'", .string),
      _Token('/// static setter docs', .comment, [.documentation]),
      _Token('static', .keyword),
      _Token('set', .keyword),
      _Token('myStaticSetter', .property, [.declaration, .static]),
      _Token('String', .class_),
      _Token('staticV', .parameter, [.declaration]),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('final', .keyword),
      _Token('a', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('print', .function),
      _Token('a', .variable),
      _Token('myGetter', .property, [.instance]),
      _Token('a', .variable),
      _Token('mySetter', .property, [.instance]),
      _Token("'a'", .string),
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
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('/// method docs', .comment, [.documentation]),
      _Token('@', .annotation),
      _Token('override', .property, [.annotation]),
      _Token('void', .keyword, [.void_]),
      _Token('myMethod', .method, [.declaration, .instance]),
      _Token('/// static method docs', .comment, [.documentation]),
      _Token('static', .keyword),
      _Token('void', .keyword, [.void_]),
      _Token('myStaticMethod', .method, [.declaration, .static]),
      _Token('// static method comment', .comment),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('final', .keyword),
      _Token('a', .variable, [.declaration]),
      _Token('MyClass', .class_, [.constructor]),
      _Token('a', .variable),
      _Token('myMethod', .method, [.instance]),
      _Token('MyClass', .class_),
      _Token('myStaticMethod', .method, [.static]),
      _Token('final', .keyword),
      _Token('b', .variable, [.declaration]),
      _Token('a', .variable),
      _Token('myMethod', .method, [.instance]),
      _Token('final', .keyword),
      _Token('c', .variable, [.declaration]),
      _Token('MyClass', .class_),
      _Token('myStaticMethod', .method, [.static]),
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
      _Token('B', .class_, [.constructor, .declaration]),
      _Token('b', .method, [.constructor, .declaration]),
      _Token('super', .keyword),
      _Token('1', .number),
      _Token('B', .class_, [.constructor, .declaration]),
      _Token('super', .keyword),
      _Token('i', .parameter, [.declaration]),
      _Token('void', .keyword, [.void_]),
      _Token('f', .method, [.declaration, .instance]),
      _Token('super', .keyword),
      _Token('f', .method, [.instance]),
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
      _Token('A', .class_, [.constructor, .declaration]),
      _Token('this', .keyword),
      _Token('a', .variable, [.instance]),
      _Token('A', .class_, [.constructor, .declaration]),
      _Token('b', .method, [.constructor, .declaration]),
      _Token('1', .number),
      _Token('void', .keyword, [.void_]),
      _Token('f', .method, [.declaration, .instance]),
      _Token('this', .keyword),
      _Token('f', .method, [.instance]),
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
      _Token('/// before [', .comment, [.documentation]),
      _Token('aaa', .property, [.instance]),
      _Token('] after', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('String', .class_),
      _Token('aaa', .variable, [.declaration, .instance]),
      _Token('/// before [', .comment, [.documentation]),
      _Token('bbb', .parameter),
      _Token('] after', .comment, [.documentation]),
      _Token('int', .class_),
      _Token('double', .function, [.declaration, .static]),
      _Token('int', .class_),
      _Token('bbb', .parameter, [.declaration]),
      _Token('bbb', .parameter),
      _Token('2', .number),
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
      _Token('/// MyClass.', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token('     CODE', .comment, [.documentation, .source]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
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
      _Token('/// MyClass.', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token(' ```', .comment, [.documentation, .source]),
      _Token('///', .comment, [.documentation]),
      _Token(' CODE', .comment, [.documentation, .source]),
      _Token('///', .comment, [.documentation]),
      _Token(' ```', .comment, [.documentation, .source]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
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
      _Token('/// MyClass.', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token('///', .comment, [.documentation]),
      _Token(' ```dart', .comment, [.documentation, .source]),
      _Token('///', .comment, [.documentation]),
      _Token(' CODE', .comment, [.documentation, .source]),
      _Token('///', .comment, [.documentation]),
      _Token(' ```', .comment, [.documentation, .source]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
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
      _Token('library', .keyword),
      _Token('foo', .namespace),
      _Token('import', .keyword),
      _Token("'package:flutter/material.dart'", .string),
      _Token('export', .keyword),
      _Token("'package:flutter/widgets.dart'", .string),
      _Token('import', .keyword),
      _Token("'../file.dart'", .string),
      _Token('if', .keyword, [.control]),
      _Token('dart', .source),
      _Token('library', .source),
      _Token('io', .source),
      _Token("'file_io.dart'", .string),
      _Token('if', .keyword, [.control]),
      _Token('dart', .source),
      _Token('library', .source),
      _Token('html', .source),
      _Token("'file_html.dart'", .string),
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
      _Token('A', .class_),
      _Token('a', .variable, [.declaration]),
      _Token('new', .method, [.constructor]),
      _Token('A', .class_),
      _Token('aa', .variable, [.declaration]),
      _Token('named', .method, [.constructor]),
      _Token('42', .number),
      _Token('A', .class_),
      _Token('aTearOff', .variable, [.declaration]),
      _Token('new', .method, [.constructor]),
      _Token('A', .class_),
      _Token('aTearOff', .variable, [.declaration]),
      _Token('named', .method, [.constructor]),
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
      _Token('E', .enum_),
      _Token('e', .variable, [.declaration]),
      _Token('a', .enumMember),
      _Token('A', .class_),
      _Token('a', .variable, [.declaration]),
      _Token('aGetter', .property, [.static]),
      _Token('B', .class_),
      _Token('b', .variable, [.declaration]),
      _Token('bGetter', .property, [.static]),
      _Token('Mixin', .class_),
      _Token('m', .variable, [.declaration]),
      _Token('dGetter', .property, [.static]),
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
      _Token('A', .class_),
      _Token('a', .variable, [.declaration]),
      _Token('aMethod', .method, [.static]),
      _Token('A', .class_),
      _Token('aa', .variable, [.declaration]),
      _Token('aMethod', .method, [.static]),
      _Token('B', .class_),
      _Token('b', .variable, [.declaration]),
      _Token('bMethod', .method, [.static]),
      _Token('B', .class_),
      _Token('bb', .variable, [.declaration]),
      _Token('bMethod', .method, [.static]),
      _Token('Mixin', .class_),
      _Token('m', .variable, [.declaration]),
      _Token('dMethod', .method, [.static]),
      _Token('Mixin', .class_),
      _Token('mm', .variable, [.declaration]),
      _Token('dMethod', .method, [.static]),
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
      _Token('extension', .keyword),
      _Token('A', .class_),
      _Token('on', .keyword),
      _Token('String', .class_),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_extensionType() async {
    var content = '''
extension type E(int i) {}
''';

    var expected = [
      _Token('extension', .keyword),
      _Token('type', .keyword),
      _Token('E', .class_, [.declaration]),
      _Token('int', .class_),
      _Token('i', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_fromPlugin() async {
    var pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    var pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    var content = 'CLASS STRING VARIABLE';
    var code = TestCode.parseNormalized(content);

    var expected = [
      _Token('CLASS', .class_),
      _Token('STRING', .string),
      _Token('VARIABLE', .variable, [.declaration]),
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
    var decoded = _decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_function_callMethod_invocation() async {
    var content = r'''
f(void Function(int)? x) {
  [!x?.call(2);!]
}
''';

    var expected = [
      _Token('x', .parameter),
      _Token('call', .method, [.instance]),
      _Token('2', .number),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_invocation_extension() async {
    var content = r'''
extension on void Function() {
  m() => [!call()!];
}
''';

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_function_callMethod_propertyAccess() async {
    var content = r'''
extension on void Function()? {
  m() => [!this?.call!];
}
''';

    var expected = <_Token>[
      _Token('this', .keyword),
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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
      _Token('x', .parameter),
      _Token('call', .method, [.instance]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_functionType_callMethod_invocation_extension() async {
    var content = r'''
extension on Function {
  m() => [!call()!];
}
''';

    var expected = <_Token>[
      _Token('call', .method, [.instance]),
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
      _Token('x', .parameter),
      _Token('call', .method, [.instance]),
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
    var decoded = _decodeSemanticTokens(updatedContent, tokens);
    expect(decoded, [
      _Token('class', .keyword),
      _Token('Aaaaa', .class_, [.declaration]),
      _Token('class', .keyword),
      _Token('Bbbbb', .class_, [.declaration]),
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
      _Token('A', .class_, [.constructor, .declaration]),
      _Token('String', .class_),
      _Token('a', .parameter, [.declaration]),
      _Token('a', .variable, [.instance]),
      _Token('a', .parameter),
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
      _Token('/// class docs', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('// class comment', .comment),
    ];
    var expected2 = [
      _Token('/// class docs 2', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass2', .class_, [.declaration]),
      _Token('// class comment 2', .comment),
    ];

    await initialize();
    await openFile(mainFileUri, code.code);

    var tokens = await getSemanticTokens(mainFileUri);
    var decoded = _decodeSemanticTokens(code.code, tokens);

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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('async', .keyword, [.control]),
      _Token('var', .keyword),
      _Token('a', .variable, [.declaration]),
      _Token('new', .keyword),
      _Token('Object', .class_, [.constructor]),
      _Token('await', .keyword, [.control]),
      _Token('null', .keyword),
      _Token('if', .keyword, [.control]),
      _Token('false', .boolean),
      _Token('print', .function),
      _Token("'test'", .string),
      _Token('for', .keyword, [.control]),
      _Token('var', .keyword),
      _Token('item', .variable, [.declaration]),
      _Token('in', .keyword, [.control]),
      _Token('switch', .keyword, [.control]),
      _Token('1', .number),
      _Token('case', .keyword, [.control]),
      _Token('int', .class_),
      _Token('var', .keyword),
      _Token('isEven', .variable, [.declaration]),
      _Token('when', .keyword, [.control]),
      _Token('isEven', .variable),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('myLabel', .label, [.declaration]),
      _Token('while', .keyword, [.control]),
      _Token('true', .boolean),
      _Token('break', .keyword, [.control]),
      _Token('myLabel', .label),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_code() async {
    var content = 'String? bar;';

    var expected = [
      _Token('String', .class_),
      _Token('bar', .variable, [.declaration]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_comment() async {
    var content = '// Trailing comment';

    var expected = [_Token('// Trailing comment', .comment)];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_lastLine_multilineComment() async {
    var content = '''
/**
 * Trailing comment
 */''';

    var expected = [
      _Token('/**$eol', .comment, [.documentation]),
      _Token(' * Trailing comment$eol', .comment, [.documentation]),
      _Token(' */', .comment, [.documentation]),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('func', .function, [.declaration]),
      _Token('String', .class_),
      _Token('a', .parameter, [.declaration]),
      _Token('print', .function),
      _Token('a', .parameter),
      _Token('final', .keyword),
      _Token('funcTearOff', .variable, [.declaration]),
      _Token('func', .function),
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
      _Token('class', .keyword),
      _Token('MyTestClass', .class_, [.declaration]),
      for (var i = 1; i <= 6; i++) ...[
        _Token('/// test', .comment, [.documentation]),
        _Token('/// test', .comment, [.documentation]),
        _Token('bool', .class_),
        _Token('test$i', .variable, [.declaration, .instance]),
        _Token('false', .boolean),
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
        _Token('import', .keyword),
        _Token("'dart:async'", .string),
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
      _Token('mixin', .keyword),
      _Token('M', .class_),
      _Token('on', .keyword),
      _Token('C', .class_),
      _Token('class', .keyword),
      _Token('C', .class_, [.declaration]),
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
      _Token('/**$eol', .comment, [.documentation]),
      _Token(' * This is my class comment$eol', .comment, [.documentation]),
      _Token(' *$eol', .comment, [.documentation]),
      _Token(' * There are$eol', .comment, [.documentation]),
      _Token(' * multiple lines$eol', .comment, [.documentation]),
      _Token(' */', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
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
      _Token('f', .function, [.declaration, .static]),
      _Token('String', .class_),
      _Token('a', .parameter, [.declaration]),
      _Token('dynamic', .type),
      _Token('b', .parameter, [.declaration]),
      _Token('f', .function),
      _Token('a', .parameter, [.label]),
      _Token('a', .parameter),
      _Token('b', .parameter, [.label]),
      _Token('b', .parameter),
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
      _Token('extension', .keyword),
      _Token('on', .keyword),
      _Token('int', .class_),
      _Token('get', .keyword),
      _Token('other', .property, [.declaration, .instance]),
      _Token('field', .property, [.instance]),
      _Token('this', .keyword),
      _Token('field', .property, [.instance]),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_never() async {
    var content = '''
Never f() => throw '';
Never? g() => throw '';
''';

    var expected = [
      _Token('Never', .type),
      _Token('f', .function, [.declaration, .static]),
      _Token('throw', .keyword, [.control]),
      _Token("''", .string),
      _Token('Never', .type),
      _Token('g', .function, [.declaration, .static]),
      _Token('throw', .keyword, [.control]),
      _Token("''", .string),
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
      _Token('this', .keyword),
      _Token('a', .variable, [.instance]),
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
      _Token('B', .class_, [.constructor, .declaration]),
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
      _Token('super', .keyword),
      _Token('b', .parameter, [.label]),
      _Token('a', .parameter),
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
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
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
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
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
      _Token('super', .keyword),
      _Token('a', .parameter, [.declaration]),
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
      _Token('this', .keyword),
      _Token('a', .variable, [.instance]),
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
      _Token('this', .keyword),
      _Token('a', .variable, [.instance]),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('int', .class_),
      _Token('a', .variable, [.declaration]),
      _Token('b', .variable, [.declaration]),
      _Token('int', .class_),
      _Token('a', .variable),
      _Token('b', .variable),
      _Token('1', .number),
      _Token('2', .number),
      _Token('var', .keyword),
      _Token('c', .variable, [.declaration]),
      _Token('d', .variable, [.declaration]),
      _Token('1', .number),
      _Token('2', .number),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('switch', .keyword, [.control]),
      _Token('1', .number),
      _Token('case', .keyword, [.control]),
      _Token('var', .keyword),
      _Token('c', .variable, [.declaration]),
      _Token("'a'", .string),
      _Token('when', .keyword, [.control]),
      _Token('c', .variable),
      _Token('null', .keyword),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('switch', .keyword, [.control]),
      _Token('1', .number),
      _Token('case', .keyword, [.control]),
      _Token('int', .class_),
      _Token('isEven', .property, [.instance]),
      _Token('var', .keyword),
      _Token('isEven', .variable, [.declaration]),
      _Token('toString', .method, [.instance]),
      _Token('var', .keyword),
      _Token('toString', .variable, [.declaration]),
      _Token('when', .keyword, [.control]),
      _Token('isEven', .variable),
      _Token('isEven', .variable),
      _Token('toString', .variable),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('switch', .keyword, [.control]),
      _Token('1', .number),
      _Token('case', .keyword, [.control]),
      _Token('int', .class_),
      _Token('var', .keyword),
      _Token('isEven', .variable, [.declaration]),
      _Token('when', .keyword, [.control]),
      _Token('isEven', .variable),
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
      _Token('extension', .keyword),
      _Token('on', .keyword),
      _Token('int', .class_),
      _Token('double', .class_),
      _Token('get', .keyword),
      _Token('other', .property, [.declaration, .instance]),
      _Token(r'$1', .property, [.instance]),
      _Token(r'$2', .property, [.instance]),
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
      _Token('MyClass', .class_, [.declaration]),
      _Token('T', .typeParameter),
      _Token('// class comment', .comment),
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
      _Token('/// class docs', .comment, [.documentation]),
      _Token('class', .keyword),
      _Token('MyClass', .class_, [.declaration]),
      _Token('T', .typeParameter),
      _Token('// class comment', .comment),
      _Token('// Trailing comment', .comment),
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
      _Token(' * There are$eol', .comment, [.documentation]),
      _Token(' * multiple lines$eol', .comment, [.documentation]),
      _Token(' */', .comment, [.documentation]),
      _Token('class', .keyword),
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
      _Token('record', .parameter),
      _Token(r'$1', .property, [.instance]),
      _Token('record', .parameter),
      _Token('field1', .property, [.instance]),
      _Token('1', .number),
      _Token(r'$1', .property, [.instance]),
      _Token('field1', .parameter),
      _Token('1', .number),
      _Token('field1', .property, [.instance]),
      _Token('1', .number),
      _Token('unresolved', .source),
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
      _Token("'", .string),
      _Token(r'$', .source, [.interpolation]),
      _Token('s', .property),
      _Token(r'$', .source, [.interpolation]),
      _Token('s', .property),
      _Token("'", .string),
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
      _Token('String', .class_),
      _Token('foo', .function, [.declaration, .static]),
      _Token('String', .class_),
      _Token('c', .parameter, [.declaration]),
      _Token('c', .parameter),

      _Token('const', .keyword),
      _Token('string1', .variable, [.declaration]),
      _Token("'test'", .string),

      _Token('var', .keyword),
      _Token('string2', .variable, [.declaration]),
      _Token(r"'test1 ", .string),
      _Token(r'$', .source, [.interpolation]),
      _Token('string1', .property),
      _Token(' test2 ', .string),
      _Token(r'${', .source, [.interpolation]),
      _Token('foo', .function),
      _Token('(', .source, [.interpolation]),
      _Token("'a'", .string),
      _Token(' + ', .source, [.interpolation]),
      _Token("'b'", .string),
      _Token(')}', .source, [.interpolation]),
      _Token("'", .string),

      // string3 is raw and should be treated as a single string.
      _Token('const', .keyword),
      _Token('string3', .variable, [.declaration]),
      _Token(r"r'$string1 ${string1.length}'", .string),
      _Token('const', .keyword),

      _Token('string4', .variable, [.declaration]),
      _Token("'''$eol", .string),
      _Token('multi$eol', .string),
      _Token('  line$eol', .string),
      _Token('    string$eol', .string),
      _Token("'''", .string),
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
      _Token('const', .keyword),
      _Token('string1', .variable, [.declaration]),
      _Token("'it", .string),
      _Token(r"\'", .string, [.escape]),
      _Token('s escaped', .string),
      _Token(r'\\', .string, [.escape]),
      _Token(r'\n', .string, [.escape]),
      _Token(r'\$', .string, [.escape]),
      _Token(r"'", .string),
      _Token('const', .keyword),
      _Token('string2', .variable, [.declaration]),
      _Token("'hex ", .string),
      _Token(r'\x12', .string, [.escape]),
      _Token(r'\x12', .string, [.escape]),
      // The 99 is not part of the escape
      _Token("99'", .string),
      _Token('const', .keyword),
      _Token('string3', .variable, [.declaration]),
      _Token("'unicode ", .string),
      _Token(r'\u1234', .string, [.escape]),
      _Token(r'\u1234', .string, [.escape]),
      // The 99 is not part of the escape
      _Token('99', .string),
      _Token(r'\u{123456}', .string, [.escape]),
      // The 99 makes this invalid so i's not an escape
      _Token(r"\u{12345699}'", .string),
      _Token('const', .keyword),
      _Token('string4', .variable, [.declaration]),
      _Token('"', .string),
      _Token(r'\"', .string, [.escape]),
      _Token('"', .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_strings_escape_interpolation1() async {
    var content = r'''
const value = 1;
const string1 = 'it\'s $value escaped\\\n';
''';

    var expected = [
      _Token('const', .keyword),
      _Token('value', .variable, [.declaration]),
      _Token('1', .number),
      _Token('const', .keyword),
      _Token('string1', .variable, [.declaration]),
      _Token("'it", .string),
      _Token(r"\'", .string, [.escape]),
      _Token('s ', .string),
      _Token(r'$', .source, [.interpolation]),
      _Token('value', .property),
      _Token(' escaped', .string),
      _Token(r'\\', .string, [.escape]),
      _Token(r'\n', .string, [.escape]),
      _Token(r"'", .string),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  Future<void> test_strings_escape_interpolation2() async {
    var content = r'''
const value = 1;
const string1 = 'it\'s ${value} escaped\\\n';
''';

    var expected = [
      _Token('const', .keyword),
      _Token('value', .variable, [.declaration]),
      _Token('1', .number),
      _Token('const', .keyword),
      _Token('string1', .variable, [.declaration]),
      _Token("'it", .string),
      _Token(r"\'", .string, [.escape]),
      _Token('s ', .string),
      _Token(r'${', .source, [.interpolation]),
      _Token('value', .property),
      _Token('}', .source, [.interpolation]),
      _Token(' escaped', .string),
      _Token(r'\\', .string, [.escape]),
      _Token(r'\n', .string, [.escape]),
      _Token(r"'", .string),
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
      _Token('/// strings docs', .comment, [.documentation]),
      _Token('const', .keyword),
      _Token('strings', .variable, [.declaration]),
      _Token('String', .class_),
      _Token('"test"', .string),
      _Token("'test'", .string),
      _Token("r'test'", .string),
      _Token("'''test'''", .string),
      _Token('/// func docs', .comment, [.documentation]),
      _Token('func', .function, [.declaration, .static]),
      _Token('String', .class_),
      _Token('a', .parameter, [.declaration]),
      _Token('print', .function),
      _Token('a', .parameter),
      _Token('/// abc docs', .comment, [.documentation]),
      _Token('bool', .class_),
      _Token('get', .keyword),
      _Token('abc', .property, [.declaration]),
      _Token('true', .boolean),
      _Token('final', .keyword),
      _Token('funcTearOff', .variable, [.declaration]),
      _Token('func', .function),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('strings', .property),
      _Token('func', .function),
      _Token('abc', .property),
      _Token('funcTearOff', .property),
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
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('int', .class_),
      _Token('a', .variable, [.declaration]),
      _Token('a', .variable),
      _Token('foo', .source),
      _Token('bar', .source),
      _Token('baz', .source),
      _Token('dynamic', .type),
      _Token('b', .variable, [.declaration]),
      _Token('b', .variable),
      _Token('foo', .source),
      _Token('bar', .source),
      _Token('baz', .source),
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
      _Token('_', .variable, [.declaration, .wildcard]),
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
      _Token('_', .variable, [.declaration, .wildcard]),
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
      _Token('_', .variable, [.declaration, .wildcard]),
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
      _Token('_', .method, [.declaration, .instance]),
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
      _Token('this', .keyword),
      _Token('_', .variable, [.instance]),
      _Token('super', .keyword),
      _Token('_', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_topLevelFunction() async {
    var content = r'''
void [!_!]() {}
''';

    var expected = [
      _Token('_', .function, [.declaration, .static]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_topLevelVariable() async {
    var content = r'''
var [!_!] = 1;
''';

    var expected = [
      _Token('_', .variable, [.declaration]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_notWildcard_typeName() async {
    var content = r'''
class [!_!] {}
''';

    var expected = [
      _Token('_', .class_, [.declaration]),
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
      _Token('_', .variable, [.declaration, .wildcard]),
      _Token('_', .variable, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_functionExpression() async {
    var content = r'''
var a = [].where(([!_!]) => true);
''';

    var expected = [
      _Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_functionType() async {
    var content = r'''
typedef T = void Function(String [!_!]);
''';

    var expected = [
      _Token('_', .parameter, [.declaration, .wildcard]),
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
      _Token('_', .parameter, [.declaration, .wildcard]),
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
      _Token('_', .parameter, [.declaration, .wildcard]),
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
      _Token('_', .parameter, [.declaration, .wildcard]),
    ];

    await _initializeAndVerifyTokensInRange(content, expected);
  }

  Future<void> test_wildcard_parameter_topLevelFunction() async {
    var content = r'''
void f([!_!]) {}
''';

    var expected = [
      _Token('_', .parameter, [.declaration, .wildcard]),
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
      _Token('_', .variable, [.declaration, .wildcard]),
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
      _Token('class', .keyword),
      _Token('T', .class_, [.declaration]),
      _Token('_', .typeParameter, [.wildcard]),
      _Token('void', .keyword, [.void_]),
      _Token('genericFunction', .function, [.declaration, .static]),
      _Token('_', .typeParameter, [.wildcard]),
      _Token('Object', .class_),
      _Token('_', .parameter, [.declaration, .wildcard]),
      _Token('void', .keyword, [.void_]),
      _Token('f', .function, [.declaration, .static]),
      _Token('genericFunction', .function),
      _Token('_', .typeParameter, [.wildcard]),
      _Token('true', .boolean),
    ];

    await _initializeAndVerifyTokens(content, expected);
  }

  /// Decode tokens according to the LSP spec and pair with relevant file contents.
  List<_Token> _decodeSemanticTokens(String content, SemanticTokens tokens) {
    var contentLines = content.split(eol).map((line) => '$line$eol').toList();
    var results = <_Token>[];

    var lastLine = 0;
    var lastColumn = 0;
    for (var i = 0; i < tokens.data.length; i += 5) {
      var lineDelta = tokens.data[i];
      var columnDelta = tokens.data[i + 1];
      var length = tokens.data[i + 2];
      var tokenTypeIndex = tokens.data[i + 3];
      var modifierBitmask = tokens.data[i + 4];

      // Calculate the actual line/col from the deltas.
      var line = lastLine + lineDelta;
      var column = lineDelta == 0 ? lastColumn + columnDelta : columnDelta;

      var tokenContent = contentLines[line].substring(column, column + length);
      results.add(
        _Token(
          tokenContent,
          _AllSemanticTokenTypes.forTokenType(
            semanticTokenLegend.typeForIndex(tokenTypeIndex),
          ),
          semanticTokenLegend
              .modifiersForBitmask(modifierBitmask)
              .map(_AllSemanticTokenModifiers.forModifier)
              .toList(),
        ),
      );

      lastLine = line;
      lastColumn = column;
    }

    return results;
  }

  /// Initializes the server with [content] in [uri] and then calls
  /// [_verifyTokens] to check the semantic tokens match [expected].
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _initializeAndVerifyTokens(
    String content,
    List<_Token> expected, {
    Uri? uri,
  }) async {
    uri ??= mainFileUri;
    content = normalizeNewlinesForPlatform(content);
    newFile(fromUri(uri), content);
    await initialize();

    await _verifyTokens(uri, content, expected);
  }

  /// Initializes the server with [content] in [uri] and then checks the
  ///  semantic tokens for the marked range match [expected].
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _initializeAndVerifyTokensInRange(
    String content,
    List<_Token> expected, {
    Uri? uri,
  }) async {
    uri ??= mainFileUri;
    var code = TestCode.parseNormalized(content);
    newFile(fromUri(uri), code.code);
    await initialize();

    var tokens = await getSemanticTokensRange(mainFileUri, code.range.range);
    var decoded = _decodeSemanticTokens(code.code, tokens);
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
    List<_Token> expected,
  ) async {
    content = normalizeNewlinesForPlatform(content);

    var tokens = await getSemanticTokens(uri);
    var decoded = _decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }
}

/// A helper enum to combine both standard and custom modifiers so that they
/// can all be used as DotShorthands for improved readability in test
/// expectations.
enum _AllSemanticTokenModifiers {
  abstract(SemanticTokenModifiers.abstract),
  annotation(CustomSemanticTokenModifiers.annotation),
  async(SemanticTokenModifiers.async),
  constructor(CustomSemanticTokenModifiers.constructor),
  control(CustomSemanticTokenModifiers.control),
  declaration(SemanticTokenModifiers.declaration),
  defaultLibrary(SemanticTokenModifiers.defaultLibrary),
  definition(SemanticTokenModifiers.definition),
  deprecated(SemanticTokenModifiers.deprecated),
  documentation(SemanticTokenModifiers.documentation),
  escape(CustomSemanticTokenModifiers.escape),
  importPrefix(CustomSemanticTokenModifiers.importPrefix),
  instance(CustomSemanticTokenModifiers.instance),
  interpolation(CustomSemanticTokenModifiers.interpolation),
  label(CustomSemanticTokenModifiers.label),
  modification(SemanticTokenModifiers.modification),
  readonly(SemanticTokenModifiers.readonly),
  source(CustomSemanticTokenModifiers.source),
  static(SemanticTokenModifiers.static),
  void_(CustomSemanticTokenModifiers.void_),
  wildcard(CustomSemanticTokenModifiers.wildcard);

  final SemanticTokenModifiers modifier;

  new(this.modifier);

  factory forModifier(SemanticTokenModifiers modifier) {
    return _AllSemanticTokenModifiers.values.singleWhere(
      (value) => value.modifier == modifier,
    );
  }
}

/// A helper enum to combine both standard and custom semantic token types so
/// that they can all be used as DotShorthands for improved readability in test
/// expectations.
///
///
enum _AllSemanticTokenTypes {
  annotation(CustomSemanticTokenTypes.annotation),
  boolean(CustomSemanticTokenTypes.boolean),
  class_(SemanticTokenTypes.class_),
  comment(SemanticTokenTypes.comment),
  decorator(SemanticTokenTypes.decorator),
  enum_(SemanticTokenTypes.enum_),
  enumMember(SemanticTokenTypes.enumMember),
  event(SemanticTokenTypes.event),
  function(SemanticTokenTypes.function),
  interface(SemanticTokenTypes.interface),
  keyword(SemanticTokenTypes.keyword),
  label(SemanticTokenTypes.label),
  macro(SemanticTokenTypes.macro),
  method(SemanticTokenTypes.method),
  modifier(SemanticTokenTypes.modifier),
  namespace(SemanticTokenTypes.namespace),
  number(SemanticTokenTypes.number),
  operator(SemanticTokenTypes.operator),
  parameter(SemanticTokenTypes.parameter),
  property(SemanticTokenTypes.property),
  regexp(SemanticTokenTypes.regexp),
  source(CustomSemanticTokenTypes.source),
  string(SemanticTokenTypes.string),
  struct(SemanticTokenTypes.struct),
  type(SemanticTokenTypes.type),
  typeParameter(SemanticTokenTypes.typeParameter),
  variable(SemanticTokenTypes.variable);

  final SemanticTokenTypes tokenType;

  new(this.tokenType);

  factory forTokenType(SemanticTokenTypes tokenType) {
    return _AllSemanticTokenTypes.values.singleWhere(
      (value) => value.tokenType == tokenType,
    );
  }
}

class _Token {
  final String content;
  final SemanticTokenTypes type;
  final List<SemanticTokenModifiers> modifiers;

  new(
    this.content,
    _AllSemanticTokenTypes type, [
    List<_AllSemanticTokenModifiers> mods = const [],
  ]) : type = type.tokenType,
       modifiers = mods.map((mod) => mod.modifier).toList();

  @override
  int get hashCode => content.hashCode;

  @override
  bool operator ==(Object o) =>
      o is _Token &&
      o.content == content &&
      o.type == type &&
      listEqual(
        // Treat nulls the same as empty lists for convenience when comparing.
        o.modifiers,
        modifiers,
        (SemanticTokenModifiers a, SemanticTokenModifiers b) => a == b,
      );

  /// Outputs a text representation of the token in the form of constructor
  /// args for easy copy/pasting into tests to update expectations.
  @override
  String toString() {
    var modifiersString = modifiers.isEmpty
        ? ''
        : ', [${modifiers.map((m) => '.$m').join(', ')}]';
    return "('$content', .$type$modifiersString)";
  }
}
