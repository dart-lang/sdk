// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/types/types.dart' show TypeMask, ContainerTypeMask;
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

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
  runTest({bool useKernel}) async {
    var result = await runCompiler(
        memorySourceFiles: TEST, options: useKernel ? [Flags.useKernel] : []);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var elementEnvironment = closedWorld.elementEnvironment;

    checkType(String name, type, length) {
      MemberEntity element = elementEnvironment.lookupLibraryMember(
          elementEnvironment.mainLibrary, name);
      TypeMask mask = typesInferrer.getTypeOfMember(element);
      Expect.isTrue(mask.isContainer);
      ContainerTypeMask container = mask;
      Expect.equals(type, simplify(container.elementType, closedWorld), name);
      Expect.equals(container.length, length);
    }

    checkType('myList', closedWorld.commonMasks.numType, 42);
    checkType('myOtherList', closedWorld.commonMasks.uint31Type, 32);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
