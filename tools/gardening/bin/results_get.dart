// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:gardening/src/results/result_service.dart';
import 'package:gardening/src/results/io_service.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/util.dart';
import 'package:gardening/src/try.dart';

class GetCommand extends Command {
  @override
  String get description => "Get results for files and test-suites.";

  @override
  String get name => "get";

  GetCommand() {
    argParser.addFlag('only-failed');
    addSubcommand(new GetTestsWithResultCommand());
    addSubcommand(new GetTestsWithResultAndExpectationCommand());
  }
}

class GetTestsWithResultCommand extends Command {
  @override
  String get description => "Get results for tests.";

  @override
  String get name => "tests";

  Future run() async {
    if (argResults.rest.length == 0) {
      print("No result.log file given as argument.");
      return;
    }

    var file = new File(argResults.rest[0]);
    var testResult = await getTestResultFromFile(file);
    testResult.fold(exceptionPrint("Could not perform command."), (value) {
      print("Test\tResult");
      value.results.forEach((res) {
        print("${res.name}\t${res.result}");
      });
    });
  }
}

class GetTestsWithResultAndExpectationCommand extends Command {
  @override
  String get description => "Get results and expectations for tests.";

  @override
  String get name => "results";

  Future run() async {
    if (argResults.rest.length == 0) {
      print("No result.log file given as argument.");
      return;
    }

    Try<models.TestResult> tryTestResult = null;
    if (argResults.rest[0].startsWith("http")) {
      tryTestResult = await getTestResultFromLogdog(argResults.rest[0]);
    } else {
      var file = new File(argResults.rest[0]);
      tryTestResult = await getTestResultFromFile(file);
    }

    (await tryTestResult.bindAsync(getTestResultsWithExpectation))
        .fold(exceptionPrint("Could not perform command."), (value) {
      print("Test\tResult\tExpected\tSucceded");
      value.forEach((res) {
        print("${res.name}\t${res.result}\t${res.expectation}\t${res.succes}");
      });
    });
  }
}
