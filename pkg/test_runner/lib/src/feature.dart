// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A capability that a Dart implementation may or may not provide that a test
/// may require.
///
/// Each `TestConfiguration` specifies the set of features it supports. A test
/// can have a "// Requirements" comment indicating the names of features it
/// requires. If a test requires a feature not supported by the current
/// configution, the test runner automatically skips it.
class Feature {
  /// Opted out of NNBD and still using the legacy semantics.
  static const nnbdLegacy = Feature._("nnbd-legacy");

  /// Opted in to NNBD features.
  ///
  /// Note that this does not imply either strong or weak checking. A test that
  /// only requires "nnbd" should run in both weak and strong checking modes.
  static const nnbd = Feature._("nnbd");

  /// Weak checking of NNBD features.
  static const nnbdWeak = Feature._("nnbd-weak");

  /// Full strong checking of NNBD features.
  static const nnbdStrong = Feature._("nnbd-strong");

  static const all = [nnbdLegacy, nnbd, nnbdWeak, nnbdStrong];

  final String name;

  const Feature._(this.name);

  String toString() => name;
}
