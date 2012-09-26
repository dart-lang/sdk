// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('sdk_source');

#import('io.dart');
#import('package.dart');
#import('pubspec.dart');
#import('source.dart');
#import('version.dart');

/// A package source that uses libraries from the Dart SDK.
class SdkSource extends Source {
  final String name = "sdk";
  final bool shouldCache = false;

  /// The root directory of the Dart SDK.
  final String _rootDir;

  String get rootDir {
    if (_rootDir != null) return _rootDir;
    throw "Pub can't find the Dart SDK. Please set the DART_SDK environment "
      "variable to the Dart SDK directory.";
  }

  SdkSource(this._rootDir);

  /// SDK packages are not individually versioned. Instead, their version is
  /// inferred from the revision number of the SDK itself.
  Future<Pubspec> describe(PackageId id) {
    var version;
    return readTextFile(join(rootDir, "revision")).chain((revision) {
      version = new Version.parse("0.0.0-r.${revision.trim()}");
      // Read the pubspec for the package's dependencies.
      return _getPackagePath(id);
    }).chain((packageDir) {
      // TODO(rnystrom): What if packageDir is null?
      return Package.load(id.name, packageDir, systemCache.sources);
    }).transform((package) {
      // Ignore the pubspec's version, and use the SDK's.
      return new Pubspec(id.name, version, package.pubspec.dependencies);
    });
  }

  /// Since all the SDK files are already available locally, installation just
  /// involves symlinking the SDK library into the packages directory.
  Future<bool> install(PackageId id, String destPath) {
    return _getPackagePath(id).chain((path) {
      if (path == null) return new Future<bool>.immediate(false);

      return createPackageSymlink(id.name, path, destPath).transform(
          (_) => true);
    });
  }

  /// Gets the path in the SDK to the directory containing package [id]. Looks
  /// inside both "pkg" and "lib" in the SDK. Returns `null` if the package
  /// could not be found.
  Future<String> _getPackagePath(PackageId id) {
    // Look in "pkg" first.
    var pkgPath = join(rootDir, "pkg", id.description);
    return exists(pkgPath).chain((found) {
      if (found) return new Future<String>.immediate(pkgPath);

      // Not in "pkg", so try "lib".
      // TODO(rnystrom): Get rid of this when all SDK packages are moved from
      // "lib" to "pkg".
      var libPath = join(rootDir, "lib", id.description);
      return exists(libPath).transform((found) => found ? libPath : null);
    });
  }
}
