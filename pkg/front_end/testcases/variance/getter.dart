// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Derived from language/variance/variance_in_field_error_test

class A<in T> {
  final T a = throw "uncalled"; // Error
  final T Function() b = () => throw "uncalled"; // Error
  T get c => throw "uncalled"; // Error
  late T d; // Error
  covariant late T e; // Error
  T? f = null; // Error
}

mixin BMixin<in T> {
  final T a = throw "uncalled"; // Error
  final T Function() b = () => throw "uncalled"; // Error
  T get c => throw "uncalled"; // Error
  late T d; // Error
  covariant late T e; // Error
  T? f = null; // Error
}

abstract class C<in T> {
  T get a; // Error
}

class D<in T> extends C<T> {
  var a; // Error
}