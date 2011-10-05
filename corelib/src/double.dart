// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

interface double extends num {
  // Specialization of super-interface. Double is contagious. We can therefore
  // specialize more methods than in other num sub-interfaces.
  double remainder(num other);
  double operator +(num other);
  double operator -(num other);
  double operator *(num other);
  double operator %(num other);
  double operator /(num other);
  double operator ~/(num other);
  double operator negate();
  double abs();
  double round();
  double floor();
  double ceil();
  double truncate();
}
