// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks whether importing the library with URI [library2] into the
/// library with URI [library1] could be a relative import.
///
/// Both URIs must be package: URIs and belong to the same package for this to
/// be true.
bool canBeRelativeImport(Uri library1, Uri library2) {
  return library1.isScheme('package') &&
      library2.isScheme('package') &&
      library1.pathSegments.isNotEmpty &&
      library2.pathSegments.isNotEmpty &&
      library1.pathSegments.first == library2.pathSegments.first;
}
