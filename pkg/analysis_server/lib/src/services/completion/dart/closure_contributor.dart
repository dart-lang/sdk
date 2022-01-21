// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';

/// A contributor that produces a closure matching the context type.
class ClosureContributor extends DartCompletionContributor {
  ClosureContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) : super(request, builder);

  bool get _isArgument {
    var node = request.target.containingNode;
    return node is ArgumentList || node is NamedExpression;
  }

  @override
  Future<void> computeSuggestions() async {
    var contextType = request.contextType;
    if (contextType is FunctionType) {
      builder.suggestClosure(
        contextType,
        includeTrailingComma: _isArgument && !request.target.isFollowedByComma,
      );
    }
  }
}
