// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<X> {
  void m1({List<void Function(X)> xs = const []}) {}
  void m2({List<void Function<Y extends List<X>>(Y)> xs = const []}) {}
}

void main() => C().m1();
