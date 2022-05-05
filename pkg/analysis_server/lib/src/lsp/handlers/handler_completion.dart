// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/fix_data_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:collection/collection.dart';

class CompletionHandler extends MessageHandler<CompletionParams, CompletionList>
    with LspPluginRequestHandlerMixin {
  /// Whether to include symbols from libraries that have not been imported.
  final bool suggestFromUnimportedLibraries;

  CompletionHandler(super.server, LspInitializationOptions options)
      : suggestFromUnimportedLibraries = options.suggestFromUnimportedLibraries;

  @override
  Method get handlesMessage => Method.textDocument_completion;

  @override
  LspJsonHandler<CompletionParams> get jsonHandler =>
      CompletionParams.jsonHandler;

  @override
  Future<ErrorOr<CompletionList>> handle(CompletionParams params,
      MessageInfo message, CancellationToken token) async {
    final clientCapabilities = server.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    final requestLatency = message.timeSinceRequest;
    final triggerCharacter = params.context?.triggerCharacter;
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);

    // IMPORTANT:
    // This handler is frequently called while the user is typing, which means
    // during any `await` there is a good chance of the file contents being
    // updated, but we must return results consistent with the file at the time
    // this request started so that the client can compensate for any typing
    // in the meantime.
    //
    // To do this, tell the server to lock requests until we have a resolved
    // unit and LineInfo.
    late ErrorOr<LineInfo> lineInfo;
    late ErrorOr<ResolvedUnitResult> unit;
    await server.lockRequestsWhile(() async {
      unit = await path.mapResult(requireResolvedUnit);
      lineInfo = await unit.map(
        // If we don't have a unit, we can still try to obtain the line info from
        // the server (this could be because the file is non-Dart, such as YAML or
        // another handled by a plugin).
        (error) => path.mapResult(getLineInfo),
        (unit) => success(unit.lineInfo),
      );
    });

    if (token.isCancellationRequested) {
      return cancelled();
    }

    // Map the offset, propagating the previous failure if we didn't have a
    // valid LineInfo.
    final offsetResult = !lineInfo.isError
        ? toOffset(lineInfo.result, pos)
        : failure<int>(lineInfo);

    if (offsetResult.isError) {
      return failure(offsetResult);
    }
    final offset = offsetResult.result;

    Future<ErrorOr<_CompletionResults>>? serverResultsFuture;
    final pathContext = server.resourceProvider.pathContext;
    final fileExtension = pathContext.extension(path.result);

    final maxResults =
        server.clientConfiguration.forResource(path.result).maxCompletionItems;

    CompletionPerformance? completionPerformance;
    if (fileExtension == '.dart' && !unit.isError) {
      final result = unit.result;
      var performance = OperationPerformanceImpl('<root>');
      serverResultsFuture = performance.runAsync(
        'request',
        (performance) async {
          final thisPerformance = CompletionPerformance(
            performance: performance,
            path: result.path,
            requestLatency: requestLatency,
            content: result.content,
            offset: offset,
          );
          completionPerformance = thisPerformance;
          server.recentPerformance.completion.add(thisPerformance);

          // `await` required for `performance.runAsync` to count time.
          return await _getServerDartItems(
            clientCapabilities,
            unit.result,
            thisPerformance,
            performance,
            offset,
            triggerCharacter,
            token,
          );
        },
      );
    } else if (fileExtension == '.yaml') {
      YamlCompletionGenerator? generator;
      if (file_paths.isAnalysisOptionsYaml(pathContext, path.result)) {
        generator = AnalysisOptionsGenerator(server.resourceProvider);
      } else if (file_paths.isFixDataYaml(pathContext, path.result)) {
        generator = FixDataGenerator(server.resourceProvider);
      } else if (file_paths.isPubspecYaml(pathContext, path.result)) {
        generator =
            PubspecGenerator(server.resourceProvider, server.pubPackageService);
      }
      if (generator != null) {
        serverResultsFuture = _getServerYamlItems(
          generator,
          clientCapabilities,
          path.result,
          lineInfo.result,
          offset,
          token,
        );
      }
    }

    serverResultsFuture ??= Future.value(success(_CompletionResults.empty()));

    final pluginResultsFuture = _getPluginResults(
        clientCapabilities, lineInfo.result, path.result, offset);

    final serverResults = await serverResultsFuture;
    final pluginResults = await pluginResultsFuture;

    if (serverResults.isError) return failure(serverResults);
    if (pluginResults.isError) return failure(pluginResults);

    final untruncatedRankedItems = serverResults.result.rankedItems
        .followedBy(pluginResults.result.items)
        .toList();
    final unrankedItems = serverResults.result.unrankedItems;

    // Truncate ranked items allowing for all unranked items.
    final maxRankedItems = math.max(maxResults - unrankedItems.length, 0);
    final truncatedRankedItems = untruncatedRankedItems.length <= maxRankedItems
        ? untruncatedRankedItems
        : _truncateResults(
            untruncatedRankedItems,
            serverResults.result.targetPrefix,
            maxRankedItems,
          );

    final truncatedItems =
        truncatedRankedItems.followedBy(unrankedItems).toList();

    // If we're tracing performance (only Dart), record the number of results
    // after truncation.
    completionPerformance?.transmittedSuggestionCount = truncatedItems.length;

    return success(CompletionList(
      // If any set of the results is incomplete, the whole batch must be
      // marked as such.
      isIncomplete: serverResults.result.isIncomplete ||
          pluginResults.result.isIncomplete ||
          truncatedRankedItems.length != untruncatedRankedItems.length,
      items: truncatedItems,
    ));
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
        final librarySource = element.librarySource;
        final elementName = element.name;
        if (librarySource != null && elementName != null) {
          final declaringLibraryUri = librarySource.uri;

          final key =
              _createImportedSymbolKey(elementName, declaringLibraryUri);
          alreadyImportedSymbols
              .putIfAbsent(key, () => <String>{})
              .add('${importedLibrary.librarySource.uri}');
        }
      }
    }
    return alreadyImportedSymbols;
  }

  /// The insert length is the shorter of the replacementLength or the
  /// difference between the replacementOffset and the caret position.
  int _computeInsertLength(
      int offset, int replacementOffset, int replacementLength) {
    final insertLength =
        math.min(offset - replacementOffset, replacementLength);
    assert(insertLength >= 0);
    assert(insertLength <= replacementLength);
    return insertLength;
  }

  String _createImportedSymbolKey(String name, Uri declaringUri) =>
      '$name/$declaringUri';

  Future<Iterable<CompletionItem>> _getDartSnippetItems({
    required LspClientCapabilities clientCapabilities,
    required ResolvedUnitResult unit,
    required int offset,
    required LineInfo lineInfo,
  }) async {
    final request = DartSnippetRequest(
      unit: unit,
      offset: offset,
    );
    final snippetManager = DartSnippetManager();
    final snippets = await snippetManager.computeSnippets(request);

    return snippets.map((snippet) => snippetToCompletionItem(
          server,
          clientCapabilities,
          unit.path,
          lineInfo,
          toPosition(lineInfo.getLocation(offset)),
          snippet,
        ));
  }

  Future<ErrorOr<CompletionList>> _getPluginResults(
    LspClientCapabilities capabilities,
    LineInfo lineInfo,
    String path,
    int offset,
  ) async {
    final requestParams = plugin.CompletionGetSuggestionsParams(path, offset);
    final pluginResponses = await requestFromPlugins(path, requestParams,
        timeout: const Duration(milliseconds: 100));

    final pluginResults = pluginResponses
        .map((e) => plugin.CompletionGetSuggestionsResult.fromResponse(e))
        .toList();

    return success(CompletionList(
      isIncomplete: false,
      items: _pluginResultsToItems(
        capabilities,
        lineInfo,
        offset,
        pluginResults,
      ).toList(),
    ));
  }

  Future<ErrorOr<_CompletionResults>> _getServerDartItems(
    LspClientCapabilities capabilities,
    ResolvedUnitResult unit,
    CompletionPerformance completionPerformance,
    OperationPerformanceImpl performance,
    int offset,
    String? triggerCharacter,
    CancellationToken token,
  ) async {
    final useSuggestionSets =
        suggestFromUnimportedLibraries && capabilities.applyEdit;

    final completionRequest = DartCompletionRequest.forResolvedUnit(
      resolvedUnit: unit,
      offset: offset,
      dartdocDirectiveInfo: server.getDartdocDirectiveInfoFor(unit),
      completionPreference: CompletionPreference.replace,
    );
    final target = completionRequest.target;
    final targetPrefix = completionRequest.targetPrefix;
    final fuzzy = _FuzzyFilterHelper(targetPrefix);

    if (triggerCharacter != null) {
      if (!_triggerCharacterValid(offset, triggerCharacter, target)) {
        return success(_CompletionResults.empty());
      }
    }

    Set<ElementKind>? includedElementKinds;
    Set<String>? includedElementNames;
    List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;
    if (useSuggestionSets) {
      includedElementKinds = <ElementKind>{};
      includedElementNames = <String>{};
      includedSuggestionRelevanceTags = <IncludedSuggestionRelevanceTag>[];
    }

    try {
      final serverSuggestions2 =
          await performance.runAsync('computeSuggestions', (performance) async {
        var contributor = DartCompletionManager(
          budget: CompletionBudget(CompletionBudget.defaultDuration),
          includedElementKinds: includedElementKinds,
          includedElementNames: includedElementNames,
          includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
        );

        // `await` required for `performance.runAsync` to count time.
        return await contributor.computeSuggestions(
          completionRequest,
          performance,
        );
      });

      final serverSuggestions =
          performance.run('buildSuggestions', (performance) {
        return serverSuggestions2
            .map((serverSuggestion) => serverSuggestion.build())
            .toList();
      });

      final insertLength = _computeInsertLength(
        offset,
        completionRequest.replacementOffset,
        completionRequest.replacementLength,
      );

      if (token.isCancellationRequested) {
        return cancelled();
      }

      /// completeFunctionCalls should be suppressed if the target is an
      /// invocation that already has an argument list, otherwise we would
      /// insert dupes.
      final completeFunctionCalls = _hasExistingArgList(target.entity)
          ? false
          : server.clientConfiguration.global.completeFunctionCalls;

      /// Helper to convert [CompletionSuggestions] to [CompletionItem].
      CompletionItem suggestionToCompletionItem(CompletionSuggestion item) {
        var itemReplacementOffset =
            item.replacementOffset ?? completionRequest.replacementOffset;
        var itemReplacementLength =
            item.replacementLength ?? completionRequest.replacementLength;
        var itemInsertLength = insertLength;

        // Recompute the insert length if it may be affected by the above.
        if (item.replacementOffset != null || item.replacementLength != null) {
          itemInsertLength = _computeInsertLength(
              offset, itemReplacementOffset, itemInsertLength);
        }

        // Convert to LSP ranges using the LineInfo.
        Range? replacementRange = toRange(
            unit.lineInfo, itemReplacementOffset, itemReplacementLength);
        Range? insertionRange =
            toRange(unit.lineInfo, itemReplacementOffset, itemInsertLength);

        return toCompletionItem(
          capabilities,
          unit.lineInfo,
          item,
          replacementRange: replacementRange,
          insertionRange: insertionRange,
          // TODO(dantup): Move commit characters to the main response
          // and remove from each individual item (to reduce payload size)
          // once the following change ships (and the Dart VS Code
          // extension is updated to use it).
          // https://github.com/microsoft/vscode-languageserver-node/issues/673
          includeCommitCharacters:
              server.clientConfiguration.global.previewCommitCharacters,
          completeFunctionCalls: completeFunctionCalls,
        );
      }

      final rankedResults = performance.run('mapSuggestions', (performance) {
        return serverSuggestions
            .where(fuzzy.completionSuggestionMatches)
            .map(suggestionToCompletionItem)
            .toList();
      });

      // Now compute items in suggestion sets.
      var includedSuggestionSets = <IncludedSuggestionSet>[];
      final declarationsTracker = server.declarationsTracker;
      if (declarationsTracker != null &&
          includedElementKinds != null &&
          includedElementNames != null &&
          includedSuggestionRelevanceTags != null) {
        performance.run('computeIncludedSetList', (performance) {
          // Checked in `if` above.
          includedElementNames!;

          computeIncludedSetList(
            declarationsTracker,
            completionRequest,
            includedSuggestionSets,
            includedElementNames,
          );
        });

        // Build a fast lookup for imported symbols so that we can filter out
        // duplicates.
        final alreadyImportedSymbols =
            performance.run('_buildLookupOfImportedSymbols', (performance) {
          return _buildLookupOfImportedSymbols(unit);
        });

        /// Helper to check existing imports to ensure we don't already import
        /// this element (this exact element from its declaring
        /// library, not just something with the same name). If we do
        /// we'll want to skip it.
        bool isNotImportedOrLibraryIsFirst(Declaration item, Library library) {
          final declaringUri =
              item.parent?.locationLibraryUri ?? item.locationLibraryUri!;

          // For enums and named constructors, only the parent enum/class is in
          // the list of imported symbols so we use the parents name.
          final nameKey = item.kind == DeclarationKind.ENUM_CONSTANT ||
                  item.kind == DeclarationKind.CONSTRUCTOR
              ? item.parent!.name
              : item.name;
          final key = _createImportedSymbolKey(nameKey, declaringUri);
          final importingUris = alreadyImportedSymbols[key];

          // Keep it only if:
          // - no existing imports include it
          //     (in which case all libraries will be offered as
          //     auto-imports)
          // - this is the first imported URI that includes it
          //     (we don't want to repeat it for each imported library that
          //     includes it)
          return importingUris == null ||
              importingUris.first == '${library.uri}';
        }

        /// Helper to filter to only the kinds we should return.
        bool shouldIncludeKind(Declaration item) =>
            includedElementKinds!.contains(protocolElementKind(item.kind));

        // Only specific types of child declarations should be included.
        // This list matches what's in _protocolAvailableSuggestion in
        // the DAS implementation.
        bool shouldIncludeChild(Declaration child) =>
            child.kind == DeclarationKind.CONSTRUCTOR ||
            child.kind == DeclarationKind.ENUM_CONSTANT;

        performance.run('addIncludedSuggestionSets', (performance) {
          // Checked in `if` above.
          includedSuggestionRelevanceTags!;

          // Make a fast lookup for tag relevance.
          final tagBoosts = <String, int>{};
          for (final t in includedSuggestionRelevanceTags) {
            tagBoosts[t.tag] = t.relevanceBoost;
          }

          for (final includedSet in includedSuggestionSets) {
            final library = declarationsTracker.getLibrary(includedSet.id);
            if (library == null) {
              break;
            }

            // Collect declarations and their children.
            final setResults = library.declarations
                .followedBy(library.declarations
                    .expand((decl) => decl.children.where(shouldIncludeChild)))
                .where(fuzzy.declarationMatches)
                .where(shouldIncludeKind)
                .where((Declaration item) =>
                    isNotImportedOrLibraryIsFirst(item, library))
                .map((item) => declarationToCompletionItem(
                      capabilities,
                      unit.path,
                      offset,
                      includedSet,
                      library,
                      tagBoosts,
                      unit.lineInfo,
                      item,
                      completionRequest.replacementOffset,
                      insertLength,
                      completionRequest.replacementLength,
                      // TODO(dantup): Move commit characters to the main response
                      // and remove from each individual item (to reduce payload size)
                      // once the following change ships (and the Dart VS Code
                      // extension is updated to use it).
                      // https://github.com/microsoft/vscode-languageserver-node/issues/673
                      includeCommitCharacters: server
                          .clientConfiguration.global.previewCommitCharacters,
                      completeFunctionCalls: completeFunctionCalls,
                    ));
            rankedResults.addAll(setResults);
          }
        });
      }

      // Add in any snippets.
      final snippetsEnabled =
          server.clientConfiguration.forResource(unit.path).enableSnippets;
      // We can only produce edits with edit builders for files inside
      // the root, so skip snippets entirely if not.
      final isEditableFile =
          unit.session.analysisContext.contextRoot.isAnalyzed(unit.path);
      List<CompletionItem> unrankedResults;
      if (capabilities.completionSnippets &&
          snippetsEnabled &&
          isEditableFile) {
        unrankedResults =
            await performance.runAsync('getSnippets', (performance) async {
          final snippets = await _getDartSnippetItems(
            clientCapabilities: capabilities,
            unit: unit,
            offset: offset,
            lineInfo: unit.lineInfo,
          );
          return snippets.where(fuzzy.completionItemMatches).toList();
        });
      } else {
        unrankedResults = [];
      }

      // transmittedCount will be set after combining with plugins + truncation.
      completionPerformance.computedSuggestionCount =
          rankedResults.length + unrankedResults.length;

      return success(_CompletionResults(
          isIncomplete: false,
          targetPrefix: targetPrefix,
          rankedItems: rankedResults,
          unrankedItems: unrankedResults));
    } on AbortCompletion {
      return success(_CompletionResults.empty());
    } on InconsistentAnalysisException {
      return success(_CompletionResults.empty());
    }
  }

  Future<ErrorOr<_CompletionResults>> _getServerYamlItems(
    YamlCompletionGenerator generator,
    LspClientCapabilities capabilities,
    String path,
    LineInfo lineInfo,
    int offset,
    CancellationToken token,
  ) async {
    final suggestions = generator.getSuggestions(path, offset);
    final insertLength = _computeInsertLength(
      offset,
      suggestions.replacementOffset,
      suggestions.replacementLength,
    );
    final replacementRange = toRange(
        lineInfo, suggestions.replacementOffset, suggestions.replacementLength);
    final insertionRange =
        toRange(lineInfo, suggestions.replacementOffset, insertLength);

    // Perform fuzzy matching based on the identifier in front of the caret to
    // reduce the size of the payload.
    final fuzzyPattern = suggestions.targetPrefix;
    final fuzzyMatcher =
        FuzzyMatcher(fuzzyPattern, matchStyle: MatchStyle.TEXT);

    final completionItems = suggestions.suggestions
        .where((item) =>
            fuzzyMatcher.score(item.displayText ?? item.completion) > 0)
        .map(
          (item) => toCompletionItem(
            capabilities,
            lineInfo,
            item,
            replacementRange: replacementRange,
            insertionRange: insertionRange,
            includeCommitCharacters: false,
            completeFunctionCalls: false,
            // Add on any completion-kind-specific resolution data that will be
            // used during resolve() calls to provide additional information.
            resolutionData: item.kind == CompletionSuggestionKind.PACKAGE_NAME
                ? PubPackageCompletionItemResolutionInfo(
                    // The completion for package names may contain a trailing
                    // ': ' for convenience, so if it's there, trim it off.
                    packageName: item.completion.split(':').first,
                  )
                : null,
          ),
        )
        .toList();
    return success(
      _CompletionResults.unranked(completionItems, isIncomplete: false),
    );
  }

  /// Returns true if [node] is part of an invocation and already has an argument
  /// list.
  bool _hasExistingArgList(Object? node) {
    // print^('foo');
    if (node is ast.ExpressionStatement) {
      node = node.expression;
    }
    // super.foo^();
    if (node is ast.SimpleIdentifier) {
      node = node.parent;
    }
    // new Aaaa.bar^()
    if (node is ast.ConstructorName) {
      node = node.parent;
    }
    return (node is ast.InvocationExpression &&
            !node.argumentList.beginToken.isSynthetic) ||
        (node is ast.InstanceCreationExpression &&
            !node.argumentList.beginToken.isSynthetic) ||
        // "ClassName.^()" will appear as accessing a property named '('.
        (node is ast.PropertyAccess && node.propertyName.name.startsWith('('));
  }

  Iterable<CompletionItem> _pluginResultsToItems(
    LspClientCapabilities capabilities,
    LineInfo lineInfo,
    int offset,
    List<plugin.CompletionGetSuggestionsResult> pluginResults,
  ) {
    return pluginResults.expand((result) {
      final insertLength = _computeInsertLength(
        offset,
        result.replacementOffset,
        result.replacementLength,
      );
      final replacementRange =
          toRange(lineInfo, result.replacementOffset, result.replacementLength);
      final insertionRange =
          toRange(lineInfo, result.replacementOffset, insertLength);

      return result.results.map(
        (item) => toCompletionItem(
          capabilities,
          lineInfo,
          item,
          replacementRange: replacementRange,
          insertionRange: insertionRange,
          // Plugins cannot currently contribute commit characters and we should
          // not assume that the Dart ones would be correct for all of their
          // completions.
          includeCommitCharacters: false,
          completeFunctionCalls: false,
        ),
      );
    });
  }

  /// Checks whether the given [triggerCharacter] is valid for [target].
  ///
  /// Some trigger characters are only valid in certain locations, for example
  /// a single quote ' is valid to trigger completion after typing an import
  /// statement, but not when terminating a string. The client has no context
  /// and sends the requests unconditionally.
  bool _triggerCharacterValid(
      int offset, String triggerCharacter, CompletionTarget target) {
    final node = target.containingNode;

    switch (triggerCharacter) {
      // For quotes, it's only valid if we're right after the opening quote of a
      // directive.
      case '"':
      case "'":
        return node is ast.SimpleStringLiteral &&
            node.parent is ast.Directive &&
            offset == node.contentsOffset;
      // Braces only for starting interpolated expressions.
      case '{':
        return node is ast.InterpolationExpression &&
            node.expression.offset == offset;
      // Slashes only as path separators in directives.
      case '/':
        return node is ast.SimpleStringLiteral &&
            node.parent is ast.Directive &&
            offset >= node.contentsOffset &&
            offset <= node.contentsEnd;
    }

    return true; // Any other trigger character can be handled always.
  }

  /// Truncates [items] to [maxItems] but additionally includes any items that
  /// exactly match [prefix].
  Iterable<CompletionItem> _truncateResults(
    List<CompletionItem> items,
    String prefix,
    int maxItems,
  ) {
    // Take the top `maxRankedItem` plus any exact matches.
    final prefixLower = prefix.toLowerCase();
    bool isExactMatch(CompletionItem item) =>
        (item.filterText ?? item.label).toLowerCase() == prefixLower;

    // Sort the items by relevance using sortText.
    items.sort(sortTextComparer);

    // Skip the text comparisons if we don't have a prefix (plugin results, or
    // just no prefix when completion was invoked).
    final shouldInclude = prefixLower.isEmpty
        ? (int index, CompletionItem item) => index < maxItems
        : (int index, CompletionItem item) =>
            index < maxItems || isExactMatch(item);

    return items.whereIndexed(shouldInclude);
  }

  /// Compares [CompletionItem]s by the `sortText` field, which is derived from
  /// relevance.
  ///
  /// For items with the same relevance, shorter items are sorted first so that
  /// truncation always removes longer items first (which can be included by
  /// typing more of their characters).
  static int sortTextComparer(CompletionItem item1, CompletionItem item2) {
    // Note: It should never be the case that we produce items without sortText
    // but if they're null, fall back to label which is what the client would do
    // when sorting.
    final item1Text = item1.sortText ?? item1.label;
    final item2Text = item2.sortText ?? item2.label;

    // If both items have the same text, this means they had the same relevance.
    // In this case, sort by the length of the name ascending, so that shorter
    // items are first. This is because longer items can be obtained by typing
    // additional characters where shorter ones may not.
    //
    // For example, with:
    //   - String aaa1;
    //   - String aaa2;
    //   - ...
    //   - String aaa(N); // up to past the truncation amount
    //   - String aaa;    // declared last, same prefix
    //
    // Typing 'aaa' should not allow 'aaa' to be truncated before 'aaa1'.
    if (item1Text == item2Text) {
      return item1.label.length.compareTo(item2.label.length);
    }

    return item1Text.compareTo(item2Text);
  }
}

/// A set of completion items split into ranked and unranked items.
class _CompletionResults {
  /// Items that can be ranked using their relevance/sortText.
  final List<CompletionItem> rankedItems;

  /// Items that cannot be ranked, and should avoid being truncated.
  final List<CompletionItem> unrankedItems;

  /// Any prefixed used to filter the results.
  final String targetPrefix;

  final bool isIncomplete;

  _CompletionResults({
    this.rankedItems = const [],
    this.unrankedItems = const [],
    required this.targetPrefix,
    required this.isIncomplete,
  });

  _CompletionResults.empty() : this(targetPrefix: '', isIncomplete: false);

  _CompletionResults.unranked(
    List<CompletionItem> unrankedItems, {
    required bool isIncomplete,
  }) : this(
          unrankedItems: unrankedItems,
          targetPrefix: '',
          isIncomplete: isIncomplete,
        );
}

/// Helper to simplify fuzzy filtering.
///
/// Used to perform fuzzy matching based on the identifier in front of the caret to
/// reduce the size of the payload.
class _FuzzyFilterHelper {
  final FuzzyMatcher _matcher;

  _FuzzyFilterHelper(String prefix)
      : _matcher = FuzzyMatcher(prefix, matchStyle: MatchStyle.TEXT);

  bool completionItemMatches(CompletionItem item) =>
      _matcher.score(item.filterText ?? item.label) > 0;

  bool completionSuggestionMatches(CompletionSuggestion item) =>
      _matcher.score(item.displayText ?? item.completion) > 0;

  bool declarationMatches(Declaration item) =>
      _matcher.score(getDeclarationName(item)) > 0;
}
