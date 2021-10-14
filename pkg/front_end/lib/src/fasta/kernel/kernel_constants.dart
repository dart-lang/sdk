// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import '../builder/library_builder.dart';

import '../fasta_codes.dart' show LocatedMessage;

import '../source/source_loader.dart' show SourceLoader;

import 'constant_evaluator.dart' show ErrorReporter;

class KernelConstantErrorReporter extends ErrorReporter {
  final SourceLoader loader;

  KernelConstantErrorReporter(this.loader);

  @override
  void report(LocatedMessage message, [List<LocatedMessage>? context]) {
    // Try to find library.
    LibraryBuilder? builder = loader.lookupLibraryBuilder(message.uri!);
    if (builder == null) {
      for (LibraryBuilder candidate in loader.libraryBuilders) {
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
          message.length, message.uri,
          context: context);
    } else {
      builder.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
  }
}
