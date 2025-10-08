// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceContainerWithColoredBox extends ResolvedCorrectionProducer {
  ReplaceContainerWithColoredBox({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.replaceContainerWithColoredBox;

  @override
  FixKind? get multiFixKind => DartFixKind.replaceContainerWithColoredBoxMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic is Diagnostic) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.diagnostic(diagnostic),
          'ColoredBox',
        );
      });
    }
  }
}
