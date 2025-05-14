// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: method:Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
// Called via [foo] with integer then double.
method(
  /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ a,
) {
  return a;
}

const foo = method;

/*member: returnNum:[null|subclass=Object|powerset=1]*/
returnNum(
  /*Union([exact=JSNumNotInt|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/ x,
) {
  return foo(x);
}

/*member: main:[null|powerset=1]*/
main() {
  returnNum(10);
  returnNum(10.5);
}
