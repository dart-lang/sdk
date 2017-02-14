// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/protocol/protocol.dart' as server;
import 'package:analysis_server/src/protocol/protocol_internal.dart' as server;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;

/**
 * An object used to convert between similar objects defined by both the plugin
 * protocol and the server protocol.
 */
class ResultConverter {
  /**
   * The decoder used to decode Json representations of server objects.
   */
  static final server.ResponseDecoder decoder =
      new server.ResponseDecoder(null);

  server.AnalysisError convertAnalysisError(plugin.AnalysisError error) {
    return new server.AnalysisError.fromJson(decoder, '', error.toJson());
  }

  server.AnalysisErrorFixes convertAnalysisErrorFixes(
      plugin.AnalysisErrorFixes fixes) {
    List<server.SourceChange> changes = fixes.fixes
        .map((plugin.PrioritizedSourceChange change) =>
            convertPrioritizedSourceChange(change))
        .toList();
    return new server.AnalysisErrorFixes(convertAnalysisError(fixes.error),
        fixes: changes);
  }

  server.AnalysisNavigationParams convertAnalysisNavigationParams(
      plugin.AnalysisNavigationParams params) {
    return new server.AnalysisNavigationParams.fromJson(
        decoder, '', params.toJson());
  }

  server.CompletionSuggestion convertCompletionSuggestion(
      plugin.CompletionSuggestion suggestion) {
    return new server.CompletionSuggestion.fromJson(
        decoder, '', suggestion.toJson());
  }

  server.EditGetRefactoringResult convertEditGetRefactoringResult(
      plugin.RefactoringKind kind, plugin.EditGetRefactoringResult result) {
    return new server.EditGetRefactoringResult.fromJson(
        new server.ResponseDecoder(convertRefactoringKind(kind)),
        '',
        result.toJson());
  }

  server.FoldingRegion convertFoldingRegion(plugin.FoldingRegion region) {
    return new server.FoldingRegion.fromJson(decoder, '', region.toJson());
  }

  server.HighlightRegion convertHighlightRegion(plugin.HighlightRegion region) {
    return new server.HighlightRegion.fromJson(decoder, '', region.toJson());
  }

  server.Occurrences convertOccurrences(plugin.Occurrences occurrences) {
    return new server.Occurrences.fromJson(decoder, '', occurrences.toJson());
  }

  server.Outline convertOutline(plugin.Outline outline) {
    return new server.Outline.fromJson(decoder, '', outline.toJson());
  }

  server.SourceChange convertPrioritizedSourceChange(
      plugin.PrioritizedSourceChange change) {
    return convertSourceChange(change.change);
  }

  server.RefactoringFeedback convertRefactoringFeedback(
      plugin.RefactoringKind kind, plugin.RefactoringFeedback feedback) {
    return new server.RefactoringFeedback.fromJson(
        new server.ResponseDecoder(convertRefactoringKind(kind)),
        '',
        feedback.toJson(),
        null);
  }

  server.RefactoringKind convertRefactoringKind(
      plugin.RefactoringKind feedback) {
    return new server.RefactoringKind.fromJson(decoder, '', feedback.toJson());
  }

  server.SourceChange convertSourceChange(plugin.SourceChange change) {
    return new server.SourceChange.fromJson(decoder, '', change.toJson());
  }
}
