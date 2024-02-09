// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
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

typedef StaticOptions = Either2<bool, ReferenceOptions>;

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
        '_getReferences',
        (performance) async => offset.mapResult((offset) => _getReferences(
            unit.result, offset, params, unit.result, performance)));
  }

  List<Location> _getDeclarations(ParsedUnitResult result, int offset) {
    final collector = NavigationCollectorImpl();
    computeDartNavigation(
        server.resourceProvider, collector, result, offset, 0);

    return convert(collector.targets, (NavigationTarget target) {
      final targetFilePath = collector.files[target.fileIndex];
      final targetFileUri = pathContext.toUri(targetFilePath);
      final lineInfo = server.getLineInfo(targetFilePath);
      return lineInfo != null
          ? navigationTargetToLocation(targetFileUri, target, lineInfo)
          : null;
    }).whereNotNull().toList();
  }

  Future<ErrorOr<List<Location>?>> _getReferences(
      ResolvedUnitResult result,
      int offset,
      ReferenceParams params,
      ResolvedUnitResult unit,
      OperationPerformanceImpl performance) async {
    var node = NodeLocator(offset).searchWithin(result.unit);
    node = _getReferenceTargetNode(node);
    var element = server.getElementOfNode(node);
    if (element == null) {
      return success(null);
    }

    final computer = ElementReferencesComputer(server.searchEngine);
    final session = element.session ?? unit.session;
    final results = await performance.runAsync(
        'computer.compute',
        (childPerformance) =>
            computer.compute(element, false, performance: childPerformance));

    Location? toLocation(SearchMatch result) {
      final file = session.getFile(result.file);
      if (file is! FileResult) {
        return null;
      }
      return Location(
        uri: pathContext.toUri(result.file),
        range: toRange(
          file.lineInfo,
          result.sourceRange.offset,
          result.sourceRange.length,
        ),
      );
    }

    final referenceResults = performance.run(
        'convert', (_) => convert(results, toLocation).whereNotNull().toList());

    if (params.context.includeDeclaration == true) {
      // Also include the definition for the symbol at this location.
      referenceResults.addAll(performance.run(
          '_getDeclarations', (_) => _getDeclarations(unit, offset)));
    }

    return success(referenceResults);
  }

  /// Gets the nearest node that should be used for finding references.
  ///
  /// This is usually the same node but allows some adjustments such as
  /// considering the offset between a type name and type arguments as part
  /// of the type.
  AstNode? _getReferenceTargetNode(AstNode? node) {
    // Consider the angle brackets for type arguments part of the leading type,
    // otherwise we don't navigate in the common situation of having the type
    // name selected, where VS Code provides the end of the selection as the
    // position to search.
    //
    // In `A^<String>` node will be `TypeParameterList` and we will not find any
    // references.
    if (node is TypeParameterList) {
      node = node.parent;
    }

    return node;
  }
}

class ReferencesRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  ReferencesRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_references;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.references;
}
