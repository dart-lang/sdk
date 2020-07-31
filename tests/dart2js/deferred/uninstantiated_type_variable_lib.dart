// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All of these types are considered instantiated because we create an instance
// of [C].

class A {}

class Box<T> {
  int value;
}

class B<T> extends A {
  final box = new Box<T>();
}

class C extends B<N> {}

// N is not instantiated, but used as a type argument in C and indirectly in a
// Box<N>.
// If we don't mark it as part of the output unit of C, we accidentally add it
// to the main output unit. However, A is in the output unit of C so we fail
// when trying to finalize the declaration of N while loading the main output
// unit.
class N extends A {}
