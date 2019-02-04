// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';

/// Information about the workspace in which change builders operate.
abstract class ChangeWorkspace {
  /// Return `true` if the file with the given [path] is in a context root.
  bool containsFile(String path);

  /// Return the session that should analyze the given [path], or throw
  /// [StateError] if the [path] does not belong to a context root.
  AnalysisSession getSession(String path);
}
