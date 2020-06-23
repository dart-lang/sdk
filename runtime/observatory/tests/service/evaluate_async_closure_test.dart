// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    // Silence analyzer on 'dart:async' import.
    expect(new Future.value(0) != null, isTrue);
    String test = "(){ "
        "  var k = () { return Future.value(3); }; "
        "  var w = () async { return await k(); }; "
        "  return w(); "
        "}()";
    Library lib = await isolate.rootLibrary.load() as Library;

    var result = await lib.evaluate(test);
    expect("$result", equals("Instance(a _Future)"));
  },
];

main(args) => runIsolateTests(args, tests);
