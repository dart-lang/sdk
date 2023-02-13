// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
main() {
  getRecord1();
  useRecord1();
}

// TODO(50701): This should be a record type.
/*member: getRecord1:[null|subclass=Object]*/
(num, num) getRecord1() => (1, 1);


// TODO(50701): This should be a constant or JSUint31.
/*member: useRecord1:[subclass=JSNumber]*/
useRecord1() {
  final r = getRecord1();
  return r.$1;
}
