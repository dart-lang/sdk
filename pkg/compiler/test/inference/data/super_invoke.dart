// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  superMethodInvoke();
  superFieldInvoke();
  superGetterInvoke();
  overridingAbstractSuperMethodInvoke();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super method.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Super1|powerset={N}]*/
class Super1 {
  /*member: Super1.method:[exact=JSUInt31|powerset={I}]*/
  method() => 42;
}

/*member: Sub1.:[exact=Sub1|powerset={N}]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[subclass=JSPositiveInt|powerset={I}]*/
  method() {
    var a = super.method();
    return a. /*invoke: [exact=JSUInt31|powerset={I}]*/ abs();
  }
}

/*member: superMethodInvoke:[null|powerset={null}]*/
superMethodInvoke() {
  Sub1(). /*invoke: [exact=Sub1|powerset={N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: _method1:[exact=JSUInt31|powerset={I}]*/
_method1() => 42;

/*member: Super2.:[exact=Super2|powerset={N}]*/
class Super2 {
  /*member: Super2.field:[subclass=Closure|powerset={N}]*/
  var field = _method1;
}

/*member: Sub2.:[exact=Sub2|powerset={N}]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[null|subclass=Object|powerset={null}{IN}]*/
  method() {
    return super.field();
  }
}

/*member: superFieldInvoke:[null|powerset={null}]*/
superFieldInvoke() {
  Sub2(). /*invoke: [exact=Sub2|powerset={N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of super getter.
////////////////////////////////////////////////////////////////////////////////

/*member: _method2:[exact=JSUInt31|powerset={I}]*/
_method2() => 42;

/*member: Super3.:[exact=Super3|powerset={N}]*/
class Super3 {
  /*member: Super3.getter:[subclass=Closure|powerset={N}]*/
  get getter => _method2;
}

/*member: Sub3.:[exact=Sub3|powerset={N}]*/
class Sub3 extends Super3 {
  /*member: Sub3.method:[null|subclass=Object|powerset={null}{IN}]*/
  method() {
    return super.getter();
  }
}

/*member: superGetterInvoke:[null|powerset={null}]*/
superGetterInvoke() {
  Sub3(). /*invoke: [exact=Sub3|powerset={N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Invocation of abstract super method that overrides a concrete method.
////////////////////////////////////////////////////////////////////////////////

/*member: SuperSuper10.:[exact=SuperSuper10|powerset={N}]*/
class SuperSuper10 {
  /*member: SuperSuper10.method:[exact=JSUInt31|powerset={I}]*/
  method() => 42;
}

/*member: Super10.:[exact=Super10|powerset={N}]*/
class Super10 extends SuperSuper10 {
  method();
}

/*member: Sub10.:[exact=Sub10|powerset={N}]*/
class Sub10 extends Super10 {
  /*member: Sub10.method:[exact=JSUInt31|powerset={I}]*/
  method() => super.method();
}

/*member: overridingAbstractSuperMethodInvoke:[null|powerset={null}]*/
overridingAbstractSuperMethodInvoke() {
  Sub10(). /*invoke: [exact=Sub10|powerset={N}]*/ method();
}
