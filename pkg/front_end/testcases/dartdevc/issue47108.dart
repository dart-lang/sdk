// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {}

const constructorTearOff = C.new;

main() {
  // These instantiations are in a const context so they appear in the const pool.
  const instantiatedTearOff = constructorTearOff<int>;
  const instantiatedTearOff2 = constructorTearOff<int>;
  print(identical(instantiatedTearOff, instantiatedTearOff2)); // Prints true

  // These instantiations are not in a const context so they don't appear in the const pool.
  print(identical(constructorTearOff<String>, constructorTearOff<String>)); // Prints false
}