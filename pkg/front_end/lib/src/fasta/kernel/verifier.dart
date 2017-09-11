// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.verifier;

import 'package:kernel/ast.dart'
    show
        InvalidExpression,
        InvalidStatement,
        InvalidInitializer,
        Class,
        ExpressionStatement,
        Field,
        Library,
        Procedure,
        Program,
        TreeNode;

import 'package:kernel/verifier.dart' show VerifyingVisitor;

import '../compiler_context.dart' show CompilerContext;

import '../fasta_codes.dart'
    show LocatedMessage, templateInternalVerificationError;

import '../severity.dart' show Severity;

import '../type_inference/type_schema.dart' show TypeSchemaVisitor, UnknownType;

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

List<LocatedMessage> verifyProgram(Program program, {bool isOutline: false}) {
  FastaVerifyingVisitor verifier = new FastaVerifyingVisitor(isOutline);
  program.accept(verifier);
  return verifier.errors;
}

class FastaVerifyingVisitor extends VerifyingVisitor
    implements TypeSchemaVisitor {
  final List<LocatedMessage> errors = <LocatedMessage>[];

  String fileUri;

  FastaVerifyingVisitor(bool isOutline) {
    this.isOutline = isOutline;
  }

  String checkLocation(TreeNode node, String name, String fileUri) {
    if (name == null || name.contains("#")) {
      // TODO(ahe): Investigate if these checks can be enabled:
      // if (node.fileUri != null && node is! Library) {
      //   problem(node, "A synthetic node shouldn't have a fileUri",
      //       context: node);
      // }
      // if (node.fileOffset != -1) {
      //   problem(node, "A synthetic node shouldn't have a fileOffset",
      //       context: node);
      // }
      return fileUri;
    } else {
      if (fileUri == null) {
        problem(node, "'$name' has no fileUri", context: node);
        return fileUri;
      }
      if (node.fileOffset == -1 && node is! Library) {
        problem(node, "'$name' has no fileOffset", context: node);
      }
      return fileUri;
    }
  }

  @override
  problem(TreeNode node, String details, {TreeNode context}) {
    node ??= (context ?? this.context);
    int offset = node?.fileOffset ?? -1;
    LocatedMessage message = templateInternalVerificationError
        .withArguments(details)
        .withLocation(fileUri == null ? null : Uri.parse(fileUri), offset);
    CompilerContext.current.report(message, Severity.error);
    errors.add(message);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    // Bypass verification of the [StaticGet] in [RedirectingFactoryBody] as
    // this is a static get without a getter.
    if (node is! RedirectingFactoryBody) {
      super.visitExpressionStatement(node);
    }
  }

  @override
  visitLibrary(Library node) {
    fileUri = checkLocation(node, node.name, node.fileUri);
    super.visitLibrary(node);
  }

  @override
  visitClass(Class node) {
    fileUri = checkLocation(node, node.name, node.fileUri);
    super.visitClass(node);
  }

  @override
  visitField(Field node) {
    fileUri = checkLocation(node, node.name.name, node.fileUri);
    super.visitField(node);
  }

  @override
  visitProcedure(Procedure node) {
    fileUri = checkLocation(node, node.name.name, node.fileUri);
    super.visitProcedure(node);
  }

  @override
  visitInvalidExpression(InvalidExpression node) {
    problem(node, "Invalid expression.");
  }

  @override
  visitInvalidStatement(InvalidStatement node) {
    problem(node, "Invalid statement.");
  }

  @override
  visitInvalidInitializer(InvalidInitializer node) {
    problem(node, "Invalid initializer.");
  }

  @override
  visitUnknownType(UnknownType node) {
    // Note: we can't pass [node] to [problem] because it's not a [TreeNode].
    problem(null, "Unexpected appearance of the unknown type.");
  }
}
