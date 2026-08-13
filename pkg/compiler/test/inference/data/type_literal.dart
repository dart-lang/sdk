// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: main:[null|powerset={null}]*/
main() {
  typeLiteral();
  typeLiteralToString();
  typeLiteralSubstring();
}

/*member: typeLiteral:[exact=_Type|powerset={N}{O}{N}]*/
typeLiteral() => Object;

/*member: typeLiteralToString:[exact=JSString|powerset={I}{O}{I}]*/
typeLiteralToString() =>
    (Object). /*invoke: [exact=_Type|powerset={N}{O}{N}]*/ toString();

/*member: typeLiteralSubstring:[exact=JSString|powerset={I}{O}{I}]*/
typeLiteralSubstring() {
  String name = (List). /*invoke: [exact=_Type|powerset={N}{O}{N}]*/ toString();
  name = name. /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ substring(
    0,
    name. /*invoke: [exact=JSString|powerset={I}{O}{I}]*/ indexOf('<'),
  );
  return name;
}
