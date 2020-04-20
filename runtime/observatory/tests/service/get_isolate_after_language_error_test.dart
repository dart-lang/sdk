// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

var x;

doThrow() {
  if (x) while {
  };
}

var tests = <IsolateTest>[
  hasStoppedAtExit,

  (Isolate isolate) async {
    await isolate.reload();
    expect(isolate.error, isNotNull);
    expect(isolate.error.message.contains("'(' expected"), isTrue);
  }
];

main(args) => runIsolateTestsSynchronous(args,
                                         tests,
                                         pause_on_exit: true,
                                         testeeConcurrent: doThrow);
