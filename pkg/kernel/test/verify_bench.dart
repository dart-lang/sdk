// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:kernel/kernel.dart';
import 'package:kernel/verifier.dart';

final String usage = '''
Usage: verify_bench FILE.dill

Measures the time it takes to run kernel verifier on the given program.
''';

main(List<String> args) {
  if (args.length != 1) {
    print(usage);
    exit(1);
  }
  var program = loadProgramFromBinary(args[0]);
  var watch = new Stopwatch()..start();
  verifyProgram(program);
  print('Cold: ${watch.elapsedMilliseconds} ms');
  const int warmUpTrials = 20;
  for (int i = 0; i < warmUpTrials; ++i) {
    verifyProgram(program);
  }
  watch.reset();
  const int numberOfTrials = 100;
  for (int i = 0; i < numberOfTrials; ++i) {
    verifyProgram(program);
  }
  double millisecondsPerRun = watch.elapsedMilliseconds / numberOfTrials;
  print('Hot:  $millisecondsPerRun ms');
}
