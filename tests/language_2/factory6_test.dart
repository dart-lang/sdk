// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class Link<T> {
  factory Link.Foo() = LinkFactory<T>.Foo; // //# 00: compile-time error
}

class LinkFactory<T> {
  factory LinkFactory.Foo() = Foo<T>; // //# 00: continued
}

main() {
  Expect.throws(() => new Link<int>.Foo()); //# 00: continued
}
