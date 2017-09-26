// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'result_models.dart';
import '../try.dart';
import '../logger.dart';
import '../cache_new.dart';
import '../logdog_new.dart';
import '../logdog_rpc.dart';
import '../luci_api.dart';
import '../luci.dart';
import 'util.dart';

/// Gets a test-result from a [path], which can either be a [url] or a local
/// path.
Future<Try<TestResult>> getTestResult(
    String path, Logger logger, CreateCacheFunction createCache) {
  if (path.startsWith("http")) {
    return getTestResultFromLogdog(path, logger, createCache);
  } else {
    var file = new File(path);
    return getTestResultFromFile(file);
  }
}

/// Gets the latest result from a builder with [name] in a [project].
Future<Try<TestResult>> getLatestTestResultForBuilder(String project,
    String name, Logger logger, CreateCacheFunction createCache) async {
  // TODO(mkroghj): Needs implementation.
  return null;
}

/// Get test results for a build [buildNumber] on a builder with [name] in a
/// [project].
Future<Try<TestResult>> getTestResultForBuilder(String project, String name,
    int buildNumber, Logger logger, CreateCacheFunction createCache) async {
  var cache = createCache(duration: new Duration(days: 365));
  var logdog = new LogdogRpc();
  logger.info('Querying $name for logs in $buildNumber...');
  var result = await logdog.query(
      "chromium",
      "bb/client.dart/$name/$buildNumber/+"
      "/recipes/steps/**/result.log/0",
      cache);
  return (await result.bindAsync((streams) async {
    var testResults = <TestResult>[];
    for (var stream in streams) {
      logger.info('Getting the log ${stream.path}...');
      var logResult = await logdog.get(project, stream.path, cache);
      if (logResult.isError) {
        logger.warning("Could not fetch the log ${stream.path}. The error "
            "reported was: ${logResult.error}");
        continue;
      }
      testResults.add(new TestResult.fromJson(JSON.decode(logResult.value)));
    }
    return testResults;
  })).bind((testResults) {
    return combineTestResults(testResults);
  });
}

/// Get latest test-result for a builder group with [name].
/// TODO(mkroghj): Needs project to allow for FYI.
Future<Try<TestResult>> getLatestTestResultForBuilderGroup(
    String name, Logger logger, CreateCacheFunction createCache) async {
  var cache = createCache(duration: new Duration(days: 1));
  LuciApi luciApi = new LuciApi();
  logger.info("Getting builders in builder-group $name.");
  var tryBuilders =
      await getBuildersInBuilderGroup(luciApi, "client.dart", cache, "vm");
  logger.info("Getting latest build numbers for all builders. "
      "Query takes around 10-15 seconds.");
  // TODO(mkroghj): Get commit hash and use as a key to caching instead.
  var tryLatestBuildNumbers = await getLatestBuilderNumbers(
      createCache(duration: new Duration(hours: 1)));
  return await tryBuilders.bindAsync((builders) async {
    if (tryLatestBuildNumbers.isError) {
      logger.warning("Could not find build numbers by calling logdog.");
    }
    List<TestResult> testResults = [];
    await tryLatestBuildNumbers.bindAsync((buildNumberMap) async {
      await Future.forEach(builders, (builder) async {
        int buildNumber = buildNumberMap[builder];
        if (buildNumber != null) {
          var builderTestResults = await getTestResultForBuilder(
              BUILDER_PROJECT, builder, buildNumber, logger, createCache);
          builderTestResults.fold((err, st) {
            logger.warning("Could not find test result for $builder with "
                "$buildNumber. The error was:\n$err\n$st");
          }, (testResult) => testResults.add(testResult));
        }
      });
    });
    return combineTestResults(testResults);
  });
}

/// Reads the test result from a [file].
Future<Try<TestResult>> getTestResultFromFile(File file) async {
  return tryStartAsync(() async {
    var json = await file.readAsString();
    return new TestResult.fromJson(JSON.decode(json));
  });
}

/// Get a test result from logdog by massaging the [uri] passed in, if it is not
/// in the correct format.
/// TODO(mkroghj): This needs to be tested with a CQ url
Future<Try<TestResult>> getTestResultFromLogdog(
    String uri, Logger logger, CreateCacheFunction createCache) async {
  var logName = null;
  // If it is an (invalid) buildbot url:
  // https://uberchromegw.corp.google.com/i/client.dart/builders/.....log
  if (uri.contains("uberchrome")) {
    logger.debug("Assuming that $uri is an uberchrome url.");
    uri = Uri.decodeFull(uri);
    var reg = new RegExp(r"^https:\/\/uberchromegw\.corp\.google\.com\/i\/"
        r"(.*)\/builders\/(.*)\/builds\/(\d*)(.*)\/logs\/result.log$");
    var match = reg.firstMatch(uri);
    if (match != null) {
      logName = "bb/${match.group(1)}/${match.group(2)}/"
          "${match.group(3)}/+/recipes${match.group(4).replaceAll(' ', '_')}"
          "/0/logs/result.log/0";
    }
  } else if (uri.contains("luci-logdog")) {
    // If it is an luci log-dog url:
    // https://luci-logdog.appspot.com/v/?s=chromium%2Fbb%2Fclient.dart%....log
    logger.debug("Assuming that $uri is a luci-logdog url.");
    logName = "${Uri.decodeFull(uri.substring(48))}";
  } else {
    logger
        .debug("Assuming that $uri is a logdog url that can be used directly");
    // Assume it is a logdog url and use it directly.
    logName = uri;
  }

  if (logName == null) {
    return new Try.fail(new Exception("Could not identify URL $uri"), null);
  }

  var logdog = new LogdogRpc();
  var tryGet = await logdog.get(
      BUILDER_PROJECT, logName, createCache(duration: new Duration(days: 365)));
  return tryGet.bind((json) => new TestResult.fromJson(JSON.decode(json)));
}

/// Combines multiple test-results into a single test-result, potentially by
/// giving new names to later configurations.
TestResult combineTestResults(List<TestResult> results) {
  // We build a new Test Result iteratively by going through results.
  var returnResult = new TestResult();
  results.forEach((tr) {
    Map<String, String> translatedConfigurations = {};
    for (var confKey in tr.configurations.keys) {
      var newKey = findExistingConfiguration(
          tr.configurations[confKey], returnResult.configurations);
      newKey ??= "conf${returnResult.configurations.length + 1}";
      translatedConfigurations[confKey] = newKey;
      returnResult.configurations[newKey] = tr.configurations[confKey];
    }
    returnResult.results.addAll(tr.results.map((res) {
      res.configuration = translatedConfigurations[res.configuration];
      return res;
    }));
  });
  return returnResult;
}

/// Finds an existing configuration based on the arguments passed to test.py.
String findExistingConfiguration(Configuration configurationToFind,
    Map<String, Configuration> existingConfigurations) {
  String thisArgs = configurationToFind.toArgs().join();
  for (var confKey in existingConfigurations.keys) {
    String confArgs = existingConfigurations[confKey].toArgs().join();
    if (confArgs == thisArgs) {
      return confKey;
    }
  }
  return null;
}
