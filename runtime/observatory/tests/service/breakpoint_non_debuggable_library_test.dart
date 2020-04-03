// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory/service_io.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const String file = 'package:path/path.dart';
// At join() function
const int LINE_A = 259;
// At current getter function
const int LINE_B = 84;

testMain() {
  print(join('test', 'test'));
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    // Mark 'package:path/path.dart' as not debuggable.
    await isolate.reload();
    Library path =
        isolate.libraries.firstWhere((Library library) => library.uri == file);
    await path.load();
    expect(path.debuggable, true);

    // SetBreakpoint before setting library to non-debuggable.
    // Breakpoints are allowed to be set (before marking library as non-debuggable) but are not hit when running (after marking library as non-debuggable).
    Script script = path.scripts.single;
    Breakpoint bpt = await isolate.addBreakpoint(script, LINE_A);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
    expect(bpt is Breakpoint, isTrue);

    // Set breakpoint and check later that this breakpoint won't be added if library is non-debuggable.
    bpt = await isolate.addBreakpoint(script, LINE_B);
    print("Breakpoint is $bpt");
    expect(bpt, isNotNull);
    expect(bpt is Breakpoint, isTrue);
    await script.reload();
    // Remove breakpoint.
    var res = await isolate.removeBreakpoint(bpt);
    expect(res.type, 'Success');

    var setDebugParams = {
      'libraryId': path.id,
      'isDebuggable': false,
    };
    Map<String, dynamic> result = await isolate.invokeRpcNoUpgrade(
        'setLibraryDebuggable', setDebugParams);
    expect(result['type'], 'Success');
    await path.reload();
    expect(path.debuggable, false);
    print('$path is debuggable: ${path.debuggable}');

    // Breakpoints are not allowed to set on non-debuggable libraries.
    try {
      await isolate.addBreakpoint(script, LINE_B);
    } catch (e) {
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
