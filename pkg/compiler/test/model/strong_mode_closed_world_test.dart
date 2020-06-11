// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/world.dart';
import '../helpers/memory_compiler.dart';

main() {
  asyncTest(() async {
    await runTest();
  });
}

runTest() async {
  // Pretend this is a dart2js_native test to allow use of 'native' keyword
  // and import of private libraries.
  String main = 'sdk/tests/dart2js_2/native/main.dart';
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

class G {
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

class K {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class L = Object with K;
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
  Class1a c;
}

main() {
  method1();
  method2();
}

@pragma('dart2js:disableFinal')
method1() {
  A a = new A();
  B b = new B();
  a.method1();
  a.getter;
  b.method2();
  b.setter = 42; 
  new C();
  new D();
  new H();
  new J();
  new M().method1();
  new M2().getter;
  new N();
  O o = new P();
  o.method1(); 
  o.getter;
  o.setter = 42;
  R r;
  r.method3();
  r = new R(); // Create R after call.
  new Class1a();
  new Class1b();
  new Class2().c(0, 1, 2);
}

method2() {
  A a = new A();
  B b = new B();
  a.method4();
  b.method5();
}
'''
  });
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;

  Map<String, List<String>> expectedLiveMembersMap = <String, List<String>>{
    'A': ['method1', 'getter', 'method4'],
    'B': ['method2', 'setter', 'method5'],
    'C': ['method1', 'getter'],
    'D': ['method2', 'setter'],
    'G': ['method1', 'getter'],
    'I': ['method1', 'getter'],
    'K': ['method1', 'getter'],
    'N': [],
    'P': ['method1', 'getter', 'setter'],
    'Q': ['method3'],
    'Class1a': ['call'],
    'Class1b': [],
    'Class2': ['c'],
  };

  KClosedWorld closedWorld = compiler.frontendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  elementEnvironment.forEachClass(elementEnvironment.mainLibrary,
      (ClassEntity cls) {
    List<String> expectedLiveMembers =
        expectedLiveMembersMap[cls.name] ?? const <String>[];
    List<String> actualLiveMembers = <String>[];
    closedWorld.liveMemberUsage.forEach((MemberEntity member, _) {
      if (member.enclosingClass != cls) return;
      if (member.isConstructor) return;
      actualLiveMembers.add(member.name);
    });
    Expect.setEquals(
        expectedLiveMembers,
        actualLiveMembers,
        "Unexpected live members for $cls. \n"
        "Expected members for ${cls.name}: $expectedLiveMembers\n"
        "Actual members for ${cls.name}  : $actualLiveMembers");
  });
}
