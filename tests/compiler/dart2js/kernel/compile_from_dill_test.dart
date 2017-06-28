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

const SOURCE = const {
  'main.dart': '''
foo({named}) => 1;
bar(a) => !a;
class Class {
  var field;
  static var staticField;

  Class();
  Class.named(this.field);

  method() {}
}

class SubClass extends Class {
  method() {
    super.method();
  }  
}
main() {
  foo();
  bar(true);
  [];
  {};
  new Object();
  new Class.named('');
  new SubClass().method();
  Class.staticField;
  var x = null;
  var y1 = x == null;
  var y2 = null == x;
  var z1 = x?.toString();
  var z2 = x ?? y1;
  var z3 = x ??= y2;
  var w = x == null ? null : x.toString();
  for (int i = 0; i < 10; i++) {
    if (i == 5) continue;
    x = i;
    if (i == 5) break;
  }
  int i = 0;
  while (i < 10) {
    if (i == 5) continue;
    x = i;
    if (i == 5) break;
  }
  for (var v in [3, 5]) {
    if (v == 5) continue;
    x = v;
    if (v == 5) break;
  }
  print(x);
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
      skipErrors: skipErrors);
}
