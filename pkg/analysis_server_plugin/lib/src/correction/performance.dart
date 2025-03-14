// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Timing information for a (correction) producer's call to `compute()`.
typedef ProducerTiming = ({
  /// The producer class name.
  String className,

  /// The time elapsed during `compute()`.
  int elapsedTime,
});
