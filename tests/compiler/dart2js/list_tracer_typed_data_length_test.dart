// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/types/types.dart' show ContainerTypeMask, TypeMask;
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;

import 'memory_compiler.dart';
import 'compiler_helper.dart' show findElement;
import 'type_mask_test_helper.dart';

const TEST = const {
  'main.dart': r'''
import 'dart:typed_data';

var myList = new Float32List(42);
var myOtherList = new Uint8List(32);

main() {
  var a = new Float32List(9);
  return myList[0] + myOtherList[0];
}
'''
};

void main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(memorySourceFiles: TEST);
    Compiler compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    ClosedWorld closedWorld = typesInferrer.closedWorld;

    checkType(String name, type, length) {
      MemberElement element = findElement(compiler, name);
      TypeMask mask = typesInferrer.getTypeOfMember(element);
      Expect.isTrue(mask.isContainer);
      ContainerTypeMask container = mask;
      Expect.equals(type, simplify(container.elementType, closedWorld), name);
      Expect.equals(container.length, length);
    }

    checkType('myList', closedWorld.commonMasks.numType, 42);
    checkType('myOtherList', closedWorld.commonMasks.uint31Type, 32);
  });
}
