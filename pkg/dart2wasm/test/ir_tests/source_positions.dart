// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// printSourcePositions
// functionFilter=addOne|addTwo
// typeFilter=NoMatch
// globalFilter=NoMatch
// compilerOption=-O0
// compilerOption=--inlining

void main(List<String> args) {
  print(addTwo(args.length));
}

@pragma('wasm:never-inline')
int addTwo(int x) {
  final result = addOne(x) + 1;
  return result;
}

@pragma('wasm:prefer-inline')
int addOne(int x) => x + 1;
