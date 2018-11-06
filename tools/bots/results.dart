// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// results.json and flaky.json parses.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

List<Map<String, dynamic>> parseResults(String contents) {
  return LineSplitter.split(contents)
      .map(jsonDecode)
      .toList()
      .cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> loadResults(String path) async {
  final results = <Map<String, dynamic>>[];
  final lines = new File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(new LineSplitter());
  await for (final line in lines) {
    final Map<String, dynamic> map = jsonDecode(line);
    results.add(map);
  }
  return results;
}

Map<String, Map<String, dynamic>> createResultsMap(
        List<Map<String, dynamic>> results) =>
    new Map<String, Map<String, dynamic>>.fromIterable(
        results
            // TODO: Temporarily discard results in the old flaky.json format
            // This can be removed once every bot has run once after this commit
            // has landed, purging all old flakiness information.
            .where((result) => result["configuration"] != null),
        key: (dynamic result) =>
            "${result["configuration"]}:${result["name"]}");

Map<String, Map<String, dynamic>> parseResultsMap(String contents) =>
    createResultsMap(parseResults(contents));

Future<Map<String, Map<String, dynamic>>> loadResultsMap(String path) async =>
    createResultsMap(await loadResults(path));
