// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class WrapInFuture extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.WRAP_IN_FUTURE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    //
    // Extract the information needed to build the edit.
    //
    Expression expression;
    if (node is ReturnStatement) {
      expression = (node as ReturnStatement).expression;
    } else if (node is Expression) {
      expression = node;
    } else {
      return;
    }
    var value = utils.getNodeText(expression);
    //
    // Build the edit.
    //
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.node(expression), 'Future.value($value)');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static WrapInFuture newInstance() => WrapInFuture();
}
