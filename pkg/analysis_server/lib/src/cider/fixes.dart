// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

class CiderErrorFixes {
  final AnalysisError error;

  /// The fixes for the [error], might be empty.
  final List<Fix> fixes;

  final LineInfo lineInfo;

  CiderErrorFixes({
    required this.error,
    required this.fixes,
    required this.lineInfo,
  });
}

class CiderFixesComputer {
  final PerformanceLog _logger;
  final FileResolver _fileResolver;

  CiderFixesComputer(this._logger, this._fileResolver);

  /// Compute quick fixes for errors on the line with the [offset].
  Future<List<CiderErrorFixes>> compute(String path, int lineNumber) async {
    var result = <CiderErrorFixes>[];
    var resolvedUnit = _fileResolver.resolve(path: path);

    var lineInfo = resolvedUnit.lineInfo;

    await _logger.runAsync('Compute fixes', () async {
      for (var error in resolvedUnit.errors) {
        var errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == lineNumber) {
          var workspace = DartChangeWorkspace([resolvedUnit.session]);
          var context = _CiderDartFixContextImpl(
            _fileResolver,
            workspace,
            resolvedUnit,
            error,
          );

          var fixes = await DartFixContributor().computeFixes(context);
          fixes.sort(Fix.SORT_BY_RELEVANCE);

          result.add(
            CiderErrorFixes(error: error, fixes: fixes, lineInfo: lineInfo),
          );
        }
      }
    });

    return result;
  }
}

class _CiderDartFixContextImpl extends DartFixContextImpl {
  final FileResolver _fileResolver;

  _CiderDartFixContextImpl(
    this._fileResolver,
    ChangeWorkspace workspace,
    ResolvedUnitResult resolvedUnit,
    AnalysisError error,
  ) : super(InstrumentationService.NULL_SERVICE, workspace, resolvedUnit,
            error);

  @override
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(
    String name,
  ) async {
    var result = <LibraryElement, Element>{};
    var files = _fileResolver.getFilesWithTopLevelDeclarations(name);
    for (var file in files) {
      if (file.partOfLibrary == null) {
        var libraryElement = _fileResolver.getLibraryByUri(
          uriStr: file.uriStr,
        );
        TopLevelDeclarations.addElement(result, libraryElement, name);
      }
    }
    return result;
  }

  @override
  Stream<LibraryElement> librariesWithExtensions(String memberName) async* {}
}
