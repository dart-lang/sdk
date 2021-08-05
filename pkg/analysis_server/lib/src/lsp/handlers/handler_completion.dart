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
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:analysis_server/src/services/completion/yaml/analysis_options_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/fix_data_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/pubspec_generator.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

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
    final clientCapabilities = server.clientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return error(ErrorCodes.ServerNotInitialized,
          'Requests not before server is initilized');
    }

    final includeSuggestionSets =
        suggestFromUnimportedLibraries && clientCapabilities.applyEdit;

    final triggerCharacter = params.context?.triggerCharacter;
    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);

    final lineInfo = await unit.map(
      // If we don't have a unit, we can still try to obtain the line info for
      // plugin contributors.
      (error) => path.mapResult(getLineInfo),
      (unit) => success(unit.lineInfo),
    );
    final offset =
        await lineInfo.mapResult((lineInfo) => toOffset(lineInfo, pos));

    return offset.mapResult((offset) async {
      Future<ErrorOr<List<CompletionItem>>>? serverResultsFuture;
      final pathContext = server.resourceProvider.pathContext;
      final fileExtension = pathContext.extension(path.result);

      if (fileExtension == '.dart' && !unit.isError) {
        serverResultsFuture = _getServerDartItems(
          clientCapabilities,
          includeSuggestionSets,
          unit.result,
          offset,
          triggerCharacter,
          token,
        );
      } else if (fileExtension == '.yaml') {
        YamlCompletionGenerator? generator;
        if (file_paths.isAnalysisOptionsYaml(pathContext, path.result)) {
          generator = AnalysisOptionsGenerator(server.resourceProvider);
        } else if (file_paths.isFixDataYaml(pathContext, path.result)) {
          generator = FixDataGenerator(server.resourceProvider);
        } else if (file_paths.isPubspecYaml(pathContext, path.result)) {
          generator = PubspecGenerator(
              server.resourceProvider, server.pubPackageService);
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

      serverResultsFuture ??= Future.value(success(const <CompletionItem>[]));

      final pluginResultsFuture = _getPluginResults(
          clientCapabilities, lineInfo.result, path.result, offset);

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

  Future<ErrorOr<List<CompletionItem>>> _getPluginResults(
    LspClientCapabilities capabilities,
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
      capabilities,
      lineInfo,
      offset,
      pluginResults,
    ).toList());
  }

  Future<ErrorOr<List<CompletionItem>>> _getServerDartItems(
    LspClientCapabilities capabilities,
    bool includeSuggestionSets,
    ResolvedUnitResult unit,
    int offset,
    String? triggerCharacter,
    CancellationToken token,
  ) async {
    final performance = CompletionPerformance();
    performance.path = unit.path;
    performance.setContentsAndOffset(unit.content, offset);
    server.performanceStats.completion.add(performance);

    return await performance.runRequestOperation((perf) async {
      final completionRequest =
          CompletionRequestImpl(unit, offset, performance);
      final directiveInfo =
          server.getDartdocDirectiveInfoFor(completionRequest.result);
      final dartCompletionRequest = await DartCompletionRequestImpl.from(
          perf, completionRequest, directiveInfo);
      final target = dartCompletionRequest.target;

      if (triggerCharacter != null) {
        if (!_triggerCharacterValid(offset, triggerCharacter, target)) {
          return success([]);
        }
      }

      Set<ElementKind>? includedElementKinds;
      Set<String>? includedElementNames;
      List<IncludedSuggestionRelevanceTag>? includedSuggestionRelevanceTags;
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
          completionPreference: CompletionPreference.replace,
        );

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

        final results = serverSuggestions.map(
          (item) {
            var itemReplacementOffset =
                item.replacementOffset ?? completionRequest.replacementOffset;
            var itemReplacementLength =
                item.replacementLength ?? completionRequest.replacementLength;
            var itemInsertLength = insertLength;

            // Recompute the insert length if it may be affected by the above.
            if (item.replacementOffset != null ||
                item.replacementLength != null) {
              itemInsertLength = _computeInsertLength(
                  offset, itemReplacementOffset, itemInsertLength);
            }

            return toCompletionItem(
              capabilities,
              unit.lineInfo,
              item,
              itemReplacementOffset,
              itemInsertLength,
              itemReplacementLength,
              // TODO(dantup): Including commit characters in every completion
              // increases the payload size. The LSP spec is ambigious
              // about how this should be handled (and VS Code requires it) but
              // this should be removed (or made conditional based on a capability)
              // depending on how the spec is updated.
              // https://github.com/microsoft/vscode-languageserver-node/issues/673
              includeCommitCharacters:
                  server.clientConfiguration.global.previewCommitCharacters,
              completeFunctionCalls: completeFunctionCalls,
            );
          },
        ).toList();

        // Now compute items in suggestion sets.
        var includedSuggestionSets = <IncludedSuggestionSet>[];
        final declarationsTracker = server.declarationsTracker;
        if (declarationsTracker != null &&
            includedElementKinds != null &&
            includedElementNames != null &&
            includedSuggestionRelevanceTags != null) {
          computeIncludedSetList(
            declarationsTracker,
            unit,
            includedSuggestionSets,
            includedElementNames,
          );

          // Build a fast lookup for imported symbols so that we can filter out
          // duplicates.
          final alreadyImportedSymbols = _buildLookupOfImportedSymbols(unit);

          includedSuggestionSets.forEach((includedSet) {
            final library = declarationsTracker.getLibrary(includedSet.id);
            if (library == null) {
              return;
            }

            // Make a fast lookup for tag relevance.
            final tagBoosts = <String, int>{};
            includedSuggestionRelevanceTags!
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
                .where((item) => includedElementKinds!
                    .contains(protocolElementKind(item.kind)))
                .where((item) {
              // Check existing imports to ensure we don't already import
              // this element (this exact element from its declaring
              // library, not just something with the same name). If we do
              // we'll want to skip it.
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
            }).map((item) => declarationToCompletionItem(
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
                      // TODO(dantup): Including commit characters in every completion
                      // increases the payload size. The LSP spec is ambigious
                      // about how this should be handled (and VS Code requires it) but
                      // this should be removed (or made conditional based on a capability)
                      // depending on how the spec is updated.
                      // https://github.com/microsoft/vscode-languageserver-node/issues/673
                      includeCommitCharacters: server
                          .clientConfiguration.global.previewCommitCharacters,
                      completeFunctionCalls: completeFunctionCalls,
                    ));
            results.addAll(setResults);
          });
        }

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

  Future<ErrorOr<List<CompletionItem>>> _getServerYamlItems(
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
    final completionItems = suggestions.suggestions
        .map(
          (item) => toCompletionItem(
            capabilities,
            lineInfo,
            item,
            suggestions.replacementOffset,
            insertLength,
            suggestions.replacementLength,
            includeCommitCharacters: false,
            completeFunctionCalls: false,
            // Add on any completion-kind-specific resolution data that will be
            // used during resolve() calls to provide additional information.
            resolutionData: item.kind == CompletionSuggestionKind.PACKAGE_NAME
                ? PubPackageCompletionItemResolutionInfo(
                    file: path,
                    offset: offset,
                    // The completion for package names may contain a trailing
                    // ': ' for convenience, so if it's there, trim it off.
                    packageName: item.completion.split(':').first,
                  )
                : null,
          ),
        )
        .toList();
    return success(completionItems);
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
            !node.argumentList.beginToken.isSynthetic);
  }

  Iterable<CompletionItem> _pluginResultsToItems(
    LspClientCapabilities capabilities,
    LineInfo lineInfo,
    int offset,
    List<plugin.CompletionGetSuggestionsResult> pluginResults,
  ) {
    return pluginResults.expand((result) {
      return result.results.map(
        (item) => toCompletionItem(
          capabilities,
          lineInfo,
          item,
          result.replacementOffset,
          _computeInsertLength(
            offset,
            result.replacementOffset,
            result.replacementLength,
          ),
          result.replacementLength,
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
}
