// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=runApp|foo
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=-O2

void main() => runApp();

@pragma('wasm:never-inline')
void runApp() {
  foo('1');
  foo('2');
  print(foo('3'));
  print(foo('4'));
}

@pragma('wasm:never-inline')
@pragma('wasm:pure-function')
dynamic foo(String arg) {
  'foo($arg)'.length;
  'bar($arg)'.length;
  return arg.length;
}
