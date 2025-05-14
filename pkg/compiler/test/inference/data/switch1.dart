// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:[exact=JSString|powerset=0]*/
foo(int /*[subclass=JSInt|powerset=0]*/ x) {
  var a = "one";
  switch (x) {
    case 1:
      a = "two";
      break;
    case 2:
      break;
  }

  return a;
}

/*member: main:[null|powerset=1]*/
main() {
  foo(
    new DateTime.now(). /*[exact=DateTime|powerset=0]*/ millisecondsSinceEpoch,
  );
}
