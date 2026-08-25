#!/usr/bin/env dart
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A script to find all try jobs for a set of tests.
//
// Usage:
//
// ```
// $ tools/find_builders.dart ffi/regress_51504_test ffi/regress_52298_test
// Cq-Include-Trybots: dart/try:vm-kernel-linux-debug-x64,...
// ```

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('mode', help: 'Filter configurations by mode (e.g. debug, release)')
    ..addOption('os', help: 'Filter configurations by OS (e.g. linux, win, mac)')
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false);

  final parsedArgs = parser.parse(args);
  if (parsedArgs['help'] as bool) {
    return printHelp(parser);
  }
  final testNames = parsedArgs.rest.map(_cleanTestName).toList();

  final configurations = _filterConfigurations(
    {
      for (final testName in testNames)
        ...await _testGetConfigurations(testName),
    },
    mode: parsedArgs['mode'] as String?,
    os: parsedArgs['os'] as String?,
  );
  final configurationBuilders = await _configurationBuilders();
  final builders = _filterBuilders({
    for (final config in configurations) configurationBuilders[config]!,
  }).toList()
    ..sort();

  final gerritTryList = builders.map((b) => '$b-try').join(',');
  print('Cq-Include-Trybots: dart/try:$gerritTryList');
}

String _cleanTestName(String path) {
  var name = path.replaceAll('\\', '/');
  if (name.startsWith('tests/')) {
    name = name.substring('tests/'.length);
  }
  if (name.endsWith('.dart')) {
    name = name.substring(0, name.length - '.dart'.length);
  }
  return name;
}

Future<List<String>> _testGetConfigurations(String testName) async {
  final requestUrl = Uri(
    scheme: 'https',
    host: 'current-results-qvyo5rktwa-uc.a.run.app',
    path: 'v1/results',
    queryParameters: {'filter': testName},
  );
  final response = await _get(requestUrl);
  final object = jsonDecode(response) as Map<String, dynamic>;
  final results = object['results'] as List?;
  if (results == null) return [];
  return [
    for (final result in results.cast<Map>())
      result['configuration'],
  ];
}

Future<String> _get(Uri requestUrl) async {
  final client = HttpClient();
  final request = await client.getUrl(requestUrl);
  final response = await request.close();
  final responseString = await response.transform(const Utf8Decoder()).join();
  client.close();
  return responseString;
}

Iterable<String> _filterConfigurations(
  Set<String> configs, {
  String? mode,
  String? os,
}) {
  var filtered = configs;
  if (os != null) {
    filtered = filtered.where((c) => c.contains(os)).toSet();
  }

  if (mode != null) {
    return filtered.where((c) => c.contains(mode)).toList()..sort();
  }

  final result = <String>[];
  for (final config in filtered) {
    if (config.contains('debug')) {
      result.add(config);
    } else if (config.contains('release') &&
        !filtered.contains(config.replaceFirst('release', 'debug'))) {
      result.add(config);
    } else if (config.contains('profile') &&
        !filtered.contains(config.replaceFirst('profile', 'debug')) &&
        !filtered.contains(config.replaceFirst('profile', 'release'))) {
      result.add(config);
    }
  }
  return result..sort();
}

Iterable<String> _filterBuilders(Iterable<String> builders) {
  return builders.where(
    (b) => !_ciOnlyBuilders.contains(b) && !_denyListedBuilders.contains(b),
  );
}

const _ciOnlyBuilders = {
  'vm-aot-linux-release-arm64',
  'vm-linux-release-arm64',
};

const _denyListedBuilders = <String>{};

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
    final object = jsonDecode(response) as Map<String, dynamic>;
    yield* Stream.fromIterable(
      (object['documents'] as List).cast<Map<String, dynamic>>(),
    );

    nextPageToken = object['nextPageToken'];
  } while (nextPageToken != null);
}

Future<Map<String, String>> _configurationBuilders() async {
  return {
    await for (final document in _configurationDocuments())
      if (document
          case {
            'name': String fullName,
            'fields': {'builder': {'stringValue': String builder}},
          })
        fullName.split('/').last: builder,
  };
}

void printHelp(ArgParser parser) {
  print('''
A script to find all try jobs for a set of tests.

  Usage: tools/find_builders.dart [options] [selector] [selector2] [...]

Options:
${parser.usage}

Sample output: Cq-Include-Trybots: dart/try:vm-kernel-linux-debug-x64,...
''');
}
