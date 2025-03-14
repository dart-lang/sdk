// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: a:Value([exact=JSString|powerset=0], value: "", powerset: 0)*/
var a = '';

/*member: A.:[exact=A|powerset=0]*/
class A {
  /*member: A.+:[exact=JSUInt31|powerset=0]*/
  operator +(/*[exact=JSUInt31|powerset=0]*/ other) => other;
}

/*member: foo:[exact=JSString|powerset=0]*/
foo() {
  // The following '+' call will first say that it may call A::+,
  // String::+, or int::+. After all methods have been analyzed, we know
  // that a is of type String, and therefore, this method cannot call
  // A::+. Therefore, the type of the parameter of A::+ will be the
  // one given by the other calls.
  return a /*invoke: Value([exact=JSString|powerset=0], value: "", powerset: 0)*/ +
      'foo';
}

/*member: main:[null|powerset=1]*/
main() {
  A() /*invoke: [exact=A|powerset=0]*/ + 42;
  foo();
}
