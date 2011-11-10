// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile time error for factories with parametrized types.


main() {
  // Compile time error, wrong factory method.
  var a = new Link<int>.create();
}

interface Link<T> factory LinkFactory {
  Link.create();
}

class LinkFactory {
  // Compile time error: should be Link<T>.create().
  factory Link.create() {
    return null;
  }
}
