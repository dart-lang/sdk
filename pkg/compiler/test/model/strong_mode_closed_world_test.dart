// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/kernel/kernel_world.dart';
import 'package:compiler/src/util/memory_compiler.dart';

main() {
  asyncTest(() async {
    await runTest();
  });
}

runTest() async {
  // Pretend this is a web/native test to allow use of 'native' keyword
  // and import of private libraries.
  String main = 'sdk/tests/web/native/main.dart';
  Uri entryPoint = Uri.parse('memory:$main');

  CompilationResult result =
      await runCompiler(entryPoint: entryPoint, memorySourceFiles: {
    main: '''
class A {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class B {
  method1() {}
  method2() {}
  method5() {}
  get getter => 42;
  set setter(_) {}
}

class C extends A {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class D implements B {
  method1() {}
  method2() {}
  method5() {}
  get getter => 42;
  set setter(_) {}
}

class E implements A {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class F extends B {
  method1() {}
  method2() {}
  method5() {}
  get getter => 42;
  set setter(_) {}
}

mixin G {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class H extends Object with G implements A {}

class I {
  method1() {}
  method2() {}
  method4() {}
  get getter => 42;
  set setter(_) {}
}

class J extends I implements A {}

mixin K {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

mixin class L = Object with K;
class L2 = Object with L;
class M extends L {}
class M2 extends L2 {}

class N {
  method1() {}
  get getter => 42;
  set setter(_) {}
}

abstract class O extends N {}

class P implements O {
  method1() {}
  get getter => 42;
  set setter(_) {}
}

class Q {
  method3() {}
}

class R extends Q {}

class Class1a {
  call(a, b, c) {} // Call structure only used in Class1a and Class2b.
}

class Class1b {
  call(a, b, c) {}
}

class Class2 {
  Class1a? c;
}

main() {
  method1();
  method2();
}

@pragma('dart2js:disableFinal')
method1() {
  A a = A();
  B b = B();
  a.method1();
  a.getter;
  b.method2();
  b.setter = 42;
  C();
  D();
  H();
  J();
  M().method1();
  M2().getter;
  N();
  O o = P();
  o.method1();
  o.getter;
  o.setter = 42;
  R? r;
  r!.method3();
  r = R(); // Create R after call.
  Class1a();
  Class1b();
  Class2().c!(0, 1, 2);
}

method2() {
  A a = A();
  B b = B();
  a.method4();
  b.method5();
}
'''
  });
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler!;

  Map<String, List<String>> expectedLiveMembersMap = <String, List<String>>{
    'A': ['method1', 'getter', 'method4'],
    'B': ['method2', 'setter', 'method5'],
    'C': ['method1', 'getter', 'method4'],
    'D': ['method2', 'setter', 'method5'],
    'G': ['method1', 'getter', 'method4'],
    'I': ['method1', 'getter', 'method4'],
    'K': ['method1', 'getter'],
    'N': [],
    'P': ['method1', 'getter', 'setter'],
    'Q': ['method3'],
    'Class1a': ['call'],
    'Class1b': [],
    'Class2': ['c'],
  };

  KClosedWorld closedWorld = compiler.frontendClosedWorldForTesting!;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  elementEnvironment.forEachClass(elementEnvironment.mainLibrary!,
      (ClassEntity cls) {
    List<String> expectedLiveMembers =
        expectedLiveMembersMap[cls.name] ?? const <String>[];
    List<String> actualLiveMembers = <String>[];
    closedWorld.liveMemberUsage.forEach((MemberEntity member, _) {
      if (member.enclosingClass != cls) return;
      if (member is ConstructorEntity) return;
      actualLiveMembers.add(member.name!);
    });
    Expect.setEquals(
        expectedLiveMembers,
        actualLiveMembers,
        "Unexpected live members for $cls. \n"
        "Expected members for ${cls.name}: $expectedLiveMembers\n"
        "Actual members for ${cls.name}  : $actualLiveMembers");
  });
}
