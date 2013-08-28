// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library var_test;

import 'package:unittest/unittest.dart';
import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';
import 'testing.dart';

void simpleVar() {
  final errors = [];
  final input = ''':root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
}
''';

  final generated = ''':root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
}''';

  var stylesheet = compileCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void expressionsVar() {
  final errors = [];
  final input = ''':root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10Px;
  var-rgba: rgba(10,20,255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}

.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);

  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);

  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}

@font-face {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}

@font-face {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}

.foobar {
    grid-columns: var(grid-columns);
}
''';

  final generated = ''':root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10px;
  var-rgba: rgba(10, 20, 255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}
.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);
  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);
  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}
@font-face  {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}
@font-face  {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}
.foobar {
  grid-columns: var(grid-columns);
}''';

  var stylesheet = compileCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void defaultVar() {
  final errors = [];
  final input = '''
:root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
}

.test {
  background-color: var(test, orange);
}

body {
  background: var(a) var(image) no-repeat right top;
}

div {
  background: var(color-background) url('img_tree.png') no-repeat right top;
}

.test-2 {
  background: var(color-background) var(image-2, url('img_1.png'))
              no-repeat right top;
}

.test-3 {
  background: var(color-background) var(image-2) no-repeat right top;
}

.test-4 {
  background: #ffff00 var(image) no-repeat right top;
}

.test-5 {
  background: var(test-color, var(a)) var(image) no-repeat right top;
}

.test-6 {
  border: red var(a-1, solid 20px);
}
''';

  final generated = ''':root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
}
.test {
  background-color: var(test, #ffa500);
}
body {
  background: var(a) var(image) no-repeat right top;
}
div {
  background: var(color-background) url("img_tree.png") no-repeat right top;
}
.test-2 {
  background: var(color-background) var(image-2, url("img_1.png")) no-repeat right top;
}
.test-3 {
  background: var(color-background) var(image-2) no-repeat right top;
}
.test-4 {
  background: #ff0 var(image) no-repeat right top;
}
.test-5 {
  background: var(test-color, var(a)) var(image) no-repeat right top;
}
.test-6 {
  border: #f00 var(a-1, solid 20px);
}''';

  var stylesheet = compileCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void cyclesVar() {
  final errors = [];
  final input = ''':root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;

  var-one: var(two);
  var-two: var(one);

  var-four: var(five);
  var-five: var(six);
  var-six: var(four);

  var-def-1: var(def-2);
  var-def-2: var(def-3);
  var-def-3: var(def-2);
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
}
.test-2 {
  color: var(one);
}
''';

  final generated = ''':root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
}
.testIt {
  color: var(color-foreground);
  background: var(color-background);
}
.test-2 {
  color: var(one);
}''';

  var stylesheet = compileCss(input, errors: errors,
      opts: ['--no-colors', '--warnings_as_errors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.length, 8, reason: errors.toString());
  int testBitMap = 0;
  var errorStrings = [
      'error :14:3: var cycle detected var-six\n'
      '  var-six: var(four);\n'
      '  ^^^^^^^^^^^^^^^^^^',
      'error :18:3: var cycle detected var-def-3\n'
      '  var-def-3: var(def-2);\n'
      '  ^^^^^^^^^^^^^^^^^^^^^',
      'error :10:3: var cycle detected var-two\n'
      '  var-two: var(one);\n'
      '  ^^^^^^^^^^^^^^^^^',
      'error :17:3: var cycle detected var-def-2\n'
      '  var-def-2: var(def-3);\n'
      '  ^^^^^^^^^^^^^^^^^^^^^',
      'error :16:3: var cycle detected var-def-1\n'
      '  var-def-1: var(def-2);\n'
      '  ^^^^^^^^^^^^^^^^^^^^^',
      'error :13:3: var cycle detected var-five\n'
      '  var-five: var(six);\n'
      '  ^^^^^^^^^^^^^^^^^^',
      'error :9:3: var cycle detected var-one\n'
      '  var-one: var(two);\n'
      '  ^^^^^^^^^^^^^^^^^',
      'error :12:3: var cycle detected var-four\n'
      '  var-four: var(five);\n'
      '  ^^^^^^^^^^^^^^^^^^^'
  ];
  outer: for (var error in errors) {
    var errorString = error.toString();
    for (int i = 0; i < 8; i++) {
      if (errorString == errorStrings[i]) {
        testBitMap |= 1 << i;
        continue outer;
      }
    }
    fail("Unexpected error string: $errorString");
  }
  expect(testBitMap, equals((1 << 8) - 1));
  expect(prettyPrint(stylesheet), generated);
}

parserVar() {
  final errors = [];
  final input = ''':root {
  var-color-background: red;
  var-color-foreground: blue;

  var-a: var(b);
  var-b: var(c);
  var-c: #00ff00;

  var-image: url(test.png);

  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30EM;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10Px;
  var-rgba: rgba(10,20,255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}

.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);

  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);

  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}

@font-face {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}

@font-face {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}

.foobar {
    grid-columns: var(grid-columns);
}
''';

  final generated = ''':root {
  var-color-background: #f00;
  var-color-foreground: #00f;
  var-a: var(b);
  var-b: var(c);
  var-c: #0f0;
  var-image: url("test.png");
  var-b-width: 20cm;
  var-m-width: 33%;
  var-b-height: 30em;
  var-width: .6in;
  var-length: 1.2in;
  var-web-stuff: -10px;
  var-rgba: rgba(10, 20, 255);
  var-transition: color 0.4s;
  var-transform: rotate(20deg);
  var-content: "✔";
  var-text-shadow: 0 -1px 0 #bfbfbf;
  var-font-family: Gentium;
  var-src: url("http://example.com/fonts/Gentium.ttf");
  var-src-1: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  var-unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
  var-unicode-range-1: U+0A-FF, U+980-9FF, U+????, U+3???;
  var-grid-columns: 10px ("content" 1fr 10px) [4];
}
.testIt {
  color: var(color-foreground);
  background: var(c);
  background-image: var(image);
  border-width: var(b-width);
  margin-width: var(m-width);
  border-height: var(b-height);
  width: var(width);
  length: var(length);
  -web-stuff: var(web-stuff);
  background-color: var(rgba);
  transition: var(transition);
  transform: var(transform);
  content: var(content);
  text-shadow: var(text-shadow);
}
@font-face  {
  font-family: var(font-family);
  src: var(src);
  unicode-range: var(unicode-range);
}
@font-face  {
  font-family: var(font-family);
  src: var(src-1);
  unicode-range: var(unicode-range-1);
}
.foobar {
  grid-columns: var(grid-columns);
}''';

  var stylesheet = parseCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

testVar() {
  final errors = [];
  final input = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}
''';
  final generated = '''
var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  var stylesheet = parseCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  stylesheet = compileCss(input, errors: errors..clear(),
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  final input2 = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: @color-background;
  color: @color-foreground;
}
''';
  final generated2 = '''var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  stylesheet = parseCss(input, errors: errors..clear(),
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  stylesheet = compileCss(input2, errors: errors..clear(),
      opts: ['--no-colors', 'memory', '--no-less']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);
}

testLess() {
  final errors = [];
  final input = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}
''';
  final generated = '''var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  var stylesheet = parseCss(input, errors: errors,
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  stylesheet = compileCss(input, errors: errors..clear(),
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  final input2 = '''
@color-background: red;
@color-foreground: blue;

.test {
  background-color: @color-background;
  color: @color-foreground;
}
''';
  final generated2 = '''var-color-background: #f00;
var-color-foreground: #00f;

.test {
  background-color: var(color-background);
  color: var(color-foreground);
}''';

  stylesheet = parseCss(input, errors: errors..clear(),
      opts: ['--no-colors', 'memory']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  stylesheet = compileCss(input2, errors: errors..clear(),
      opts: ['--no-colors', 'memory', '--no-less']);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);
}

main() {
  test('Simple var', simpleVar);
  test('Expressions var', expressionsVar);
  test('Default value in var()', defaultVar);
  test('CSS Parser only var', parserVar);
  test('Var syntax', testVar);
  test('Cycles var', cyclesVar);
  test('Less syntax', testLess);
}
