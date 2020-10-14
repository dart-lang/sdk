// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNullWithClosure extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.REPLACE_NULL_WITH_CLOSURE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode nodeToFix;
    var parameters = const <ParameterElement>[];
    if (coveredNode is NamedExpression) {
      NamedExpression namedExpression = coveredNode;
      var expression = namedExpression.expression;
      if (expression is NullLiteral) {
        var element = namedExpression.element;
        if (element is ParameterElement) {
          var type = element.type;
          if (type is FunctionType) {
            parameters = type.parameters;
          }
        }
        nodeToFix = expression;
      }
    } else if (coveredNode is NullLiteral) {
      nodeToFix = coveredNode;
    }

    if (nodeToFix != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(range.node(nodeToFix), (builder) {
          builder.writeParameters(parameters);
          builder.write(' => null');
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static ReplaceNullWithClosure newInstance() => ReplaceNullWithClosure();
}
