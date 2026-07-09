// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type const Option<V>(Object? _value) {
  static const Option<Never> none = const None() as Option<Never>;

  V get value => _value is None ? (throw StateError("No Value")) : _value as V;
}

class None {
  const None();
}
