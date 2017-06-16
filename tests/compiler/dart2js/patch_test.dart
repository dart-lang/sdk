// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/diagnostics/messages.dart' show MessageKind;
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/elements/modelx.dart';
import 'package:compiler/src/elements/names.dart';
import 'package:compiler/src/tree/tree.dart';
import 'package:compiler/src/types/types.dart';
import 'package:compiler/src/universe/call_structure.dart' show CallStructure;
import 'package:compiler/src/universe/selector.dart' show Selector;
import 'package:compiler/src/world.dart';

import 'mock_compiler.dart';
import 'mock_libraries.dart';

Future<Compiler> applyPatch(String script, String patch,
    {bool analyzeAll: false,
    bool analyzeOnly: false,
    bool runCompiler: false,
    String main: ""}) async {
  Map<String, String> core = <String, String>{'script': script};
  MockCompiler compiler = new MockCompiler.internal(
      coreSource: core, analyzeAll: analyzeAll, analyzeOnly: analyzeOnly);
  compiler.diagnosticHandler = createHandler(compiler, '');
  var uri = Uri.parse("patch:core");
  compiler.registerSource(uri, "$DEFAULT_PATCH_CORE_SOURCE\n$patch");
  if (runCompiler) {
    await compiler.run(null, main);
  } else {
    await compiler.init(main);
  }
  return compiler;
}

void expectHasBody(compiler, ElementX element) {
  dynamic node = element.parseNode(compiler.parsingContext);
  Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
  Expect.isNotNull(node.body);
  // If the element has a body it is either a Block or a Return statement,
  // both with different begin and end tokens.
  Expect.isTrue(node.body is Block || node.body is Return);
  Expect.notEquals(node.body.getBeginToken(), node.body.getEndToken());
}

void expectHasNoBody(compiler, ElementX element) {
  dynamic node = element.parseNode(compiler.parsingContext);
  Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
  Expect.isFalse(node.hasBody);
}

Element ensure(compiler, String name, Element lookup(name),
    {bool expectIsPatched: false,
    bool expectIsPatch: false,
    bool checkHasBody: false,
    bool expectIsGetter: false,
    bool expectIsFound: true,
    bool expectIsRegular: false}) {
  dynamic element = lookup(name);
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
  dynamic compiler = await applyPatch(
      "external test();", "@patch test() { return 'string'; } ");
  ensure(compiler, "test", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "test",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true, checkHasBody: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testPatchFunctionMetadata() async {
  dynamic compiler = await applyPatch(
      """
      const a = 0;
      @a external test();
      """,
      """
      const _b = 1;
      @patch @_b test() {}
      """);
  Element origin = ensure(
      compiler, "test", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true, checkHasBody: true);
  Element patch = ensure(compiler, "test",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true, checkHasBody: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");

  Expect.equals(1, origin.metadata.length,
      "Unexpected origin metadata: ${origin.metadata}.");
  Expect.equals(3, patch.metadata.length,
      "Unexpected patch metadata: ${patch.metadata}.");
}

Future testPatchFunctionGeneric() async {
  dynamic compiler = await applyPatch(
      "external T test<T>();", "@patch T test<T>() { return null; } ");
  Element origin = ensure(
      compiler, "test", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "test",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true, checkHasBody: true);
  compiler.resolver.resolve(origin);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testPatchFunctionGenericExtraTypeVariable() async {
  dynamic compiler = await applyPatch(
      "external T test<T>();", "@patch T test<T, S>() { return null; } ");
  Element origin = ensure(
      compiler, "test", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "test",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true, checkHasBody: true);
  compiler.resolver.resolve(origin);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.PATCH_TYPE_VARIABLES_MISMATCH);
}

Future testPatchFunctionGenericDifferentNames() async {
  dynamic compiler = await applyPatch(
      "external T test<T, S>();", "@patch T test<S, T>() { return null; } ");
  Element origin = ensure(
      compiler, "test", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "test",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true, checkHasBody: true);
  compiler.resolver.resolve(origin);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.PATCH_TYPE_VARIABLES_MISMATCH);
}

Future testPatchConstructor() async {
  dynamic compiler = await applyPatch(
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
  dynamic classOrigin = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  classOrigin.ensureResolved(compiler.resolution);
  dynamic classPatch = ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  Expect.equals(classPatch, classOrigin.patch);
  Expect.equals(classOrigin, classPatch.origin);

  dynamic constructorOrigin = ensure(
      compiler, "", (name) => classOrigin.localLookup(name),
      expectIsPatched: true);
  dynamic constructorPatch = ensure(
      compiler, "", (name) => classPatch.localLookup(name),
      expectIsPatch: true);

  Expect.equals(constructorPatch, constructorOrigin.patch);
  Expect.equals(constructorOrigin, constructorPatch.origin);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testPatchRedirectingConstructor() async {
  dynamic compiler = await applyPatch(
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
  dynamic classOrigin = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  classOrigin.ensureResolved(compiler.resolution);

  dynamic classPatch = ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  Expect.equals(classOrigin, classPatch.origin);
  Expect.equals(classPatch, classOrigin.patch);

  dynamic constructorRedirecting =
      ensure(compiler, "", (name) => classOrigin.localLookup(name));
  dynamic constructorOrigin = ensure(
      compiler, "_", (name) => classOrigin.localLookup(name),
      expectIsPatched: true);
  dynamic constructorPatch = ensure(
      compiler, "_", (name) => classPatch.localLookup(name),
      expectIsPatch: true);
  Expect.equals(constructorOrigin, constructorPatch.origin);
  Expect.equals(constructorPatch, constructorOrigin.patch);

  compiler.resolver.resolve(constructorRedirecting);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testPatchMember() async {
  dynamic compiler = await applyPatch(
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
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  ensure(compiler, "toString", container.lookupLocalMember,
      expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "toString", container.patch.lookupLocalMember,
      expectIsPatch: true, checkHasBody: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testPatchGetter() async {
  dynamic compiler = await applyPatch(
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
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  ensure(compiler, "field", container.lookupLocalMember,
      expectIsGetter: true, expectIsPatched: true, checkHasBody: true);
  ensure(compiler, "field", container.patch.lookupLocalMember,
      expectIsGetter: true, expectIsPatch: true, checkHasBody: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testRegularMember() async {
  dynamic compiler = await applyPatch(
      """
      class Class {
        void regular() {}
      }
      """,
      """
      @patch class Class {
      }
      """);
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  ensure(compiler, "regular", container.lookupLocalMember,
      checkHasBody: true, expectIsRegular: true);
  ensure(compiler, "regular", container.patch.lookupLocalMember,
      checkHasBody: true, expectIsRegular: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testInjectedMember() async {
  dynamic compiler = await applyPatch(
      """
      class Class {
      }
      """,
      """
      @patch class Class {
        void _injected() {}
      }
      """);
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  ensure(compiler, "_injected", container.lookupLocalMember,
      expectIsFound: false);
  ensure(compiler, "_injected", container.patch.lookupLocalMember,
      checkHasBody: true, expectIsRegular: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testInjectedPublicMember() async {
  dynamic compiler = await applyPatch(
      """
      class Class {
      }
      """,
      """
      @patch class Class {
        void injected() {}
      }
      """);
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  ensure(compiler, "Class",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      expectIsPatch: true);

  ensure(compiler, "injected", container.lookupLocalMember,
      expectIsFound: false);
  ensure(compiler, "injected", container.patch.lookupLocalMember,
      checkHasBody: true, expectIsRegular: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.equals(
      1, collector.errors.length, "Unexpected errors: ${collector.errors}");
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.INJECTED_PUBLIC_MEMBER);
}

Future testInjectedFunction() async {
  dynamic compiler = await applyPatch("", "int _function() => 5;");
  ensure(compiler, "_function",
      compiler.resolution.commonElements.coreLibrary.find,
      expectIsFound: false);
  ensure(compiler, "_function",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      checkHasBody: true, expectIsRegular: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.isTrue(
      collector.errors.isEmpty, "Unexpected errors: ${collector.errors}");
}

Future testInjectedPublicFunction() async {
  dynamic compiler = await applyPatch("", "int function() => 5;");
  ensure(
      compiler, "function", compiler.resolution.commonElements.coreLibrary.find,
      expectIsFound: false);
  ensure(compiler, "function",
      compiler.resolution.commonElements.coreLibrary.patch.find,
      checkHasBody: true, expectIsRegular: true);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  Expect.equals(
      1, collector.errors.length, "Unexpected errors: ${collector.errors}");
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.INJECTED_PUBLIC_MEMBER);
}

Future testPatchSignatureCheck() async {
  dynamic compiler = await applyPatch(
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
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.ensureResolved(compiler.resolution);
  container.parseNode(compiler.parsingContext);
  DiagnosticCollector collector = compiler.diagnosticCollector;

  void expect(String methodName, List infos, List errors) {
    collector.clear();
    compiler.resolver.resolveMethodElement(ensure(
        compiler, methodName, container.lookupLocalMember,
        expectIsPatched: true, checkHasBody: true));
    Expect.equals(0, collector.warnings.length);
    Expect.equals(infos.length, collector.infos.length,
        "Unexpected infos: ${collector.infos} on $methodName");
    for (int i = 0; i < infos.length; i++) {
      Expect.equals(infos[i], collector.infos.elementAt(i).message.kind);
    }
    Expect.equals(errors.length, collector.errors.length,
        "Unexpected errors: ${collector.errors} on $methodName");
    for (int i = 0; i < errors.length; i++) {
      Expect.equals(errors[i], collector.errors.elementAt(i).message.kind);
    }
  }

  expect("method1", [], [MessageKind.PATCH_RETURN_TYPE_MISMATCH]);
  expect("method2", [], [MessageKind.PATCH_REQUIRED_PARAMETER_COUNT_MISMATCH]);
  expect("method3", [MessageKind.PATCH_POINT_TO_PARAMETER],
      [MessageKind.PATCH_PARAMETER_MISMATCH]);
  expect("method4", [], [MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH]);
  expect("method5", [], [MessageKind.PATCH_OPTIONAL_PARAMETER_COUNT_MISMATCH]);
  expect("method6", [], [MessageKind.PATCH_OPTIONAL_PARAMETER_NAMED_MISMATCH]);
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
  dynamic compiler = await applyPatch(
      """
      external void foo();
      """,
      """
      // @patch void foo() {}
      """);
  dynamic function = ensure(
      compiler, "foo", compiler.resolution.commonElements.coreLibrary.find);
  compiler.resolver.resolve(function);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testExternalWithoutImplementationTopLevel:${collector.errors}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
  Expect.stringEquals('External method without an implementation.',
      collector.errors.first.message.toString());
}

Future testExternalWithoutImplementationMember() async {
  dynamic compiler = await applyPatch(
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
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  collector.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "foo", container.lookupLocalMember));
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testExternalWithoutImplementationMember:${collector.errors}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(collector.errors.first.message.kind ==
      MessageKind.PATCH_EXTERNAL_WITHOUT_IMPLEMENTATION);
  Expect.stringEquals('External method without an implementation.',
      collector.errors.first.message.toString());
}

Future testIsSubclass() async {
  dynamic compiler = await applyPatch(
      """
      class A {}
      """,
      """
      @patch class A {}
      """);
  ClassElement cls = ensure(
      compiler, "A", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  ClassElement patch = cls.patch;
  Expect.isTrue(cls != patch);
  Expect.isTrue(cls.isSubclassOf(patch));
  Expect.isTrue(patch.isSubclassOf(cls));
}

Future testPatchNonExistingTopLevel() async {
  dynamic compiler = await applyPatch(
      """
      // class Class {}
      """,
      """
      @patch class Class {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testPatchNonExistingTopLevel:${collector.errors}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_EXISTING);
}

Future testPatchNonExistingMember() async {
  dynamic compiler = await applyPatch(
      """
      class Class {}
      """,
      """
      @patch class Class {
        @patch void foo() {}
      }
      """);
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);
  DiagnosticCollector collector = compiler.diagnosticCollector;

  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testPatchNonExistingMember:${collector.errors}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_EXISTING);
}

Future testPatchNonPatchablePatch() async {
  dynamic compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch var foo;
      """);
  ensure(compiler, "foo", compiler.resolution.commonElements.coreLibrary.find);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testPatchNonPatchablePatch:${collector.errors}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NONPATCHABLE);
}

Future testPatchNonPatchableOrigin() async {
  dynamic compiler = await applyPatch(
      """
      external var foo;
      """,
      """
      @patch get foo => 0;
      """);
  ensure(compiler, "foo", compiler.resolution.commonElements.coreLibrary.find);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  Expect.isTrue(
      collector.warnings.isEmpty, "Unexpected warnings: ${collector.warnings}");
  print('testPatchNonPatchableOrigin:${collector.errors}');
  Expect.equals(2, collector.errors.length);
  Expect.equals(
      MessageKind.EXTRANEOUS_MODIFIER, collector.errors.first.message.kind);
  Expect.equals(
      // TODO(ahe): Eventually, this error should be removed as it will be
      // handled by the regular parser.
      MessageKind.PATCH_NONPATCHABLE,
      collector.errors.elementAt(1).message.kind);
}

Future testPatchNonExternalTopLevel() async {
  dynamic compiler = await applyPatch(
      """
      void foo() {}
      """,
      """
      @patch void foo() {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonExternalTopLevel.errors:${collector.errors}');
  print('testPatchNonExternalTopLevel.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_EXTERNAL);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(collector.infos.first.message.kind ==
      MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchNonExternalMember() async {
  dynamic compiler = await applyPatch(
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
  dynamic container = ensure(
      compiler, "Class", compiler.resolution.commonElements.coreLibrary.find,
      expectIsPatched: true);
  container.parseNode(compiler.parsingContext);

  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonExternalMember.errors:${collector.errors}');
  print('testPatchNonExternalMember.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_EXTERNAL);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(collector.infos.first.message.kind ==
      MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchNonClass() async {
  dynamic compiler = await applyPatch(
      """
      external void Class() {}
      """,
      """
      @patch class Class {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_CLASS);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(
      collector.infos.first.message.kind == MessageKind.PATCH_POINT_TO_CLASS);
}

Future testPatchNonGetter() async {
  dynamic compiler = await applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch get foo => 0;
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_GETTER);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(
      collector.infos.first.message.kind == MessageKind.PATCH_POINT_TO_GETTER);
}

Future testPatchNoGetter() async {
  dynamic compiler = await applyPatch(
      """
      external set foo(var value) {}
      """,
      """
      @patch get foo => 0;
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NO_GETTER);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(
      collector.infos.first.message.kind == MessageKind.PATCH_POINT_TO_GETTER);
}

Future testPatchNonSetter() async {
  dynamic compiler = await applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch set foo(var value) {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_SETTER);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(
      collector.infos.first.message.kind == MessageKind.PATCH_POINT_TO_SETTER);
}

Future testPatchNoSetter() async {
  dynamic compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch set foo(var value) {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NO_SETTER);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(
      collector.infos.first.message.kind == MessageKind.PATCH_POINT_TO_SETTER);
}

Future testPatchNonFunction() async {
  dynamic compiler = await applyPatch(
      """
      external get foo;
      """,
      """
      @patch void foo() {}
      """);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  print('testPatchNonClass.errors:${collector.errors}');
  print('testPatchNonClass.warnings:${collector.warnings}');
  Expect.equals(1, collector.errors.length);
  Expect.isTrue(
      collector.errors.first.message.kind == MessageKind.PATCH_NON_FUNCTION);
  Expect.equals(0, collector.warnings.length);
  Expect.equals(1, collector.infos.length);
  Expect.isTrue(collector.infos.first.message.kind ==
      MessageKind.PATCH_POINT_TO_FUNCTION);
}

Future testPatchAndSelector() async {
  dynamic compiler = await applyPatch(
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
      runCompiler: true,
      analyzeOnly: true);
  compiler.closeResolution();
  ClosedWorld world = compiler.resolutionWorldBuilder.closedWorldForTesting;

  ClassElement cls = ensure(
      compiler, "A", compiler.resolution.commonElements.coreLibrary.find,
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
  MethodElement method = cls.implementation.lookupLocalMember('method');
  method.computeType(compiler.resolution);
  Expect.isTrue(selector.applies(method));
  Expect.isTrue(typeMask.canHit(method, selector, world));

  // Check that the declaration method in the declaration class is a target
  // for a typed selector.
  selector =
      new Selector.call(const PublicName('clear'), CallStructure.NO_ARGS);
  typeMask = new TypeMask.exact(cls, world);
  method = cls.lookupLocalMember('clear');
  method.computeType(compiler.resolution);
  Expect.isTrue(selector.applies(method));
  Expect.isTrue(typeMask.canHit(method, selector, world));

  // Check that the declaration method in the declaration class is a target
  // for a typed selector on a subclass.
  cls = ensure(
      compiler, "B", compiler.resolution.commonElements.coreLibrary.find);
  cls.ensureResolved(compiler.resolution);
  typeMask = new TypeMask.exact(cls, world);
  Expect.isTrue(selector.applies(method));
  Expect.isTrue(typeMask.canHit(method, selector, world));
}

Future testAnalyzeAllInjectedMembers() async {
  Future expect(String patchText, [expectedWarnings]) async {
    if (expectedWarnings == null) expectedWarnings = [];
    if (expectedWarnings is! List) {
      expectedWarnings = <MessageKind>[expectedWarnings];
    }

    dynamic compiler =
        await applyPatch('', patchText, analyzeAll: true, analyzeOnly: true);
    compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
    await compiler.run(null);
    DiagnosticCollector collector = compiler.diagnosticCollector;
    compareWarningKinds(patchText, expectedWarnings, collector.warnings);
  }

  await expect('String s = 0;', MessageKind.NOT_ASSIGNABLE);
  await expect('void method() { String s = 0; }', MessageKind.NOT_ASSIGNABLE);
  await expect(
      '''
         class Class {
           String s = 0;
         }
         ''',
      MessageKind.NOT_ASSIGNABLE);
  await expect(
      '''
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
      factory A.forwardOne() = B.patchFactory;
      factory A.forwardTwo() = B.reflectBack;
      factory A.forwardThree() = B.patchInjected;
    }
    class B extends A {
      B() : super();
      external B.patchTarget();
      external factory B.patchFactory();
      external factory B.reflectBack();
      B.originTarget() : super();
      external factory B.patchInjected();
    }
    """;
  String patch = """
    @patch class B {
      @patch
      B.patchTarget() : super();
      @patch
      factory B.patchFactory() => new B.patchTarget();
      @patch
      factory B.reflectBack() = B.originTarget;
      @patch
      factory B.patchInjected() = _C.injected;
    }
    class _C extends B {
      _C.injected() : super.patchTarget();
    }
    """;

  dynamic compiler = await applyPatch(origin, patch,
      analyzeAll: true, analyzeOnly: true, runCompiler: true);
  ClassElement clsA = compiler.resolution.commonElements.coreLibrary.find("A");
  ClassElement clsB = compiler.resolution.commonElements.coreLibrary.find("B");
  Expect.isNotNull(clsB);

  ConstructorElement forward = clsA.lookupConstructor("forward");
  ConstructorElement target = forward.effectiveTarget;
  Expect.isTrue(target.isPatched, "Unexpected target $target for $forward");
  Expect.isFalse(target.isPatch, "Unexpected target $target for $forward");
  Expect.equals("patchTarget", target.name);

  ConstructorElement forwardOne = clsA.lookupConstructor("forwardOne");
  target = forwardOne.effectiveTarget;
  Expect.isFalse(forwardOne.isMalformed);
  Expect.isFalse(target.isPatch, "Unexpected target $target for $forwardOne");
  Expect.equals("patchFactory", target.name);

  ConstructorElement forwardTwo = clsA.lookupConstructor("forwardTwo");
  target = forwardTwo.effectiveTarget;
  Expect.isFalse(forwardTwo.isMalformed);
  Expect.isFalse(target.isPatch, "Unexpected target $target for $forwardTwo");
  Expect.equals("originTarget", target.name);

  ConstructorElement forwardThree = clsA.lookupConstructor("forwardThree");
  target = forwardThree.effectiveTarget;
  Expect.isFalse(forwardThree.isMalformed);
  Expect.isTrue(
      target.isInjected, "Unexpected target $target for $forwardThree");
  Expect.equals("injected", target.name);
}

Future testTypecheckPatchedMembers() async {
  String originText = "external void method();";
  String patchText = """
                     @patch void method() {
                       String s = 0;
                     }
                     """;
  dynamic compiler = await applyPatch(originText, patchText,
      analyzeAll: true, analyzeOnly: true);
  compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
  await compiler.run(null);
  DiagnosticCollector collector = compiler.diagnosticCollector;
  compareWarningKinds(
      patchText, [MessageKind.NOT_ASSIGNABLE], collector.warnings);
}

main() {
  asyncTest(() async {
    await testPatchConstructor();
    await testPatchRedirectingConstructor();
    await testPatchFunction();
    await testPatchFunctionMetadata();
    await testPatchFunctionGeneric();
    await testPatchFunctionGenericExtraTypeVariable();
    await testPatchFunctionGenericDifferentNames();
    await testPatchMember();
    await testPatchGetter();
    await testRegularMember();
    await testInjectedMember();
    await testInjectedPublicMember();
    await testInjectedFunction();
    await testInjectedPublicFunction();
    await testPatchSignatureCheck();

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
