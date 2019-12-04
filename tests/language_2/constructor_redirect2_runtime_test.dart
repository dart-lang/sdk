// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Redirection constructors must not have a function body.

class A {
  var x;
  A(this.x) {}

  // Redirecting constructor must not have a function body.


  // Redirecting constructor must not initialize any fields.


  // Redirecting constructor must not have initializing formal parameters.


  // Redirection constructors must not call super constructor.

}

main() {
  new A(3);




}
