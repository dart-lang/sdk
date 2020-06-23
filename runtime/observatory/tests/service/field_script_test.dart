// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_script_test;

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

part 'field_script_other.dart';

code() {
  print(otherField);
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  (Isolate isolate) async {
    Library lib = await isolate.rootLibrary.load() as Library;
    var fields = lib.variables;
    expect(fields.length, 2);
    print(lib.variables);
    for (Field f in fields) {
      await f.load();
      String locationString = await f.location!.toUserString();
      if (f.name == "tests") {
        expect(locationString, "field_script_test.dart:18:5");
      } else if (f.name == "otherField") {
        expect(locationString, "field_script_other.dart:7:5");
      } else {
        fail("Unexpected field: ${f.name}");
      }
    }
  }
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
