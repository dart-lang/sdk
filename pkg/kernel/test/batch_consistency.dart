// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.batch_consistency;

import 'dart:async';
import 'dart:io';
import '../bin/dartk.dart' as dartk;
import '../bin/batch_util.dart';
import 'package:path/path.dart' as pathlib;
import 'package:test/test.dart';

String usage = """
Usage: batch_consistency [options] -- files...

Run dartk on the given files, both separately and in a batch, and check that
the output is identical for the two modes.
""";

const String outputDir = 'out/batch-consistency';

main(List<String> args) async {
  int separator = args.indexOf('--');
  if (separator == -1) {
    print(usage);
    exit(1);
  }

  List<String> options = args.sublist(0, separator);
  List<String> files = args.sublist(separator + 1);

  await new Directory(outputDir).create(recursive: true);

  testBatchModeConsistency(options, files);
}

Future<bool> areFilesEqual(String first, String second) async {
  List<List<int>> bytes = await Future
      .wait([new File(first).readAsBytes(), new File(second).readAsBytes()]);
  if (bytes[0].length != bytes[1].length) return false;
  for (int i = 0; i < bytes[0].length; ++i) {
    if (bytes[0][i] != bytes[1][i]) return false;
  }
  return true;
}

testBatchModeConsistency(List<String> options, List<String> files) {
  var sharedState = new dartk.BatchModeState();
  for (String file in files) {
    test(file, () async {
      var name = pathlib.basename(file);
      List<String> outputFiles = <String>[
        '$outputDir/$name.batch.dill',
        '$outputDir/$name.unbatch.dill'
      ];
      List results = [null, null];
      bool failed = false;
      for (int i = 0; i < 2; ++i) {
        var args = <String>[]
          ..addAll(options)
          ..addAll(['--out', outputFiles[i], file]);
        var state = (i == 0) ? sharedState : new dartk.BatchModeState();
        try {
          // We run the two executions in a loop to ensure any stack traces
          // are identical in case they both crash at the same place.
          // Crashing at the same place is acceptable for the purpose of
          // this test, there are other tests that check for crashes.
          results[i] = await dartk.batchMain(args, state);
        } catch (e) {
          results[i] = '$e';
          failed = true;
        }
      }
      if (results[0] != results[1]) {
        fail('Batch mode returned ${results[0]}, expected ${results[1]}');
        return;
      }
      if (results[0] == CompilerOutcome.Fail) {
        failed = true;
      }
      if (!failed && !await areFilesEqual(outputFiles[0], outputFiles[1])) {
        fail('Batch mode output differs for $file');
      }
    });
  }
}
