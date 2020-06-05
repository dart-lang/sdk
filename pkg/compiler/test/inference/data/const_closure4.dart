// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method:Union([exact=JSDouble], [exact=JSUInt31])*/
// Called via [foo] with integer then double.
method(/*Union([exact=JSDouble], [exact=JSUInt31])*/ a) {
  return a;
}

const foo = method;

/*member: returnNum:[null|subclass=Object]*/
returnNum(/*Union([exact=JSDouble], [exact=JSUInt31])*/ x) {
  return foo(x);
}

/*member: main:[null]*/
main() {
  returnNum(10);
  returnNum(10.5);
}
