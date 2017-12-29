// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import '../memory_compiler.dart';
import '../type_mask_test_helper.dart';

const String TEST = '''
int closure(int x) {
  return x;
}

class A {
  static const DEFAULT = const {'fun' : closure};

  final map;

  A([maparg]) : map = maparg == null ? DEFAULT : maparg;
}

main() {
  var a = new A();
  a.map['fun'](3.3);
  print(closure(22));
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
    var commonMasks = closedWorld.commonMasks;

    MemberEntity element = elementEnvironment.lookupLibraryMember(
        elementEnvironment.mainLibrary, 'closure');
    var mask = typesInferrer.getReturnTypeOfMember(element);
    Expect.equals(commonMasks.numType, simplify(mask, closedWorld));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
