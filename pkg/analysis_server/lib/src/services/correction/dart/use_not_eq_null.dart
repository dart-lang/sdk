// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseNotEqNull extends ResolvedCorrectionProducer {
  UseNotEqNull({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.USE_NOT_EQ_NULL;

  @override
  FixKind get multiFixKind => DartFixKind.USE_NOT_EQ_NULL_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (coveringNode is IsExpression) {
      var isExpression = coveringNode as IsExpression;
      await builder.addDartFileEdit(file, (builder) {
        builder.addReplacement(
          range.endEnd(isExpression.expression, isExpression),
          (builder) {
            builder.write(' != null');
          },
        );
      });
    }
  }
}
