// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisGetNavigationParams;
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/plugin/result_merger.dart';
import 'package:analysis_server/src/protocol_server.dart' show NavigationTarget;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/analyzer_converter.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation_dart.dart';
import 'package:collection/collection.dart';

typedef StaticOptions = Either2<bool, DefinitionOptions>;

class DefinitionHandler extends LspMessageHandler<TextDocumentPositionParams,
    TextDocumentDefinitionResult> with LspPluginRequestHandlerMixin {
  DefinitionHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_definition;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  Future<List<AnalysisNavigationParams>> getPluginResults(
    String path,
    int offset,
  ) async {
    // LSP requests must be converted to DAS-protocol requests for compatibility
    // with plugins.
    final requestParams = plugin.AnalysisGetNavigationParams(path, offset, 0);
    final responses = await requestFromPlugins(path, requestParams);

    return responses
        .map((response) =>
            plugin.AnalysisGetNavigationResult.fromResponse(response))
        .map((result) => AnalysisNavigationParams(
            path, result.regions, result.targets, result.files))
        .toList();
  }

  Future<AnalysisNavigationParams> getServerResult(
      bool supportsLocationLink, String path, int offset) async {
    final collector = NavigationCollectorImpl();

    final result = await server.getResolvedUnit(path);
    final unit = result?.unit;
    if (unit != null) {
      computeDartNavigation(
          server.resourceProvider, collector, unit, offset, 0);
      if (supportsLocationLink) {
        await _updateTargetsWithCodeLocations(collector);
      }
      collector.createRegions();
    }

    return AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  @override
  Future<ErrorOr<TextDocumentDefinitionResult>> handle(
      TextDocumentPositionParams params,
      MessageInfo message,
      CancellationToken token) async {
    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final supportsLocationLink = clientCapabilities.definitionLocationLink;

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      final lineInfo = server.getLineInfo(path);
      // If there is no lineInfo, the request cannot be translated from LSP line/col
      // to server offset/length.
      if (lineInfo == null) {
        return success(TextDocumentDefinitionResult.t2(const []));
      }

      final offset = toOffset(lineInfo, pos);

      return offset.mapResult((offset) async {
        final allResults = [
          await getServerResult(supportsLocationLink, path, offset),
          ...await getPluginResults(path, offset),
        ];

        final merger = ResultMerger();
        final mergedResults = merger.mergeNavigation(allResults);
        final mergedTargets = mergedResults?.targets ?? [];

        if (mergedResults == null) {
          return success(TextDocumentDefinitionResult.t2(const []));
        }

        // Convert and filter the results using the correct type of Location class
        // depending on the client capabilities.
        if (supportsLocationLink) {
          final convertedResults = convert(
            mergedTargets,
            (NavigationTarget target) =>
                _toLocationLink(mergedResults, lineInfo, target),
          ).whereNotNull().toList();

          final results = _filterResults(
            convertedResults,
            params.textDocument.uri,
            pos.line,
            (LocationLink element) => element.targetUri,
            (LocationLink element) => element.targetSelectionRange,
          );

          return success(TextDocumentDefinitionResult.t2(results));
        } else {
          final convertedResults = convert(
            mergedTargets,
            (NavigationTarget target) => _toLocation(mergedResults, target),
          ).whereNotNull().toList();

          final results = _filterResults(
            convertedResults,
            params.textDocument.uri,
            pos.line,
            (Location element) => element.uri,
            (Location element) => element.range,
          );

          return success(
            TextDocumentDefinitionResult.t1(Definition.t1(results)),
          );
        }
      });
    });
  }

  /// Helper that selects the correct results (filtering out at the same
  /// line/location) generically, handling either type of Location class.
  List<T> _filterResults<T>(
    List<T> results,
    Uri sourceUri,
    int sourceLineNumber,
    Uri Function(T) uriSelector,
    Range Function(T) rangeSelector,
  ) {
    // If we fetch navigation on a keyword like `var`, the results will include
    // both the definition and also the variable name. This will cause the editor
    // to show the user both options unnecessarily (the variable name is always
    // adjacent to the var keyword, so providing navigation to it is not useful).
    // To prevent this, filter the list to only those on different lines (or
    // different files).
    final otherResults = results
        .where((element) =>
            uriSelector(element) != sourceUri ||
            rangeSelector(element).start.line != sourceLineNumber)
        .toList();

    return otherResults.isNotEmpty ? otherResults : results;
  }

  /// Get the location of the code (excluding leading doc comments) for this element.
  Future<protocol.Location?> _getCodeLocation(Element element) async {
    var codeElement = element;
    // For synthetic getters created for fields, we need to access the associated
    // variable to get the codeOffset/codeLength.
    if (codeElement.isSynthetic && codeElement is PropertyAccessorElementImpl) {
      codeElement = codeElement.variable;
    }

    // Read the main codeOffset from the element. This may include doc comments
    // but will give the correct end position.
    int? codeOffset, codeLength;
    if (codeElement is ElementImpl) {
      codeOffset = codeElement.codeOffset;
      codeLength = codeElement.codeLength;
    }

    if (codeOffset == null || codeLength == null) {
      return null;
    }

    // Read the declaration so we can get the offset after the doc comments.
    // TODO(dantup): Skip this for parts (getParsedLibrary will throw), but find
    // a better solution.
    final declaration = await _parsedDeclaration(codeElement);
    var node = declaration?.node;
    if (node is VariableDeclaration) {
      node = node.parent;
    }
    if (node is AnnotatedNode) {
      var offsetAfterDocs = node.firstTokenAfterCommentAndMetadata.offset;

      // Reduce the length by the difference between the end of docs and the start.
      codeLength -= offsetAfterDocs - codeOffset;
      codeOffset = offsetAfterDocs;
    }

    return AnalyzerConverter()
        .locationFromElement(element, offset: codeOffset, length: codeLength);
  }

  Location? _toLocation(
      AnalysisNavigationParams mergedResults, NavigationTarget target) {
    final targetFilePath = mergedResults.files[target.fileIndex];
    final targetFileUri = pathContext.toUri(targetFilePath);
    final targetLineInfo = server.getLineInfo(targetFilePath);
    return targetLineInfo != null
        ? navigationTargetToLocation(targetFileUri, target, targetLineInfo)
        : null;
  }

  LocationLink? _toLocationLink(AnalysisNavigationParams mergedResults,
      LineInfo sourceLineInfo, NavigationTarget target) {
    final region = mergedResults.regions.first;
    final targetFilePath = mergedResults.files[target.fileIndex];
    final targetFileUri = pathContext.toUri(targetFilePath);
    final targetLineInfo = server.getLineInfo(targetFilePath);

    return targetLineInfo != null
        ? navigationTargetToLocationLink(
            region, sourceLineInfo, targetFileUri, target, targetLineInfo)
        : null;
  }

  Future<void> _updateTargetsWithCodeLocations(
    NavigationCollectorImpl collector,
  ) async {
    for (var targetToUpdate in collector.targetsToUpdate) {
      var codeLocation = await _getCodeLocation(targetToUpdate.element);
      if (codeLocation != null) {
        targetToUpdate.target
          ..codeOffset = codeLocation.offset
          ..codeLength = codeLocation.length;
      }
    }
  }

  static Future<ElementDeclarationResult?> _parsedDeclaration(
    Element element,
  ) async {
    var session = element.session;
    if (session == null) {
      return null;
    }

    var libraryPath = element.library?.source.fullName;
    if (libraryPath == null) {
      return null;
    }

    var parsedLibrary = session.getParsedLibrary(libraryPath);
    if (parsedLibrary is! ParsedLibraryResult) {
      return null;
    }

    return parsedLibrary.getElementDeclaration(element);
  }
}

class DefinitionRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  DefinitionRegistrations(super.info);

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_definition;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => clientDynamic.definition;
}
