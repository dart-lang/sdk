// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart' show
    MessageKind;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/modelx.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/universe/call_structure.dart' show
    CallStructure;
import 'package:compiler/src/universe/selector.dart' show
    Selector;
import 'package:compiler/src/world.dart';

import 'mock_compiler.dart';
import 'mock_libraries.dart';

Future<Compiler> applyPatch(String script, String patch,
                            {bool analyzeAll: false,
                             bool analyzeOnly: false,
                             bool runCompiler: false,
                             String main: "",
                             String patchVersion}) {
  Map<String, String> core = <String, String>{'script': script};
  MockCompiler compiler = new MockCompiler.internal(coreSource: core,
                                                    analyzeAll: analyzeAll,
                                                    analyzeOnly: analyzeOnly,
                                                    patchVersion: patchVersion);
  compiler.diagnosticHandler = createHandler(compiler, '');
  var uri = Uri.parse("patch:core");
  compiler.registerSource(uri, "$DEFAULT_PATCH_CORE_SOURCE\n$patch");
  var future;
  if (runCompiler) {
    future = compiler.run(null, main);
  } else {
    future = compiler.init(main);
  }
  return future.then((_) => compiler);
}

void expectHasBody(compiler, ElementX element) {
    var node = element.parseNode(compiler.parsing);
    Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
    Expect.isNotNull(node.body);
    // If the element has a body it is either a Block or a Return statement,
    // both with different begin and end tokens.
    Expect.isTrue(node.body is Block || node.body is Return);
    Expect.notEquals(node.body.getBeginToken(), node.body.getEndToken());
}

void expectHasNoBody(compiler, ElementX element) {
    var node = element.parseNode(compiler.parsing);
    Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
    Expect.isFalse(node.hasBody());
}

Element ensure(compiler,
               String name,
               Element lookup(name),
               {bool expectIsPatched: false,
                bool expectIsPatch: false,
                bool checkHasBody: false,
                bool expectIsGetter: false,
                bool expectIsFound: true,
                bool expectIsRegular: false}) {
  var element = lookup(name);
  if (!expectIsFound) {
    Expect.isNull(element);
    return element;
  }
  Expect.isNotNull(element);
  if (expectIsGetter) {
    Expect.isTrue(element is AbstractFieldElement);
    Expect.isNotNull(element.getter);
    element = element.getter;
  }
  Expect.equals(expectIsPatched, element.isPatched,
      'Unexpected: $element.isPatched = ${element.isPatched}');
  if (expectIsPatched) {
    Expect.isNull(element.origin);
    Expect.isNotNull(element.patch);

    Expect.equals(element, element.declaration);
    Expect.equals(element.patch, element.implementation);

    if (checkHasBody) {
      expectHasNoBody(compiler, element);
      expectHasBody(compiler, element.patch);
    }
  } else {
    Expect.isTrue(element.isImplementation);
  }
  Expect.equals(expectIsPatch, element.isPatch);
  if (expectIsPatch) {
    Expect.isNotNull(element.origin);
    Expect.isNull(element.patch);

    Expect.equals(element.origin, element.declaration);
    Expect.equals(element, element.implementation);

    if (checkHasBody) {
      expectHasBody(compiler, element);
      expectHasNoBody(compiler, element.origin);
    }
  } else {
    Expect.isTrue(element.isDeclaration);
  }
  if (expectIsRegular) {
    Expect.isNull(element.origin);
    Expect.isNull(element.patch);

    Expect.equals(element, element.declaration);
    Expect.equals(element, element.implementation);

    if (checkHasBody) {
      expectHasBody(compiler, element);
    }
  }
  Expect.isFalse(element.isPatched && element.isPatch);
  return element;
}

Future testPatchFunction() async {
  var compiler = await applyPatch(
      "external test();",
      "@patch test() { return 'string'; } ");
  ensure(compiler, "test", compiler.coreLibrary.find,
         expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "test", compiler.coreLibrary.patch.find,
         expectIsPatch: true, checkHasBody: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testPatchFunctionMetadata() async {
  var compiler = await applyPatch(
      """
      const a = 0;
      @a external test();
      """,
      """
      const _b = 1;
      @patch @_b test() {}
      """);
  Element origin = ensure(compiler, "test", compiler.coreLibrary.find,
         expectIsPatched: true, checkHasBody: true);
  Element patch = ensure(compiler, "test", compiler.coreLibrary.patch.find,
         expectIsPatch: true, checkHasBody: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");

  Expect.equals(1, origin.metadata.length,
                "Unexpected origin metadata: ${origin.metadata}.");
  Expect.equals(3, patch.metadata.length,
                "Unexpected patch metadata: ${patch.metadata}.");
}


Future testPatchVersioned() async {
  String fullPatch = "test(){return 'string';}";
  String lazyPatch = "test(){return 'new and improved string';}";

  String patchSource =
      """
      @patch_full $fullPatch
      @patch_lazy $lazyPatch
      """;

  Future test(String patchVersion,
       {String patchText,
        bool expectIsPatched: true,
        String expectedError,
        String defaultPatch: '',
        String expectedInternalError}) async {
    return applyPatch(
        "external test();",
        """
        $defaultPatch
        $patchSource
        """,
        patchVersion: patchVersion).then((compiler) {
        Element origin =
            ensure(compiler, "test", compiler.coreLibrary.find,
                 expectIsPatched: expectIsPatched, checkHasBody: true);
        if (expectIsPatched) {
          AstElement patch =
              ensure(compiler, "test", compiler.coreLibrary.patch.find,
                  expectIsPatch: true, checkHasBody: true);
          Expect.equals(origin.patch, patch);
          Expect.equals(patch.origin, origin);
          Expect.equals(patchText, patch.node.toString());
        }

        compiler.analyzeElement(origin);
        compiler.enqueuer.resolution.emptyDeferredTaskQueue();

        Expect.isTrue(compiler.warnings.isEmpty,
                      "Unexpected warnings: ${compiler.warnings}");
        if (expectedError != null) {
          Expect.equals(expectedError,
                        compiler.errors[0].message.toString());
        } else {
          Expect.isTrue(compiler.errors.isEmpty,
                        "Unexpected errors: ${compiler.errors}");
        }
      }).catchError((error) {
        if (expectedInternalError != null) {
          Expect.equals(
              'Internal Error: $expectedInternalError', error.toString());
        } else {
          throw error;
        }
      });
  }

  await test('full', patchText: fullPatch);
  await test('lazy', patchText: lazyPatch);
  await test('unknown', expectIsPatched: false,
       expectedError: 'External method without an implementation.');
  await test('full',
       defaultPatch: "@patch test(){}",
       expectedInternalError: "Trying to patch a function more than once.");
}

Future testPatchConstructor() async {
  var compiler = await applyPatch(
      """
      class Class {
        external Class();
      }
      """,
      """
      @patch class Class {
        @patch Class();
      }
      """);
  var classOrigin = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
  classOrigin.ensureResolved(compiler.resolution);
  var classPatch = ensure(compiler, "Class", compiler.coreLibrary.patch.find,
                          expectIsPatch: true);

  Expect.equals(classPatch, classOrigin.patch);
  Expect.equals(classOrigin, classPatch.origin);

  var constructorOrigin = ensure(compiler, "",
                                 (name) => classOrigin.localLookup(name),
                                 expectIsPatched: true);
  var constructorPatch = ensure(compiler, "",
                                (name) => classPatch.localLookup(name),
                                expectIsPatch: true);

  Expect.equals(constructorPatch, constructorOrigin.patch);
  Expect.equals(constructorOrigin, constructorPatch.origin);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testPatchRedirectingConstructor() async {
  var compiler = await applyPatch(
      """
      class Class {
        Class(x) : this._(x, false);

        external Class._(x, y);
      }
      """,
      r"""
      @patch class Class {
        @patch Class._(x, y) { print('$x,$y'); }
      }
      """);
  var classOrigin = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
  classOrigin.ensureResolved(compiler.resolution);

  var classPatch = ensure(compiler, "Class", compiler.coreLibrary.patch.find,
                          expectIsPatch: true);

  Expect.equals(classOrigin, classPatch.origin);
  Expect.equals(classPatch, classOrigin.patch);

  var constructorRedirecting =
      ensure(compiler, "",
             (name) => classOrigin.localLookup(name));
  var constructorOrigin =
      ensure(compiler, "_",
             (name) => classOrigin.localLookup(name),
             expectIsPatched: true);
  var constructorPatch =
      ensure(compiler, "_",
             (name) => classPatch.localLookup(name),
             expectIsPatch: true);
  Expect.equals(constructorOrigin, constructorPatch.origin);
  Expect.equals(constructorPatch, constructorOrigin.patch);

  compiler.resolver.resolve(constructorRedirecting);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testPatchMember() async {
  var compiler = await applyPatch(
      """
      class Class {
        external String toString();
      }
      """,
      """
      @patch class Class {
        @patch String toString() => 'string';
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         expectIsPatch: true);

  ensure(compiler, "toString", container.lookupLocalMember,
         expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "toString", container.patch.lookupLocalMember,
         expectIsPatch: true, checkHasBody: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testPatchGetter() async {
  var compiler = await applyPatch(
      """
      class Class {
        external int get field;
      }
      """,
      """
      @patch class Class {
        @patch int get field => 5;
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);
  ensure(compiler,
         "field",
         container.lookupLocalMember,
         expectIsGetter: true,
         expectIsPatched: true,
         checkHasBody: true);
  ensure(compiler,
         "field",
         container.patch.lookupLocalMember,
         expectIsGetter: true,
         expectIsPatch: true,
         checkHasBody: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testRegularMember() async {
  var compiler = await applyPatch(
      """
      class Class {
        void regular() {}
      }
      """,
      """
      @patch class Class {
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         expectIsPatch: true);

  ensure(compiler, "regular", container.lookupLocalMember,
         checkHasBody: true, expectIsRegular: true);
  ensure(compiler, "regular", container.patch.lookupLocalMember,
         checkHasBody: true, expectIsRegular: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testInjectedMember() async {
  var compiler = await applyPatch(
      """
      class Class {
      }
      """,
      """
      @patch class Class {
        void _injected() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         expectIsPatch: true);

  ensure(compiler, "_injected", container.lookupLocalMember,
         expectIsFound: false);
  ensure(compiler, "_injected", container.patch.lookupLocalMember,
         checkHasBody: true, expectIsRegular: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testInjectedPublicMember() async {
  var compiler = await applyPatch(
      """
      class Class {
      }
      """,
      """
      @patch class Class {
        void injected() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         expectIsPatch: true);

  ensure(compiler, "injected", container.lookupLocalMember,
         expectIsFound: false);
  ensure(compiler, "injected", container.patch.lookupLocalMember,
         checkHasBody: true, expectIsRegular: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.equals(1, compiler.errors.length,
                "Unexpected errors: ${compiler.errors}");
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.INJECTED_PUBLIC_MEMBER);
}

Future testInjectedFunction() async {
  var compiler = await applyPatch(
      "",
      "int _function() => 5;");
  ensure(compiler,
         "_function",
         compiler.coreLibrary.find,
         expectIsFound: false);
  ensure(compiler,
         "_function",
         compiler.coreLibrary.patch.find,
         checkHasBody: true, expectIsRegular: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty,
                "Unexpected errors: ${compiler.errors}");
}

Future testInjectedPublicFunction() async {
  var compiler = await applyPatch(
      "",
      "int function() => 5;");
  ensure(compiler,
         "function",
         compiler.coreLibrary.find,
         expectIsFound: false);
  ensure(compiler,
         "function",
         compiler.coreLibrary.patch.find,
         checkHasBody: true, expectIsRegular: true);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  Expect.equals(1, compiler.errors.length,
                "Unexpected errors: ${compiler.errors}");
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.INJECTED_PUBLIC_MEMBER);
}

Future testPatchSignatureCheck() async {
  var compiler = await applyPatch(
      """
      class Class {
        external String method1();
        external void method2(String str);
        external void method3(String s1);
        external void method4([String str]);
        external void method5({String str});
        external void method6({String str});
        external void method7([String s1]);
        external void method8({String s1});
        external void method9(String str);
        external void method10([String str]);
        external void method11({String str});
      }
      """,
      """
      @patch class Class {
        @patch int method1() => 0;
        @patch void method2() {}
        @patch void method3(String s2) {}
        @patch void method4([String str, int i]) {}
        @patch void method5() {}
        @patch void method6([String str]) {}
        @patch void method7([String s2]) {}
        @patch void method8({String s2}) {}
        @patch void method9(int str) {}
        @patch void method10([int str]) {}
        @patch void method11({int str}) {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.ensureResolved(compiler.resolution);
  container.parseNode(compiler.parsing);

  void expect(String methodName, List infos, List errors) {
    compiler.clearMessages();
    compiler.resolver.resolveMethodElement(
        ensure(compiler, methodName, container.lookupLocalMember,
            expectIsPatched: true, checkHasBody: true));
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(infos.length, compiler.infos.length,
                  "Unexpected infos: ${compiler.infos} on $methodName");
    for (int i = 0 ; i < infos.length ; i++) {
      Expect.equals(infos[i], compiler.infos[i].message.kind);
    }
    Expect.equals(errors.length, compiler.errors.length,
                  "Unexpected errors: ${compiler.errors} on $methodName");
    for (int i = 0 ; i < errors.length ; i++) {
      Expect.equals(errors[i], compiler.errors[i].message.kind);
    }
  }

  expect("method1", [], [MessageKind.PATCH_RETURN_TYPE_MISMATCH]);
  expect("method2", [],
         [MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH]);
  expect("method3", [MessageKind.PATCH_POINT_TO_PARAMETER],
                    [MessageKind.PATCH_PARAMETER_MISMATCH]);
  expect("method4", [],
         [MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH]);
  expect("method5", [],
         [MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH]);
  expect("method6", [],
         [MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH]);
  expect("method7", [MessageKind.PATCH_POINT_TO_PARAMETER],
                    [MessageKind.PATCH_PARAMETER_MISMATCH]);
  expect("method8", [MessageKind.PATCH_POINT_TO_PARAMETER],
                    [MessageKind.PATCH_PARAMETER_MISMATCH]);
  expect("method9", [MessageKind.PATCH_POINT_TO_PARAMETER],
                    [MessageKind.PATCH_PARAMETER_TYPE_MISMATCH]);
  expect("method10", [MessageKind.PATCH_POINT_TO_PARAMETER],
                     [MessageKind.PATCH_PARAMETER_TYPE_MISMATCH]);
  expect("method11", [MessageKind.PATCH_POINT_TO_PARAMETER],
                     [MessageKind.PATCH_PARAMETER_TYPE_MISMATCH]);
}

Future testExternalWithoutImplementationTopLevel() async {
  var compiler = await applyPatch(
      """
      external void foo();
      """,
      """
      // @patch void foo() {}
      """);
  var function = ensure(compiler, "foo", compiler.coreLibrary.find);
  compiler.resolver.resolve(function);
  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testExternalWithoutImplementationTopLevel:${compiler.errors}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind ==
          MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
  Expect.stringEquals('External method without an implementation.',
                      compiler.errors[0].message.toString());
}

Future testExternalWithoutImplementationMember() async {
  var compiler = await applyPatch(
      """
      class Class {
        external void foo();
      }
      """,
      """
      @patch class Class {
        // @patch void foo() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "foo", container.lookupLocalMember));
  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testExternalWithoutImplementationMember:${compiler.errors}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind ==
          MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
  Expect.stringEquals('External method without an implementation.',
                      compiler.errors[0].message.toString());
}

Future testIsSubclass() async {
  var compiler = await applyPatch(
      """
      class A {}
      """,
      """
      @patch class A {}
      """);
  ClassElement cls = ensure(compiler, "A", compiler.coreLibrary.find,
                            expectIsPatched: true);
  ClassElement patch = cls.patch;
  Expect.isTrue(cls != patch);
  Expect.isTrue(cls.isSubclassOf(patch));
  Expect.isTrue(patch.isSubclassOf(cls));
}

Future testPatchNonExistingTopLevel() async {
  var compiler = await applyPatch(
      """
      // class Class {}
      """,
      """
      @patch class Class {}
      """);
  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testPatchNonExistingTopLevel:${compiler.errors}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXISTING);
}

Future testPatchNonExistingMember() async {
  var compiler = await applyPatch(
      """
      class Class {}
      """,
      """
      @patch class Class {
        @patch void foo() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testPatchNonExistingMember:${compiler.errors}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXISTING);
}

Future testPatchNonPatchablePatch() async {
  var compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch var foo;
      """);
  ensure(compiler, "foo", compiler.coreLibrary.find);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testPatchNonPatchablePatch:${compiler.errors}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NONPATCHABLE);
}

Future testPatchNonPatchableOrigin() async {
  var compiler = await applyPatch(
      """
      external var foo;
      """,
      """
      @patch get foo => 0;
      """);
  ensure(compiler, "foo", compiler.coreLibrary.find);

  Expect.isTrue(compiler.warnings.isEmpty,
                "Unexpected warnings: ${compiler.warnings}");
  print('testPatchNonPatchableOrigin:${compiler.errors}');
  Expect.equals(2, compiler.errors.length);
  Expect.equals(
      MessageKind.EXTRANEOUS_MODIFIER, compiler.errors[0].message.kind);
  Expect.equals(
      // TODO(ahe): Eventually, this error should be removed as it will be
      // handled by the regular parser.
      MessageKind.PATCH_NONPATCHABLE, compiler.errors[1].message.kind);
}

Future testPatchNonExternalTopLevel() async {
  var compiler = await applyPatch(
      """
      void foo() {}
      """,
      """
      @patch void foo() {}
      """);
  print('testPatchNonExternalTopLevel.errors:${compiler.errors}');
  print('testPatchNonExternalTopLevel.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXTERNAL);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(compiler.infos[0].message.kind ==
      MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchNonExternalMember() async {
  var compiler = await applyPatch(
      """
      class Class {
        void foo() {}
      }
      """,
      """
      @patch class Class {
        @patch void foo() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         expectIsPatched: true);
  container.parseNode(compiler.parsing);

  print('testPatchNonExternalMember.errors:${compiler.errors}');
  print('testPatchNonExternalMember.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXTERNAL);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(compiler.infos[0].message.kind ==
      MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchNonClass() async {
  var compiler = await applyPatch(
      """
      external void Class() {}
      """,
      """
      @patch class Class {}
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_CLASS);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_CLASS);
}

Future testPatchNonGetter() async {
  var compiler = await applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch get foo => 0;
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_GETTER);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_GETTER);
}

Future testPatchNoGetter() async {
  var compiler = await applyPatch(
      """
      external set foo(var value) {}
      """,
      """
      @patch get foo => 0;
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NO_GETTER);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_GETTER);
}

Future testPatchNonSetter() async {
  var compiler = await applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch set foo(var value) {}
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_SETTER);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_SETTER);
}

Future testPatchNoSetter() async {
  var compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch set foo(var value) {}
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NO_SETTER);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_SETTER);
}

Future testPatchNonFunction() async {
  var compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch void foo() {}
      """);
  print('testPatchNonClass.errors:${compiler.errors}');
  print('testPatchNonClass.warnings:${compiler.warnings}');
  Expect.equals(1, compiler.errors.length);
  Expect.isTrue(
      compiler.errors[0].message.kind == MessageKind.PATCH_NON_FUNCTION);
  Expect.equals(0, compiler.warnings.length);
  Expect.equals(1, compiler.infos.length);
  Expect.isTrue(
      compiler.infos[0].message.kind ==
          MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchAndSelector() async {
  var compiler = await applyPatch(
      """
      class A {
        external void clear();
      }
      class B extends A {
      }
      """,
      """
      @patch class A {
        int method() => 0;
        @patch void clear() {}
      }
      """,
      main: """
      main () {
        new A(); // ensure A and B are instantiated
        new B();
      }
      """,
      runCompiler: true, analyzeOnly: true);
  World world = compiler.world;

  ClassElement cls = ensure(compiler, "A", compiler.coreLibrary.find,
                            expectIsPatched: true);
  cls.ensureResolved(compiler.resolution);

  ensure(compiler, "method", cls.patch.lookupLocalMember,
         checkHasBody: true, expectIsRegular: true);

  ensure(compiler, "clear", cls.lookupLocalMember,
         checkHasBody: true, expectIsPatched: true);

  compiler.phase = Compiler.PHASE_DONE_RESOLVING;

  // Check that a method just in the patch class is a target for a
  // typed selector.
  Selector selector =
      new Selector.call(const PublicName('method'), CallStructure.NO_ARGS);
  TypeMask typeMask = new TypeMask.exact(cls, world);
  FunctionElement method = cls.implementation.lookupLocalMember('method');
  method.computeType(compiler.resolution);
  Expect.isTrue(selector.applies(method, world));
  Expect.isTrue(typeMask.canHit(method, selector, world));

  // Check that the declaration method in the declaration class is a target
  // for a typed selector.
  selector =
      new Selector.call(const PublicName('clear'), CallStructure.NO_ARGS);
  typeMask = new TypeMask.exact(cls, world);
  method = cls.lookupLocalMember('clear');
  method.computeType(compiler.resolution);
  Expect.isTrue(selector.applies(method, world));
  Expect.isTrue(typeMask.canHit(method, selector, world));

  // Check that the declaration method in the declaration class is a target
  // for a typed selector on a subclass.
  cls = ensure(compiler, "B", compiler.coreLibrary.find);
  cls.ensureResolved(compiler.resolution);
  typeMask = new TypeMask.exact(cls, world);
  Expect.isTrue(selector.applies(method, world));
  Expect.isTrue(typeMask.canHit(method, selector, world));
}

Future testAnalyzeAllInjectedMembers() async {
  Future expect(String patchText, [expectedWarnings]) async {
    if (expectedWarnings == null) expectedWarnings = [];
    if (expectedWarnings is! List) {
      expectedWarnings = <MessageKind>[expectedWarnings];
    }

    var compiler = await applyPatch('', patchText, analyzeAll: true,
               analyzeOnly: true);
      compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
    await compiler.run(null);
    compareWarningKinds(patchText, expectedWarnings, compiler.warnings);
  }

  await expect('String s = 0;', MessageKind.NOT_ASSIGNABLE);
  await expect('void method() { String s = 0; }', MessageKind.NOT_ASSIGNABLE);
  await expect('''
         class Class {
           String s = 0;
         }
         ''',
         MessageKind.NOT_ASSIGNABLE);
  await expect('''
         class Class {
           void method() {
             String s = 0;
           }
         }
         ''',
         MessageKind.NOT_ASSIGNABLE);
}

Future testEffectiveTarget() async {
  String origin = """
    class A {
      A() : super();
      factory A.forward() = B.patchTarget;
      factory A.forwardTwo() = B.reflectBack;
    }
    class B extends A {
      B() : super();
      external B.patchTarget();
      external factory B.reflectBack();
      B.originTarget() : super();
    }
    """;
  String patch = """
    @patch class B {
      @patch
      B.patchTarget() : super();
      @patch
      factory B.reflectBack() = B.originTarget;
    }
    """;

  var compiler = await applyPatch(origin, patch, analyzeAll: true,
                 analyzeOnly: true, runCompiler: true);
  ClassElement clsA = compiler.coreLibrary.find("A");
  ClassElement clsB = compiler.coreLibrary.find("B");

  ConstructorElement forward = clsA.lookupConstructor("forward");
  ConstructorElement target = forward.effectiveTarget;
  Expect.isTrue(target.isPatch);
  Expect.equals("patchTarget", target.name);

  ConstructorElement forwardTwo = clsA.lookupConstructor("forwardTwo");
  target = forwardTwo.effectiveTarget;
  Expect.isFalse(forwardTwo.isMalformed);
  Expect.isFalse(target.isPatch);
  Expect.equals("originTarget", target.name);
}

Future testTypecheckPatchedMembers() async {
  String originText = "external void method();";
  String patchText = """
                     @patch void method() {
                       String s = 0;
                     }
                     """;
  var compiler = await applyPatch(originText, patchText,
             analyzeAll: true, analyzeOnly: true);
  compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
  await compiler.run(null);
  compareWarningKinds(patchText,
      [MessageKind.NOT_ASSIGNABLE], compiler.warnings);
}

main() {
  asyncTest(() async {
    await testPatchConstructor();
    await testPatchRedirectingConstructor();
    await testPatchFunction();
    await testPatchFunctionMetadata();
    await testPatchMember();
    await testPatchGetter();
    await testRegularMember();
    await testInjectedMember();
    await testInjectedPublicMember();
    await testInjectedFunction();
    await testInjectedPublicFunction();
    await testPatchSignatureCheck();

    await testPatchVersioned();

    await testExternalWithoutImplementationTopLevel();
    await testExternalWithoutImplementationMember();

    await testIsSubclass();

    await testPatchNonExistingTopLevel();
    await testPatchNonExistingMember();
    await testPatchNonPatchablePatch();
    await testPatchNonPatchableOrigin();
    await testPatchNonExternalTopLevel();
    await testPatchNonExternalMember();
    await testPatchNonClass();
    await testPatchNonGetter();
    await testPatchNoGetter();
    await testPatchNonSetter();
    await testPatchNoSetter();
    await testPatchNonFunction();

    await testPatchAndSelector();

    await testEffectiveTarget();

    await testAnalyzeAllInjectedMembers();
    await testTypecheckPatchedMembers();
  });
}
