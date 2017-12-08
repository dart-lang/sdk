// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import '../luci.dart';
import '../luci_api.dart';
import '../util.dart';
import 'result_json_models.dart';
import 'test_result_service.dart';

/// Utility method to get a single test-result no matter what has been passed in
/// as arguments. The test-result can either be from a builder-group, a single
/// build on a builder or from a log.
Future<TestResult> getTestResult(List<String> arguments) async {
  if (arguments.isEmpty) {
    print("No result.log file given as argument.");
    return null;
  }

  var logger = createLogger();
  var cache = createCacheFunction(logger);
  var testResultService = new TestResultService(logger, cache);

  String firstArgument = arguments.first;

  var luciApi = new LuciApi();
  bool isBuilderGroup = (await getBuilderGroups(luciApi, DART_CLIENT, cache()))
      .any((builder) => builder == firstArgument);
  bool isBuilder = (await getAllBuilders(luciApi, DART_CLIENT, cache()))
      .any((builder) => builder == firstArgument);

  if (arguments.length == 1) {
    if (arguments.first.startsWith("http")) {
      return testResultService.fromLogdog(firstArgument);
    } else if (isBuilderGroup) {
      return testResultService.forBuilderGroup(firstArgument);
    } else if (isBuilder) {
      return testResultService.latestForBuilder(BUILDER_PROJECT, firstArgument);
    }
  }

  var file = new File(arguments.first);
  if (await file.exists()) {
    return testResultService.getFromFile(file);
  }

  if (arguments.length == 2 && isBuilder && isNumber(arguments.last)) {
    var buildNumber = int.parse(arguments.last);
    return testResultService.forBuild(
        BUILDER_PROJECT, firstArgument, buildNumber);
  }

  print("Too many arguments passed to command or arguments were incorrect.");
  return null;
}

/// Utility method to get test results from the CQ.
Future<Iterable<BuildBucketTestResult>> getTestResultsFromCq(
    List<String> arguments) async {
  if (arguments.isEmpty) {
    print("No result.log file given as argument.");
    return null;
  }

  var logger = createLogger();
  var createCache = createCacheFunction(logger);
  var testResultService = new TestResultService(logger, createCache);

  String firstArgument = arguments.first;

  if (arguments.length == 1) {
    if (!isSwarmingTaskUrl(firstArgument)) {
      print("URI does not match "
          "`https://ci.chromium.org/swarming/task/<taskid>?server...`.");
      return null;
    }
    String swarmingTaskId = getSwarmingTaskId(firstArgument);
    return await testResultService.getFromSwarmingTaskId(swarmingTaskId);
  }

  if (arguments.length == 2 && areNumbers(arguments)) {
    int changeNumber = int.parse(firstArgument);
    int patchset = int.parse(arguments.last);
    return await testResultService.fromGerrit(changeNumber, patchset);
  }

  print("Too many arguments passed to command or arguments were incorrect.");
  return null;
}
