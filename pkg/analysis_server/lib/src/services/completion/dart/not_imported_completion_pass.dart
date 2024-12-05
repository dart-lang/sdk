// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/completion/dart/completion_state.dart';
import 'package:analysis_server/src/services/completion/dart/declaration_helper.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// An operation run by the [NotImportedCompletionPass] to add the constructors
/// from a not imported library.
class ConstructorsOperation extends NotImportedOperation {
  /// The declaration helper to be used to create the candidate suggestions.
  final DeclarationHelper _declarationHelper;

  /// Initialize a newly created operation to use the [declarationHelper] to add
  /// the static members from a library.
  ConstructorsOperation({required DeclarationHelper declarationHelper})
      : _declarationHelper = declarationHelper;

  /// Compute any candidate suggestions for elements in the [library].
  void computeSuggestionsIn(LibraryElement library) {
    _declarationHelper.addNotImportedConstructors(library);
  }
}

/// An operation run by the [NotImportedCompletionPass] to add the members of
/// the extensions in a given library that match a known type.
class InstanceExtensionMembersOperation extends NotImportedOperation {
  /// The declaration helper to be used to create the candidate suggestions.
  final DeclarationHelper _declarationHelper;

  /// The type that the extensions must extend.
  final DartType _type;

  /// The names of getters that should not be suggested.
  final Set<String> _excludedGetters;

  /// Whether to include suggestions for methods.
  final bool _includeMethods;

  /// Whether to include suggestions for setters.
  final bool _includeSetters;

  InstanceExtensionMembersOperation(
      {required DeclarationHelper declarationHelper,
      required DartType type,
      required Set<String> excludedGetters,
      required bool includeMethods,
      required bool includeSetters})
      : _declarationHelper = declarationHelper,
        _type = type,
        _excludedGetters = excludedGetters,
        _includeMethods = includeMethods,
        _includeSetters = includeSetters;

  /// Compute any candidate suggestions for elements in the [library].
  void computeSuggestionsIn(LibraryElement library) {
    _declarationHelper.addNotImportedExtensionMethods(
        library: library,
        type: _type,
        excludedGetters: _excludedGetters,
        includeMethods: _includeMethods,
        includeSetters: _includeSetters);
  }
}

/// A completion pass that will create candidate suggestions based on the
/// elements that are not in scope in the library containing the selection, but
/// that could be imported into the scope.
class NotImportedCompletionPass {
  /// The state used to compute the candidate suggestions.
  final CompletionState _state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector _collector;

  /// The operation to be performed for each of the not imported libraries.
  final List<NotImportedOperation> _operations;

  /// Initialize a newly created completion pass.
  NotImportedCompletionPass(
      {required CompletionState state,
      required SuggestionCollector collector,
      required List<NotImportedOperation> operations})
      : _state = state,
        _collector = collector,
        _operations = operations;

  /// Compute any candidate suggestions for elements in not imported libraries.
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var request = _state.request;
    var budget = _state.budget;

    var analysisDriver = request.analysisContext.driver;

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(request.path),
    );

    try {
      await performance.runAsync('discoverAvailableFiles', (_) async {
        await analysisDriver.discoverAvailableFiles().timeout(budget.left);
      });
    } on TimeoutException {
      _collector.isIncomplete = true;
      return;
    }

    _ImportSummary? importSummary;
    var knownFiles = fsState.knownFiles.toList();
    for (var file in knownFiles) {
      if (budget.isEmpty) {
        _collector.isIncomplete = true;
        return;
      }

      if (file.kind is PartFileKind || !filter.shouldInclude(file)) {
        continue;
      }

      var elementResult = await performance.runAsync(
        'getLibraryByUri',
        (_) async {
          return await analysisDriver.getLibraryByUri(file.uriStr);
        },
      );
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      var library = request.libraryElement;
      var element = elementResult.element;
      if (element == library) {
        // Don't suggest elements from the library in which completion is being
        // requested. They've already been suggested.
        continue;
      }

      for (var operation in _operations) {
        switch (operation) {
          case ConstructorsOperation():
            importSummary ??= _ImportSummary(library);
            if (importSummary.importedLibraries.contains(element)) {
              continue;
            }
            performance.run('constructors', (_) {
              operation.computeSuggestionsIn(element);
            });
          case InstanceExtensionMembersOperation():
            performance.run('instanceMembers', (_) {
              operation.computeSuggestionsIn(element);
            });
          case StaticMembersOperation():
            importSummary ??= _ImportSummary(library);
            if (importSummary.importedLibraries.contains(element)) {
              continue;
            }

            var exportNamespace = element.exportNamespace;
            var exportElements = exportNamespace.definedNames.values.toList();

            performance.run('staticMembers', (_) {
              operation.computeSuggestionsIn(element, exportElements,
                  importSummary?.importedElements ?? {});
            });
        }
      }
    }
  }
}

/// An operation used to process a not imported library in order to add
/// candidate completion suggestions from the library.
sealed class NotImportedOperation {}

/// An operation run by the [NotImportedCompletionPass] to add the static
/// members from a not imported library.
class StaticMembersOperation extends NotImportedOperation {
  /// The declaration helper to be used to create the candidate suggestions.
  final DeclarationHelper _declarationHelper;

  /// Initialize a newly created operation to use the [declarationHelper] to add
  /// the static members from a library.
  StaticMembersOperation({required DeclarationHelper declarationHelper})
      : _declarationHelper = declarationHelper;

  /// Compute any candidate suggestions for elements in the [library].
  void computeSuggestionsIn(LibraryElement library,
      List<Element> exportElements, Set<Element> importedElements) {
    // TODO(brianwilkerson): Determine whether we need the element parameters.
    _declarationHelper.addNotImportedTopLevelDeclarations(library);
  }
}

/// A summary of the elements imported by a library.
class _ImportSummary {
  /// The elements that are imported from libraries that are only partially
  /// imported.
  Set<Element> importedElements = Set<Element>.identity();

  /// The libraries that are imported in their entirety.
  Set<LibraryElement> importedLibraries = Set<LibraryElement>.identity();

  _ImportSummary(LibraryElement library) {
    for (var import in library.definingCompilationUnit.libraryImports) {
      var importedLibrary = import.importedLibrary;
      if (importedLibrary != null) {
        if (import.combinators.isEmpty) {
          importedLibraries.add(importedLibrary);
        } else {
          importedElements.addAll(
            import.namespace.definedNames.values,
          );
        }
      }
    }
  }
}
