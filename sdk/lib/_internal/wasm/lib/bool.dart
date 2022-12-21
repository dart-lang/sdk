// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class bool {
  // Note: this needs to be in `bool`, cannot be overridden in `_BoxedBool`. I
  // suspect the problem is there's an assumption in the front-end that `bool`
  // has one implementation class (unlike `double`, `int`, `String`) which is
  // the `bool` class itself. So when `runtimeType` is not overridden in
  // `bool`, in code like `x.runtimeType` where `x` is `bool`, direct call
  // metadata says that the member is `Object.runtimeType`.
  @override
  Type get runtimeType => bool;
}

@pragma("wasm:entry-point")
class _BoxedBool extends bool {
  // A boxed bool contains an unboxed bool.
  @pragma("wasm:entry-point")
  bool value = false;

  /// Dummy factory to silence error about missing superclass constructor.
  external factory _BoxedBool();

  @override
  bool operator ==(Object other) {
    return other is bool
        ? this == other // Intrinsic ==
        : false;
  }

  bool operator &(bool other) => this & other; // Intrinsic &
  bool operator ^(bool other) => this ^ other; // Intrinsic ^
  bool operator |(bool other) => this | other; // Intrinsic |
}
