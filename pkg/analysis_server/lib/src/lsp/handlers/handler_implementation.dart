// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide TypeHierarchyItem, Element;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:collection/collection.dart';

class ImplementationHandler
    extends MessageHandler<TextDocumentPositionParams, List<Location>> {
  ImplementationHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_implementation;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<List<Location>>> handle(TextDocumentPositionParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }
    var performance = message.performance;
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await performance.runAsync(
      "requireResolvedUnit",
      (_) async => path.mapResult(requireResolvedUnit),
    );
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));
    return await performance.runAsync(
        "_getImplementations",
        (performance) async => offset.mapResult((offset) =>
            _getImplementations(unit.result, offset, token, performance)));
  }

  Future<ErrorOr<List<Location>>> _getImplementations(
      ResolvedUnitResult result,
      int offset,
      CancellationToken token,
      OperationPerformanceImpl performance) async {
    final node = NodeLocator(offset).searchWithin(result.unit);
    final element = server.getElementOfNode(node);
    if (element == null) {
      return success([]);
    }

    final helper = TypeHierarchyComputerHelper.fromElement(element);
    final interfaceElement = helper.pivotClass;
    if (interfaceElement == null) {
      return success([]);
    }
    final needsMember = helper.findMemberElement(interfaceElement) != null;

    var allSubtypes = <InterfaceElement>{};
    await performance.runAsync(
        "appendAllSubtypes",
        (performance) => server.searchEngine
            .appendAllSubtypes(interfaceElement, allSubtypes, performance));

    final locations = performance.run(
        "filter and get location",
        (_) => allSubtypes
            .map((element) {
              return needsMember
                  // Filter based on type, so when searching for members we don't
                  // include any intermediate classes that don't have
                  // implementations for the method.
                  ? helper.findMemberElement(element)?.nonSynthetic
                  : element;
            })
            .whereNotNull()
            .toSet()
            .map((element) {
              final unitElement =
                  element.thisOrAncestorOfType<CompilationUnitElement>();
              if (unitElement == null) {
                return null;
              }
              return Location(
                uri: Uri.file(unitElement.source.fullName),
                range: toRange(
                  unitElement.lineInfo,
                  element.nameOffset,
                  element.nameLength,
                ),
              );
            })
            .whereNotNull()
            .toList());

    return success(locations);
  }
}
