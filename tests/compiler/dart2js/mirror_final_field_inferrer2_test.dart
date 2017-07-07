// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that final fields in @MirrorsUsed are still inferred.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show runCompiler;
import 'compiler_helper.dart' show findElement;
import 'type_mask_test_helper.dart';

const MEMORY_SOURCE_FILES = const <String, String>{
  'main.dart': """
import 'dart:mirrors';

const field = 42;

main() {
  var mirror = reflect(field);
  mirror.invoke(null, null);
}
"""
};

void main() {
  asyncTest(() async {
    var result = await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    var compiler = result.compiler;
    var element = findElement(compiler, 'field');
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var commonMasks = closedWorld.commonMasks;
    Expect.equals(commonMasks.uint31Type,
        simplify(typesInferrer.getTypeOfMember(element), closedWorld), 'field');
  });
}
