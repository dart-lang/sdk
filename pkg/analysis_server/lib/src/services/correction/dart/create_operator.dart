// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class CreateOperator extends ResolvedCorrectionProducer {
  String _operator = '';

  CreateOperator({required super.context});

  @override
  CorrectionApplicability get applicability {
    // Not predictably the correct action.
    return CorrectionApplicability.singleLocation;
  }

  @override
  List<String>? get fixArguments => [_operator];

  @override
  FixKind get fixKind => DartFixKind.createOperator;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    bool indexSetter = false;
    bool innerParameter = true;
    var node = this.node;
    if (node is! Expression) {
      return;
    }

    Expression? target;
    DartType? parameterType;
    Fragment? targetFragment;
    DartType? assigningType;
    CompilationUnitMember? targetNode;

    switch (node) {
      case IndexExpression(:var parent):
        target = node.target;
        _operator = TokenType.INDEX.lexeme;
        parameterType = node.index.staticType;
        if (parameterType == null) {
          return;
        }
        if (parent case AssignmentExpression(
          :var leftHandSide,
          :var rightHandSide,
        ) when leftHandSide == node) {
          assigningType = rightHandSide.staticType;
          indexSetter = true;
          _operator = TokenType.INDEX_EQ.lexeme;
        }
      case BinaryExpression():
        target = node.leftOperand;
        _operator = node.operator.lexeme;
        parameterType = node.rightOperand.staticType;
        if (parameterType == null) {
          return;
        }
      case PrefixExpression():
        target = node.operand;
        _operator = node.operator.lexeme;
        innerParameter = false;
    }

    if (target == null) {
      return;
    }

    // We need the type for the extension.
    var targetType = target.staticType;
    if (targetType == null ||
        targetType is DynamicType ||
        targetType is InvalidType) {
      return;
    }

    DartType returnType;
    // If this is an index setter, the return type must be void.
    if (indexSetter) {
      returnType = VoidTypeImpl.instance;
    } else {
      // Try to find the return type.
      returnType = inferUndefinedExpressionType(node) ?? VoidTypeImpl.instance;
    }
    if (returnType is InvalidType) {
      return;
    }

    var targetClassElement = getTargetInterfaceElement(target);
    if (targetClassElement == null) {
      return;
    }
    targetFragment = targetClassElement.firstFragment;
    if (targetClassElement.library.isInSdk) {
      return;
    }
    // Prepare target ClassDeclaration.
    if (targetClassElement is MixinElement) {
      var fragment = targetClassElement.firstFragment;
      targetNode = await getMixinDeclaration(fragment);
    } else if (targetClassElement is ClassElement) {
      var fragment = targetClassElement.firstFragment;
      targetNode = await getClassDeclaration(fragment);
    } else if (targetClassElement is ExtensionTypeElement) {
      var fragment = targetClassElement.firstFragment;
      targetNode = await getExtensionTypeDeclaration(fragment);
    } else if (targetClassElement is EnumElement) {
      var fragment = targetClassElement.firstFragment;
      targetNode = await getEnumDeclaration(fragment);
    }
    if (targetNode == null) {
      return;
    }
    // Use different utils.
    var targetPath = targetFragment.libraryFragment!.source.fullName;
    var targetResolveResult = await unitResult.session.getResolvedUnit(
      targetPath,
    );
    if (targetResolveResult is! ResolvedUnitResult) {
      return;
    }
    var targetSource = targetFragment.libraryFragment!.source;
    var targetFile = targetSource.fullName;

    var writeReturnType = getCodeStyleOptions(
      unitResult.file,
    ).specifyReturnTypes;

    if (returnType is TypeParameterType) {
      returnType = returnType.bound;
    }

    await builder.addDartFileEdit(targetFile, (builder) {
      if (targetNode == null) {
        return;
      }
      builder.insertMethod(targetNode, (builder) {
        // Append return type.
        builder.writeType(returnType, shouldWriteDynamic: writeReturnType);
        if ((returnType is! DynamicType && returnType is! InvalidType) ||
            writeReturnType) {
          builder.write(' ');
        }
        builder.write('operator ');
        builder.write(_operator);
        // Append parameters.
        if (innerParameter) {
          builder.write('(');
          builder.writeParameter('other', type: parameterType);
          if (assigningType != null) {
            builder.write(', ');
            builder.writeParameter('value', type: assigningType);
          }
          builder.write(')');
        } else {
          builder.write('()');
        }
        if (returnType.isDartAsyncFuture) {
          builder.write(' async');
        }
        builder.write(' {}');
      });
    });
  }
}
