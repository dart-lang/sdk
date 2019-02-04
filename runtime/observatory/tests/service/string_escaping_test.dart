// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_escaping_test;

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var ascii;
var latin1;
var unicode;
var hebrew;
var singleQuotes;
var doubleQuotes;
var newLines;
var tabs;
var suggrogatePairs;
var nullInTheMiddle;
var escapedUnicodeEscape;
var longStringEven;
var longStringOdd;
var malformedWithLeadSurrogate;
var malformedWithTrailSurrogate;

void script() {
  ascii = "Hello, World!";
  latin1 = "blåbærgrød";
  unicode = "Îñţérñåţîöñåļîžåţîờñ";
  hebrew = "שלום רב שובך צפורה נחמדת"; // Right-to-left text.
  singleQuotes = "'One,' he said.";
  doubleQuotes = '"Two," he said.';
  newLines = "Windows\r\nSmalltalk\rUnix\n";
  tabs = "One\tTwo\tThree";
  suggrogatePairs = "1𝄞2𝄞𝄞3𝄞𝄞𝄞";
  nullInTheMiddle = "There are four\u0000 words.";
  escapedUnicodeEscape = "Should not be A: \\u0041";

  // A surrogate pair will cross the preferred truncation boundry.
  longStringEven = "..";
  for (int i = 0; i < 512; i++) longStringEven += "𝄞";
  longStringOdd = ".";
  for (int i = 0; i < 512; i++) longStringOdd += "𝄞";

  malformedWithLeadSurrogate = "before" + "𝄞"[0] + "after";
  malformedWithTrailSurrogate = "before" + "𝄞"[1] + "after";
}

Future testStrings(Isolate isolate) async {
  Library lib = isolate.rootLibrary;
  await lib.load();
  for (var variable in lib.variables) {
    await variable.load();
  }

  expectFullString(String varName, String varValueAsString) {
    Field field = lib.variables.singleWhere((v) => v.name == varName);
    Instance value = field.staticValue;
    expect(value.valueAsString, equals(varValueAsString));
    expect(value.valueAsStringIsTruncated, isFalse);
  }

  expectTruncatedString(String varName, String varValueAsString) {
    Field field = lib.variables.singleWhere((v) => v.name == varName);
    Instance value = field.staticValue;
    print(value.valueAsString);
    expect(varValueAsString, startsWith(value.valueAsString));
    expect(value.valueAsStringIsTruncated, isTrue);
  }

  script(); // Need to initialize variables in the testing isolate.
  expectFullString('ascii', ascii);
  expectFullString('latin1', latin1);
  expectFullString('unicode', unicode);
  expectFullString('hebrew', hebrew);
  expectFullString('singleQuotes', singleQuotes);
  expectFullString('doubleQuotes', doubleQuotes);
  expectFullString('newLines', newLines);
  expectFullString('tabs', tabs);
  expectFullString('suggrogatePairs', suggrogatePairs);
  expectFullString('nullInTheMiddle', nullInTheMiddle);
  expectTruncatedString('longStringEven', longStringEven);
  expectTruncatedString('longStringOdd', longStringOdd);
  expectFullString('malformedWithLeadSurrogate', malformedWithLeadSurrogate);
  expectFullString('malformedWithTrailSurrogate', malformedWithTrailSurrogate);
}

var tests = <IsolateTest>[
  testStrings,
];

main(args) => runIsolateTests(args, tests, testeeBefore: script);
