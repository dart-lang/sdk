// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Link<T> {
  factory Link.create() = LinkFactory.create;
  //                      ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_RETURN_TYPE
  // [cfe] The constructor function type 'LinkFactory<dynamic> Function()' isn't a subtype of 'Link<T> Function()'.
}

class A<T> {}

class LinkFactory<T> extends A<T> {
  factory LinkFactory.create() {
    return LinkFactory._();
  }

  LinkFactory._();
}

main() {
  new Link<int>.create();
}
