// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RenameMethodParameter extends ResolvedCorrectionProducer {
  String _oldName = '';
  String _newName = '';

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_oldName, _newName];

  @override
  FixKind get fixKind => DartFixKind.RENAME_METHOD_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parameter = node;
    if (parameter is! FormalParameter) return;
    var paramIdentifier = parameter.name;
    if (paramIdentifier == null) return;

    var method = parameter.thisOrAncestorOfType<MethodDeclaration>();
    if (method == null) return;
    var methodParameters = method.parameters;
    if (methodParameters == null) return;

    var classDeclaration = method.parent as Declaration;
    var classElement = classDeclaration.declaredElement;
    if (classElement is! InterfaceElement) return;

    var parentMethod = classElement.lookUpInheritedMethod(
        method.name.lexeme, classElement.library);
    if (parentMethod == null) return;

    var parameters = methodParameters.parameters;
    var parentParameters = parentMethod.parameters;
    var oldName = paramIdentifier.lexeme;

    var i = parameters.indexOf(parameter);
    if (0 <= i && i < parentParameters.length) {
      var newName = parentParameters[i].name;

      var collector = _Collector(newName, parameter.declaredElement!);
      method.accept(collector);

      if (!collector.error) {
        _oldName = oldName;
        _newName = newName;

        await builder.addDartFileEdit(file, (builder) {
          for (var token in collector.oldTokens) {
            builder.addSimpleReplacement(range.token(token), newName);
          }
        });
      }
    }
  }
}

class _Collector extends RecursiveAstVisitor<void> {
  bool error = false;
  final String newName;
  final ParameterElement target;

  final oldTokens = <Token>[];

  _Collector(this.newName, this.target);

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _addNameToken(node.name, node.declaredElement);
    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addNameToken(node.token, node.staticElement);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _addNameToken(node.name, node.declaredElement);
    super.visitVariableDeclaration(node);
  }

  void _addNameToken(Token? nameToken, Element? element) {
    if (error) return;

    if (nameToken != null) {
      if (element == target) {
        oldTokens.add(nameToken);
      } else if (nameToken.lexeme == newName) {
        error = true;
      }
    }
  }
}
