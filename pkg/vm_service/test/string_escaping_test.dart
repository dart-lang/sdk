// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'string_escaping_lib.dart';
import 'string_escaping_lib.dart' as testee_lib;

Future<void> testStrings(VmService service, IsolateRef isolateRef) async {
  final isolateId = isolateRef.id!;
  final isolate = await service.getIsolate(isolateId);
  final rootLib = await service.getObject(
    isolateId,
    isolate.libraries!
        .firstWhere((l) => l.uri!.contains('string_escaping_lib'))
        .id!,
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

void main([args = const <String>[]]) =>
    IsolateTestHarness('string_escaping_lib.dart', args)
        .addCustomTest(testStrings)
        .run(testeeMain: testee_lib.main);
