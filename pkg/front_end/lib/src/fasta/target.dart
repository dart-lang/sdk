// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.target;

import 'dart:async' show Future;

import 'package:kernel/ast.dart' show Component;

import 'ticker.dart' show Ticker;

/// A compilation target.
///
/// A target reads source files with [read], builds outlines when
/// [buildOutlines] is called and builds the full component when
/// [buildComponent] is called.
abstract class Target {
  final Ticker ticker;

  Target(this.ticker);

  /// Build and return outlines for all libraries.
  Future<Component> buildOutlines();

  /// Build and return the full component for all libraries.
  Future<Component> buildComponent();
}
