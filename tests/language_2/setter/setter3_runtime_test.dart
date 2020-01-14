// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that setters cannot have defined, non-void return types.
// Note: The language specification specifies the absence of a type means
// it is dynamic, however you cannot specify dynamic.

class A {
  set foo(x) {}
  void set bar(x) {}


}

main() {
  new A();
}
