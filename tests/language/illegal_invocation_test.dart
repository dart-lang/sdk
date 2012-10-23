// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.
//
// Test for issue 1393.  Invoking a type alias or library prefix name caused
// an internal error in dartc
//
import "illegal_invocation_lib.dart" as foo;  /// 02: compile-time error

typedef void a();                 /// 01: compile-time error

class Foo {}                      /// 04: compile-time error

class Bar<T> {
  method() {
    T();                          /// 05: compile-time error
  }
}

main() {
  a();                           /// 01: continued

  // probably what the user meant was foo.foo(), but the qualifier refers
  // to the library prefix, not the method defined within the library.
  foo();                         /// 02: continued

  outer: for (int i =0 ; i < 1; i++) {
    outer();                     /// 03: compile-time error
  }

  Foo();                         /// 04: continued

  var bar = new Bar<int>();
  bar.method();                  /// 05: continued
}
