// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
main() {
  useRecord1();
  useRecord2();
  useRecord3();
}

// TODO(50701): This should be a record type.
/*member: getRecord1:[null|subclass=Object]*/
(num, num) getRecord1() => (1, 1);
/*member: getRecord2:[null|subclass=Object]*/
(bool, bool) getRecord2() => (true, false);
/*member: getRecord3:[null|subclass=Object]*/
dynamic getRecord3() => ("a", "b");

// TODO(50701): This should be a constant or JSUint31.
/*member: useRecord1:[subclass=JSNumber]*/
useRecord1() {
  final r = getRecord1();
  return r.$1;
}

/*member: useRecord2:[subtype=bool]*/
useRecord2() {
  final r = getRecord2();
  return r.$2;
}

/*member: useRecord3:Union([exact=JSBool], [exact=JSString], [exact=JSUInt31])*/
useRecord3() {
  final r = getRecord3();
  return r.$2;
}
