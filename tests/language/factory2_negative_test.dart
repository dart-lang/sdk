// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile time error for factories with parameterized types.

abstract class Link<T> {
  factory Link.create() = LinkFactory<T>.create;
}

class LinkFactory {
  //   Compile time error: should be LinkFactory<T> to match abstract class above
  factory Link.create() {
    return null;
  }
}

main() {
  var a = new Link.create(); // Equivalent to new Link<dynamic>.create().
}
