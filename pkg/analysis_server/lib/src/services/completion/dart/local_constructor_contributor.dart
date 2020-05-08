// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show CompletionSuggestion;
import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// A contributor that produces suggestions based on the constructors declared
/// in the same file in which suggestions were requested.
class LocalConstructorContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request, SuggestionBuilder builder) async {
    var opType = request.opType;
    if (!opType.isPrefixed && opType.includeConstructorSuggestions) {
      var unit = request.target.unit;
      // TODO(brianwilkerson) Consider iterating over
      //  `unit.declaredElement.types` instead.
      for (var declaration in unit.declarations) {
        if (declaration is ClassDeclaration) {
          var classElement = declaration.declaredElement;
          if (classElement != null) {
            for (var constructor in classElement.constructors) {
              if (!classElement.isAbstract || constructor.isFactory) {
                builder.suggestConstructor(constructor);
              }
            }
          }
        }
      }
    }
    return const <CompletionSuggestion>[];
  }
}
