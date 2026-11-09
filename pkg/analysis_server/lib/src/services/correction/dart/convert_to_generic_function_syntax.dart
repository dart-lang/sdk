// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToGenericFunctionSyntax extends ParsedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  AssistKind get assistKind => DartAssistKind.convertIntoGenericFunctionSyntax;

  @override
  FixKind get fixKind => DartFixKind.convertToGenericFunctionSyntax;

  @override
  FixKind get multiFixKind => DartFixKind.convertToGenericFunctionSyntaxMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    for (var node in node.withAncestors) {
      if (node is FunctionTypeAlias) {
        return _convertFunctionTypeAlias(builder, node);
      } else if (node is FormalParameter && node.functionTypedSuffix != null) {
        return _convertFunctionTypedFormalParameter(builder, node);
      } else if (node is FormalParameterList && diagnostic == null) {
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
      if (parameter.functionTypedSuffix != null) {
        continue;
      }
      if (parameter.type == null) {
        return false;
      }
    }
    return true;
  }

  Future<void> _convertFunctionTypeAlias(
    ChangeBuilder builder,
    FunctionTypeAlias node,
  ) async {
    if (!_allParametersHaveTypes(node.parameters)) {
      return;
    }

    String? returnType;
    var returnTypeNode = node.returnType;
    if (returnTypeNode != null) {
      returnType = utils.getNodeText(returnTypeNode);
    }

    var functionName = utils.getRangeText(
      range.startEnd(node.name, node.typeParameters ?? node.name),
    );
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
        replacement,
      );
    });
  }

  Future<void> _convertFunctionTypedFormalParameter(
    ChangeBuilder builder,
    FormalParameter node,
  ) async {
    var functionTypedSuffix = node.functionTypedSuffix;
    if (functionTypedSuffix == null ||
        !_allParametersHaveTypes(functionTypedSuffix.formalParameters)) {
      return;
    }
    var required = node.requiredKeyword != null ? 'required ' : '';
    var covariant = node.covariantKeyword != null ? 'covariant ' : '';
    var declaringKeyword = _declaringKeyword(node);
    var returnTypeNode = node.type;
    var returnType = returnTypeNode != null
        ? '${utils.getNodeText(returnTypeNode)} '
        : '';
    var functionName = node.name?.lexeme;
    if (functionName == null) {
      return;
    }
    var namePrefix = switch (node) {
      FieldFormalParameter() => 'this.',
      SuperFormalParameter() => 'super.',
      _ => '',
    };
    var typeParametersNode = functionTypedSuffix.typeParameters;
    var typeParameters = typeParametersNode != null
        ? utils.getNodeText(typeParametersNode)
        : '';

    var parameters = utils.getNodeText(functionTypedSuffix.formalParameters);
    var question = functionTypedSuffix.question != null ? '?' : '';
    var replacement =
        '$required$covariant$declaringKeyword${returnType}Function'
        '$typeParameters$parameters$question $namePrefix$functionName';

    // Leave the doc comment, annotations, and default value outside the edit.
    // `range.node` covers those, and this rebuild does not.
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.startEnd(
          node.firstTokenAfterCommentAndMetadata,
          functionTypedSuffix,
        ),
        replacement,
      );
    });
  }

  /// The `final` or `var` of a primary-constructor parameter, with a trailing
  /// space, or empty.
  ///
  /// Those keywords make the parameter declaring. The function-type syntax
  /// still accepts them there, so dropping them deletes the field. Elsewhere
  /// `final` and `var` are already illegal on an old-style function-typed
  /// parameter, and omitting them produces a valid parameter. `var` is also
  /// illegal on an extension type representation field, which is implicitly
  /// final.
  String _declaringKeyword(FormalParameter node) {
    if (node is! RegularFormalParameter) {
      return '';
    }
    var keyword = node.finalKeyword ?? node.varKeyword;
    var declaration = _primaryConstructorDeclaration(node);
    if (keyword == null || declaration == null) {
      return '';
    }
    if (keyword.lexeme == 'var' &&
        declaration.parent is ExtensionTypeDeclaration) {
      return '';
    }
    return '${keyword.lexeme} ';
  }

  /// The primary constructor containing [node], or `null` when [node] is nested
  /// inside a function-typed suffix or is not in a primary constructor.
  PrimaryConstructorDeclaration? _primaryConstructorDeclaration(
    FormalParameter node,
  ) {
    var current = node.parent;
    while (current != null) {
      if (current is FunctionTypedFormalParameterSuffix) {
        return null;
      }
      if (current is PrimaryConstructorDeclaration) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }
}
