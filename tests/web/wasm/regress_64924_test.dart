// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--enable-asserts

import 'dart:convert';

import 'package:expect/expect.dart';

void main() {
  const n = 50000;

  // Array of nested objects: `[ {}, {}, ... ]`.
  final arrayOfObjects =
      json.decode('[${List.filled(n, '{}').join(',')}]') as List;
  Expect.equals(n, arrayOfObjects.length);

  // Array of nested arrays: `[ [], [], ... ]`.
  final arrayOfArrays =
      json.decode('[${List.filled(n, '[]').join(',')}]') as List;
  Expect.equals(n, arrayOfArrays.length);

  // Object with nested objects: `{ "0": {}, "1": {}, ... }`.
  final objectOfObjects =
      json.decode('{${List.generate(n, (i) => '"$i":{}').join(',')}}') as Map;
  Expect.equals(n, objectOfObjects.length);
}
