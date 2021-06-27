// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveUnnecessaryCast extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => false;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REMOVE_UNNECESSARY_CAST;

  @override
  FixKind get multiFixKind => DartFixKind.REMOVE_UNNECESSARY_CAST_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var asExpression = coveredNode;
    if (asExpression is! AsExpression) {
      return;
    }

    // remove 'as T' from 'e as T'
    await builder.addDartFileEdit(file, (builder) {
      var expression = asExpression.expression;
      builder.addDeletion(range.endEnd(expression, asExpression));
      builder.removeEnclosingParentheses(asExpression);
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static RemoveUnnecessaryCast newInstance() => RemoveUnnecessaryCast();
}
