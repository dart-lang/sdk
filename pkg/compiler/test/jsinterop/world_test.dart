// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library jsinterop.world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common_elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart' show ClassEntity;
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/class_hierarchy.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/world.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

void main() {
  asyncTest(() async {
    await testClasses();
  });
}

testClasses() async {
  test(String mainSource,
      {List<String> directlyInstantiated: const <String>[],
      List<String> abstractlyInstantiated: const <String>[],
      List<String> indirectlyInstantiated: const <String>[]}) async {
    CompilationResult result = await runCompiler(memorySourceFiles: {
      'main.dart': """
import 'package:js/js.dart';

@JS()
class A {
  external get foo;

  external A(var foo);
}

@JS('BClass')
class B {
  external get foo;

  external B(var foo);
}

@JS()
@anonymous
class C {
  external get foo;

  external factory C({foo});
}

@JS()
@anonymous
class D {
  external get foo;

  external factory D({foo});
}

class E {
  final foo;

  E(this.foo);
}

class F {
  final foo;

  F(this.foo);
}

newA() => new A(0);
newB() => new B(1);
newC() => new C(foo: 2);
newD() => new D(foo: 3);
newE() => new E(4);
newF() => new F(5);

$mainSource
"""
    });
    Compiler compiler = result.compiler;
    Map<String, ClassEntity> classEnvironment = <String, ClassEntity>{};

    ClassEntity registerClass(ClassEntity cls) {
      classEnvironment[cls.name] = cls;
      return cls;
    }

    JClosedWorld world = compiler.backendClosedWorldForTesting;
    ElementEnvironment elementEnvironment = world.elementEnvironment;
    ClassEntity Object_ = registerClass(world.commonElements.objectClass);
    ClassEntity Interceptor =
        registerClass(world.commonElements.jsInterceptorClass);
    ClassEntity JavaScriptObject =
        registerClass(world.commonElements.jsJavaScriptObjectClass);
    ClassEntity A = registerClass(findClass(world, 'A'));
    ClassEntity B = registerClass(findClass(world, 'B'));
    ClassEntity C = registerClass(findClass(world, 'C'));
    ClassEntity D = registerClass(findClass(world, 'D'));
    ClassEntity E = registerClass(findClass(world, 'E'));
    ClassEntity F = registerClass(findClass(world, 'F'));

    Selector nonExisting = new Selector.getter(const PublicName('nonExisting'));

    Expect.equals(elementEnvironment.getSuperClass(Interceptor), Object_);
    Expect.equals(
        elementEnvironment.getSuperClass(JavaScriptObject), Interceptor);

    Expect.equals(elementEnvironment.getSuperClass(A), JavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(B), JavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(C), JavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(D), JavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(E), Object_);
    Expect.equals(elementEnvironment.getSuperClass(F), Object_);

    Expect.isFalse(world.nativeData.isJsInteropClass(Object_));
    Expect.isTrue(world.nativeData.isJsInteropClass(A));
    Expect.isTrue(world.nativeData.isJsInteropClass(B));
    Expect.isTrue(world.nativeData.isJsInteropClass(C));
    Expect.isTrue(world.nativeData.isJsInteropClass(D));
    Expect.isFalse(world.nativeData.isJsInteropClass(E));
    Expect.isFalse(world.nativeData.isJsInteropClass(F));

    Expect.isFalse(world.nativeData.isAnonymousJsInteropClass(Object_));
    Expect.isFalse(world.nativeData.isAnonymousJsInteropClass(A));
    Expect.isFalse(world.nativeData.isAnonymousJsInteropClass(B));
    Expect.isTrue(world.nativeData.isAnonymousJsInteropClass(C));
    Expect.isTrue(world.nativeData.isAnonymousJsInteropClass(D));
    Expect.isFalse(world.nativeData.isAnonymousJsInteropClass(E));
    Expect.isFalse(world.nativeData.isAnonymousJsInteropClass(F));

    Expect.equals('', world.nativeData.getJsInteropClassName(A));
    Expect.equals('BClass', world.nativeData.getJsInteropClassName(B));
    Expect.equals('', world.nativeData.getJsInteropClassName(C));
    Expect.equals('', world.nativeData.getJsInteropClassName(D));

    for (String name in classEnvironment.keys) {
      ClassEntity cls = classEnvironment[name];
      bool isInstantiated = false;
      if (directlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.classHierarchy.isDirectlyInstantiated(cls),
            "Expected $name to be directly instantiated in `${mainSource}`:"
            "\n${world.classHierarchy.dump(cls)}");
      }
      if (abstractlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.classHierarchy.isAbstractlyInstantiated(cls),
            "Expected $name to be abstractly instantiated in `${mainSource}`:"
            "\n${world.classHierarchy.dump(cls)}");
        Expect.isTrue(
            world.needsNoSuchMethod(cls, nonExisting, ClassQuery.EXACT),
            "Expected $name to need noSuchMethod for $nonExisting.");
        Expect.isTrue(
            world.needsNoSuchMethod(cls, nonExisting, ClassQuery.SUBCLASS),
            "Expected $name to need noSuchMethod for $nonExisting.");
        Expect.isTrue(
            world.needsNoSuchMethod(cls, nonExisting, ClassQuery.SUBTYPE),
            "Expected $name to need noSuchMethod for $nonExisting.");
      }
      if (indirectlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.classHierarchy.isIndirectlyInstantiated(cls),
            "Expected $name to be indirectly instantiated in `${mainSource}`:"
            "\n${world.classHierarchy.dump(cls)}");
      }
      if (!isInstantiated && (name != 'Object' && name != 'Interceptor')) {
        Expect.isFalse(
            world.classHierarchy.isInstantiated(cls),
            "Expected $name to be uninstantiated in `${mainSource}`:"
            "\n${world.classHierarchy.dump(cls)}");
      }
    }
  }

  await test('main() {}');

  await test('main() => newA();',
      abstractlyInstantiated: ['A', 'B', 'C', 'D'],
      indirectlyInstantiated: ['Object', 'Interceptor', 'JavaScriptObject']);

  await test('main() => newB();',
      abstractlyInstantiated: ['A', 'B', 'C', 'D'],
      indirectlyInstantiated: ['Object', 'Interceptor', 'JavaScriptObject']);

  await test('main() => newC();',
      abstractlyInstantiated: ['A', 'B', 'C', 'D'],
      indirectlyInstantiated: ['Object', 'Interceptor', 'JavaScriptObject']);

  await test('main() => newD();',
      abstractlyInstantiated: ['A', 'B', 'C', 'D'],
      indirectlyInstantiated: ['Object', 'Interceptor', 'JavaScriptObject']);

  await test('main() => newE();', directlyInstantiated: ['E']);

  await test('main() => newF();', directlyInstantiated: ['F']);

  await test('main() => [newD(), newE()];',
      directlyInstantiated: ['E'],
      abstractlyInstantiated: ['A', 'B', 'C', 'D'],
      indirectlyInstantiated: ['Object', 'Interceptor', 'JavaScriptObject']);
}
