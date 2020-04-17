// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analyzer/dart/element/element.dart' show LibraryElement;
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/micro/resolve_file.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';

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

  CiderCompletionComputer(this._logger, this._cache, this._fileResolver);

  Future<List<CompletionSuggestion>> compute(String path, int offset) async {
    var resolvedUnit = _fileResolver.resolve(path);

    var completionRequest = CompletionRequestImpl(
      resolvedUnit,
      offset,
      false,
      CompletionPerformance(),
    );
    var dartdocDirectiveInfo = DartdocDirectiveInfo();

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

    _dartCompletionRequest = await DartCompletionRequestImpl.from(
      completionRequest,
      dartdocDirectiveInfo,
    );

    _logger.run('Add imported suggestions', () {
      suggestions.addAll(
        _importedLibrariesSuggestions(
          resolvedUnit.libraryElement,
        ),
      );
    });

    return suggestions;
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
    var visitor = LibraryElementSuggestionBuilder(_dartCompletionRequest, '');
    var exportMap = element.exportNamespace.definedNames;
    for (var definedElement in exportMap.values) {
      definedElement.accept(visitor);
    }
    return visitor.suggestions;
  }
}

class CiderCompletionResult {
  final List<CompletionSuggestion> suggestions;

  CiderCompletionResult(this.suggestions);
}

class _CiderImportedLibrarySuggestions {
  final String signature;
  final List<CompletionSuggestion> suggestions;

  _CiderImportedLibrarySuggestions(this.signature, this.suggestions);
}
