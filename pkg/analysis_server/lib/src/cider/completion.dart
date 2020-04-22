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
import 'package:meta/meta.dart';

/// The cache that can be reuse for across multiple completion request.
///
/// It contains data that is relatively small, and does not include for
/// example types and elements.
class CiderCompletionCache {
  final Map<String, _CiderImportedLibrarySuggestions> _importedLibraries = {};
  _LastCompletionResult _lastResult;
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

  @deprecated
  Future<List<CompletionSuggestion>> compute(String path, int offset) async {
    var fileContext = _fileResolver.getFileContext(path);
    var file = fileContext.file;

    var location = file.lineInfo.getLocation(offset);

    var result = await compute2(
      path: path,
      line: location.lineNumber - 1,
      column: location.columnNumber - 1,
    );

    return result.suggestions;
  }

  /// Return completion suggestions for the file and position.
  ///
  /// The [path] must be the absolute and normalized path of the file.
  ///
  /// The content of the file has already been updated.
  ///
  /// The [line] and [column] are zero based.
  Future<CiderCompletionResult> compute2({
    @required String path,
    @required int line,
    @required int column,
  }) async {
    var fileContext = _logger.run('Get file $path', () {
      return _fileResolver.getFileContext(path);
    });

    var file = fileContext.file;

    var resolvedSignature = _logger.run('Get signature', () {
      return file.resolvedSignature;
    });

    var lineInfo = file.lineInfo;
    var offset = lineInfo.getOffsetOfLine(line) + column;

    // If the same file, in the same state as the last time, reuse the result.
    var lastResult = _cache._lastResult;
    if (lastResult != null &&
        lastResult.path == path &&
        lastResult.signature == resolvedSignature &&
        lastResult.offset == offset) {
      _logger.writeln('Use the last completion result.');
      return lastResult.result;
    }

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

    if (_dartCompletionRequest.includeIdentifiers) {
      _logger.run('Add imported suggestions', () {
        suggestions.addAll(
          _importedLibrariesSuggestions(
            resolvedUnit.libraryElement,
          ),
        );
      });
    }

    var result = CiderCompletionResult._(suggestions);

    _cache._lastResult =
        _LastCompletionResult(path, resolvedSignature, offset, result);

    return result;
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

  CiderCompletionResult._(this.suggestions);
}

class _CiderImportedLibrarySuggestions {
  final String signature;
  final List<CompletionSuggestion> suggestions;

  _CiderImportedLibrarySuggestions(this.signature, this.suggestions);
}

class _LastCompletionResult {
  final String path;
  final String signature;
  final int offset;
  final CiderCompletionResult result;

  _LastCompletionResult(this.path, this.signature, this.offset, this.result);
}
