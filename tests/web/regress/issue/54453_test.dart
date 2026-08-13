// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure binary operations are correctly handled for range-like values in
// SSA's value range analyzer.

void main() {
  int counter = 0;
  for (int i = 0; i < 5; i++) {
    counter += counter;
  }
}
