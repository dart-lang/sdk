// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

/// The class `UriResolver` implements the rules for resolving URIs to file
/// paths.
///
/// TODO(paulberry): Is it necessary to support the "http" scheme?
class UriResolver {
  /// A map from package name to the file URI of the "lib" directory of the
  /// corresponding package.  This is equivalent to the format returned by
  /// the "package_config" package's parse() function.
  final Map<String, Uri> packages;

  /// A map from SDK library name (e.g. `core` for `dart:core`) to the file URI
  /// of the defining compilation unit of the SDK library.
  final Map<String, Uri> sdkLibraries;

  /// The path context which should be used to convert from file URIs to file
  /// paths.
  final p.Context pathContext;

  /// The URI scheme used for "package" URIs.
  static const PACKAGE_SCHEME = 'package';

  /// The URI scheme used for "dart" URIs.
  static const DART_SCHEME = 'dart';

  /// The URI scheme used for "file" URIs.
  static const FILE_SCHEME = 'file';

  UriResolver(this.packages, this.sdkLibraries, this.pathContext);

  /// Converts a URI to a file path.
  ///
  /// If the given URI is valid, and of a recognized form, returns the file path
  /// it corresponds to.  Otherwise returns `null`.  It is not necessary for the
  /// URI to be absolute (relative URIs will be converted to relative file
  /// paths).
  ///
  /// Note that no I/O is performed; the file path that is returned will be
  /// independent of whether or not any particular file exists on the file
  /// system.
  String resolve(Uri uri) {
    Uri fileUri;
    if (uri.scheme == FILE_SCHEME) {
      fileUri = uri;
    } else {
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
      fileUri = libUri.resolve(rest);
      if (fileUri.scheme != FILE_SCHEME) return null;
    }
    return pathContext.fromUri(fileUri);
  }
}
