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
  compiler.applyClassPatches(compiler.coreLibrary);
  return compiler;
}

Element ensure(compiler,
               String name,
               Element lookup(name),
               [bool isPatched = true,
                bool hasBody = false,
                bool isGetter = false]) {
  var element = lookup(buildSourceString(name));
  Expect.isNotNull(element);
  if (isGetter) {
    Expect.isTrue(element is AbstractFieldElement);
    Expect.isNotNull(element.getter);
    element = element.getter;
  }
  if (element is! ContainerElement &&
      element is! AbstractFieldElement) {
    // Classes aren't patched like functions and variables are.
    Expect.equals(isPatched, element.isPatched);
  }
  if (hasBody) {
    var node = element.parseNode(compiler);
    Expect.isNotNull(node, "Element isn't parseable, when a body was expected");
    Expect.isNotNull(node.body, "expected body, bot none found");
  }
  return element;
}

testPatchFunction() {
  var compiler = applyPatch(
      "external test();",
      "patch test() { return 'string'; } ");
  ensure(compiler, "test", compiler.coreLibrary.find, hasBody: true);
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
  var container = ensure(compiler, "Class", compiler.coreLibrary.find);
  ensure(compiler, "toString", container.lookupLocalMember, hasBody:true);
}

testPatchGetter() {
  var compiler = applyPatch(
      """
      class Class {
        external int get field();
      }
      """,
      """
      patch class Class {
        patch int get field() => 5;
      }
      """);
  var container = ensure(compiler, "Class", compiler.coreLibrary.find);
  ensure(compiler,
         "field",
         container.lookupLocalMember,
         isGetter: true,
         hasBody: true);
}

testInjectFunction() {
  var compiler = applyPatch(
      "",
      "int _function() => 5;");
  ensure(compiler,
         "_function",
         compiler.coreLibrary.find,
         hasBody: true,
         isPatched: false);
}

main() {
  testPatchFunction();
  testPatchMember();
  testPatchGetter();
  testInjectFunction();
}
