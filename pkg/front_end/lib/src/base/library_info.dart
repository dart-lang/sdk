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

/// Parse a category string in the SDK's "libraries.dart".
///
/// This declaration duplicates the declaration in the SDK's "libraries.dart".
Category parseCategory(String name) {
  switch (name) {
    case 'Client':
      return Category.client;
    case 'Server':
      return Category.server;
    case 'Embedded':
      return Category.embedded;
  }
  return null;
}

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

/// Information about a "dart:" library gleaned from the SDK's "libraries.dart"
/// file.
///
/// This declaration duplicates the declaration in "libraries.dart".
class LibraryInfo {
  /// Path to the library's *.dart file relative to the SDK's "lib" directory.
  final String path;

  /// The categories in which the library can be used, encoded as a
  /// comma-separated String.
  final String _categories;

  /// Path to the dart2js library's *.dart file relative to the SDK's "lib"
  /// directory, or null if dart2js uses the common library path defined above.
  final String dart2jsPath;

  /// Path to the dart2js library's patch file relative to the SDK's "lib"
  /// directory, or null if no dart2js patch file associated with this library.
  final String dart2jsPatchPath;

  /// True if this library is documented and should be shown to the user.
  final bool documented;

  /// Bit flags indicating which platforms consume this library.  See
  /// [DART2JS_LIBRARY] and [VM_LIBRARY].
  final int platforms;

  /// True if the library contains implementation details for another library.
  /// The implication is that these libraries are less commonly used and that
  /// tools like the analysis server should not show these libraries in a list
  /// of all libraries unless the user specifically asks the tool to do so.
  final bool implementation;

  /// States the current maturity of this library.
  final Maturity maturity;

  const LibraryInfo(this.path,
      {String categories: "",
      this.dart2jsPath,
      this.dart2jsPatchPath,
      this.implementation: false,
      this.documented: true,
      this.maturity: Maturity.UNSPECIFIED,
      this.platforms: DART2JS_PLATFORM | VM_PLATFORM})
      : _categories = categories;

  /// The categories in which the library can be used.
  ///
  /// If no categories are specified, the library is internal and cannot be
  /// loaded by user code.
  List<Category> get categories {
    // `''.split(',')` returns [''], not [], so we handle that case separately.
    if (_categories.isEmpty) return const <Category>[];
    return _categories.split(',').map(parseCategory).toList();
  }

  /// The original "categories" String that was passed to the constructor.
  ///
  /// Can be used to construct a slightly modified copy of this LibraryInfo.
  String get categoriesString {
    return _categories;
  }

  bool get isDart2jsLibrary => (platforms & DART2JS_PLATFORM) != 0;

  bool get isInternal => categories.isEmpty;

  bool get isVmLibrary => (platforms & VM_PLATFORM) != 0;
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

  String toString() => "$name: $level\n$description\n";
}
