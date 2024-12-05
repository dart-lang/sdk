// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FileSystemDependencyTracker {
  final List<Uri> dependencies = <Uri>[];

  static void recordDependency(FileSystemDependencyTracker? tracker, Uri uri) {
    if (!uri.isScheme("file") &&
        // Coverage-ignore(suite): Not run.
        !uri.isScheme("http")) {
      throw new ArgumentError("Expected a file or http URI, but got: '$uri'.");
    }
    // Coverage-ignore-block(suite): Not run.
    if (tracker != null) {
      tracker.dependencies.add(uri);
    }
  }
}
