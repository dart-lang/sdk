// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// If caching is working properly, the coverage data will go into the same
// Script object from which we requested coverage data, instead of a new
// Script object.

library caching_test;

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load();
    Script script = await lib.scripts.single.load();
    Script script2 = await isolate.getObject(script.id);
    expect(identical(script, script2), isTrue);
  },
];

main(args) => runIsolateTests(args, tests);
