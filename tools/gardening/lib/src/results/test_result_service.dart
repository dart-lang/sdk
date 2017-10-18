// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'result_models.dart';
import '../logger.dart';
import '../cache_new.dart';
import '../logdog_new.dart';
import '../logdog_rpc.dart';
import '../luci_api.dart';
import '../luci.dart';
import '../buildbucket.dart';
import 'util.dart';
import '../util.dart';

/// [TestResultService] provides functions to obtain [TestResult]s from logs.
class TestResultService {
  final Logger logger;
  final CreateCacheFunction standardCache;

  TestResultService(this.logger, this.standardCache);

  /// Gets a test-result from a [path], which can either be a [url] to a build
  /// bot or a local path.
  Future<TestResult> getTestResult(String path,
      {CreateCacheFunction createCache}) {
    if (path.startsWith("http")) {
      return fromLogdog(path, createCache: createCache);
    } else {
      return getFromFile(new File(path));
    }
  }

  /// Gets the latest result from a builder with [name] in a [project].
  Future<TestResult> latestForBuilder(String project, String name,
      {CreateCacheFunction createCache}) async {
    int buildNumber = (await latestBuildNumbersForBuilders([name]))[name];
    if (buildNumber == 0) {
      print("Could not get any results for builder with name $name.");
      return new TestResult();
    }
    return forBuild(project, name, buildNumber, createCache: createCache);
  }

  /// Get a test result from logdog by massaging the [uri] passed in, if it is
  /// not in the correct format.
  Future<TestResult> fromLogdog(String uri, {CreateCacheFunction createCache}) {
    String logName;
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
    } else if (uri.contains("build.chromium.org")) {
      // If it is an (invalid) public buildbot url:
      // https://build.chromium.org/p/client.dart/builders/....log
      logger.debug("Assuming that $uri is an build.chromium.org url.");
      uri = Uri.decodeFull(uri);
      var reg = new RegExp(r"^https:\/\/build\.chromium\.org\/p\/(.*)\/"
          r"builders\/(.*)\/builds\/(\d*)(.*)\/logs\/result.log$");
      var match = reg.firstMatch(uri);
      if (match != null) {
        logName = "bb/${match.group(1)}/${match.group(2)}/"
            "${match.group(3)}/+/recipes${match.group(4).replaceAll(' ', '_')}"
            "/0/logs/result.log/0";
      }
    } else if (uri.contains("luci-logdog")) {
      // If it is an luci log-dog url:
      // https://luci-logdog.appspot.com/v/?s=chromium%2Fbb%2Fclient.dart%...log
      logger.debug("Assuming that $uri is a luci-logdog url.");
      logName = "${Uri.decodeFull(uri.substring(48))}";
    } else {
      logger.debug(
          "Assuming that $uri is a logdog url that can be used directly");
      // Assume it is a logdog url and use it directly.
      logName = uri;
    }

    if (logName == null) {
      throw new Exception("Could not identify URL $uri");
    }

    var logdog = new LogdogRpc();
    var cache = createCache ?? standardCache;
    return logdog
        .get(BUILDER_PROJECT, logName, cache(duration: new Duration(days: 365)))
        .then((json) => new TestResult.fromJson(JSON.decode(json)));
  }

  /// Gets result logs from logdog streams.
  Future<List<TestResult>> fromStreams(
      String project, List<LogdogStream> streams, WithCacheFunction cache) {
    var logdog = new LogdogRpc();
    return Future.wait(streams.map((stream) {
      logger.debug('Getting the log ${stream.path}...');
      return logdog.get(project, stream.path, cache).then((log) {
        return new TestResult.fromJson(JSON.decode(log));
      }).catchError(
          errorLogger(logger, "Could not get a log.", new TestResult()));
    }));
  }

  /// Get test results for a build [buildNumber] on a builder with [name] in a
  /// [project].
  Future<TestResult> forBuild(String project, String name, int buildNumber,
      {CreateCacheFunction createCache}) async {
    logger.info('Querying $name for logs in $buildNumber...');
    Iterable<BuildStepTestResult> steps = await fromPrefix(
        "chromium", "bb/client.dart/$name/$buildNumber", false,
        createCache: createCache);
    return steps.fold<TestResult>(new TestResult(), (acc, buildStep) {
      return acc..combineWith([buildStep.testResult]);
    });
  }

  /// Get latest test-result for a builder group with [name].
  /// TODO(mkroghj): Needs project to allow for FYI.
  Future<TestResult> forBuilderGroup(String name,
      {CreateCacheFunction createCache}) async {
    var cacheCreater = createCache ?? standardCache;
    var cache = cacheCreater(duration: new Duration(days: 1));

    LuciApi luciApi = new LuciApi();
    logger.info("Getting builders in builder-group $name.");
    List<String> builders =
        await getBuildersInBuilderGroup(luciApi, "client.dart", cache, name)
            .whenComplete(() => luciApi.close());
    var buildNumbers = await latestBuildNumbersForBuilders(builders);
    var testResults = await Future.wait(builders.map((builder) {
      int buildNumber = buildNumbers[builder];
      if (buildNumber == 0) {
        return new Future.value(new TestResult());
      }
      return forBuild(BUILDER_PROJECT, builder, buildNumber,
              createCache: createCache)
          .catchError(errorLogger(
              logger,
              "Could not get log for builder $builder "
              "with build number $buildNumber",
              new TestResult()));
    }));
    return new TestResult()..combineWith(testResults);
  }

  /// Gets [BuildBucketTestResult]s by querying logdog for information, coming
  /// from [builds].
  Future<Iterable<BuildBucketTestResult>> fromBuildBucketBuilds(
      Iterable<BuildBucketBuild> builds,
      {CreateCacheFunction createCache}) async {
    Iterable<Iterable<BuildStepTestResult>> testResults =
        await Future.wait(builds.map((build) {
      logger.debug('Querying ${build.builder} for logs...');
      String prefix = "buildbucket/cr-buildbucket.appspot.com/${build.id}";
      return fromPrefix("dart", prefix, true, createCache: createCache)
          .catchError(errorLogger(logger, null, []));
    }));

    return zipWith(builds, testResults,
        (BuildBucketBuild build, Iterable<BuildStepTestResult> steps) {
      TestResult result = steps.fold(new TestResult(), (acc, buildStep) {
        return acc..combineWith([buildStep.testResult]);
      });
      return new BuildBucketTestResult(build, result);
    });
  }

  /// Gets [BuildStepTestResult]s by querying logdog for information from
  /// a given [prefix].
  Future<Iterable<BuildStepTestResult>> fromPrefix(
      String project, String prefix, bool buildBucket,
      {CreateCacheFunction createCache}) async {
    var cacheCreater = createCache ?? standardCache;
    var cache = cacheCreater(duration: new Duration(minutes: 1));
    var longCache = cacheCreater(duration: new Duration(days: 365));
    LogdogRpc logdog = new LogdogRpc();
    String recipes = buildBucket ? "" : "recipes/";
    List<LogdogStream> streams = await logdog.query(
        project, "$prefix/+/${recipes}steps/**/result.log/0", cache);
    RegExp stepNameRegExp =
        new RegExp(r"^.*\/steps\/read_results_of_(.*)\/0\/logs\/.*");
    return await Future.wait(streams.map((stream) async {
      String name = stepNameRegExp.firstMatch(stream.path).group(1);
      List<TestResult> results =
          await fromStreams(project, [stream], longCache);
      return new BuildStepTestResult(name.replaceAll("_", " "), results[0]);
    }));
  }

  /// Gets [BuildBucketTestResult]s from a specific from [swarmTaskId].
  Future<Iterable<BuildBucketTestResult>> getFromSwarmingTaskId(
      String swarmTaskId,
      {CreateCacheFunction createCache}) {
    return buildsFromSwarmingTaskId(swarmTaskId).then(
        (builds) => fromBuildBucketBuilds(builds, createCache: createCache));
  }

  /// Gets [BuildBucketTestResult]s from a Gerrit CL with [changeNumber] and
  /// [patchset].
  Future<Iterable<BuildBucketTestResult>> fromGerrit(
      int changeNumber, int patchset,
      {CreateCacheFunction createCache}) {
    // First get builds from the buildbucket.
    return buildsFromGerrit(changeNumber, patchset).then(
        (builds) => fromBuildBucketBuilds(builds, createCache: createCache));
  }

  /// Reads the test result from a [file].
  Future<TestResult> getFromFile(File file) {
    return file
        .readAsString()
        .then(JSON.decode)
        .then((json) => new TestResult.fromJson(json));
  }
}

/// Class that keeps track of a try build and the corresponding test result.
class BuildBucketTestResult {
  final BuildBucketBuild build;
  final TestResult testResult;
  BuildBucketTestResult(this.build, this.testResult);
}

/// Class that keeps track of a test step and test result.
class BuildStepTestResult {
  final String name;
  final TestResult testResult;
  BuildStepTestResult(this.name, this.testResult);
}
