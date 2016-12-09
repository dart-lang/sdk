// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// When type checks are enabled, a type mismatch in a list literal is a compile-time error

main() {
  var m = const
      <String>  /// 01: static type warning, checked mode compile-time error
      [0, 1];
}
