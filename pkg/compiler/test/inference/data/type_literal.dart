// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  typeLiteral();
  typeLiteralToString();
  typeLiteralSubstring();
}

/*member: typeLiteral:[exact=_Type|powerset={N}{O}]*/
typeLiteral() => Object;

/*member: typeLiteralToString:[exact=JSString|powerset={I}{O}]*/
typeLiteralToString() =>
    (Object). /*invoke: [exact=_Type|powerset={N}{O}]*/ toString();

/*member: typeLiteralSubstring:[exact=JSString|powerset={I}{O}]*/
typeLiteralSubstring() {
  String name = (List). /*invoke: [exact=_Type|powerset={N}{O}]*/ toString();
  name = name. /*invoke: [exact=JSString|powerset={I}{O}]*/ substring(
    0,
    name. /*invoke: [exact=JSString|powerset={I}{O}]*/ indexOf('<'),
  );
  return name;
}
