// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interface for showing progress during compilation.
class Progress {
  const Progress();

  /// Starts a new phase for which to show progress.
  void startPhase() {}

  /// Shows progress of the current phase if needed. The shown message is
  /// computed as '$prefix$count$suffix'.
  void showProgress(String prefix, int count, String suffix) {}
}
