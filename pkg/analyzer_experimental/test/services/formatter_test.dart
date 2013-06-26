// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'package:analyzer_experimental/src/generated/ast.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';
import 'package:analyzer_experimental/src/services/formatter.dart';
import 'package:analyzer_experimental/src/services/formatter_impl.dart';

main() {

  /// Edit recorder tests
  group('edit recorder', () {

    test('countWhitespace', (){
      expect(newRecorder('   ').countWhitespace(), equals(3));
      expect(newRecorder('').countWhitespace(), equals(0));
      expect(newRecorder('  foo').countWhitespace(), equals(2));
    });

    test('isNewlineAt', (){
      expect(newRecorder('012\n').isNewlineAt(3), isTrue);
      expect(newRecorder('012\n3456').isNewlineAt(3), isTrue);
      expect(newRecorder('\n').isNewlineAt(0), isTrue);
    });

    test('space advances 1', (){
      var recorder = newRecorder(' foo');
      var startColumn = recorder.column;
      recorder.space();
      expect(recorder.column, equals(startColumn + 1));
    });

    test('space eats WS (1)', (){
      var recorder = newRecorder('  class')
          ..currentToken = new KeywordToken(Keyword.CLASS, 3)
          ..space()
          ..advanceToken('class');
      expect(doFormat(recorder), equals(' class'));
    });

    test('space eats WS (2)', (){
      var src = 'class  A';
      var recorder = newRecorder(src);
      recorder..currentToken = (classKeyword(0)..setNext(identifier('A', 7)))
              ..advanceToken('class')
              ..space()
              ..advanceToken('A');

      expect(doFormat(recorder), equals('class A'));
    });

    test('advance string token', (){
      var recorder = newRecorder('class A')..currentToken = classKeyword(0);
      expect(recorder.column, equals(0));
      recorder.advanceToken('class');
      expect(recorder.column, equals(5));
    });

    test('advance string token (failure)', (){
      var recorder = newRecorder('class A')..currentToken = classKeyword(0);
      expect(() => recorder.advanceToken('static'),
          throwsA(new isInstanceOf<FormatterException>()));
    });

    test('advance indent', (){
      var recorder = newRecorder(' class A')..currentToken = classKeyword(0);
      recorder.advanceIndent();
      expect(doFormat(recorder), equals('class A'));
    });

    test('indent string', (){
      var recorder = newRecorder('');
      expect(recorder.getIndentString(0).length, equals(0));
      expect(recorder.getIndentString(5).length, equals(5));
      expect(recorder.getIndentString(50).length, equals(50));
    });


    test('newline', (){
      var recorder = newRecorder('class A { }');
      recorder..currentToken = chain([classKeyword(0),
                                      identifier('A', 6),
                                      openParen(8),
                                      closeParen(10)])
              ..advanceToken('class')
              ..space()
              ..advanceToken('A')
              ..space()
              ..advanceToken('{')
              ..newline();

      expect(doFormat(recorder)[9], equals(NEW_LINE));
    });

    test('newline eats trailing WS', (){
      var src = 'class A {';
      var recorder = newRecorder(src + '    ');
      recorder..currentToken = chain([classKeyword(0),
                                      identifier('A', 6),
                                      openParen(8)])
              ..advanceToken('class')
              ..space()
              ..advanceToken('A')
              ..space()
              ..advanceToken('{')
              ..newline();

      expect(doFormat(recorder).length, equals((src + NEW_LINE).length));
    });


  });


  /// Edit operations
  group('edit operations', () {

    test('replace same length', () {
      var edits = [new Edit(1, 2, 'oo'),
                   new Edit(4, 5, 'bar')];
      expect(new EditOperation().apply(edits, 'fun house'), equals('foo bar'));
    });

    test('replace shorten', () {
      var edits = [new Edit(0, 2, 'a'),
                   new Edit(2, 2, 'b'),
                   new Edit(4, 2, 'c')];
      expect(new EditOperation().apply(edits, 'AaBbCc'), equals('abc'));
    });


  });


  /// Formatter tests
  group('formatter', () {

    test('failed parse', () {
      var formatter = new CodeFormatter();
      expect(() => formatter.format(CodeKind.COMPILATION_UNIT, '~'),
                   throwsA(new isInstanceOf<FormatterException>()));
    });

    test('CU (1)', () {
      expectCUFormatsTo(
          'class A  {\n'
          '}',
          'class A {\n'
          '}'
        );
    });

    test('CU (2)', () {
      expectCUFormatsTo(
          'class      A  {  \n'
          '}',
          'class A {\n'
          '}'
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
          '}',
          'class A {\n'
          '}'
        );
    });

    test('CU (method indent)', () {
      expectCUFormatsTo(
          'class A {\n'
          'void x(){\n'
          '}\n'
          '}',
          'class A {\n'
          '  void x() {\n'
          '  }\n'
          '}'
        );
    });

    test('CU (method indent - 2)', () {
      expectCUFormatsTo(
          'class A {\n'
          ' static  void x(){}\n'
          ' }',
          'class A {\n'
          '  static void x() {\n'
          '  }\n'
          '}'
        );
    });



//    test('initialIndent', () {
//      var formatter = new CodeFormatter(
//          new FormatterOptions(initialIndentationLevel:2));
//      var formattedSource = formatter.format(CodeKind.STATEMENT, 'var x;');
//      expect(formattedSource, startsWith('  '));
//    });

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

EditRecorder newRecorder(source) =>
    new EditRecorder(new FormatterOptions())..source = source;

String doFormat(recorder) =>
    new EditOperation().apply(recorder.editStore.edits, recorder.source);

String formatCU(src, {options: const FormatterOptions()}) =>
    new CodeFormatter(options).format(CodeKind.COMPILATION_UNIT, src);

expectCUFormatsTo(src, expected) => expect(formatCU(src), equals(expected));
