// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that hidden native class names are not used by generated code.

@native("*B")
class A  {
  get name => 'A';
  static A create() => makeA();
}

@native("*C")
class B  {
  get name => 'B';
  static B create() => makeB();
}

class C {  // Ordinary class with name clashing with native class.
  get name => 'C';
  static C create() => new C();
}

@native makeA();
@native makeB();

@native("""
// Poison hidden native names 'B' and 'C' to prove the compiler didn't place
// anthing on the hidden native class.
B = null;
C = null;
""")
void setup1();

@native("""
// This code is all inside 'setup' and so not accesible from the global scope.
function B(){}
function C(){}
makeA = function(){return new B};  // A is "*B"
makeB = function(){return new C};  // B is "*C"
""")
void setup2();

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  setup1();
  setup2();

  var things = [A.create(), B.create(), C.create()];
  var a = things[inscrutable(0)];
  var b = things[inscrutable(1)];
  var c = things[inscrutable(2)];

  Expect.equals('A', a.name);
  Expect.equals('B', b.name);
  Expect.equals('C', c.name);
}
