// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.uri_retention_test;

import 'dart:async';

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart' show runCompiler, OutputCollector;

Future<String> compileSources(sources, {bool minify}) async {
  var options = [];
  if (minify) options.add(Flags.minify);
  OutputCollector outputCollector = new OutputCollector();
  await runCompiler(
      memorySourceFiles: sources,
      options: options,
      outputProvider: outputCollector);
  return outputCollector.getOutput('', OutputType.js);
}

Future test(sources, {bool libName, bool fileName}) {
  return compileSources(sources, minify: false).then((output) {
    // Unminified the sources should always contain the library name and the
    // file name.
    Expect.isTrue(output.contains("main_lib"));
    Expect.isTrue(output.contains("main.dart"));
  }).then((_) {
    compileSources(sources, minify: true).then((output) {
      Expect.equals(libName, output.contains("main_lib"));
      Expect.isFalse(output.contains("main.dart"));
    });
  });
}

void main() {
  runTests() async {
    await test(MEMORY_SOURCE_FILES1, libName: false, fileName: false);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

const MEMORY_SOURCE_FILES1 = const <String, String>{
  'main.dart': """
library main_lib;

class A {
  final uri = "foo";
}

main() {
  print(Uri.base);
  print(new A().uri);
}
""",
};
