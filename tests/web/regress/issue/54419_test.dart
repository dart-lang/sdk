// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

// Ensure we don't omit as checks based on a subtype check ignoring nullability.

void foo<T>(T? x) {
  print(x as T);
}

void main() {
  if (!unsoundNullSafety) {
    Expect.throws(() => foo<int>(null));
  }
}
