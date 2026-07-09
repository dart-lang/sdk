// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// compilerOption=--standalone
// globalFilter=Hello world

@pragma('wasm:never-inline')
void main() {
  // The purpose of this test is to verify we don't import JS string globals in
  // standalone mode.
  print('Hello world');
}
