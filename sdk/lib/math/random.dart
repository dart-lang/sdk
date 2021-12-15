// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.math;

/// A generator of random bool, int, or double values.
///
/// The default implementation supplies a stream of pseudo-random bits that are
/// not suitable for cryptographic purposes.
///
/// Use the [Random.secure]() constructor for cryptographic purposes.
///
/// To create a non-negative random integer uniformly distributed in the range
/// from 0, inclusive, to [max], exclusive, use [nextInt(int max)].
/// ```dart
/// var value = Random().nextInt(10); // Value between 0 - 9.
/// value = Random().nextInt(100) + 50; // Value between 50 - 149
/// ```
/// To create a non-negative random floating point value uniformly distributed
/// in the range from 0.0, inclusive, to 1.0, exclusive, use [nextDouble].
/// ```dart continued
/// value = Random().nextDouble(); // Value between 0.0 - 1.0.
/// value = Random().nextDouble() + 10; // Value is >= 10.0 and < 11.0
/// ```
/// To create a random boolean value, use [nextBool].
/// ```dart continued
/// value = Random().nextBool(); // Value is true or false.
/// ```
abstract class Random {
  /// Creates a random number generator.
  ///
  /// The optional parameter [seed] is used to initialize the
  /// internal state of the generator. The implementation of the
  /// random stream can change between releases of the library.
  external factory Random([int? seed]);

  /// Creates a cryptographically secure random number generator.
  ///
  /// If the program cannot provide a cryptographically secure
  /// source of random numbers, it throws an [UnsupportedError].
  external factory Random.secure();

  /// Generates a non-negative random integer uniformly distributed in the range
  /// from 0, inclusive, to [max], exclusive.
  ///
  /// Implementation note: The default implementation supports [max] values
  /// between 1 and (1<<32) inclusive.
  int nextInt(int max);

  /// Generates a non-negative random floating point value uniformly distributed
  /// in the range from 0.0, inclusive, to 1.0, exclusive.
  double nextDouble();

  /// Generates a random boolean value.
  bool nextBool();
}
