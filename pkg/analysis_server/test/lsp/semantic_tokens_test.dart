// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
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
  @override
  AnalysisServerOptions get serverOptions => AnalysisServerOptions()
    ..enabledExperiments = [
      EnableString.patterns,
    ];

  Future<void> test_annotation() async {
    final content = '''
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

    final otherContent = '''
class C {
  const C();
  const C.n();
}
''';

    final code = TestCode.parse(content);
    final otherCode = TestCode.parse(otherContent);

    final expectedStart = [
      _Token('import', SemanticTokenTypes.keyword),
      _Token("'other_file.dart'", SemanticTokenTypes.string),
      _Token('as', SemanticTokenTypes.keyword),
      _Token('other', SemanticTokenTypes.variable,
          [CustomSemanticTokenModifiers.importPrefix]),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('a', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('A', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('(', CustomSemanticTokenTypes.annotation),
      _Token(')', CustomSemanticTokenTypes.annotation),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('A', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('.', CustomSemanticTokenTypes.annotation),
      _Token('n', SemanticTokenTypes.method, [
        CustomSemanticTokenModifiers.constructor,
        CustomSemanticTokenModifiers.annotation
      ]),
      _Token('(', CustomSemanticTokenTypes.annotation),
      _Token(')', CustomSemanticTokenTypes.annotation),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('B', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('(', CustomSemanticTokenTypes.annotation),
      _Token('A', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token(')', CustomSemanticTokenTypes.annotation),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('other', SemanticTokenTypes.variable,
          [CustomSemanticTokenModifiers.importPrefix]),
      _Token('.', CustomSemanticTokenTypes.annotation),
      _Token('C', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('(', CustomSemanticTokenTypes.annotation),
      _Token(')', CustomSemanticTokenTypes.annotation),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('other', SemanticTokenTypes.variable,
          [CustomSemanticTokenModifiers.importPrefix]),
      _Token('.', CustomSemanticTokenTypes.annotation),
      _Token('C', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('.', CustomSemanticTokenTypes.annotation),
      _Token('n', SemanticTokenTypes.method, [
        CustomSemanticTokenModifiers.constructor,
        CustomSemanticTokenModifiers.annotation
      ]),
      _Token('(', CustomSemanticTokenTypes.annotation),
      _Token(')', CustomSemanticTokenTypes.annotation),
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('foo', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static])
    ];

    final otherFilePath = join(projectFolderPath, 'lib', 'other_file.dart');
    final otherFileUri = pathContext.toUri(otherFilePath);

    await initialize();
    await openFile(mainFileUri, code.code);
    await openFile(otherFileUri, otherCode.code);

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = _decodeSemanticTokens(content, tokens);
    expect(
      // Only check the first expectedStart.length items since the test code
      // is mostly unrelated to the annotations.
      decoded.sublist(0, expectedStart.length),
      equals(expectedStart),
    );
  }

  Future<void> test_class() async {
    final content = '''
/// class docs
class MyClass<T> {
  // class comment
}

// Trailing comment
''';

    final expected = [
      _Token('/// class docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('T', SemanticTokenTypes.typeParameter),
      _Token('// class comment', SemanticTokenTypes.comment),
      _Token('// Trailing comment', SemanticTokenTypes.comment),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_class_constructors() async {
    final content = '''
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

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_, [
        CustomSemanticTokenModifiers.constructor,
        SemanticTokenModifiers.declaration
      ]),
      _Token('MyClass', SemanticTokenTypes.class_, [
        CustomSemanticTokenModifiers.constructor,
        SemanticTokenModifiers.declaration
      ]),
      _Token('named', SemanticTokenTypes.method, [
        CustomSemanticTokenModifiers.constructor,
        SemanticTokenModifiers.declaration
      ]),
      _Token('factory', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_, [
        CustomSemanticTokenModifiers.constructor,
        SemanticTokenModifiers.declaration
      ]),
      _Token('factory', SemanticTokenTypes.method, [
        CustomSemanticTokenModifiers.constructor,
        SemanticTokenModifiers.declaration
      ]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('b', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('named', SemanticTokenTypes.method,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('c', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('factory', SemanticTokenTypes.method,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('d', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('named', SemanticTokenTypes.method,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('e', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_class_fields() async {
    final content = '''
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

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('/// field docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('myField', SemanticTokenTypes.property, [
        SemanticTokenModifiers.declaration,
        CustomSemanticTokenModifiers.instance
      ]),
      _Token("'FieldVal'", SemanticTokenTypes.string),
      _Token('/// static field docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('String', SemanticTokenTypes.class_),
      _Token('myStaticField', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token("'StaticFieldVal'", SemanticTokenTypes.string),
      _Token(
          'void', SemanticTokenTypes.keyword, [SemanticTokenModifiers('void')]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myField', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.instance]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('myStaticField', SemanticTokenTypes.property,
          [SemanticTokenModifiers.static]),
      _Token("'a'", SemanticTokenTypes.string),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_class_getterSetter() async {
    final content = '''
class MyClass {
  /// getter docs
  String get myGetter => 'GetterVal';
  /// setter docs
  set mySetter(String v) {};
  /// static getter docs
  static String get myStaticGetter => 'StaticGetterVal';
  /// static setter docs
  static set myStaticSetter(String staticV) {};
}

void f() {
  final a = MyClass();
  print(a.myGetter);
  a.mySetter = 'a';
}
''';

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('/// getter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('myGetter', SemanticTokenTypes.property, [
        SemanticTokenModifiers.declaration,
        CustomSemanticTokenModifiers.instance
      ]),
      _Token("'GetterVal'", SemanticTokenTypes.string),
      _Token('/// setter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('set', SemanticTokenTypes.keyword),
      _Token('mySetter', SemanticTokenTypes.property, [
        SemanticTokenModifiers.declaration,
        CustomSemanticTokenModifiers.instance
      ]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('v', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('/// static getter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('String', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('myStaticGetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token("'StaticGetterVal'", SemanticTokenTypes.string),
      _Token('/// static setter docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('set', SemanticTokenTypes.keyword),
      _Token('myStaticSetter', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('staticV', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token(
          'void', SemanticTokenTypes.keyword, [SemanticTokenModifiers('void')]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myGetter', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.instance]),
      _Token('a', SemanticTokenTypes.variable),
      _Token('mySetter', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.instance]),
      _Token("'a'", SemanticTokenTypes.string),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_class_method() async {
    final content = '''
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

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('/// method docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('@', CustomSemanticTokenTypes.annotation),
      _Token('override', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.annotation]),
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('myMethod', SemanticTokenTypes.method, [
        SemanticTokenModifiers.declaration,
        CustomSemanticTokenModifiers.instance
      ]),
      _Token('/// static method docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('static', SemanticTokenTypes.keyword),
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('myStaticMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('// static method comment', SemanticTokenTypes.comment),
      _Token(
          'void', SemanticTokenTypes.keyword, [SemanticTokenModifiers('void')]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myMethod', SemanticTokenTypes.method,
          [CustomSemanticTokenModifiers.instance]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('myStaticMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.static]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('b', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('a', SemanticTokenTypes.variable),
      _Token('myMethod', SemanticTokenTypes.method,
          [CustomSemanticTokenModifiers.instance]),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('c', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('MyClass', SemanticTokenTypes.class_),
      _Token('myStaticMethod', SemanticTokenTypes.method,
          [SemanticTokenModifiers.static]),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_dartdoc() async {
    final content = '''
/// before [aaa] after
class MyClass {
  String aaa;
}

/// before [bbb] after
int double(int bbb) => bbb * 2;
''';

    final expected = [
      _Token('/// before [', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('aaa', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.instance]),
      _Token('] after', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('aaa', SemanticTokenTypes.property, [
        SemanticTokenModifiers.declaration,
        CustomSemanticTokenModifiers.instance
      ]),
      _Token('/// before [', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('bbb', SemanticTokenTypes.parameter),
      _Token('] after', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('double', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('bbb', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('bbb', SemanticTokenTypes.parameter),
      _Token('2', SemanticTokenTypes.number)
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_directives() async {
    final content = '''
import 'package:flutter/material.dart';
export 'package:flutter/widgets.dart';
import '../file.dart'
  if (dart.library.io) 'file_io.dart'
  if (dart.library.html) 'file_html.dart';

library foo;
''';

    final expected = [
      _Token('import', SemanticTokenTypes.keyword),
      _Token("'package:flutter/material.dart'", SemanticTokenTypes.string),
      _Token('export', SemanticTokenTypes.keyword),
      _Token("'package:flutter/widgets.dart'", SemanticTokenTypes.string),
      _Token('import', SemanticTokenTypes.keyword),
      _Token("'../file.dart'", SemanticTokenTypes.string),
      _Token('if', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('dart', CustomSemanticTokenTypes.source),
      _Token('library', CustomSemanticTokenTypes.source),
      _Token('io', CustomSemanticTokenTypes.source),
      _Token("'file_io.dart'", SemanticTokenTypes.string),
      _Token('if', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('dart', CustomSemanticTokenTypes.source),
      _Token('library', CustomSemanticTokenTypes.source),
      _Token('html', CustomSemanticTokenTypes.source),
      _Token("'file_html.dart'", SemanticTokenTypes.string),
      _Token('library', SemanticTokenTypes.keyword),
      _Token('foo', SemanticTokenTypes.namespace),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_extension() async {
    final content = '''
extension A on String {}
''';

    final expected = [
      _Token('extension', SemanticTokenTypes.keyword),
      _Token('A', SemanticTokenTypes.class_),
      _Token('on', SemanticTokenTypes.keyword),
      _Token('String', SemanticTokenTypes.class_)
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_fromPlugin() async {
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    final pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    final content = 'CLASS STRING VARIABLE';
    final code = TestCode.parse(content);

    final expected = [
      _Token('CLASS', SemanticTokenTypes.class_),
      _Token('STRING', SemanticTokenTypes.string),
      _Token('VARIABLE', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
    ];

    await initialize();
    await openFile(pluginAnalyzedFileUri, code.code);

    final pluginResult = plugin.AnalysisHighlightsParams(
      pluginAnalyzedFilePath,
      [
        plugin.HighlightRegion(plugin.HighlightRegionType.CLASS, 0, 5),
        plugin.HighlightRegion(plugin.HighlightRegionType.LITERAL_STRING, 6, 6),
        plugin.HighlightRegion(
            plugin.HighlightRegionType.LOCAL_VARIABLE_DECLARATION, 13, 8),
      ],
    );
    configureTestPlugin(notification: pluginResult.toNotification());

    final tokens = await getSemanticTokens(pluginAnalyzedFileUri);
    final decoded = _decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> test_invalidSyntax() async {
    final content = '''
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
    final code = TestCode.parse(content);

// Expect the correct tokens for the valid code before/after but don't
// check the tokens for the invalid code as there are no concrete
// expectations for them.
    final expected1 = [
      _Token('/// class docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('// class comment', SemanticTokenTypes.comment),
    ];
    final expected2 = [
      _Token('/// class docs 2', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass2', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('// class comment 2', SemanticTokenTypes.comment),
    ];

    await initialize();
    await openFile(mainFileUri, code.code);

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = _decodeSemanticTokens(content, tokens);

    // Remove the tokens between the two expected sets.
    decoded.removeRange(expected1.length, decoded.length - expected2.length);

    expect(decoded, equals([...expected1, ...expected2]));
  }

  Future<void> test_keywords() async {
    // "control" keywords should be tagged with a modifier so the client
    // can color them differently to other keywords.
    final content = r'''
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

    final expected = [
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('async', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('new', SemanticTokenTypes.keyword),
      _Token('Object', SemanticTokenTypes.class_,
          [CustomSemanticTokenModifiers.constructor]),
      _Token('await', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('null', SemanticTokenTypes.keyword),
      _Token('if', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('false', CustomSemanticTokenTypes.boolean),
      _Token('print', SemanticTokenTypes.function),
      _Token("'test'", SemanticTokenTypes.string),
      _Token('for', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('item', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('in', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('switch', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('1', SemanticTokenTypes.number),
      _Token('case', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('isEven', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('when', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('isEven', SemanticTokenTypes.variable),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_lastLine_code() async {
    final content = 'String bar;';

    final expected = [
      _Token('String', SemanticTokenTypes.class_),
      _Token('bar', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_lastLine_comment() async {
    final content = '// Trailing comment';

    final expected = [
      _Token('// Trailing comment', SemanticTokenTypes.comment),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_lastLine_multilineComment() async {
    final content = '''
/**
 * Trailing comment
 */''';

    final expected = [
      _Token('/**\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' * Trailing comment\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' */', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_local() async {
    final content = '''
void f() {
  func(String a) => print(a);
  final funcTearOff = func;
}
''';

    final expected = [
      _Token(
          'void', SemanticTokenTypes.keyword, [SemanticTokenModifiers('void')]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('func', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.parameter),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('funcTearOff', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('func', SemanticTokenTypes.function),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_manyBools_bug() async {
// Similar to test_manyImports_sortBug, this code triggered inconsistent tokens
// for "false" because tokens were sorted incorrectly (because both boolean and
// keyword had the same offset and length, which is all that were sorted by).
    final content = '''
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

    final expected = [
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyTestClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      for (var i = 1; i <= 6; i++) ...[
        _Token('/// test', SemanticTokenTypes.comment,
            [SemanticTokenModifiers.documentation]),
        _Token('/// test', SemanticTokenTypes.comment,
            [SemanticTokenModifiers.documentation]),
        _Token('bool', SemanticTokenTypes.class_),
        _Token('test$i', SemanticTokenTypes.property, [
          SemanticTokenModifiers.declaration,
          CustomSemanticTokenModifiers.instance
        ]),
        _Token('false', CustomSemanticTokenTypes.boolean),
      ],
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_manyImports_sortBug() async {
// This test is for a bug where some "import" tokens would not be highlighted
// correctly. Imports are made up of a DIRECTIVE token that spans a
// BUILT_IN ("import") and LITERAL_STRING. The original code sorted by only
// offset when handling overlapping tokens, which for certain lists (such as
// the one created for the code below) would result in the BUILTIN coming before
// the DIRECTIVE, which resulted in the DIRECTIVE overwriting it.
    final content = '''
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

    final expected = [
      for (var i = 0; i < 13; i++) ...[
        _Token('import', SemanticTokenTypes.keyword),
        _Token("'dart:async'", SemanticTokenTypes.string),
      ],
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_multilineRegions() async {
    final content = '''
/**
 * This is my class comment
 *
 * There are
 * multiple lines
 */
class MyClass {}
''';

    final expected = [
      _Token('/**\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' * This is my class comment\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' *\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' * There are\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' * multiple lines\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' */', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_namedArguments() async {
    final content = '''
f({String a}) {
  f(a: a);
}
''';

    final expected = [
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('f', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.parameter,
          [CustomSemanticTokenModifiers.label]),
      _Token('a', SemanticTokenTypes.parameter),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_never() async {
    final content = '''
Never f() => throw '';
Never? g() => throw '';
''';

    final expected = [
      _Token('Never', SemanticTokenTypes.type),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('throw', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token("''", SemanticTokenTypes.string),
      _Token('Never', SemanticTokenTypes.type),
      _Token('g', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('throw', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token("''", SemanticTokenTypes.string),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_patterns_assignment() async {
    final content = r'''
void f() {
  int a, b;
  <int>[a, b] = [1, 2];
  var [c, d] = [1, 2];
}
''';

    final expected = [
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('b', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.variable),
      _Token('b', SemanticTokenTypes.variable),
      _Token('1', SemanticTokenTypes.number),
      _Token('2', SemanticTokenTypes.number),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('c', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('d', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('1', SemanticTokenTypes.number),
      _Token('2', SemanticTokenTypes.number)
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_list() async {
    final content = r'''
void f() {
  switch (1) {
    case [var c, == 'a'] when c != null:
  }
}
''';

    final expected = [
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('switch', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('1', SemanticTokenTypes.number),
      _Token('case', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('c', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token("'a'", SemanticTokenTypes.string),
      _Token('when', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('c', SemanticTokenTypes.variable),
      _Token('null', SemanticTokenTypes.keyword)
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_object() async {
    final content = r'''
void f() {
  switch (1) {
    case int(isEven: var isEven) when isEven:
  }
}
''';

    final expected = [
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('switch', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('1', SemanticTokenTypes.number),
      _Token('case', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('isEven', SemanticTokenTypes.property,
          [CustomSemanticTokenModifiers.instance]),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('isEven', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('when', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('isEven', SemanticTokenTypes.variable),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_patterns_switch_object_inferredName() async {
    final content = r'''
void f() {
  switch (1) {
    case int(:var isEven) when isEven:
  }
}
''';

    final expected = [
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('switch', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('1', SemanticTokenTypes.number),
      _Token('case', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('var', SemanticTokenTypes.keyword),
      _Token('isEven', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('when', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.control]),
      _Token('isEven', SemanticTokenTypes.variable),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_range() async {
    final content = '''
/// class docs
class [!MyClass<T> {
  // class comment
}!]

// Trailing comment
''';

    final expected = [
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('T', SemanticTokenTypes.typeParameter),
      _Token('// class comment', SemanticTokenTypes.comment),
    ];

    await _verifyTokensInRange(content, expected);
  }

  Future<void> test_range_entireFile() async {
    final content = '''[!
/// class docs
class MyClass<T> {
  // class comment
}

// Trailing comment
!]''';

    final expected = [
      _Token('/// class docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
      _Token('MyClass', SemanticTokenTypes.class_,
          [SemanticTokenModifiers.declaration]),
      _Token('T', SemanticTokenTypes.typeParameter),
      _Token('// class comment', SemanticTokenTypes.comment),
      _Token('// Trailing comment', SemanticTokenTypes.comment),
    ];

    await _verifyTokensInRange(content, expected);
  }

  Future<void> test_range_multilineRegions() async {
    final content = '''
/**
 * This is my class comment
 *
 * [!There are
 * multiple lines
 */
class!] MyClass {}
''';

    final expected = [
      _Token(' * There are\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' * multiple lines\n', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token(' */', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('class', SemanticTokenTypes.keyword),
    ];

    await _verifyTokensInRange(content, expected);
  }

  Future<void> test_sort_sameOffsets() async {
// This code initially (before merging) produces a String token starting at
// offset 11 (as it drops out of one interpolated variable) and then a new
// Interpolatation token.
// This test is to ensure the assertion in `offsetLengthPrioritySort` does
// not trigger (as it does if length is ignored, which was a bug).
    final content = r'''
var a = '$s$s';
''';

    final expected = [
      _Token('var', SemanticTokenTypes.keyword),
      _Token('a', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'", SemanticTokenTypes.string),
      _Token(r'$', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token('s', CustomSemanticTokenTypes.source),
      _Token(r'$', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token('s', CustomSemanticTokenTypes.source),
      _Token("'", SemanticTokenTypes.string)
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_strings() async {
    final content = '''
String foo(String c) => c;
const string1 = 'test';
const string2 = 'test1 \$string1 test2 \${foo('a' + 'b')}';
const string3 = r'\$string1 \${string1.length}';
const string4 = \'\'\'
multi
  line
    string
\'\'\';
''';

    final expected = [
      _Token('String', SemanticTokenTypes.class_),
      _Token('foo', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('c', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('c', SemanticTokenTypes.parameter),

      _Token('const', SemanticTokenTypes.keyword),
      _Token('string1', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'test'", SemanticTokenTypes.string),

      _Token('const', SemanticTokenTypes.keyword),
      _Token('string2', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token(r"'test1 ", SemanticTokenTypes.string),
      _Token(r'$', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token('string1', SemanticTokenTypes.property),
      _Token(' test2 ', SemanticTokenTypes.string),
      _Token(r'${', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token('foo', SemanticTokenTypes.function),
      _Token('(', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token("'a'", SemanticTokenTypes.string),
      _Token(' + ', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token("'b'", SemanticTokenTypes.string),
      _Token(')}', CustomSemanticTokenTypes.source,
          [CustomSemanticTokenModifiers.interpolation]),
      _Token("'", SemanticTokenTypes.string),

      // string3 is raw and should be treated as a single string.
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string3', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token(r"r'$string1 ${string1.length}'", SemanticTokenTypes.string),
      _Token('const', SemanticTokenTypes.keyword),

      _Token('string4', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'''\n", SemanticTokenTypes.string),
      _Token('multi\n', SemanticTokenTypes.string),
      _Token('  line\n', SemanticTokenTypes.string),
      _Token('    string\n', SemanticTokenTypes.string),
      _Token("'''", SemanticTokenTypes.string),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_strings_escape() async {
    // The 9's in these strings are not part of the escapes (they make the
    // strings too long).
    final content = r'''
const string1 = 'it\'s escaped\\\n';
const string2 = 'hex \x12\x1299';
const string3 = 'unicode \u1234\u123499\u{123456}\u{12345699}';
''';

    final expected = [
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string1', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'it", SemanticTokenTypes.string),
      _Token(r"\'", SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      _Token('s escaped', SemanticTokenTypes.string),
      _Token(r'\\', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      _Token(r'\n', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      _Token(r"'", SemanticTokenTypes.string),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string2', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'hex ", SemanticTokenTypes.string),
      _Token(r'\x12', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      _Token(r'\x12', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      // The 99 is not part of the escape
      _Token("99'", SemanticTokenTypes.string),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('string3', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token("'unicode ", SemanticTokenTypes.string),
      _Token(r'\u1234', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      _Token(r'\u1234', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      // The 99 is not part of the escape
      _Token('99', SemanticTokenTypes.string),
      _Token(r'\u{123456}', SemanticTokenTypes.string,
          [CustomSemanticTokenModifiers.escape]),
      // The 99 makes this invalid so i's not an escape
      _Token(r"\u{12345699}'", SemanticTokenTypes.string),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_topLevel() async {
    final content = '''
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

    final expected = [
      _Token('/// strings docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('const', SemanticTokenTypes.keyword),
      _Token('strings', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('"test"', SemanticTokenTypes.string),
      _Token("'test'", SemanticTokenTypes.string),
      _Token("r'test'", SemanticTokenTypes.string),
      _Token("'''test'''", SemanticTokenTypes.string),
      _Token('/// func docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('func', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('String', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.parameter,
          [SemanticTokenModifiers.declaration]),
      _Token('print', SemanticTokenTypes.function),
      _Token('a', SemanticTokenTypes.parameter),
      _Token('/// abc docs', SemanticTokenTypes.comment,
          [SemanticTokenModifiers.documentation]),
      _Token('bool', SemanticTokenTypes.class_),
      _Token('get', SemanticTokenTypes.keyword),
      _Token('abc', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('true', CustomSemanticTokenTypes.boolean),
      _Token('final', SemanticTokenTypes.keyword),
      _Token('funcTearOff', SemanticTokenTypes.property,
          [SemanticTokenModifiers.declaration]),
      _Token('func', SemanticTokenTypes.function),
      _Token('void', SemanticTokenTypes.keyword,
          [CustomSemanticTokenModifiers.void_]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('strings', SemanticTokenTypes.property),
      _Token('func', SemanticTokenTypes.function),
      _Token('abc', SemanticTokenTypes.property),
      _Token('funcTearOff', SemanticTokenTypes.property),
    ];

    await _verifyTokens(content, expected);
  }

  Future<void> test_unresolvedOrInvalid() async {
    // Unresolved/invalid names should be marked as "source", which is used to
    // mark up code the server thinks should be uncolored (without this, a
    // clients other grammars would show through, losing the benefit from having
    // resolved the code).
    final content = '''
void f() {
  int a;
  a.foo().bar.baz();

  dynamic b;
  b.foo().bar.baz();
}
''';

    final expected = [
      _Token(
          'void', SemanticTokenTypes.keyword, [SemanticTokenModifiers('void')]),
      _Token('f', SemanticTokenTypes.function,
          [SemanticTokenModifiers.declaration, SemanticTokenModifiers.static]),
      _Token('int', SemanticTokenTypes.class_),
      _Token('a', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('a', SemanticTokenTypes.variable),
      _Token('foo', CustomSemanticTokenTypes.source),
      _Token('bar', CustomSemanticTokenTypes.source),
      _Token('baz', CustomSemanticTokenTypes.source),
      _Token('dynamic', SemanticTokenTypes.type),
      _Token('b', SemanticTokenTypes.variable,
          [SemanticTokenModifiers.declaration]),
      _Token('b', SemanticTokenTypes.variable),
      _Token('foo', CustomSemanticTokenTypes.source),
      _Token('bar', CustomSemanticTokenTypes.source),
      _Token('baz', CustomSemanticTokenTypes.source),
    ];

    await _verifyTokens(content, expected);
  }

  /// Decode tokens according to the LSP spec and pair with relevant file contents.
  List<_Token> _decodeSemanticTokens(String content, SemanticTokens tokens) {
    final contentLines = content.split('\n').map((line) => '$line\n').toList();
    final results = <_Token>[];

    var lastLine = 0;
    var lastColumn = 0;
    for (var i = 0; i < tokens.data.length; i += 5) {
      final lineDelta = tokens.data[i];
      final columnDelta = tokens.data[i + 1];
      final length = tokens.data[i + 2];
      final tokenTypeIndex = tokens.data[i + 3];
      final modifierBitmask = tokens.data[i + 4];

      // Calculate the actual line/col from the deltas.
      final line = lastLine + lineDelta;
      final column = lineDelta == 0 ? lastColumn + columnDelta : columnDelta;

      final tokenContent =
          contentLines[line].substring(column, column + length);
      results.add(_Token(
        tokenContent,
        semanticTokenLegend.typeForIndex(tokenTypeIndex),
        semanticTokenLegend.modifiersForBitmask(modifierBitmask),
      ));

      lastLine = line;
      lastColumn = column;
    }

    return results;
  }

  Future<void> _verifyTokens(String content, List<_Token> expected) async {
    final code = TestCode.parse(content);
    await initialize();
    await openFile(mainFileUri, code.code);

    final tokens = await getSemanticTokens(mainFileUri);
    final decoded = _decodeSemanticTokens(content, tokens);
    expect(decoded, equals(expected));
  }

  Future<void> _verifyTokensInRange(
      String content, List<_Token> expected) async {
    final code = TestCode.parse(content);
    await initialize();
    await openFile(mainFileUri, code.code);

    final tokens = await getSemanticTokensRange(mainFileUri, code.range.range);
    final decoded = _decodeSemanticTokens(code.code, tokens);
    expect(decoded, equals(expected));
  }
}

class _Token {
  final String content;
  final SemanticTokenTypes type;
  final List<SemanticTokenModifiers> modifiers;

  _Token(this.content, this.type, [this.modifiers = const []]);

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
          (SemanticTokenModifiers a, SemanticTokenModifiers b) => a == b);

  /// Outputs a text representation of the token in the form of constructor
  /// args for easy copy/pasting into tests to update expectations.
  @override
  String toString() {
    final modifiersString = modifiers.isEmpty
        ? ''
        : ', [${modifiers.map((m) => 'SemanticTokenModifiers.$m').join(', ')}]';
    return "('$content', SemanticTokenTypes.$type$modifiersString)";
  }
}
