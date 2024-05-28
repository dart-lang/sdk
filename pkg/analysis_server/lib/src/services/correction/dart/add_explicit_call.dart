// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddExplicitCall extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.ADD_EXPLICIT_CALL;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_EXPLICIT_CALL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    AstNode? current = node;
    while (current != null && current is! ImplicitCallReference) {
      current = current.parent;
    }
    if (current == null) return;
    var implicitReference = current as ImplicitCallReference;
    var expression = implicitReference.expression;
    var needsParens = expression.precedence < Precedence.postfix;
    await builder.addDartFileEdit(file, (builder) {
      var sourceRange = range.node(expression);
      if (needsParens) {
        builder.addInsertion(sourceRange.offset, (builder) {
          builder.write('(');
        });
      }
      builder.addInsertion(sourceRange.end, (builder) {
        if (needsParens) {
          builder.write(')');
        }
        builder.write('.call');
      });
    });
  }
}
