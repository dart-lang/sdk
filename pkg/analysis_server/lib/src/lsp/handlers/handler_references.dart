// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' show NavigationTarget;
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    show SearchMatch;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation_dart.dart';
import 'package:collection/collection.dart';

class ReferencesHandler
    extends LspMessageHandler<ReferenceParams, List<Location>?> {
  ReferencesHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_references;

  @override
  LspJsonHandler<ReferenceParams> get jsonHandler =>
      ReferenceParams.jsonHandler;

  @override
  Future<ErrorOr<List<Location>?>> handle(ReferenceParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return await message.performance.runAsync(
        "_getReferences",
        (performance) async => offset.mapResult((offset) => _getReferences(
            unit.result, offset, params, unit.result, performance)));
  }

  List<Location> _getDeclarations(CompilationUnit unit, int offset) {
    final collector = NavigationCollectorImpl();
    computeDartNavigation(server.resourceProvider, collector, unit, offset, 0);

    return convert(collector.targets, (NavigationTarget target) {
      final targetFilePath = collector.files[target.fileIndex];
      final lineInfo = server.getLineInfo(targetFilePath);
      return lineInfo != null
          ? navigationTargetToLocation(targetFilePath, target, lineInfo)
          : null;
    }).whereNotNull().toList();
  }

  Future<ErrorOr<List<Location>?>> _getReferences(
      ResolvedUnitResult result,
      int offset,
      ReferenceParams params,
      ResolvedUnitResult unit,
      OperationPerformanceImpl performance) async {
    final node = NodeLocator(offset).searchWithin(result.unit);
    var element = server.getElementOfNode(node);
    if (element == null) {
      return success(null);
    }

    final computer = ElementReferencesComputer(server.searchEngine);
    final session = element.session ?? unit.session;
    final results = await performance.runAsync(
        "computer.compute",
        (childPerformance) =>
            computer.compute(element, false, performance: childPerformance));

    Location? toLocation(SearchMatch result) {
      final file = session.getFile(result.file);
      if (file is! FileResult) {
        return null;
      }
      return Location(
        uri: Uri.file(result.file),
        range: toRange(
          file.lineInfo,
          result.sourceRange.offset,
          result.sourceRange.length,
        ),
      );
    }

    final referenceResults = performance.run(
        "convert", (_) => convert(results, toLocation).whereNotNull().toList());

    final compilationUnit = unit.unit;
    if (params.context.includeDeclaration == true) {
      // Also include the definition for the symbol at this location.
      referenceResults.addAll(performance.run("_getDeclarations",
          (_) => _getDeclarations(compilationUnit, offset)));
    }

    return success(referenceResults);
  }
}
