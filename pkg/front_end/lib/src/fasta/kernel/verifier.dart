// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.verifier;

import 'package:kernel/ast.dart' show
    ExpressionStatement,
    Program;

import 'package:kernel/verifier.dart' show
    VerifyingVisitor;

import 'redirecting_factory_body.dart' show
    RedirectingFactoryBody;

void verifyProgram(Program program, {bool isOutline: false}) {
  program.accept(new FastaVerifyingVisitor(isOutline));
}

class FastaVerifyingVisitor extends VerifyingVisitor {
  FastaVerifyingVisitor(bool isOutline) {
    this.isOutline = isOutline;
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    // Bypass verification of the [StaticGet] in [RedirectingFactoryBody] as
    // this is a static get without a getter.
    if (node is! RedirectingFactoryBody) {
      super.visitExpressionStatement(node);
    }
  }
}
