// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension UriExtension on Uri {
  /// Whether this URI represents a path in a package's private "implementation"
  /// directory.
  bool get isImplementation =>
      (isScheme('package') || !hasAbsolutePath) &&
      pathSegments.length > 2 &&
      pathSegments[1] == 'src';

  /// Whether this URI and [other] are each 'package:' URIs referencing the same
  /// package name.
  bool isSamePackageAs(Uri other) {
    return isScheme('package') &&
        other.isScheme('package') &&
        pathSegments.isNotEmpty &&
        other.pathSegments.isNotEmpty &&
        pathSegments.first == other.pathSegments.first;
  }
}
