// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: a:Value([exact=JSString], value: "")*/
var a = '';

/*member: A.:[exact=A]*/
class A {
  /*member: A.+:[exact=JSUInt31]*/
  operator +(/*[exact=JSUInt31]*/ other) => other;
}

/*member: foo:[exact=JSString]*/
foo() {
  // The following '+' call will first say that it may call A::+,
  // String::+, or int::+. After all methods have been analyzed, we know
  // that a is of type String, and therefore, this method cannot call
  // A::+. Therefore, the type of the parameter of A::+ will be the
  // one given by the other calls.
  return a /*invoke: Value([exact=JSString], value: "")*/ + 'foo';
}

/*member: main:[null]*/
main() {
  new A() /*invoke: [exact=A]*/ + 42;
  foo();
}
