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

const strongConfigurations = {
  "analyzer": "analyzer-asserts-strong-linux",
  "cfe": "cfe-strong-linux",
  "dart2js": "dart2js-hostasserts-strong-linux-x64-d8",
  "ddc": "dartdevk-strong-linux-release-chrome",
  "vm": "dartk-strong-linux-release-x64",
};

const weakConfigurations = {
  "analyzer": "analyzer-asserts-weak-linux",
  "cfe": "cfe-weak-linux",
  "dart2js": "dart2js-weak-linux-x64-d8",
  "ddc": "dartdevk-weak-linux-release-chrome",
  "vm": "dartk-weak-asserts-linux-release-x64",
};

void main(List<String> arguments) async {
  var testDir = "";
  var isLegacy = false;
  var isStrong = true;
  var compiler = "ddc";

  var argParser = ArgParser();
  argParser.addFlag("legacy",
      help: "Run the legacy tests.",
      negatable: false,
      callback: (flag) => isLegacy = flag);

  argParser.addOption("configuration",
      abbr: "c",
      help: "Which Dart implementation to run the tests on.",
      allowed: ["analyzer", "cfe", "dart2js", "ddc", "vm"],
      callback: (option) => compiler = option as String);

  argParser.addFlag("weak", abbr: "w",
      help: "Run the tests in weak mode.",
      negatable: false, callback: (flag) => isStrong = !flag);

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

  // DDC doesn't have a Mac bot so when running DDC tests on a Mac, use a manual
  // configuration. Otherwise, use the right named configuration.
  List<String> testArgs;
  if (Platform.isLinux || compiler != "ddc") {
    var configurations = isStrong ? strongConfigurations : weakConfigurations;
    var configuration = configurations[compiler];
    if (!Platform.isLinux) {
      // TODO(rnystrom): We'll probably never need to run this script on
      // Windows, but if we do... do that.
      configuration = configuration.replaceAll("linux", "mac");
    }

    testArgs = ["-n$configuration", testDir];
  } else {
    testArgs = [
      "--mode=release",
      if (!isLegacy) ...[
        "--enable-experiment=non-nullable",
        "--nnbd=${isStrong ? 'strong' : 'weak'}",
      ],
      "--compiler=${compilerNames[compiler]}",
      testDir,
    ];
  }

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
