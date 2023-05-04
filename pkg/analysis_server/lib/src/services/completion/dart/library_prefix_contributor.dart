// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// A contributor that produces suggestions based on the prefixes defined on
/// import directives.
class LibraryPrefixContributor extends DartCompletionContributor {
  LibraryPrefixContributor(super.request, super.builder);

  @override
  Future<void> computeSuggestions({
    required OperationPerformanceImpl performance,
  }) async {
    if (!request.includeIdentifiers) {
      return;
    }

    var imports = request.libraryElement.libraryImports;
    for (var element in imports) {
      var prefix = element.prefix?.element.name;
      if (prefix != null && prefix.isNotEmpty) {
        var libraryElement = element.importedLibrary;
        if (libraryElement != null) {
          builder.suggestPrefix(libraryElement, prefix);
        }
      }
    }
  }
}
