// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';
import '../../constraint_harness.dart';

void main(List<String> args, SendPort sendPort) {
  waitForImportsAndInvoke(sendPort, processDeferredImports);
}

List<Node> processDeferredImports(List<String> imports) {
  var step1 = 'memory:sdk/tests/web/native/main.dart#step1';
  var step2a = 'memory:sdk/tests/web/native/main.dart#step2a';
  var step2b = 'memory:sdk/tests/web/native/main.dart#step2b';
  var step3 = 'memory:sdk/tests/web/native/main.dart#step3';
  var builder = ProgramSplitBuilder();
  return [
    ...imports.map(builder.referenceNode),
    builder.orderNode(step1, step2a),
    builder.orderNode(step1, step2b),
    builder.orderNode(step2a, step3),
    builder.orderNode(step2b, step3),
  ];
}
