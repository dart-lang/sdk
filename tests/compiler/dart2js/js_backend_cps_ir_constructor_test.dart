// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of interceptors.

library constructor_test;

import 'js_backend_cps_ir.dart';

const List<TestEntry> tests = const [
  const TestEntry("""
class Base {
  var x;
  Base(this.x);
}
class Sub extends Base {
  var y;
  Sub(x, this.y) : super(x);
}
main() {
  print(new Sub(1, 2).x);
}""",
r"""
function() {
  var v0 = H.S(1);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),

  const TestEntry("""
class Base {
  var x;
  Base(this.x);
}
class Sub extends Base {
  var y;
  Sub(x, this.y) : super(x) {
    print(x);
  }
}
main() {
  print(new Sub(1, 2).x);
}""",
r"""
function() {
  P.print(1);
  P.print(1);
}"""),

  const TestEntry("""
class Base0 {
  Base0() {
    print('Base0');
  }
}
class Base extends Base0 {
  var x;
  Base(this.x);
}
class Sub extends Base {
  var y;
  Sub(x, this.y) : super(x) {
    print(x);
  }
}
main() {
  print(new Sub(1, 2).x);
}""",
r"""
function() {
  P.print("Base0");
  P.print(1);
  P.print(1);
}"""),

  const TestEntry("""
class Base0 {
  Base0() {
    print('Base0');
  }
}
class Base extends Base0 {
  var x;
  Base(x1) : x = (() => ++x1) {
    print(x1); // use boxed x1
  }
}
class Sub extends Base {
  var y;
  Sub(x, this.y) : super(x) {
    print(x);
  }
}
main() {
  print(new Sub(1, 2).x);
}""",
r"""
function() {
  var _box_0 = {};
  _box_0.x1 = 1;
  P.print("Base0");
  P.print(_box_0.x1);
  P.print(1);
  P.print(new V.Base_closure(_box_0));
}"""),

  const TestEntry("""
foo(x) {
  print(x);
}
class Base {
  var x1 = foo('x1');
  var x2;
  var x3 = foo('x3');
  Base() : x2 = foo('x2');
}
class Sub extends Base {
  var y1 = foo('y1');
  var y2;
  var y3;
  Sub() : y2 = foo('y2'), super(), y3 = foo('y3');
}
main() {
  new Sub();
}
""",
r"""
function() {
  V.foo("y1");
  V.foo("y2");
  V.foo("x1");
  V.foo("x3");
  V.foo("x2");
  V.foo("y3");
}"""),


  const TestEntry("""
class Bar {
  Bar(x, {y, z: 'z', w: '_', q}) {
    print(x);
    print(y);
    print(z);
    print(w);
    print(q);
  }
}
class Foo extends Bar {
  Foo() : super('x', y: 'y', w: 'w');
}
main() {
  new Foo();
}
""",
r"""
function() {
  P.print("x");
  P.print("y");
  P.print("z");
  P.print("w");
  P.print(null);
}"""),
  const TestEntry(r"""
class C<T> {
  foo() => T;
}
main() {
  print(new C<int>().foo());
}""", r"""
function() {
  var v0 = H.S(H.createRuntimeType(H.runtimeTypeToString(H.getTypeArgumentByIndex(V.C$(P.$int), 0))));
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  const TestEntry(r"""
class C<T> {
  foo() => C;
}
main() {
  print(new C<int>().foo());
}""", r"""
function() {
  var v0;
  V.C$();
  v0 = H.S(C.Type_C_cdS);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
  const TestEntry.forMethod('generative_constructor(C#)', r"""
class C<T> {
  C() { print(T); }
  foo() => print(T);
}
main() {
  new C<int>();
}""", r"""
function($T) {
  var v0 = H.setRuntimeTypeInfo(new V.C(), [$T]);
  v0.C$0();
  return v0;
}"""),
  const TestEntry.forMethod('generative_constructor(C#)', r"""
class C<T> {
  var x;
  C() : x = new D<T>();
}
class D<T> {
  foo() => T;
}
main() {
  print(new C<int>().x.foo());
}""", r"""
function($T) {
  return H.setRuntimeTypeInfo(new V.C(V.D$($T)), [$T]);
}"""),


  const TestEntry(r"""
class A {
  var x;
  A() : this.b(1);
  A.b(this.x);
}
main() {
  print(new A().x);
}""", r"""
function() {
  var v0 = H.S(1);
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),


const TestEntry(r"""
class Foo {
  factory Foo.make(x) {
    print('Foo');
    return new Foo.create(x);
  }
  var x;
  Foo.create(this.x);
}
main() {
  print(new Foo.make(5));
}""", r"""
function() {
  P.print("Foo");
  P.print(new V.Foo(5));
}"""),
const TestEntry(r"""
class Foo {
  factory Foo.make(x) = Foo.create;
  var x;
  Foo.create(this.x);
}
main() {
  print(new Foo.make(5));
}""", r"""
function() {
  var v0 = new V.Foo(5), v1 = "Instance of '" + H.Primitives_objectTypeName(v0) + "'";
  if (!(typeof v1 === "string"))
    throw H.wrapException(H.argumentErrorValue(v0));
  v0 = v1;
  if (typeof dartPrint == "function")
    dartPrint(v0);
  else if (typeof console == "object" && typeof console.log != "undefined")
    console.log(v0);
  else if (!(typeof window == "object")) {
    if (!(typeof print == "function"))
      throw "Unable to print message: " + String(v0);
    print(v0);
  }
}"""),
const TestEntry(r"""
class A {
  factory A(x) = B<int>;
  get typevar;
}
class B<T> implements A {
  var x;
  B(this.x);

  get typevar => T;
}
main() {
  new A(5).typevar;
}""", r"""
function() {
  V.B$(5, P.$int);
}"""),
];

void main() {
  runTests(tests);
}
