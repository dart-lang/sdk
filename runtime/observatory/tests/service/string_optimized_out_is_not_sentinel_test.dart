// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

@pragma("vm:entry-point") // Prevent obfuscation
var field;

void testeeMain() {
  field = "<optimized out>";
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library lib = isolate.rootLibrary;
    await lib.load();
    Field field = lib.variables.singleWhere((v) => v.name == "field");
    await field.load();
    Instance value = field.staticValue as Instance;
    print(value);
    expect(value.kind, equals(M.InstanceKind.string)); // Not sentinel
    expect(value.valueAsString, equals("<optimized out>"));
    expect(value.valueAsStringIsTruncated, isFalse);
  }
];

main(args) => runIsolateTests(args, tests, testeeBefore: testeeMain);
