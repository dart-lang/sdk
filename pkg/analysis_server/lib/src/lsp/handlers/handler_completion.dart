// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/// If the client does not provide capabilities.completion.completionItemKind.valueSet
/// then we must never send a kind that's not in this list.
final defaultSupportedCompletionKinds = HashSet<CompletionItemKind>.of([
  CompletionItemKind.Text,
  CompletionItemKind.Method,
  CompletionItemKind.Function,
  CompletionItemKind.Constructor,
  CompletionItemKind.Field,
  CompletionItemKind.Variable,
  CompletionItemKind.Class,
  CompletionItemKind.Interface,
  CompletionItemKind.Module,
  CompletionItemKind.Property,
  CompletionItemKind.Unit,
  CompletionItemKind.Value,
  CompletionItemKind.Enum,
  CompletionItemKind.Keyword,
  CompletionItemKind.Snippet,
  CompletionItemKind.Color,
  CompletionItemKind.File,
  CompletionItemKind.Reference,
]);

class CompletionHandler
    extends MessageHandler<CompletionParams, List<CompletionItem>>
    with LspPluginRequestHandlerMixin {
  final bool suggestFromUnimportedLibraries;
  CompletionHandler(
      LspAnalysisServer server, this.suggestFromUnimportedLibraries)
      : super(server);

  @override
  Method get handlesMessage => Method.textDocument_completion;

  @override
  LspJsonHandler<CompletionParams> get jsonHandler =>
      CompletionParams.jsonHandler;

  @override
  Future<ErrorOr<List<CompletionItem>>> handle(
      CompletionParams params, CancellationToken token) async {
    final completionCapabilities =
        server?.clientCapabilities?.textDocument?.completion;

    final clientSupportedCompletionKinds =
        completionCapabilities?.completionItemKind?.valueSet != null
            ? HashSet<CompletionItemKind>.of(
                completionCapabilities.completionItemKind.valueSet)
            : defaultSupportedCompletionKinds;

    final includeSuggestionSets = suggestFromUnimportedLibraries &&
        server?.clientCapabilities?.workspace?.applyEdit == true;

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);

    final lineInfo = unit.map<ErrorOr<LineInfo>>(
      // If we don't have a unit, we can still try to obtain the line info for
      // plugin contributors.
      (error) => path.mapResult(getLineInfo),
      (unit) => success(unit.lineInfo),
    );
    final offset =
        await lineInfo.mapResult((lineInfo) => toOffset(lineInfo, pos));

    return offset.mapResult((offset) async {
      // For server results we need a valid unit, but if we don't have one
      // we shouldn't consider this an error when merging with plugin results.
      final serverResultsFuture = unit.isError
          ? Future.value(success(const <CompletionItem>[]))
          : _getServerItems(
              completionCapabilities,
              clientSupportedCompletionKinds,
              includeSuggestionSets,
              unit.result,
              offset,
              token,
            );

      final pluginResultsFuture = _getPluginResults(completionCapabilities,
          clientSupportedCompletionKinds, lineInfo.result, path.result, offset);

      // Await both server + plugin results together to allow async/IO to
      // overlap.
      final serverAndPluginResults =
          await Future.wait([serverResultsFuture, pluginResultsFuture]);
      final serverResults = serverAndPluginResults[0];
      final pluginResults = serverAndPluginResults[1];

      if (serverResults.isError) return serverResults;
      if (pluginResults.isError) return pluginResults;

      return success(
        serverResults.result.followedBy(pluginResults.result).toList(),
      );
    });
  }

  /// Build a list of existing imports so we can filter out any suggestions
  /// that resolve to the same underlying declared symbol.
  /// Map with key "elementName/elementDeclaringLibraryUri"
  /// Value is a set of imported URIs that import that element.
  Map<String, Set<String>> _buildLookupOfImportedSymbols(
      ResolvedUnitResult unit) {
    final alreadyImportedSymbols = <String, Set<String>>{};
    final importElementList = unit.libraryElement.imports;
    for (var import in importElementList) {
      final importedLibrary = import.importedLibrary;
      if (importedLibrary == null) continue;

      for (var element in import.namespace.definedNames.values) {
        if (element.librarySource != null) {
          final declaringLibraryUri = element.librarySource.uri;
          final elementName = element.name;

          final key =
              _createImportedSymbolKey(elementName, declaringLibraryUri);
          alreadyImportedSymbols.putIfAbsent(key, () => <String>{});
          alreadyImportedSymbols[key]
              .add('${importedLibrary.librarySource.uri}');
        }
      }
    }
    return alreadyImportedSymbols;
  }

  String _createImportedSymbolKey(String name, Uri declaringUri) =>
      '$name/$declaringUri';

  Future<ErrorOr<List<CompletionItem>>> _getPluginResults(
    CompletionClientCapabilities completionCapabilities,
    HashSet<CompletionItemKind> clientSupportedCompletionKinds,
    LineInfo lineInfo,
    String path,
    int offset,
  ) async {
    final requestParams = plugin.CompletionGetSuggestionsParams(path, offset);
    final pluginResponses =
        await requestFromPlugins(path, requestParams, timeout: 100);

    final pluginResults = pluginResponses
        .map((e) => plugin.CompletionGetSuggestionsResult.fromResponse(e))
        .toList();

    return success(_pluginResultsToItems(
      completionCapabilities,
      clientSupportedCompletionKinds,
      lineInfo,
      pluginResults,
    ).toList());
  }

  Future<ErrorOr<List<CompletionItem>>> _getServerItems(
    CompletionClientCapabilities completionCapabilities,
    HashSet<CompletionItemKind> clientSupportedCompletionKinds,
    bool includeSuggestionSets,
    ResolvedUnitResult unit,
    int offset,
    CancellationToken token,
  ) async {
    final performance = CompletionPerformance();
    performance.path = unit.path;
    performance.setContentsAndOffset(unit.content, offset);
    server.performanceStats.completion.add(performance);

    return await performance.runRequestOperation((perf) async {
      final completionRequest = CompletionRequestImpl(
          unit, offset, server.options.useNewRelevance, performance);
      final directiveInfo =
          server.getDartdocDirectiveInfoFor(completionRequest.result);
      final dartCompletionRequest = await DartCompletionRequestImpl.from(
          perf, completionRequest, directiveInfo);

      Set<ElementKind> includedElementKinds;
      Set<String> includedElementNames;
      List<IncludedSuggestionRelevanceTag> includedSuggestionRelevanceTags;
      if (includeSuggestionSets) {
        includedElementKinds = <ElementKind>{};
        includedElementNames = <String>{};
        includedSuggestionRelevanceTags = <IncludedSuggestionRelevanceTag>[];
      }

      try {
        var contributor = DartCompletionManager(
          dartdocDirectiveInfo: directiveInfo,
          includedElementKinds: includedElementKinds,
          includedElementNames: includedElementNames,
          includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
        );

        final serverSuggestions = await contributor.computeSuggestions(
          perf,
          completionRequest,
          enableUriContributor: true,
        );

        if (token.isCancellationRequested) {
          return cancelled();
        }

        final results = serverSuggestions
            .map(
              (item) => toCompletionItem(
                completionCapabilities,
                clientSupportedCompletionKinds,
                unit.lineInfo,
                item,
                completionRequest.replacementOffset,
                completionRequest.replacementLength,
              ),
            )
            .toList();

        // Now compute items in suggestion sets.
        var includedSuggestionSets = <IncludedSuggestionSet>[];
        if (includedElementKinds != null && unit != null) {
          computeIncludedSetList(
            server.declarationsTracker,
            unit,
            includedSuggestionSets,
            includedElementNames,
          );
        }

        // Build a fast lookup for imported symbols so that we can filter out
        // duplicates.
        final alreadyImportedSymbols = _buildLookupOfImportedSymbols(unit);

        includedSuggestionSets.forEach((includedSet) {
          final library = server.declarationsTracker.getLibrary(includedSet.id);
          if (library == null) {
            return;
          }

          // Make a fast lookup for tag relevance.
          final tagBoosts = <String, int>{};
          includedSuggestionRelevanceTags
              .forEach((t) => tagBoosts[t.tag] = t.relevanceBoost);

          // Only specific types of child declarations should be included.
          // This list matches what's in _protocolAvailableSuggestion in
          // the DAS implementation.
          bool shouldIncludeChild(Declaration child) =>
              child.kind == DeclarationKind.CONSTRUCTOR ||
              child.kind == DeclarationKind.ENUM_CONSTANT ||
              (child.kind == DeclarationKind.GETTER && child.isStatic) ||
              (child.kind == DeclarationKind.FIELD && child.isStatic);

          // Collect declarations and their children.
          final allDeclarations = library.declarations
              .followedBy(library.declarations
                  .expand((decl) => decl.children.where(shouldIncludeChild)))
              .toList();

          final setResults = allDeclarations
              // Filter to only the kinds we should return.
              .where((item) =>
                  includedElementKinds.contains(protocolElementKind(item.kind)))
              .where((item) {
            // Check existing imports to ensure we don't already import
            // this element (this exact element from its declaring
            // library, not just something with the same name). If we do
            // we'll want to skip it.
            final declaringUri = item.parent != null
                ? item.parent.locationLibraryUri
                : item.locationLibraryUri;

            // For enums and named constructors, only the parent enum/class is in
            // the list of imported symbols so we use the parents name.
            final nameKey = item.kind == DeclarationKind.ENUM_CONSTANT ||
                    item.kind == DeclarationKind.CONSTRUCTOR
                ? item.parent.name
                : item.name;
            final key = _createImportedSymbolKey(nameKey, declaringUri);
            final importingUris = alreadyImportedSymbols[key];

            // Keep it only if there are either:
            // - no URIs importing it
            // - the URIs importing it include this one
            return importingUris == null ||
                importingUris.contains('${library.uri}');
          }).map((item) => declarationToCompletionItem(
                    completionCapabilities,
                    clientSupportedCompletionKinds,
                    unit.path,
                    offset,
                    includedSet,
                    library,
                    tagBoosts,
                    unit.lineInfo,
                    item,
                    completionRequest.replacementOffset,
                    completionRequest.replacementLength,
                  ));
          results.addAll(setResults);
        });

        // Perform fuzzy matching based on the identifier in front of the caret to
        // reduce the size of the payload.
        final fuzzyPattern = dartCompletionRequest.targetPrefix;
        final fuzzyMatcher =
            FuzzyMatcher(fuzzyPattern, matchStyle: MatchStyle.TEXT);

        final matchingResults =
            results.where((e) => fuzzyMatcher.score(e.label) > 0).toList();

        performance.suggestionCount = results.length;

        return success(matchingResults);
      } on AbortCompletion {
        return success([]);
      }
    });
  }

  Iterable<CompletionItem> _pluginResultsToItems(
    CompletionClientCapabilities completionCapabilities,
    HashSet<CompletionItemKind> clientSupportedCompletionKinds,
    LineInfo lineInfo,
    List<plugin.CompletionGetSuggestionsResult> pluginResults,
  ) {
    return pluginResults.expand((result) {
      return result.results.map(
        (item) => toCompletionItem(
          completionCapabilities,
          clientSupportedCompletionKinds,
          lineInfo,
          item,
          result.replacementOffset,
          result.replacementLength,
        ),
      );
    });
  }
}
