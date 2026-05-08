// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=tryBlocks.*
// tableFilter=NoMatch
// globalFilter=NoMatch
// typeFilter=NoMatch
// compilerOption=--no-minify

// Tests Wasm `catch` block tags based on Dart types being caught.

import 'dart:js_interop';

void main() {
  tryBlocks1();
  tryBlocks2();
  tryBlocks3();
}

// Catch `JSAny`: this should generate a Wasm `try` that catches both Dart and
// JS exceptions.
@pragma('wasm:never-inline')
void tryBlocks1() {
  try {
    f();
  } on JSAny {
    print("Caught JSAny");
  }
}

// Catch `Object`: same as above.
@pragma('wasm:never-inline')
void tryBlocks2() {
  try {
    f();
  } on Object {
    print("Caught Object");
  }
}

// Catch a non-interop type: this shouldn't catch JS exceptions, so the Wasm
// code should only catch the Dart exception tag.
@pragma('wasm:never-inline')
void tryBlocks3() {
  try {
    f();
  } on Error {
    print("Caught Error");
  }
}

@pragma('wasm:never-inline')
void f() {
  if (int.parse('1') == 0) {
    throw "Hi";
  }
}
