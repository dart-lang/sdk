// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/local_library_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart'
    show SuggestionBuilder;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';

/// A contributor of suggestions from not yet imported libraries.
class NotImportedContributor extends DartCompletionContributor {
  final List<Uri> librariesToImport;

  NotImportedContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
    this.librariesToImport,
  ) : super(request, builder);

  @override
  Future<void> computeSuggestions() async {
    if (!request.includeIdentifiers) {
      return;
    }

    var session = request.result.session as AnalysisSessionImpl;
    var analysisDriver = session.getDriver(); // ignore: deprecated_member_use

    // TODO(scheglov) discover more files

    var knownFiles = analysisDriver.fsState.knownFiles.toList();
    for (var file in knownFiles) {
      var elementResult = await session.getLibraryByUri(file.uriStr);
      if (elementResult is! LibraryElementResult) {
        continue;
      }

      var newSuggestions = builder.markSuggestions();

      _buildSuggestions(
        elementResult.element.exportNamespace,
      );

      newSuggestions.setLibraryUriToImportIndex(() {
        librariesToImport.add(file.uri);
        return librariesToImport.length - 1;
      });
    }
  }

  void _buildSuggestions(Namespace namespace) {
    var visitor = LibraryElementSuggestionBuilder(request, builder);
    for (var element in namespace.definedNames.values) {
      element.accept(visitor);
    }
  }
}
