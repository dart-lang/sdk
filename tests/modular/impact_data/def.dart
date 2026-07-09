// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int totalCases = 1;

int runCases() {
  int cases = 0;
  const foos = [1, 2, 3];
  for (final foo in foos) {
    if (cases == 0) cases++;
    print(foo);
  }

  return cases;
}
