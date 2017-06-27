// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compilation equivalence between source and .dill based
// compilation using the fast_startup emitter.
library dart2js.kernel.compile_from_dill_fast_startup_test;

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import '../serialization/helper.dart';

import 'compile_from_dill_test_helper.dart';

// TODO(johnniwinther): Maybe share this with 'compile_from_dill_test.dart'.
const SOURCE = const {
  'main.dart': '''
foo({named}) => 1;
bar(a) => !a;
class Class {
  var field;
  static var staticField;
  Class(this.field);
}
main() {
  foo();
  bar(true);
  [];
  {};
  new Object();
  new Class('');
  Class.staticField;
  var x = null;
  for (int i = 0; i < 10; i++) {
    x = i;
    if (i == 5) break;
  }
  return x;
}
'''
};

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
      skipErrors: skipErrors,
      options: [Flags.fastStartup]);
}
