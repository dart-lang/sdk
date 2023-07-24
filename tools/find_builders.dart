#!/usr/bin/env dart
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A script to find all try jobs for a set of tests.
//
// Usage:
//
// ```
// $ tools/find_builders.dart ffi/regress_51504_test ffi/regress_51913_test
// Cq-Include-Trybots: luci.dart.try:vm-kernel-linux-debug-x64,...
// ```

import 'dart:convert';
import 'dart:io';

// TODO(dacoharkes): Be able to use test full paths instead of test names.
// TODO(dacoharkes): Be able to use different filters.
Future<void> main(List<String> args) async {
  if (args.contains('--help')) {
    return printHelp();
  }
  final testNames = args;

  final configurations = _filterConfigurations({
    for (final testName in testNames) ...await _testGetConfigurations(testName),
  });
  final configurationBuilders = await _configurationBuilders();
  final builders = [
    for (final config in configurations) configurationBuilders[config]
  ]..sort();

  print('Cq-Include-Trybots: luci.dart.try:${builders.join(',')}');
}

Future<List<String>> _testGetConfigurations(String testName) async {
  final requestUrl = Uri.parse(
      'https://current-results-qvyo5rktwa-uc.a.run.app/v1/results?filter=$testName');
  final response = await _get(requestUrl);
  final object = jsonDecode(response) as Map<String, dynamic>;
  final results = (object['results'] as List).cast<Map<String, dynamic>>();
  return [for (final result in results) result['configuration'] as String];
}

Future<String> _get(Uri requestUrl) async {
  final client = HttpClient();
  final request = await client.getUrl(requestUrl);
  final response = await request.close();
  final responseString =
      await response.cast<List<int>>().transform(const Utf8Decoder()).join();
  client.close();
  return responseString;
}

Iterable<String> _filterConfigurations(Set<String> configs) {
  final result = <String>[];
  for (final config in configs) {
    if (config.contains('debug')) {
      result.add(config);
    } else if (config.contains('release') &&
        !configs.contains(config.replaceFirst('release', 'debug'))) {
      result.add(config);
    } else if (config.contains('profile') &&
        !configs.contains(config.replaceFirst('profile', 'debug')) &&
        !configs.contains(config.replaceFirst('profile', 'release'))) {
      result.add(config);
    }
  }
  return result..sort();
}

Stream<Map<String, dynamic>> _configurationDocuments() async* {
  String? nextPageToken;
  while (true) {
    final requestUrl = Uri(
      scheme: 'https',
      host: 'firestore.googleapis.com',
      path: 'v1/projects/dart-ci/databases/(default)/documents/configurations',
      queryParameters: {
        'pageSize': '300',
        if (nextPageToken != null) 'pageToken': nextPageToken,
      },
    );
    final response = await _get(requestUrl);
    final object = jsonDecode(response) as Map<String, dynamic>;
    final documents =
        (object['documents'] as List).cast<Map<String, dynamic>>();
    for (final d in documents) {
      yield d;
    }

    nextPageToken = object['nextPageToken'] as String?;
    if (nextPageToken == null) {
      break;
    }
  }
}

Future<Map<String, String>> _configurationBuilders() async {
  final result = <String, String>{};
  await for (final document in _configurationDocuments()) {
    final fullName = document['name'] as String;
    final name = fullName.split('/').last;
    final builder = document['fields']['builder']['stringValue'] as String?;
    if (builder != null) {
      result[name] = builder;
    }
  }
  return result;
}

void printHelp() {
  print(r'''
A script to find all try jobs for a set of tests.

  Usage: tools/find_builders.dart [selector] [selector2] [...]

Sample output: Cq-Include-Trybots: luci.dart.try:vm-kernel-linux-debug-x64,...
''');
}
