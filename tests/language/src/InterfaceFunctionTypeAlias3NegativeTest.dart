// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deprecated syntax for introducing function type aliases
// using the interface keyword isn't valid anymore.

interface String f();

main() {
  InterfaceFunctionTypeAlias3NegativeTest.testMain();
}
