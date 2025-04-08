// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// [defaultFn_i] is called only via [foo_i]'s default value with a small integer.

/*member: defaultFn1:[exact=JSUInt31|powerset=0]*/
defaultFn1(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: defaultFn2:[exact=JSUInt31|powerset=0]*/
defaultFn2(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: defaultFn3:[exact=JSUInt31|powerset=0]*/
defaultFn3(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: defaultFn4:[exact=JSUInt31|powerset=0]*/
defaultFn4(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: defaultFn5:[exact=JSUInt31|powerset=0]*/
defaultFn5(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: defaultFn6:[exact=JSUInt31|powerset=0]*/
defaultFn6(/*[exact=JSUInt31|powerset=0]*/ a) => a;

/*member: foo1:[null|subclass=Object|powerset=1]*/
foo1([/*[subclass=Closure|powerset=0]*/ fn = defaultFn1]) => fn(54);

/*member: foo2:[null|subclass=Object|powerset=1]*/
foo2({/*[subclass=Closure|powerset=0]*/ fn = defaultFn2}) => fn(54);

/*member: foo3:[null|subclass=Object|powerset=1]*/
foo3([/*[subclass=Closure|powerset=0]*/ fn = defaultFn3]) => fn(54);

/*member: foo4:[null|subclass=Object|powerset=1]*/
foo4({/*[subclass=Closure|powerset=0]*/ fn = defaultFn4}) => fn(54);

/*member: foo5:[null|subclass=Object|powerset=1]*/
foo5([/*[null|subclass=Object|powerset=1]*/ fn = defaultFn5]) => fn(54);

/*member: foo6:[null|subclass=Object|powerset=1]*/
foo6({/*[null|subclass=Object|powerset=1]*/ fn = defaultFn6}) => fn(54);

/*member: main:[null|powerset=1]*/
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
