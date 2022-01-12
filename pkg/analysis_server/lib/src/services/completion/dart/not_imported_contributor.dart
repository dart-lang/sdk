// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/extension_member_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/file_state_filter.dart';

/// A contributor of suggestions from not yet imported libraries.
class NotImportedContributor extends DartCompletionContributor {
  final CompletionBudget budget;
  final NotImportedSuggestions additionalData;

  NotImportedContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
    this.budget,
    this.additionalData,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    var analysisDriver = request.analysisContext.driver;

    var fsState = analysisDriver.fsState;
    var filter = FileStateFilter(
      fsState.getFileForPath(request.path),
    );

    try {
      await analysisDriver.discoverAvailableFiles().timeout(budget.left);
    } on TimeoutException {
      additionalData.isIncomplete = true;
      return;
    }

    // Use single instance to track getter / setter pairs.
    var extensionContributor = ExtensionMemberContributor(request, builder);

    var knownFiles = fsState.knownFiles.toList();
    for (var file in knownFiles) {
      if (budget.isEmpty) {
        additionalData.isIncomplete = true;
        return;
      }

      if (!filter.shouldInclude(file)) {
        continue;
      }

      var element = analysisDriver.getLibraryByFile(file);
      if (element == null) {
        continue;
      }

      var exportNamespace = element.exportNamespace;
      var exportElements = exportNamespace.definedNames.values.toList();

      builder.laterReplacesEarlier = false;
      builder.suggestionAdded = (suggestion) {
        additionalData.set.add(suggestion);
      };

      if (request.includeIdentifiers) {
        _buildSuggestions(exportElements);
      }

      extensionContributor.addExtensions(
        exportElements.whereType<ExtensionElement>().toList(),
      );
    }

    builder.laterReplacesEarlier = true;
    builder.suggestionAdded = null;
  }

  void _buildSuggestions(List<Element> elements) {
    var visitor = LibraryElementSuggestionBuilder(request, builder);
    for (var element in elements) {
      element.accept(visitor);
    }
  }
}
