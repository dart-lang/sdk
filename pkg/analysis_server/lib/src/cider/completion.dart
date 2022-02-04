// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/fuzzy_filter_sort.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
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

  late DartCompletionRequest _dartCompletionRequest;

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
    required String path,
    required int line,
    required int column,
    @visibleForTesting void Function(ResolvedUnitResult)? testResolvedUnit,
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

      _dartCompletionRequest = DartCompletionRequest.forResolvedUnit(
        resolvedUnit: resolvedUnit,
        offset: offset,
      );

      var suggestions = await performance.runAsync(
        'suggestions',
        (performance) async {
          var result = await _logger.runAsync('Compute suggestions', () async {
            var includedElementKinds = <ElementKind>{};
            var includedElementNames = <String>{};
            var includedSuggestionRelevanceTags =
                <IncludedSuggestionRelevanceTag>[];

            var manager = DartCompletionManager(
              budget: CompletionBudget(CompletionBudget.defaultDuration),
              includedElementKinds: includedElementKinds,
              includedElementNames: includedElementNames,
              includedSuggestionRelevanceTags: includedSuggestionRelevanceTags,
            );

            return await manager.computeSuggestions(
              _dartCompletionRequest,
              performance,
              enableOverrideContributor: false,
              enableUriContributor: false,
            );
          });

          performance.getDataInt('count').add(result.length);
          return result.toList();
        },
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

      var filterPattern = _dartCompletionRequest.targetPrefix;

      performance.run('filter', (performance) {
        _logger.run('Filter suggestions', () {
          performance.getDataInt('count').add(suggestions.length);
          suggestions = fuzzyFilterSort(
            pattern: filterPattern,
            suggestions: suggestions,
          );
          performance.getDataInt('matchCount').add(suggestions.length);
        });
      });

      var result = CiderCompletionResult._(
        suggestions: suggestions.map((e) => e.build()).toList(),
        performance: CiderCompletionPerformance._(
          operations: _performanceRoot.children.first,
        ),
        prefixStart: CiderPosition(line, column - filterPattern.length),
      );

      return result;
    });
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
  List<CompletionSuggestionBuilder> _importedLibrariesSuggestions({
    required LibraryElement target,
    required OperationPerformanceImpl performance,
  }) {
    var suggestionBuilders = <CompletionSuggestionBuilder>[];
    for (var importedLibrary in target.importedLibraries) {
      var importedSuggestions = _importedLibrarySuggestions(
        element: importedLibrary,
        performance: performance,
      );
      suggestionBuilders.addAll(importedSuggestions);
    }
    performance.getDataInt('count').add(suggestionBuilders.length);
    return suggestionBuilders;
  }

  /// Return cached, or compute unprefixed suggestions for all elements
  /// exported from the library.
  List<CompletionSuggestionBuilder> _importedLibrarySuggestions({
    required LibraryElement element,
    required OperationPerformanceImpl performance,
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
    return cacheEntry.suggestionBuilders;
  }

  /// Compute all unprefixed suggestions for all elements exported from
  /// the library.
  List<CompletionSuggestionBuilder> _librarySuggestions(
      LibraryElement element) {
    var suggestionBuilder = SuggestionBuilder(_dartCompletionRequest);
    suggestionBuilder.libraryUriStr = element.source.uri.toString();
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
  /// The tree of operation performances.
  final OperationPerformance operations;

  CiderCompletionPerformance._({
    required this.operations,
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
    required this.suggestions,
    required this.performance,
    required this.prefixStart,
  });
}

class CiderPosition {
  final int line;
  final int column;

  CiderPosition(this.line, this.column);
}

class _CiderImportedLibrarySuggestions {
  final String signature;
  final List<CompletionSuggestionBuilder> suggestionBuilders;

  _CiderImportedLibrarySuggestions(this.signature, this.suggestionBuilders);
}
