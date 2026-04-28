// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=main
// compilerOption=--no-inlining
// compilerOption=--no-minify

@pragma('external-effect')
external void externalEffect(Object? o);

void nonExternalEffect(Object? o) {}

int use(int i) {
  print(i);
  return i;
}

@pragma('wasm:never-inline')
void main() {
  externalEffect(use(0));
  print(1);
  nonExternalEffect(use(2));
}
