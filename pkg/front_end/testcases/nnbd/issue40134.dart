// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for http://dartbug.com/40134.

class GenericMethodBounds<T> {
  Type get t => T;
  GenericMethodBounds<E> foo<E extends T>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(T)>() =>
      new GenericMethodBounds<E>();
}

class GenericMethodBoundsDerived extends GenericMethodBounds<num> {
  GenericMethodBounds<E> foo<E extends num>() => new GenericMethodBounds<E>();
  GenericMethodBounds<E> bar<E extends void Function(num)>() =>
      new GenericMethodBounds<E>();
}

main() {}
