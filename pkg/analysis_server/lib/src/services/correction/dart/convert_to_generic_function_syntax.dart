// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToGenericFunctionSyntax extends CorrectionProducer {
  @override
  AssistKind get assistKind =>
      DartAssistKind.CONVERT_INTO_GENERIC_FUNCTION_SYNTAX;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_GENERIC_FUNCTION_SYNTAX;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    while (node != null) {
      if (node is FunctionTypeAlias) {
        return _convertFunctionTypeAlias(builder, node);
      } else if (node is FunctionTypedFormalParameter) {
        return _convertFunctionTypedFormalParameter(builder, node);
      } else if (node is FormalParameterList) {
        // It would be confusing for this assist to alter a surrounding context
        // when the selection is inside a parameter list.
        return null;
      }
      node = node.parent;
    }
  }

  /// Return `true` if all of the parameters in the given list of [parameters]
  /// have an explicit type annotation.
  bool _allParametersHaveTypes(FormalParameterList parameters) {
    for (var parameter in parameters.parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = (parameter as DefaultFormalParameter).parameter;
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
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
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
          range.startStart(node.typedefKeyword.next, node.semicolon),
          replacement);
    });
  }

  Future<void> _convertFunctionTypedFormalParameter(
      ChangeBuilder builder, FunctionTypedFormalParameter node) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }
    String returnType;
    if (node.returnType != null) {
      returnType = utils.getNodeText(node.returnType);
    }
    var functionName = utils.getRangeText(range.startEnd(
        node.identifier, node.typeParameters ?? node.identifier));
    var parameters = utils.getNodeText(node.parameters);
    String replacement;
    if (returnType == null) {
      replacement = 'Function$parameters $functionName';
    } else {
      replacement = '$returnType Function$parameters $functionName';
    }
    // add change
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.node(node), replacement);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToGenericFunctionSyntax newInstance() =>
      ConvertToGenericFunctionSyntax();
}
