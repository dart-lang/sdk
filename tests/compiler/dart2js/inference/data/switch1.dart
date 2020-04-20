// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: foo:[exact=JSString]*/
foo(int /*[subclass=JSInt]*/ x) {
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

/*member: main:[null]*/ main() {
  foo(new DateTime.now(). /*[exact=DateTime]*/ millisecondsSinceEpoch);
}
