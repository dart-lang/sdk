// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Resolve the [containedUri] against [baseUri] using Dart rules.
///
/// This function behaves similarly to [Uri.resolveUri], except that it
/// handles `dart:` URIS as follows:
/// ```
/// resolveRelativeUri(dart:core, bool.dart) -> dart:core/bool.dart
/// ```
Uri resolveRelativeUri(Uri baseUri, Uri containedUri) {
  if (containedUri.isAbsolute) {
    return containedUri;
  }
  // dart:core => dart:core/core.dart
  if (baseUri.isScheme('dart')) {
    String path = baseUri.path;
    if (!path.contains('/')) {
      baseUri = Uri.parse('dart:$path/');
    }
  }
  return baseUri.resolveUri(containedUri);
}
