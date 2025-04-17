// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
// Called only via [foo2] with a small integer.
method(
  /*Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ a,
) {
  return a;
}

const foo = method;

/*member: returnInt:[null|subclass=Object|powerset={null}{IN}]*/
returnInt() {
  return foo(54);
}

/*member: main:[null|powerset={null}]*/
main() {
  returnInt();
  method(55.2);
}
