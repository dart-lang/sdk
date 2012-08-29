// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks
//
// When type checks are enabled, a type mismatch in a map literal is a compile-time error

main() {
  try {
    var m = const <String, String>{"a": 0};  // 0 is not a String.
  } on TypeError catch (error) {
    // not a catchable error
  }
}



