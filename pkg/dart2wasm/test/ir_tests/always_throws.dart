// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=foo
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0

void main() {
  foo();
}

void foo() {
  print('foo');
  print(fooAlwaysThrows());
}

Never fooAlwaysThrows() {
  print('fooAlwaysThrows');
  throw Object();
}
