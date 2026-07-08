// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
late String ascii;
@pragma('vm:entry-point') // Prevent obfuscation
late String latin1;
@pragma('vm:entry-point') // Prevent obfuscation
late String unicode;
@pragma('vm:entry-point') // Prevent obfuscation
late String hebrew;
@pragma('vm:entry-point') // Prevent obfuscation
late String singleQuotes;
@pragma('vm:entry-point') // Prevent obfuscation
late String doubleQuotes;
@pragma('vm:entry-point') // Prevent obfuscation
late String newLines;
@pragma('vm:entry-point') // Prevent obfuscation
late String tabs;
@pragma('vm:entry-point') // Prevent obfuscation
late String surrogatePairs;
@pragma('vm:entry-point') // Prevent obfuscation
late String nullInTheMiddle;
@pragma('vm:entry-point') // Prevent obfuscation
late String escapedUnicodeEscape;
@pragma('vm:entry-point') // Prevent obfuscation
late String longStringEven;
@pragma('vm:entry-point') // Prevent obfuscation
late String longStringOdd;
@pragma('vm:entry-point') // Prevent obfuscation
late String malformedWithLeadSurrogate;
@pragma('vm:entry-point') // Prevent obfuscation
late String malformedWithTrailSurrogate;

void script() {
  ascii = 'Hello, World!';
  latin1 = 'blåbærgrød';
  unicode = 'Îñţérñåţîöñåļîžåţîờñ';
  hebrew = 'שלום רב שובך צפורה נחמדת'; // Right-to-left text.
  singleQuotes = "'One,' he said.";
  doubleQuotes = '"Two," he said.';
  newLines = 'Windows\r\nSmalltalk\rUnix\n';
  tabs = 'One\tTwo\tThree';
  surrogatePairs = '1𝄞2𝄞𝄞3𝄞𝄞𝄞';
  nullInTheMiddle = 'There are four\u0000 words.';
  escapedUnicodeEscape = 'Should not be A: \\u0041';

  // A surrogate pair will cross the preferred truncation boundary.
  longStringEven = '..';
  for (int i = 0; i < 512; i++) {
    longStringEven += '𝄞';
  }
  longStringOdd = '.';
  for (int i = 0; i < 512; i++) {
    longStringOdd += '𝄞';
  }

  malformedWithLeadSurrogate = 'before${'𝄞'[0]}after';
  malformedWithTrailSurrogate = 'before${'𝄞'[1]}after';
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
