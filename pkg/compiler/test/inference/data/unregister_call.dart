// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: a:Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/
var a = '';

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {
  /*member: A.+:[exact=JSUInt31|powerset={I}{O}{N}]*/
  operator +(/*[exact=JSUInt31|powerset={I}{O}{N}]*/ other) => other;
}

/*member: foo:[exact=JSString|powerset={I}{O}{I}]*/
foo() {
  // The following '+' call will first say that it may call A::+,
  // String::+, or int::+. After all methods have been analyzed, we know
  // that a is of type String, and therefore, this method cannot call
  // A::+. Therefore, the type of the parameter of A::+ will be the
  // one given by the other calls.
  return a /*invoke: Value([exact=JSString|powerset={I}{O}{I}], value: "", powerset: {I}{O}{I})*/ +
      'foo';
}

/*member: main:[null|powerset={null}]*/
main() {
  A() /*invoke: [exact=A|powerset={N}{O}{N}]*/ + 42;
  foo();
}
