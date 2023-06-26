// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/service_io.dart';
import 'package:observatory_2/sample_profile.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

class Foo {
  Foo() {
    print('Foo');
  }
}

class Bar {
  Bar() {
    print('Bar');
  }
}

void test() {
  List l = <Object>[];
  debugger();
  // Toggled on for Foo.
  // Traced allocation.
  l.add(Foo());
  // Untraced allocation.
  l.add(Bar());
  // Toggled on for Bar.
  debugger();
  // Traced allocation.
  l.add(Bar());
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Initial.
  (Isolate isolate) async {
    // Verify initial state of 'Foo'.
    final fooClass = await getClassFromRootLib(isolate, 'Foo');
    expect(fooClass, isNotNull);
    expect(fooClass.name, equals('Foo'));
    print(fooClass.id);
    expect(fooClass.traceAllocations, isFalse);
    await fooClass.setTraceAllocations(true);
    await fooClass.reload();
    expect(fooClass.traceAllocations, true);
  },

  resumeIsolate,
  hasStoppedAtBreakpoint,

  // Allocation profile.
  (Isolate isolate) async {
    final fooClass = await getClassFromRootLib(isolate, 'Foo');
    await fooClass.reload();
    expect(fooClass.traceAllocations, true);

    final profileResponse = (await isolate.getAllocationTraces()) as ServiceMap;
    expect(profileResponse, isNotNull);
    expect(profileResponse['type'], 'CpuSamples');
    expect(profileResponse['samples'].length, 1);
    expect(profileResponse['samples'][0]['identityHashCode'], isNotNull);
    expect(profileResponse['samples'][0]['identityHashCode'] != 0, true);
    await fooClass.setTraceAllocations(false);
    await fooClass.reload();
    expect(fooClass.traceAllocations, isFalse);

    // Verify the allocation trace for the `Foo()` allocation.
    final cpuProfile = SampleProfile();
    await cpuProfile.load(isolate, profileResponse);
    cpuProfile.buildCodeCallerAndCallees();
    cpuProfile.buildFunctionCallerAndCallees();
    final tree = cpuProfile.loadCodeTree(M.ProfileTreeDirection.exclusive);
    var node = tree.root;
    final expected = [
      'Root',
      '[Unoptimized] test',
      '[Unoptimized] test',
      '[Unoptimized] _ServiceTesteeRunner.run',
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(node.profileCode.code.name, equals(expected[i]));
      // Depth first traversal.
      if (node.children.length == 0) {
        node = null;
      } else {
        node = node.children[0];
      }
      expect(node, isNotNull);
    }
  },
  (Isolate isolate) async {
    // Trace Bar.
    final barClass = await getClassFromRootLib(isolate, 'Bar');
    await barClass.reload();
    expect(barClass.traceAllocations, false);
    await barClass.setTraceAllocations(true);
    await barClass.reload();
    expect(barClass.traceAllocations, true);
  },

  resumeIsolate,
  hasStoppedAtBreakpoint,

  (Isolate isolate) async {
    // Ensure the allocation of `Bar()` was recorded.
    final profileResponse = (await isolate.getAllocationTraces()) as ServiceMap;
    expect(profileResponse['samples'].length, 2);
  },
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: test);
