// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: method:Union([exact=JSDouble], [exact=JSUInt31])*/
// Called only via [foo2] with a small integer.
method(/*Union([exact=JSDouble], [exact=JSUInt31])*/ a) {
  return a;
}

const foo = method;

/*member: returnInt:[null|subclass=Object]*/
returnInt() {
  return foo(54);
}

/*member: main:[null]*/
main() {
  returnInt();
  method(55.2);
}
