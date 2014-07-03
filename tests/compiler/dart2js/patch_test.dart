// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import "package:compiler/implementation/dart2jslib.dart";
import "package:compiler/implementation/elements/elements.dart";
import "package:compiler/implementation/tree/tree.dart";
import "package:compiler/implementation/util/util.dart";
import "mock_compiler.dart";
import "mock_libraries.dart";
import "parser_helper.dart";

Future<Compiler> applyPatch(String script, String patch,
                            {bool analyzeAll: false, bool analyzeOnly: false}) {
  Map<String, String> core = <String, String>{'script': script};
  MockCompiler compiler = new MockCompiler.internal(coreSource: core,
                                                    analyzeAll: analyzeAll,
                                                    analyzeOnly: analyzeOnly);
  var uri = Uri.parse("patch:core");
  compiler.registerSource(uri, "$DEFAULT_PATCH_CORE_SOURCE\n$patch");
  return compiler.init().then((_) => compiler);
}

void expectHasBody(compiler, Element element) {
    var node = element.parseNode(compiler);
    Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
    Expect.isNotNull(node.body);
    // If the element has a body it is either a Block or a Return statement,
    // both with different begin and end tokens.
    Expect.isTrue(node.body is Block || node.body is Return);
    Expect.notEquals(node.body.getBeginToken(), node.body.getEndToken());
}

void expectHasNoBody(compiler, Element element) {
    var node = element.parseNode(compiler);
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
  Expect.equals(expectIsPatched, element.isPatched);
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

testPatchFunction() {
  asyncTest(() => applyPatch(
      "external test();",
      "@patch test() { return 'string'; } ").then((compiler) {
    ensure(compiler, "test", compiler.coreLibrary.find,
           expectIsPatched: true, checkHasBody: true);
    ensure(compiler, "test", compiler.coreLibrary.patch.find,
           expectIsPatch: true, checkHasBody: true);

    Expect.isTrue(compiler.warnings.isEmpty,
                  "Unexpected warnings: ${compiler.warnings}");
    Expect.isTrue(compiler.errors.isEmpty,
                  "Unexpected errors: ${compiler.errors}");
  }));
}

testPatchConstructor() {
  asyncTest(() => applyPatch(
      """
      class Class {
        external Class();
      }
      """,
      """
      @patch class Class {
        @patch Class();
      }
      """).then((compiler) {
    var classOrigin = ensure(compiler, "Class", compiler.coreLibrary.find,
                             expectIsPatched: true);
    classOrigin.ensureResolved(compiler);
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
  }));
}

testPatchRedirectingConstructor() {
  asyncTest(() => applyPatch(
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
      """).then((compiler) {
    var classOrigin = ensure(compiler, "Class", compiler.coreLibrary.find,
                             expectIsPatched: true);
    classOrigin.ensureResolved(compiler);

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
   }));
}

testPatchMember() {
  asyncTest(() => applyPatch(
      """
      class Class {
        external String toString();
      }
      """,
      """
      @patch class Class {
        @patch String toString() => 'string';
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);
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
  }));
}

testPatchGetter() {
  asyncTest(() => applyPatch(
      """
      class Class {
        external int get field;
      }
      """,
      """
      @patch class Class {
        @patch int get field => 5;
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);
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
  }));
}

testRegularMember() {
  asyncTest(() => applyPatch(
      """
      class Class {
        void regular() {}
      }
      """,
      """
      @patch class Class {
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);
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
  }));
}

testGhostMember() {
  asyncTest(() => applyPatch(
      """
      class Class {
      }
      """,
      """
      @patch class Class {
        void ghost() {}
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);
    ensure(compiler, "Class", compiler.coreLibrary.patch.find,
           expectIsPatch: true);

    ensure(compiler, "ghost", container.lookupLocalMember,
           expectIsFound: false);
    ensure(compiler, "ghost", container.patch.lookupLocalMember,
           checkHasBody: true, expectIsRegular: true);

    Expect.isTrue(compiler.warnings.isEmpty,
                  "Unexpected warnings: ${compiler.warnings}");
    Expect.isTrue(compiler.errors.isEmpty,
                  "Unexpected errors: ${compiler.errors}");
  }));
}

testInjectFunction() {
  asyncTest(() => applyPatch(
      "",
      "int _function() => 5;").then((compiler) {
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
  }));
}

testPatchSignatureCheck() {
  asyncTest(() => applyPatch(
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
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.ensureResolved(compiler);
    container.parseNode(compiler);

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
  }));
}

testExternalWithoutImplementationTopLevel() {
  asyncTest(() => applyPatch(
      """
      external void foo();
      """,
      """
      // @patch void foo() {}
      """).then((compiler) {
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
  }));
}

testExternalWithoutImplementationMember() {
  asyncTest(() => applyPatch(
      """
      class Class {
        external void foo();
      }
      """,
      """
      @patch class Class {
        // @patch void foo() {}
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);

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
  }));
}

testIsSubclass() {
  asyncTest(() => applyPatch(
      """
      class A {}
      """,
      """
      @patch class A {}
      """).then((compiler) {
    ClassElement cls = ensure(compiler, "A", compiler.coreLibrary.find,
                              expectIsPatched: true);
    ClassElement patch = cls.patch;
    Expect.isTrue(cls != patch);
    Expect.isTrue(cls.isSubclassOf(patch));
    Expect.isTrue(patch.isSubclassOf(cls));
  }));
}

testPatchNonExistingTopLevel() {
  asyncTest(() => applyPatch(
      """
      // class Class {}
      """,
      """
      @patch class Class {}
      """).then((compiler) {
    Expect.isTrue(compiler.warnings.isEmpty,
                  "Unexpected warnings: ${compiler.warnings}");
    print('testPatchNonExistingTopLevel:${compiler.errors}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXISTING);
  }));
}

testPatchNonExistingMember() {
  asyncTest(() => applyPatch(
      """
      class Class {}
      """,
      """
      @patch class Class {
        @patch void foo() {}
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);

    Expect.isTrue(compiler.warnings.isEmpty,
                  "Unexpected warnings: ${compiler.warnings}");
    print('testPatchNonExistingMember:${compiler.errors}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXISTING);
  }));
}

testPatchNonPatchablePatch() {
  asyncTest(() => applyPatch(
      """
      external get foo;
      """,
      """
      @patch var foo;
      """).then((compiler) {
    ensure(compiler, "foo", compiler.coreLibrary.find);

    Expect.isTrue(compiler.warnings.isEmpty,
                  "Unexpected warnings: ${compiler.warnings}");
    print('testPatchNonPatchablePatch:${compiler.errors}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NONPATCHABLE);
  }));
}

testPatchNonPatchableOrigin() {
  asyncTest(() => applyPatch(
      """
      external var foo;
      """,
      """
      @patch get foo => 0;
      """).then((compiler) {
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
  }));
}

testPatchNonExternalTopLevel() {
  asyncTest(() => applyPatch(
      """
      void foo() {}
      """,
      """
      @patch void foo() {}
      """).then((compiler) {
    print('testPatchNonExternalTopLevel.errors:${compiler.errors}');
    print('testPatchNonExternalTopLevel.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXTERNAL);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(compiler.infos[0].message.kind ==
        MessageKind.PATCH_POINT_TO_FUNCTION);
  }));
}

testPatchNonExternalMember() {
  asyncTest(() => applyPatch(
      """
      class Class {
        void foo() {}
      }
      """,
      """
      @patch class Class {
        @patch void foo() {}
      }
      """).then((compiler) {
    var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                           expectIsPatched: true);
    container.parseNode(compiler);

    print('testPatchNonExternalMember.errors:${compiler.errors}');
    print('testPatchNonExternalMember.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_EXTERNAL);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(compiler.infos[0].message.kind ==
        MessageKind.PATCH_POINT_TO_FUNCTION);
  }));
}

testPatchNonClass() {
  asyncTest(() => applyPatch(
      """
      external void Class() {}
      """,
      """
      @patch class Class {}
      """).then((compiler) {
    print('testPatchNonClass.errors:${compiler.errors}');
    print('testPatchNonClass.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_CLASS);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(
        compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_CLASS);
  }));
}

testPatchNonGetter() {
  asyncTest(() => applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch get foo => 0;
      """).then((compiler) {
    print('testPatchNonClass.errors:${compiler.errors}');
    print('testPatchNonClass.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_GETTER);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(
        compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_GETTER);
  }));
}

testPatchNoGetter() {
  asyncTest(() => applyPatch(
      """
      external set foo(var value) {}
      """,
      """
      @patch get foo => 0;
      """).then((compiler) {
    print('testPatchNonClass.errors:${compiler.errors}');
    print('testPatchNonClass.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NO_GETTER);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(
        compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_GETTER);
  }));
}

testPatchNonSetter() {
  asyncTest(() => applyPatch(
      """
      external void foo() {}
      """,
      """
      @patch set foo(var value) {}
      """).then((compiler) {
    print('testPatchNonClass.errors:${compiler.errors}');
    print('testPatchNonClass.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NON_SETTER);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(
        compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_SETTER);
  }));
}

testPatchNoSetter() {
  asyncTest(() => applyPatch(
      """
      external get foo;
      """,
      """
      @patch set foo(var value) {}
      """).then((compiler) {
    print('testPatchNonClass.errors:${compiler.errors}');
    print('testPatchNonClass.warnings:${compiler.warnings}');
    Expect.equals(1, compiler.errors.length);
    Expect.isTrue(
        compiler.errors[0].message.kind == MessageKind.PATCH_NO_SETTER);
    Expect.equals(0, compiler.warnings.length);
    Expect.equals(1, compiler.infos.length);
    Expect.isTrue(
        compiler.infos[0].message.kind == MessageKind.PATCH_POINT_TO_SETTER);
  }));
}

testPatchNonFunction() {
  asyncTest(() => applyPatch(
      """
      external get foo;
      """,
      """
      @patch void foo() {}
      """).then((compiler) {
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
  }));
}

testPatchAndSelector() {
  asyncTest(() => applyPatch(
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
      """).then((compiler) {
    ClassElement cls = ensure(compiler, "A", compiler.coreLibrary.find,
                              expectIsPatched: true);
    cls.ensureResolved(compiler);

    ensure(compiler, "method", cls.patch.lookupLocalMember,
           checkHasBody: true, expectIsRegular: true);

    ensure(compiler, "clear", cls.lookupLocalMember,
           checkHasBody: true, expectIsPatched: true);

    compiler.phase = Compiler.PHASE_DONE_RESOLVING;

    // Check that a method just in the patch class is a target for a
    // typed selector.
    var selector = new Selector.call('method', compiler.coreLibrary, 0);
    var typedSelector = new TypedSelector.exact(cls, selector, compiler);
    Element method = cls.implementation.lookupLocalMember('method');
    Expect.isTrue(selector.applies(method, compiler));
    Expect.isTrue(typedSelector.applies(method, compiler));

    // Check that the declaration method in the declaration class is a target
    // for a typed selector.
    selector = new Selector.call('clear', compiler.coreLibrary, 0);
    typedSelector = new TypedSelector.exact(cls, selector, compiler);
    method = cls.lookupLocalMember('clear');
    Expect.isTrue(selector.applies(method, compiler));
    Expect.isTrue(typedSelector.applies(method, compiler));

    // Check that the declaration method in the declaration class is a target
    // for a typed selector on a subclass.
    cls = ensure(compiler, "B", compiler.coreLibrary.find);
    cls.ensureResolved(compiler);
    typedSelector = new TypedSelector.exact(cls, selector, compiler);
    Expect.isTrue(selector.applies(method, compiler));
    Expect.isTrue(typedSelector.applies(method, compiler));
  }));
}

void testAnalyzeAllInjectedMembers() {
  void expect(String patchText, [expectedWarnings]) {
    if (expectedWarnings == null) expectedWarnings = [];
    if (expectedWarnings is! List) {
      expectedWarnings = <MessageKind>[expectedWarnings];
    }

    asyncTest(() => applyPatch('', patchText, analyzeAll: true,
               analyzeOnly: true).then((compiler) {
      compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
      return compiler.runCompiler(null).then((_) {
        compareWarningKinds(patchText, expectedWarnings, compiler.warnings);
      });
    }));
  }

  expect('String s = 0;', MessageKind.NOT_ASSIGNABLE);
  expect('void method() { String s = 0; }', MessageKind.NOT_ASSIGNABLE);
  expect('''
         class Class {
           String s = 0;
         }
         ''',
         MessageKind.NOT_ASSIGNABLE);
  expect('''
         class Class {
           void method() {
             String s = 0;
           }
         }
         ''',
         MessageKind.NOT_ASSIGNABLE);
}

void testTypecheckPatchedMembers() {
  String originText = "external void method();";
  String patchText = """
                     @patch void method() {
                       String s = 0;
                     }
                     """;
  asyncTest(() => applyPatch(originText, patchText,
             analyzeAll: true, analyzeOnly: true).then((compiler) {
    compiler.librariesToAnalyzeWhenRun = [Uri.parse('dart:core')];
    return compiler.runCompiler(null).then((_) {
      compareWarningKinds(patchText,
          [MessageKind.NOT_ASSIGNABLE], compiler.warnings);
    });
  }));
}

main() {
  testPatchConstructor();
  testPatchRedirectingConstructor();
  testPatchFunction();
  testPatchMember();
  testPatchGetter();
  testRegularMember();
  testGhostMember();
  testInjectFunction();
  testPatchSignatureCheck();

  testExternalWithoutImplementationTopLevel();
  testExternalWithoutImplementationMember();

  testIsSubclass();

  testPatchNonExistingTopLevel();
  testPatchNonExistingMember();
  testPatchNonPatchablePatch();
  testPatchNonPatchableOrigin();
  testPatchNonExternalTopLevel();
  testPatchNonExternalMember();
  testPatchNonClass();
  testPatchNonGetter();
  testPatchNoGetter();
  testPatchNonSetter();
  testPatchNoSetter();
  testPatchNonFunction();

  testPatchAndSelector();

  testAnalyzeAllInjectedMembers();
  testTypecheckPatchedMembers();
}
