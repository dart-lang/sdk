// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Parses results.json and flaky.json.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:pool/pool.dart';

/// The path to the gsutil script.
String gsutilPy;

// TODO(karlklose):  Update this class with all fields that
// are used in pkg/test_runner and the tools/bots scripts and include
// validation (in particular for fields from extend_results.dart, that are
// optional but expected in some contexts and should always be all or nothing).
class Result {
  final String configuration;
  final String expectation;
  final bool matches;
  final String name;
  final String outcome;
  final bool changed;
  final String commitHash;
  final bool flaked; // From optional flakiness_data argument to constructor.
  final bool isFlaky; // From results.json after it is extended.
  final String previousOutcome;

  Result(
      this.configuration,
      this.name,
      this.outcome,
      this.expectation,
      this.matches,
      this.changed,
      this.commitHash,
      this.isFlaky,
      this.previousOutcome,
      [this.flaked = false]);

  Result.fromMap(Map<String, dynamic> map, [Map<String, dynamic> flakinessData])
      : configuration = map["configuration"] as String,
        name = map["name"] as String,
        outcome = map["result"] as String,
        expectation = map["expected"] as String,
        matches = map["matches"] as bool,
        changed = map["changed"] as bool,
        commitHash = map["commit_hash"] as String,
        isFlaky = map["flaky"] as bool,
        previousOutcome = map["previous_result"] as String,
        flaked = flakinessData != null &&
            (flakinessData["active"] ?? true) == true &&
            (flakinessData["outcomes"] as List).contains(map["result"]);

  String get key => "$configuration:$name";
}

/// Cloud storage location containing results.
const testResultsStoragePath = "gs://dart-test-results/builders";

/// Limit the number of concurrent subprocesses by half the number of cores.
final gsutilPool = Pool(math.max(1, Platform.numberOfProcessors ~/ 2));

/// Runs gsutil with the provided [arguments] and returns the standard output.
///
/// Returns null if the requested URL didn't exist.
Future<String> runGsutil(List<String> arguments) async {
  return gsutilPool.withResource(() async {
    var processResult = await Process.run(
        "python", [gsutilPy]..addAll(arguments),
        runInShell: Platform.isWindows);
    var stderr = processResult.stderr as String;
    if (processResult.exitCode != 0) {
      if (processResult.exitCode == 1 && stderr.contains("No URLs matched") ||
          stderr.contains("One or more URLs matched no objects")) {
        return null;
      }
      var error = "Failed to run: python $gsutilPy $arguments\n"
          "exitCode: ${processResult.exitCode}\n"
          "stdout:\n${processResult.stdout}\n"
          "stderr:\n${processResult.stderr}";
      if (processResult.exitCode == 1 &&
          stderr.contains("401 Anonymous caller")) {
        error =
            "\n\nYou need to authenticate by running:\npython $gsutilPy config\n";
      }
      throw Exception(error);
    }
    return processResult.stdout as String;
  });
}

/// Returns the contents of the provided cloud storage [path], or null if it
/// didn't exist.
Future<String> catGsutil(String path) => runGsutil(["cat", path]);

/// Returns the files and directories in the provided cloud storage [directory],
/// or null if it didn't exist.
Future<Iterable<String>> lsGsutil(String directory) async {
  var contents = await runGsutil(["ls", directory]);
  if (contents == null) {
    return null;
  }
  return LineSplitter.split(contents).map((String path) {
    var elements = path.split("/");
    if (elements[elements.length - 1].isEmpty) {
      return elements[elements.length - 2];
    } else {
      return elements[elements.length - 1];
    }
  });
}

/// Copies a file to or from cloud storage.
Future cpGsutil(String source, String destination) =>
    runGsutil(["cp", source, destination]);

/// Copies a directory recursively to or from cloud strorage.
Future cpRecursiveGsutil(String source, String destination) =>
    runGsutil(["-m", "cp", "-r", "-Z", source, destination]);

/// Lists the bots in cloud storage.
Future<Iterable<String>> listBots() => lsGsutil("$testResultsStoragePath");

/// Returns the cloud storage path for the [bot].
String botCloudPath(String bot) => "$testResultsStoragePath/$bot";

/// Returns the cloud storage path to the [build] on the [bot].
String buildCloudPath(String bot, String build) =>
    "${botCloudPath(bot)}/$build";

/// Returns the cloud storage path to the [file] inside the [bot]'s directory.
String fileCloudPath(String bot, String file) => "${botCloudPath(bot)}/$file";

/// Reads the contents of the [file] inside the [bot]'s cloud storage.
Future<String> readFile(String bot, String file) =>
    catGsutil(fileCloudPath(bot, file));

/// Returns the cloud storage path to the [file] inside the [build] on the
/// [bot].
String buildFileCloudPath(String bot, String build, String file) =>
    "${buildCloudPath(bot, build)}/$file";

/// Reads the contents of the [file] inside the [build] in the [bot]'s cloud
/// storage.
Future<String> readBuildFile(String bot, String build, String file) =>
    catGsutil(buildFileCloudPath(bot, build, file));

List<Map<String, dynamic>> parseResults(String contents) {
  return LineSplitter.split(contents)
      .map(jsonDecode)
      .toList()
      .cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> loadResults(String path) async {
  var results = <Map<String, dynamic>>[];
  var lines = File(path)
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (var line in lines) {
    results.add(jsonDecode(line) as Map<String, dynamic>);
  }
  return results;
}

Map<String, Map<String, dynamic>> createResultsMap(
    List<Map<String, dynamic>> results) {
  var result = <String, Map<String, dynamic>>{};
  for (var map in results) {
    var key = "${map["configuration"]}:${map["name"]}";
    result.putIfAbsent(key, () => map);
  }
  return result;
}

Map<String, Map<String, dynamic>> parseResultsMap(String contents) =>
    createResultsMap(parseResults(contents));

Future<Map<String, Map<String, dynamic>>> loadResultsMap(String path) async =>
    createResultsMap(await loadResults(path));
