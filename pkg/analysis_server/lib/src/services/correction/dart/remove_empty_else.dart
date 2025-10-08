// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveEmptyElse extends ResolvedCorrectionProducer {
  RemoveEmptyElse({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeEmptyElse;

  @override
  FixKind get multiFixKind => DartFixKind.removeEmptyElseMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = node.parent;
    if (parent is IfStatement) {
      var elseKeyword = parent.elseKeyword;
      var elseStatement = parent.elseStatement;
      if (elseKeyword != null && elseStatement != null) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(
            utils.getLinesRange(range.startEnd(elseKeyword, elseStatement)),
          );
        });
      }
    }
  }
}
