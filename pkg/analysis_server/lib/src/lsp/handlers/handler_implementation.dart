// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart'
    hide TypeHierarchyItem, Element;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/search/type_hierarchy.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

typedef StaticOptions =
    Either3<bool, ImplementationOptions, ImplementationRegistrationOptions>;

class ImplementationHandler
    extends SharedMessageHandler<TextDocumentPositionParams, List<Location>> {
  ImplementationHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_implementation;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<List<Location>>> handle(
    TextDocumentPositionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }
    var performance = message.performance;
    var pos = params.position;
    var path = pathOfDoc(params.textDocument);
    var unit = await performance.runAsync(
      'requireResolvedUnit',
      (_) async => path.mapResult(requireResolvedUnit),
    );
    var offset = unit.mapResultSync((unit) => toOffset(unit.lineInfo, pos));
    return await performance.runAsync(
      '_getImplementations',
      (performance) async => (unit, offset).mapResults(
        (unit, offset) => _getImplementations(unit, offset, token, performance),
      ),
    );
  }

  Future<ErrorOr<List<Location>>> _getImplementations(
    ResolvedUnitResult result,
    int offset,
    CancellationToken token,
    OperationPerformanceImpl performance,
  ) async {
    var node = NodeLocator(offset).searchWithin(result.unit);
    var element = server.getElementOfNode2(node);
    if (element == null) {
      return success([]);
    }

    var helper = TypeHierarchyComputerHelper.fromElement(element);
    var interfaceElement = helper.pivotClass;
    if (interfaceElement == null) {
      return success([]);
    }
    var needsMember = helper.findMemberElement(interfaceElement) != null;

    var allSubtypes = <InterfaceElement2>{};
    await performance.runAsync(
      'appendAllSubtypes',
      (performance) => server.searchEngine.appendAllSubtypes2(
        interfaceElement,
        allSubtypes,
        performance,
      ),
    );

    var locations = performance.run(
      'filter and get location',
      (_) =>
          allSubtypes
              .map((element) {
                return needsMember
                    // Filter based on type, so when searching for members we don't
                    // include any intermediate classes that don't have
                    // implementations for the method.
                    ? helper.findMemberElement(element)?.nonSynthetic2
                    : element;
              })
              .nonNulls
              .toSet()
              .map((element) {
                var firstFragment = element.firstFragment;
                var libraryFragment = firstFragment.libraryFragment;
                if (libraryFragment == null) {
                  return null;
                }

                var nameOffset = firstFragment.nameOffset2;
                var name = firstFragment.name2;
                if (nameOffset == null || name == null) {
                  return null;
                }

                return Location(
                  uri: uriConverter.toClientUri(
                    libraryFragment.source.fullName,
                  ),
                  range: toRange(
                    libraryFragment.lineInfo,
                    nameOffset,
                    name.length,
                  ),
                );
              })
              .nonNulls
              .toList(),
    );

    return success(locations);
  }
}

class ImplementationRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  ImplementationRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_implementation;

  @override
  StaticOptions get staticOptions => Either3.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.implementation;
}
