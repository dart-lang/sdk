// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';

/// The cache that can be reuse for across multiple completion request.
///
/// It contains data that is relatively small, and does not include for
/// example types and elements.
class CiderCompletionCache {
  final Map<String, _CiderImportedLibrarySuggestions> _importedLibraries = {};
}

class CiderCompletionComputer {
  final PerformanceLog _logger;
  final CiderCompletionCache _cache;
  final FileResolver _fileResolver;

  DartCompletionRequestImpl _dartCompletionRequest;

  /// Paths of imported libraries for which suggestions were (re)computed
  /// during processing of this request. Does not include libraries that were
  /// processed during previous requests, and reused from the cache now.
  @visibleForTesting
  final List<String> computedImportedLibraries = [];

  CiderCompletionComputer(this._logger, this._cache, this._fileResolver);

  /// Return completion suggestions for the file and position.
  ///
  /// The [path] must be the absolute and normalized path of the file.
  ///
  /// The content of the file has already been updated.
  ///
  /// The [line] and [column] are zero based.
  Future<CiderCompletionResult> compute({
    @required String path,
    @required int line,
    @required int column,
  }) async {
    var getFileTimer = Stopwatch()..start();
    var fileContext = _logger.run('Get file $path', () {
      try {
        return _fileResolver.getFileContext(path);
      } finally {
        getFileTimer.stop();
      }
    });

    var file = fileContext.file;

    var lineInfo = file.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    var resolutionTimer = Stopwatch()..start();
    var resolvedUnit = _fileResolver.resolve(path);
    resolutionTimer.stop();

    var completionRequest = CompletionRequestImpl(
      resolvedUnit,
      offset,
      false,
      CompletionPerformance(),
    );
    var dartdocDirectiveInfo = DartdocDirectiveInfo();

    var suggestionsTimer = Stopwatch()..start();
    var suggestions = await _logger.runAsync('Compute suggestions', () async {
      var includedElementKinds = <ElementKind>{};
      var includedElementNames = <String>{};
      var includedSuggestionRelevanceTags = <IncludedSuggestionRelevanceTag>[];

      var manager = DartCompletionManager(
        dartdocDirectiveInfo: dartdocDirectiveInfo,
        includedElementKinds: includedElementKinds,
        includedElementNames: includedElementNames,
        includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
      );

      return await manager.computeSuggestions(completionRequest);
    });
    suggestionsTimer.stop();

    _dartCompletionRequest = await DartCompletionRequestImpl.from(
      completionRequest,
      dartdocDirectiveInfo,
    );

    var importsTimer = Stopwatch();
    if (_dartCompletionRequest.includeIdentifiers) {
      _logger.run('Add imported suggestions', () {
        importsTimer.start();
        suggestions.addAll(
          _importedLibrariesSuggestions(
            resolvedUnit.libraryElement,
          ),
        );
        importsTimer.stop();
      });
    }

    var filter = _FilterSort(
      _dartCompletionRequest,
      suggestions,
    );

    _logger.run('Filter suggestions', () {
      suggestions = filter.perform();
    });

    var result = CiderCompletionResult._(
      suggestions: suggestions,
      performance: CiderCompletionPerformance(
        file: getFileTimer.elapsed,
        imports: importsTimer.elapsed,
        resolution: resolutionTimer.elapsed,
        suggestions: suggestionsTimer.elapsed,
      ),
      prefixStart: CiderPosition(line, column - filter._pattern.length),
    );

    return result;
  }

  @Deprecated('Use compute')
  Future<CiderCompletionResult> compute2({
    @required String path,
    @required int line,
    @required int column,
  }) async {
    return compute(path: path, line: line, column: column);
  }

  /// Return suggestions from libraries imported into the [target].
  ///
  /// TODO(scheglov) Implement show / hide combinators.
  /// TODO(scheglov) Implement prefixes.
  List<CompletionSuggestion> _importedLibrariesSuggestions(
    LibraryElement target,
  ) {
    var suggestions = <CompletionSuggestion>[];
    for (var importedLibrary in target.importedLibraries) {
      var importedSuggestions = _importedLibrarySuggestions(importedLibrary);
      suggestions.addAll(importedSuggestions);
    }
    return suggestions;
  }

  /// Return cached, or compute unprefixed suggestions for all elements
  /// exported from the library.
  List<CompletionSuggestion> _importedLibrarySuggestions(
    LibraryElement element,
  ) {
    var path = element.source.fullName;
    var signature = _fileResolver.getLibraryLinkedSignature(path);

    var cacheEntry = _cache._importedLibraries[path];
    if (cacheEntry == null || cacheEntry.signature != signature) {
      computedImportedLibraries.add(path);
      var suggestions = _librarySuggestions(element);
      cacheEntry = _CiderImportedLibrarySuggestions(
        signature,
        suggestions,
      );
      _cache._importedLibraries[path] = cacheEntry;
    }
    return cacheEntry.suggestions;
  }

  /// Compute all unprefixed suggestions for all elements exported from
  /// the library.
  List<CompletionSuggestion> _librarySuggestions(LibraryElement element) {
    var suggestionBuilder = SuggestionBuilder(_dartCompletionRequest);
    var visitor = LibraryElementSuggestionBuilder(
        _dartCompletionRequest, suggestionBuilder);
    var exportMap = element.exportNamespace.definedNames;
    for (var definedElement in exportMap.values) {
      definedElement.accept(visitor);
    }
    return suggestionBuilder.suggestions.toList();
  }
}

class CiderCompletionPerformance {
  /// The elapsed time for file access.
  final Duration file;

  /// The elapsed time to compute import suggestions.
  final Duration imports;

  /// The elapsed time for resolution.
  final Duration resolution;

  /// The elapsed time to compute suggestions.
  final Duration suggestions;

  CiderCompletionPerformance({
    @required this.file,
    @required this.imports,
    @required this.resolution,
    @required this.suggestions,
  });
}

class CiderCompletionResult {
  final List<CompletionSuggestion> suggestions;

  final CiderCompletionPerformance performance;

  /// The start of the range that should be replaced with the suggestion. This
  /// position always precedes or is the same as the cursor provided in the
  /// completion request.
  final CiderPosition prefixStart;

  CiderCompletionResult._({
    @required this.suggestions,
    @required this.performance,
    @required this.prefixStart,
  });
}

class CiderPosition {
  final int line;
  final int column;

  CiderPosition(this.line, this.column);
}

class _CiderImportedLibrarySuggestions {
  final String signature;
  final List<CompletionSuggestion> suggestions;

  _CiderImportedLibrarySuggestions(this.signature, this.suggestions);
}

class _FilterSort {
  final DartCompletionRequestImpl _request;
  final List<CompletionSuggestion> _suggestions;

  FuzzyMatcher _matcher;
  String _pattern;

  _FilterSort(this._request, this._suggestions);

  List<CompletionSuggestion> perform() {
    _pattern = _matchingPattern();
    _matcher = FuzzyMatcher(_pattern, matchStyle: MatchStyle.SYMBOL);

    var scored = _suggestions
        .map((e) => _FuzzyScoredSuggestion(e, _score(e)))
        .where((e) => e.score > 0)
        .toList();

    scored.sort((a, b) {
      // Prefer what the user requested by typing.
      if (a.score > b.score) {
        return -1;
      } else if (a.score < b.score) {
        return 1;
      }

      // Then prefer what is more relevant in the context.
      if (a.suggestion.relevance != b.suggestion.relevance) {
        return -(a.suggestion.relevance - b.suggestion.relevance);
      }

      // Other things being equal, sort by name.
      return a.suggestion.completion.compareTo(b.suggestion.completion);
    });

    return scored.map((e) => e.suggestion).toList();
  }

  /// Return the pattern to match suggestions against, from the identifier
  /// to the left of the caret. Return the empty string if cannot find the
  /// identifier.
  String _matchingPattern() {
    SimpleIdentifier patternNode;
    _request.target.containingNode.accept(
      FunctionAstVisitor(simpleIdentifier: (node) {
        if (node.end == _request.offset) {
          patternNode = node;
        }
      }),
    );

    if (patternNode != null) {
      return patternNode.name;
    }

    return '';
  }

  double _score(CompletionSuggestion e) {
    var suggestionTextToMatch = e.completion;

    if (e.kind == CompletionSuggestionKind.NAMED_ARGUMENT) {
      var index = suggestionTextToMatch.indexOf(':');
      if (index != -1) {
        suggestionTextToMatch = suggestionTextToMatch.substring(0, index);
      }
    }

    return _matcher.score(suggestionTextToMatch);
  }
}

/// [CompletionSuggestion] scored using [FuzzyMatcher].
class _FuzzyScoredSuggestion {
  final CompletionSuggestion suggestion;
  final double score;

  _FuzzyScoredSuggestion(this.suggestion, this.score);
}
