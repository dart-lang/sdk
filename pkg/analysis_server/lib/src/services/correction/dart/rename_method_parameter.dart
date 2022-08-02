// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RenameMethodParameter extends CorrectionProducer {
  String _oldName = '';
  String _newName = '';

  @override
  List<Object> get fixArguments => [_oldName, _newName];

  @override
  FixKind get fixKind => DartFixKind.RENAME_METHOD_PARAMETER;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final parameter = node.parent;
    if (parameter is! FormalParameter) return;
    var paramIdentifier = parameter.name;
    if (paramIdentifier == null) return;

    var method = parameter.thisOrAncestorOfType<MethodDeclaration>();
    if (method == null) return;
    var methodParameters = method.parameters;
    if (methodParameters == null) return;

    var classDeclaration = method.parent as Declaration;
    var classElement = classDeclaration.declaredElement;
    if (classElement is! ClassElement) return;

    var parentMethod = classElement.lookUpInheritedMethod(
        method.name2.lexeme, classElement.library);
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
          for (var i in collector.oldIdentifiers) {
            builder.addSimpleReplacement(range.node(i), newName);
          }
        });
      }
    }
  }
}

class _Collector extends RecursiveAstVisitor<void> {
  var error = false;
  final String newName;
  final ParameterElement target;

  final oldIdentifiers = <SimpleIdentifier>[];

  _Collector(this.newName, this.target);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (error) return;

    var nodeElement = node.staticElement;
    if (nodeElement == target) {
      oldIdentifiers.add(node);
    } else if (node.name == newName) {
      error = true;
    }
  }
}
