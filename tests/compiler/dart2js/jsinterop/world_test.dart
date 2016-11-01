// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsinterop.world_test;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common.dart';
import 'package:compiler/src/elements/elements.dart' show Element, ClassElement;
import 'package:compiler/src/js_backend/js_backend.dart';
import 'package:compiler/src/world.dart';
import '../type_test_helper.dart';

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
    TypeEnvironment env = await TypeEnvironment.create(
        r"""
@JS()
class A {
  get foo;

  external A(var foo);
}

@JS()
class B {
  get foo;

  external B(var foo);
}

@JS()
@anonymous
class C {
  final foo;

  external factory C({foo});
}

@JS()
@anonymous
class D {
  final foo;

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
""",
        mainSource: """
import 'package:js/js.dart';

$mainSource
""",
        useMockCompiler: false);
    Map<String, ClassElement> classEnvironment = <String, ClassElement>{};

    ClassElement registerClass(ClassElement cls) {
      classEnvironment[cls.name] = cls;
      return cls;
    }

    ClosedWorld world = env.compiler.closedWorld;
    JavaScriptBackend backend = env.compiler.backend;
    ClassElement Object_ = registerClass(env.compiler.coreClasses.objectClass);
    ClassElement Interceptor =
        registerClass(backend.helpers.jsInterceptorClass);
    ClassElement JavaScriptObject =
        registerClass(backend.helpers.jsJavaScriptObjectClass);
    ClassElement A = registerClass(env.getElement('A'));
    ClassElement B = registerClass(env.getElement('B'));
    ClassElement C = registerClass(env.getElement('C'));
    ClassElement D = registerClass(env.getElement('D'));
    ClassElement E = registerClass(env.getElement('E'));
    ClassElement F = registerClass(env.getElement('F'));

    Expect.equals(Interceptor.superclass, Object_);
    Expect.equals(JavaScriptObject.superclass, Interceptor);

    Expect.equals(A.superclass, JavaScriptObject);
    Expect.equals(B.superclass, JavaScriptObject);
    Expect.equals(C.superclass, JavaScriptObject);
    Expect.equals(D.superclass, JavaScriptObject);
    Expect.equals(E.superclass, Object_);
    Expect.equals(F.superclass, Object_);

    for (String name in classEnvironment.keys) {
      ClassElement cls = classEnvironment[name];
      bool isInstantiated = false;
      if (directlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.isDirectlyInstantiated(cls),
            "Expected $name to be directly instantiated in `${mainSource}`:"
            "\n${world.dump(cls)}");
      }
      if (abstractlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.isAbstractlyInstantiated(cls),
            "Expected $name to be abstractly instantiated in `${mainSource}`:"
            "\n${world.dump(cls)}");
      }
      if (indirectlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
            world.isIndirectlyInstantiated(cls),
            "Expected $name to be indirectly instantiated in `${mainSource}`:"
            "\n${world.dump(cls)}");
      }
      if (!isInstantiated && (name != 'Object' && name != 'Interceptor')) {
        Expect.isFalse(
            world.isInstantiated(cls),
            "Expected $name to be uninstantiated in `${mainSource}`:"
            "\n${world.dump(cls)}");
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
