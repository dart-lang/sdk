// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Declaration;
import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/completion_utils.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
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
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A record of a [CompletionItem] and a fuzzy score.
typedef _ScoredCompletionItem = ({CompletionItem item, double score});

class CompletionHandler
    extends LspMessageHandler<CompletionParams, CompletionList>
    with LspPluginRequestHandlerMixin {
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
            server.initializationOptions?.suggestFromUnimportedLibraries ??
                true {
    var budgetMs = server.initializationOptions?.completionBudgetMilliseconds;
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
  Future<ErrorOr<CompletionList>> handle(
    CompletionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var clientCapabilities = message.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    // Cancel any existing in-progress completion request in case the client did
    // not do it explicitly, because the results will not be useful and it may
    // delay processing this one.
    previousRequestCancellationToken?.cancel(
      reason: 'Another textDocument/completion request was started',
    );
    previousRequestCancellationToken = token.asCancelable();

    var requestLatency = message.timeSinceRequest;
    var triggerCharacter = params.context?.triggerCharacter;
    var pos = params.position;
    var path = pathOfDoc(params.textDocument);

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
        (error) => path.mapResultSync(getLineInfo),
        (unit) => success(unit.lineInfo),
      );
    });

    if (delayAfterResolveForTests != null) {
      await delayAfterResolveForTests;
    }
    if (token.isCancellationRequested) {
      return cancelled(token);
    }

    // Map the offset, propagating the previous failure if we didn't have a
    // valid LineInfo.
    var offset = lineInfo.mapResultSync((lineInfo) => toOffset(lineInfo, pos));

    return await (path, lineInfo, offset).mapResults((
      path,
      lineInfo,
      offset,
    ) async {
      var fileExtension = pathContext.extension(path);
      var maxResults =
          server.lspClientConfiguration.forResource(path).maxCompletionItems;
      CompletionPerformance? completionPerformance;
      Future<ErrorOr<_CompletionResults>>? serverResultsFuture;
      if (fileExtension == '.dart') {
        unit.ifResult((unit) {
          var performance = message.performance;
          serverResultsFuture = performance.runAsync('request', (
            performance,
          ) async {
            var thisPerformance = CompletionPerformance(
              performance: performance,
              path: unit.path,
              requestLatency: requestLatency,
              content: unit.content,
              offset: offset,
            );
            completionPerformance = thisPerformance;
            server.recentPerformance.completion.add(thisPerformance);

            // `await` required for `performance.runAsync` to count time.
            return await _getServerDartItems(
              clientCapabilities,
              unit,
              thisPerformance,
              performance,
              offset,
              triggerCharacter,
              token,
              maxResults,
            );
          });
        });
      } else if (fileExtension == '.yaml') {
        YamlCompletionGenerator? generator;
        if (file_paths.isAnalysisOptionsYaml(pathContext, path)) {
          generator = AnalysisOptionsGenerator(server.resourceProvider);
        } else if (file_paths.isFixDataYaml(pathContext, path)) {
          generator = FixDataGenerator(server.resourceProvider);
        } else if (file_paths.isPubspecYaml(pathContext, path)) {
          generator = PubspecGenerator(
            server.resourceProvider,
            server.pubPackageService,
          );
        }
        if (generator != null) {
          serverResultsFuture = _getServerYamlItems(
            generator,
            clientCapabilities,
            path,
            lineInfo,
            offset,
            token,
          );
        }
      }

      var serverResults =
          (await serverResultsFuture) ?? success(_CompletionResults.empty());

      return serverResults.mapResultSync((serverResults) {
        var untruncatedRankedItems = serverResults.rankedItems.toList();
        var unrankedItems = serverResults.unrankedItems;

        // Truncate ranked items allowing for all unranked items.
        var maxRankedItems = math.max(maxResults - unrankedItems.length, 0);
        var truncatedRankedItems =
            untruncatedRankedItems.length <= maxRankedItems
                ? untruncatedRankedItems
                : _truncateResults(
                    untruncatedRankedItems,
                    serverResults.targetPrefix,
                    maxRankedItems,
                  );

        var truncatedItems = truncatedRankedItems
            .map((item) => item.item)
            .followedBy(unrankedItems)
            .toList();

        // If we're tracing performance (only Dart), record the number of results
        // after truncation.
        completionPerformance?.transmittedSuggestionCount =
            truncatedItems.length;

        return success(
          CompletionList(
            // If any set of the results is incomplete, the whole batch must be
            // marked as such.
            isIncomplete: serverResults.isIncomplete ||
                truncatedRankedItems.length != untruncatedRankedItems.length,
            items: truncatedItems,
            itemDefaults: serverResults.defaults,
          ),
        );
      });
    });
  }

  /// Computes all supported defaults for completion items based on
  /// [capabilities].
  CompletionItemDefaults? _computeCompletionDefaults(
    LspClientCapabilities capabilities,
    Range insertionRange,
    Range replacementRange,
  ) {
    // None of the items we use are set.
    if (!capabilities.completionDefaultEditRange &&
        !capabilities.completionDefaultTextMode) {
      return null;
    }

    return CompletionItemDefaults(
      insertTextMode:
          capabilities.completionDefaultTextMode ? InsertTextMode.asIs : null,
      editRange: _computeDefaultEditRange(
        capabilities,
        insertionRange,
        replacementRange,
      ),
    );
  }

  /// Computes the default completion edit range based on [capabilities] and
  /// whether the insert/replacement ranges differ.
  Either2<EditRangeWithInsertReplace, Range>? _computeDefaultEditRange(
    LspClientCapabilities capabilities,
    Range insertionRange,
    Range replacementRange,
  ) {
    if (!capabilities.completionDefaultEditRange) {
      return null;
    }

    if (!capabilities.insertReplaceCompletionRanges ||
        insertionRange == replacementRange) {
      return Either2<EditRangeWithInsertReplace, Range>.t2(replacementRange);
    } else {
      return Either2<EditRangeWithInsertReplace, Range>.t1(
        EditRangeWithInsertReplace(
          insert: insertionRange,
          replace: replacementRange,
        ),
      );
    }
  }

  /// The insert length is the shorter of the replacementLength or the
  /// difference between the replacementOffset and the caret position.
  int _computeInsertLength(
    int offset,
    int replacementOffset,
    int replacementLength,
  ) {
    var insertLength = math.min(offset - replacementOffset, replacementLength);
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
    CompletionItemDefaults? defaults,
  }) async {
    var request = DartSnippetRequest(unit: unit, offset: offset);
    var snippetManager = DartSnippetManager();
    var snippets = await snippetManager.computeSnippets(
      request,
      filter: filter,
    );

    return snippets.map(
      (snippet) => snippetToCompletionItem(
        server,
        clientCapabilities,
        unit.path,
        lineInfo,
        toPosition(lineInfo.getLocation(offset)),
        snippet,
        defaults,
      ),
    );
  }

  Future<ErrorOr<_CompletionResults>> _getServerDartItems(
    LspClientCapabilities capabilities,
    ResolvedUnitResult unit,
    CompletionPerformance completionPerformance,
    OperationPerformanceImpl performance,
    int offset,
    String? triggerCharacter,
    CancellationToken token,
    int maxSuggestions,
  ) async {
    var useNotImportedCompletions =
        suggestFromUnimportedLibraries && capabilities.applyEdit;

    var completionRequest = DartCompletionRequest.forResolvedUnit(
      resolvedUnit: unit,
      offset: offset,
      dartdocDirectiveInfo: server.getDartdocDirectiveInfoFor(unit),
      completionPreference: CompletionPreference.replace,
    );
    var target = completionRequest.target;
    var targetPrefix = completionRequest.targetPrefix;
    var fuzzy = _FuzzyScoreHelper(targetPrefix);

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
      var candidateSuggestions = await performance.runAsync(
        'computeSuggestions',
        (performance) async {
          var contributor = DartCompletionManager(
            budget: CompletionBudget(completionBudgetDuration),
            notImportedSuggestions: notImportedSuggestions,
          );

          var suggestions =
              await contributor.computeFinalizedCandidateSuggestions(
            request: completionRequest,
            performance: performance,
            maxSuggestions: maxSuggestions,
          );

          // Keep track of whether the set of results was truncated (because
          // budget was exhausted).
          isIncomplete =
              (contributor.notImportedSuggestions?.isIncomplete ?? false) ||
                  contributor.isTruncated;
          return suggestions;
        },
      );

      var replacementOffset = completionRequest.replacementOffset;
      var replacementLength = completionRequest.replacementLength;
      var insertLength = _computeInsertLength(
        offset,
        replacementOffset,
        replacementLength,
      );

      if (token.isCancellationRequested) {
        return cancelled(token);
      }

      /// completeFunctionCalls should be suppressed if the target is an
      /// invocation that already has an argument list, otherwise we would
      /// insert dupes.
      var completeFunctionCalls = _hasExistingArgList(target.entity)
          ? false
          : server.lspClientConfiguration.global.completeFunctionCalls;

      // Compute defaults that will allow us to reduce payload size.
      var defaultReplacementRange = toRange(
        unit.lineInfo,
        replacementOffset,
        replacementLength,
      );
      var defaultInsertionRange = toRange(
        unit.lineInfo,
        replacementOffset,
        insertLength,
      );
      var defaults = _computeCompletionDefaults(
        capabilities,
        defaultInsertionRange,
        defaultReplacementRange,
      );

      /// Helper to convert [CandidateSuggestion] to [CompletionItem].
      Future<CompletionItem?> candidateSuggestionToCompletionItem(
        CandidateSuggestion item,
      ) async {
        if (item is OverrideSuggestion) {
          item.data = await createOverrideSuggestionData(
            item,
            completionRequest,
          );
        }
        var itemReplacementOffset = completionRequest.replacementOffset;
        var itemReplacementLength = completionRequest.replacementLength;
        var itemInsertLength = insertLength;

        if (item is NamedArgumentSuggestion) {
          if (item.replacementLength != null) {
            itemReplacementLength = item.replacementLength!;
          }
          // Recompute the insert length if it may be affected by the above.
          itemInsertLength = _computeInsertLength(
            offset,
            itemReplacementOffset,
            itemInsertLength,
          );
        }

        // Convert to LSP ranges using the LineInfo.
        var replacementRange = toRange(
          unit.lineInfo,
          itemReplacementOffset,
          itemReplacementLength,
        );
        var insertionRange = toRange(
          unit.lineInfo,
          itemReplacementOffset,
          itemInsertLength,
        );

        // For items that need imports, we'll round-trip some additional info
        // to allow their additional edits (and documentation) to be handled
        // lazily to reduce the payload.
        CompletionItemResolutionInfo? resolutionInfo;

        if (item is ElementBasedSuggestion && item is ImportableSuggestion) {
          var elementLocation =
              (item as ElementBasedSuggestion).element.location;
          var importUri = item.importData?.libraryUri;

          if (importUri != null) {
            resolutionInfo = DartCompletionResolutionInfo(
              file: unit.path,
              importUris: [importUri.toString()],
              ref: elementLocation?.encoding,
            );
          }
        } else if (item is OverrideSuggestion) {
          var overrideData = item.data;
          if (overrideData != null && overrideData.imports.isNotEmpty) {
            var elementLocation =
                (item as ElementBasedSuggestion).element.location;
            var importUris = overrideData.imports;
            resolutionInfo = DartCompletionResolutionInfo(
              file: unit.path,
              importUris: importUris.map((uri) => uri.toString()).toList(),
              ref: elementLocation?.encoding,
            );
          }
        }

        return toLspCompletionItem(
          capabilities,
          unit.lineInfo,
          item,
          request: completionRequest,
          uriConverter: uriConverter,
          pathContext: pathContext,
          completionFilePath: unit.path,
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

      var rankedResults = await performance.run('mapSuggestions', (
        performance,
      ) async {
        var completionItems = <({CompletionItem item, double score})>[];
        for (var suggestion in candidateSuggestions.suggestions) {
          var item = await candidateSuggestionToCompletionItem(suggestion);
          if (item != null) {
            completionItems.add((item: item, score: suggestion.matcherScore));
          }
        }
        return completionItems;
      });

      // Add in any snippets.
      var snippetsEnabled =
          server.lspClientConfiguration.forResource(unit.path).enableSnippets;
      // We can only produce edits with edit builders for files inside
      // the root, so skip snippets entirely if not.
      var isEditableFile = unit.session.analysisContext.contextRoot.isAnalyzed(
        unit.path,
      );
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
          unrankedResults = await performance.runAsync('getSnippets', (
            performance,
          ) async {
            // TODO(dantup): Pass `fuzzy` into here so we can filter snippets
            //  before computing them to avoid looking up Element->Public Library
            //  if they won't be included.
            var snippets = await _getDartSnippetItems(
              clientCapabilities: capabilities,
              unit: unit,
              offset: offset,
              lineInfo: unit.lineInfo,
              filter: fuzzy.stringMatches,
              defaults: defaults,
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

      return success(
        _CompletionResults(
          isIncomplete: isIncomplete,
          fuzzy: fuzzy,
          rankedItems: rankedResults,
          unrankedItems: unrankedResults,
          defaults: defaults,
        ),
      );
    } on AbortCompletion {
      return success(_CompletionResults.emptyIncomplete());
    } on InconsistentAnalysisException {
      return success(_CompletionResults.emptyIncomplete());
    }
  }

  Future<ErrorOr<_CompletionResults>> _getServerYamlItems(
    YamlCompletionGenerator generator,
    LspClientCapabilities capabilities,
    String filePath,
    LineInfo lineInfo,
    int offset,
    CancellationToken token,
  ) async {
    var suggestions = generator.getSuggestions(filePath, offset);
    var insertLength = _computeInsertLength(
      offset,
      suggestions.replacementOffset,
      suggestions.replacementLength,
    );
    var replacementRange = toRange(
      lineInfo,
      suggestions.replacementOffset,
      suggestions.replacementLength,
    );
    var insertionRange = toRange(
      lineInfo,
      suggestions.replacementOffset,
      insertLength,
    );

    // Perform fuzzy matching based on the identifier in front of the caret to
    // reduce the size of the payload.
    var fuzzyPattern = suggestions.targetPrefix;
    var fuzzyMatcher = FuzzyMatcher(fuzzyPattern);

    var completionItems = suggestions.suggestions
        .where(
      (item) => fuzzyMatcher.score(item.displayText ?? item.completion) > 0,
    )
        .map((item) {
      var resolutionInfo = item.kind == CompletionSuggestionKind.PACKAGE_NAME
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
        uriConverter: uriConverter,
        pathContext: pathContext,
        completionFilePath: filePath,
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

  /// Checks whether the given [triggerCharacter] is valid for [target].
  ///
  /// Some trigger characters are only valid in certain locations, for example
  /// a single quote ' is valid to trigger completion after typing an import
  /// statement, but not when terminating a string. The client has no context
  /// and sends the requests unconditionally.
  bool _triggerCharacterValid(
    int offset,
    String triggerCharacter,
    CompletionTarget target,
  ) {
    var node = target.containingNode;

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

  /// Truncates [items] to [maxCompletionCount] after sorting by fuzzy score
  /// (then relevance/sortText) but always includes any items that exactly match
  /// [prefix].
  Iterable<_ScoredCompletionItem> _truncateResults(
    List<_ScoredCompletionItem> items,
    String prefix,
    int maxCompletionCount,
  ) {
    var prefixLower = prefix.toLowerCase();
    bool isExactMatch(CompletionItem item) =>
        (item.filterText ?? item.label).toLowerCase() == prefixLower;

    // Sort the items by fuzzy score and then relevance (sortText).
    items.sort(_scoreCompletionItemComparer);

    // Skip the text comparisons if we don't have a prefix (plugin results, or
    // just no prefix when completion was invoked).
    var shouldInclude = prefixLower.isEmpty
        ? (int index, _ScoredCompletionItem item) => index < maxCompletionCount
        : (int index, _ScoredCompletionItem item) =>
            index < maxCompletionCount || isExactMatch(item.item);

    return items.whereIndexed(shouldInclude);
  }

  /// Compares [_ScoredCompletionItem]s by their fuzzy match score and then
  /// `sortText` field (which is derived from relevance).
  ///
  /// For items with the same fuzzy score/relevance, shorter items are sorted
  /// first so that truncation always removes longer items first (which can be
  /// included by typing more of their characters).
  static int _scoreCompletionItemComparer(
    _ScoredCompletionItem item1,
    _ScoredCompletionItem item2,
  ) {
    // First try to sort by fuzzy score.
    if (item1.score != item2.score) {
      return item2.score.compareTo(item1.score);
    }

    // Otherwise, use sortText.
    // Note: It should never be the case that we produce items without sortText
    // but if they're null, fall back to label which is what the client would do
    // when sorting.
    var item1Text = item1.item.sortText ?? item1.item.label;
    var item2Text = item2.item.sortText ?? item2.item.label;

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
      return item1.item.label.length.compareTo(item2.item.label.length);
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
          documentSelector: dartFiles,
          triggerCharacters: dartCompletionTriggerCharacters,
          allCommitCharacters:
              previewCommitCharacters ? dartCompletionCommitCharacters : null,
          resolveProvider: true,
          completionItem: ServerCompletionItemOptions(
            labelDetailsSupport: true,
          ),
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
  List<TextDocumentFilterScheme> get nonDartCompletionTypes {
    var pluginTypesExcludingDart = pluginTypes.where(
      (filter) => filter.pattern != '**/*.dart',
    );

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
        completionItem: ServerCompletionItemOptions(labelDetailsSupport: true),
      );

  @override
  bool get supportsDynamic => clientDynamic.completion;
}

/// A set of completion items split into ranked and unranked items.
class _CompletionResults {
  /// Items that can be ranked using their relevance/sortText, returned with
  /// their fuzzy match (if [targetPrefix] was provided).
  final List<_ScoredCompletionItem> rankedItems;

  /// Items that cannot be ranked, and should avoid being truncated.
  final List<CompletionItem> unrankedItems;

  /// The fuzzy filter used to score results.
  final _FuzzyScoreHelper fuzzy;

  final bool isIncomplete;

  /// Item defaults for completion items.
  ///
  /// Defaults are only supported on Dart server items (not plugins).
  final CompletionItemDefaults? defaults;

  _CompletionResults({
    this.rankedItems = const [],
    this.unrankedItems = const [],
    required this.fuzzy,
    required this.isIncomplete,
    this.defaults,
  });

  _CompletionResults.empty()
      : this(fuzzy: _FuzzyScoreHelper.empty, isIncomplete: false);

  /// An empty result set marked as incomplete because an error occurred.
  _CompletionResults.emptyIncomplete()
      : this(fuzzy: _FuzzyScoreHelper.empty, isIncomplete: true);

  _CompletionResults.unranked(
    List<CompletionItem> unrankedItems, {
    required bool isIncomplete,
  }) : this(
          unrankedItems: unrankedItems,
          fuzzy: _FuzzyScoreHelper.empty,
          isIncomplete: isIncomplete,
        );

  /// Any prefix used to filter the results.
  String get targetPrefix => fuzzy.prefix;
}

/// Helper to simplify fuzzy scoring.
///
/// Used to sort results for truncation and to filter out items that don't
/// match the characters in front of the caret to reduce the size of the
/// payload.
class _FuzzyScoreHelper {
  static final empty = _FuzzyScoreHelper('');

  final String prefix;

  final FuzzyMatcher _matcher;

  _FuzzyScoreHelper(this.prefix) : _matcher = FuzzyMatcher(prefix);

  bool completionItemMatches(CompletionItem item) =>
      stringMatches(item.filterText ?? item.label);

  double completionItemScore(CompletionItem item) =>
      _matcher.score(item.filterText ?? item.label);

  bool stringMatches(String input) => _matcher.score(input) > 0;

  double suggestionScore(CompletionSuggestion item) =>
      _matcher.score(item.displayText ?? item.completion);
}
