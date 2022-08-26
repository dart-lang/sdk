// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

import 'dart:isolate';

import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';
import '../../constraint_harness.dart';

void main(List<String> args, SendPort sendPort) {
  waitForImportsAndInvoke(sendPort, processDeferredImports);
}

List<Node> processDeferredImports(List<String> imports) {
  var lib1 = 'memory:sdk/tests/web/native/lib1.dart#b1';
  var lib2 = 'memory:sdk/tests/web/native/lib2.dart#b2';
  var builder = ProgramSplitBuilder();
  return [
    ...imports.map(builder.referenceNode),
    builder.fuseNode({lib1, lib2}),
  ];
}
