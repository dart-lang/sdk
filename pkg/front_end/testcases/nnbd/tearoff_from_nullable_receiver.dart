// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int call() => 0;
}

functionContext(int Function() f) {}

nullableFunctionContext(int Function()? f) {}

foo<T extends C?>(C? c, T t, T? nt) {
  functionContext(null as C?); // Error.
  nullableFunctionContext(null as C?); // Error.
  functionContext(c); // Error.
  nullableFunctionContext(c); // Error.
  functionContext(t); // Error.
  nullableFunctionContext(t); // Error.
  functionContext(nt); // Error.
  nullableFunctionContext(nt); // Error.
}

bar<T extends C>(C c, T t) {
  functionContext(c); // Shouldn't result in a compile-time error.
  nullableFunctionContext(c); // Shouldn't result in a compile-time error.
  functionContext(t); // Shouldn't result in a compile-time error.
  nullableFunctionContext(t); // Shouldn't result in a compile-time error.
}

main() {}
