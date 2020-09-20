// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(Never x, Never? y) {
  var local0 = y.toString(); // Not an error.
  var local1 = y.hashCode; // Not an error.

  x.foo(); // Not an error.
  x.bar; // Not an error.
  x.baz = 42; // Not an error.
  x(); // Not an error.
  x[42]; // Not an error.
  x[42] = 42; // Not an error.
  x++; // Not an error.
  x += 1; // Not an error.
  y?.foo(); // Not an error.
  y?.bar; // Not an error.
  y?.baz = 42; // Not an error.
  y?.call(); // Not an error.
  y?[42]; // Not an error.
  y?[42] = 42; // Not an error.

  x?.foo(); // Warning.
  x?.bar; // Warning.
  x?.baz = 42; // Warning.
  x?[42]; // Warning.
  x?[42] = 42; // Warning.

  y.foo(); // Error.
  y.bar; // Error.
  y.baz = 42; // Error.
  y(); // Error.
  y++; // Error.
  y += 1; // Error.
  y[42]; // Error.
  y[42] = 42; // Error.
}

main() {}
