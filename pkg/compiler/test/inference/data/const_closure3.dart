// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:[exact=JSUInt31|powerset={I}{O}]*/
// Called only via [foo2] with a small integer.
method(/*[exact=JSUInt31|powerset={I}{O}]*/ a) {
  return a;
}

const foo = method;

/*member: returnInt:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
returnInt() {
  return foo(54);
}

/*member: main:[null|powerset={null}]*/
main() {
  returnInt();
}
