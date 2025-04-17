// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  superFieldAccess();
  superGetterAccess();
  superMethodAccess();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super field.
////////////////////////////////////////////////////////////////////////////////

/*member: Super1.:[exact=Super1|powerset={N}]*/
class Super1 {
  /*member: Super1.field:[exact=JSUInt31|powerset={I}]*/
  var field = 42;
}

/*member: Sub1.:[exact=Sub1|powerset={N}]*/
class Sub1 extends Super1 {
  /*member: Sub1.method:[exact=JSUInt31|powerset={I}]*/
  method() => super.field;
}

/*member: superFieldAccess:[null|powerset={null}]*/
superFieldAccess() {
  Sub1(). /*invoke: [exact=Sub1|powerset={N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super getter.
////////////////////////////////////////////////////////////////////////////////

/*member: Super2.:[exact=Super2|powerset={N}]*/
class Super2 {
  /*member: Super2.getter:[exact=JSUInt31|powerset={I}]*/
  get getter => 42;
}

/*member: Sub2.:[exact=Sub2|powerset={N}]*/
class Sub2 extends Super2 {
  /*member: Sub2.method:[exact=JSUInt31|powerset={I}]*/
  method() => super.getter;
}

/*member: superGetterAccess:[null|powerset={null}]*/
superGetterAccess() {
  Sub2(). /*invoke: [exact=Sub2|powerset={N}]*/ method();
}

////////////////////////////////////////////////////////////////////////////////
// Access of super method.
////////////////////////////////////////////////////////////////////////////////

/*member: Super3.:[exact=Super3|powerset={N}]*/
class Super3 {
  /*member: Super3.superMethod:[null|powerset={null}]*/
  superMethod() {}
}

/*member: Sub3.:[exact=Sub3|powerset={N}]*/
class Sub3 extends Super3 {
  /*member: Sub3.method:[subclass=Closure|powerset={N}]*/
  method() => super.superMethod;
}

/*member: superMethodAccess:[null|powerset={null}]*/
superMethodAccess() {
  Sub3(). /*invoke: [exact=Sub3|powerset={N}]*/ method();
}
