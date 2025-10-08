// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceNullWithClosure extends ResolvedCorrectionProducer {
  ReplaceNullWithClosure({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceNullWithClosure;

  @override
  FixKind get multiFixKind => DartFixKind.replaceNullWithClosureMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode nodeToFix;
    var parameters = const <FormalParameterElement>[];

    var coveringNode = this.coveringNode;
    if (coveringNode is NamedExpression) {
      var expression = coveringNode.expression;
      if (expression is NullLiteral) {
        var element = coveringNode.element;
        if (element is FormalParameterElement) {
          var type = element.type;
          if (type is FunctionType) {
            parameters = type.formalParameters;
          }
        }
        nodeToFix = expression;
      } else {
        return;
      }
    } else if (coveringNode is NullLiteral) {
      nodeToFix = coveringNode;
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(nodeToFix), (builder) {
        builder.writeFormalParameters(parameters);
        builder.write(' => null');
      });
    });
  }
}
