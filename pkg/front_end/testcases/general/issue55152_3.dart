// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `const Alias2.impl()` is at nestedness level 2 of default values, and we
// need to make sure we don't crash in that case. Compiling the program still
// results in a compile-time error, due to function expressions not being const
// values, but it shouldn't crash.
class Class {
  const Class.named(
      {dynamic x = (({dynamic y = const [Alias2.impl()]}) =>
          const [Alias.impl()])});
}

typedef Alias<X> = Const<X>;

typedef Alias2<X> = Const<X>;

abstract class Const<X> {
  const factory Const.impl() = _ConstImpl;
}

class _ConstImpl<T> implements Const<T> {
  const _ConstImpl();
}
