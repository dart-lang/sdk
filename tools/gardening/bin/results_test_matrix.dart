// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:gardening/src/buildbucket.dart';
import 'package:gardening/src/luci.dart';
import 'package:gardening/src/luci_api.dart';
import 'package:gardening/src/results/result_models.dart' as models;
import 'package:gardening/src/results/test_result_service.dart';
import 'package:gardening/src/util.dart';

/// [TestMatrixCommand] handles when given command 'test-matrix'.
class TestMatrixCommand extends Command {
  String get usage => "Run the command by results.dart test-matrix <master>.";

  @override
  String get description => "Generates a test-matrix for configurations run "
      "for a master.";

  @override
  String get name => "test-matrix";

  TestMatrixCommand() {
    argParser.addFlag("json",
        help: "Set if tool should generate root test-matrix.json",
        negatable: false);
  }

  Future run() async {
    if (argResults.rest.length == 0) {
      print("Too few arguments given.");
      print(usage);
      return;
    }

    if (argResults.rest.length > 1) {
      print("Too many arguments given.");
      print(usage);
      return;
    }

    String client = argResults.rest.first;
    bool isBuildBucket = client == "luci.dart.try";
    var logger = createLogger();
    var cache = createCacheFunction(logger);

    Iterable<String> builders;
    if (isBuildBucket) {
      Iterable<Builder> luciBuilders = await fetchBuilders(client);
      if (luciBuilders != null) {
        builders = (await fetchBuilders(client)).map((builder) => builder.name);
      }
    } else {
      var api = new LuciApi();
      builders = await getAllBuilders(api, client, cache());
    }

    if (builders == null) {
      print("Could not find any builders for $client. "
          "Make sure the name is correct");
      return;
    }

    TestResultService service = new TestResultService(logger, cache);

    Iterable<BuilderWithSteps> buildersWithSteps =
        await Future.wait(builders.map((builder) async {
      Iterable<BuildStepTestResult> steps;
      if (isBuildBucket) {
        steps = await stepsFromBuildBucket(service, builder);
      }
      return new BuilderWithSteps(builder, steps);
    }));

    buildersWithSteps.forEach((buildWithStep) {
      print(buildWithStep.name);
      buildWithStep.steps.forEach((step) {
        print("\t${step.name}");
      });
    });
  }

  /// Gets the last build from [builder] and find all steps with [TestResult]
  /// for that build.
  Future<Iterable<BuildStepTestResult>> stepsFromBuildBucket(
      TestResultService service, String builder) async {
    Iterable<BuildBucketBuild> builds = await buildsFromBuilder(builder);
    if (builds == null || builds.length == 0) {
      return [];
    }
    String prefix = "buildbucket/cr-buildbucket.appspot.com/${builds.first.id}";
    return await service.fromPrefix("dart", prefix, true);
  }
}

/// Class to hold information about a builder and specific test steps that
/// generates result logs.
class BuilderWithSteps {
  final String name;
  final Iterable<BuildStepTestResult> steps;
  BuilderWithSteps(this.name, this.steps);
}
