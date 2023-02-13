// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Test<S, T> on S {
  T operator >>(T Function(S s) f) => f(this);
}

void test() {
  Object o = Object() Test<Object,Object>.>> ((Object o) => o);
  print(o);
}