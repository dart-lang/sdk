// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateLocalVariable extends ResolvedCorrectionProducer {
  String _variableName = '';

  CreateLocalVariable({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  List<String> get fixArguments => [_variableName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_LOCAL_VARIABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var nameNode = node;
    if (nameNode is! SimpleIdentifier) {
      return;
    }
    _variableName = nameNode.name;
    // if variable is assigned, convert assignment into declaration
    var assignment = node.parent;
    if (assignment is AssignmentExpression) {
      if (assignment.leftHandSide == node &&
          assignment.operator.type == TokenType.EQ &&
          assignment.parent is ExpressionStatement) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(node.offset, 'var ');
        });
        return;
      }
    }

    // In `foo.bar`, `bar` is not a local variable.
    // It also does not seem useful to suggest `foo`.
    // So, always skip with these parents.
    var parent = nameNode.parent;
    switch (parent) {
      case PrefixedIdentifier():
      case PropertyAccess():
        return;
    }

    // prepare target Statement
    var target = node.thisOrAncestorOfType<Statement>();
    if (target == null) {
      return;
    }
    var prefix = utils.getNodePrefix(target);
    // compute type
    var type = inferUndefinedExpressionType(nameNode);
    if (!(type == null ||
        type is InterfaceType ||
        type is FunctionType ||
        type is RecordType ||
        type is InvalidType)) {
      return;
    }
    // build variable declaration source
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(target.offset, (builder) {
        builder.writeLocalVariableDeclaration(
          _variableName,
          nameGroupName: 'NAME',
          type: type,
          typeGroupName: 'TYPE',
        );
        builder.writeln();
        builder.write(prefix);
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
  }
}
