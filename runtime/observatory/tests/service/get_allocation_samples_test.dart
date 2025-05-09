// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/sample_profile.dart';
import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

class Foo {
  Foo() {
    print('new Foo');
  }
}

void test() {
  final l = <Object>[];
  debugger();
  // Toggled on.
  // Allocation.
  l.add(new Foo());
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,

  // Initial.
  (Isolate isolate) async {
    // Verify initial state of 'Foo'.
    var fooClass = await getClassFromRootLib(isolate, 'Foo') as Class;
    expect(fooClass, isNotNull);
    expect(fooClass.name, equals('Foo'));
    print(fooClass.id);
    expect(fooClass.traceAllocations, isFalse);
    await fooClass.setTraceAllocations(true);
    await fooClass.reload();
    expect(fooClass.traceAllocations, isTrue);
  },

  resumeIsolate,
  hasStoppedAtBreakpoint,

  // Allocation profile.
  (Isolate isolate) async {
    var fooClass = await getClassFromRootLib(isolate, 'Foo') as Class;
    await fooClass.reload();
    expect(fooClass.traceAllocations, isTrue);
    dynamic profileResponse = await fooClass.getAllocationTraces();
    expect(profileResponse, isNotNull);
    //expect(profileResponse['type'], equals('_CpuProfile'));
    await fooClass.setTraceAllocations(false);
    await fooClass.reload();
    expect(fooClass.traceAllocations, isFalse);
    SampleProfile cpuProfile = new SampleProfile();
    await cpuProfile.load(isolate, profileResponse);
    cpuProfile.buildCodeCallerAndCallees();
    cpuProfile.buildFunctionCallerAndCallees();
    var tree = cpuProfile.loadCodeTree(M.ProfileTreeDirection.exclusive);
    CodeCallTreeNode? node = tree.root;
    var expected = [
      'Root',
      '[Unoptimized] test',
      '[Unoptimized] test',
      '[Unoptimized] _Closure.call',
      '[Unoptimized] _ServiceTesteeRunner.run',
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(node!.profileCode.code.name, equals(expected[i]));
      // Depth first traversal.
      if (node.children.length == 0) {
        node = null;
      } else {
        node = node.children[0];
      }
      expect(node, isNotNull);
    }
  },
  resumeIsolate,
];

main(args) async => runIsolateTests(args, tests, testeeConcurrent: test);
