// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';

/// The context in which a refactoring was requested.
class AbstractRefactoringContext {
  /// Return the search engine used to search outside the resolved library.
  final SearchEngine searchEngine;

  /// The sessions at the start of the refactoring.
  final List<AnalysisSession> startSessions;

  /// The result of resolving the library in which a refactoring was requested.
  final ResolvedLibraryResult resolvedLibraryResult;

  /// The result of resolving the compilation unit in which a refactoring was
  /// requested. This will always be one of the `units` from the
  /// [resolvedLibraryResult].
  final ResolvedUnitResult resolvedUnitResult;

  /// The offset to the beginning of the selection range.
  final int selectionOffset;

  /// The number of selected characters.
  final int selectionLength;

  /// Whether to include refactors marked as experimental.
  final bool includeExperimental;

  /// Utilities available to be used in the process of computing the edits.
  late final CorrectionUtils utils = CorrectionUtils(resolvedUnitResult);

  /// The selection, or `null` if the selection is not valid.
  late final Selection? selection = resolvedUnitResult.unit
      .select(offset: selectionOffset, length: selectionLength);

  /// Capabilities of the client that will handle the edits resulting from this
  /// refactor.
  final LspClientCapabilities? clientCapabilities;

  /// The helper used to efficiently access resolved units.
  late final AnalysisSessionHelper sessionHelper =
      AnalysisSessionHelper(session);

  /// The change workspace associated with this refactoring.
  late final ChangeWorkspace workspace = DartChangeWorkspace(startSessions);

  /// Initialize a newly created refactoring context.
  AbstractRefactoringContext({
    required this.searchEngine,
    required this.startSessions,
    required this.resolvedLibraryResult,
    required this.resolvedUnitResult,
    required this.clientCapabilities,
    required this.selectionOffset,
    required this.selectionLength,
    required this.includeExperimental,
  });

  /// The most deeply nested node whose range completely includes the range of
  /// characters described by [selectionOffset] and [selectionLength].
  AstNode? get coveringNode => selection?.coveringNode;

  /// Return the offset of the first character after the selection range.
  int get selectionEnd => selectionOffset + selectionLength;

  /// Returns the selection range.
  SourceRange get selectionRange =>
      SourceRange(selectionOffset, selectionLength);

  /// Return the analysis session in which additional resolution can occur.
  AnalysisSession get session => resolvedUnitResult.session;

  /// Return `true` if the selection is inside the given [token].
  bool selectionIsInToken(Token? token) =>
      token != null &&
      selectionOffset >= token.offset &&
      selectionEnd <= token.end;
}

/// The context in which a refactoring was requested.
class RefactoringContext extends AbstractRefactoringContext {
  final LspAnalysisServer server;

  /// Initialize a newly created refactoring context.
  RefactoringContext({
    required this.server,
    required super.startSessions,
    required super.resolvedLibraryResult,
    required super.resolvedUnitResult,
    required super.clientCapabilities,
    required super.selectionOffset,
    required super.selectionLength,
    required super.includeExperimental,
  }) : super(
          searchEngine: server.searchEngine,
        );
}
