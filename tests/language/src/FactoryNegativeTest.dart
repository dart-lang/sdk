// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile time error for factories with parameterized types.

interface Link<T> default LinkFactory {
  Link.create();
}

class LinkFactory {   // Compile time error: should be LinkFactory<T> to match interface above
  factory Link.create() {
    return null;
  }
}

main() {
  var a = new Link<int>.create();
}
