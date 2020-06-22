// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Typed as dynamic to also test spreading a value of type dynamic.
final dynamic list = [1, 2, 3, 4];
final dynamic map = {1: 1, 2: 2, 3: 3, 4: 4};
final dynamic set = {1, 2, 3, 4};

void main() {
  dynamic nonIterable = 3;
  Expect.throwsTypeError(() => <int>[...nonIterable]);
  Expect.throwsTypeError(() => <int>{...nonIterable});

  dynamic nonMap = 3;
  Expect.throwsTypeError(() => <int, int>{...nonMap});

  dynamic wrongIterableType = <String>["s"];
  Expect.throwsTypeError(() => <int>[...wrongIterableType]);
  Expect.throwsTypeError(() => <int>{...wrongIterableType});

  dynamic wrongKeyType = <String, int>{"s": 1};
  dynamic wrongValueType = <int, String>{1: "s"};
  Expect.throwsTypeError(() => <int, int>{...wrongKeyType});
  Expect.throwsTypeError(() => <int, int>{...wrongValueType});

  // Mismatched collection types.
  Expect.throwsTypeError(() => <int>[...map]);
  Expect.throwsTypeError(() => <int, int>{...list});
  Expect.throwsTypeError(() => <int, int>{...set});
  Expect.throwsTypeError(() => <int>{...map});
}
