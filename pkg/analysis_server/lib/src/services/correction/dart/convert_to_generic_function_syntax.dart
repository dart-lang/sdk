// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToGenericFunctionSyntax extends ParsedCorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.CONVERT_INTO_GENERIC_FUNCTION_SYNTAX;

  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX;

  @override
  FixKind get multiFixKind =>
      DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    for (var node in this.node.withParents) {
      if (node is FunctionTypeAlias) {
        return _convertFunctionTypeAlias(builder, node);
      } else if (node is FunctionTypedFormalParameter) {
        return _convertFunctionTypedFormalParameter(builder, node);
      } else if (node is FormalParameterList) {
        // It would be confusing for this assist to alter a surrounding context
        // when the selection is inside a parameter list.
        return;
      }
    }
  }

  /// Return `true` if all of the parameters in the given list of [parameters]
  /// have an explicit type annotation.
  bool _allParametersHaveTypes(FormalParameterList parameters) {
    for (var parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      if (parameter is SimpleFormalParameter) {
        if (parameter.type == null) {
          return false;
        }
      } else if (parameter is! FunctionTypedFormalParameter) {
        return false;
      }
    }
    return true;
  }

  Future<void> _convertFunctionTypeAlias(
      ChangeBuilder builder, FunctionTypeAlias node) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }

    String? returnType;
    var returnTypeNode = node.returnType;
    if (returnTypeNode != null) {
      returnType = utils.getNodeText(returnTypeNode);
    }

    var functionName = utils.getRangeText(
        range.startEnd(node.name, node.typeParameters ?? node.name));
    var parameters = utils.getNodeText(node.parameters);
    String replacement;
    if (returnType == null) {
      replacement = '$functionName = Function$parameters';
    } else {
      replacement = '$functionName = $returnType Function$parameters';
    }
    // add change
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.startStart(node.typedefKeyword.next!, node.semicolon),
          replacement);
    });
  }

  Future<void> _convertFunctionTypedFormalParameter(
      ChangeBuilder builder, FunctionTypedFormalParameter node) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }
    var required = node.requiredKeyword != null ? 'required ' : '';
    var covariant = node.covariantKeyword != null ? 'covariant ' : '';
    var returnTypeNode = node.returnType;
    var returnType =
        returnTypeNode != null ? '${utils.getNodeText(returnTypeNode)} ' : '';
    var functionName = node.name.lexeme;
    var typeParametersNode = node.typeParameters;
    var typeParameters =
        typeParametersNode != null ? utils.getNodeText(typeParametersNode) : '';

    var parameters = utils.getNodeText(node.parameters);
    var question = node.question != null ? '?' : '';
    var replacement = '$required$covariant${returnType}Function'
        '$typeParameters$parameters$question $functionName';

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node), replacement);
    });
  }
}
