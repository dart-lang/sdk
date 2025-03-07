// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset=1]*/
main() {
  typeLiteral();
  typeLiteralToString();
  typeLiteralSubstring();
}

/*member: typeLiteral:[exact=_Type|powerset=0]*/
typeLiteral() => Object;

/*member: typeLiteralToString:[exact=JSString|powerset=0]*/
typeLiteralToString() =>
    (Object). /*invoke: [exact=_Type|powerset=0]*/ toString();

/*member: typeLiteralSubstring:[exact=JSString|powerset=0]*/
typeLiteralSubstring() {
  String name = (List). /*invoke: [exact=_Type|powerset=0]*/ toString();
  name = name. /*invoke: [exact=JSString|powerset=0]*/ substring(
    0,
    name. /*invoke: [exact=JSString|powerset=0]*/ indexOf('<'),
  );
  return name;
}
