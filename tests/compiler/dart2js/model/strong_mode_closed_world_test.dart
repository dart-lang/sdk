// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/universe/world_builder.dart';
import 'package:compiler/src/world.dart';
import '../memory_compiler.dart';

main() {
  useStrongModeWorldStrategy = true;
  asyncTest(() async {
    print('--test from non-strong mode---------------------------------------');
    await runTest(strongMode: false);
    print('--test from strong mode-------------------------------------------');
    await runTest(strongMode: true);
  });
}

runTest({bool strongMode}) async {
  CompilationResult result = await runCompiler(memorySourceFiles: {
    'main.dart': '''
class A {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class B {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class C extends A {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class D implements B {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class E implements A {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class F extends B {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class G {
  method1() {}
  method2() {}
  get getter => 42;
  set setter(_) {}
}

class H extends Object with G implements A {}

class I {
  method1() {}
  method2() {}
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

main() {
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
}
'''
  }, options: strongMode ? [Flags.strongMode] : []);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;

  Map<String, List<String>> expectedLiveMembersMap = <String, List<String>>{
    'A': strongMode
        ? ['method1', 'getter']
        : ['method1', 'method2', 'getter', 'setter'],
    'B': strongMode
        ? ['method2', 'setter']
        : ['method1', 'method2', 'getter', 'setter'],
    'C': strongMode
        ? ['method1', 'getter']
        : ['method1', 'method2', 'getter', 'setter'],
    'D': strongMode
        ? ['method2', 'setter']
        : ['method1', 'method2', 'getter', 'setter'],
    'G': strongMode
        ? ['method1', 'getter']
        : ['method1', 'method2', 'getter', 'setter'],
    'I': strongMode
        ? ['method1', 'getter']
        : ['method1', 'method2', 'getter', 'setter'],
    'K': strongMode
        ? ['method1', 'getter']
        : ['method1', 'method2', 'getter', 'setter'],
    'N': strongMode ? [] : ['method1', 'getter', 'setter'],
    'P': ['method1', 'getter', 'setter'],
    'Q': ['method3'],
  };

  ClosedWorld closedWorld =
      compiler.resolutionWorldBuilder.closedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;

  elementEnvironment.forEachClass(elementEnvironment.mainLibrary,
      (ClassEntity cls) {
    List<String> expectedLiveMembers =
        expectedLiveMembersMap[cls.name] ?? const <String>[];
    List<String> actualLiveMembers = <String>[];
    closedWorld.processedMembers.forEach((MemberEntity member) {
      if (member.enclosingClass != cls) return;
      if (member.isConstructor) return;
      actualLiveMembers.add(member.name);
    });
    Expect.setEquals(
        expectedLiveMembers,
        actualLiveMembers,
        "Unexpected live members for $cls "
        "in ${strongMode ? 'Dart 2' : 'Dart 1'}. \n"
        "Expected members for ${cls.name}: $expectedLiveMembers\n"
        "Actual members for ${cls.name}  : $actualLiveMembers");
  });
}
