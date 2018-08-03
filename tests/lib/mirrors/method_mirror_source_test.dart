// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Note: This test relies on LF line endings in the source file.
// It requires an entry in the .gitattributes file.

import "dart:mirrors";
import "package:expect/expect.dart";
import "method_mirror_source_other.dart";

expectSource(Mirror mirror, String source) {
  MethodMirror methodMirror;
  if (mirror is ClosureMirror) {
    methodMirror = mirror.function;
  } else {
    methodMirror = mirror as MethodMirror;
  }
  Expect.isTrue(methodMirror is MethodMirror);
  Expect.equals(source, methodMirror.source);
}

foo1() {}
doSomething(e) => e;

int get x => 42;
set x(value) { }

class S {}

class C extends S {

  var _x;
  var _y;

  C(this._x, y)
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
  expectSource(lib.declarations[#foo1],
      "foo1() {}");
  expectSource(lib.declarations[#x],
      "int get x => 42;");
  expectSource(lib.declarations[const Symbol("x=")],
      "set x(value) { }");

  // Class members
  ClassMirror cm = reflectClass(C);
  expectSource(cm.declarations[#foo],
      "static dynamic foo() {\n"
      "    // Happy foo.\n"
      "  }");
  expectSource(cm.declarations[#bar],
      "void bar() { /* Not so happy bar. */ }");
  expectSource(cm.declarations[#someX],
      "num get someX =>\n"
      "    181;");
  expectSource(cm.declarations[const Symbol("someX=")],
      "set someX(v) {\n"
      "    // Discard this one.\n"
      "  }");
  expectSource(cm.declarations[#C],
      "C(this._x, y)\n"
      "    : _y = y,\n"
      "      super();");
  expectSource(cm.declarations[#C.other],
      "factory C.other(num z) {}");
  expectSource(cm.declarations[#C.other3],
      "factory C.other3() = C.other2;");

  // Closures
  expectSource(reflect((){}), "(){}");
  expectSource(reflect((x,y,z) { return x*y*z; }), "(x,y,z) { return x*y*z; }");
  expectSource(reflect((e) => doSomething(e)), "(e) => doSomething(e)");

  namedClosure(x,y,z) => 1;
  var a = () {};
  expectSource(reflect(namedClosure), "namedClosure(x,y,z) => 1;");
  expectSource(reflect(a), "() {}");

  // Function at first line.
  LibraryMirror otherLib = reflectClass(SomethingInOther).owner;
  expectSource(otherLib.declarations[#main],
"""main() {
  print("Blah");
}""");
}
