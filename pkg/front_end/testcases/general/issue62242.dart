// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E(Object? it) {}

foo<X extends E>(Function(X) x, Function(E) e) {
  var list = [x, e];
  x = list[0];
}
