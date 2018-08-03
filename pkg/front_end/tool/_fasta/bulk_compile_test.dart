// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate' show ReceivePort;

import 'package:front_end/src/api_prototype/compiler_options.dart'
    show CompilerOptions;

import 'bulk_compile.dart' show BulkCompiler;

testCompiler() async {
  BulkCompiler compiler = new BulkCompiler(new CompilerOptions()
    ..debugDump = true
    ..verbose = true);
  await compiler.compile("main() { print('Hello, World!'); }");
  await compiler.compile(
      // This example is a regression test of lazy loading of FunctionNode
      // which would break when this is preceeded by hello-world.
      "main() { [].map(); }");
  await compiler.compile("main() { print('Hello, Brave New World!'); }");
  await compiler.compile("import 'package';");
}

main() {
  var port = new ReceivePort();
  testCompiler().whenComplete(port.close);
}
