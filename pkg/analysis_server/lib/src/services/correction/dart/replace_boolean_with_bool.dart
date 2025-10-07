// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceBooleanWithBool extends ResolvedCorrectionProducer {
  ReplaceBooleanWithBool({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.acrossSingleFile;

  @override
  FixKind get fixKind => DartFixKind.replaceBooleanWithBool;

  @override
  FixKind get multiFixKind => DartFixKind.replaceBooleanWithBoolMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (diagnostic case var diagnostic?) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.diagnostic(diagnostic), 'bool');
      });
    }
  }
}
