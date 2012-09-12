// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// TODO: Convert this abstract class into a concrete class double
// that uses the patch class functionality to account for the
// different platform implementations.

abstract class double implements num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;

  // Specialization of super-interface. Double is contagious. We can therefore
  // specialize more methods than in other num sub-interfaces.
  abstract double remainder(num other);
  abstract double operator +(num other);
  abstract double operator -(num other);
  abstract double operator *(num other);
  abstract double operator %(num other);
  abstract double operator /(num other);
  abstract double operator ~/(num other);
  abstract double operator -();
  abstract double abs();
  abstract double round();
  abstract double floor();
  abstract double ceil();
  abstract double truncate();
}
