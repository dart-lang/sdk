// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:[null]*/
main() {
  superMethodInvoke();
  superFieldInvoke();
  superGetterInvoke();
  overridingAbstractSuperMethodInvoke();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method.
////////////////////////////////////////////////////////////////////////////////

/*element: Super1.:[exact=Super1]*/
class Super1 {
  /*element: Super1.method:[exact=JSUInt31]*/
  method() => 42;
}

/*element: Sub1.:[exact=Sub1]*/
class Sub1 extends Super1 {
  /*element: Sub1.method:[subclass=JSPositiveInt]*/
  method() {
    var a = super.method();
    return a. /*invoke: [exact=JSUInt31]*/ abs();
  }
}

/*element: superMethodInvoke:[null]*/
superMethodInvoke() {
  new Sub1(). /*invoke: [exact=Sub1]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super field.
////////////////////////////////////////////////////////////////////////////////

/*element: _method1:[exact=JSUInt31]*/
_method1() => 42;

/*element: Super2.:[exact=Super2]*/
class Super2 {
  /*element: Super2.field:[subclass=Closure]*/
  var field = _method1;
}

/*element: Sub2.:[exact=Sub2]*/
class Sub2 extends Super2 {
  /*element: Sub2.method:[null|subclass=Object]*/
  method() {
    return super.field();
  }
}

/*element: superFieldInvoke:[null]*/
superFieldInvoke() {
  new Sub2(). /*invoke: [exact=Sub2]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super getter.
////////////////////////////////////////////////////////////////////////////////

/*element: _method2:[exact=JSUInt31]*/
_method2() => 42;

/*element: Super3.:[exact=Super3]*/
class Super3 {
  /*element: Super3.getter:[subclass=Closure]*/
  get getter => _method2;
}

/*element: Sub3.:[exact=Sub3]*/
class Sub3 extends Super3 {
  /*element: Sub3.method:[null|subclass=Object]*/
  method() {
    return super.getter();
  }
}

/*element: superGetterInvoke:[null]*/
superGetterInvoke() {
  new Sub3(). /*invoke: [exact=Sub3]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of abstract super method that overrides a concrete method.
////////////////////////////////////////////////////////////////////////////////

/*element: SuperSuper10.:[exact=SuperSuper10]*/
class SuperSuper10 {
  /*element: SuperSuper10.method:[exact=JSUInt31]*/
  method() => 42;
}

/*element: Super10.:[exact=Super10]*/
class Super10 extends SuperSuper10 {
  method();
}

/*element: Sub10.:[exact=Sub10]*/
class Sub10 extends Super10 {
  /*element: Sub10.method:[exact=JSUInt31]*/
  method() => super.method();
}

/*element: overridingAbstractSuperMethodInvoke:[null]*/
overridingAbstractSuperMethodInvoke() {
  new Sub10(). /*invoke: [exact=Sub10]*/ method();
}
