// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddTrailingComma extends ResolvedCorrectionProducer {
  AddTrailingComma({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.addTrailingComma;

  @override
  FixKind get multiFixKind => DartFixKind.addTrailingCommaMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is ArgumentList) {
      await _insertComma(builder, node.arguments.last);
    } else if (node is FormalParameterList) {
      await _insertComma(builder, node.parameters.last);
    } else if (node is Assertion) {
      await _insertComma(builder, node.message ?? node.condition);
    } else if (node is ListLiteral) {
      await _insertComma(builder, node.elements.last);
    } else if (node is SetOrMapLiteral) {
      await _insertComma(builder, node.elements.last);
    } else if (node is ParenthesizedExpression) {
      await _insertComma(builder, node.expression);
    } else if (node is RecordLiteral) {
      await _insertComma(builder, node.fields.last);
    } else if (node is RecordTypeAnnotation) {
      await _insertComma(builder, node.positionalFields.last);
    }
  }

  Future<void> _insertComma(ChangeBuilder builder, AstNode lastNode) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleInsertion(lastNode.end, ',');
    });
  }
}
