// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// results.json and flaky.json parses.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<List<Map<String, dynamic>>> loadResults(String path) async {
  final results = <Map<String, dynamic>>[];
  final lines = new File(path)
      .openRead()
      .transform(utf8.decoder)
      .transform(new LineSplitter());
  await for (final line in lines) {
    try {
      final Map<String, dynamic> map = jsonDecode(line);
      results.add(map);
    } on FormatException {}
  }
  return results;
}

Map<String, Map<String, dynamic>> createResultsMap(
        List<Map<String, dynamic>> results) =>
    new Map<String, Map<String, dynamic>>.fromIterable(results,
        key: (dynamic result) => (result as Map<String, dynamic>)['name']);

Future<Map<String, Map<String, dynamic>>> loadResultsMap(String path) async =>
    createResultsMap(await loadResults(path));
