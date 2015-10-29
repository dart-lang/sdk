// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show runCompiler;
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import 'package:compiler/src/dart_backend/dart_backend.dart' show
    DartBackend;
import 'package:compiler/src/tree/tree.dart' show
    Identifier, Node, Send;
import 'package:compiler/src/mirror_renamer/mirror_renamer.dart' show
    MirrorRenamerImpl;

main() {
  asyncTest(() async {
    await testUniqueMinification();
    await testNoUniqueMinification();
  });
}

Future<CompilerImpl> run({useMirrorHelperLibrary: false, minify: false}) async {
  List<String> options = ['--output-type=dart'];
  if (minify) {
    options.add('--minify');
  }
  var result = await runCompiler(
      memorySourceFiles: MEMORY_SOURCE_FILES,
      options: options,
      beforeRun: (CompilerImpl compiler) {
        DartBackend backend = compiler.backend;
        backend.useMirrorHelperLibrary = useMirrorHelperLibrary;
      });
  return result.compiler;
}

Future testUniqueMinification() async {
  CompilerImpl compiler = await run(useMirrorHelperLibrary: true, minify: true);
  DartBackend backend = compiler.backend;
  MirrorRenamerImpl mirrorRenamer = backend.mirrorRenamer;
  Map<Node, String> renames = backend.placeholderRenamer.renames;
  Map<String, String> symbols = mirrorRenamer.symbols;

  // Check that no two different source code names get the same mangled name,
  // with the exception of MirrorSystem.getName that gets renamed to the same
  // mangled name as the getNameHelper from _mirror_helper.dart.
  for (Node node in renames.keys) {
    Identifier identifier = node.asIdentifier();
    if (identifier != null) {
      String source = identifier.source;
      Send send = mirrorRenamer.mirrorSystemGetNameNodes.first;
      if (send.selector == node)
        continue;
      if (symbols.containsKey(renames[node])) {
        print(node);
        Expect.equals(source, symbols[renames[node]]);
      }
    }
  }
}

Future testNoUniqueMinification() async {
  CompilerImpl compiler =
      await run(useMirrorHelperLibrary: false, minify: true);
  DartBackend backend = compiler.backend;
  Map<Node, String> renames = backend.placeholderRenamer.renames;

  // 'Foo' appears twice and 'invocation' and 'hest' get the same mangled
  // name.
  Expect.equals(renames.values.toSet().length, renames.values.length - 2);
}

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
import 'dart:mirrors';

class Foo {
  noSuchMethod(invocation) {
    MirrorSystem.getName(null);
  }
}

main(hest) {
  new Foo().fisk();
}
"""};
