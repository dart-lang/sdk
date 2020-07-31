// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// [defaultFn_i] is called only via [foo_i]'s default value with a small integer.

/*member: defaultFn1:[exact=JSUInt31]*/
defaultFn1(/*[exact=JSUInt31]*/ a) => a;

/*member: defaultFn2:[exact=JSUInt31]*/
defaultFn2(/*[exact=JSUInt31]*/ a) => a;

/*member: defaultFn3:[exact=JSUInt31]*/
defaultFn3(/*[exact=JSUInt31]*/ a) => a;

/*member: defaultFn4:[exact=JSUInt31]*/
defaultFn4(/*[exact=JSUInt31]*/ a) => a;

/*member: defaultFn5:[exact=JSUInt31]*/
defaultFn5(/*[exact=JSUInt31]*/ a) => a;

/*member: defaultFn6:[exact=JSUInt31]*/
defaultFn6(/*[exact=JSUInt31]*/ a) => a;

/*member: foo1:[null|subclass=Object]*/
foo1([/*[subclass=Closure]*/ fn = defaultFn1]) => fn(54);

/*member: foo2:[null|subclass=Object]*/
foo2({/*[subclass=Closure]*/ fn: defaultFn2}) => fn(54);

/*member: foo3:[null|subclass=Object]*/
foo3([/*[subclass=Closure]*/ fn = defaultFn3]) => fn(54);

/*member: foo4:[null|subclass=Object]*/
foo4({/*[subclass=Closure]*/ fn: defaultFn4}) => fn(54);

/*member: foo5:[null|subclass=Object]*/
foo5([/*[null|subclass=Object]*/ fn = defaultFn5]) => fn(54);

/*member: foo6:[null|subclass=Object]*/
foo6({/*[null|subclass=Object]*/ fn: defaultFn6}) => fn(54);

/*member: main:[null]*/
main() {
  // Direct calls.
  foo1();
  foo2();
  // Indirect calls.
  (foo3)();
  (foo4)();
  // Calls via Function.apply.
  Function.apply(foo5, []);
  Function.apply(foo6, []);
}
