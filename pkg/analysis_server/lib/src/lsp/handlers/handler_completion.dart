// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Declaration;
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/dart_completion_suggestion.dart';
import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/fix_data_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet_manager.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/fuzzy_matcher.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

class CompletionHandler
    extends LspMessageHandler<CompletionParams, CompletionList>
    with LspPluginRequestHandlerMixin, LspHandlerHelperMixin {
  /// A [Future] used by tests to allow inserting a delay between resolving
  /// the initial unit and the completion code running.
  @visibleForTesting
  static Future<void>? delayAfterResolveForTests;

  /// Whether to include symbols from libraries that have not been imported.
  final bool suggestFromUnimportedLibraries;

  /// The budget to use for [NotImportedContributor] computation.
  ///
  /// This is usually the default value, but can be overridden via
  /// initializationOptions (used for tests, but may also be useful for
  /// debugging).
  late final Duration completionBudgetDuration;

  /// A cancellation token for the previous completion request.
  ///
  /// A new completion request will cancel the previous request. We do not allow
  /// concurrent completion requests.
  ///
  /// `null` if there is no previous request. It the previous request has
  /// already completed, cancelling this token will not do anything.
  CancelableToken? previousRequestCancellationToken;

  CompletionHandler(super.server)
      : suggestFromUnimportedLibraries =
            server.initializationOptions.suggestFromUnimportedLibraries {
    final budgetMs = server.initializationOptions.completionBudgetMilliseconds;
    completionBudgetDuration = budgetMs != null
        ? Duration(milliseconds: budgetMs)
        : CompletionBudget.defaultDuration;
  }

  @override
  Method get handlesMessage => Method.textDocument_completion;

  @override
  LspJsonHandler<CompletionParams> get jsonHandler =>
      CompletionParams.jsonHandler;

  @override
  Future<ErrorOr<CompletionList>> handle(CompletionParams params,
      MessageInfo message, CancellationToken token) async {
    final clientCapabilities = server.lspClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    // Cancel any existing in-progress completion request in case the client did
    // not do it explicitly, because the results will not be useful and it may
    // delay processing this one.
    previousRequestCancellationToken?.cancel();
    previousRequestCancellationToken = token.asCancelable();

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

    if (delayAfterResolveForTests != null) {
      await delayAfterResolveForTests;
    }
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
    final fileExtension = pathContext.extension(path.result);

    final maxResults = server.lspClientConfiguration
        .forResource(path.result)
        .maxCompletionItems;

    CompletionPerformance? completionPerformance;
    if (fileExtension == '.dart' && !unit.isError) {
      final result = unit.result;
      var performance = message.performance;
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

    final serverResult = serverResults.result;
    final untruncatedRankedItems = serverResult.rankedItems
        .followedBy(pluginResults.result.items)
        .toList();
    final unrankedItems = serverResult.unrankedItems;

    // Truncate ranked items allowing for all unranked items.
    final maxRankedItems = math.max(maxResults - unrankedItems.length, 0);
    final truncatedRankedItems = untruncatedRankedItems.length <= maxRankedItems
        ? untruncatedRankedItems
        : _truncateResults(
            untruncatedRankedItems,
            serverResult.targetPrefix,
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
      isIncomplete: serverResult.isIncomplete ||
          pluginResults.result.isIncomplete ||
          truncatedRankedItems.length != untruncatedRankedItems.length,
      items: truncatedItems,
      itemDefaults: serverResult.defaults,
    ));
  }

  /// Computes all supported defaults for completion items based on
  /// [capabilities].
  CompletionListItemDefaults? _computeCompletionDefaults(
    LspClientCapabilities capabilities,
    Range insertionRange,
    Range replacementRange,
  ) {
    // None of the items we use are set.
    if (!capabilities.completionDefaultEditRange &&
        !capabilities.completionDefaultTextMode) {
      return null;
    }

    return CompletionListItemDefaults(
      insertTextMode:
          capabilities.completionDefaultTextMode ? InsertTextMode.asIs : null,
      editRange: _computeDefaultEditRange(
          capabilities, insertionRange, replacementRange),
    );
  }

  /// Computes the default completion edit range based on [capabilities] and
  /// whether the insert/replacement ranges differ.
  Either2<CompletionItemEditRange, Range>? _computeDefaultEditRange(
    LspClientCapabilities capabilities,
    Range insertionRange,
    Range replacementRange,
  ) {
    if (!capabilities.completionDefaultEditRange) {
      return null;
    }

    if (!capabilities.insertReplaceCompletionRanges ||
        insertionRange == replacementRange) {
      return Either2<CompletionItemEditRange, Range>.t2(replacementRange);
    } else {
      return Either2<CompletionItemEditRange, Range>.t1(
        CompletionItemEditRange(
          insert: insertionRange,
          replace: replacementRange,
        ),
      );
    }
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

  Future<Iterable<CompletionItem>> _getDartSnippetItems({
    required LspClientCapabilities clientCapabilities,
    required ResolvedUnitResult unit,
    required int offset,
    required LineInfo lineInfo,
    required bool Function(String input) filter,
  }) async {
    final request = DartSnippetRequest(
      unit: unit,
      offset: offset,
    );
    final snippetManager = DartSnippetManager();
    final snippets =
        await snippetManager.computeSnippets(request, filter: filter);

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
        path,
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
    final useNotImportedCompletions =
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

    NotImportedSuggestions? notImportedSuggestions;
    if (useNotImportedCompletions) {
      notImportedSuggestions = NotImportedSuggestions();
    }

    var isIncomplete = false;
    try {
      final serverSuggestions2 =
          await performance.runAsync('computeSuggestions', (performance) async {
        var contributor = DartCompletionManager(
          budget: CompletionBudget(completionBudgetDuration),
          notImportedSuggestions: notImportedSuggestions,
        );

        final suggestions = await contributor.computeSuggestions(
          completionRequest,
          performance,
          useFilter: true,
        );

        // Keep track of whether the set of results was truncated (because
        // budget was exhausted).
        isIncomplete =
            contributor.notImportedSuggestions?.isIncomplete ?? false;

        return suggestions;
      });

      final serverSuggestions =
          performance.run('buildSuggestions', (performance) {
        return serverSuggestions2
            .map((serverSuggestion) => serverSuggestion.build())
            .toList();
      });

      final replacementOffset = completionRequest.replacementOffset;
      final replacementLength = completionRequest.replacementLength;
      final insertLength = _computeInsertLength(
        offset,
        replacementOffset,
        replacementLength,
      );

      if (token.isCancellationRequested) {
        return cancelled();
      }

      /// completeFunctionCalls should be suppressed if the target is an
      /// invocation that already has an argument list, otherwise we would
      /// insert dupes.
      final completeFunctionCalls = _hasExistingArgList(target.entity)
          ? false
          : server.lspClientConfiguration.global.completeFunctionCalls;

      // Compute defaults that will allow us to reduce payload size.
      final defaultReplacementRange =
          toRange(unit.lineInfo, replacementOffset, replacementLength);
      final defaultInsertionRange =
          toRange(unit.lineInfo, replacementOffset, insertLength);
      final defaults = _computeCompletionDefaults(
          capabilities, defaultInsertionRange, defaultReplacementRange);

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
        final replacementRange = toRange(
            unit.lineInfo, itemReplacementOffset, itemReplacementLength);
        final insertionRange =
            toRange(unit.lineInfo, itemReplacementOffset, itemInsertLength);

        // For items that need imports, we'll round-trip some additional info
        // to allow their additional edits (and documentation) to be handled
        // lazily to reduce the payload.
        CompletionItemResolutionInfo? resolutionInfo;
        if (item is DartCompletionSuggestion) {
          final elementLocation = item.elementLocation;
          final importUris = item.requiredImports;

          if (importUris.isNotEmpty) {
            resolutionInfo = DartCompletionResolutionInfo(
              file: unit.path,
              importUris: importUris.map((uri) => uri.toString()).toList(),
              ref: elementLocation?.encoding,
            );
          }
        }

        return toCompletionItem(
          capabilities,
          unit.lineInfo,
          item,
          hasDefaultTextMode: defaults?.insertTextMode != null,
          hasDefaultEditRange: defaults?.editRange != null &&
              insertionRange == defaultInsertionRange &&
              replacementRange == defaultReplacementRange,
          replacementRange: replacementRange,
          insertionRange: insertionRange,
          commitCharactersEnabled:
              server.lspClientConfiguration.global.previewCommitCharacters,
          completeFunctionCalls: completeFunctionCalls,
          resolutionData: resolutionInfo,
          // Exclude docs if we will be providing them via
          // `completionItem/resolve`, otherwise use users preference.
          includeDocumentation: resolutionInfo != null
              ? DocumentationPreference.none
              : server.lspClientConfiguration.global.preferredDocumentation,
        );
      }

      final rankedResults = performance.run('mapSuggestions', (performance) {
        return serverSuggestions
            .where(fuzzy.completionSuggestionMatches)
            .map(suggestionToCompletionItem)
            .toList();
      });

      // Add in any snippets.
      final snippetsEnabled =
          server.lspClientConfiguration.forResource(unit.path).enableSnippets;
      // We can only produce edits with edit builders for files inside
      // the root, so skip snippets entirely if not.
      final isEditableFile =
          unit.session.analysisContext.contextRoot.isAnalyzed(unit.path);
      List<CompletionItem> unrankedResults;
      if (capabilities.completionSnippets &&
          snippetsEnabled &&
          isEditableFile) {
        // Snippets may need to obtain resolved units to produce edits in files.
        // If files have been modified since we started, these will throw but
        // we should not bring down the entire completion request, just exclude
        // the snippets and set isIncomplete=true.
        //
        // VS Code assumes we will continue to service a completion request
        // even when documents are modified (as the user is typing).
        try {
          unrankedResults =
              await performance.runAsync('getSnippets', (performance) async {
            // TODO(dantup): Pass `fuzzy` into here so we can filter snippets
            //  before computing them to avoid looking up Element->Public Library
            //  if they won't be included.
            final snippets = await _getDartSnippetItems(
              clientCapabilities: capabilities,
              unit: unit,
              offset: offset,
              lineInfo: unit.lineInfo,
              filter: fuzzy.stringMatches,
            );
            return snippets.where(fuzzy.completionItemMatches).toList();
          });
        } on AbortCompletion {
          isIncomplete = true;
          unrankedResults = [];
        } on InconsistentAnalysisException {
          isIncomplete = true;
          unrankedResults = [];
        }
      } else {
        unrankedResults = [];
      }

      // transmittedCount will be set after combining with plugins + truncation.
      completionPerformance.computedSuggestionCount =
          rankedResults.length + unrankedResults.length;

      return success(_CompletionResults(
        isIncomplete: isIncomplete,
        targetPrefix: targetPrefix,
        rankedItems: rankedResults,
        unrankedItems: unrankedResults,
        defaults: defaults,
      ));
    } on AbortCompletion {
      return success(_CompletionResults.emptyIncomplete());
    } on InconsistentAnalysisException {
      return success(_CompletionResults.emptyIncomplete());
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
        .map((item) {
      final resolutionInfo = item.kind == CompletionSuggestionKind.PACKAGE_NAME
          ? PubPackageCompletionItemResolutionInfo(
              // The completion for package names may contain a trailing
              // ': ' for convenience, so if it's there, trim it off.
              packageName: item.completion.split(':').first,
            )
          : null;
      return toCompletionItem(
        capabilities,
        lineInfo,
        item,
        replacementRange: replacementRange,
        insertionRange: insertionRange,
        commitCharactersEnabled: false,
        completeFunctionCalls: false,
        // Exclude docs if we could provide them via
        // `completionItem/resolve`, otherwise use users preference.
        includeDocumentation: resolutionInfo != null
            ? DocumentationPreference.none
            : server.lspClientConfiguration.global.preferredDocumentation,
        // Add on any completion-kind-specific resolution data that will be
        // used during resolve() calls to provide additional information.
        resolutionData: resolutionInfo,
      );
    }).toList();
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
    String path,
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

      return result.results.map((item) {
        final isNotImported = item.isNotImported ?? false;
        final importUri = item.libraryUri;

        DartCompletionResolutionInfo? resolutionInfo;
        if (isNotImported && importUri != null) {
          resolutionInfo = DartCompletionResolutionInfo(
            file: path,
            importUris: [importUri],
          );
        }

        return toCompletionItem(
          capabilities,
          lineInfo,
          item,
          replacementRange: replacementRange,
          insertionRange: insertionRange,
          includeDocumentation:
              server.lspClientConfiguration.global.preferredDocumentation,
          // Plugins cannot currently contribute commit characters and we should
          // not assume that the Dart ones would be correct for all of their
          // completions.
          commitCharactersEnabled: false,
          completeFunctionCalls: false,
          resolutionData: resolutionInfo,
        );
      });
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
      // Disallow colons automatically triggering for switch statements
      // (case, default).
      case ':':
        return node is! ast.SwitchStatement;
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

class CompletionRegistrations extends FeatureRegistration
    with StaticRegistration<CompletionOptions> {
  CompletionRegistrations(super.info);

  @override
  List<LspDynamicRegistration> get dynamicRegistrations {
    return [
      // Trigger and commit characters are specific to Dart, so register them
      // separately to the others.
      (
        Method.textDocument_completion,
        CompletionRegistrationOptions(
          documentSelector: [dartFiles],
          triggerCharacters: dartCompletionTriggerCharacters,
          allCommitCharacters:
              previewCommitCharacters ? dartCompletionCommitCharacters : null,
          resolveProvider: true,
        ),
      ),
      (
        Method.textDocument_completion,
        CompletionRegistrationOptions(
          documentSelector: nonDartCompletionTypes,
          resolveProvider: true,
        ),
      ),
    ];
  }

  /// Types of documents we support completion for that are not Dart.
  ///
  /// We use two dynamic registrations because for Dart we support trigger
  /// characters but for other kinds of files we do not.
  List<TextDocumentFilterWithScheme> get nonDartCompletionTypes {
    final pluginTypesExcludingDart =
        pluginTypes.where((filter) => filter.pattern != '**/*.dart');

    return {
      ...pluginTypesExcludingDart,
      pubspecFile,
      analysisOptionsFile,
      fixDataFile,
    }.toList();
  }

  bool get previewCommitCharacters =>
      clientConfiguration.global.previewCommitCharacters;

  @override
  CompletionOptions get staticOptions => CompletionOptions(
        triggerCharacters: dartCompletionTriggerCharacters,
        allCommitCharacters:
            previewCommitCharacters ? dartCompletionCommitCharacters : null,
        resolveProvider: true,
      );

  @override
  bool get supportsDynamic => clientDynamic.completion;
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

  /// Item defaults for completion items.
  ///
  /// Defaults are only supported on Dart server items (not plugins).
  final CompletionListItemDefaults? defaults;

  _CompletionResults({
    this.rankedItems = const [],
    this.unrankedItems = const [],
    required this.targetPrefix,
    required this.isIncomplete,
    this.defaults,
  });

  _CompletionResults.empty() : this(targetPrefix: '', isIncomplete: false);

  /// An empty result set marked as incomplete because an error occurred.
  _CompletionResults.emptyIncomplete()
      : this(targetPrefix: '', isIncomplete: true);

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
      stringMatches(item.filterText ?? item.label);

  bool completionSuggestionMatches(CompletionSuggestion item) =>
      stringMatches(item.displayText ?? item.completion);

  bool stringMatches(String input) => _matcher.score(input) > 0;
}
