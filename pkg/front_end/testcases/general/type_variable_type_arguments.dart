// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void method<S>(S<int> a) {}

class Class<T> {
  void method<S>(T<int> a, S<int> b) {
    local<U>(U<int> a) {}
  }
}

main() {}
