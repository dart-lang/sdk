// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

T id<T>(T value) => value;

main() async {
  FutureOr<int> x = 1 + id(1);

  FutureOr<int> y = 1 + id(1)
    ..checkStaticType<Exactly<int>>();
  FutureOr<int> z = 1 + contextType(1)
    ..checkStaticType<Exactly<int>>();
}

extension<T> on T {
  void checkStaticType<R extends Exactly<T>>() {}
}

typedef Exactly<T> = T Function(T);
T contextType<T>(Object? o) => o as T;
