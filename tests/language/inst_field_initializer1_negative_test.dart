// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Catch illegal access to 'this' in initalized instance fields.

class A {
  A() {}
  int x = 5;
  int arr = new List(x); // Illegal access to 'this'.
  // Also not a compile const expression.
}

void main() {
  var foo = new A();
}
