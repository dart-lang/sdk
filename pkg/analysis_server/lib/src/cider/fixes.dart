// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_processor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/services/top_level_declarations.dart';

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
    var resolvedUnit = await _fileResolver.resolve(path: path);

    var lineInfo = resolvedUnit.lineInfo;

    await _logger.runAsync('Compute fixes', () async {
      for (var error in resolvedUnit.errors) {
        var errorLine = lineInfo.getLocation(error.offset).lineNumber;
        if (errorLine == lineNumber) {
          var workspace = DartChangeWorkspace([resolvedUnit.session]);
          var context = _CiderDartFixContextImpl(
            _fileResolver,
            workspace: workspace,
            resolvedResult: resolvedUnit,
            error: error,
          );

          var fixes = await computeFixes(context);
          fixes.sort(Fix.compareFixes);

          result.add(
            CiderErrorFixes(error: error, fixes: fixes, lineInfo: lineInfo),
          );
        }
      }
    });

    return result;
  }
}

class _CiderDartFixContextImpl extends DartFixContext {
  final FileResolver _fileResolver;

  _CiderDartFixContextImpl(
    this._fileResolver, {
    required super.workspace,
    required super.resolvedResult,
    required super.error,
  }) : super(instrumentationService: InstrumentationService.NULL_SERVICE);

  @override
  Future<Map<LibraryElement, Element>> getTopLevelDeclarations(
    String name,
  ) async {
    var result = <LibraryElement, Element>{};
    var files = _fileResolver.getFilesWithTopLevelDeclarations(name);
    for (var file in files) {
      var kind = file.kind;
      if (kind is LibraryFileKind) {
        var libraryElement = await _fileResolver.getLibraryByUri2(
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
