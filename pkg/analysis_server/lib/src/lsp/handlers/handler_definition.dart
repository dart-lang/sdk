// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisGetNavigationParams;
import 'package:analysis_server/src/lsp/error_or.dart';
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
    var requestParams = plugin.AnalysisGetNavigationParams(path, offset, 0);
    var responses = await requestFromPlugins(path, requestParams);

    return responses
        .map((response) =>
            plugin.AnalysisGetNavigationResult.fromResponse(response))
        .map((result) => AnalysisNavigationParams(
            path, result.regions, result.targets, result.files))
        .toList();
  }

  Future<AnalysisNavigationParams> getServerResult(ResolvedUnitResult result,
      String path, bool supportsLocationLink, int offset) async {
    var collector = NavigationCollectorImpl();

    computeDartNavigation(
        server.resourceProvider, collector, result, offset, 0);
    if (supportsLocationLink) {
      await _updateTargetsWithCodeLocations(collector);
    }
    collector.createRegions();

    return AnalysisNavigationParams(
        path, collector.regions, collector.targets, collector.files);
  }

  @override
  Future<ErrorOr<TextDocumentDefinitionResult>> handle(
      TextDocumentPositionParams params,
      MessageInfo message,
      CancellationToken token) async {
    var clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    var supportsLocationLink = clientCapabilities.definitionLocationLink;

    var pos = params.position;
    var path = pathOfDoc(params.textDocument);

    return path.mapResult((path) async {
      // Always prefer a LineInfo from a resolved unit than server.getLineInfo.
      var resolvedUnit = (await requireResolvedUnit(path)).resultOrNull;
      var lineInfo = resolvedUnit?.lineInfo ?? server.getLineInfo(path);

      // If there is no lineInfo, the request cannot be translated from LSP line/col
      // to server offset/length.
      if (lineInfo == null) {
        return success(TextDocumentDefinitionResult.t2(const []));
      }

      var offset = toOffset(lineInfo, pos);

      return offset.mapResult((offset) async {
        var allResults = [
          if (resolvedUnit != null)
            await getServerResult(
                resolvedUnit, path, supportsLocationLink, offset),
          ...await getPluginResults(path, offset),
        ];

        var merger = ResultMerger();
        var mergedResults = merger.mergeNavigation(allResults);
        var mergedTargets = mergedResults?.targets ?? [];

        if (mergedResults == null) {
          return success(TextDocumentDefinitionResult.t2(const []));
        }

        // Convert and filter the results using the correct type of Location class
        // depending on the client capabilities.
        if (supportsLocationLink) {
          var convertedResults = convert(
            mergedTargets,
            (NavigationTarget target) =>
                _toLocationLink(mergedResults, lineInfo, target),
          ).nonNulls.toList();

          var results = _filterResults(
            convertedResults,
            params.textDocument.uri,
            pos.line,
            (LocationLink element) => element.targetUri,
            (LocationLink element) => element.targetSelectionRange,
          );

          return success(TextDocumentDefinitionResult.t2(results));
        } else {
          var convertedResults = convert(
            mergedTargets,
            (NavigationTarget target) => _toLocation(mergedResults, target),
          ).nonNulls.toList();

          var results = _filterResults(
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
    var otherResults = results
        .where((element) =>
            uriSelector(element) != sourceUri ||
            rangeSelector(element).start.line != sourceLineNumber)
        .toList();

    return otherResults.isNotEmpty ? otherResults : results;
  }

  /// Get the location of the code (excluding leading doc comments) for this element.
  Future<protocol.Location?> _getCodeLocation(Element element) async {
    Element? codeElement = element;
    // For synthetic getters created for fields, we need to access the associated
    // variable to get the codeOffset/codeLength.
    if (codeElement is PropertyAccessorElementImpl && codeElement.isSynthetic) {
      codeElement = codeElement.variable2!;
    }

    // For extension types, the primary constructor has a range that covers only
    // the parameters / representation type but we want the whole declaration
    // for the code range because otherwise previews will just show `(int a)`
    // which is not what the user expects.
    if (codeElement.enclosingElement3 case ExtensionTypeElement enclosingElement
        when enclosingElement.primaryConstructor == codeElement) {
      codeElement = enclosingElement;
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
    var declaration = await _parsedDeclaration(codeElement);
    var node = declaration?.node;

    if (node is VariableDeclaration) {
      // For variables, expand to the variable declaration list if this is the
      // only variable so that the target range can include keywords/type.
      // Don't do this when there are multiple becaues it may include other
      // variables in the range.
      var parent = node.parent;
      if (parent is VariableDeclarationList && parent.variables.length == 1) {
        node = node.parent;
      }
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
    var targetFilePath = mergedResults.files[target.fileIndex];
    var targetFileUri = uriConverter.toClientUri(targetFilePath);
    var targetLineInfo = server.getLineInfo(targetFilePath);
    return targetLineInfo != null
        ? navigationTargetToLocation(targetFileUri, target, targetLineInfo)
        : null;
  }

  LocationLink? _toLocationLink(AnalysisNavigationParams mergedResults,
      LineInfo sourceLineInfo, NavigationTarget target) {
    var region = mergedResults.regions.first;
    var targetFilePath = mergedResults.files[target.fileIndex];
    var targetFileUri = uriConverter.toClientUri(targetFilePath);
    var targetLineInfo = server.getLineInfo(targetFilePath);

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
