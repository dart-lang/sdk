// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:args/command_runner.dart';
import 'package:gardening/src/results/configurations.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/results/testpy_wrapper.dart';

void addStandardArguments(argParser) {
  argParser.addOption("arch", allowed: Architecture.names);
  argParser.addOption("builder-tag", defaultsTo: '');
  argParser.addFlag("checked", negatable: false);
  argParser.addOption("compiler", allowed: Compiler.names);
  argParser.addFlag("csp", negatable: false);
  argParser.addFlag("dart2js-with-kernel", negatable: false);
  argParser.addFlag("dart2js-with-kernel-in-ssa", negatable: false);
  argParser.addFlag("enable-asserts", negatable: false);
  argParser.addFlag("fast-startup", negatable: false);
  argParser.addFlag("host-checked", negatable: false);
  argParser.addFlag("hot-reload", negatable: false);
  argParser.addFlag("hot-reload-rollback", negatable: false);
  argParser.addFlag("minified", negatable: false);
  argParser.addOption("mode", allowed: Mode.names);
  argParser.addOption("runtime", allowed: Runtime.names);
  argParser.addFlag("strong", negatable: false);
  argParser.addOption("system", allowed: System.names);
  argParser.addFlag("use-sdk", negatable: false);
}

class ListCommand extends Command {
  @override
  String get description => "Lists information about test suites and "
      "status-files";

  @override
  String get name => "list";

  ListCommand() {
    addSubcommand(new ListTestsWithExpectationsForConfiguration());
    addSubcommand(new ListStatusFilesForConfiguration());
  }
}

class ListTestsWithExpectationsForConfiguration extends Command {
  @override
  String get description => "Get all tests with the expectation for a "
      "desired configuration. This directly calls test.py with arguments.";

  @override
  String get name => "tests";

  ListTestsWithExpectationsForConfiguration() {
    addStandardArguments(argParser);
  }

  Future run() async {
    var conf = new models.Configuration(
        argResults["mode"],
        argResults["arch"],
        argResults["compiler"],
        argResults["runtime"],
        argResults["checked"],
        argResults["strong"],
        argResults["host-checked"],
        argResults["minified"],
        argResults["csp"],
        argResults["system"],
        [],
        argResults["use-sdk"],
        argResults["builder-tag"],
        argResults["fast-startup"],
        0,
        argResults["dart2js-with-kernel"],
        argResults["dart2js-with-kernel-in-ssa"],
        argResults["enable-asserts"],
        argResults["hot-reload"],
        argResults["hot-reload-rollback"]);
    var result = await testLister(conf, argResults.rest);
    result.forEach(print);
  }
}

class ListStatusFilesForConfiguration extends Command {
  @override
  String get description => "Get all status files for the desired "
      "configuration. This directly calls test.py with arguments.";

  @override
  String get name => "status-files";

  ListStatusFilesForConfiguration() {
    addStandardArguments(argParser);
  }

  Future run() async {
    var conf = new models.Configuration(
        argResults["mode"],
        argResults["arch"],
        argResults["compiler"],
        argResults["runtime"],
        argResults["checked"],
        argResults["strong"],
        argResults["host-checked"],
        argResults["minified"],
        argResults["csp"],
        argResults["system"],
        [],
        argResults["use-sdk"],
        argResults["builder-tag"],
        argResults["fast-startup"],
        0,
        argResults["dart2js-with-kernel"],
        argResults["dart2js-with-kernel-in-ssa"],
        argResults["enable-asserts"],
        argResults["hot-reload"],
        argResults["hot-reload-rollback"]);
    var result = await statusFileLister(conf, argResults.rest);
    result.forEach(print);
  }
}
