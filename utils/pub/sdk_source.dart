// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('sdk_source');

#import('io.dart');
#import('package.dart');
#import('pubspec.dart');
#import('source.dart');
#import('version.dart');

/**
 * A package source that uses libraries from the Dart SDK.
 *
 * This currently uses the "sdkdir" command-line argument to find the SDK.
 */
class SdkSource extends Source {
  final String name = "sdk";
  final bool shouldCache = false;

  /**
   * The root directory of the Dart SDK.
   */
  final String _rootDir;

  String get rootDir {
    if (_rootDir != null) return _rootDir;
    throw "Pub can't find the Dart SDK. Please set the DART_SDK environment "
      "variable to the Dart SDK directory.";
  }

  SdkSource(this._rootDir);

  /**
   * An SDK package has no dependencies. Its version number is inferred from the
   * revision number of the SDK itself.
   */
  Future<Pubspec> describe(PackageId id) {
    return readTextFile(join(rootDir, "revision")).transform((revision) {
      var version = new Version.parse("0.0.0-r.${revision.trim()}");
      return new Pubspec(id.name, version, <PackageRef>[]);
    });
  }

  /**
   * Since all the SDK files are already available locally, installation just
   * involves symlinking the SDK library into the packages directory.
   */
  Future<bool> install(PackageId id, String destPath) {
    // Look in "pkg" first.
    var sourcePath = join(rootDir, "pkg", id.description);
    return exists(sourcePath).chain((found) {
      if (!found) {
        // TODO(rnystrom): Get rid of this when all SDK packages are moved from
        // "lib" to "pkg".
        // Not in "pkg", so try "lib".
        sourcePath = join(rootDir, "lib", id.description);
        return exists(sourcePath).chain((found) {
          if (!found) return new Future<bool>.immediate(false);
          return createPackageSymlink(id.name, sourcePath, destPath).transform(
              (_) => true);
        });
      }

      return createPackageSymlink(id.name, sourcePath, destPath).transform(
          (_) => true);
    });
  }
}
