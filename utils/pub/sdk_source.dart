// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sdk_source;

import 'dart:async';
import 'io.dart';
import 'package.dart';
import 'pubspec.dart';
import 'sdk.dart' as sdk;
import 'source.dart';
import 'version.dart';

/// A package source that uses libraries from the Dart SDK.
class SdkSource extends Source {
  final String name = "sdk";
  final bool shouldCache = false;

  /// SDK packages are not individually versioned. Instead, their version is
  /// inferred from the revision number of the SDK itself.
  Future<Pubspec> describe(PackageId id) {
    return _getPackagePath(id).then((packageDir) {
      // TODO(rnystrom): What if packageDir is null?
      return Package.load(id.name, packageDir, systemCache.sources);
    }).then((package) {
      // Ignore the pubspec's version, and use the SDK's.
      return new Pubspec(id.name, sdk.version, package.pubspec.dependencies,
          package.pubspec.environment);
    });
  }

  /// Since all the SDK files are already available locally, installation just
  /// involves symlinking the SDK library into the packages directory.
  Future<bool> install(PackageId id, String destPath) {
    return _getPackagePath(id).then((path) {
      if (path == null) return new Future<bool>.immediate(false);

      return createPackageSymlink(id.name, path, destPath).then(
          (_) => true);
    });
  }

  /// Gets the path in the SDK's "pkg" directory to the directory containing
  /// package [id]. Returns `null` if the package could not be found.
  Future<String> _getPackagePath(PackageId id) {
    var pkgPath = join(sdk.rootDirectory, "pkg", id.description);
    return dirExists(pkgPath).then((found) => found ? pkgPath : null);
  }
}
