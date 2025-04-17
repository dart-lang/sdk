// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: getInt:[exact=JSUInt31|powerset={I}]*/
int get getInt => 42;

/*member: foo:Union(null, [exact=JSString|powerset={I}], [exact=JSUInt31|powerset={I}], powerset: {null}{I})*/
foo() {
  dynamic local = 3;
  for (
    int i = 0;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ < 10;
    i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ ++
  ) {
    switch (getInt) {
      case 42:
        break;
      default:
        local = 'hello';
    }
    if (i /*invoke: [subclass=JSPositiveInt|powerset={I}]*/ > 5) {
      return local;
    }
  }
  return null;
}

/*member: main:[null|powerset={null}]*/
void main() {
  foo();
}
