// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that an instance field cannot be read as a static field.

class Foo {
  Foo() {}
  var x;
  void m() {}
}

main() {
  if (false) {
    var x = Foo.x;
    //          ^
    // [analyzer] STATIC_WARNING.STATIC_ACCESS_TO_INSTANCE_MEMBER
    // [cfe] Getter not found: 'x'.
    var m = Foo.m;
    //          ^
    // [analyzer] STATIC_WARNING.STATIC_ACCESS_TO_INSTANCE_MEMBER
    // [cfe] Getter not found: 'm'.
    Foo.m = 1;
    //  ^
    // [analyzer] STATIC_TYPE_WARNING.UNDEFINED_SETTER
    // [cfe] Setter not found: 'm'.
    Foo.x = 1;
    //  ^
    // [analyzer] STATIC_WARNING.STATIC_ACCESS_TO_INSTANCE_MEMBER
    // [cfe] Setter not found: 'x'.
  }
}
