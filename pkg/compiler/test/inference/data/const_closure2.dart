// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/
// Called via [foo] with integer then double.
method(
  /*Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ a,
) {
  return a;
}

const foo = method;

/*member: returnNum:[null|subclass=Object|powerset={null}{IN}]*/
returnNum(
  /*Union([exact=JSNumNotInt|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {I})*/ x,
) {
  return foo(x);
}

/*member: main:[null|powerset={null}]*/
main() {
  returnNum(10);
  returnNum(10.5);
}
