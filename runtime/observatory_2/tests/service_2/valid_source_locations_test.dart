// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'package:observatory_2/service_io.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

void testFunction() {
  debugger();
}

Future validateLocation(Location location, Object object) async {
  if (location == null) return;
  if (location.tokenPos < 0) return;
  if (location.script.uri == 'dart:_internal-patch/class_id_fasta.dart') {
    // Injected fields from this script cannot be reloaded.
    return;
  }

  // Ensure the script is loaded.
  final Script script = await location.script.load();

  // Use the more low-level functions.
  final line = script.tokenToLine(location.tokenPos);
  if (line == null) {
    throw 'missing location for $object in script ${script.uri}';
  }
  script.getLine(line);
  script.tokenToCol(location.tokenPos);

  // Use the helper functions.
  await location.getLine();
  await location.getColumn();
}

Future validateFieldLocation(Field field) async {
  field = await field.load();
  await validateLocation(field.location, field);
}

Future validateFunctionLocation(ServiceFunction fun) async {
  fun = await fun.load();
  await validateLocation(fun.location, fun);
}

Future validateClassLocation(Class klass) async {
  klass = await klass.load();
  await validateLocation(klass.location, klass);

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
    // Force everything to be compiled.
    final params = {
      'reports': ['Coverage'],
      'forceCompile': true
    };
    await isolate.invokeRpcNoUpgrade('getSourceReport', params);

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
