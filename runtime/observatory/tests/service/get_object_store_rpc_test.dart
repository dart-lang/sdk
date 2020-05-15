// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

void testeeMain() {}

bool isClosureFunctionsList(NamedField field) {
  return field.name == 'closure_functions_';
}

var tests = <IsolateTest>[
// Get object_store.
  (Isolate isolate) async {
    var object_store = await isolate.getObjectStore();
    expect(object_store.runtimeType, equals(ObjectStore));
    // Sanity check.
    expect(object_store.fields.length, greaterThanOrEqualTo(1));
    // Checking Closures.
    var single = object_store.fields.singleWhere(isClosureFunctionsList);
    expect(single, isNotNull);
    var value = single.value as Instance;
    expect(value.isList, isTrue);
  }
];

main(args) => runIsolateTestsSynchronous(args, tests, testeeBefore: testeeMain);
