// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:[null|exact=JSUInt31|powerset={null}{I}{O}{N}]*/
foo(int /*[subclass=JSInt|powerset={I}{O}{N}]*/ x) {
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

/*member: main:[null|powerset={null}]*/
main() {
  foo(
    new DateTime.now()
        . /*[exact=DateTime|powerset={N}{O}{N}]*/ millisecondsSinceEpoch,
  );
}
