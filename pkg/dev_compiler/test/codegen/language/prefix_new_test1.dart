// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library PrefixTest1;

import "prefix_test2.dart" as test2;

class Prefix {
  static const int foo = 43;

  static getSource() {
    return foo;
  }

  static getImport() {
    return test2.Prefix.foo;
  }
}
