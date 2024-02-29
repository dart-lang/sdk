// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A bit flag used by [LibraryInfo] indicating that a library is used by
/// dart2js.
///
/// This declaration duplicates the declaration in the SDK's "libraries.dart".
const int DART2JS_PLATFORM = 1;

/// A bit flag used by [LibraryInfo] indicating that a library is used by the
/// VM.
///
/// This declaration duplicates the declaration in the SDK's "libraries.dart".
const int VM_PLATFORM = 2;

/// The contexts that a library can be used from.
///
/// This declaration duplicates the declaration in the SDK's "libraries.dart".
enum Category {
  /// Indicates that a library can be used in a browser context.
  client,

  /// Indicates that a library can be used in a command line context.
  server,

  /// Indicates that a library can be used from embedded devices.
  embedded
}

/// Abstraction to capture the maturity of a library.
class Maturity {
  static const Maturity DEPRECATED = const Maturity(0, "Deprecated",
      "This library will be remove before next major release.");
  static const Maturity EXPERIMENTAL = const Maturity(
      1,
      "Experimental",
      "This library is experimental and will likely change or be removed\n"
          "in future versions.");
  static const Maturity UNSTABLE = const Maturity(
      2,
      "Unstable",
      "This library is in still changing and have not yet endured\n"
          "sufficient real-world testing.\n"
          "Backwards-compatibility is NOT guaranteed.");

  static const Maturity WEB_STABLE = const Maturity(
      3,
      "Web Stable",
      "This library is tracking the DOM evolution as defined by WC3.\n"
          "Backwards-compatibility is NOT guaranteed.");

  static const Maturity STABLE = const Maturity(
      4,
      "Stable",
      "The library is stable. API backwards-compatibility is guaranteed.\n"
          "However implementation details might change.");

  static const Maturity LOCKED = const Maturity(5, "Locked",
      "This library will not change except when serious bugs are encountered.");

  static const Maturity UNSPECIFIED = const Maturity(-1, "Unspecified",
      "The maturity for this library has not been specified.");

  final int level;

  final String name;

  final String description;

  const Maturity(this.level, this.name, this.description);

  @override
  String toString() => "$name: $level\n$description\n";
}
