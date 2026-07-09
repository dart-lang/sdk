// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<T> {
  const A(o);
}

void Function<@A<int>() T>(T)? f;

// TODO(johnniwinther): Report errors on annotations here.
typedef F = void Function<@A<bool>() T>(T);

typedef void G<@A<dynamic>() T>(T t);

void method1<@A<String>() T>(T t) {}

void method2(void Function<@A<num>() T>(T) f) {}

// TODO(johnniwinther): Report errors on annotations here.
class Class<T extends void Function<@A<void>() S>(S)> {}

main() {
  void local<@A<double>() T>(T t) {}

  void Function<@A<int>() T>(T)? f;
}
