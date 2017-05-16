// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target;

import 'dart:async' show Future;

import 'ticker.dart' show Ticker;

/// A compilation target.
///
/// A target reads source files with [read] and computes outlines when
/// [computeOutline] is called.
abstract class Target {
  final Ticker ticker;

  Target(this.ticker);

  /// Instructs this target to include [uri] in its result.
  void read(Uri uri);

  /// Compute outlines for all [read] URIs.
  Future<Null> computeOutline();

  /// Write the resulting program in the file [uri].
  Future writeProgram(Uri uri);
}
