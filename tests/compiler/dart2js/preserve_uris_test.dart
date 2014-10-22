// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_compiler.dart' show compilerFor, OutputCollector;

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
library main;

@MirrorsUsed(targets: const ['main', 'lib'])
import 'dart:mirrors';
import 'lib.dart';


class Subclass extends Super {
  int _private;

  int magic() => _private++;
}

main() {
  var objects = [new Super(), new Subclass()];
  print(currentMirrorSystem().findLibrary(#main).uri);
}
""",
  'lib.dart': """
library lib;

class Super {
  int _private;

  int magic() => _private++;
}
"""
};

runTest(bool preserveUris) {
  OutputCollector collector = new OutputCollector();
  var options = ["--minify"];
  if (preserveUris) options.add("--preserve-uris");
  var compiler = compilerFor(MEMORY_SOURCE_FILES,
                             outputProvider: collector,
                             options: options);
  return compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    String jsOutput = collector.getOutput('', 'js');
    Expect.equals(preserveUris, jsOutput.contains("main.dart"));
    Expect.equals(preserveUris, jsOutput.contains("lib.dart"));
  });
}

void main() {
  asyncStart();
  new Future.value()
    .then((_) => runTest(true))
    .then((_) => runTest(false))
    .whenComplete(asyncEnd);
}
