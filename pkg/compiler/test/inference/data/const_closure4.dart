// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/
// Called via [foo] with integer then double.
method(
  /*Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/ a,
) {
  return a;
}

const foo = method;

/*member: returnNum:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
returnNum(
  /*Union([exact=JSNumNotInt|powerset={I}{O}{N}], [exact=JSUInt31|powerset={I}{O}{N}], powerset: {I}{O}{N})*/ x,
) {
  return foo(x);
}

/*member: main:[null|powerset={null}]*/
main() {
  returnNum(10);
  returnNum(10.5);
}
