// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test insures that statically initialized variables, fields, and
// parameters report compile-time errors.



class A {



  A() {

  }
  method(
      [

      g = "String"]) {
    return g;
  }
}

main() {}
