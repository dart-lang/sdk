// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/search/element_references.dart';
import 'package:analysis_server/src/services/search/search_engine.dart'
    show SearchMatch;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

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

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await path.mapResult(requireResolvedUnit);
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));
    return await message.performance.runAsync(
        '_getReferences',
        (performance) async => (unit, offset).mapResults((unit, offset) =>
            _getReferences(unit, offset, params, performance)));
  }

  List<Location> _getDeclarations(Element element) {
    element = element.nonSynthetic;
    var unitElement = element.thisOrAncestorOfType<CompilationUnitElement>();
    if (unitElement == null) {
      return [];
    }

    return [
      Location(
        uri: uriConverter.toClientUri(unitElement.source.fullName),
        range: toRange(
            unitElement.lineInfo, element.nameOffset, element.nameLength),
      )
    ];
  }

  Future<ErrorOr<List<Location>?>> _getReferences(
      ResolvedUnitResult result,
      int offset,
      ReferenceParams params,
      OperationPerformanceImpl performance) async {
    var node = NodeLocator(offset).searchWithin(result.unit);
    node = _getReferenceTargetNode(node);

    var element = switch (server.getElementOfNode(node)) {
      FieldFormalParameterElement(:var field?) => field,
      PropertyAccessorElement(:var variable2?) => variable2,
      (var element) => element,
    };

    if (element == null) {
      return success(null);
    }

    var computer = ElementReferencesComputer(server.searchEngine);
    var session = element.session ?? result.session;
    var results = await performance.runAsync(
        'computer.compute',
        (childPerformance) =>
            computer.compute(element, false, performance: childPerformance));

    Location? toLocation(SearchMatch result) {
      var file = session.getFile(result.file);
      if (file is! FileResult) {
        return null;
      }
      return Location(
        uri: uriConverter.toClientUri(result.file),
        range: toRange(
          file.lineInfo,
          result.sourceRange.offset,
          result.sourceRange.length,
        ),
      );
    }

    var referenceResults = performance.run(
        'convert', (_) => convert(results, toLocation).nonNulls.toList());

    if (params.context.includeDeclaration == true) {
      // Also include the definition for the resolved element.
      referenceResults.addAll(performance.run(
          '_getDeclarations', (_) => _getDeclarations(element)));
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
