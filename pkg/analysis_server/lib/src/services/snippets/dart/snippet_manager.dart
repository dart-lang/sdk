// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/snippets/dart/flutter_snippet_producers.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

typedef SnippetProducerGenerator = SnippetProducer Function(DartSnippetRequest);

/// [DartSnippetManager] determines if a snippet request is Dart specific
/// and forwards those requests to all Snippet Producers that return `true` from
/// their `isValid()` method.
class DartSnippetManager {
  final producerGenerators =
      const <SnippetContext, List<SnippetProducerGenerator>>{
    SnippetContext.atTopLevel: [
      FlutterStatefulWidgetSnippetProducer.newInstance,
      FlutterStatefulWidgetWithAnimationControllerSnippetProducer.newInstance,
      FlutterStatelessWidgetSnippetProducer.newInstance,
    ]
  };

  Future<List<Snippet>> computeSnippets(
    DartSnippetRequest request,
  ) async {
    var pathContext = request.resourceProvider.pathContext;
    if (!file_paths.isDart(pathContext, request.filePath)) {
      return const [];
    }

    try {
      final snippets = <Snippet>[];
      final generators = producerGenerators[request.context];
      if (generators == null) {
        return snippets;
      }
      for (final generator in generators) {
        final producer = generator(request);
        if (await producer.isValid()) {
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

/// The information about a request for a list of snippets within a Dart file.
class DartSnippetRequest {
  /// The resolved unit for the file that snippets are being requested for.
  final ResolvedUnitResult unit;

  /// The path of the file snippets are being requested for.
  final String filePath;

  /// The offset within the source at which snippets are being
  /// requested for.
  final int offset;

  /// The context in which the snippet request is being made.
  late final SnippetContext context;

  /// The source range that represents the region of text that should be
  /// replaced if the snippet is selected.
  late final SourceRange replacementRange;

  DartSnippetRequest({
    required this.unit,
    required this.offset,
  }) : filePath = unit.path {
    final target = CompletionTarget.forOffset(unit.unit, offset);
    context = _getContext(target);
    replacementRange = target.computeReplacementRange(offset);
  }

  /// The analysis session that produced the elements of the request.
  AnalysisSession get analysisSession => unit.session;

  /// The resource provider associated with this request.
  ResourceProvider get resourceProvider => analysisSession.resourceProvider;

  static SnippetContext _getContext(CompletionTarget target) {
    final entity = target.entity;
    if (entity is Token) {
      final tokenType = (entity.beforeSynthetic ?? entity).type;

      if (tokenType == TokenType.MULTI_LINE_COMMENT ||
          tokenType == TokenType.SINGLE_LINE_COMMENT) {
        return SnippetContext.inComment;
      }

      if (tokenType == TokenType.STRING ||
          tokenType == TokenType.STRING_INTERPOLATION_EXPRESSION ||
          tokenType == TokenType.STRING_INTERPOLATION_IDENTIFIER) {
        return SnippetContext.inString;
      }
    }

    AstNode? node = target.containingNode;
    while (node != null) {
      if (node is Comment) {
        return SnippetContext.inComment;
      }

      if (node is StringLiteral) {
        return SnippetContext.inString;
      }

      if (node is Block) {
        return SnippetContext.inBlock;
      }

      if (node is Statement || node is Expression || node is Annotation) {
        return SnippetContext.inExpressionOrStatement;
      }

      if (node is BlockFunctionBody) {
        return SnippetContext.inBlock;
      }

      if (node is ClassOrMixinDeclaration || node is ExtensionDeclaration) {
        return SnippetContext.inClass;
      }

      node = node.parent;
    }

    return SnippetContext.atTopLevel;
  }
}

class Snippet {
  /// The text the user will type to use this snippet.
  final String prefix;

  /// The label/title of this snippet.
  final String label;

  /// A description of/documentation for the snippet.
  final String? documentation;

  /// The source changes to be made to insert this snippet.
  final SourceChange change;

  Snippet(
    this.prefix,
    this.label,
    this.documentation,
    this.change,
  );
}

/// The context in which a snippet request was made.
///
/// This is used to filter the available snippets (for example preventing
/// snippets that create classes showing up when inside an existing class or
/// function body).
enum SnippetContext {
  atTopLevel,
  inClass,
  inBlock,
  inExpressionOrStatement,
  inComment,
  inString,
}

abstract class SnippetProducer {
  final DartSnippetRequest request;

  SnippetProducer(this.request);

  Future<Snippet> compute();

  Future<bool> isValid();
}
