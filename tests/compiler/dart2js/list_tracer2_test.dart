// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We used to always nullify the element type of a list we are tracing in
// the presence of a fixed length list constructor call.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/types/types.dart' show ContainerTypeMask;
import 'package:expect/expect.dart';
import 'memory_compiler.dart';
import 'type_mask_test_helper.dart';

const String TEST = r'''
var myList = [42];
main() {
  var a = new List(42);
  return myList[0];
}
''';

void main() {
  runTest({bool useKernel}) async {
    var result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var elementEnvironment = closedWorld.elementEnvironment;

    checkType(String name, type) {
      MemberEntity element = elementEnvironment.lookupLibraryMember(
          elementEnvironment.mainLibrary, name);
      ContainerTypeMask mask = typesInferrer.getTypeOfMember(element);
      Expect.equals(type, simplify(mask.elementType, closedWorld), name);
    }

    checkType('myList', typesInferrer.closedWorld.commonMasks.uint31Type);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
