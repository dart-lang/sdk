// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines [ForwardConstantEvaluationErrors], an implementation of
/// [constants.ErrorReporter] which uses package:front_end to report errors.
library vm.constants_error_reporter;

import 'package:front_end/src/api_unstable/vm.dart'
    show CompilerContext, Severity;

import 'package:front_end/src/api_unstable/vm.dart' as codes;

import 'package:kernel/ast.dart'
    show Constant, DartType, FileUriNode, IntConstant, Procedure, TreeNode;
import 'package:kernel/transformations/constants.dart' as constants;
import 'package:kernel/type_environment.dart' show TypeEnvironment;

class ForwardConstantEvaluationErrors implements constants.ErrorReporter {
  // This will get the currently active [CompilerContext] from a zone variable.
  // If there is no active context, this will throw.
  final CompilerContext compilerContext = CompilerContext.current;

  final TypeEnvironment typeEnvironment;

  ForwardConstantEvaluationErrors(this.typeEnvironment);

  duplicateKey(List<TreeNode> context, TreeNode node, Constant key) {
    final message = codes.templateConstEvalDuplicateKey.withArguments(key);
    reportIt(context, message, node);
  }

  invalidDartType(List<TreeNode> context, TreeNode node, Constant receiver,
      DartType expectedType) {
    final message = codes.templateConstEvalInvalidType.withArguments(
        receiver, expectedType, receiver.getType(typeEnvironment));
    reportIt(context, message, node);
  }

  invalidBinaryOperandType(
      List<TreeNode> context,
      TreeNode node,
      Constant receiver,
      String op,
      DartType expectedType,
      DartType actualType) {
    final message = codes.templateConstEvalInvalidBinaryOperandType
        .withArguments(op, receiver, expectedType, actualType);
    reportIt(context, message, node);
  }

  invalidMethodInvocation(
      List<TreeNode> context, TreeNode node, Constant receiver, String op) {
    final message = codes.templateConstEvalInvalidMethodInvocation
        .withArguments(op, receiver);
    reportIt(context, message, node);
  }

  invalidStaticInvocation(
      List<TreeNode> context, TreeNode node, Procedure target) {
    final message = codes.templateConstEvalInvalidStaticInvocation
        .withArguments(target.name.toString());
    reportIt(context, message, node);
  }

  invalidStringInterpolationOperand(
      List<TreeNode> context, TreeNode node, Constant constant) {
    final message = codes.templateConstEvalInvalidStringInterpolationOperand
        .withArguments(constant);
    reportIt(context, message, node);
  }

  zeroDivisor(
      List<TreeNode> context, TreeNode node, IntConstant receiver, String op) {
    final message = codes.templateConstEvalZeroDivisor
        .withArguments(op, '${receiver.value}');
    reportIt(context, message, node);
  }

  negativeShift(List<TreeNode> context, TreeNode node, IntConstant receiver,
      String op, IntConstant argument) {
    final message = codes.templateConstEvalNegativeShift
        .withArguments(op, '${receiver.value}', '${argument.value}');
    reportIt(context, message, node);
  }

  nonConstLiteral(List<TreeNode> context, TreeNode node, String klass) {
    final message =
        codes.templateConstEvalNonConstantLiteral.withArguments(klass);
    reportIt(context, message, node);
  }

  failedAssertion(List<TreeNode> context, TreeNode node, String string) {
    final message = string == null
        ? codes.messageConstEvalFailedAssertion
        : codes.templateConstEvalFailedAssertionWithMessage
            .withArguments(string);
    reportIt(context, message, node);
  }

  nonConstantVariableGet(
      List<TreeNode> context, TreeNode node, String variableName) {
    final message = codes.templateConstEvalNonConstantVariableGet
        .withArguments(variableName);
    reportIt(context, message, node);
  }

  deferredLibrary(List<TreeNode> context, TreeNode node, String importName) {
    final message =
        codes.templateConstEvalDeferredLibrary.withArguments(importName);
    reportIt(context, message, node);
  }

  reportIt(List<TreeNode> context, codes.Message message, TreeNode node) {
    final Uri uri = getFileUri(node);
    final int fileOffset = getFileOffset(node);

    final contextMessages = <codes.LocatedMessage>[];
    for (final TreeNode node in context) {
      final Uri uri = getFileUri(node);
      final int fileOffset = getFileOffset(node);
      contextMessages.add(codes.messageConstEvalContext
          .withLocation(uri, fileOffset, codes.noLength));
    }

    final locatedMessage =
        message.withLocation(uri, fileOffset, codes.noLength);

    compilerContext.options
        .report(locatedMessage, Severity.error, context: contextMessages);
  }

  getFileUri(TreeNode node) {
    while (node is! FileUriNode) {
      node = node.parent;
    }
    return (node as FileUriNode).fileUri;
  }

  getFileOffset(TreeNode node) {
    while (node?.fileOffset == TreeNode.noOffset) {
      node = node.parent;
    }
    return node == null ? TreeNode.noOffset : node.fileOffset;
  }
}
