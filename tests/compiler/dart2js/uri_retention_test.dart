// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.test.uri_retention_test;

import 'dart:async';

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";

import 'memory_compiler.dart' show
    compilerFor;

Future<String> compileSources(sources, {bool minify, bool preserveUri}) {
  var options = [];
  if (minify) options.add("--minify");
  if (preserveUri) options.add("--preserve-uris");
  var compiler = compilerFor(sources, options: options);
  return compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    return compiler.assembledCode;
  });
}

Future test(sources, { bool libName, bool fileName }) {
  return
      compileSources(sources, minify: false, preserveUri: false).then((output) {
    // Unminified the sources should always contain the library name and the
    // file name.
    Expect.isTrue(output.contains("main_lib"));
    Expect.isTrue(output.contains("main.dart"));
  }).then((_) {
    compileSources(sources, minify: true, preserveUri: false).then((output) {
      Expect.equals(libName, output.contains("main_lib"));
      Expect.isFalse(output.contains("main.dart"));
    });
  }).then((_) {
    compileSources(sources, minify: true, preserveUri: true).then((output) {
      Expect.equals(libName, output.contains("main_lib"));
      Expect.equals(fileName, output.contains("main.dart"));
    });
  });
}

void main() {
  asyncTest(() {
    return new Future.value()
      .then((_) => test(MEMORY_SOURCE_FILES1, libName: false, fileName: false))
      .then((_) => test(MEMORY_SOURCE_FILES2, libName: true, fileName: false))
      .then((_) => test(MEMORY_SOURCE_FILES3, libName: true, fileName: true));
  });
}

const MEMORY_SOURCE_FILES1 = const <String, String> {
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
const MEMORY_SOURCE_FILES2 = const <String, String> {
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
const MEMORY_SOURCE_FILES3 = const <String, String> {
  'main.dart': """
library main_lib;

@MirrorsUsed(targets: 'main_lib')
import 'dart:mirrors';

main() {
  print(currentMirrorSystem().findLibrary(#main_lib).uri);
}
""",
};
