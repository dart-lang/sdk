// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class ConvertToNullAwareSpread extends ResolvedCorrectionProducer {
  ConvertToNullAwareSpread({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_NULL_AWARE_SPREAD;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = coveringNode?.parent;
    if (parent is SpreadElement && !parent.isNullAware) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(parent.spreadOperator.end, '?');
      });
    }
  }
}
