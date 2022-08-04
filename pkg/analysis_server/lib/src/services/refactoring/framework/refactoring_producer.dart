// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// An object that can compute a refactoring in a Dart file.
abstract class RefactoringProducer {
  /// The context in which the refactoring was requested.
  final RefactoringContext _context;

  /// Initialize a newly created refactoring producer to create a refactoring in
  /// the given [_context].
  RefactoringProducer(this._context);

  /// Return the command name used to apply this refactoring.
  String get commandName;

  /// Return the kind of refactoring this producer produces. Subclasses should
  /// override this method if they produce a subtype of the type
  /// [CodeActionKind.Refactor], such as [CodeActionKind.RefactorExtract],
  /// [CodeActionKind.RefactorInline], or [CodeActionKind.RefactorRewrite].
  CodeActionKind get kind => CodeActionKind.Refactor;

  /// Return a list of the parameters to send to the client.
  List<CommandParameter> get parameters;

  /// Return the offset of the first character after the selection range.
  int get selectionEnd => selectionOffset + selectionLength;

  /// Return the number of selected characters.
  int get selectionLength => _context.selectionLength;

  /// Return the offset of the beginning of the selection range.
  int get selectionOffset => _context.selectionOffset;

  /// Return the helper used to efficiently access resolved units.
  AnalysisSessionHelper get sessionHelper => _context.sessionHelper;

  /// Return the title of this refactoring.
  String get title;

  /// Given the [commandArguments] associated with the command, use the
  /// [builder] to generate the edits necessary to apply this refactoring.
  Future<void> compute(List<String> commandArguments, ChangeBuilder builder);

  /// Return `true` if this refactoring is available in the given context.
  bool isAvailable();
}
