// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for Issue 27354.

int total = 1;
void inc() => total++ < 10 ? null : throw "do not loop forever!";

void main() {
  // Problem was moving the load of 'total' inside the loop.
  int count = null ?? total;
  for (int i = 0; i < count; i++) inc();
}
