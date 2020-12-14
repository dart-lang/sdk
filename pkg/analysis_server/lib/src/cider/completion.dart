// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/filtering/fuzzy_matcher.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
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

  final OperationPerformanceImpl _performanceRoot =
      OperationPerformanceImpl('<root>');

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
    @visibleForTesting void Function(ResolvedUnitResult) testResolvedUnit,
  }) async {
    return _performanceRoot.runAsync('completion', (performance) async {
      var resolvedUnit = performance.run('resolution', (performance) {
        return _fileResolver.resolve(
          completionLine: line,
          completionColumn: column,
          path: path,
          performance: performance,
        );
      });

      if (testResolvedUnit != null) {
        testResolvedUnit(resolvedUnit);
      }

      var lineInfo = resolvedUnit.lineInfo;
      var offset = lineInfo.getOffsetOfLine(line) + column;

      var completionRequest = CompletionRequestImpl(
        resolvedUnit,
        offset,
        CompletionPerformance(),
      );
      var dartdocDirectiveInfo = DartdocDirectiveInfo();

      var suggestions = await performance.runAsync(
        'suggestions',
        (performance) async {
          var result = await _logger.runAsync('Compute suggestions', () async {
            var includedElementKinds = <ElementKind>{};
            var includedElementNames = <String>{};
            var includedSuggestionRelevanceTags =
                <IncludedSuggestionRelevanceTag>[];

            var manager = DartCompletionManager(
              dartdocDirectiveInfo: dartdocDirectiveInfo,
              includedElementKinds: includedElementKinds,
              includedElementNames: includedElementNames,
              includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
            );

            return await manager.computeSuggestions(
              performance,
              completionRequest,
              enableOverrideContributor: false,
              enableUriContributor: false,
            );
          });

          performance.getDataInt('count').add(result.length);
          return result.toList();
        },
      );

      _dartCompletionRequest = await DartCompletionRequestImpl.from(
        performance,
        completionRequest,
        dartdocDirectiveInfo,
      );

      performance.run('imports', (performance) {
        if (_dartCompletionRequest.includeIdentifiers) {
          _logger.run('Add imported suggestions', () {
            suggestions.addAll(
              _importedLibrariesSuggestions(
                target: resolvedUnit.libraryElement,
                performance: performance,
              ),
            );
          });
        }
      });

      var filter = _FilterSort(
        _dartCompletionRequest,
        suggestions,
      );

      performance.run('filter', (performance) {
        _logger.run('Filter suggestions', () {
          performance.getDataInt('count').add(suggestions.length);
          suggestions = filter.perform();
          performance.getDataInt('matchCount').add(suggestions.length);
        });
      });

      var result = CiderCompletionResult._(
        suggestions: suggestions,
        performance: CiderCompletionPerformance._(
          file: Duration.zero,
          imports: performance.getChild('imports').elapsed,
          resolution: performance.getChild('resolution').elapsed,
          suggestions: performance.getChild('suggestions').elapsed,
          operations: _performanceRoot.children.first,
        ),
        prefixStart: CiderPosition(line, column - filter._pattern.length),
      );

      return result;
    });
  }

  @Deprecated('Use compute')
  Future<CiderCompletionResult> compute2({
    @required String path,
    @required int line,
    @required int column,
  }) async {
    return compute(path: path, line: line, column: column);
  }

  /// Prepare for computing completions in files from the [pathList].
  ///
  /// This method might be called when we are finishing a large initial
  /// analysis, so spending additionally a fraction of this time to make
  /// any subsequent completion seem fast is a reasonable trade-off.
  Future<void> warmUp(List<String> pathList) async {
    for (var path in pathList) {
      await compute(path: path, line: 0, column: 0);
    }
  }

  /// Return suggestions from libraries imported into the [target].
  ///
  /// TODO(scheglov) Implement show / hide combinators.
  /// TODO(scheglov) Implement prefixes.
  List<CompletionSuggestion> _importedLibrariesSuggestions({
    @required LibraryElement target,
    @required OperationPerformanceImpl performance,
  }) {
    var suggestions = <CompletionSuggestion>[];
    for (var importedLibrary in target.importedLibraries) {
      var importedSuggestions = _importedLibrarySuggestions(
        element: importedLibrary,
        performance: performance,
      );
      suggestions.addAll(importedSuggestions);
    }
    performance.getDataInt('count').add(suggestions.length);
    return suggestions;
  }

  /// Return cached, or compute unprefixed suggestions for all elements
  /// exported from the library.
  List<CompletionSuggestion> _importedLibrarySuggestions({
    @required LibraryElement element,
    @required OperationPerformanceImpl performance,
  }) {
    performance.getDataInt('libraryCount').increment();

    var path = element.source.fullName;
    var signature = _fileResolver.getLibraryLinkedSignature(
      path: path,
      performance: performance,
    );

    var cacheEntry = _cache._importedLibraries[path];
    if (cacheEntry == null || cacheEntry.signature != signature) {
      performance.getDataInt('libraryCompute').increment();
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
  @Deprecated('This operation is not performed anymore')
  final Duration file;

  /// The elapsed time to compute import suggestions.
  @Deprecated("Use 'operations' instead")
  final Duration imports;

  /// The elapsed time for resolution.
  @Deprecated("Use 'operations' instead")
  final Duration resolution;

  /// The elapsed time to compute suggestions.
  @Deprecated("Use 'operations' instead")
  final Duration suggestions;

  /// The tree of operation performances.
  final OperationPerformance operations;

  CiderCompletionPerformance._({
    @required this.file,
    @required this.imports,
    @required this.resolution,
    @required this.suggestions,
    @required this.operations,
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
    _pattern = _request.targetPrefix;
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
