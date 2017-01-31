// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.dart2js_test;

import 'package:test_dart/test_configurations.dart' show
    testConfigurations;

import 'package:test_dart/test_options.dart' show
    TestOptionsParser;

import 'package:test_dart/test_suite.dart' show
    TestUtils;

const String arch = "-ax64";

const String mode = "-mrelease";

const String processes = "-j16";

const String dart2jsV8 = "-cdart2js -rd8";

const String common =
    // --dart2js-batch is ignored unless set in the first configuration.
    "--dart2js-batch --time -pcolor --report --failure-summary";

main(List<String> arguments) {
  if (arguments.join(" ") != "--run-tests") {
    // Protect against being run from test.dart.
    print("Usage: dart2js_test.dart --run-tests");
    return;
  }
  TestUtils.setDartDirUri(Uri.base);
  List<String> commandLines = <String>[
      "--checked dart2js",
      "$dart2jsV8 --exclude-suite=observatory_ui",
      "$dart2jsV8 dart2js_extra dart2js_native",
    ];
  List<Map> configurations = <Map>[];
  for (String commandLine in commandLines) {
    List<String> arguments = <String>[arch, mode, processes]
        ..addAll("$common $commandLine".split(" "));
    TestOptionsParser optionsParser = new TestOptionsParser();
    configurations.addAll(optionsParser.parse(arguments));
  }
  testConfigurations(configurations);
}
