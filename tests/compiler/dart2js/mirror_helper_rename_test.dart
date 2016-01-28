// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show runCompiler, OutputCollector;
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import 'package:compiler/src/tree/tree.dart' show
    Node;
import 'package:compiler/src/dart_backend/dart_backend.dart';
import 'package:compiler/src/mirror_renamer/mirror_renamer.dart';

main() {
  asyncTest(() async {
    await testWithMirrorHelperLibrary(minify: true);
    await testWithMirrorHelperLibrary(minify: false);
    await testWithoutMirrorHelperLibrary(minify: true);
    await testWithoutMirrorHelperLibrary(minify: false);
  });
}

Future<CompilerImpl> run({OutputCollector outputCollector,
                      bool useMirrorHelperLibrary: false,
                      bool minify: false}) async {
  List<String> options = ['--output-type=dart'];
  if (minify) {
    options.add('--minify');
  }
  var result = await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      outputProvider: outputCollector,
      options: options,
      beforeRun: (CompilerImpl compiler) {
        DartBackend backend = compiler.backend;
        backend.useMirrorHelperLibrary = useMirrorHelperLibrary;
      });
  return result.compiler;
}

Future testWithMirrorHelperLibrary({bool minify}) async {
  OutputCollector outputCollector = new OutputCollector();
  CompilerImpl compiler = await run(
      outputCollector: outputCollector,
      useMirrorHelperLibrary: true,
      minify: minify);
  DartBackend backend = compiler.backend;
  MirrorRenamerImpl mirrorRenamer = backend.mirrorRenamer;
  Map<Node, String> renames = backend.placeholderRenamer.renames;
  Map<String, String> symbols = mirrorRenamer.symbols;

  Expect.isFalse(null == mirrorRenamer.helperLibrary);
  Expect.isFalse(null == mirrorRenamer.getNameFunction);

  for (Node n in renames.keys) {
    if (symbols.containsKey(renames[n])) {
      if(n.toString() == 'getName') {
        Expect.equals(
            MirrorRenamerImpl.MIRROR_HELPER_GET_NAME_FUNCTION,
            symbols[renames[n]]);
      } else {
        Expect.equals(n.toString(), symbols[renames[n]]);
      }
    }
  }

  String output = outputCollector.getOutput('', 'dart');
  String getNameMatch = MirrorRenamerImpl.MIRROR_HELPER_GET_NAME_FUNCTION;
  Iterable i = getNameMatch.allMatches(output);
  print(output);
  if (minify) {
    Expect.equals(0, i.length);
  } else {
    // Appears twice in code (defined & called).
    Expect.equals(2, i.length);
  }

  RegExp mapMatch = new RegExp('const<String,( )?String>');
  i = mapMatch.allMatches(output);
  Expect.equals(1, i.length);
}

Future testWithoutMirrorHelperLibrary({bool minify}) async {
  CompilerImpl compiler =
      await run(useMirrorHelperLibrary: false, minify: minify);
  DartBackend backend = compiler.backend;
  MirrorRenamer mirrorRenamer = backend.mirrorRenamer;

  Expect.equals(null, mirrorRenamer.helperLibrary);
  Expect.equals(null, mirrorRenamer.getNameFunction);
}

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
import 'dart:mirrors';

class Foo {
  noSuchMethod(Invocation invocation) {
    MirrorSystem.getName(invocation.memberName);
  }
}

void main() {
  new Foo().fisk();
}
"""};