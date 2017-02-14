// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The class `UriResolver` implements the rules for resolving "dart:" and
/// "package:" URIs.
class UriResolver {
  /// The URI scheme used for "package" URIs.
  static const PACKAGE_SCHEME = 'package';

  /// The URI scheme used for "dart" URIs.
  static const DART_SCHEME = 'dart';

  /// A map from package name to the file URI of the "lib" directory of the
  /// corresponding package.  This is equivalent to the format returned by
  /// the "package_config" package's parse() function.
  final Map<String, Uri> packages;

  /// A map from SDK library name (e.g. `core` for `dart:core`) to the file URI
  /// of the defining compilation unit of the SDK library.
  final Map<String, Uri> sdkLibraries;

  UriResolver(this.packages, this.sdkLibraries);

  /// Converts "package:" and "dart:" URIs to the locations of the corresponding
  /// files.
  ///
  /// If the given URI is a "package:" or "dart:" URI, is well formed, and names
  /// a package or dart library that is recognized, returns the URI it resolves
  /// to.  If the given URI is a "package:" or "dart:" URI, and is ill-formed
  /// or names a package or dart library that is not recognized, returns `null`.
  ///
  /// If the given URI has any scheme other than "package:" or "dart:", it is
  /// returned unchanged.
  ///
  /// It is not necessary for the URI to be absolute (relative URIs will be
  /// passed through unchanged).
  ///
  /// Note that no I/O is performed; the URI that is returned will be
  /// independent of whether or not any particular file exists on the file
  /// system.
  Uri resolve(Uri uri) {
    if (uri.scheme == DART_SCHEME || uri.scheme == PACKAGE_SCHEME) {
      var path = uri.path;
      var slashIndex = path.indexOf('/');
      String prefix;
      String rest;
      if (slashIndex >= 0) {
        prefix = path.substring(0, slashIndex);
        rest = path.substring(slashIndex + 1);
      } else {
        prefix = path;
        rest = '';
      }
      Uri libUri;
      if (uri.scheme == PACKAGE_SCHEME) {
        if (slashIndex < 0) return null;
        libUri = packages[prefix];
      } else if (uri.scheme == DART_SCHEME) {
        libUri = sdkLibraries[prefix];
      }
      if (libUri == null) return null;
      return libUri.resolve(rest);
    } else {
      return uri;
    }
  }
}
