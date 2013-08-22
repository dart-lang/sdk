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
  Map<Node, String> renames = backend.renames;

  //'Foo' appears twice, so toSet() reduces the length by 1.
  Expect.equals(renames.values.toSet().length, renames.values.length - 1);
}

void testNoUniqueMinification() {
  Compiler compiler = runCompiler(useMirrorHelperLibrary: false, minify: true);
  DartBackend backend = compiler.backend;
  Map<Node, String> renames = backend.renames;

  //'Foo' appears twice and now 'invocation' and 'hest' can get the same name.
  Expect.equals(renames.values.toSet().length, renames.values.length - 2);
}

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
import 'dart:mirrors';

class Foo {
  noSuchMethod(invocation) {
    MirrorSystem.getName(const Symbol('hest'));
  }
}

main() {
  new Foo().fisk();
  var hest;
}
"""};
