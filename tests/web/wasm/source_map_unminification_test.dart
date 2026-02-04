// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=-DTEST_COMPILATION_DIR=$TEST_COMPILATION_DIR

import 'dart:convert';

import 'utils.dart';

import 'package:dart2js_tools/src/dart2js_mapping.dart';
import 'package:expect/expect.dart';
import 'package:source_maps/parser.dart';

final isMinified = const bool.fromEnvironment('dart.tool.dart2wasm.minify');
final compilationDir = const String.fromEnvironment('TEST_COMPILATION_DIR');

void main() {
  if (!isMinified) {
    // Class names are only added to the source maps when minifying.
    return;
  }

  final sourceMapFilePath = getSourceMapFilePath(
    'source_map_unminification',
    0,
  );

  final sourceMapFileContents = utf8.decode(readfile(sourceMapFilePath));

  final sourceMapJson =
      jsonDecode(sourceMapFileContents) as Map<String, dynamic>;

  final mapping = Dart2jsMapping(
    parseJson(sourceMapJson) as SingleMapping,
    sourceMapJson,
  );

  Expect.equals("List<int>", unminify(<int>[].runtimeType.toString(), mapping));
  Expect.equals(
    "Container<Foo, Bar>",
    unminify(Container<Foo, Bar>().runtimeType.toString(), mapping),
  );
}

class Container<T1, T2> {}

class Foo {}

class Bar {}

final RegExp classRegexp = RegExp(r'minified:(Class\d+)');

String unminify(String input, Dart2jsMapping mapping) => input.replaceAllMapped(
  classRegexp,
  (match) => mapping.globalNames[match.group(1)!]!,
);
