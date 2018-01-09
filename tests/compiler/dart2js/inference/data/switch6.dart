// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: foo:[null|exact=JSUInt31]*/
foo(int /*[subclass=JSInt]*/ x) {
  var a;
  do {
    // add extra locals scope
    switch (x) {
      case 1:
        a = 1;
        break;
      case 2:
        a = 2;
        break;
    }
  } while (false);

  return a;
}

/*element: main:[null]*/
main() {
  foo(new DateTime.now(). /*[exact=DateTime]*/ millisecondsSinceEpoch);
}
