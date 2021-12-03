// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' as prefixedCore;
import 'dart:core';

extension type E0 on int hide operator * {}
extension type E1 on int hide get isEven {}
extension type E2<T> on List<T> hide set length {}
extension type E3 on int hide num {}
extension type E4 on List<int> hide prefixedCore.Iterable<int> {} // Error?
extension type E5 on List hide prefixedCore.Iterable {} // Error?
extension type E6 on List<int> hide Iterable<int> {}

abstract class A {
  A operator *(A other);
}

class B<X> implements A {
  bool get foo => throw 42;
  A operator *(A other) => throw 42;
}

class C extends B<int> {
  void set bar(int value) {}
  void baz() {}
}

extension type E on C hide A, B<int>, operator *, get foo, set bar, baz {}

main() {}
