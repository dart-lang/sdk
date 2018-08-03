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
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
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
    // TODO(brianwilkerson) Determine whether this await is necessary.
    await null;
    var contextResult = await analysisDriver.getResult(contextFile);
    var session = contextResult.session;

    const codeMarker = '__code_\_';

    // Insert the code being completed at the context offset.
    var changeBuilder = new DartChangeBuilder(session);
    int nextImportPrefixIndex = 0;
    await changeBuilder.addFileEdit(contextFile, (builder) {
      builder.addInsertion(contextOffset, (builder) {
        builder.writeln('{');

        // TODO(scheglov) Use variables.

        builder.write(codeMarker);
        builder.writeln(';');

        builder.writeln('}');
      });
    }, importPrefixGenerator: (uri) => '__prefix${nextImportPrefixIndex++}');

    // Compute the patched context file content.
    String targetCode = SourceEdit.applySequence(
      contextResult.content,
      changeBuilder.sourceChange.edits[0].edits,
    );

    // Insert the code being completed.
    int targetOffset = targetCode.indexOf(codeMarker) + offset;
    targetCode = targetCode.replaceAll(codeMarker, code);

    // Update the context file content to include the code being completed.
    // Then resolve it, and restore the file to its initial state.
    AnalysisResult targetResult;
    String contentFileOverlay = fileContentOverlay[contextFile];
    try {
      fileContentOverlay[contextFile] = targetCode;
      analysisDriver.changeFile(contextFile);
      targetResult = await analysisDriver.getResult(contextFile);
    } finally {
      fileContentOverlay[contextFile] = contentFileOverlay;
      analysisDriver.changeFile(contextFile);
    }

    CompletionContributor contributor = new DartCompletionManager();
    CompletionRequestImpl request = new CompletionRequestImpl(
      targetResult,
      targetOffset,
      new CompletionPerformance(),
    );
    var suggestions = await contributor.computeSuggestions(request);

    // Remove completions with synthetic import prefixes.
    suggestions.removeWhere((s) => s.completion.startsWith('__prefix'));

    // TODO(scheglov) Add support for expressions.
    var expressions = <RuntimeCompletionExpression>[];
    return new RuntimeCompletionResult(expressions, suggestions);
  }
}

/// The result of performing runtime completion.
class RuntimeCompletionResult {
  final List<RuntimeCompletionExpression> expressions;
  final List<CompletionSuggestion> suggestions;

  RuntimeCompletionResult(this.expressions, this.suggestions);
}
