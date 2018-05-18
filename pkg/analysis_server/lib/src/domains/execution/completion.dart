// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    show
        CompletionSuggestion,
        RuntimeCompletionExpression,
        RuntimeCompletionVariable,
        SourceEdit;
import 'package:analysis_server/src/provisional/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_core.dart';
import 'package:analysis_server/src/services/completion/completion_performance.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';

class RuntimeCompletionComputer {
  final ResourceProvider resourceProvider;
  final FileContentOverlay fileContentOverlay;
  final AnalysisDriver analysisDriver;

  final String code;
  final int offset;

  final String contextFile;
  final int contextOffset;

  final List<RuntimeCompletionVariable> variables;
  final List<RuntimeCompletionExpression> expressions;

  AnalysisSession session;
  _Context context;

  RuntimeCompletionComputer(
      this.resourceProvider,
      this.fileContentOverlay,
      this.analysisDriver,
      this.code,
      this.offset,
      this.contextFile,
      this.contextOffset,
      this.variables,
      this.expressions);

  Future<RuntimeCompletionResult> compute() async {
    var pathContext = resourceProvider.pathContext;
    var contextDir = pathContext.dirname(contextFile);
    var targetPath = pathContext.join(contextDir, '_runtimeCompletion.dart');

    // TODO(scheglov) Use variables.
    await _initContext();

    String baseTargetCode = r'''
library _runtimeCompletion;
''';
    fileContentOverlay[targetPath] = baseTargetCode;

    const codeMarker = '__code__';

    // Build the target code that provides the same context.
    var changeBuilder = new DartChangeBuilder(session);
    int nextImportPrefixIndex = 0;
    await changeBuilder.addFileEdit(targetPath, (builder) {
      builder.addInsertion(baseTargetCode.length, (builder) {
        builder.writeln('main() {');
        // Write all visible local declarations.
        for (var local in context.locals.values) {
          builder.writeLocalVariableDeclaration(local.name, type: local.type);
          builder.writeln();
        }

        // Write the marker to insert the code being completed.
        builder.write(codeMarker);

        // Finalize main().
        builder.writeln(';');
        builder.writeln('}');
      });
    }, importPrefixGenerator: (uri) => '__prefix${nextImportPrefixIndex++}');

    // Compute the target code.
    List<SourceEdit> targetEdits = changeBuilder.sourceChange.edits[0].edits;
    String targetCode = SourceEdit.applySequence(baseTargetCode, targetEdits);

    // Insert the code being completed.
    int targetOffset = targetCode.indexOf(codeMarker) + offset;
    targetCode = targetCode.replaceAll(codeMarker, code);

    // Resolve the constructed target file.
    AnalysisResult targetResult;
    try {
      fileContentOverlay[targetPath] = targetCode;
      analysisDriver.changeFile(targetPath);
      targetResult = await analysisDriver.getResult(targetPath);
    } finally {
      fileContentOverlay[targetPath] = null;
      analysisDriver.changeFile(targetPath);
    }

    CompletionContributor contributor = new DartCompletionManager();
    // TODO(scheglov) Stop requiring Source, it has it in AnalysisResult.
    CompletionRequestImpl request = new CompletionRequestImpl(
      targetResult,
      resourceProvider,
      targetResult.unit.element.source,
      targetOffset,
      new CompletionPerformance(),
    );
    var suggestions = await contributor.computeSuggestions(request);

    // TODO(scheglov) Add support for expressions.
    var expressions = <RuntimeCompletionExpression>[];
    return new RuntimeCompletionResult(expressions, suggestions);
  }

  Future<void> _initContext() async {
    var contextResult = await analysisDriver.getResult(contextFile);
    session = contextResult.session;
    context = new _Context(contextResult.unit, contextOffset);
  }
}

/// The result of performing runtime completion.
class RuntimeCompletionResult {
  final List<RuntimeCompletionExpression> expressions;
  final List<CompletionSuggestion> suggestions;

  RuntimeCompletionResult(this.expressions, this.suggestions);
}

/// The context in which completion is performed.
class _Context {
  final int contextOffset;

  ClassElement enclosingClass;
  Map<String, VariableElement> locals = {};

  _Context(CompilationUnit unit, this.contextOffset) {
    var node = new NodeLocator2(contextOffset).searchWithin(unit);

    var enclosingClass = node.getAncestor((n) => n is ClassDeclaration);
    if (enclosingClass is ClassDeclaration) {
      this.enclosingClass = enclosingClass.element;
    }

    _appendLocals(node);
  }

  void _appendLocals(AstNode node) {
    if (node is Block) {
      for (var statement in node.statements) {
        if (statement.offset > contextOffset) {
          break;
        }
        if (statement is VariableDeclarationStatement) {
          for (var variable in statement.variables.variables) {
            VariableElement element = variable.element;
            locals[element.name] ??= element;
          }
        }
      }
    } else if (node is ClassDeclaration) {
      // TODO(scheglov) implement, maybe not locals anymore
      return;
    } else if (node is CompilationUnit) {
      return;
    } else if (node is FunctionDeclaration) {
      _appendParameters(node.functionExpression.parameters);
    } else if (node is MethodDeclaration) {
      _appendParameters(node.parameters);
    }
    _appendLocals(node.parent);
  }

  void _appendParameters(FormalParameterList parameters) {
    if (parameters != null) {
      for (var parameter in parameters.parameters) {
        VariableElement element = parameter.element;
        locals[element.name] ??= element;
      }
    }
  }
}
