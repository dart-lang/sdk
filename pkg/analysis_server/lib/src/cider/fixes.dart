// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:meta/meta.dart';

class CiderErrorFixes {
  final AnalysisError error;

  /// The fixes for the [error], might be empty.
  final List<Fix> fixes;

  CiderErrorFixes({
    @required this.error,
    @required this.fixes,
  });
}

class CiderFixesComputer {
  final PerformanceLog _logger;
  final FileResolver _fileResolver;

  CiderFixesComputer(this._logger, this._fileResolver);

  /// Compute quick fixes for errors on the line with the [offset].
  Future<List<CiderErrorFixes>> compute(String path, int offset) async {
    var result = <CiderErrorFixes>[];
    var resolvedUnit = _fileResolver.resolve(path: path);

    var lineInfo = resolvedUnit.lineInfo;
    var requestLine = lineInfo.getLocation(offset).lineNumber;

    await _logger.runAsync('Compute fixes', () async {
      for (var error in resolvedUnit.errors) {
        var errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == requestLine) {
          var workspace = DartChangeWorkspace([resolvedUnit.session]);
          var context = DartFixContextImpl(
            InstrumentationService.NULL_SERVICE,
            workspace,
            resolvedUnit,
            error,
            (name) => const [],
          );

          var fixes = await DartFixContributor().computeFixes(context);
          fixes.sort(Fix.SORT_BY_RELEVANCE);

          result.add(
            CiderErrorFixes(error: error, fixes: fixes),
          );
        }
      }
    });

    return result;
  }
}
