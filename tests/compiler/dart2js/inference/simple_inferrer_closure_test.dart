// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = """
returnInt1() {
  var a = 42;
  var f = () {
    return a;
  };
  return a;
}

returnDyn1() {
  var a = 42;
  var f = () {
    a = {};
  };
  return a;
}

returnInt2() {
  var a = 42;
  var f = () {
    a = 54;
  };
  return a;
}

returnDyn2() {
  var a = 42;
  var f = () {
    a = 54;
  };
  var g = () {
    a = {};
  };
  return a;
}

returnInt3() {
  var a = 42;
  if (a == 53) {
    var f = () {
      return a;
    };
  }
  return a;
}

returnDyn3() {
  var a = 42;
  if (a == 53) {
    var f = () {
      a = {};
    };
  }
  return a;
}

returnInt4() {
  var a = 42;
  g() { return a; }
  return g();
}

returnNum1() {
  var a = 42.5;
  try {
    g() {
      var b = {};
      b = 42;
      return b;
    }
    a = g();
  } finally {
  }
  return a;
}

returnIntOrNull() {
  for (var b in [42]) {
    var bar = 42;
    f() => bar;
    bar = null;
    return f();
  }
  return 42;
}

class A {
  foo() {
    f() => this;
    return f();
  }
}

main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnNum1();
  returnIntOrNull();
  new A().foo();
}
""";

void main() {
  runTest({bool useKernel}) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    Expect.isTrue(result.isSuccess);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;

    checkReturn(String name, type) {
      MemberEntity element = findMember(closedWorld, name);
      Expect.equals(
          type,
          simplify(typesInferrer.getReturnTypeOfMember(element), closedWorld),
          name);
    }

    checkReturn('returnInt1', closedWorld.commonMasks.uint31Type);
    checkReturn('returnInt2', closedWorld.commonMasks.uint31Type);
    checkReturn('returnInt3', closedWorld.commonMasks.uint31Type);
    checkReturn('returnInt4', closedWorld.commonMasks.uint31Type);
    checkReturn(
        'returnIntOrNull', closedWorld.commonMasks.uint31Type.nullable());

    checkReturn(
        'returnDyn1', closedWorld.commonMasks.dynamicType.nonNullable());
    checkReturn(
        'returnDyn2', closedWorld.commonMasks.dynamicType.nonNullable());
    checkReturn(
        'returnDyn3', closedWorld.commonMasks.dynamicType.nonNullable());
    checkReturn('returnNum1', closedWorld.commonMasks.numType);

    checkReturnInClass(String className, String methodName, type) {
      var element = findClassMember(closedWorld, className, methodName);
      Expect.equals(type,
          simplify(typesInferrer.getReturnTypeOfMember(element), closedWorld));
    }

    dynamic cls = findClass(closedWorld, 'A');
    checkReturnInClass('A', 'foo', new TypeMask.nonNullExact(cls, closedWorld));
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}
