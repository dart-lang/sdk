// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';

/// The context in which a refactoring was requested.
class RefactoringContext {
  final LspAnalysisServer server;

  /// The result of resolving the compilation unit in which a refactoring was
  /// requested.
  final ResolvedUnitResult resolvedResult;

  /// The offset to the beginning of the selection range.
  final int selectionOffset;

  /// The number of selected characters.
  final int selectionLength;

  /// The helper used to efficiently access resolved units.
  late final AnalysisSessionHelper sessionHelper =
      AnalysisSessionHelper(session);

  /// Initialize a newly created context based on the [resolvedResult].
  RefactoringContext({
    required this.server,
    required this.resolvedResult,
    required this.selectionOffset,
    required this.selectionLength,
  });

  /// Return the analysis session in which additional resolution can occur.
  AnalysisSession get session => resolvedResult.session;
}
