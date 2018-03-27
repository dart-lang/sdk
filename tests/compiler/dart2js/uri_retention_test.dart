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

Future<String> compileSources(sources, {bool minify, bool useKernel}) async {
  var options = [];
  if (minify) options.add(Flags.minify);
  if (!useKernel) options.add(Flags.useOldFrontend);
  OutputCollector outputCollector = new OutputCollector();
  await runCompiler(
      memorySourceFiles: sources,
      options: options,
      outputProvider: outputCollector);
  return outputCollector.getOutput('', OutputType.js);
}

Future test(sources, {bool libName, bool fileName, bool useKernel}) {
  return compileSources(sources, minify: false, useKernel: useKernel)
      .then((output) {
    // Unminified the sources should always contain the library name and the
    // file name.
    Expect.isTrue(output.contains("main_lib"));
    Expect.isTrue(output.contains("main.dart"));
  }).then((_) {
    compileSources(sources, minify: true, useKernel: useKernel).then((output) {
      Expect.equals(libName, output.contains("main_lib"));
      Expect.isFalse(output.contains("main.dart"));
    });
  });
}

void main() {
  runTests({bool useKernel}) async {
    await test(MEMORY_SOURCE_FILES1,
        libName: false, fileName: false, useKernel: useKernel);
    if (!useKernel) {
      await test(MEMORY_SOURCE_FILES2,
          libName: true, fileName: false, useKernel: useKernel);
      await test(MEMORY_SOURCE_FILES3,
          libName: true, fileName: true, useKernel: useKernel);
    }
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTests(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTests(useKernel: true);
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

// Requires the library name, but not the URIs.
const MEMORY_SOURCE_FILES2 = const <String, String>{
  'main.dart': """
library main_lib;

@MirrorsUsed(targets: 'main_lib')
import 'dart:mirrors';
import 'file2.dart';

class A {
}

main() {
  print(Uri.base);
  // Unfortunately we can't use new B().uri yet, because that would require
  // some type-feedback to know that the '.uri' is not the one from the library.
  print(new B());
  print(reflectClass(A).declarations.length);
}
""",
  'file2.dart': """
library other_lib;

class B {
  final uri = "xyz";
}
""",
};

// Requires the uri (and will contain the library-name, too).
const MEMORY_SOURCE_FILES3 = const <String, String>{
  'main.dart': """
library main_lib;

@MirrorsUsed(targets: 'main_lib')
import 'dart:mirrors';

main() {
  print(currentMirrorSystem().findLibrary(#main_lib).uri);
}
""",
};
