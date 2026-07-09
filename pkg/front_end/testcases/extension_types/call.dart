// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E(T Function<T>(T) call) {}

method(E e) {
  int Function(int) a = e<int>; // Error
  int Function(int) b = e; // Error
}
