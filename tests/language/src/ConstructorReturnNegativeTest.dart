// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart spec 0.03, section 11.10 - generative constructors cannot have return
// statements in the form 'return e;' where 'e' is any arbitrary expression.
class A {
  A() { return null; }
}

main() {
  A a = new A();
}
