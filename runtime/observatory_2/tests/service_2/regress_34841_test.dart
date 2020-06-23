// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// While it's not (currently) necessary, add some noise here to push down token
// positions in this file compared to the file regress_34841_lib.dart.
// This is to ensure that any possible tokens in that file are just comments
// (i.e. not actual) positions in this file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:developer';
import 'regress_34841_lib.dart';

class Bar extends Object with Foo {}

void testFunction() {
  Bar bar = new Bar();
  print(bar.foo);
  print(bar.baz());
  debugger();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    var stack = await isolate.getStack();

    // Make sure we are in the right place.
    expect(stack.type, equals('Stack'));
    expect(stack['frames'].length, greaterThanOrEqualTo(1));
    expect(stack['frames'][0].function.name, equals('testFunction'));

    var root = isolate.rootLibrary;
    await root.load();
    Script script = root.scripts.first;
    await script.load();

    var params = {
      'reports': ['Coverage'],
      'scriptId': script.id,
      'forceCompile': true
    };
    var report = await isolate.invokeRpcNoUpgrade('getSourceReport', params);
    List<dynamic> ranges = report['ranges'];
    List<int> coveragePlaces = <int>[];
    for (var range in ranges) {
      for (int i in range["coverage"]["hits"]) {
        coveragePlaces.add(i);
      }
      for (int i in range["coverage"]["misses"]) {
        coveragePlaces.add(i);
      }
    }

    // Make sure we can translate it all.
    for (int place in coveragePlaces) {
      int line = script.tokenToLine(place);
      int column = script.tokenToCol(place);
      if (line == null || column == null) {
        throw "Token $place translated to $line:$column";
      }
    }
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
