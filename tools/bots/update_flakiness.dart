#!/usr/bin/env dart
// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Update the flakiness data with a set of fresh results.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'package:test_runner/bot_results.dart';

void main(List<String> args) async {
  final parser = ArgParser();
  parser.addFlag('help', help: 'Show the program usage.', negatable: false);
  parser.addOption('input', abbr: 'i', help: 'Input flakiness file.');
  parser.addOption('output', abbr: 'o', help: 'Output flakiness file.');
  parser.addOption('build-id', help: 'Logdog ID of this buildbot run');
  parser.addOption('commit', help: 'Commit hash of this buildbot run');
  parser.addFlag('no-forgive', help: 'Don\'t remove any flaky records');

  final options = parser.parse(args);
  if (options['help']) {
    print('''
Usage: update_flakiness.dart [OPTION]... [RESULT-FILE]...
Update the flakiness data with a set of fresh results.

The options are as follows:

${parser.usage}''');
    return;
  }
  final parameters = options.rest;

  // Load the existing flakiness data, if any.
  final data = options['input'] != null
      ? await loadResultsMap(options['input'])
      : <String, Map<String, dynamic>>{};

  final resultsForInactiveFlakiness = {
    for (final flakyTest in data.keys)
      if (data[flakyTest]!['active'] == false) flakyTest: <String>{}
  };

  final now = DateTime.now();
  final nowString = now.toIso8601String();
  // Incrementally update the flakiness data with each observed result.
  for (final path in parameters) {
    final results = await loadResults(path);
    for (final resultObject in results) {
      final String configuration = resultObject['configuration'];
      final String name = resultObject['name'];
      final String result = resultObject['result'];
      final key = '$configuration:$name';
      resultsForInactiveFlakiness[key]?.add(result);
      final testData = data[key] ??= {};
      testData['configuration'] = configuration;
      testData['name'] = name;
      testData['expected'] = resultObject['expected'];
      final List<dynamic> outcomes = testData['outcomes'] ??= [];
      if (!outcomes.contains(result)) {
        outcomes
          ..add(result)
          ..sort();
        testData['last_new_result_seen'] = nowString;
      }
      if (testData['current'] == result) {
        testData['current_counter']++;
      } else {
        testData['current'] = result;
        testData['current_counter'] = 1;
      }
      Map<String, dynamic> mapField(String key) =>
          testData[key] ??= <String, dynamic>{};
      mapField('occurrences')[result] =
          (mapField('occurrences')[result] ?? 0) + 1;
      mapField('first_seen')[result] ??= nowString;
      mapField('last_seen')[result] = nowString;
      mapField('matches')[result] = resultObject['matches'];
      if (options['build-id'] != null) {
        mapField('build_ids')[result] = options['build-id'];
      }
      if (options['commit'] != null) {
        mapField('commits')[result] = options['commit'];
      }
    }
  }

  // Write out the new flakiness data.
  final flakinessHorizon = now.subtract(Duration(days: 7));
  final sink =
      options['output'] != null ? File(options['output']).openWrite() : stdout;
  final keys = data.keys.toList()..sort();
  for (final key in keys) {
    final testData = data[key]!;
    if (testData['outcomes'].length < 2) continue;
    // Reactivate inactive flaky results that are flaky again.
    if (testData['active'] == false) {
      if (resultsForInactiveFlakiness[key]!.length > 1) {
        testData['active'] = true;
        testData['reactivation_count'] =
            (testData['reactivation_count'] ?? 0) + 1;
      }
    } else if (options['no-forgive']) {
      testData['active'] = true;
    } else if (testData['current_counter'] >= 100) {
      // Forgive tests that have been stable for 100 builds.
      testData['active'] = false;
    } else {
      // Forgive tests that have been stable since flakiness horizon (one week).
      final resultTimes = [
        for (final timeString in testData['last_seen'].values)
          DateTime.parse(timeString)
      ]..sort();
      // The latest timestamp is the current result. The one before that is the
      // timestamp of the latest flake. Timestamps are sorted from earliest to latest.
      if (resultTimes[resultTimes.length - 2].isBefore(flakinessHorizon)) {
        testData['active'] = false;
      } else {
        testData['active'] = true;
      }
    }
    sink.writeln(jsonEncode(testData));
  }
}
