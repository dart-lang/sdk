// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_library_debuggable_test;

import 'dart:developer';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 19;
const LINE_B = 20;
const LINE_C = 21;

testMain() async {
  debugger();
  print('hi'); // LINE_A.
  print('yep'); // LINE_B.
  print('zoo'); // LINE_C.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  markDartColonLibrariesDebuggable,
  (Isolate isolate) async {
    await isolate.reload();
    Library dartCore = isolate.libraries
        .firstWhere((Library library) => library.uri == 'dart:core');
    await dartCore.reload();
    expect(dartCore.debuggable, equals(true));
  },
  stoppedInFunction('testMain', contains: true, includeOwner: true),
  stoppedAtLine(LINE_A),
  stepInto,
  stoppedInFunction('print'),
  stepOut,
  stoppedInFunction('testMain', contains: true, includeOwner: true),
  stoppedAtLine(LINE_B),
  (Isolate isolate) async {
    // Mark 'dart:core' as not debuggable.
    await isolate.reload();
    Library dartCore = isolate.libraries
        .firstWhere((Library library) => library.uri == 'dart:core');
    await dartCore.load();
    expect(dartCore.debuggable, equals(true));
    var setDebugParams = {
      'libraryId': dartCore.id,
      'isDebuggable': false,
    };
    Map<String, dynamic> result = await isolate.invokeRpcNoUpgrade(
        'setLibraryDebuggable', setDebugParams);
    expect(result['type'], equals('Success'));
    await dartCore.reload();
    expect(dartCore.debuggable, equals(false));
  },
  stoppedInFunction('testMain', contains: true, includeOwner: true),
  stoppedAtLine(LINE_B),
  stepInto,
  stoppedInFunction('testMain', contains: true, includeOwner: true),
  stoppedAtLine(LINE_C),
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: testMain);
