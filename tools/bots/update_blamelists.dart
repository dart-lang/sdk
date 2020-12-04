// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This script is used by the bisection mechanism to update the blamelists
// of active, non-approved failures which include the commit of the current
// bisection build.

// @dart = 2.9

import 'dart:io';

import 'package:args/args.dart';

import 'lib/src/firestore.dart';
import 'package:test_runner/bot_results.dart';

const newTest = 'new test';
const skippedTest = 'skipped';

const maxAttempts = 20;

FirestoreDatabase database;

class ResultRecord {
  final data;

  ResultRecord(this.data);

  Map field(String name) => data['fields'][name] /*!*/;

  int get blamelistStartIndex {
    return int.parse(field('blamelist_start_index')['integerValue']);
  }

  void set blamelistStartIndex(int index) {
    field('blamelist_start_index')['integerValue'] = '$index';
  }

  int get blamelistEndIndex {
    return int.parse(field('blamelist_end_index')['integerValue']);
  }

  String get result => field('result')['stringValue'] /*!*/;

  String get previousResult => field('previous_result')['stringValue'] /*!*/;

  String get name => field('name')['stringValue'] /*!*/;

  String get updateTime => data['updateTime'] /*!*/;
}

Query unapprovedActiveFailuresQuery(String configuration) {
  return Query(
      'results',
      CompositeFilter('AND', [
        Field('approved').equals(Value.boolean(false)),
        // TODO(karlklose): also search for inactive failures?
        Field('active_configurations').contains(Value.string(configuration)),
        // TODO(karlklose): add index to check for blamelist_start_index < ?
      ]));
}

Future<int> getCommitIndex(String commit) async {
  try {
    Map document = await database.getDocument('commits', commit);
    var index = document['fields']['index'];
    if (index['integerValue'] == null) {
      throw Exception('Expected an integer, but got "$index"');
    }
    return int.parse(index['integerValue']);
  } catch (exception) {
    print('Could not retrieve index for commit "$commit".\n');
    rethrow;
  }
}

/// Compute if the record should be updated based on the outcomes in the
/// result record and the new test result.
bool shouldUpdateRecord(ResultRecord resultRecord, Result testResult) {
  if (testResult == null || !testResult.matches) {
    return false;
  }
  var baseline = testResult.expectation.toLowerCase();
  if (resultRecord.previousResult.toLowerCase() != baseline) {
    // Currently we only support the case where a bisection run improves the
    // accuracy of a "Green" -> "Red" result record.
    return false;
  }
  if (resultRecord.result.toLowerCase() == newTest ||
      resultRecord.result.toLowerCase() == skippedTest) {
    // Skipped tests are often configuration dependent, so it could be wrong
    // to generalize their effect for the result record to different
    // configurations.
    return false;
  }
  return true;
}

void updateBlameLists(
    String configuration, String commit, Map<String, Map> testResults) async {
  int commitIndex = await getCommitIndex(commit);
  var query = unapprovedActiveFailuresQuery(configuration);
  bool needsRetry;
  int attempts = 0;
  do {
    needsRetry = false;
    var documents = (await database.runQuery(query))
        .where((result) => result['document'] != null)
        .map((result) => result['document']['name']);
    for (var documentPath in documents) {
      await database.beginTransaction();
      var documentName = documentPath.split('/').last;
      var result =
          ResultRecord(await database.getDocument('results', documentName));
      if (commitIndex < result.blamelistStartIndex ||
          commitIndex >= result.blamelistEndIndex) {
        continue;
      }
      String name = result.name;
      var testResultData = testResults['$configuration:$name'];
      var testResult =
          testResultData != null ? Result.fromMap(testResultData) : null;
      if (!shouldUpdateRecord(result, testResult)) {
        continue;
      }
      print('Found result record: $configuration:${result.name}: '
          '${result.previousResult} -> ${result.result} '
          'in ${result.blamelistStartIndex}..${result.blamelistEndIndex} '
          'to update with ${testResult.outcome} at $commitIndex.');
      // We found a result representation for this test and configuration whose
      // blamelist includes this results' commit but whose outcome is different
      // then the outcome in the provided test results.
      // This means that this commit should not be part of the result
      // representation and we can update the lower bound of the commit range
      // and the previous result.
      var newStartIndex = commitIndex + 1;
      if (newStartIndex > result.blamelistEndIndex) {
        print('internal error: inconsistent results; skipping results entry');
        continue;
      }
      result.blamelistStartIndex = newStartIndex;
      var updateIndex = Update(['blamelist_start_index'], result.data);
      if (!await database.commit([updateIndex])) {
        // Commiting the change to the database had a conflict, retry.
        needsRetry = true;
        if (++attempts == maxAttempts) {
          throw Exception('Exceeded maximum retry attempts ($maxAttempts).');
        }
        print('Transaction failed, trying again!');
      }
    }
  } while (needsRetry);
}

main(List<String> arguments) async {
  var parser = ArgParser()
    ..addOption('auth-token',
        abbr: 'a',
        help: 'path to a file containing the gcloud auth token (required)')
    ..addOption('results',
        abbr: 'r',
        help: 'path to a file containing the test results (required)')
    ..addFlag('staging', abbr: 's', help: 'use staging database');
  var options = parser.parse(arguments);
  if (options.rest.isNotEmpty ||
      options['results'] == null ||
      options['auth-token'] == null) {
    print(parser.usage);
    exit(1);
  }
  var results = await loadResultsMap(options['results']);
  if (results.isEmpty) {
    print("No test results provided, nothing to update.");
    return;
  }
  // Pick an arbitrary result entry to find configuration and commit hash.
  var firstResult = Result.fromMap(results.values.first);
  var commit = firstResult.commitHash;
  var configuration = firstResult.configuration;
  var project = options['staging'] ? 'dart-ci-staging' : 'dart-ci';
  database = FirestoreDatabase(
      project, await readGcloudAuthToken(options['auth-token']));
  await updateBlameLists(configuration, commit, results);
  database.closeClient();
}
