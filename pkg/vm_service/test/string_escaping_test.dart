// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

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
  for (int i = 0; i < 512; i++) longStringEven += '𝄞';
  longStringOdd = '.';
  for (int i = 0; i < 512; i++) longStringOdd += '𝄞';

  malformedWithLeadSurrogate = 'before' + '𝄞'[0] + 'after';
  malformedWithTrailSurrogate = 'before' + '𝄞'[1] + 'after';
}

Future<void> testStrings(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
    isolateId,
    isolate.rootLib!.id!,
  ) as Library;

  final variables = <Field>[
    for (final variable in rootLib.variables!)
      await service.getObject(
        isolateId,
        variable.id!,
      ) as Field,
  ];

  void expectFullString(String varName, String varValueAsString) {
    final field = variables.singleWhere((v) => v.name == varName);
    final value = field.staticValue as InstanceRef;
    expect(value.valueAsString, varValueAsString);
    expect(value.valueAsStringIsTruncated, isNull);
  }

  void expectTruncatedString(String varName, String varValueAsString) {
    final field = variables.singleWhere((v) => v.name == varName);
    final value = field.staticValue as InstanceRef;
    expect(varValueAsString, startsWith(value.valueAsString!));
    expect(value.valueAsStringIsTruncated, true);
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
  expectFullString('surrogatePairs', surrogatePairs);
  expectFullString('nullInTheMiddle', nullInTheMiddle);
  expectTruncatedString('longStringEven', longStringEven);
  expectTruncatedString('longStringOdd', longStringOdd);
  expectFullString('malformedWithLeadSurrogate', malformedWithLeadSurrogate);
  expectFullString('malformedWithTrailSurrogate', malformedWithTrailSurrogate);
}

final tests = <IsolateTest>[
  testStrings,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'string_escaping_test.dart',
      testeeBefore: script,
    );
