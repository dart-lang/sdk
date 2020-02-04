#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Find the success/failure status for a builder that is written to
// Firestore by the cloud functions that process results.json.
// These cloud functions write a success/failure result to the
// builder table based on the approvals in Firestore.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const numAttempts = 20;
const queryUrl = 'https://firestore.googleapis.com/v1/'
    'projects/dart-ci/databases/(default)/documents:runQuery';
String builder;
String token;
http.Client client;

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

main(List<String> args) async {
  final parser = new ArgParser();
  parser.addFlag('help', help: 'Show the program usage.', negatable: false);
  parser.addOption('auth_token',
      abbr: 'a', help: 'Authorization token with cloud-platform scope');
  parser.addOption('builder', abbr: 'b', help: 'The builder name');
  parser.addOption('build_number', abbr: 'n', help: 'The build number');

  final options = parser.parse(args);
  if (options['help']) {
    usage(parser);
  }

  builder = options['builder'];
  final buildNumber = options['build_number'];
  final table = builder.endsWith('-try') ? 'try_builds' : 'builds';
  token = await File(options['auth_token']).readAsString();
  client = http.Client();
  final query = {
    'from': [
      {'collectionId': table}
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
  };
  for (int count = 0; count < numAttempts; ++count) {
    if (count > 0) {
      await Future.delayed(Duration(seconds: 10));
    }
    final response = await runFirestoreQuery(query);
    if (response.statusCode == HttpStatus.ok) {
      final documents = jsonDecode(response.body);
      final document = documents.first['document'];
      if (document != null) {
        bool success = booleanFieldOrFalse(document, 'success');
        bool completed = booleanFieldOrFalse(document, 'completed');
        bool activeFailures = booleanFieldOrFalse(document, 'active_failures');
        if (completed) {
          if (success) {
            print('No unapproved new failures');
            if (activeFailures == true) {
              print('There are unapproved failures from previous builds');
              await printResultsFeedLink();
            }
          } else {
            print('There are unapproved new failures on this build');
            await printResultsFeedLink();
          }
          exit((success && (activeFailures != true)) ? 0 : 1);
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
        print('No results recieved for build $buildNumber of $builder');
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

void printResultsFeedLink() async {
  if (builder.endsWith('-try')) return;
  final query = {
    'from': [
      {'collectionId': 'configurations'}
    ],
    'where': {
      'fieldFilter': {
        'field': {'fieldPath': 'builder'},
        'op': 'EQUAL',
        'value': {'stringValue': builder}
      }
    }
  };
  final response = await runFirestoreQuery(query);
  if (response.statusCode == HttpStatus.ok) {
    final documents = jsonDecode(response.body);
    final groups = <String>{
      for (Map document in documents)
        if (document.containsKey('document'))
          document['document']['name'].split('/').last.split('-').first
    };
    String fragment = [
      'showLatestFailures=true',
      'showUnapprovedOnly=true',
      if (groups.isNotEmpty) 'configurationGroups=${groups.join(',')}'
    ].join('&');
    final link = 'https://dart-ci.firebaseapp.com/#$fragment';
    print('Failures link: $link');
  } else {
    print('HTTP status ${response.statusCode} received '
        'when fetching configurations for results feed link');
    print('HTTP response: ${response.body}');
  }
}

Future<http.Response> runFirestoreQuery(Map<String, dynamic> query) {
  final json = jsonEncode({'structuredQuery': query});
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
    'Content-Type': 'application/json'
  };
  return client.post(queryUrl, headers: headers, body: json);
}
