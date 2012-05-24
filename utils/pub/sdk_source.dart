// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('sdk_source');

#import('io.dart');
#import('package.dart');
#import('source.dart');

/**
 * A package source that uses libraries from the Dart SDK.
 *
 * This currently uses the "sdkdir" command-line argument to find the SDK.
 */
// TODO(nweiz): This should read the SDK directory from an environment variable
// once we can set those for tests.
class SdkSource extends Source {
  final String name = "sdk";
  final bool shouldCache = false;

  /**
   * The root directory of the Dart SDK.
   */
  final String rootDir;

  SdkSource(this.rootDir);

  /**
   * Since all the SDK files are already available locally, installation just
   * involves symlinking the SDK library into the packages directory.
   */
  Future<bool> install(PackageId id, String destPath) {
    var sourcePath = join(rootDir, "lib", id.description);
    return exists(sourcePath).chain((exists) {
      if (!exists) return new Future<bool>.immediate(false);
      return createSymlink(sourcePath, destPath).transform((_) => true);
    });
  }
}
