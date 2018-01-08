// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a non-used generative constructor does not prevent
// inferring types for fields.

class A {
  /*element: A.intField:[exact=JSUInt31]*/
  final intField;

  /*element: A.stringField:Value([exact=JSString], value: "foo")*/
  final stringField;

  /*element: A.:[exact=A]*/
  A()
      : intField = 42,
        stringField = 'foo';

  A.bar()
      : intField = 'bar',
        stringField = 42;
}

/*element: main:[null]*/
main() {
  new A();
}
