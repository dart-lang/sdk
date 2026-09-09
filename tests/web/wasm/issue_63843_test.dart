// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:expect/expect.dart';

final class CustomType implements Type {
  const CustomType();
}

final Type customType = const CustomType();

void main() {
  Expect.isTrue(identical(customType, const CustomType()));
  final copy = SplayTreeSet<int>.from([3, 1, 2]).toSet();
  Expect.listEquals([1, 2, 3], copy.toList());
}
