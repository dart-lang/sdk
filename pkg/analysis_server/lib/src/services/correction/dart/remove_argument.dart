// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveArgument extends ResolvedCorrectionProducer {
  RemoveArgument({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeArgument;

  @override
  FixKind get multiFixKind => DartFixKind.removeArgumentMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var arg = node;
    if (arg is! Expression) {
      return;
    }

    arg = stepUpNamedExpression(arg);

    var argumentList = arg.parent?.thisOrAncestorOfType<ArgumentList>();
    if (argumentList == null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var sourceRange = range.nodeInListWithComments(
        unitResult.lineInfo,
        argumentList.arguments,
        arg,
      );
      builder.addDeletion(sourceRange);
    });
  }
}
