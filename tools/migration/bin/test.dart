// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A little utility script to make it easier to run NNBD and legacy tests.
import 'dart:io';

import 'package:args/args.dart';

import 'package:migration/src/io.dart';
import 'package:migration/src/test_directories.dart';

/// Maps "normal" names for Dart implementations to their test runner compiler
/// names.
const compilerNames = {
  "analyzer": "dart2analyzer",
  "cfe": "fasta",
  "dart2js": "dart2js",
  "ddc": "dartdevk",
  "vm": "dartk",
};

void main(List<String> arguments) async {
  var testDir = "";
  var isLegacy = false;
  var compilers = <String>[];

  var argParser = ArgParser();
  argParser.addFlag("legacy",
      help: "Run the legacy tests.",
      negatable: false,
      callback: (flag) => isLegacy = flag);

  argParser.addMultiOption("compiler",
      abbr: "c",
      help: "Which Dart implementations to run the tests on.",
      allowed: ["analyzer", "cfe", "dart2js", "ddc", "vm"],
      callback: (implementations) {
    compilers.addAll(implementations.map((name) => compilerNames[name]));
  });

  if (arguments.contains("--help")) {
    showUsage(argParser);
  }

  try {
    var argResults = argParser.parse(arguments);

    if (argResults.rest.length != 1) {
      showUsage(argParser, "Missing test directory.");
    }

    testDir = argResults.rest[0];

    // If the test directory is just a single identifier, assume it's a language
    // test subdirectory.
    if (!testDir.contains("/")) testDir = "language_2/$testDir";
  } on FormatException catch (exception) {
    showUsage(argParser, exception.message);
  }

  if (!isLegacy) testDir = toNnbdPath(testDir);

  var testArgs = [
    "--mode=release",
    if (!isLegacy) ...[
      "--enable-experiment=non-nullable",
      "--nnbd=strong",
    ],
    "--compiler=${compilers.join(',')}",
    testDir,
  ];

  print("Running tools/test.py ${testArgs.join(' ')}");
  await runProcessAsync("tools/test.py", testArgs);
}

void showUsage(ArgParser argParser, [String error]) {
  if (error != null) {
    print(error);
    print("");
  }
  print("Usage: dart test.dart <source dir>");
  print(argParser.usage);
  exit(error == null ? 0 : 1);
}
