// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithIs extends ResolvedCorrectionProducer {
  late String operatorText;

  late String exclamationText;

  ReplaceWithIs({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // Changes an "always false" expression to an actual test.
      .singleLocation;

  @override
  List<String> get fixArguments => [operatorText, exclamationText];

  @override
  FixKind get fixKind => DartFixKind.replaceWithIs;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! BinaryExpression) {
      return;
    }
    var operator = node.operator;
    operatorText = operator.type.lexeme;
    exclamationText = operator.type == .BANG_EQ ? '!' : '';
    if (node.leftOperand case TypeLiteral()) {
      var type = node.leftOperand;
      var other = node.rightOperand;
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(range.startStart(type, other));
        builder.addInsertion(other.end, (builder) {
          builder.write(' is$exclamationText ');
          builder.write(type.toSource());
        });
      });
    } else if (node.rightOperand case TypeLiteral()) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.token(operator),
          'is$exclamationText',
        );
      });
    }
  }
}
