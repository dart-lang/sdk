// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Link<T> {

}

class A<T> {}

class LinkFactory<T> extends A<T> {
  factory LinkFactory.create() {
    return LinkFactory._();
  }

  LinkFactory._();
}

main() {

}
