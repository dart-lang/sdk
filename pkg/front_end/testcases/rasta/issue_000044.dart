// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// Parse error: but the parser should recover and create something that looks
// like `a b(c) => d`.
a b(c) = d;

class C {
  // Good constructor.
  const C.constant();

  // Bad constructor: missing factory keyword (and additional formals).
  C.missingFactoryKeyword() = C.constant;

  // Good redirecting const factory constructor.
  const factory C.good() = C.constant;

  // Parse error, the parser should recover and create a redirecting factory
  // constructor body.
  C notEvenAConstructor(a) = h;
}

main() {
  C c = null;
  print(const C.constant());
  print(const C.missingFactoryKeyword());
  print(const C.good());
  print(new C.constant().notEvenAConstructor(null));
}
