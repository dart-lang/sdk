// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class GenericClass<T> {}

extension GenericExtension<T> on GenericClass<T> {
  set setter(T value) {}
}

error() {
  GenericClass<int> genericClass = new GenericClass<int>();
  expect(null, GenericExtension<double>(genericClass).setter = null);
}


expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}