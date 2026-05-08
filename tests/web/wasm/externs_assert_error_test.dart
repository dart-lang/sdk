// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--enable-experimental-wasm-interop

import 'dart:_wasm';

external Memory get missingAnnotation;
//                  ^
// [web] This external getter returns a memory instance, but no annotation describing it was found

@pragma('wasm:memory-type', MemoryType(limits: Limits(1, 10)))
external Memory get validDefinition;

void main() {
  validDefinition.loadUint8(10);
  validDefinition.size;

  print(validDefinition);
  //    ^
  // [web] WebAssembly elements may only be referenced to directly call a method on them.

  print(validDefinition.fill);
  //                    ^
  // [web] This intrinsic extension member may not be torn off.
}

void invalidDynamicMemory(Memory memory) {
  memory.loadUint8(10);
  //     ^
  // [web] The receiver of this call must be a top-level variable describing the WebAssembly element.
}

int get notAConstant => 3;

void invalidNonConstantArguments() {
  validDefinition.loadUint8(0, offset: 12, align: 1);
  validDefinition.loadUint8(0, offset: notAConstant);
  //                                   ^
  // [web] The variable 'offset' is not a constant, only constant expressions are allowed.
  validDefinition.loadUint8(0, align: notAConstant);
  //                                  ^
  // [web] The variable 'align' is not a constant, only constant expressions are allowed.
}
