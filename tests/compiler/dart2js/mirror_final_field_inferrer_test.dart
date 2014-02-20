// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that final fields in @MirrorsUsed are still inferred.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show compilerFor;
import 'compiler_helper.dart' show findElement;
import 'type_mask_test_helper.dart';

const MEMORY_SOURCE_FILES = const <String, String> {
  'main.dart': """
@MirrorsUsed(targets: 'field')
import 'dart:mirrors';

const field = 42;

main() {
  return field;
}
"""
};

void main() {
  var compiler = compilerFor(MEMORY_SOURCE_FILES);
  asyncTest(() => compiler.runCompiler(Uri.parse('memory:main.dart')).then((_) {
    var element = findElement(compiler, 'field');
    var typesTask = compiler.typesTask;
    var typesInferrer = typesTask.typesInferrer;
    Expect.equals(typesTask.uint31Type,
                  simplify(typesInferrer.getTypeOfElement(element), compiler),
                  'field');
  }));
}
