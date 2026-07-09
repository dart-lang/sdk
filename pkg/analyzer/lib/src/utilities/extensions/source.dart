// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';

extension SourceExtension on Source {
  /// Gets the string contents of this source.
  ///
  /// This is a performance optimization that avoids reading the modification
  /// timestamp for [FileSource] that [contents] would cause.
  String get stringContents {
    if (this case FileSource fileSource) {
      return fileSource.file.readAsStringSync();
    }
    return contents.data;
  }
}
