// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class CreateLocalVariable extends CorrectionProducer {
  String _variableName;

  @override
  List<Object> get fixArguments => [_variableName];

  @override
  FixKind get fixKind => DartFixKind.CREATE_LOCAL_VARIABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is! SimpleIdentifier) {
      return;
    }
    SimpleIdentifier nameNode = node;
    _variableName = nameNode.name;
    // if variable is assigned, convert assignment into declaration
    if (node.parent is AssignmentExpression) {
      AssignmentExpression assignment = node.parent;
      if (assignment.leftHandSide == node &&
          assignment.operator.type == TokenType.EQ &&
          assignment.parent is ExpressionStatement) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleInsertion(node.offset, 'var ');
        });
        return;
      }
    }
    // prepare target Statement
    var target = node.thisOrAncestorOfType<Statement>();
    if (target == null) {
      return;
    }
    var prefix = utils.getNodePrefix(target);
    // compute type
    var type = inferUndefinedExpressionType(node);
    if (!(type == null || type is InterfaceType || type is FunctionType)) {
      return;
    }
    // build variable declaration source
    await builder.addDartFileEdit(file, (builder) {
      builder.addInsertion(target.offset, (builder) {
        builder.writeLocalVariableDeclaration(_variableName,
            nameGroupName: 'NAME', type: type, typeGroupName: 'TYPE');
        builder.write(eol);
        builder.write(prefix);
      });
      builder.addLinkedPosition(range.node(node), 'NAME');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static CreateLocalVariable newInstance() => CreateLocalVariable();
}
