// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:package_config/package_config.dart';

/// An absolute URI representing a source file reference.
///
/// Can be a `package:` URI or `file:///` / `multi-root:///` URI for sources
/// outside of any package.
extension type LibraryUri(Uri _value) {
  /// Resolves another uri relative to this.
  LibraryUri resolve(Uri other) => LibraryUri(_value.resolveUri(other));

  /// Find the physical URI for this source in the given [packageConfig].
  FileSystemUri? expand(PackageConfig packageConfig) {
    if (_value.isScheme('package')) {
      final resolved = packageConfig.resolve(_value);
      return resolved == null ? null : FileSystemUri(resolved);
    }
    return FileSystemUri(_value);
  }

  bool isScheme(String scheme) => _value.isScheme(scheme);

  static LibraryUri parse(String uri) => LibraryUri(Uri.parse(uri));
}

extension type FileSystemUri(Uri value) {
  static FileSystemUri parse(String uri) => FileSystemUri(Uri.parse(uri));
}
