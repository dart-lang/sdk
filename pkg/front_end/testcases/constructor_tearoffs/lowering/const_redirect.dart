// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that redirecting factory invocations in default values are handled for
// tear off parameters.

class Class {
  final List<Const> constants;

  Class(
      {this.constants = const [
        Const.impl(),
        Alias.impl(),
        ImplAlias<String>()
      ]});

  const Class.named(
      {this.constants = const [
        Const.impl(),
        Alias.impl(),
        ImplAlias<String>()
      ]});
}

typedef Alias = Const;

abstract class Const {
  const factory Const.impl() = _ConstImpl;
}

typedef ImplAlias<T extends num> = _ConstImpl<T>;

class _ConstImpl<T> implements Const {
  const _ConstImpl();
}

main() {}
