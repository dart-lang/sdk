// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parser_test;

import 'dart:convert';
import 'package:unittest/unittest.dart';
import 'package:source_maps/source_maps.dart';
import 'common.dart';

const Map<String, dynamic> MAP_WITH_NO_SOURCE_LOCATION = const {
    'version': 3,
    'sourceRoot': '',
    'sources': const ['input.dart'],
    'names': const [],
    'mappings': 'A',
    'file': 'output.dart'
};

const Map<String, dynamic> MAP_WITH_SOURCE_LOCATION = const {
    'version': 3,
    'sourceRoot': '',
    'sources': const ['input.dart'],
    'names': const [],
    'mappings': 'AAAA',
    'file': 'output.dart'
};

const Map<String, dynamic> MAP_WITH_SOURCE_LOCATION_AND_NAME = const {
    'version': 3,
    'sourceRoot': '',
    'sources': const ['input.dart'],
    'names': const ['var'],
    'mappings': 'AAAAA',
    'file': 'output.dart'
};

main() {
  test('parse', () {
    var mapping = parseJson(EXPECTED_MAP);
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('parse + json', () {
    var mapping = parse(JSON.encode(EXPECTED_MAP));
    check(outputVar1, mapping, inputVar1, false);
    check(outputVar2, mapping, inputVar2, false);
    check(outputFunction, mapping, inputFunction, false);
    check(outputExpr, mapping, inputExpr, false);
  });

  test('parse with file', () {
    var mapping = parseJson(EXPECTED_MAP);
    check(outputVar1, mapping, inputVar1, true);
    check(outputVar2, mapping, inputVar2, true);
    check(outputFunction, mapping, inputFunction, true);
    check(outputExpr, mapping, inputExpr, true);
  });

  test('parse with no source location', () {
    SingleMapping map = parse(JSON.encode(MAP_WITH_NO_SOURCE_LOCATION));
    expect(map.lines.length, 1);
    expect(map.lines.first.entries.length, 1);
    TargetEntry entry = map.lines.first.entries.first;

    expect(entry.column, 0);
    expect(entry.sourceUrlId, null);
    expect(entry.sourceColumn, null);
    expect(entry.sourceLine, null);
    expect(entry.sourceNameId, null);
  });

  test('parse with source location and no name', () {
    SingleMapping map = parse(JSON.encode(MAP_WITH_SOURCE_LOCATION));
    expect(map.lines.length, 1);
    expect(map.lines.first.entries.length, 1);
    TargetEntry entry = map.lines.first.entries.first;

    expect(entry.column, 0);
    expect(entry.sourceUrlId, 0);
    expect(entry.sourceColumn, 0);
    expect(entry.sourceLine, 0);
    expect(entry.sourceNameId, null);
  });

  test('parse with source location and name', () {
    SingleMapping map = parse(JSON.encode(MAP_WITH_SOURCE_LOCATION_AND_NAME));
    expect(map.lines.length, 1);
    expect(map.lines.first.entries.length, 1);
    TargetEntry entry = map.lines.first.entries.first;

    expect(entry.sourceUrlId, 0);
    expect(entry.sourceUrlId, 0);
    expect(entry.sourceColumn, 0);
    expect(entry.sourceLine, 0);
    expect(entry.sourceNameId, 0);
  });

  test('parse with source root', () {
    var inputMap = new Map.from(MAP_WITH_SOURCE_LOCATION);
    inputMap['sourceRoot'] = '/pkg/';
    var mapping = parseJson(inputMap);
    expect(mapping.spanFor(0, 0).sourceUrl, Uri.parse("/pkg/input.dart"));

    var newSourceRoot = '/new/';

    mapping.sourceRoot = newSourceRoot;
    inputMap["sourceRoot"] = newSourceRoot;

    expect(mapping.toJson(), equals(inputMap));
  });

  test('parse and re-emit', () {
    for (var expected in [
        EXPECTED_MAP,
        MAP_WITH_NO_SOURCE_LOCATION,
        MAP_WITH_SOURCE_LOCATION,
        MAP_WITH_SOURCE_LOCATION_AND_NAME]) {
      var mapping = parseJson(expected);
      expect(mapping.toJson(), equals(expected));
    }
  });
}
