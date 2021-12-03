// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E on int show get ceil, floor hide get floor {}

test(E e) {
  e.ceil; // Ok.
  e.ceil(); // Error.
  e.ceil = 42; // Error.

  e.floor; // Error.
  e.floor(); // Ok.
  e.ceil = 42; // Error.
}

main() {}
