// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseEffectiveIntegerDivision extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    for (var n = node; n != null; n = n.parent) {
      if (n is MethodInvocation &&
          n.offset == errorOffset &&
          n.length == errorLength) {
        var target = (n as MethodInvocation).target.unParenthesized;
        await builder.addDartFileEdit(file, (builder) {
          // replace "/" with "~/"
          var binary = target as BinaryExpression;
          builder.addSimpleReplacement(range.token(binary.operator), '~/');
          // remove everything before and after
          builder.addDeletion(range.startStart(n, binary.leftOperand));
          builder.addDeletion(range.endEnd(binary.rightOperand, n));
        });
        // done
        break;
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static UseEffectiveIntegerDivision newInstance() =>
      UseEffectiveIntegerDivision();
}
