// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: getInt:[exact=JSUInt31]*/
int get getInt => 42;

// TODO(http://dartbug.com/52170): Return type should include int. The return
// within the loop can and will be invoked with local = 3.
/*member: foo:Value([null|exact=JSString], value: "hello")*/
foo() {
  dynamic local = 3;
  for (int i = 0;
      i /*invoke: [subclass=JSPositiveInt]*/ < 10;
      i /*invoke: [subclass=JSPositiveInt]*/ ++) {
    switch (getInt) {
      case 42:
        break;
      default:
        local = 'hello';
    }
    if (i /*invoke: [subclass=JSPositiveInt]*/ > 5) {
      return local;
    }
  }
  return null;
}

/*member: main:[null]*/
void main() {
  foo();
}
