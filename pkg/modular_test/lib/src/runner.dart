// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A generic runner that executes a pipeline on a folder containing modular
/// tests.
import 'dart:io';

import 'package:args/args.dart';
import 'package:async_helper/async_helper.dart';
import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/loader.dart';
import 'package:modular_test/src/suite.dart';

Future<void> runSuite(Uri suiteFolder, Options options, IOPipeline pipeline) {
  return asyncTest(() async {
    var dir = Directory.fromUri(suiteFolder);
    await for (var entry in dir.list(recursive: false)) {
      if (entry is Directory) {
        var dirName = entry.uri.path.substring(suiteFolder.path.length);
        try {
          if (options.filter != null && !dirName.contains(options.filter)) {
            if (options.verbose) print("skipped: $dirName");
            continue;
          }
          print("testing: $dirName");
          ModularTest test = await loadTest(entry.uri);
          if (options.verbose) print(test.debugString());
          await pipeline.run(test);
          print("pass: $dirName");
        } catch (e, st) {
          print("failed: $dirName - $e\n$st");
          exitCode = 1;
        }
      }
    }
    await pipeline.cleanup();
  });
}

class Options {
  bool showSkipped = false;
  bool verbose = false;
  String filter = null;

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addFlag('verbose',
          abbr: 'v',
          defaultsTo: false,
          help: "print detailed information about the test and modular steps")
      ..addFlag('show-skipped',
          defaultsTo: false,
          help: "print the name of the tests skipped by the filtering option")
      ..addOption('filter',
          help: "only run tests containing this filter as a substring");
    ArgResults argResults = parser.parse(args);
    return Options()
      ..showSkipped = argResults['show-skipped']
      ..verbose = argResults['verbose']
      ..filter = argResults['filter'];
  }
}
