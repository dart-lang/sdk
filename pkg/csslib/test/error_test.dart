// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_test;

import 'package:unittest/unittest.dart';
import 'testing.dart';
import 'package:csslib/src/messages.dart';

/**
 * Test for unsupported font-weights values of bolder, lighter and inherit.
 */
void testUnsupportedFontWeights() {
  var errors = [];

  // TODO(terry): Need to support bolder.
  // font-weight value bolder.
  var input = ".foobar { font-weight: bolder; }";
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unknown property value bolder
.foobar { font-weight: bolder; }
                       ^^^^^^''');
  expect(stylesheet != null, true);

  expect(prettyPrint(stylesheet), r'''
.foobar {
  font-weight: bolder;
}''');

  // TODO(terry): Need to support lighter.
  // font-weight value lighter.
  input = ".foobar { font-weight: lighter; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unknown property value lighter
.foobar { font-weight: lighter; }
                       ^^^^^^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  font-weight: lighter;
}''');

  // TODO(terry): Need to support inherit.
  // font-weight value inherit.
  input = ".foobar { font-weight: inherit; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unknown property value inherit
.foobar { font-weight: inherit; }
                       ^^^^^^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  font-weight: inherit;
}''');
}

/**
 * Test for unsupported line-height values of units other than px, pt and
 * inherit.
 */
void testUnsupportedLineHeights() {
  var errors = [];

  // line-height value in percentge unit.
  var input = ".foobar { line-height: 120%; }";
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unexpected value for line-height
.foobar { line-height: 120%; }
                       ^^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  line-height: 120%;
}''');

  // TODO(terry): Need to support all units.
  // line-height value in cm unit.
  input = ".foobar { line-height: 20cm; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unexpected unit for line-height
.foobar { line-height: 20cm; }
                       ^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  line-height: 20cm;
}''');

  // TODO(terry): Need to support inherit.
  // line-height value inherit.
  input = ".foobar { line-height: inherit; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 24: Unknown property value inherit
.foobar { line-height: inherit; }
                       ^^^^^^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  line-height: inherit;
}''');
}

/** Test for bad selectors. */
void testBadSelectors() {
  var errors = [];

  // Invalid id selector.
  var input = "# foo { color: #ff00ff; }";
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 1: Not a valid ID selector expected #id
# foo { color: #ff00ff; }
^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
# foo {
  color: #f0f;
}''');

  // Invalid class selector.
  input = ". foo { color: #ff00ff; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 1: Not a valid class selector expected .className
. foo { color: #ff00ff; }
^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
. foo {
  color: #f0f;
}''');
}

/** Test for bad hex values. */
void testBadHexValues() {
  var errors = [];

  // Invalid hex value.
  var input = ".foobar { color: #AH787; }";
  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 18: Bad hex number
.foobar { color: #AH787; }
                 ^^^^^^''');
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  color: #AH787;
}''');

  // Bad color constant.
  input = ".foobar { color: redder; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 18: Unknown property value redder
.foobar { color: redder; }
                 ^^^^^^''');

  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  color: redder;
}''');

  // Bad hex color #<space>ffffff.
  input = ".foobar { color: # ffffff; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 18: Expected hex number
.foobar { color: # ffffff; }
                 ^''');

  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), r'''
.foobar {
  color: # ffffff;
}''');

  // Bad hex color #<space>123fff.
  input = ".foobar { color: # 123fff; }";
  stylesheet = parseCss(input, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(), r'''
error on line 1, column 18: Expected hex number
.foobar { color: # 123fff; }
                 ^''');

  expect(stylesheet != null, true);

  // Formating is off with an extra space.  However, the entire value is bad
  // and isn't processed anyway.
  expect(prettyPrint(stylesheet), r'''
.foobar {
  color: # 123 fff;
}''');

}

void testBadUnicode() {
  var errors = [];
  final String input = '''
@font-face {
  src: url(fonts/BBCBengali.ttf) format("opentype");
  unicode-range: U+400-200;
}''';

  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, false);
  expect(errors[0].toString(),
      'error on line 3, column 20: unicode first range can not be greater than '
        'last\n'
      '  unicode-range: U+400-200;\n'
      '                   ^^^^^^^');

  final String input2 = '''
@font-face {
  src: url(fonts/BBCBengali.ttf) format("opentype");
  unicode-range: U+12FFFF;
}''';

  stylesheet = parseCss(input2, errors: errors..clear());

  expect(errors.isEmpty, false);
  expect(errors[0].toString(),
      'error on line 3, column 20: unicode range must be less than 10FFFF\n'
      '  unicode-range: U+12FFFF;\n'
      '                   ^^^^^^');
}

void testBadNesting() {
  var errors = [];

  // Test for bad declaration in a nested rule.
  final String input = '''
div {
  width: 20px;
  span + ul { color: blue; }
  span + ul > #aaaa {
    color: #ffghghgh;
  }
  background-color: red;
}
''';

  var stylesheet = parseCss(input, errors: errors);
  expect(errors.length, 1);
  var errorMessage = messages.messages[0];
  expect(errorMessage.message, contains('Bad hex number'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 4);
  expect(errorMessage.span.start.column, 11);
  expect(errorMessage.span.text, '#ffghghgh');

  // Test for bad selector syntax.
  final String input2 = '''
div {
  span + ul #aaaa > (3333)  {
    color: #ffghghgh;
  }
}
''';
  var stylesheet2 = parseCss(input2, errors: errors..clear());
  expect(errors.length, 4);
  errorMessage = messages.messages[0];
  expect(errorMessage.message, contains(':, but found +'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 1);
  expect(errorMessage.span.start.column, 7);
  expect(errorMessage.span.text, '+');

  errorMessage = messages.messages[1];
  expect(errorMessage.message, contains('Unknown property value ul'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 1);
  expect(errorMessage.span.start.column, 9);
  expect(errorMessage.span.text, 'ul');

  errorMessage = messages.messages[2];
  expect(errorMessage.message, contains('expected }, but found >'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 1);
  expect(errorMessage.span.start.column, 18);
  expect(errorMessage.span.text, '>');

  errorMessage = messages.messages[3];
  expect(errorMessage.message, contains('premature end of file unknown CSS'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 1);
  expect(errorMessage.span.start.column, 20);
  expect(errorMessage.span.text, '(');

  // Test for missing close braces and bad declaration.
  final String input3 = '''
div {
  span {
    color: #green;
}
''';
  var stylesheet3 = parseCss(input3, errors: errors..clear());
  expect(errors.length, 2);
  errorMessage = messages.messages[0];
  expect(errorMessage.message, contains('Bad hex number'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 2);
  expect(errorMessage.span.start.column, 11);
  expect(errorMessage.span.text, '#green');

  errorMessage = messages.messages[1];
  expect(errorMessage.message, contains('expected }, but found end of file'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 3);
  expect(errorMessage.span.start.column, 1);
  expect(errorMessage.span.text, '\n');
}

main() {
  test('font-weight value errors', testUnsupportedFontWeights);
  test('line-height value errors', testUnsupportedLineHeights);
  test('bad selectors', testBadSelectors);
  test('bad Hex values', testBadHexValues);
  test('bad unicode ranges', testBadUnicode);
  test('nested rules', testBadNesting);
}
