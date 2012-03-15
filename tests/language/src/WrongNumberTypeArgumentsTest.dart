// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Map takes 2 type arguments.
Map<String> foo;  /// 00: static type warning

main() {
  foo = null;  /// 00: continued
  var bar = new Map<String>();  /// 01: compile-time error
}
