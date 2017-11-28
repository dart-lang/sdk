// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.batch_util;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum CompilerOutcome {
  Ok,
  Fail,
}

typedef Future<CompilerOutcome> BatchCallback(List<String> arguments);

/// Runs the given [callback] in the batch mode for use by the test framework in
/// `dart-lang/sdk`.
///
/// The [callback] should behave as a main method, except it should return a
/// [CompilerOutcome] for reporting its outcome to the testing framework.
Future runBatch(BatchCallback callback) async {
  int totalTests = 0;
  int testsFailed = 0;
  var watch = new Stopwatch()..start();
  print('>>> BATCH START');
  Stream input = stdin.transform(UTF8.decoder).transform(new LineSplitter());
  await for (String line in input) {
    if (line.isEmpty) {
      int time = watch.elapsedMilliseconds;
      print('>>> BATCH END '
          '(${totalTests - testsFailed})/$totalTests ${time}ms');
      break;
    }
    ++totalTests;
    var arguments = line.split(new RegExp(r'\s+'));
    try {
      var outcome = await callback(arguments);
      stderr.writeln('>>> EOF STDERR');
      if (outcome == CompilerOutcome.Ok) {
        print('>>> TEST PASS ${watch.elapsedMilliseconds}ms');
      } else {
        print('>>> TEST FAIL ${watch.elapsedMilliseconds}ms');
      }
    } catch (e, stackTrace) {
      stderr.writeln(e);
      stderr.writeln(stackTrace);
      stderr.writeln('>>> EOF STDERR');
      print('>>> TEST CRASH');
    }
  }
}
