// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/snippets/dart/class_declaration.dart';
import 'package:analysis_server/src/services/snippets/dart/do_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateful_widget.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateful_widget_with_animation.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_stateless_widget.dart';
import 'package:analysis_server/src/services/snippets/dart/for_in_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/for_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/function_declaration.dart';
import 'package:analysis_server/src/services/snippets/dart/if_else_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/if_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/main_function.dart';
import 'package:analysis_server/src/services/snippets/dart/switch_expression.dart';
import 'package:analysis_server/src/services/snippets/dart/switch_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/test_definition.dart';
import 'package:analysis_server/src/services/snippets/dart/test_group_definition.dart';
import 'package:analysis_server/src/services/snippets/dart/try_catch_statement.dart';
import 'package:analysis_server/src/services/snippets/dart/while_statement.dart';
import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_context.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;

typedef SnippetProducerGenerator = SnippetProducer Function(DartSnippetRequest,
    {required Map<Element2, LibraryElement2?> elementImportCache});

/// [DartSnippetManager] determines if a snippet request is Dart specific
/// and forwards those requests to all Snippet Producers that return `true` from
/// their `isValid()` method.
class DartSnippetManager {
  final producerGenerators =
      const <SnippetContext, List<SnippetProducerGenerator>>{
    SnippetContext.atTopLevel: [
      ClassDeclaration.new,
      FlutterStatefulWidget.new,
      FlutterStatefulWidgetWithAnimationController.new,
      FlutterStatelessWidget.new,
      FunctionDeclaration.new,
      MainFunction.new,
    ],
    SnippetContext.inBlock: [
      DoStatement.new,
      ForInStatement.new,
      ForStatement.new,
      FunctionDeclaration.new,
      IfElseStatement.new,
      IfStatement.new,
      SwitchStatement.new,
      TestDefinition.new,
      TestGroupDefinition.new,
      TryCatchStatement.new,
      WhileStatement.new,
    ],
    SnippetContext.inClass: [
      FunctionDeclaration.new,
    ],
    SnippetContext.inExpression: [
      SwitchExpression.new,
    ],
  };

  Future<List<Snippet>> computeSnippets(
    DartSnippetRequest request, {
    bool Function(String input)? filter,
  }) async {
    var pathContext = request.resourceProvider.pathContext;
    if (!file_paths.isDart(pathContext, request.filePath)) {
      return const [];
    }

    try {
      var snippets = <Snippet>[];
      var generators = producerGenerators[request.context];
      if (generators == null) {
        return snippets;
      }
      var elementImportCache = <Element2, LibraryElement2?>{};
      for (var generator in generators) {
        var producer =
            generator(request, elementImportCache: elementImportCache);
        var matchesFilter = filter?.call(producer.snippetPrefix) ?? true;
        if (matchesFilter && await producer.isValid()) {
          snippets.add(await producer.compute());
        }
      }
      return snippets;
    } on InconsistentAnalysisException {
      // The state of the code being analyzed has changed, so results are likely
      // to be inconsistent. Just abort the operation.
      throw AbortCompletion();
    }
  }
}
