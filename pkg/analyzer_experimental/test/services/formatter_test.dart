// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/services/formatter_impl.dart';
import 'package:analyzer_experimental/src/services/writer.dart';

main() {

  /// Formatter tests
  group('formatter', () {

    test('failed parse', () {
      var formatter = new CodeFormatter();
      expect(() => formatter.format(CodeKind.COMPILATION_UNIT, '~'),
                   throwsA(new isInstanceOf<FormatterException>()));
    });

    test('CU (1)', () {
      expectCUFormatsTo(
          'class A {\n'
          '  var z;\n'
          '  inc(int x) => ++x;\n'
          '}\n',
          'class A {\n'
          '  var z;\n'
          '  inc(int x) => ++x;\n'
          '}\n'
        );
    });

    test('CU (2)', () {
      expectCUFormatsTo(
          'class      A  {  \n'
          '}\n',
          'class A {\n'
          '}\n'
        );
    });

    test('CU (3)', () {
      expectCUFormatsTo(
          'class A {\n'
          '  }',
          'class A {\n'
          '}'
        );
    });

    test('CU (4)', () {
      expectCUFormatsTo(
          ' class A {\n'
          '}\n',
          'class A {\n'
          '}\n'
        );
    });

    test('CU (5)', () {
      expectCUFormatsTo(
          'class A  { int meaningOfLife() => 42; }',
          'class A {\n'
          '  int meaningOfLife() => 42;\n'
          '}'
      );
    });
    
    
//    test('CU - comments', () {
//      expectCUFormatsTo(
//          'library foo;\n'
//          '\n'
//          '//comment one\n\n'
//          '//comment two\n\n'
//          'class C {\n}\n',
//          'library foo;\n'
//          '\n'
//          '//comment one\n\n'
//          '//comment two\n\n'
//          'class C {\n}\n'
//      );
//    });
    
    test('CU - top level', () {
      expectCUFormatsTo(
          '\n\n'
          'foo() {\n'
          '}\n'
          'bar() {\n'
          '}\n',
          '\n\n'
          'foo() {\n'
          '}\n'
          'bar() {\n'
          '}\n'
      );
      expectCUFormatsTo(
          'const A = 42;\n'
          'final foo = 32;\n',
          'const A = 42;\n'
          'final foo = 32;\n'
      );
    });
    
    test('CU - imports', () {
      expectCUFormatsTo(
          'import "dart:io";\n\n'
          'import "package:unittest/unittest.dart";\n'
          'foo() {\n'
          '}\n',
          'import "dart:io";\n\n'
          'import "package:unittest/unittest.dart";\n'
          'foo() {\n'
          '}\n'
      );
    });
    
    test('CU - method invocations', () {
      expectCUFormatsTo(
          'class A {\n'
          '  foo() {\n'
          '    bar();\n'
          '    for (int i = 0; i < 42; i++) {\n'
          '      baz();\n'
          '    }\n'
          '  }\n'
          '}\n',
          'class A {\n'
          '  foo() {\n'
          '    bar();\n'
          '    for (int i = 0; i < 42; i++) {\n'
          '      baz();\n'
          '    }\n'
          '  }\n'
          '}\n'
        );
    });

    test('CU w/class decl comment', () {
      expectCUFormatsTo(
          'import "foo";\n\n'
          '//Killer class\n'
          'class A {\n'
          '}',
          'import "foo";\n\n'
          '//Killer class\n'
          'class A {\n'
          '}'
        );
    });

    test('CU (method body)', () {
      expectCUFormatsTo(
          'class A {\n'
          '  foo(path) {\n'
          '    var buffer = new StringBuffer();\n'
          '    var file = new File(path);\n'
          '    return file;\n'
          '  }\n'
          '}\n',
          'class A {\n'
          '  foo(path) {\n'
          '    var buffer = new StringBuffer();\n'
          '    var file = new File(path);\n'
          '    return file;\n'
          '  }\n'
          '}\n'
      );
      expectCUFormatsTo(
          'class A {\n'
          '  foo(files) {\n'
          '    for (var  file in files) {\n'
          '      print(file);\n'
          '    }\n'
          '  }\n'
          '}\n',
          'class A {\n'
          '  foo(files) {\n'
          '    for (var file in files) {\n'
          '      print(file);\n'
          '    }\n'
          '  }\n'
          '}\n'
      );
    });
    
    test('CU (method indent)', () {
      expectCUFormatsTo(
          'class A {\n'
          'void x(){\n'
          '}\n'
          '}\n',
          'class A {\n'
          '  void x() {\n'
          '  }\n'
          '}\n'
      );
    });

    test('CU (method indent - 2)', () {
      expectCUFormatsTo(
          'class A {\n'
          ' static  bool x(){\n'
          'return true; }\n'
          ' }\n',
          'class A {\n'
          '  static bool x() {\n'
          '    return true;\n'
          '  }\n'
          '}\n'
        );
    });

    test('CU (method indent - 3)', () {
      expectCUFormatsTo(
          'class A {\n'
          ' int x() =>   42   + 3 ;  \n'
          '   }\n',
          'class A {\n'
          '  int x() => 42 + 3;\n'
          '}\n'
        );
    });

    test('CU (method indent - 4)', () {
      expectCUFormatsTo(
          'class A {\n'
          ' int x() { \n'
          'if (true) {\n'
          'return 42;\n'
          '} else {\n'
          'return 13;\n }\n'
          '   }'
          '}\n',
          'class A {\n'
          '  int x() {\n'
          '    if (true) {\n'
          '      return 42;\n'
          '    } else {\n'
          '      return 13;\n'
          '    }\n'
          '  }\n'
          '}\n'
        );
    });

    test('CU (multiple members)', () {
      expectCUFormatsTo(
          'class A {\n'
          '}\n'
          'class B {\n'
          '}\n',
          'class A {\n'
          '}\n'
          'class B {\n'
          '}\n'
        );
    });

    test('CU (multiple members w/blanks)', () {
      expectCUFormatsTo(
          'class A {\n'
          '}\n\n'
          'class B {\n\n\n'
          '  int b() => 42;\n\n'
          '  int c() => b();\n\n'
          '}\n',
          'class A {\n'
          '}\n\n'
          'class B {\n\n\n'
          '  int b() => 42;\n\n'
          '  int c() => b();\n\n'
          '}\n'
      );
    });
    
    test('CU - constructor', () {
      expectCUFormatsTo(
          'class A {\n'
          '  const _a;\n'
          '  A();\n'
          '  int a() => _a;\n'
          '}\n',
          'class A {\n'
          '  const _a;\n'
          '  A();\n'
          '  int a() => _a;\n'
          '}\n'
        );
    });

    test('CU - method decl w/ named params', () {
      expectCUFormatsTo(
          'class A {\n'
          '  int a(var x, {optional: null}) => null;\n'
          '}\n',
          'class A {\n'
          '  int a(var x, {optional: null}) => null;\n'
          '}\n'
        );
    });
    
    test('CU - method decl w/ optional params', () {
      expectCUFormatsTo(
          'class A {\n'
          '  int a(var x, [optional = null]) => null;\n'
          '}\n',
          'class A {\n'
          '  int a(var x, [optional = null]) => null;\n'
          '}\n'
        );
    });
    
    test('CU - factory constructor redirects', () {
      expectCUFormatsTo(
          'class A {\n'
          '  const factory A() = B;\n'
          '}\n',
          'class A {\n'
          '  const factory A() = B;\n'
          '}\n'
        );
    });
    
    test('CU - constructor initializers', () {
      expectCUFormatsTo(
          'class A {\n'
          '  int _a;\n'
          '  A(a) : _a = a;\n'
          '}\n',
          'class A {\n'
          '  int _a;\n'
          '  A(a) : _a = a;\n'
          '}\n'
        );
    });
    
    test('stmt', () {
      expectStmtFormatsTo(
         'if (true){\n'
         'if (true){\n'
         'if (true){\n'
         'return true;\n'
         '} else{\n'
         'return false;\n'
         '}\n'
         '}\n'
         '}else{\n'
         'return false;\n'
         '}',
         'if (true) {\n'
         '  if (true) {\n'
         '    if (true) {\n'
         '      return true;\n'
         '    } else {\n'
         '      return false;\n'
         '    }\n'
         '  }\n'
         '} else {\n'
         '  return false;\n'
         '}'
      );
    });

    test('stmt (switch)', () {
      expectStmtFormatsTo(
        'switch (fruit) {\n'
        'case "apple":\n'
        'print("delish");\n'
        'break;\n'
        'case "fig":\n'
        'print("bleh");\n'
        'break;\n'
        '}',
        'switch (fruit) {\n'
        '  case "apple":\n'
        '    print("delish");\n'
        '    break;\n'
        '  case "fig":\n'
        '    print("bleh");\n'
        '    break;\n'
        '}'
      );
    });
  
    test('stmt (generics)', () {
      expectStmtFormatsTo(
        'var numbers = <int>[1, 2, (3 + 4)];',
        'var numbers = <int>[1, 2, (3 + 4)];'
      );
    });
    
    test('stmt (try/catch)', () {
      expectStmtFormatsTo(
        'try {\n'
        'doSomething();\n'
        '} catch (e) {\n'
        'print(e);\n'
        '}',
        'try {\n'
        '  doSomething();\n'
        '} catch (e) {\n'
        '  print(e);\n'
        '}'
      );
    });
    
    test('stmt (binary/ternary ops)', () {
      expectStmtFormatsTo(
        'var a = 1 + 2 / (3 * -b);',
        'var a = 1 + 2 / (3 * -b);'
      );
      expectStmtFormatsTo(
        'var c = !condition == a > b;',
        'var c = !condition == a > b;'
      );
      expectStmtFormatsTo(
        'var d = condition ? b : object.method(a, b, c);',
        'var d = condition ? b : object.method(a, b, c);'
      );
      expectStmtFormatsTo(
        'var d = obj is! SomeType;',
        'var d = obj is! SomeType;'
      );
    });
    
    test('initialIndent', () {
      var formatter = new CodeFormatter(
          new FormatterOptions(initialIndentationLevel: 2));
      var formattedSource = formatter.format(CodeKind.STATEMENT, 'var x;');
      expect(formattedSource, startsWith('    '));
    });

  });


  /// Line tests
  group('line', () {

    test('space', () {
      var line = new Line(indent: 0);
      line.addSpaces(2);
      expect(line.toString(), equals('  '));
    });

    test('initial indent', () {
      var line = new Line(indent: 2);
      expect(line.toString(), equals('    '));
    });

    test('initial indent (tabbed)', () {
      var line = new Line(indent:1, useTabs: true);
      expect(line.toString(), equals('\t'));
    });

    test('addToken', () {
      var line = new Line();
      line.addToken(new LineToken('foo'));
      expect(line.toString(), equals('foo'));
    });

    test('addToken (2)', () {
      var line = new Line(indent: 1);
      line.addToken(new LineToken('foo'));
      expect(line.toString(), equals('  foo'));
    });

    test('isWhitespace', () {
      var line = new Line(indent: 1);
      expect(line.isWhitespace(), isTrue);
    });

  });


  /// Writer tests
  group('writer', () {

    test('basic print', () {
      var writer = new SourceWriter();
      writer.print('foo');
      writer.print(' ');
      writer.print('bar');
      expect(writer.toString(), equals('foo bar'));
    });

    test('newline', () {
      var writer = new SourceWriter();
      writer.print('foo');
      writer.newline();
      expect(writer.toString(), equals('foo\n'));
    });

    test('newline trims whitespace', () {
      var writer = new SourceWriter(indentCount:2);
      writer.newline();
      expect(writer.toString(), equals('\n'));
    });

    test('basic print (with indents)', () {
      var writer = new SourceWriter();
      writer.print('foo');
      writer.indent();
      writer.newline();
      writer.print('bar');
      writer.unindent();
      writer.newline();
      writer.print('baz');
      expect(writer.toString(), equals('foo\n  bar\nbaz'));
    });

  });


  /// Helper method tests
  group('helpers', () {

    test('indentString', () {
      expect(getIndentString(0), '');
      expect(getIndentString(1), ' ');
      expect(getIndentString(4), '    ');
    });

    test('indentString (tabbed)', () {
      expect(getIndentString(0, useTabs: true), '');
      expect(getIndentString(1, useTabs: true), '\t');
      expect(getIndentString(3, useTabs: true), '\t\t\t');
    });

    test('repeat', () {
      expect(repeat('x', 0), '');
      expect(repeat('x', 1), 'x');
      expect(repeat('x', 4), 'xxxx');
    });

  });

}

Token classKeyword(int offset) =>
    new KeywordToken(Keyword.CLASS, offset);

Token identifier(String value, int offset) =>
    new StringToken(TokenType.IDENTIFIER, value, offset);

Token openParen(int offset) =>
    new StringToken(TokenType.OPEN_PAREN, '{', offset);

Token closeParen(int offset) =>
    new StringToken(TokenType.CLOSE_PAREN, '}', offset);

Token chain(List<Token> tokens) {
  for (var i = 0; i < tokens.length - 1; ++i) {
    tokens[i].setNext(tokens[i + 1]);
  }
  return tokens[0];
}

String formatCU(src, {options: const FormatterOptions()}) =>
    new CodeFormatter(options).format(CodeKind.COMPILATION_UNIT, src);

String formatStatement(src, {options: const FormatterOptions()}) =>
    new CodeFormatter(options).format(CodeKind.STATEMENT, src);

expectCUFormatsTo(src, expected) => expect(formatCU(src), equals(expected));

expectStmtFormatsTo(src, expected) => expect(formatStatement(src),
    equals(expected));
