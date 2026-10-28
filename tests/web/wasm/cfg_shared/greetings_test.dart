// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2wasmOptions=--extra-compiler-option=--cfg

class Greeter {
  @pragma('wasm:never-inline')
  @pragma('wasm:cfg')
  static String greeting() => 'Hello, world!';
}

@pragma('wasm:never-inline')
@pragma('wasm:cfg')
void greet(String message) => print(message);

void main() => greet(Greeter.greeting());
