// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=testSimple|testNullabilityOnly|testTypeParam
// typeFilter=NoMatch
// globalFilter=NoMatch

void main() {
  final runtimeTrue = int.parse('1') == 1;
  final int? maybeInt = runtimeTrue ? 1 : null;

  print(testSimple(maybeInt));
  print(testSimple('a'));
  print(testNullabilityOnly(maybeInt));
  print(testTypeParam<int>(maybeInt));
  print(testTypeParam<String>('a'));
}

@pragma('wasm:cfg')
bool testSimple(Object? x) => x is int;

@pragma('wasm:cfg')
bool testNullabilityOnly(int? x) => x is int;

@pragma('wasm:cfg')
bool testTypeParam<T>(Object? x) => x is T;
