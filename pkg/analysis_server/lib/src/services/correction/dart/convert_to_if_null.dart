// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfNull extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_IF_NULL;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is ConditionalExpression &&
        node.offset == errorOffset &&
        node.length == errorLength) {
      var condition = node.condition as BinaryExpression;
      Expression nullableExpression;
      Expression defaultExpression;
      if (condition.operator.type == TokenType.EQ_EQ) {
        nullableExpression = node.elseExpression;
        defaultExpression = node.thenExpression;
      } else {
        nullableExpression = node.thenExpression;
        defaultExpression = node.elseExpression;
      }
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(node), (builder) {
          builder.write(utils.getNodeText(nullableExpression));
          builder.write(' ?? ');
          builder.write(utils.getNodeText(defaultExpression));
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ConvertToIfNull newInstance() => ConvertToIfNull();
}
