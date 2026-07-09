// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--no-omit-error-details

import 'package:expect/expect.dart';

final l = [0, 1, 2, 3, 4];

void main() {
  try {
    print(l[int.parse('6')]);
  } on IndexError catch (e) {
    Expect.contains(
      'Index out of range: index should be less than 5: 6',
      e.toString(),
    );
  }
}
