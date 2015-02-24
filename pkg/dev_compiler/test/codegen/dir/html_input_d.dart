// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library html_input_d;

int fib(int n) => _fib(n, new Map<int, int>());

int _fib(int n, Map<int, int> seen) {
  if (n == 0 || n == 1) return 1;
  if (seen[n] != null) return seen[n];
  seen[n] = _fib(n - 1, seen) + _fib(n - 2, seen);
  return seen[n];
}
