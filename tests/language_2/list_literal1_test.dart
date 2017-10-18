// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// A type mismatch in a list literal is a compile-time error

main() {
  var m = const
      <String> //# 01: compile-time error
      [0, 1];
}
