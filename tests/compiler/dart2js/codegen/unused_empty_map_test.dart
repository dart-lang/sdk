// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Ensure that unused empty HashMap nodes are dropped from the output.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/compiler_new.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

const TEST_SOURCE = const {
  "main.dart": r"""
void main() {
  var x = {};
  return;
}
"""
};

const HASHMAP_EMPTY_CONSTRUCTOR = r"LinkedHashMap_LinkedHashMap$_empty";

main() {
  runTest() async {
    var collector = new OutputCollector();
    await runCompiler(
        memorySourceFiles: TEST_SOURCE, outputProvider: collector);
    String generated = collector.getOutput('', OutputType.js);
    Expect.isFalse(generated.contains(HASHMAP_EMPTY_CONSTRUCTOR));
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTest();
  });
}
