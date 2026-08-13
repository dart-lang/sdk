// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Base<A, B> {}

extension on Object {
  B? foo<A extends Base<A, B>, B extends Base<A, B>>(B? orig) {
    return null;
  }
}

main() {
  print(Object().foo);
}
