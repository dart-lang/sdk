// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a non-used generative constructor does not prevent
// inferring types for fields.

class A {
  /*member: A.intField:[exact=JSUInt31|powerset={I}{O}{N}]*/
  final intField;

  /*member: A.stringField:Value([exact=JSString|powerset={I}{O}{I}], value: "foo", powerset: {I}{O}{I})*/
  final stringField;

  /*member: A.:[exact=A|powerset={N}{O}{N}]*/
  A() : intField = 42, stringField = 'foo';

  A.bar() : intField = 'bar', stringField = 42;
}

/*member: main:[null|powerset={null}]*/
main() {
  A();
}
