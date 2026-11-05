// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// printSourcePositions
// functionFilter=testAdd|loopSum
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0
// compilerOption=--cfg

void main(List<String> args) {
  print(testAdd(args.length, 42));
  print(loopSum(args.length));
}

@pragma('wasm:cfg')
int testAdd(int a, int b) {
  return a + b;
}

@pragma('wasm:cfg')
int loopSum(int n) {
  int sum = 0;
  for (int i = 0; i < n; i++) {
    sum = sum + i;
  }
  return sum;
}
