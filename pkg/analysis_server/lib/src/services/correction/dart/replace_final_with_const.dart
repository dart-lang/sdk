// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceFinalWithConst extends ResolvedCorrectionProducer {
  ReplaceFinalWithConst({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceFinalWithConst;

  @override
  FixKind get multiFixKind => DartFixKind.replaceFinalWithConstMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is VariableDeclarationList) {
      var keyword = node.keyword;
      if (keyword != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addSimpleReplacement(range.token(keyword), 'const');
        });
      }

      for (var variable in node.variables) {
        var initializer = variable.initializer;
        if (initializer != null) {
          Token? constToken;
          if (initializer
              case InstanceCreationExpression(:var keyword) ||
                  DotShorthandConstructorInvocation(
                    constKeyword: Token? keyword,
                  )) {
            constToken = keyword;
          } else if (initializer is TypedLiteral) {
            constToken = initializer.constKeyword;
          }

          if (constToken == null) {
            continue;
          }

          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(
              range.startStart(constToken!, constToken.next!),
            );
          });
        }
      }
    }
  }
}
