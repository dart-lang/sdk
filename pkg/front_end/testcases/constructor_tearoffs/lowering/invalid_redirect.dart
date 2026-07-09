// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Link<T> {
  factory Link.create1() = LinkFactory<T>.create;
  factory Link.create2() = LinkFactory<T, T>.create;
  factory Link.create3(int i) = LinkFactory.create;
  factory Link.create4({int i}) = LinkFactory.create;
}

class LinkFactory {
  factory Link.create() {
    return null;
  }
}

main() {}
