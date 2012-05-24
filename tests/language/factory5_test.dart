// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Link<T> default LinkFactory {
  Link.create();
}

class LinkFactory<T> {
  factory Link.create() { return null; }
  factory Foo.create() { return null; }  /// 00: static type warning
}

main() {
  var a = new Link<int>.create();
}
