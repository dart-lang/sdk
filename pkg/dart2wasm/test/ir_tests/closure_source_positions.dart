// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// printSourcePositions
// functionFilter=makeAdder.*closure
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0

// The instructions at the start of a closure, which capture its parameters,
// are mapped to the closure, like the start of any other function.

void main(List<String> args) {
  print(makeAdder(args.length)(1)());
}

@pragma('wasm:never-inline')
int Function() Function(int) makeAdder(int x) {
  return (int y) {
    return () => x + y;
  };
}
