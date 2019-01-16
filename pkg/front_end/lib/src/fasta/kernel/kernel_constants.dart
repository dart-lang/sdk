// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_constants;

import 'package:kernel/ast.dart'
    show
        Constant,
        DartType,
        EnvironmentBoolConstant,
        EnvironmentIntConstant,
        EnvironmentStringConstant,
        IntConstant,
        Library,
        ListConstant,
        MapConstant,
        Member,
        NullConstant,
        StaticInvocation,
        StringConstant,
        TreeNode;

import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'package:kernel/transformations/constants.dart'
    show ConstantsBackend, ErrorReporter;

import '../fasta_codes.dart'
    show
        Message,
        noLength,
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

import '../problems.dart' show unexpected, unimplemented;

class KernelConstantErrorReporter extends ErrorReporter {
  final Loader<Library> loader;
  final TypeEnvironment typeEnvironment;

  KernelConstantErrorReporter(this.loader, this.typeEnvironment);

  void addProblem(TreeNode node, Message message) {
    loader.addProblem(message, getFileOffset(node), noLength, getFileUri(node));
  }

  @override
  void freeTypeParameter(List<TreeNode> context, TreeNode node, DartType type) {
    addProblem(node, templateConstEvalFreeTypeParameter.withArguments(type));
  }

  @override
  void duplicateKey(List<TreeNode> context, TreeNode node, Constant key) {
    addProblem(node, templateConstEvalDuplicateKey.withArguments(key));
  }

  @override
  void invalidDartType(List<TreeNode> context, TreeNode node, Constant receiver,
      DartType expectedType) {
    addProblem(
        node,
        templateConstEvalInvalidType.withArguments(
            receiver, expectedType, receiver.getType(typeEnvironment)));
  }

  @override
  void invalidBinaryOperandType(
      List<TreeNode> context,
      TreeNode node,
      Constant receiver,
      String op,
      DartType expectedType,
      DartType actualType) {
    addProblem(
        node,
        templateConstEvalInvalidBinaryOperandType.withArguments(
            op, receiver, expectedType, actualType));
  }

  @override
  void invalidMethodInvocation(
      List<TreeNode> context, TreeNode node, Constant receiver, String op) {
    addProblem(node,
        templateConstEvalInvalidMethodInvocation.withArguments(op, receiver));
  }

  @override
  void invalidStaticInvocation(
      List<TreeNode> context, TreeNode node, Member target) {
    addProblem(
        node,
        templateConstEvalInvalidStaticInvocation
            .withArguments(target.name.toString()));
  }

  @override
  void invalidStringInterpolationOperand(
      List<TreeNode> context, TreeNode node, Constant constant) {
    addProblem(
        node,
        templateConstEvalInvalidStringInterpolationOperand
            .withArguments(constant));
  }

  @override
  void invalidSymbolName(
      List<TreeNode> context, TreeNode node, Constant constant) {
    addProblem(
        node, templateConstEvalInvalidSymbolName.withArguments(constant));
  }

  @override
  void zeroDivisor(
      List<TreeNode> context, TreeNode node, IntConstant receiver, String op) {
    addProblem(node,
        templateConstEvalZeroDivisor.withArguments(op, '${receiver.value}'));
  }

  @override
  void negativeShift(List<TreeNode> context, TreeNode node,
      IntConstant receiver, String op, IntConstant argument) {
    addProblem(
        node,
        templateConstEvalNegativeShift.withArguments(
            op, '${receiver.value}', '${argument.value}'));
  }

  @override
  void nonConstLiteral(List<TreeNode> context, TreeNode node, String klass) {
    addProblem(node, templateConstEvalNonConstantLiteral.withArguments(klass));
  }

  @override
  void failedAssertion(List<TreeNode> context, TreeNode node, String string) {
    if (string == null) {
      addProblem(node, messageConstEvalFailedAssertion);
    } else {
      addProblem(node,
          templateConstEvalFailedAssertionWithMessage.withArguments(string));
    }
  }

  @override
  void nonConstantVariableGet(
      List<TreeNode> context, TreeNode node, String variableName) {
    addProblem(node,
        templateConstEvalNonConstantVariableGet.withArguments(variableName));
  }

  @override
  void deferredLibrary(
      List<TreeNode> context, TreeNode node, String importName) {
    addProblem(
        node, templateConstEvalDeferredLibrary.withArguments(importName));
  }
}

class KernelConstantsBackend extends ConstantsBackend {
  @override
  Constant lowerListConstant(ListConstant constant) => constant;

  @override
  Constant lowerMapConstant(MapConstant constant) => constant;

  @override
  Constant buildConstantForNative(
      String nativeName,
      List<DartType> typeArguments,
      List<Constant> positionalArguments,
      Map<String, Constant> namedArguments,
      List<TreeNode> context,
      StaticInvocation node,
      ErrorReporter errorReporter,
      void abortEvaluation()) {
    // VM-specific names of the fromEnvironment factory constructors.
    if (nativeName == 'Bool_fromEnvironment' ||
        nativeName == 'Integer_fromEnvironment' ||
        nativeName == 'String_fromEnvironment') {
      if (positionalArguments.length == 1 &&
          positionalArguments.first is StringConstant &&
          (namedArguments.length == 0 ||
              (namedArguments.length == 1 &&
                  namedArguments.containsKey('defaultValue')))) {
        StringConstant name = positionalArguments.first;
        Constant defaultValue =
            namedArguments['defaultValue'] ?? new NullConstant();
        if (nativeName == 'Bool_fromEnvironment') {
          return new EnvironmentBoolConstant(name.value, defaultValue);
        }
        if (nativeName == 'Integer_fromEnvironment') {
          return new EnvironmentIntConstant(name.value, defaultValue);
        }
        return new EnvironmentStringConstant(name.value, defaultValue);
      }
      return unexpected('valid constructor invocation', node.toString(),
          node.fileOffset, node.location.file);
    }
    return unimplemented('constant evaluation of ${nativeName}',
        node.fileOffset, node.location.file);
  }
}
