// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'memory_compiler.dart' show compilerFor;
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart' show
    Compiler;
import
    '../../../sdk/lib/_internal/compiler/implementation/dart_backend/dart_backend.dart'
show
    DartBackend;
import
    '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart'
show
    Node;

main() {
  testUniqueMinification();
  testNoUniqueMinification();
}

Compiler runCompiler({useMirrorHelperLibrary: false, minify: false}) {
  List<String> options = ['--output-type=dart'];
  if (minify) {
    options.add('--minify');
  }
  Compiler compiler = compilerFor(MEMORY_SOURCE_FILES, options: options);
  DartBackend backend = compiler.backend;
  backend.useMirrorHelperLibrary = useMirrorHelperLibrary;
  compiler.runCompiler(Uri.parse('memory:main.dart'));
  return compiler;
}

void testUniqueMinification() {
  Compiler compiler = runCompiler(useMirrorHelperLibrary: true, minify: true);
  DartBackend backend = compiler.backend;
  MirrorRenamer mirrorRenamer = backend.mirrorRenamer;
  Map<Node, String> renames = backend.renames;
  Map<String, SourceString> symbols = mirrorRenamer.symbols;

  // Check that no two different source code names get the same mangled name,
  // with the exception of MirrorSystem.getName that gets renamed to the same
  // mangled name as the getNameHelper from _mirror_helper.dart.
  for (Node node in renames.keys) {
    Identifier identifier = node.asIdentifier();
    if (identifier != null) {
      SourceString source = identifier.source;
      if (mirrorRenamer.mirrorSystemGetNameNodes.first.selector == node)
        continue;
      if (symbols.containsKey(renames[node])) {
        print(node);
        Expect.equals(source, symbols[renames[node]]);
      }
    }
  }
}

void testNoUniqueMinification() {
  Compiler compiler = runCompiler(useMirrorHelperLibrary: false, minify: true);
  DartBackend backend = compiler.backend;
  Map<Node, String> renames = backend.renames;

  // 'Foo' appears twice and 'invocation' and 'hest' get the same mangled name.
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

main() {
  new Foo().fisk();
  var hest;
}
"""};
