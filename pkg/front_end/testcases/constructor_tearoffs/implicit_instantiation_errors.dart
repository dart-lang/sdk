// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t, int i) => t;
T Function<T>(T, int i)? alias = id;

class Class {
  T call<T>(T t, int i) => t;
}

method(int Function(int, int?) f) {}

test() {
  Class c = new Class();
  int Function(int, int) f = alias;
  int Function(int, int?)? g;
  g = alias;
  int Function(int, int?) h = c;
  g = c;
  method(alias);
}

main() {}
