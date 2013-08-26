// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

expectSource(Mirror mirror, String source) {
  if (mirror is ClosureMirror) {
    mirror = mirror.function;
  }
  Expect.isTrue(mirror is MethodMirror);
  Expect.equals(mirror.source, source);
}

foo1() {}

int get x => 42;
set x(value) { }

class S {}

class C extends S {

  var _x;
  var _y;

  C(this.x, y)
    : _y = y,
      super();

  factory C.other(num z) {}
  factory C.other2() {}
  factory C.other3() = C.other2;

  static dynamic foo() {
    // Happy foo.
  }

  // Some comment.

  void bar() { /* Not so happy bar. */ }

  num get someX =>
    181;

  set someX(v) {
    // Discard this one.
  }
}
    

main() {
  // Top-level members
  LibraryMirror lib = reflectClass(C).owner;
  expectSource(lib.members[const Symbol("foo1")],
      "foo1() {}");
  expectSource(lib.members[const Symbol("x")],
      "int get x => 42;");
  expectSource(lib.members[const Symbol("x=")],
      "set x(value) { }");

  // Class members
  ClassMirror cm = reflectClass(C);
  expectSource(cm.members[const Symbol("foo")],
      "static dynamic foo() {\n"
      "    // Happy foo.\n"
      "  }");
  expectSource(cm.members[const Symbol("bar")],
      "void bar() { /* Not so happy bar. */ }");
  expectSource(cm.members[const Symbol("someX")],
      "num get someX =>\n"
      "    181;");
  expectSource(cm.members[const Symbol("someX=")],
      "set someX(v) {\n"
      "    // Discard this one.\n"
      "  }");
  expectSource(cm.constructors[const Symbol("C")],
      "C(this.x, y)\n"
      "    : _y = y,\n"
      "      super();");
  expectSource(cm.constructors[const Symbol("C.other")],
      "factory C.other(num z) {}");
  expectSource(cm.constructors[const Symbol("C.other3")],
      "factory C.other3() = C.other2;");

  // Closures
  expectSource(reflect((){}), "(){}");
  expectSource(reflect((x,y,z) { return x*y*z; }), "(x,y,z) { return x*y*z; }");
  expectSource(reflect((e) => doSomething(e)), "(e) => doSomething(e)");

  namedClosure(x,y,z) => 1;
  var a = () {};
  expectSource(reflect(namedClosure), "namedClosure(x,y,z) => 1;");
  expectSource(reflect(a), "() {}");
}
