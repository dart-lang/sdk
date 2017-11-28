// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Link<T> {
  factory Link.create() = LinkFactory<T>.create; //# 00: compile-time error
}

class LinkFactory<T> {
  factory LinkFactory.create() {
    return null;
  }
  factory LinkFactory.Foo() = Foo<T>; //# 00: compile-time error
}

main() {
  new Link<int>.create(); //# 00: continued
}
