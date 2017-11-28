// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'path.dart';

/// Provides information about the surrounding Dart repository.
class Repository {
  /// File path pointing to the root directory of the Dart checkout.
  static Path get dir => new Path(uri.toFilePath());

  /// The URI pointing to the root of the Dart checkout.
  ///
  /// If not explicitly set, defaults to the directory three levels above the
  /// script being executed, which is assumed to be one of the test scripts in
  /// this same directory as this file.
  static Uri uri = Platform.script.resolve('../../..');
}
