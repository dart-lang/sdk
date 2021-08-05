// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart' show InvalidExpression;

import '../builder/library_builder.dart';

import '../fasta_codes.dart' show LocatedMessage;

import '../loader.dart' show Loader;

import 'constant_evaluator.dart' show ErrorReporter;

class KernelConstantErrorReporter extends ErrorReporter {
  final Loader loader;

  KernelConstantErrorReporter(this.loader);

  @override
  void report(LocatedMessage message, List<LocatedMessage>? context) {
    // Try to find library.
    LibraryBuilder? builder = loader.builders[message.uri];
    if (builder == null) {
      for (LibraryBuilder candidate in loader.builders.values) {
        if (candidate.fileUri == message.uri) {
          // Found it.
          builder = candidate;
          break;
        }
      }
    }
    if (builder == null) {
      // TODO(jensj): Probably a part or something.
      loader.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri!,
          context: context);
    } else {
      builder.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // TODO(johnniwinther): Improve the precision of this assertion. Do we
    // for instance allow warnings only to have been reported in previous
    // compilations.
    assert(
        // Either we have already reported an error
        loader.hasSeenError ||
            // or we have reported an error in a previous compilation.
            loader.builders.values.any((builder) =>
                builder.library.problemsAsJson?.isNotEmpty ?? false),
        "No error reported before seeing: "
        "${node.message}");
    // Assumed to be already reported.
  }
}
