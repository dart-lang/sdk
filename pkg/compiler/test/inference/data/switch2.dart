// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: foo:Value([null|exact=JSString|powerset={null}{I}], value: "two", powerset: {null}{I})*/
foo(int /*[subclass=JSInt|powerset={I}]*/ x) {
  var a;
  switch (x) {
    case 1:
      a = "two";
      break;
    case 2:
      break;
  }

  return a;
}

/*member: main:[null|powerset={null}]*/
main() {
  foo(
    new DateTime.now()
        . /*[exact=DateTime|powerset={N}]*/ millisecondsSinceEpoch,
  );
}
