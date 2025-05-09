// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library jsinterop.internal_annotations_test;

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'package:compiler/src/common/elements.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart' show ClassEntity;
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/universe/class_hierarchy.dart';
import 'package:compiler/src/universe/selector.dart';
import 'package:compiler/src/js_model/js_world.dart' show JClosedWorld;
import '../helpers/element_lookup.dart';
import 'package:compiler/src/util/memory_compiler.dart';

void main() {
  asyncTest(() async {
    await testClasses('package:js/js.dart', 'dart:_js_annotations');
    await testClasses('package:js/js.dart', 'package:js/js.dart');
    await testClasses('dart:_js_annotations', 'dart:_js_annotations');
  });
}

testClasses(String import1, String import2) async {
  test(
    String mainSource, {
    List<String> directlyInstantiated = const <String>[],
    List<String> abstractlyInstantiated = const <String>[],
    List<String> indirectlyInstantiated = const <String>[],
  }) async {
    String mainFile = 'sdk/tests/web/native/main.dart';
    Uri entryPoint = Uri.parse('memory:$mainFile');
    CompilationResult result = await runCompiler(
      entryPoint: entryPoint,
      memorySourceFiles: {
        mainFile:
            """
import '$import1' as js1;
import '$import2' as js2;

@js1.JS()
class A {
  external get foo;

  external A(var foo);
}

@js2.JS('BClass')
class B {
  external get foo;

  external B(var foo);
}

@js1.JS()
@js1.anonymous
class C {
  external get foo;

  external factory C({foo});
}

@js2.JS()
@js2.anonymous
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

newA() => A(0);
newB() => B(1);
newC() => C(foo: 2);
newD() => D(foo: 3);
newE() => E(4);
newF() => F(5);

$mainSource
""",
      },
    );
    Compiler compiler = result.compiler!;
    Map<String, ClassEntity> classEnvironment = <String, ClassEntity>{};

    ClassEntity registerClass(ClassEntity cls) {
      classEnvironment[cls.name] = cls;
      return cls;
    }

    JClosedWorld world = compiler.backendClosedWorldForTesting!;
    ElementEnvironment elementEnvironment = world.elementEnvironment;
    ClassEntity Object_ = registerClass(world.commonElements.objectClass);
    ClassEntity Interceptor = registerClass(
      world.commonElements.jsInterceptorClass,
    );
    ClassEntity JavaScriptObject = registerClass(
      world.commonElements.jsJavaScriptObjectClass,
    );
    ClassEntity LegacyJavaScriptObject = registerClass(
      world.commonElements.jsLegacyJavaScriptObjectClass,
    );
    ClassEntity A = registerClass(findClass(world, 'A'));
    ClassEntity B = registerClass(findClass(world, 'B'));
    ClassEntity C = registerClass(findClass(world, 'C'));
    ClassEntity D = registerClass(findClass(world, 'D'));
    ClassEntity E = registerClass(findClass(world, 'E'));
    ClassEntity F = registerClass(findClass(world, 'F'));

    Selector nonExisting = Selector.getter(const PublicName('nonExisting'));

    Expect.equals(elementEnvironment.getSuperClass(Interceptor), Object_);
    Expect.equals(
      elementEnvironment.getSuperClass(JavaScriptObject),
      Interceptor,
    );
    Expect.equals(
      elementEnvironment.getSuperClass(LegacyJavaScriptObject),
      JavaScriptObject,
    );

    Expect.equals(elementEnvironment.getSuperClass(A), LegacyJavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(B), LegacyJavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(C), LegacyJavaScriptObject);
    Expect.equals(elementEnvironment.getSuperClass(D), LegacyJavaScriptObject);
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

    classEnvironment.forEach((name, cls) {
      bool isInstantiated = false;
      if (directlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
          world.classHierarchy.isDirectlyInstantiated(cls),
          "Expected $name to be directly instantiated in `${mainSource}`:"
          "\n${world.classHierarchy.dump(cls)}",
        );
      }
      if (abstractlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
          world.classHierarchy.isAbstractlyInstantiated(cls),
          "Expected $name to be abstractly instantiated in `${mainSource}`:"
          "\n${world.classHierarchy.dump(cls)}",
        );
        Expect.isTrue(
          world.needsNoSuchMethod(cls, nonExisting, ClassQuery.exact),
          "Expected $name to need noSuchMethod for $nonExisting.",
        );
        Expect.isTrue(
          world.needsNoSuchMethod(cls, nonExisting, ClassQuery.subclass),
          "Expected $name to need noSuchMethod for $nonExisting.",
        );
        Expect.isTrue(
          world.needsNoSuchMethod(cls, nonExisting, ClassQuery.subtype),
          "Expected $name to need noSuchMethod for $nonExisting.",
        );
      }
      if (indirectlyInstantiated.contains(name)) {
        isInstantiated = true;
        Expect.isTrue(
          world.classHierarchy.isIndirectlyInstantiated(cls),
          "Expected $name to be indirectly instantiated in `${mainSource}`:"
          "\n${world.classHierarchy.dump(cls)}",
        );
      }
      // Classes that are expected to be instantiated by default. `Object` and
      // `Interceptor` are base types for non-native and native types, and
      // `JavaScriptObject` is the base type for `dart:html` types.
      var instantiatedBaseClasses = [
        'Object',
        'Interceptor',
        'JavaScriptObject',
      ];
      if (!isInstantiated && !instantiatedBaseClasses.contains(name)) {
        Expect.isFalse(
          world.classHierarchy.isInstantiated(cls),
          "Expected $name to be uninstantiated in `${mainSource}`:"
          "\n${world.classHierarchy.dump(cls)}",
        );
      }
    });
  }

  await test('main() {}');

  await test(
    'main() => newA();',
    abstractlyInstantiated: ['A', 'B', 'C', 'D'],
    indirectlyInstantiated: [
      'Object',
      'Interceptor',
      'JavaScriptObject',
      'LegacyJavaScriptObject',
    ],
  );

  await test(
    'main() => newB();',
    abstractlyInstantiated: ['A', 'B', 'C', 'D'],
    indirectlyInstantiated: [
      'Object',
      'Interceptor',
      'JavaScriptObject',
      'LegacyJavaScriptObject',
    ],
  );

  await test(
    'main() => newC();',
    abstractlyInstantiated: ['A', 'B', 'C', 'D'],
    indirectlyInstantiated: [
      'Object',
      'Interceptor',
      'JavaScriptObject',
      'LegacyJavaScriptObject',
    ],
  );

  await test(
    'main() => newD();',
    abstractlyInstantiated: ['A', 'B', 'C', 'D'],
    indirectlyInstantiated: [
      'Object',
      'Interceptor',
      'JavaScriptObject',
      'LegacyJavaScriptObject',
    ],
  );

  await test('main() => newE();', directlyInstantiated: ['E']);

  await test('main() => newF();', directlyInstantiated: ['F']);

  await test(
    'main() => [newD(), newE()];',
    directlyInstantiated: ['E'],
    abstractlyInstantiated: ['A', 'B', 'C', 'D'],
    indirectlyInstantiated: [
      'Object',
      'Interceptor',
      'JavaScriptObject',
      'LegacyJavaScriptObject',
    ],
  );
}
