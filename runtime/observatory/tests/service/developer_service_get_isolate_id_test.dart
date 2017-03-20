// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate' as Core;

import 'package:observatory/service_io.dart' as Service;
import 'package:unittest/unittest.dart';
import 'service_test_common.dart';
import 'test_helper.dart';


// testee state.
String selfId;
Core.Isolate childIsolate;
String childId;

void spawnEntry(int i) {
  dev.debugger();
}

Future testeeMain() async {
  dev.debugger();
  // Spawn an isolate.
  childIsolate = await Core.Isolate.spawn(spawnEntry, 0);
  // Assign the id for this isolate and it's child to strings so they can
  // be read by the tester.
  selfId = dev.Service.getIsolateID(Core.Isolate.current);
  childId = dev.Service.getIsolateID(childIsolate);
  dev.debugger();
}

// tester state:
Service.Isolate initialIsolate;
Service.Isolate localChildIsolate;

var tests = [
  (Service.VM vm) async {
    // Sanity check.
    expect(vm.isolates.length, 1);
    initialIsolate = vm.isolates[0];
    await hasStoppedAtBreakpoint(initialIsolate);
    // Resume.
    await initialIsolate.resume();
  },
  (Service.VM vm) async {
    // Initial isolate has paused at second debugger call.
    await hasStoppedAtBreakpoint(initialIsolate);
  },
  (Service.VM vm) async {
    // Reload the VM.
    await vm.reload();

    // Grab the child isolate.
    localChildIsolate =
        vm.isolates.firstWhere(
            (Service.Isolate i) => i != initialIsolate);
    expect(localChildIsolate, isNotNull);

    // Reload the initial isolate.
    await initialIsolate.reload();

    // Grab the root library.
    Service.Library rootLbirary = await initialIsolate.rootLibrary.load();

    // Grab self id.
    Service.Instance localSelfId =
        await initialIsolate.eval(rootLbirary, 'selfId');

    // Check that the id reported from dart:developer matches the id reported
    // from the service protocol.
    expect(localSelfId.isString, true);
    expect(initialIsolate.id, equals(localSelfId.valueAsString));

    // Grab the child isolate's id.
    Service.Instance localChildId =
        await initialIsolate.eval(rootLbirary, 'childId');

    // Check that the id reported from dart:developer matches the id reported
    // from the service protocol.
    expect(localChildId.isString, true);
    expect(localChildIsolate.id, equals(localChildId.valueAsString));
  }
];

main(args) async => runVMTests(args, tests,
    testeeConcurrent: testeeMain);
