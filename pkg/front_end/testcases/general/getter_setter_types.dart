// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class G<T extends G<T>> {}

class C {
  void Function<T extends G>() get getter2 => throw '';
  void set setter2(void Function<T extends G>() _) {}
}

extension E<T extends G<T>> on T {
  T get getter1 => throw '';
  void set setter1(T t) {}
  void Function<T extends G>() get getter2 => throw '';
  void set setter2(void Function<T extends G>() _) {}
}

extension type ET<T extends G<T>>(T it) {
  T get getter1 => throw '';
  void set setter1(T t) {}
  void Function<T extends G>() get getter2 => throw '';
  void set setter2(void Function<T extends G>() _) {}
}