// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library declaration_test;

import 'package:unittest/unittest.dart';
import 'testing.dart';


/** CSS compiler options no checks in in memory style sheet. */
List options = ['--no-colors', 'memory'];

void testSimpleTerms() {
  var errors = [];
  final String input = r'''
@ import url("test.css");
.foo {
  background-color: #191919;
  width: 10PX;
  height: 22mM !important;
  border-width: 20cm;
  margin-width: 33%;
  border-height: 30EM;
  width: .6in;
  length: 1.2in;
  -web-stuff: -10Px;
}''';
  final String generated = r'''
@import "test.css";
.foo {
  background-color: #191919;
  width: 10px;
  height: 22mm !important;
  border-width: 20cm;
  margin-width: 33%;
  border-height: 30em;
  width: .6in;
  length: 1.2in;
  -web-stuff: -10px;
}''';

  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  final String input2 = r'''
* {
  border-color: green;
}''';
  final String generated2 = r'''
* {
  border-color: #008000;
}''';

  stylesheet = parseCss(input2, errors: errors..clear());

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);
}

/**
 * Declarations with comments, references with single-quotes, double-quotes,
 * no quotes.  Hex values with # and letters, and functions (rgba, url, etc.)
 */
void testDeclarations() {
  var errors = [];
  final String input = r'''
.more {
  color: white;
  color: black;
  color: cyan;
  color: red;
  color: #aabbcc;  /* test -- 3 */
  color: blue;
  background-image: url(http://test.jpeg);
  background-image: url("http://double_quote.html");
  background-image: url('http://single_quote.html');
  color: rgba(10,20,255);  <!-- test CDO/CDC  -->
  color: #123aef;   /* hex # part integer and part identifier */
}''';
  final String generated = r'''
.more {
  color: #fff;
  color: #000;
  color: #0ff;
  color: #f00;
  color: #abc;
  color: #00f;
  background-image: url("http://test.jpeg");
  background-image: url("http://double_quote.html");
  background-image: url("http://single_quote.html");
  color: rgba(10, 20, 255);
  color: #123aef;
}''';

  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testIdentifiers() {
  var errors = [];
  final String input = r'''
#da {
  height: 100px;
}
#foo {
  width: 10px;
  color: #ff00cc;
}
''';
  final String generated = r'''
#da {
  height: 100px;
}
#foo {
  width: 10px;
  color: #f0c;
}''';

  var stylesheet = parseCss(input, errors: errors);

  expect(errors.isEmpty, true, reason: errors.toString());
  expect(stylesheet != null, true);
  expect(prettyPrint(stylesheet), generated);
}

void testComposites() {
  var errors = [];
  final String input = r'''
.xyzzy {
  border: 10px 80px 90px 100px;
  width: 99%;
}
@-webkit-keyframes pulsate {
  0% {
    -webkit-transform: translate3d(0, 0, 0) scale(1.0);
  }
}''';
  final String generated = r'''
.xyzzy {
  border: 10px 80px 90px 100px;
  width: 99%;
}
@-webkit-keyframes pulsate {
  0% {
  -webkit-transform: translate3d(0, 0, 0) scale(1.0);
  }
}''';

  var stylesheet = parseCss(input, errors: errors);
  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testUnits() {
  var errors = [];
  final String input = r'''
#id-1 {
  transition: color 0.4s;
  animation-duration: 500ms;
  top: 1em;
  left: 200ex;
  right: 300px;
  bottom: 400cm;
  border-width: 2.5mm;
  margin-top: .5in;
  margin-left: 5pc;
  margin-right: 5ex;
  margin-bottom: 5ch;
  font-size: 10pt;
  padding-top: 22rem;
  padding-left: 33vw;
  padding-right: 34vh;
  padding-bottom: 3vmin;
  transform: rotate(20deg);
  voice-pitch: 10hz;
}
#id-2 {
  left: 2fr;
  font-size: 10vmax;
  transform: rotatex(20rad);
  voice-pitch: 10khz;
  -web-kit-resolution: 2dpi;    /* Bogus property name testing dpi unit. */
}
#id-3 {
  -web-kit-resolution: 3dpcm;   /* Bogus property name testing dpi unit. */
  transform: rotatey(20grad);
}
#id-4 {
  -web-kit-resolution: 4dppx;   /* Bogus property name testing dpi unit. */
  transform: rotatez(20turn);
}
''';

  final String generated = r'''
#id-1 {
  transition: color 0.4s;
  animation-duration: 500ms;
  top: 1em;
  left: 200ex;
  right: 300px;
  bottom: 400cm;
  border-width: 2.5mm;
  margin-top: .5in;
  margin-left: 5pc;
  margin-right: 5ex;
  margin-bottom: 5ch;
  font-size: 10pt;
  padding-top: 22rem;
  padding-left: 33vw;
  padding-right: 34vh;
  padding-bottom: 3vmin;
  transform: rotate(20deg);
  voice-pitch: 10hz;
}
#id-2 {
  left: 2fr;
  font-size: 10vmax;
  transform: rotatex(20rad);
  voice-pitch: 10khz;
  -web-kit-resolution: 2dpi;
}
#id-3 {
  -web-kit-resolution: 3dpcm;
  transform: rotatey(20grad);
}
#id-4 {
  -web-kit-resolution: 4dppx;
  transform: rotatez(20turn);
}''';

  var stylesheet = parseCss(input, errors: errors, opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testUnicode() {
  var errors = [];
  final String input = r'''
.toggle:after {
  content: '✔';
  line-height: 43px;
  font-size: 20px;
  color: #d9d9d9;
  text-shadow: 0 -1px 0 #bfbfbf;
}
''';

  final String generated = r'''
.toggle:after {
  content: '✔';
  line-height: 43px;
  font-size: 20px;
  color: #d9d9d9;
  text-shadow: 0 -1px 0 #bfbfbf;
}''';

  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testNewerCss() {
  var errors = [];
  final String input = r'''
@media screen,print {
  .foobar_screen {
    width: 10px;
  }
}
@page {
  height: 22px;
  size: 3in 3in;
}
@page : left {
  width: 10px;
}
@page bar : left { @top-left { margin: 8px; } }
@charset "ISO-8859-1";
@charset 'ASCII';''';

  final String generated = r'''
@media screen, print {
.foobar_screen {
  width: 10px;
}
}
@page {
  height: 22px;
  size: 3in 3in;
}
@page:left {
  width: 10px;
}
@page bar:left {
@top-left {
  margin: 8px;
}
}
@charset "ISO-8859-1";
@charset "ASCII";''';

  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testMediaQueries() {
  var errors = [];
  String input = '''
@media screen and (-webkit-min-device-pixel-ratio:0) {
  .todo-item .toggle {
    background: none;
  }
  #todo-item .toggle {
    height: 40px;
  }
}''';
  String generated = '''
@media screen AND (-webkit-min-device-pixel-ratio:0) {
.todo-item .toggle {
  background: none;
}
#todo-item .toggle {
  height: 40px;
}
}''';

  var stylesheet = parseCss(input, errors: errors, opts: options);
  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  input = '''
  @media handheld and (min-width: 20em), 
         screen and (min-width: 20em) {
    #id { color: red; }
    .myclass { height: 20px; }
  }
  @media print and (min-resolution: 300dpi) {
    #anotherId {
      color: #fff;
    }
  }
  @media print and (min-resolution: 280dpcm) {
    #finalId {
      color: #aaa;
    }
    .class2 {
      border: 20px;
    }
  }''';
  generated =
    '''@media handheld AND (min-width:20em), screen AND (min-width:20em) {
#id {
  color: #f00;
}
.myclass {
  height: 20px;
}
} @media print AND (min-resolution:300dpi) {
#anotherId {
  color: #fff;
}
} @media print AND (min-resolution:280dpcm) {
#finalId {
  color: #aaa;
}
.class2 {
  border: 20px;
}
}''';

  stylesheet = parseCss(input, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  input = '''
@media only screen and (min-device-width: 4000px) and
    (min-device-height: 2000px), screen (another: 100px) {
      html {
        font-size: 10em;
      }
    }''';
  generated = '@media ONLY screen AND (min-device-width:4000px) '
      'AND (min-device-height:2000px), screen (another:100px) {\n'
      'html {\n  font-size: 10em;\n}\n}';

  stylesheet = parseCss(input, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  input = '''
@media screen,print (min-device-width: 4000px) and
    (min-device-height: 2000px), screen (another: 100px) {
      html {
        font-size: 10em;
      }
    }''';
  generated = '@media screen, print (min-device-width:4000px) AND '
      '(min-device-height:2000px), screen (another:100px) {\n'
      'html {\n  font-size: 10em;\n}\n}';

  stylesheet = parseCss(input, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  input = '''
@import "test.css" ONLY screen, NOT print (min-device-width: 4000px);''';
  generated =
      '@import "test.css" ONLY screen, NOT print (min-device-width:4000px);';

  stylesheet = parseCss(input, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testFontFace() {
  var errors = [];

  final String input = '''
@font-face {
  font-family: BBCBengali;
  src: url(fonts/BBCBengali.ttf) format("opentype");
  unicode-range: U+0A-FF, U+980-9FF, U+????, U+3???;
}''';
  final String generated = '''@font-face  {
  font-family: BBCBengali;
  src: url("fonts/BBCBengali.ttf") format("opentype");
  unicode-range: U+0A-FF, U+980-9FF, U+????, U+3???;
}''';
  var stylesheet = parseCss(input, errors: errors, opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  final String input1 = '''
@font-face {
  font-family: Gentium;
  src: url(http://example.com/fonts/Gentium.ttf);
  src: url(http://example.com/fonts/Gentium.ttf);
}''';
  final String generated1 = '''@font-face  {
  font-family: Gentium;
  src: url("http://example.com/fonts/Gentium.ttf");
  src: url("http://example.com/fonts/Gentium.ttf");
}''';

  stylesheet = parseCss(input1, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated1);

  final String input2 = '''
@font-face {
src: url(ideal-sans-serif.woff) format("woff"),
     url(basic-sans-serif.ttf) format("opentype"),
     local(Gentium Bold);
}''';
  final String generated2 =
      '@font-face  {\n'
      '  src: url("ideal-sans-serif.woff") '
      'format("woff"), url("basic-sans-serif.ttf") '
      'format("opentype"), local(Gentium Bold);\n}';

  stylesheet = parseCss(input2, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  final String input3 = '''@font-face {
  font-family: MyGentium Text Ornaments;
  src: local(Gentium Bold),   /* full font name */
       local(Gentium-Bold),   /* Postscript name */
       url(GentiumBold.ttf);  /* otherwise, download it */
  font-weight: bold;
}''';
  final String generated3 = '''@font-face  {
  font-family: MyGentium Text Ornaments;
  src: local(Gentium Bold), local(Gentium-Bold), url("GentiumBold.ttf");
  font-weight: bold;
}''';

  stylesheet = parseCss(input3, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated3);

  final String input4 = '''
@font-face {
  font-family: STIXGeneral;
  src: local(STIXGeneral), url(/stixfonts/STIXGeneral.otf);
  unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
}''';
  final String generated4 = '''@font-face  {
  font-family: STIXGeneral;
  src: local(STIXGeneral), url("/stixfonts/STIXGeneral.otf");
  unicode-range: U+000-49F, U+2000-27FF, U+2900-2BFF, U+1D400-1D7FF;
}''';
  stylesheet = parseCss(input4, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated4);
}

void testCssFile() {
  var errors = [];
  final String input = r'''
@import 'simple.css'
@import "test.css" print
@import url(test.css) screen, print
@import url(http://google.com/maps/maps.css);

div[href^='test'] {
  height: 10px;
}

@-webkit-keyframes pulsate {
  from {
    -webkit-transform: translate3d(0, 0, 0) scale(1.0);
  }
  10% {
    -webkit-transform: translate3d(0, 0, 0) scale(1.0);
  }
  30% {
    -webkit-transform: translate3d(0, 2, 0) scale(1.0);
  }
}

.foobar {
    grid-columns: 10px ("content" 1fr 10px)[4];
}

.test-background {
  background:  url(http://www.foo.com/bar.png);
}
''';

  final String generated =
      '@import "simple.css"; '
      '@import "test.css" print; '
      '@import "test.css" screen, print; '
      '@import "http://google.com/maps/maps.css";\n'
      'div[href^="test"] {\n'
      '  height: 10px;\n'
      '}\n'
      '@-webkit-keyframes pulsate {\n'
      '  from {\n'
      '  -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n'
      '  }\n'
      '  10% {\n'
      '  -webkit-transform: translate3d(0, 0, 0) scale(1.0);\n'
      '  }\n'
      '  30% {\n'
      '  -webkit-transform: translate3d(0, 2, 0) scale(1.0);\n'
      '  }\n'
      '}\n'
      '.foobar {\n'
      '  grid-columns: 10px ("content" 1fr 10px) [4];\n'
      '}\n'
      '.test-background {\n'
      '  background: url("http://www.foo.com/bar.png");\n'
      '}';
  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testCompactEmitter() {
  var errors = [];

  // Check !import compactly emitted.
  final String input = r'''
div {
  color: green !important;
}
''';
  final String generated = "div { color: green!important; }";

  var stylesheet = parseCss(input, errors: errors);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(compactOuptut(stylesheet), generated);

  // Check namespace directive compactly emitted.
  final String input2 = "@namespace a url(http://www.example.org/a);";
  final String generated2 = "@namespace a url(http://www.example.org/a);";

  var stylesheet2 = parseCss(input2, errors: errors..clear());

  expect(stylesheet2 != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(compactOuptut(stylesheet2), generated2);
}

void testNotSelectors() {
  var errors = [];

  final String input = r'''
.details:not(.open-details) x-element,
.details:not(.open-details) .summary {
  overflow: hidden;
}

.details:not(.open-details) x-icon {
  margin-left: 99px;
}

.kind-class .details:not(.open-details) x-icon {
  margin-left: 0px;
}

.name {
  margin-left: 0px;
}

.details:not(.open-details) .the-class {
  width: 80px;
}

*:focus
{
  outline: none;
}

body > h2:not(:first-of-type):not(:last-of-type) {
  color: red;
}

.details-1:not([DISABLED]) {
  outline: none;
}

html|*:not(:link):not(:visited) {
  width: 92%;
}

*|*:not(*) {
  font-weight: bold;
}

*:not(:not([disabled])) { color: blue; }
''';
  final String generated = r'''
.details:not(.open-details) x-element, .details:not(.open-details) .summary {
  overflow: hidden;
}
.details:not(.open-details) x-icon {
  margin-left: 99px;
}
.kind-class .details:not(.open-details) x-icon {
  margin-left: 0px;
}
.name {
  margin-left: 0px;
}
.details:not(.open-details) .the-class {
  width: 80px;
}
*:focus {
  outline: none;
}
body > h2:not(:first-of-type):not(:last-of-type) {
  color: #f00;
}
.details-1:not([DISABLED]) {
  outline: none;
}
html|*:not(:link):not(:visited) {
  width: 92%;
}
*|*:not(*) {
  font-weight: bold;
}
*:not(:not([disabled])) {
  color: #00f;
}''';

  var stylesheet = parseCss(input, errors: errors, opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testIE() {
  var errors = [];
  final String input =
".test {\n"
"  filter: progid:DXImageTransform.Microsoft.gradient"
"(GradientType=0,StartColorStr='#9d8b83', EndColorStr='#847670');\n"
"}";
  final String generated =
".test {\n"
"  filter: progid:DXImageTransform.Microsoft.gradient"
"(GradientType=0,StartColorStr='#9d8b83', EndColorStr='#847670');\n"
"}";

  var stylesheet = parseCss(input,  errors: errors, opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);

  final String input2 =
".test {\n"
"  filter: progid:DXImageTransform.Microsoft.gradient"
"(GradientType=0,StartColorStr='#9d8b83', EndColorStr='#847670')\n"
"        progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1);\n"
"}";

  final String generated2 =
".test {\n"
"  filter: progid:DXImageTransform.Microsoft.gradient"
"(GradientType=0,StartColorStr='#9d8b83', EndColorStr='#847670')\n"
"         progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1);\n"
"}";

  stylesheet = parseCss(input2, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated2);

  final String input3 = '''
div {
  filter: alpha(opacity=80);          /* IE7 and under */
  -ms-filter: "Alpha(Opacity=40)";    /* IE8 and newer */

  Filter: Blur(Add = 0, Direction = 225, Strength = 10);
  Filter: FlipV;
  Filter: Gray;
  FILTER: Chroma(Color = #000000) Mask(Color=#00FF00);
  Filter: Alpha(Opacity=100, FinishOpacity=0, Style=2, StartX=20, StartY=40, 
      FinishX=0, FinishY=0) Wave(Add=0, Freq=5, LightStrength=20, 
      Phase=220, Strength=10);
}
''';
  final String generated3 = 'div {\n  filter: alpha(opacity=80);\n'
      '  -ms-filter: "Alpha(Opacity=40)";\n'
      '  Filter: Blur(Add = 0, Direction = 225, Strength = 10);\n'
      '  Filter: FlipV;\n  Filter: Gray;\n'
      '  FILTER: Chroma(Color = #000000)  Mask(Color=#00FF00);\n'
      '  Filter: Alpha(Opacity=100, FinishOpacity=0, Style=2, '
      'StartX=20, StartY=40, \n'
      '      FinishX=0, FinishY=0)  Wave(Add=0, Freq=5, LightStrength=20, \n'
      '      Phase=220, Strength=10);\n}';

  stylesheet = parseCss(input3, errors: errors..clear(), opts: options);

  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated3);
}

/**
 *  Test IE specific declaration syntax:
 *    IE6 property name prefixed with _ (normal CSS property name can start
 *    with an underscore).
 *
 *    IE7 or below property add asterisk before the CSS property.
 *
 *    IE8 or below add \9 at end of declaration expression e.g.,
 *        background: red\9;
 */
void testIEDeclaration() {
  var errors = [];

  final input = '''
.testIE-6 {
  _zoom : 5;
}
.clearfix {
  *zoom: 1;
}
audio, video {
  display: inline-block;
  *display: inline;
  *zoom: 1;
}
input {
  *overflow: visible;
  line-height: normal;
}
.uneditable-input:focus {
  border-color: rgba(82, 168, 236, 0.8);
  outline: 0;
  outline: thin dotted \\9; /* IE6-9 */
}

input[type="radio"], input[type="checkbox"] {
  margin-top: 1px \\9;
  *margin-top: 0;
}

input.search-query {
  padding-right: 14px;
  padding-right: 4px \\9;
  padding-left: 14px;
  padding-left: 4px \\9; /* IE7-8 no border-radius, don't indent padding. */
}

.btn.active {
  background-color: #cccccc \\9;
}

@-webkit-keyframes progress-bar-stripes {
from {
background-position: 40px 0;
}
to {
background-position: 0 0;
}
}

@-moz-keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}

@-ms-keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}

@-o-keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}

@keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
}''';

  final generated = '''.testIE-6 {
  _zoom: 5;
}
.clearfix {
  *zoom: 1;
}
audio, video {
  display: inline-block;
  *display: inline;
  *zoom: 1;
}
input {
  *overflow: visible;
  line-height: normal;
}
.uneditable-input:focus {
  border-color: rgba(82, 168, 236, 0.8);
  outline: 0;
  outline: thin dotted \\9;
}
input[type="radio"], input[type="checkbox"] {
  margin-top: 1px \\9;
  *margin-top: 0;
}
input.search-query {
  padding-right: 14px;
  padding-right: 4px \\9;
  padding-left: 14px;
  padding-left: 4px \\9;
}
.btn.active {
  background-color: #ccc \\9;
}
@-webkit-keyframes progress-bar-stripes {
  from {
  background-position: 40px 0;
  }
  to {
  background-position: 0 0;
  }
}
@-moz-keyframes progress-bar-stripes {
  from {
  background-position: 40px 0;
  }
  to {
  background-position: 0 0;
  }
}
@keyframes progress-bar-stripes {
  from {
  background-position: 40px 0;
  }
  to {
  background-position: 0 0;
  }
}
@-o-keyframes progress-bar-stripes {
  from {
  background-position: 40px 0;
  }
  to {
  background-position: 0 0;
  }
}
@keyframes progress-bar-stripes {
  from {
  background-position: 40px 0;
  }
  to {
  background-position: 0 0;
  }
}''';

  var stylesheet = parseCss(input, errors: errors, opts: options);
  expect(stylesheet != null, true);
  expect(errors.isEmpty, true, reason: errors.toString());
  expect(prettyPrint(stylesheet), generated);
}

void testHangs() {
  final optionErrors = ['--no-colors', '--warnings_as_errors', 'memory'];
  var errors = [];

  // Bad hexvalue had caused a hang in processTerm.
  final input = r'''#a { color: #ebebeburl(0/IE8+9+); }''';
  var stylesheet = parseCss(input, errors: errors, opts: optionErrors);

  expect(stylesheet != null, true);
  expect(errors.length, 3, reason: errors.toString());

  var errorMessage = errors[0];
  expect(errorMessage.message, contains('Bad hex number'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 0);
  expect(errorMessage.span.start.column, 12);
  expect(errorMessage.span.text, '#ebebeburl');

  errorMessage = errors[1];
  expect(errorMessage.message, contains('expected }, but found +'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 0);
  expect(errorMessage.span.start.column, 30);
  expect(errorMessage.span.text, '+');

  errorMessage = errors[2];
  expect(errorMessage.message, contains('premature end of file unknown CSS'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 0);
  expect(errorMessage.span.start.column, 31);
  expect(errorMessage.span.text, ')');

  // Missing closing parenthesis for keyframes.
  final input2 = r'''@-ms-keyframes progress-bar-stripes {
  from {
    background-position: 40px 0;
  }
  to {
    background-position: 0 0;
  }
''';

  stylesheet = parseCss(input2, errors: errors..clear(), opts: optionErrors);

  expect(stylesheet != null, true);

  expect(errors.length, 1, reason: errors.toString());

  errorMessage = errors[0];
  expect(errorMessage.message, contains('unexpected end of file'));
  expect(errorMessage.span, isNotNull);
  expect(errorMessage.span.start.line, 7);
  expect(errorMessage.span.start.column, 0);
  expect(errorMessage.span.text.trim(), '');
}

main() {
  test('Simple Terms', testSimpleTerms);
  test('Declarations', testDeclarations);
  test('Identifiers', testIdentifiers);
  test('Composites', testComposites);
  test('Units', testUnits);
  test('Unicode', testUnicode);
  test('Newer CSS', testNewerCss);
  test('Media Queries', testMediaQueries);
  test('Font-Face', testFontFace);
  test('CSS file', testCssFile);
  test('Compact Emitter', testCompactEmitter);
  test('Selector Negation', testNotSelectors);
  test('IE stuff', testIE);
  test('IE declaration syntax', testIEDeclaration);
  test('Hanging bugs', testHangs);
}
