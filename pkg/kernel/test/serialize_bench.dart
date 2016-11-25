// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'dart:io';

final String usage = '''
Usage: serialize_bench INPUT.dill OUTPUT.dill

Deserialize INPUT and write it back to OUTPUT several times, measuring
the time it takes, including I/O time.
''';

main(List<String> args) async {
  if (args.length != 2) {
    print(usage);
    exit(1);
  }
  Program program = loadProgramFromBinary(args[0]);

  String destination = args[1];
  var watch = new Stopwatch()..start();
  await writeProgramToBinary(program, destination);
  int coldTime = watch.elapsedMilliseconds;

  watch.reset();
  int numTrials = 10;
  for (int i = 0; i < numTrials; ++i) {
    await writeProgramToBinary(program, destination);
  }
  double hotTime = watch.elapsedMilliseconds / numTrials;

  print('Cold time: $coldTime ms');
  print('Hot time:  $hotTime ms');
}
