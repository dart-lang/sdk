// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

void testFunction() {
  debugger();
}

Future validateLocation(Location location) async {
  if (location == null) return;
  if (location.tokenPos == -1) return;

  // Ensure the script is loaded.
  final Script script = await location.script.load();

  // Use the more low-level functions.
  script.getLine(script.tokenToLine(location.tokenPos));
  script.tokenToCol(location.tokenPos);

  // Use the helper functions.
  await location.getLine();
  await location.getColumn();
}

Future validateFieldLocation(Field field) async {
  // TODO(http://dartbug.com/32503): We should `field = await field.load()`
  // here, but it causes all kinds of strong-mode errors.
  await validateLocation(field.location);
}

Future validateFunctionLocation(ServiceFunction fun) async {
  fun = await fun.load();
  await validateLocation(fun.location);
}

Future validateClassLocation(Class klass) async {
  klass = await klass.load();
  await validateLocation(klass.location);

  for (Field field in klass.fields) {
    await validateFieldLocation(field);
  }
  for (ServiceFunction fun in klass.functions) {
    await validateFunctionLocation(fun);
  }
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    // Loop over all libraries, classes, functions and fields to ensure .
    for (Library lib in isolate.libraries) {
      lib = await lib.load();

      for (Field field in lib.variables) {
        await validateFieldLocation(field);
      }
      for (ServiceFunction fun in lib.functions) {
        await validateFunctionLocation(fun);
      }
      for (Class klass in lib.classes) {
        await validateClassLocation(klass);
      }
    }
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
