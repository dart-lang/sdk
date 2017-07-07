// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the front-end API for converting source code to summaries.
library front_end.summary_generator;

import 'dart:async';
import 'compiler_options.dart';

/// Creates a summary representation of the build unit whose source files are in
/// [sources].
///
/// Intended to be a part of a modular compilation process.
///
/// [sources] should be the complete set of source files for a build unit
/// (including both library and part files).
///
/// The summarization process is hermetic, meaning that the only files which
/// will be read are those listed in [sources],
/// [CompilerOptions.inputSummaries], and [CompilerOptions.sdkSummary].  If a
/// source file attempts to refer to a file which is not obtainable from these
/// paths, that will result in an error, even if the file exists on the
/// filesystem.
///
/// Any `part` declarations found in [sources] must refer to part files which
/// are also listed in [sources], otherwise an error results.  (It is not
/// permitted to refer to a part file declared in another build unit).
///
/// The return value is a list of bytes to write to the summary file.
Future<List<int>> summaryFor(List<Uri> sources, CompilerOptions options) =>
    throw new UnimplementedError();
