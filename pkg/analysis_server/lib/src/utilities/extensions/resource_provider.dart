// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';

extension ResourceProviderExtension on ResourceProvider {
  /// Whether [path] is both absolute and normalized.
  bool isAbsoluteAndNormalized(String path) =>
      pathContext.isAbsolute(path) && pathContext.normalize(path) == path;

  /// Whether [path] is a valid `FilePath`.
  ///
  /// This means that it is absolute and normalized.
  bool isValidFilePath(String path) => isAbsoluteAndNormalized(path);
}
