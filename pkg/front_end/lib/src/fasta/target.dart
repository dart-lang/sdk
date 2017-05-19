// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart';
import 'ticker.dart' show Ticker;

/// A compilation target.
///
/// A target reads source files with [read], builds outlines when
/// [buildOutlines] is called and builds the full program when [buildProgram]
/// is called.
abstract class Target {
  final Ticker ticker;

  Target(this.ticker);

  /// Instructs this target to include [uri] in its result.
  void read(Uri uri);

  /// Build and return outlines for all libraries.
  Future<Program> buildOutlines();

  /// Build and return the full program for all libraries.
  Future<Program> buildProgram();
}
