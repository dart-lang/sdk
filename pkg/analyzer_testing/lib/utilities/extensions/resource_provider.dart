// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as path;

extension ResourceProviderExtension on ResourceProvider {
  /// Converts the given posix [filePath] to conform to this provider's path
  /// context.
  String convertPath(String filePath) {
    if (pathContext.style == path.windows.style) {
      if (filePath.startsWith(path.posix.separator)) {
        filePath = r'C:' + filePath;
      }
      filePath = filePath.replaceAll(
        path.posix.separator,
        path.windows.separator,
      );
    }
    return filePath;
  }
}
