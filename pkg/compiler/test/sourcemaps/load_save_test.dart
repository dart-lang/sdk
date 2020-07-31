// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:convert';
import 'package:expect/expect.dart';
import 'package:source_maps/source_maps.dart';
import 'tools/load.dart';
import 'tools/save.dart';
import '../helpers/memory_compiler.dart';

String SOURCEMAP = '''
{
  "version": 3,
  "file": "out.js",
  "sourceRoot": "",
  "sources":
      ["$sdkPath/_internal/compiler/js_lib/js_primitives.dart","hello_world.dart","$sdkPath/_internal/compiler/js_lib/internal_patch.dart"],
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
  testReadWrite();
  testWriteRead();
}

void testReadWrite() {
  SingleMapping sourceMap = new SingleMapping.fromJson(json.decode(SOURCEMAP));
  String humanReadable = convertToHumanReadableSourceMap(sourceMap);
  SingleMapping sourceMap2 = convertFromHumanReadableSourceMap(humanReadable);
  String humanReadable2 = convertToHumanReadableSourceMap(sourceMap2);
  SingleMapping sourceMap3 = convertFromHumanReadableSourceMap(humanReadable2);
  String humanReadable3 = convertToHumanReadableSourceMap(sourceMap3);

  // Target line entries without sourceUrl are removed.
  //Expect.deepEquals(sourceMap.toJson(), sourceMap2.toJson());
  Expect.deepEquals(sourceMap2.toJson(), sourceMap3.toJson());
  Expect.deepEquals(json.decode(humanReadable), json.decode(humanReadable2));
  Expect.deepEquals(json.decode(humanReadable2), json.decode(humanReadable3));
}

void testWriteRead() {
  SingleMapping sourceMap =
      convertFromHumanReadableSourceMap(HUMAN_READABLE_SOURCE_MAP);
  print(sourceMap);
  String humanReadable = convertToHumanReadableSourceMap(sourceMap);
  print(humanReadable);
  SingleMapping sourceMap2 = convertFromHumanReadableSourceMap(humanReadable);
  Expect.deepEquals(
      json.decode(HUMAN_READABLE_SOURCE_MAP), json.decode(humanReadable));
  Expect.deepEquals(sourceMap.toJson(), sourceMap2.toJson());
}
