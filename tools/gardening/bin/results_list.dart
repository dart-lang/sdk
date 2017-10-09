// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:gardening/src/results/configurations.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/results/testpy_wrapper.dart';

/// Helper function to add all standard arguments to the [argParser].
void addStandardArguments(ArgParser argParser) {
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
  argParser.addFlag("preview-dart-2", negatable: false);
}

/// Helper function to get a configuration from [argResults].
models.Configuration getConfigurationFromArguments(ArgResults argResults) {
  return new models.Configuration(
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
      argResults["enable-asserts"],
      argResults["hot-reload"],
      argResults["hot-reload-rollback"],
      argResults["preview-dart-2"],
      argResults.rest);
}

/// [ListCommand] handles listing of information about test suites when given a
/// command 'list' and expect a sub-command.
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

/// [ListTestsWithExpectationsForConfiguration] calls test.py with the arguments
/// passed directly.
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
    var result = await testLister(getConfigurationFromArguments(argResults));
    result.forEach(print);
  }
}

/// [ListStatusFilesForConfiguration] handles the sub-command 'status-files' and
/// returns a list of status files that are found for the configuration passed.
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
    var result =
        await statusFileLister(getConfigurationFromArguments(argResults));
    result.forEach(print);
  }
}
