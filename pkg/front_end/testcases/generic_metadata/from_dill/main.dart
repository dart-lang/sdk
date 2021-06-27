// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

main() {
  C1 c1 = C1();
  C1 c2 = C1<T Function<T>(T)>();

  C2 c3 = C2();
  C2 c4 = C2<void Function<int>()>();

  C3 c5 = C3();
  C3 c6 = C3<T Function<T>()>();

  C4 c7 = C4();
  C4 c8 = C4<void Function<T>(T)>();

  C5 c9 = C5();
  C5 c10 = C5<T Function<T extends S Function<S>(S)>(T)>();

  C6 c11 = C6();
  C6 c12 = C6<
      T Function<T, S>(T, S, V Function<V extends S, U>(T, U, V, Map<S, U>))>();
}
