// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null]*/
main() {
  typeLiteral();
  typeLiteralToString();
  typeLiteralSubstring();
}

/*member: typeLiteral:[exact=TypeImpl]*/
typeLiteral() => Object;

/*member: typeLiteralToString:[exact=JSString]*/
typeLiteralToString() => (Object). /*invoke: [exact=TypeImpl]*/ toString();

/*member: typeLiteralSubstring:[exact=JSString]*/
typeLiteralSubstring() {
  String name = (List). /*invoke: [exact=TypeImpl]*/ toString();
  name = name. /*invoke: [exact=JSString]*/ substring(
      0, name. /*invoke: [exact=JSString]*/ indexOf('<'));
  return name;
}
