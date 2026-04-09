// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("vm:entry-point")
final class _Closure implements Function {
  factory _Closure._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:external-name", "Closure_equals")
  external bool operator ==(Object other);

  int get hashCode {
    int hash = _hash;
    if (hash == 0) {
      hash = _computeHash();
    }
    return hash;
  }

  @pragma("vm:entry-point")
  _Closure get call => this;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external int get _hash;

  @pragma("vm:external-name", "Closure_computeHash")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  external int _computeHash();
}
