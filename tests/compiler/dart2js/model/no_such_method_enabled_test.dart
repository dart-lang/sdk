// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/no_such_method_registry.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/memory_compiler.dart';

class NoSuchMethodInfo {
  final String className;
  final String superClassName;
  final bool hasThrowingSyntax;
  final bool hasForwardingSyntax;
  final bool isThrowing;
  final bool isDefault;
  final bool isOther;
  final bool isComplexNoReturn;
  final bool isComplexReturn;

  const NoSuchMethodInfo(this.className,
      {this.superClassName,
      this.hasThrowingSyntax: false,
      this.hasForwardingSyntax: false,
      this.isThrowing: false,
      this.isDefault: false,
      this.isOther: false,
      this.isComplexNoReturn: false,
      this.isComplexReturn: false});
}

class NoSuchMethodTest {
  final String code;
  final List<NoSuchMethodInfo> methods;
  final bool isNoSuchMethodUsed;

  const NoSuchMethodTest(this.code, this.methods,
      {this.isNoSuchMethodUsed: false});
}

const List<NoSuchMethodTest> TESTS = const <NoSuchMethodTest>[
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A implements I {
  noSuchMethod(x) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A extends B implements I {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A extends B implements I {
  noSuchMethod(x) {
    return super.noSuchMethod(x);
  }
}
class B {}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A extends B implements I {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {
  noSuchMethod(x) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A',
        superClassName: 'B', hasForwardingSyntax: true, isDefault: true),
    const NoSuchMethodInfo('B', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A extends B implements I {
  noSuchMethod(x) => super.noSuchMethod(x);
}
class B {
  noSuchMethod(x) => throw 'foo';
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A',
        superClassName: 'B', hasForwardingSyntax: true, isThrowing: true),
    const NoSuchMethodInfo('B', hasThrowingSyntax: true, isThrowing: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x) => 3;
}
main() {
  print((new A() as dynamic).foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A implements I {
  noSuchMethod(x, [y]) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A implements I {
  noSuchMethod(x, [y]) => super.noSuchMethod(y);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexNoReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x, [y]) => super.noSuchMethod(x) + y;
}
main() {
  print((new A() as dynamic).foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexNoReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(Invocation x) {
    throw new UnsupportedError('');
  }
}
main() {
  print((new A() as dynamic).foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasThrowingSyntax: true, isThrowing: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(Invocation x) {
    print('foo');
    throw 'foo';
  }
}
main() {
  print((new A() as dynamic).foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexNoReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(Invocation x) {
    return toString();
  }
}
main() {
  print((new A() as dynamic).foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A implements I {
  noSuchMethod(x) => super.noSuchMethod(x) as dynamic;
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
abstract class I {
  foo();
}
class A implements I {
  noSuchMethod(x) => super.noSuchMethod(x) as int;
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexNoReturn: true),
  ], isNoSuchMethodUsed: true),
];

main() {
  runTests() async {
    for (NoSuchMethodTest test in TESTS) {
      print('---- testing -------------------------------------------------');
      print(test.code);
      CompilationResult result =
          await runCompiler(memorySourceFiles: {'main.dart': test.code});
      Expect.isTrue(result.isSuccess);
      Compiler compiler = result.compiler;
      checkTest(compiler, test);
    }
  }

  asyncTest(() async {
    print('--test from kernel------------------------------------------------');
    await runTests();
  });
}

checkTest(Compiler compiler, NoSuchMethodTest test) {
  ElementEnvironment frontendEnvironment =
      compiler.frontendStrategy.elementEnvironment;
  NoSuchMethodRegistryImpl registry =
      compiler.frontendStrategy.noSuchMethodRegistry;
  NoSuchMethodResolver resolver = registry.internalResolverForTesting;
  FunctionEntity ObjectNSM = frontendEnvironment.lookupClassMember(
      compiler.frontendStrategy.commonElements.objectClass, 'noSuchMethod');
  JClosedWorld backendClosedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment backendEnvironment = backendClosedWorld.elementEnvironment;
  NoSuchMethodDataImpl data = backendClosedWorld.noSuchMethodData;

  // Test [NoSuchMethodResolver] results for each method.
  for (NoSuchMethodInfo info in test.methods) {
    ClassEntity cls = frontendEnvironment.lookupClass(
        frontendEnvironment.mainLibrary, info.className);
    Expect.isNotNull(cls, "Class ${info.className} not found.");
    FunctionEntity noSuchMethod =
        frontendEnvironment.lookupClassMember(cls, 'noSuchMethod');
    Expect.isNotNull(noSuchMethod, "noSuchMethod not found in $cls.");

    if (info.superClassName == null) {
      Expect.equals(ObjectNSM, resolver.getSuperNoSuchMethod(noSuchMethod));
    } else {
      ClassEntity superclass = frontendEnvironment.lookupClass(
          frontendEnvironment.mainLibrary, info.superClassName);
      Expect.isNotNull(
          superclass, "Superclass ${info.superClassName} not found.");
      FunctionEntity superNoSuchMethod =
          frontendEnvironment.lookupClassMember(superclass, 'noSuchMethod');
      Expect.isNotNull(
          superNoSuchMethod, "noSuchMethod not found in $superclass.");
      Expect.equals(
          superNoSuchMethod,
          resolver.getSuperNoSuchMethod(noSuchMethod),
          "Unexpected super noSuchMethod for $noSuchMethod.");
    }

    Expect.equals(
        info.hasForwardingSyntax,
        resolver.hasForwardingSyntax(noSuchMethod),
        "Unexpected hasForwardSyntax result on $noSuchMethod.");
    Expect.equals(
        info.hasThrowingSyntax,
        resolver.hasThrowingSyntax(noSuchMethod),
        "Unexpected hasThrowingSyntax result on $noSuchMethod.");
  }

  // Test [NoSuchMethodRegistry] results for each method. These are based on
  // the [NoSuchMethodResolver] results which are therefore tested for all
  // methods first.
  for (NoSuchMethodInfo info in test.methods) {
    ClassEntity frontendClass = frontendEnvironment.lookupClass(
        frontendEnvironment.mainLibrary, info.className);
    Expect.isNotNull(frontendClass, "Class ${info.className} not found.");
    FunctionEntity frontendNoSuchMethod =
        frontendEnvironment.lookupClassMember(frontendClass, 'noSuchMethod');
    Expect.isNotNull(
        frontendNoSuchMethod, "noSuchMethod not found in $frontendClass.");

    Expect.equals(
        info.isDefault,
        registry.defaultImpls.contains(frontendNoSuchMethod),
        "Unexpected isDefault result on $frontendNoSuchMethod.");
    Expect.equals(
        info.isThrowing,
        registry.throwingImpls.contains(frontendNoSuchMethod),
        "Unexpected isThrowing result on $frontendNoSuchMethod.");
    Expect.equals(
        info.isOther,
        registry.otherImpls.contains(frontendNoSuchMethod),
        "Unexpected isOther result on $frontendNoSuchMethod.");

    ClassEntity backendClass = backendEnvironment.lookupClass(
        backendEnvironment.mainLibrary, info.className);
    Expect.isNotNull(backendClass, "Class ${info.className} not found.");
    FunctionEntity backendNoSuchMethod =
        backendEnvironment.lookupClassMember(backendClass, 'noSuchMethod');
    Expect.isNotNull(
        backendNoSuchMethod, "noSuchMethod not found in $backendClass.");

    Expect.equals(
        info.isComplexNoReturn,
        data.complexNoReturnImpls.contains(backendNoSuchMethod),
        "Unexpected isComplexNoReturn result on $backendNoSuchMethod.");
    Expect.equals(
        info.isComplexReturn,
        data.complexReturningImpls.contains(backendNoSuchMethod),
        "Unexpected isComplexReturn result on $backendNoSuchMethod.");
  }

  Expect.equals(
      test.isNoSuchMethodUsed,
      backendClosedWorld.backendUsage.isNoSuchMethodUsed,
      "Unexpected isNoSuchMethodUsed result.");
}
