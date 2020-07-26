// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

abstract class Link<T> {
  factory Link.Foo() = LinkFactory<T>.Foo;
  //                   ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
  // [cfe] The constructor function type 'LinkFactory<T> Function()' isn't a subtype of 'Link<T> Function()'.
}

class LinkFactory<T> {
  factory LinkFactory.Foo() = Foo<T>;
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_NON_CLASS
  // [cfe] Couldn't find constructor 'Foo'.
  //                          ^
  // [cfe] Redirection constructor target not found: 'Foo'
}

main() {
  Expect.throws(() => new Link<int>.Foo());
}
