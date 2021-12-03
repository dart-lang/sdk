// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Tests to ensure that narrowing type information does not discard late
// sentinel values unintentionally.

class Foo<T> {
  // Since `List<T>` contains a free type variable, any access of [x] will be
  // immediately followed by a narrowing to the appropriate instantiation of
  // `List<T>`. This narrowing should not exclude the late sentinel value from
  // the abstract value.
  late final List<T> x;
}

void main() {
  Foo<int> foo = Foo();
  Expect.throws(() => foo.x);
  foo.x = const [];
  Expect.isTrue(foo.x.isEmpty);
}
