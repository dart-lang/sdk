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
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// An operation run by the [NotImportedCompletionPass] to add the members of
/// the extensions in a given library that match a known type.
class InstanceExtensionMembersOperation extends NotImportedOperation {
  /// The declaration helper to be used to create the candidate suggestions.
  final DeclarationHelper declarationHelper;

  /// The type that the extensions must extend.
  final InterfaceType type;

  /// The names of getters that should not be suggested.
  final Set<String> excludedGetters;

  /// Whether to include suggestions for methods.
  final bool includeMethods;

  /// Whether to include suggestions for setters.
  final bool includeSetters;

  InstanceExtensionMembersOperation(
      {required this.declarationHelper,
      required this.type,
      required this.excludedGetters,
      required this.includeMethods,
      required this.includeSetters});

  /// Compute any candidate suggestions for elements in the [library].
  void computeSuggestionsIn(LibraryElement library) {
    declarationHelper.addNotImportedExtensionMethods(
        library: library,
        type: type,
        excludedGetters: excludedGetters,
        includeMethods: includeMethods,
        includeSetters: includeSetters);
  }
}

/// A completion pass that will create candidate suggestions based on the
/// elements that are not in scope in the library containing the selection, but
/// that could be imported into the scope.
class NotImportedCompletionPass {
  /// The state used to compute the candidate suggestions.
  final CompletionState state;

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The operation to be performed for each of the not imported libraries.
  final List<NotImportedOperation> operations;

  /// Initialize a newly created completion pass.
  NotImportedCompletionPass(this.state, this.collector, this.operations);

  /// Compute any candidate suggestions for elements in not imported libraries.
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    var request = state.request;
    var budget = state.budget;

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
      collector.isIncomplete = true;
      return;
    }

    var knownFiles = fsState.knownFiles.toList();
    for (var file in knownFiles) {
      if (budget.isEmpty) {
        collector.isIncomplete = true;
        return;
      }

      if (!filter.shouldInclude(file)) {
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

      for (var operation in operations) {
        switch (operation) {
          case InstanceExtensionMembersOperation():
            performance.run('instanceMembers', (_) {
              operation.computeSuggestionsIn(elementResult.element);
            });
          case StaticMembersOperation():
            var importedElements = Set<Element>.identity();
            var importedLibraries = Set<LibraryElement>.identity();
            for (var import in request.libraryElement.libraryImports) {
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

            var element = elementResult.element;
            if (importedLibraries.contains(element)) {
              continue;
            }

            var exportNamespace = element.exportNamespace;
            var exportElements = exportNamespace.definedNames.values.toList();

            performance.run('staticMembers', (_) {
              operation.computeSuggestionsIn(
                  elementResult.element, exportElements, importedElements);
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
  final DeclarationHelper declarationHelper;

  /// Initialize a newly created operation to use the [declarationHelper] to add
  /// the static members from a library.
  StaticMembersOperation({required this.declarationHelper});

  /// Compute any candidate suggestions for elements in the [library].
  void computeSuggestionsIn(LibraryElement library,
      List<Element> exportElements, Set<Element> importedElements) {
    // TODO(brianwilkerson): Determine whether we need the element parameters.
    declarationHelper.addNotImportedTopLevelDeclarations(library);
  }
}
