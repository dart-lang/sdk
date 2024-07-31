// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';

class CiderAssistsComputer {
  final PerformanceLog _logger;
  final FileResolver _fileResolver;

  /// A mapping of [ProducerGenerator]s to the set of lint names with which they
  /// are associated (can fix).
  final Map<ProducerGenerator, Set<LintCode>> _producerGeneratorsForLintRules;

  CiderAssistsComputer(
      this._logger, this._fileResolver, this._producerGeneratorsForLintRules);

  /// Compute quick assists on the line and character position.
  Future<List<Assist>> compute(
      String path, int lineNumber, int colNumber, int length) async {
    var result = <Assist>[];
    var resolvedUnit = await _fileResolver.resolve(path: path);
    var lineInfo = resolvedUnit.lineInfo;
    var offset = lineInfo.getOffsetOfLine(lineNumber) + colNumber;

    await _logger.runAsync('Compute assists', () async {
      try {
        var workspace = DartChangeWorkspace([resolvedUnit.session]);
        var context = DartAssistContextImpl(
          InstrumentationService.NULL_SERVICE,
          workspace,
          resolvedUnit,
          _producerGeneratorsForLintRules,
          offset,
          length,
        );
        var processor = AssistProcessor(context);
        var assists = await processor.compute();
        assists.sort(Assist.compareAssists);
        result.addAll(assists);
      } on InconsistentAnalysisException {
        // If an InconsistentAnalysisException occurs, it's likely the user modified
        // the source and therefore is no longer interested in the results.
      }
    });
    return result;
  }
}
