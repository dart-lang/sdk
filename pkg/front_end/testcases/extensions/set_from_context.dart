// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f<T>(Set<T> s) {
  print(s.runtimeType);
}

extension E<T> on Set<T> {
  method() {
    print(runtimeType);
  }
}

Set<int> set = {};

void main() {
  f({});
  f({1});
  f({...set});
  E({}).method();
  E({1}).method();
  E({...set}).method();
}
