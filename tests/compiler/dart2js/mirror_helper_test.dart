// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'memory_compiler.dart' show compilerFor;
import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart' show
    Compiler;
import
    '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart'
show
    Element, LibraryElement, ClassElement;
import
    '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart'
show
    Node;
import
    '../../../sdk/lib/_internal/compiler/implementation/dart_backend/dart_backend.dart'
show
    DartBackend, ElementAst;
import
    '../../../sdk/lib/_internal/compiler/implementation/mirror_renamer/mirror_renamer.dart'
show
    MirrorRenamer;
import
    '../../../sdk/lib/_internal/compiler/implementation/scanner/scannerlib.dart'
show
    SourceString;


main() {
  testWithMirrorRenaming(minify: true);
  testWithMirrorRenaming(minify: false);
  testWithoutMirrorRenaming(minify: true);
  testWithoutMirrorRenaming(minify: false);
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

void testWithMirrorRenaming({bool minify}) {
  Compiler compiler = runCompiler(useMirrorHelperLibrary: true, minify: minify);

  DartBackend backend = compiler.backend;
  MirrorRenamer mirrorRenamer = backend.mirrorRenamer;
  Map<Node, String> renames = backend.renames;
  Map<LibraryElement, String> imports = backend.imports;

  Node getNameFunctionNode =
      backend.memberNodes.values.first.first.body.statements.nodes.head;

  Expect.equals(
      const SourceString(MirrorRenamer.MIRROR_HELPER_GET_NAME_FUNCTION),
      mirrorRenamer.symbols[renames[getNameFunctionNode.expression.selector]]);
  Expect.equals("",
                renames[getNameFunctionNode.expression.receiver]);
  Expect.equals(1, imports.keys.length);
}

void testWithoutMirrorRenaming({bool minify}) {
  Compiler compiler =
      runCompiler(useMirrorHelperLibrary: false, minify: minify);

  DartBackend backend = compiler.backend;
  Map<Node, String> renames = backend.renames;
  Map<LibraryElement, String> imports = backend.imports;

  Node getNameFunctionNode =
      backend.memberNodes.values.first.first.body.statements.nodes.head;

  Expect.isFalse(renames.containsKey(getNameFunctionNode.expression.selector));
  Expect.isFalse(renames.containsKey(getNameFunctionNode.expression.receiver));
  Expect.equals(1, imports.keys.length);
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
