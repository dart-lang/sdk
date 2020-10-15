// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:observatory_test_package/has_part.dart' as test_pkg;
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const String file = 'package:observatory_test_package/has_part.dart';
// print() within fooz()
const int LINE_A = 15;
// print() within barz()
const int LINE_B = 11;

testMain() {
  test_pkg.fooz();
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    // Mark 'package:observatory_test_package/has_part.dart' as not debuggable.
    await isolate.reload();
    Library has_part =
        isolate.libraries.firstWhere((Library library) => library.uri == file);
    await has_part.load();
    expect(has_part.debuggable, true);
    // SetBreakpoint before setting library to non-debuggable.
    // Breakpoints are allowed to be set (before marking library as
    // non-debuggable) but are not hit when running (after marking library
    // as non-debuggable).
    Script script =
        has_part.scripts.firstWhere((Script script) => script.uri == file);
    Breakpoint bpt = await isolate.addBreakpoint(script, LINE_A);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
    expect(bpt is Breakpoint, isTrue);

    // Set breakpoint and check later that this breakpoint won't be added if
    // the library is non-debuggable.
    bpt = await isolate.addBreakpoint(script, LINE_B);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
    expect(bpt is Breakpoint, isTrue);
    await script.reload();
    // Remove breakpoint.
    var res = await isolate.removeBreakpoint(bpt);
    expect(res.type, 'Success');

    var setDebugParams = {
      'libraryId': has_part.id,
      'isDebuggable': false,
    };
    Map<String, dynamic> result = await isolate.invokeRpcNoUpgrade(
        'setLibraryDebuggable', setDebugParams) as Map<String, dynamic>;
    expect(result['type'], 'Success');
    await has_part.reload();
    expect(has_part.debuggable, false);
    print('$has_part is debuggable: ${has_part.debuggable}');

    // Breakpoints are not allowed to set on non-debuggable libraries.
    try {
      await isolate.addBreakpoint(script, LINE_B);
    } on dynamic catch (e) {
      expect(e is ServerRpcException, true);
      expect(e.code == ServerRpcException.kCannotAddBreakpoint, true);
      print("Set Breakpoint to non-debuggable library is not allowed");
    }
  },
  resumeIsolate,
  hasStoppedAtExit,
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true, pause_on_exit: true);
