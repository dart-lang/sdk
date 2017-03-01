// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.verifier;

import 'package:kernel/ast.dart'
    show
        Class,
        ExpressionStatement,
        Field,
        Library,
        Procedure,
        Program,
        TreeNode;

import 'package:kernel/verifier.dart' show VerificationError, VerifyingVisitor;

import '../errors.dart' show printUnexpected;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

void verifyProgram(Program program, {bool isOutline: false}) {
  FastaVerifyingVisitor verifier = new FastaVerifyingVisitor(isOutline);
  program.accept(verifier);
  if (verifier.errors.isNotEmpty) {
    throw verifier.errors.first;
  }
}

class FastaVerifyingVisitor extends VerifyingVisitor {
  final List<VerificationError> errors = <VerificationError>[];

  String fileUri;

  FastaVerifyingVisitor(bool isOutline) {
    this.isOutline = isOutline;
  }

  @override
  problem(TreeNode node, String details) {
    VerificationError error = new VerificationError(context, node, details);
    printUnexpected(Uri.parse(fileUri), node.fileOffset, "$error");
    errors.add(error);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    // Bypass verification of the [StaticGet] in [RedirectingFactoryBody] as
    // this is a static get without a getter.
    if (node is! RedirectingFactoryBody) {
      super.visitExpressionStatement(node);
    }
  }

  visitLibrary(Library node) {
    fileUri = node.fileUri;
    super.visitLibrary(node);
  }

  visitClass(Class node) {
    fileUri = node.fileUri;
    super.visitClass(node);
  }

  visitField(Field node) {
    fileUri = node.fileUri;
    super.visitField(node);
  }

  visitProcedure(Procedure node) {
    fileUri = node.fileUri;
    super.visitProcedure(node);
  }
}
