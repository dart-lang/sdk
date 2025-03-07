// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:[exact=JSUInt31|powerset=0]*/
// Called only via [foo2] with a small integer.
method(/*[exact=JSUInt31|powerset=0]*/ a) {
  return a;
}

const foo = method;

/*member: returnInt:[null|subclass=Object|powerset=1]*/
returnInt() {
  return foo(54);
}

/*member: main:[null|powerset=1]*/
main() {
  returnInt();
}
