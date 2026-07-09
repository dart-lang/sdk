// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo<T, S>(bool b, T t, S s) {
  if (t is Object) {
    return b ? t : s; // The upper bound is supposed to be nullable.
  } else {
    return null;
  }
}

main() {}
