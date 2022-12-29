// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Mixin {}
inline class Class1 {
  final int it;

  Class1(this.it);
}
inline class Class2 = Object with Mixin;
inline class Class3<T> {
  final List<T> it;

  Class3(this.it);
}

method(Class1 c1, Class3<int> c3) {}