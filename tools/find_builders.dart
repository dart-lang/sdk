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
  final builders = _filterBuilders(
    {for (final config in configurations) configurationBuilders[config]!},
  ).toList()
    ..sort();

  final gerritTryList = builders.map((b) => '$b-try').join(',');
  print('Cq-Include-Trybots: luci.dart.try:$gerritTryList');
}

Future<List<String>> _testGetConfigurations(String testName) async {
  final requestUrl = Uri(
    scheme: 'https',
    host: 'current-results-qvyo5rktwa-uc.a.run.app',
    path: 'v1/results',
    queryParameters: {'filter': testName},
  );
  final response = await _get(requestUrl);
  final object = jsonDecode(response);
  return [for (final result in object['results']) result['configuration']];
}

Future<String> _get(Uri requestUrl) async {
  final client = HttpClient();
  final request = await client.getUrl(requestUrl);
  final response = await request.close();
  final responseString = await response.transform(const Utf8Decoder()).join();
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

Iterable<String> _filterBuilders(Iterable<String> builders) {
  return builders.where((b) => !_ciOnlyBuilders.contains(b));
}

const _ciOnlyBuilders = {
  'vm-aot-linux-release-arm64',
  'vm-linux-release-arm64',
};

Stream<Map<String, dynamic>> _configurationDocuments() async* {
  String? nextPageToken;
  do {
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
    final object = jsonDecode(response);
    yield* Stream.fromIterable(
        object['documents'].cast<Map<String, dynamic>>());

    nextPageToken = object['nextPageToken'];
  } while (nextPageToken != null);
}

Future<Map<String, String>> _configurationBuilders() async {
  return {
    await for (final document in _configurationDocuments())
      if (document
          case {
            'name': String fullName,
            'fields': {'builder': {'stringValue': String builder}}
          })
        fullName.split('/').last: builder
  };
}

void printHelp() {
  print(r'''
A script to find all try jobs for a set of tests.

  Usage: tools/find_builders.dart [selector] [selector2] [...]

Sample output: Cq-Include-Trybots: luci.dart.try:vm-kernel-linux-debug-x64,...
''');
}
