// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that final fields in @MirrorsUsed are still inferred.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart' show runCompiler;
import 'compiler_helper.dart' show findElement;

const MEMORY_SOURCE_FILES = const <String, String>{
  'main.dart': """
@MirrorsUsed(targets: 'Super')
import 'dart:mirrors';
import 'lib.dart';


class Subclass extends Super {
  int _private;

  int magic() => _private++;
}

main() {
  var objects = [new Super(), new Subclass()];
  reflect(objects[0]); // Trigger mirror usage.
}
""",
  'lib.dart': """
class Super {
  int _private;

  int magic() => _private++;
}
"""
};

void main() {
  asyncTest(() async {
    var result = await runCompiler(memorySourceFiles: MEMORY_SOURCE_FILES);
    var compiler = result.compiler;

    dynamic superclass =
        findElement(compiler, 'Super', Uri.parse('memory:lib.dart'));
    dynamic subclass = findElement(compiler, 'Subclass');
    var oracle = compiler.backend.mirrorsData.isMemberAccessibleByReflection;
    print(superclass.lookupMember('_private'));
    Expect.isTrue(oracle(superclass.lookupMember('_private')));
    Expect.isFalse(oracle(subclass.lookupMember('_private')));
  });
}
