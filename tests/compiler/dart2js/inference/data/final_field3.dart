// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test that we are analyzing field parameters correctly.

class A {
  /*member: A.dynamicField:Union([exact=JSString], [exact=JSUInt31])*/
  final dynamicField;

  /*member: A.:[exact=A]*/
  A() : dynamicField = 42;

  /*member: A.bar:[exact=A]*/
  A.bar(this. /*Value([exact=JSString], value: "foo")*/ dynamicField);
}

/*member: main:[null]*/
main() {
  new A();
  new A.bar('foo');
}
