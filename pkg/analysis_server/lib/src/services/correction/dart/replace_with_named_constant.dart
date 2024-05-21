// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithNamedConstant extends ResolvedCorrectionProducer {
  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.USE_NAMED_CONSTANTS;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic is AnalysisError) {
      String? correctionMessage = diagnostic.correctionMessage;
      if (correctionMessage == null) {
        return;
      }

      String? correction = _getCorrection(correctionMessage);
      if (correction == null) {
        return;
      }

      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.error(diagnostic), correction);
      });
    }
  }

  static String? _getCorrection(String message) {
    var match = RegExp(r"'(.*)'").firstMatch(message);
    if (match == null) {
      return null;
    }
    return match.group(1);
  }
}
