// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension<R, T> on R Function(T) {
  Type get returnType => R;
  Type get parameterType => T;
}

class Class<T extends Class<T>> {}

class Subclass extends Class<Subclass> {}

extension<T extends Class<T>> on dynamic Function<S extends T>(T, S) {
  Type get parameterType => T;
}

main() {
  int local1(int i) => i;

  print(local1.returnType);
  print(local1.parameterType);

  Subclass local2<S extends Subclass>(Subclass a, S b) => a;

  print(local2.parameterType);
}
