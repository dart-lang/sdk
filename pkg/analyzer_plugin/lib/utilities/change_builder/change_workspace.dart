// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';

/// Information about the workspace in which change builders operate.
abstract class ChangeWorkspace {
  /// The resource provider used to access the file system.
  ResourceProvider get resourceProvider;

  /// Whether the file with the given [path] is in a context root.
  bool containsFile(String path);

  /// Returns the session that should analyze the given [path], or throws
  /// [StateError] if the [path] does not belong to a context root.
  AnalysisSession? getSession(String path);
}
