// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart' show InvalidExpression, Library;

import '../fasta_codes.dart' show LocatedMessage;

import '../loader.dart' show Loader;

import 'constant_evaluator.dart' show ErrorReporter;

class KernelConstantErrorReporter extends ErrorReporter {
  final Loader<Library> loader;

  KernelConstantErrorReporter(this.loader);

  @override
  void report(LocatedMessage message, List<LocatedMessage> context) {
    loader.addProblem(
        message.messageObject, message.charOffset, message.length, message.uri,
        context: context);
  }

  @override
  void reportInvalidExpression(InvalidExpression node) {
    // Assumed to be already reported.
  }
}
