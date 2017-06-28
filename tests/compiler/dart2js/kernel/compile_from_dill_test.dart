// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compilation equivalence between source and .dill based
// compilation using the default emitter (full_emitter).
library dart2js.kernel.compile_from_dill_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import '../serialization/helper.dart';

import 'compile_from_dill_test_helper.dart';

main(List<String> args) {
  asyncTest(() async {
    await mainInternal(args);
  });
}

Future<ResultKind> mainInternal(List<String> args,
    {bool skipWarnings: false, bool skipErrors: false}) async {
  Arguments arguments = new Arguments.from(args);
  Uri entryPoint;
  Map<String, String> memorySourceFiles;
  if (arguments.uri != null) {
    entryPoint = arguments.uri;
    memorySourceFiles = const <String, String>{};
  } else {
    entryPoint = Uri.parse('memory:main.dart');
    memorySourceFiles = SOURCE;
  }

  return runTest(entryPoint, memorySourceFiles,
      verbose: arguments.verbose,
      skipWarnings: skipWarnings,
      skipErrors: skipErrors);
}
