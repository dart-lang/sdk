// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensure that unused empty HashMap nodes are dropped from the output.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'memory_compiler.dart';

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
  asyncTest(() async {
    var collector = new OutputCollector();
    var result = await runCompiler(
        memorySourceFiles: TEST_SOURCE, outputProvider: collector);
    var compiler = result.compiler;
    String generated = collector.getOutput('', 'js');
    Expect.isFalse(generated.contains(HASHMAP_EMPTY_CONSTRUCTOR));
  });
}
