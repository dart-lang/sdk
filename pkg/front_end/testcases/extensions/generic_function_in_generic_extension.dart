// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Regression test for missing substitution of type variable used in the
/// return type of a generic method on a generic extension.

class Class<T> {}

extension Extension<T> on Class<T> {
  R method<R>(T t) => null;
}

main() {
  new Class<int>().method(0)?.toString();
}