// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';

/// A contributor that produces suggestions based on the prefixes defined on
/// import directives.
class LibraryPrefixContributor extends DartCompletionContributor {
  @override
  Future<void> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    if (!request.includeIdentifiers) {
      return;
    }

    var imports = request.libraryElement.imports;
    if (imports == null) {
      return;
    }

    for (var element in imports) {
      var prefix = element.prefix?.name;
      if (prefix != null && prefix.isNotEmpty) {
        var libraryElement = element.importedLibrary;
        if (libraryElement != null) {
          builder.suggestPrefix(libraryElement, prefix);
        }
      }
    }
  }
}
