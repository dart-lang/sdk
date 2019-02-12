// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart'
    show Constant, DartType, IntConstant, Library, Member, Procedure, TreeNode;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/transformations/constants.dart' show ErrorReporter;

import '../fasta_codes.dart'
    show
        Message,
        noLength,
        messageConstEvalCircularity,
        messageConstEvalFailedAssertion,
        templateConstEvalDeferredLibrary,
        templateConstEvalDuplicateKey,
        templateConstEvalFailedAssertionWithMessage,
        templateConstEvalFreeTypeParameter,
        templateConstEvalInvalidBinaryOperandType,
        templateConstEvalInvalidMethodInvocation,
        templateConstEvalInvalidStaticInvocation,
        templateConstEvalInvalidStringInterpolationOperand,
        templateConstEvalInvalidSymbolName,
        templateConstEvalInvalidType,
        templateConstEvalNegativeShift,
        templateConstEvalNonConstantLiteral,
        templateConstEvalNonConstantVariableGet,
        templateConstEvalZeroDivisor;

import '../loader.dart' show Loader;

class KernelConstantErrorReporter extends ErrorReporter {
  final Loader<Library> loader;
  final TypeEnvironment typeEnvironment;

  KernelConstantErrorReporter(this.loader, this.typeEnvironment);

  String addProblem(TreeNode node, Message message) {
    int offset = getFileOffset(node);
    Uri uri = getFileUri(node);
    loader.addProblem(message, offset, noLength, uri);
    return loader.target.context.format(
        message.withLocation(uri, offset, noLength), message.code.severity);
  }

  @override
  String freeTypeParameter(
      List<TreeNode> context, TreeNode node, DartType type) {
    return addProblem(
        node, templateConstEvalFreeTypeParameter.withArguments(type));
  }

  @override
  String duplicateKey(List<TreeNode> context, TreeNode node, Constant key) {
    return addProblem(node, templateConstEvalDuplicateKey.withArguments(key));
  }

  @override
  String invalidDartType(List<TreeNode> context, TreeNode node,
      Constant receiver, DartType expectedType) {
    return addProblem(
        node,
        templateConstEvalInvalidType.withArguments(
            receiver, expectedType, receiver.getType(typeEnvironment)));
  }

  @override
  String invalidBinaryOperandType(
      List<TreeNode> context,
      TreeNode node,
      Constant receiver,
      String op,
      DartType expectedType,
      DartType actualType) {
    return addProblem(
        node,
        templateConstEvalInvalidBinaryOperandType.withArguments(
            op, receiver, expectedType, actualType));
  }

  @override
  String invalidMethodInvocation(
      List<TreeNode> context, TreeNode node, Constant receiver, String op) {
    return addProblem(node,
        templateConstEvalInvalidMethodInvocation.withArguments(op, receiver));
  }

  @override
  String invalidStaticInvocation(
      List<TreeNode> context, TreeNode node, Member target) {
    // TODO(kmillikin) For an invalid factory invocation we should adopt a
    // better message.  This will show something like:
    //
    // "The invocation of 'List' is not allowed within a const context."
    //
    // Which is not quite right when the code was "new List()".
    String name = target.name.toString();
    if (target is Procedure && target.isFactory) {
      if (name.isEmpty) {
        name = target.enclosingClass.name;
      } else {
        name = '${target.enclosingClass.name}.${name}';
      }
    }
    return addProblem(
        node, templateConstEvalInvalidStaticInvocation.withArguments(name));
  }

  @override
  String invalidStringInterpolationOperand(
      List<TreeNode> context, TreeNode node, Constant constant) {
    return addProblem(
        node,
        templateConstEvalInvalidStringInterpolationOperand
            .withArguments(constant));
  }

  @override
  String invalidSymbolName(
      List<TreeNode> context, TreeNode node, Constant constant) {
    return addProblem(
        node, templateConstEvalInvalidSymbolName.withArguments(constant));
  }

  @override
  String zeroDivisor(
      List<TreeNode> context, TreeNode node, IntConstant receiver, String op) {
    return addProblem(node,
        templateConstEvalZeroDivisor.withArguments(op, '${receiver.value}'));
  }

  @override
  String negativeShift(List<TreeNode> context, TreeNode node,
      IntConstant receiver, String op, IntConstant argument) {
    return addProblem(
        node,
        templateConstEvalNegativeShift.withArguments(
            op, '${receiver.value}', '${argument.value}'));
  }

  @override
  String nonConstLiteral(List<TreeNode> context, TreeNode node, String klass) {
    return addProblem(
        node, templateConstEvalNonConstantLiteral.withArguments(klass));
  }

  @override
  String failedAssertion(List<TreeNode> context, TreeNode node, String string) {
    return addProblem(
        node,
        (string == null)
            ? messageConstEvalFailedAssertion
            : templateConstEvalFailedAssertionWithMessage
                .withArguments(string));
  }

  @override
  String nonConstantVariableGet(
      List<TreeNode> context, TreeNode node, String variableName) {
    return addProblem(node,
        templateConstEvalNonConstantVariableGet.withArguments(variableName));
  }

  @override
  String deferredLibrary(
      List<TreeNode> context, TreeNode node, String importName) {
    return addProblem(
        node, templateConstEvalDeferredLibrary.withArguments(importName));
  }

  @override
  String circularity(List<TreeNode> context, TreeNode node) {
    return addProblem(node, messageConstEvalCircularity);
  }
}
