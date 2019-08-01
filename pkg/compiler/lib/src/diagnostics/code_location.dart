// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.diagnostics.code_location;

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

/// [CodeLocation] divides uris into different classes.
///
/// These are used to group uris from user code, platform libraries and
/// packages.
abstract class CodeLocation {
  /// Returns `true` if [uri] is in this code location.
  bool inSameLocation(Uri uri);

  /// Returns the uri of this location relative to [baseUri].
  String relativize(Uri baseUri);

  factory CodeLocation(Uri uri) {
    if (uri.scheme == 'package') {
      int slashPos = uri.path.indexOf('/');
      if (slashPos != -1) {
        String packageName = uri.path.substring(0, slashPos);
        return new PackageLocation(packageName);
      } else {
        return new UriLocation(uri);
      }
    } else {
      return new SchemeLocation(uri);
    }
  }
}

/// A code location defined by the scheme of the uri.
///
/// Used for non-package uris, such as 'dart', 'file', and 'http'.
class SchemeLocation implements CodeLocation {
  final Uri uri;

  SchemeLocation(this.uri);

  @override
  bool inSameLocation(Uri uri) {
    return this.uri.scheme == uri.scheme;
  }

  @override
  String relativize(Uri baseUri) {
    return fe.relativizeUri(baseUri, uri, false);
  }
}

/// A code location defined by the package name.
///
/// Used for package uris, separated by their `package names`, that is, the
/// 'foo' of 'package:foo/bar.dart'.
class PackageLocation implements CodeLocation {
  final String packageName;

  PackageLocation(this.packageName);

  @override
  bool inSameLocation(Uri uri) {
    return uri.scheme == 'package' && uri.path.startsWith('$packageName/');
  }

  @override
  String relativize(Uri baseUri) => 'package:$packageName';
}

/// A code location defined by the whole uri.
///
/// Used for package uris with no package name. For instance 'package:foo.dart'.
class UriLocation implements CodeLocation {
  final Uri uri;

  UriLocation(this.uri);

  @override
  bool inSameLocation(Uri uri) => this.uri == uri;

  @override
  String relativize(Uri baseUri) {
    return fe.relativizeUri(baseUri, uri, false);
  }
}

/// A code location that contains any uri.
class AnyLocation implements CodeLocation {
  const AnyLocation();

  @override
  bool inSameLocation(Uri uri) => true;

  @override
  String relativize(Uri baseUri) => '$baseUri';
}
