// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show runCompiler;
import 'package:compiler/src/apiimpl.dart' show
    CompilerImpl;
import 'package:compiler/src/elements/elements.dart' show
    Element, LibraryElement, ClassElement;
import 'package:compiler/src/tree/tree.dart' show
    Block, ExpressionStatement, FunctionExpression, Node, Send;
import 'package:compiler/src/dart_backend/dart_backend.dart' show
    DartBackend, ElementAst;
import 'package:compiler/src/mirror_renamer/mirror_renamer.dart' show
    MirrorRenamerImpl;

main() {
  asyncTest(() async {
    await testWithMirrorRenaming(minify: true);
    await testWithMirrorRenaming(minify: false);
    await testWithoutMirrorRenaming(minify: true);
    await testWithoutMirrorRenaming(minify: false);
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

Future testWithMirrorRenaming({bool minify}) async {
  CompilerImpl compiler =
      await run(useMirrorHelperLibrary: true, minify: minify);
  DartBackend backend = compiler.backend;
  MirrorRenamerImpl mirrorRenamer = backend.mirrorRenamer;
  Map<Node, String> renames = backend.placeholderRenamer.renames;
  Iterable<LibraryElement> imports =
      backend.placeholderRenamer.platformImports.keys;

  FunctionExpression node = backend.memberNodes.values.first.first;
  Block block = node.body;
  ExpressionStatement getNameFunctionNode = block.statements.nodes.head;
  Send send = getNameFunctionNode.expression;

  Expect.equals(renames[mirrorRenamer.getNameFunctionNode.name],
                renames[send.selector]);
  Expect.equals("",
                renames[send.receiver]);
  Expect.equals(1, imports.length);
}

Future testWithoutMirrorRenaming({bool minify}) async {
  CompilerImpl compiler =
      await run(useMirrorHelperLibrary: false, minify: minify);
  DartBackend backend = compiler.backend;
  Map<Node, String> renames = backend.placeholderRenamer.renames;
  Iterable<LibraryElement> imports =
      backend.placeholderRenamer.platformImports.keys;
  FunctionExpression node = backend.memberNodes.values.first.first;
  Block block = node.body;
  ExpressionStatement getNameFunctionNode = block.statements.nodes.head;
  Send send = getNameFunctionNode.expression;

  Expect.isFalse(renames.containsKey(send.selector));
  Expect.equals(1, imports.length);
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
