// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: method:[exact=JSUInt31]*/
// Called only via [foo2] with a small integer.
method(/*[exact=JSUInt31]*/ a) {
  return a;
}

/*element: foo:[subclass=Closure]*/
const foo = method;

/*element: returnInt:[null|subclass=Object]*/
returnInt() {
  return foo(54);
}

/*element: main:[null]*/
main() {
  returnInt();
}
