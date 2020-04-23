// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: main:[null]*/
main() {
  typeLiteral();
  typeLiteralToString();
  typeLiteralSubstring();
}

/*member: typeLiteral:[exact=_Type]*/
typeLiteral() => Object;

/*member: typeLiteralToString:[null|exact=JSString]*/
typeLiteralToString() => (Object). /*invoke: [exact=_Type]*/ toString();

/*member: typeLiteralSubstring:[exact=JSString]*/
typeLiteralSubstring() {
  String name = (List). /*invoke: [exact=_Type]*/ toString();
  name = name. /*invoke: [null|exact=JSString]*/ substring(
      0, name. /*invoke: [null|exact=JSString]*/ indexOf('<'));
  return name;
}
