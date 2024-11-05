// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma("wasm:entry-point")
final class BoxedBool implements bool {
  // A boxed bool contains an unboxed bool.
  @pragma("wasm:entry-point")
  final bool value;

  @pragma("wasm:entry-point")
  BoxedBool._(this.value);

  @override
  int get hashCode => this ? 1231 : 1237;

  @override
  String toString() => this ? "true" : "false";

  @override
  bool operator ==(Object other) {
    return other is bool
        ? this == other // Intrinsic ==
        : false;
  }

  @override
  bool operator &(bool other) => this & other; // Intrinsic &

  @override
  bool operator ^(bool other) => this ^ other; // Intrinsic ^

  @override
  bool operator |(bool other) => this | other; // Intrinsic |
}
