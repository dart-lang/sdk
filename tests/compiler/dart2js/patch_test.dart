// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("../../../lib/compiler/implementation/leg.dart");
#import("../../../lib/compiler/implementation/elements/elements.dart");
#import("../../../lib/compiler/implementation/tree/tree.dart");
#import("../../../lib/compiler/implementation/util/util.dart");
#import("mock_compiler.dart");
#import("parser_helper.dart");
#import("dart:uri");

Compiler applyPatch(String script, String patch) {
  String core = "$DEFAULT_CORELIB\n$script";
  MockCompiler compiler = new MockCompiler(coreSource: core);
  var uri = new Uri("core.dartp");
  compiler.sourceFiles[uri.toString()] = new MockFile(patch);
  compiler.patchParser.patchLibrary(uri, compiler.coreLibrary);
  return compiler;
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
    Expect.isNotNull(node.body);
    // If the element has no body it is a Block with identical begin and end
    // tokens (the semicolon).
    Expect.isTrue(node.body is Block);
    Expect.identical(node.body.getBeginToken(), node.body.getEndToken());
}

Element ensure(compiler,
               String name,
               Element lookup(name),
               [bool isPatched = false,
                bool isPatch = false,
                bool isMethod = true,
                bool isGetter = false,
                bool isFound = true]) {
  var element = lookup(buildSourceString(name));
  if (!isFound) {
    Expect.isNull(element);
    return element;
  }
  Expect.isNotNull(element);
  if (isGetter) {
    Expect.isTrue(element is AbstractFieldElement);
    Expect.isNotNull(element.getter);
    element = element.getter;
  }
  Expect.equals(isPatched, element.isPatched);
  if (isPatched) {
    Expect.isNull(element.origin);
    Expect.isNotNull(element.patch);

    Expect.equals(element, element.declaration);
    Expect.equals(element.patch, element.implementation);

    if (isMethod) {
      expectHasNoBody(compiler, element);
      expectHasBody(compiler, element.patch);
    }
  } else {
    Expect.isTrue(element.isImplementation);
  }
  Expect.equals(isPatch, element.isPatch);
  if (isPatch) {
    Expect.isNotNull(element.origin);
    Expect.isNull(element.patch);

    Expect.equals(element.origin, element.declaration);
    Expect.equals(element, element.implementation);

    if (isMethod) {
      expectHasBody(compiler, element);
      expectHasNoBody(compiler, element.origin);
    }
  } else {
    Expect.isTrue(element.isDeclaration);
  }
  if (!(element.isPatched || element.isPatch)) {
    Expect.isNull(element.origin);
    Expect.isNull(element.patch);

    Expect.equals(element, element.declaration);
    Expect.equals(element, element.implementation);

    if (isMethod) {
      expectHasBody(compiler, element);
    }
  }
  Expect.isFalse(element.isPatched && element.isPatch);
  return element;
}

testPatchFunction() {
  var compiler = applyPatch(
      "external test();",
      "patch test() { return 'string'; } ");
  ensure(compiler, "test", compiler.coreLibrary.find, isPatched: true);
  ensure(compiler, "test", compiler.coreLibrary.patch.find, isPatch: true);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testPatchMember() {
  var compiler = applyPatch(
      """
      class Class {
        external String toString();
      }
      """,
      """
      patch class Class {
        patch String toString() => 'string';
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         isMethod: false, isPatched: true);
  container.parseNode(compiler);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         isMethod: false, isPatch: true);

  ensure(compiler, "toString", container.lookupLocalMember,
         isPatched: true);
  ensure(compiler, "toString", container.patch.lookupLocalMember,
         isPatch: true);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testPatchGetter() {
  var compiler = applyPatch(
      """
      class Class {
        external int get field;
      }
      """,
      """
      patch class Class {
        patch int get field => 5;
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         isPatched: true, isMethod: false);
  container.parseNode(compiler);
  ensure(compiler,
         "field",
         container.lookupLocalMember,
         isGetter: true,
         isPatched: true);
  ensure(compiler,
         "field",
         container.patch.lookupLocalMember,
         isGetter: true,
         isPatch: true);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testRegularMember() {
  var compiler = applyPatch(
      """
      class Class {
        void regular() {}
      }
      """,
      """
      patch class Class {
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         isMethod: false, isPatched: true);
  container.parseNode(compiler);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         isMethod: false, isPatch: true);

  ensure(compiler, "regular", container.lookupLocalMember);
  ensure(compiler, "regular", container.patch.lookupLocalMember);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testGhostMember() {
  var compiler = applyPatch(
      """
      class Class {
      }
      """,
      """
      patch class Class {
        void ghost() {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         isMethod: false, isPatched: true);
  container.parseNode(compiler);
  ensure(compiler, "Class", compiler.coreLibrary.patch.find,
         isMethod: false, isPatch: true);

  ensure(compiler, "ghost", container.lookupLocalMember, isFound: false);
  ensure(compiler, "ghost", container.patch.lookupLocalMember);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testInjectFunction() {
  var compiler = applyPatch(
      "",
      "int _function() => 5;");
  ensure(compiler,
         "_function",
         compiler.coreLibrary.find,
         isFound: false);
  ensure(compiler,
         "_function",
         compiler.coreLibrary.patch.find);

  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isTrue(compiler.errors.isEmpty(),
                "Unexpected errors: ${compiler.errors}");
}

testPatchSignatureCheck() {
  var compiler = applyPatch(
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
      }
      """,
      """
      patch class Class {
        patch int method1() => 0;
        patch void method2() {}
        patch void method3(String s2) {}
        patch void method4([String str, int i]) {}
        patch void method5() {}
        patch void method6([String str]) {}
        patch void method7([String s2]) {}
        patch void method8({String s2}) {}
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find,
                         isMethod: false, isPatched: true);
  container.ensureResolved(compiler);
  container.parseNode(compiler);

  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method1", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method1:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method2", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method2:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method3", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method3:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method4", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method4:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method5", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method5:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method6", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method6:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method7", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method7:${compiler.errors}');

  compiler.warnings.clear();
  compiler.errors.clear();
  compiler.resolver.resolveMethodElement(
      ensure(compiler, "method8", container.lookupLocalMember,
          isPatched: true));
  Expect.isTrue(compiler.warnings.isEmpty(),
                "Unexpected warnings: ${compiler.warnings}");
  Expect.isFalse(compiler.errors.isEmpty());
  print('method8:${compiler.errors}');
}

main() {
  testPatchFunction();
  testPatchMember();
  testPatchGetter();
  testRegularMember();
  testGhostMember();
  testInjectFunction();
  testPatchSignatureCheck();
}
