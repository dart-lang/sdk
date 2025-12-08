// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

testNotCaptured() {
  int a = 0;
  return a;
}

testCaptured() {
  int a = 0;
  return () => a;
}

testForCounterNotCaptured() {
  int a = 0;
  for (int i = 0; i < 10; i++) {
    a += i;
  }
  return a;
}

testForCounterCaptured() {
  List<Function> closures = [];
  for (int i = 0; i < 10; i++) {
    closures.add(() => i);
  }
  return closures;
}
