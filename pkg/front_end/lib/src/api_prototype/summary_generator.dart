// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to summaries.
library front_end.summary_generator;

import 'dart:async';
import 'compiler_options.dart';

import '../base/processed_options.dart';
import '../kernel_generator_impl.dart';

/// Creates a summary representation of the build unit whose source files are in
/// [sources].
///
/// Intended to be a part of a modular compilation process.
///
/// Any dependency of [sources] that is not listed in
/// [CompilerOptions.inputSummaries] and [CompilerOptions.sdkSummary] is treated
/// as an additional source file for the build unit.
///
/// Any `part` declarations found in [sources] must refer to part files which
/// are also listed in the build unit sources, otherwise an error results.  (It
/// is not permitted to refer to a part file declared in another build unit).
///
/// If [truncate] is true, the resulting summary doesn't include any references
/// to libraries loaded from the input summaries, and only contains code that
/// was compiled from sources.
///
/// The return value is a list of bytes to write to the summary file.
Future<List<int>> summaryFor(List<Uri> sources, CompilerOptions options,
    {bool truncate: false}) async {
  return (await generateKernel(
          new ProcessedOptions(options: options, inputs: sources),
          buildSummary: true,
          buildComponent: false,
          truncateSummary: truncate))
      ?.summary;
}
