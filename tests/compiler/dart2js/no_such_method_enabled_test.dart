// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/js_backend/no_such_method_registry.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import 'kernel/compiler_helper.dart';
import 'compiler_helper.dart';

class NoSuchMethodInfo {
  final String className;
  final String superClassName;
  final bool hasThrowingSyntax;
  final bool hasForwardingSyntax;
  final bool isThrowing;
  final bool isDefault;
  final bool isOther;
  final bool isNotApplicable;
  final bool isComplexNoReturn;
  final bool isComplexReturn;

  const NoSuchMethodInfo(this.className,
      {this.superClassName,
      this.hasThrowingSyntax: false,
      this.hasForwardingSyntax: false,
      this.isThrowing: false,
      this.isDefault: false,
      this.isOther: false,
      this.isNotApplicable: false,
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
class A {
  foo() => 3;
  noSuchMethod(x) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
class A extends B {
  foo() => 3;
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
class A extends B {
  foo() => 3;
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
class A extends B {
  foo() => 3;
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
class A extends B {
  foo() => 3;
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
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x, [y]) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x, [y]) => super.noSuchMethod(x, y);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexNoReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x, y) => super.noSuchMethod(x);
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A',
        hasForwardingSyntax: true, isNotApplicable: true),
  ]),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(Invocation x) {
    throw new UnsupportedException();
  }
}
main() {
  print(new A().foo());
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
  print(new A().foo());
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
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', isOther: true, isComplexReturn: true),
  ], isNoSuchMethodUsed: true),
  const NoSuchMethodTest("""
class A {
  noSuchMethod(x) => super.noSuchMethod(x) as dynamic;
}
main() {
  print(new A().foo());
}
""", const <NoSuchMethodInfo>[
    const NoSuchMethodInfo('A', hasForwardingSyntax: true, isDefault: true),
  ]),
];

main() {
  asyncTest(() async {
    for (NoSuchMethodTest test in TESTS) {
      print('---- testing -------------------------------------------------');
      print(test.code);
      Uri uri = new Uri(scheme: 'source');
      Compiler compiler = compilerFor(test.code, uri);
      await compiler.run(uri);
      checkTest(compiler, test, testComplexReturns: true);
    }

    List<String> sources = <String>[];
    for (NoSuchMethodTest test in TESTS) {
      sources.add(test.code);
    }

    print('---- preparing for kernel tests ----------------------------------');
    List<CompileFunction> results = await compileMultiple(sources);
    for (int index = 0; index < results.length; index++) {
      print('---- testing with kernel --------------------------------------');
      print(sources[index]);
      Compiler compiler = await results[index]();
      compiler.resolutionWorldBuilder.closeWorld();
      // Complex returns are computed during inference.
      checkTest(compiler, TESTS[index], testComplexReturns: false);
    }
  });
}

checkTest(Compiler compiler, NoSuchMethodTest test, {bool testComplexReturns}) {
  ElementEnvironment elementEnvironment =
      compiler.frontendStrategy.elementEnvironment;
  NoSuchMethodRegistryImpl registry = compiler.backend.noSuchMethodRegistry;
  NoSuchMethodResolver resolver = registry.internalResolverForTesting;
  FunctionEntity ObjectNSM = elementEnvironment.lookupClassMember(
      compiler.frontendStrategy.commonElements.objectClass, 'noSuchMethod');
  ClosedWorld closedWorld =
      compiler.resolutionWorldBuilder.closedWorldForTesting;
  NoSuchMethodDataImpl data = closedWorld.noSuchMethodData;

  // Test [NoSuchMethodResolver] results for each method.
  for (NoSuchMethodInfo info in test.methods) {
    ClassEntity cls = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary, info.className);
    Expect.isNotNull(cls, "Class ${info.className} not found.");
    FunctionEntity noSuchMethod =
        elementEnvironment.lookupClassMember(cls, 'noSuchMethod');
    Expect.isNotNull(noSuchMethod, "noSuchMethod not found in $cls.");

    if (info.superClassName == null) {
      Expect.equals(ObjectNSM, resolver.getSuperNoSuchMethod(noSuchMethod));
    } else {
      ClassEntity superclass = elementEnvironment.lookupClass(
          elementEnvironment.mainLibrary, info.superClassName);
      Expect.isNotNull(
          superclass, "Superclass ${info.superClassName} not found.");
      FunctionEntity superNoSuchMethod =
          elementEnvironment.lookupClassMember(superclass, 'noSuchMethod');
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
    ClassEntity cls = elementEnvironment.lookupClass(
        elementEnvironment.mainLibrary, info.className);
    Expect.isNotNull(cls, "Class ${info.className} not found.");
    FunctionEntity noSuchMethod =
        elementEnvironment.lookupClassMember(cls, 'noSuchMethod');
    Expect.isNotNull(noSuchMethod, "noSuchMethod not found in $cls.");

    Expect.equals(info.isDefault, registry.defaultImpls.contains(noSuchMethod),
        "Unexpected isDefault result on $noSuchMethod.");
    Expect.equals(
        info.isThrowing,
        registry.throwingImpls.contains(noSuchMethod),
        "Unexpected isThrowing result on $noSuchMethod.");
    Expect.equals(info.isOther, registry.otherImpls.contains(noSuchMethod),
        "Unexpected isOther result on $noSuchMethod.");
    Expect.equals(
        info.isNotApplicable,
        registry.notApplicableImpls.contains(noSuchMethod),
        "Unexpected isNotApplicable result on $noSuchMethod.");
    if (testComplexReturns) {
      Expect.equals(
          info.isComplexNoReturn,
          data.complexNoReturnImpls.contains(noSuchMethod),
          "Unexpected isComplexNoReturn result on $noSuchMethod.");
      Expect.equals(
          info.isComplexReturn,
          data.complexReturningImpls.contains(noSuchMethod),
          "Unexpected isComplexReturn result on $noSuchMethod.");
    }
  }

  Expect.equals(
      test.isNoSuchMethodUsed,
      closedWorld.backendUsage.isNoSuchMethodUsed,
      "Unexpected isNoSuchMethodUsed result.");
}
