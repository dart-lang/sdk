// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a non-used generative constructor does not prevent
// inferring types for fields.

class A {
  /*member: A.intField:[exact=JSUInt31|powerset=0]*/
  final intField;

  /*member: A.stringField:Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/
  final stringField;

  /*member: A.:[exact=A|powerset=0]*/
  A() : intField = 42, stringField = 'foo';

  A.bar() : intField = 'bar', stringField = 42;
}

/*member: main:[null|powerset=1]*/
main() {
  A();
}
