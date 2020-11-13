#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Find the success/failure status for a builder that is written to
// Firestore by the cloud functions that process results.json.
// These cloud functions write a success/failure result to the
// builder table based on the approvals in Firestore.

// @dart = 2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const numAttempts = 20;
const failuresPerConfiguration = 20;

/*late*/ bool useStagingDatabase;

String get queryUrl {
  var project = useStagingDatabase ? "dart-ci-staging" : "dart-ci";
  return 'https://firestore.googleapis.com/v1/'
      'projects/$project/databases/(default)/documents:runQuery';
}

/*late*/ String builder;
/*late*/ String builderBase;
/*late*/ int buildNumber;
/*late*/ String token;
/*late*/ http.Client client;

String get buildTable => builder.endsWith('-try') ? 'try_builds' : 'builds';
String get resultsTable => builder.endsWith('-try') ? 'try_results' : 'results';

bool booleanFieldOrFalse(Map<String, dynamic> document, String field) {
  Map<String, dynamic> fieldObject = document['fields'][field];
  if (fieldObject == null) return false;
  return fieldObject['booleanValue'] ?? false;
}

void usage(ArgParser parser) {
  print('''
Usage: get_builder_status.dart [OPTIONS]
Gets the builder status from the Firestore database.
Polls until it gets a completed builder status, or times out.

The options are as follows:

${parser.usage}''');
  exit(1);
}

Future<String> readGcloudAuthToken(String path) async {
  String token = await File(path).readAsString();
  return token.split("\n").first;
}

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag('help', help: 'Show the program usage.', negatable: false);
  parser.addOption('auth_token',
      abbr: 'a', help: 'Authorization token with cloud-platform scope');
  parser.addOption('builder', abbr: 'b', help: 'The builder name');
  parser.addOption('build_number', abbr: 'n', help: 'The build number');
  parser.addFlag('staging',
      abbr: 's', help: 'use staging database', defaultsTo: false);

  final options = parser.parse(args);
  if (options['help']) {
    usage(parser);
  }

  useStagingDatabase = options['staging'] /*!*/;
  builder = options['builder'] /*!*/;
  buildNumber = int.parse(options['build_number'] /*!*/);
  builderBase = builder.replaceFirst(RegExp('-try\$'), '');
  if (options['auth_token'] == null) {
    print('Option "--auth_token (-a)" is required\n');
    usage(parser);
  }
  token = await readGcloudAuthToken(options['auth_token']);
  client = http.Client();
  for (int count = 0; count < numAttempts; ++count) {
    if (count > 0) {
      await Future.delayed(Duration(seconds: 10));
    }
    final response = await runFirestoreQuery(buildQuery());
    if (response.statusCode == HttpStatus.ok) {
      final documents = jsonDecode(response.body);
      final document = documents.first['document'];
      if (document != null) {
        bool success = booleanFieldOrFalse(document, 'success');
        bool completed = booleanFieldOrFalse(document, 'completed');
        if (completed) {
          print(success
              ? 'No new unapproved failures'
              : 'There are new unapproved failures on this build');
          if (builder.endsWith('-try')) exit(success ? 0 : 1);
          final configurations = await getConfigurations();
          final failures = await fetchActiveFailures(configurations);
          if (failures.isNotEmpty) {
            print('There are unapproved failures');
            printActiveFailures(failures);
            exit(1);
          } else {
            print('There are no unapproved failures');
            exit(0);
          }
        }
        String chunks =
            (document['fields']['num_chunks'] ?? const {})['integerValue'];
        String processedChunks = (document['fields']['processed_chunks'] ??
            const {})['integerValue'];
        if (processedChunks != null) {
          print([
            'Received',
            processedChunks,
            if (chunks != null) ...['out of', chunks],
            'chunks.'
          ].join(' '));
        }
      } else {
        print('No results received for build $buildNumber of $builder');
      }
    } else {
      print('HTTP status ${response.statusCode} received '
          'when fetching build data');
    }
  }
  print('No status received for build $buildNumber of $builder '
      'after $numAttempts attempts, with 10 second waits.');
  exit(2);
}

Future<List<String>> getConfigurations() async {
  final response = await runFirestoreQuery(configurationsQuery());
  if (response.statusCode == HttpStatus.ok) {
    final documents = jsonDecode(response.body);
    final groups = <String /*!*/ >{
      for (Map document in documents)
        if (document.containsKey('document'))
          document['document']['name'].split('/').last
    };
    return groups.toList();
  }
  print('Could not fetch configurations for $builderBase');
  return [];
}

Map<int, Future<String>> commitHashes = {};
Future<String> commitHash(int index) =>
    commitHashes.putIfAbsent(index, () => fetchCommitHash(index));

Future<String /*!*/ > fetchCommitHash(int index) async {
  final response = await runFirestoreQuery(commitQuery(index));
  if (response.statusCode == HttpStatus.ok) {
    final document = jsonDecode(response.body).first['document'];
    if (document != null) {
      return document['name'] /*!*/ .split('/').last;
    }
  }
  print('Could not fetch commit with index $index');
  return 'missing hash for commit $index';
}

Future<Map<String, List<Map<String, dynamic>>>> fetchActiveFailures(
    List<String /*!*/ > configurations) async {
  final failures = <String, List<Map<String, dynamic>>>{};
  for (final configuration in configurations) {
    final response =
        await runFirestoreQuery(unapprovedFailuresQuery(configuration));
    if (response.statusCode == HttpStatus.ok) {
      final documents = jsonDecode(response.body);
      for (final documentItem in documents) {
        final document = documentItem['document'];
        if (document == null) continue;
        final fields = document['fields'];
        failures.putIfAbsent(configuration, () => []).add({
          'name': fields['name']['stringValue'],
          'start_commit': await commitHash(
              int.parse(fields['blamelist_start_index']['integerValue'])),
          'end_commit': await commitHash(
              int.parse(fields['blamelist_end_index']['integerValue'])),
          'result': fields['result']['stringValue'],
          'expected': fields['expected']['stringValue'],
          'previous': fields['previous_result']['stringValue'],
        });
      }
    }
  }
  return failures;
}

void printActiveFailures(Map<String, List<Map<String, dynamic>>> failures) {
  for (final configuration in failures.keys) {
    print('($configuration):');
    for (final failure in failures[configuration]) {
      print([
        '    ',
        failure['name'],
        '   (',
        failure['previous'],
        ' -> ',
        failure['result'],
        ', expected ',
        failure['expected'],
        ') at ',
        failure['start_commit'].substring(0, 6),
        if (failure['end_commit'] != failure['start_commit']) ...[
          '..',
          failure['end_commit'].substring(0, 6)
        ]
      ].join(''));
    }
  }
}

Future<http.Response> runFirestoreQuery(String query) {
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  };
  return client.post(queryUrl, headers: headers, body: query);
}

String buildQuery() => jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': buildTable}
        ],
        'limit': 1,
        'where': {
          'compositeFilter': {
            'op': 'AND',
            'filters': [
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'build_number'},
                  'op': 'EQUAL',
                  'value': {'integerValue': buildNumber}
                }
              },
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'builder'},
                  'op': 'EQUAL',
                  'value': {'stringValue': builder}
                }
              }
            ]
          }
        }
      }
    });

String configurationsQuery() => jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'configurations'}
        ],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'builder'},
            'op': 'EQUAL',
            'value': {'stringValue': builderBase}
          }
        }
      }
    });

String unapprovedFailuresQuery(String configuration) => jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': resultsTable}
        ],
        'limit': failuresPerConfiguration,
        'where': {
          'compositeFilter': {
            'op': 'AND',
            'filters': [
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'active_configurations'},
                  'op': 'ARRAY_CONTAINS',
                  'value': {'stringValue': configuration}
                }
              },
              {
                'fieldFilter': {
                  'field': {'fieldPath': 'approved'},
                  'op': 'EQUAL',
                  'value': {'booleanValue': false}
                }
              }
            ]
          }
        }
      }
    });

String commitQuery(int index) => jsonEncode({
      'structuredQuery': {
        'from': [
          {'collectionId': 'commits'}
        ],
        'limit': 1,
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': 'index'},
            'op': 'EQUAL',
            'value': {'integerValue': index}
          }
        }
      }
    });
