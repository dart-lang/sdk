// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:source_maps/source_maps.dart';
import 'package:unittest/unittest.dart';
import 'load.dart';
import 'save.dart';

const String SOURCEMAP = '''
{
  "version": 3,
  "file": "out.js",
  "sourceRoot": "",
  "sources": ["sdk/lib/_internal/compiler/js_lib/js_primitives.dart","hello_world.dart","sdk/lib/_internal/compiler/js_lib/internal_patch.dart"],
  "names": ["printString","main","printToConsole"],
  "mappings": "A;A;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;C;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;A;;eAoBAA;;;AAIIA;;;;AAOAA;;;AAKAA;;;AAMAA;;;GAOJA;;sC;;QC5CAC;;ICYEC;GDRFD;;;;A;A;A;;;A;;;A;A;A;A;A;A;A;;;;;;A;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;A;C;;;;;;;;;;;;;;;;;;;;;;;;;;;;A"
}''';

const String HUMAN_READABLE_SOURCE_MAP = '''
{
  "file": "out.js",
  "sourceRoot": "",
  "sources": {
    "0": "out.js.map",
    "1": "test.dart",
    "2": "out.js"
  },
  "lines": [
    {"target": "3,3-", "source": "1:2,17"},
    {"target": "4,3-", "source": "1:3,17"},
    {"target": "5,3-15", "source": "1:4,17"},
    {"target": "5,15-20", "source": "1:5,17"},
    {"target": "5,20-", "source": "1:6,4"},
    {"target": "6,3-", "source": "1:7,17"},
    {"target": "7,3-", "source": "1:8,17"},
    {"target": "8,1-", "source": "1:9,1"},
    {"target": "10,3-", "source": "1:11,17"},
    {"target": "11,3-", "source": "1:12,17"},
    {"target": "12,3-", "source": "1:13,17"},
    {"target": "13,3-", "source": "1:14,17"},
    {"target": "14,1-", "source": "1:15,4"}
  ]
}''';

void main() {
  test('read/write', () {
    SingleMapping sourceMap =
        new SingleMapping.fromJson(json.decode(SOURCEMAP));
    String humanReadable = convertToHumanReadableSourceMap(sourceMap);
    SingleMapping sourceMap2 = convertFromHumanReadableSourceMap(humanReadable);
    String humanReadable2 = convertToHumanReadableSourceMap(sourceMap2);
    SingleMapping sourceMap3 =
        convertFromHumanReadableSourceMap(humanReadable2);
    String humanReadable3 = convertToHumanReadableSourceMap(sourceMap3);

    // Target line entries without sourceUrl are removed.
    //expect(sourceMap.toJson(), equals(sourceMap2.toJson()));
    expect(sourceMap2.toJson(), equals(sourceMap3.toJson()));
    expect(json.decode(humanReadable), equals(json.decode(humanReadable2)));
    expect(json.decode(humanReadable2), equals(json.decode(humanReadable3)));
  });

  test('write/read', () {
    SingleMapping sourceMap =
        convertFromHumanReadableSourceMap(HUMAN_READABLE_SOURCE_MAP);
    print(sourceMap);
    String humanReadable = convertToHumanReadableSourceMap(sourceMap);
    print(humanReadable);
    SingleMapping sourceMap2 = convertFromHumanReadableSourceMap(humanReadable);
    expect(json.decode(HUMAN_READABLE_SOURCE_MAP),
        equals(json.decode(humanReadable)));
    expect(sourceMap.toJson(), equals(sourceMap2.toJson()));
  });
}
