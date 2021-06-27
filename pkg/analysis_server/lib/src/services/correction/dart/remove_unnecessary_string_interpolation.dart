// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryStringInterpolation extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_STRING_INTERPOLATION;

  @override
  FixKind get multiFixKind =>
      DartFixKind.REMOVE_UNNECESSARY_STRING_INTERPOLATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final interpolation = node;
    if (interpolation is StringInterpolation) {
      final open = interpolation.elements[0] as InterpolationString;
      final contents = interpolation.elements[1] as InterpolationExpression;
      final close = interpolation.elements[2] as InterpolationString;

      await builder.addDartFileEdit(file, (builder) {
        final expression = contents.expression;
        if (getExpressionPrecedence(expression) <
            getExpressionParentPrecedence(interpolation)) {
          builder.addReplacement(range.startStart(open, expression), (builder) {
            builder.write('(');
          });
          builder.addReplacement(range.endEnd(expression, close), (builder) {
            builder.write(')');
          });
        } else {
          builder.addDeletion(range.startStart(open, expression));
          builder.addDeletion(range.endEnd(expression, close));
        }
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnnecessaryStringInterpolation newInstance() =>
      RemoveUnnecessaryStringInterpolation();
}
