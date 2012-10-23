// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "some.prefixable.lib.dart";

class Unprefix {
  static final int foo = 43;

  static getSource() {
    return foo;
  }

  static getImport() {
    return Prefix.foo;
  }
}
