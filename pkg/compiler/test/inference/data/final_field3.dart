// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we are analyzing field parameters correctly.

class A {
  /*member: A.dynamicField:Union([exact=JSString|powerset=0], [exact=JSUInt31|powerset=0], powerset: 0)*/
  final dynamicField;

  /*member: A.:[exact=A|powerset=0]*/
  A() : dynamicField = 42;

  /*member: A.bar:[exact=A|powerset=0]*/
  A.bar(
    this. /*Value([exact=JSString|powerset=0], value: "foo", powerset: 0)*/ dynamicField,
  );
}

/*member: main:[null|powerset=1]*/
main() {
  A();
  A.bar('foo');
}
