// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension E<T> on T {
  T Function(T) get f => (T t) => t;
}

method1<S>(S s) {
  S Function(S) f = s.f;
}

method2<S extends dynamic>(S s) {
  throws(() => s.f);
}

main() {}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    return;
  }
  throw 'Expected exception';
}
