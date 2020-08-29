// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/inferrer/abstract_value_domain.dart';
import 'package:compiler/src/inferrer/powersets/powersets.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

const String CODE = """
class A extends Comparable {
  int compareTo(x) { return 0; }
}
class B extends Comparable {
  int compareTo(x) { return 0; }
}
class C extends Comparable {
  int compareTo(x) { return 0; }
}
class D extends Comparable {
  int compareTo(x) { return 0; }
}
class E extends Comparable {
  int compareTo(x) { return 0; }
}

var sink;
test(x) {
  if (x.compareTo(x)) {
    sink = x;
  }
}

var sink2;
test2(x) {
  sink2 = x;
  print(x);
}

var sink3;
test3(x) {
  sink3 = x;
  print(x);
}


main() {
  A a = A();
  B b = B();
  C c = C();
  D d = D();
  E e = E();
  test(a);
  test(b);
  test(c);
  test(d);
  test(e);
  test2(-1);
  test2(1);
  test2("x");
  test3([1]);
  test3(0);
  test3(a);
}
""";

main() {
  retainDataForTesting = true;

  runTests() async {
    CompilationResult result = await runCompiler(memorySourceFiles: {
      'main.dart': CODE
    }, options: [
      '--experimental-powersets',
    ]);
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    var results = compiler.globalInference.resultsForTesting;
    JClosedWorld closedWorld = results.closedWorld;
    PowersetDomain powersetDomain = closedWorld.abstractValueDomain;

    checkInterceptor(String name, {AbstractBool result = AbstractBool.True}) {
      var element = findMember(closedWorld, name);
      PowersetValue value = results.resultOfMember(element).type;
      Expect.equals(powersetDomain.isInterceptor(value), result);
    }

    checkInterceptor('sink', result: AbstractBool.False);
    checkInterceptor('sink2');
    checkInterceptor('sink3', result: AbstractBool.Maybe);
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}
