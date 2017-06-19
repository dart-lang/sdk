// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/types/masks.dart';
import 'package:compiler/src/world.dart' show ClosedWorld;
import 'package:expect/expect.dart';
import 'memory_compiler.dart';
import 'type_mask_test_helper.dart';

const String SOURCE = '''
main(args) {
  test0();
  test1(args == null);
  test2(args == null);
  test3(args);
}

// Check that `throw` in the message does is handled conditionally.
test0() {
  assert(true, throw "unreachable");
  var list = [];
  return list;
}

// Check that side-effects of the assert message is not included after the
// assert.
test1(b) {
  var a;
  assert(b, a = 42);
  return a;
}

// Check that side-effects of the assert message is included after the assert
// through the thrown exception.
test2(b) {
  var a;
  try {
    assert(b, a = 42);
  } catch (e) {}
  return a;
}

// Check that type tests are preserved after the assert.
test3(a) {
  assert(a is int);
  return a;
}
''';

main() {
  asyncTest(() async {
    CompilationResult result = await runCompiler(
        entryPoint: Uri.parse('memory:main.dart'),
        memorySourceFiles: {'main.dart': SOURCE},
        options: [Flags.enableCheckedMode, Flags.enableAssertMessage]);
    Compiler compiler = result.compiler;
    ClosedWorld closedWorld =
        compiler.resolutionWorldBuilder.closedWorldForTesting;

    void check(String methodName, TypeMask expectedReturnType) {
      LibraryElement mainApp = closedWorld.elementEnvironment.mainLibrary;
      MemberElement element = mainApp.find(methodName);
      TypeMask typeMask = simplify(
          compiler.globalInference.results.resultOfMember(element).returnType,
          closedWorld);
      Expect.equals(expectedReturnType, typeMask,
          "Unexpected return type on method '$methodName'.");
    }

    check('test0', closedWorld.commonMasks.growableListType);
    check('test1', closedWorld.commonMasks.nullType);
    check('test2', closedWorld.commonMasks.uint31Type.nullable());
    check('test3', closedWorld.commonMasks.intType);
  });
}
