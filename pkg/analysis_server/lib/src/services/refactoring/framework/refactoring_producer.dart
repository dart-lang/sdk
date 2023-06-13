// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// An object that can compute a refactoring in a Dart file.
abstract class RefactoringProducer {
  /// The context in which the refactoring was requested.
  final RefactoringContext _context;

  /// Initialize a newly created refactoring producer to create a refactoring in
  /// the given [_context].
  RefactoringProducer(this._context);

  /// The most deeply nested node whose range completely includes the range of
  /// characters described by [selectionOffset] and [selectionLength].
  AstNode? get coveringNode => _context.coveringNode;

  /// Return whether this refactor is considered experimental and will only
  /// be included if the user has opted-in.
  bool get isExperimental;

  /// Return the kind of refactoring this producer produces. Subclasses should
  /// override this method if they produce a subtype of the type
  /// [CodeActionKind.Refactor], such as [CodeActionKind.RefactorExtract],
  /// [CodeActionKind.RefactorInline], or [CodeActionKind.RefactorRewrite].
  CodeActionKind get kind => CodeActionKind.Refactor;

  /// Return the result of resolving the library in which the refactoring was
  /// invoked.
  ResolvedLibraryResult get libraryResult => _context.resolvedLibraryResult;

  /// Return a list of the parameters to send to the client.
  List<CommandParameter> get parameters;

  RefactoringContext get refactoringContext => _context;

  /// Return the search engine used to search outside the resolved library.
  SearchEngine get searchEngine => _context.searchEngine;

  /// Return the selection, or `null` if the selection is not valid.
  Selection? get selection => _context.selection;

  /// Return the offset of the first character after the selection range.
  int get selectionEnd => _context.selectionEnd;

  /// Return the number of selected characters.
  int get selectionLength => _context.selectionLength;

  /// Return the offset of the beginning of the selection range.
  int get selectionOffset => _context.selectionOffset;

  /// Return the helper used to efficiently access resolved units.
  AnalysisSessionHelper get sessionHelper => _context.sessionHelper;

  /// Return `true` if the client has support for creating files. Subclasses
  /// that require the ability to create new files must not create a refactoring
  /// if this getter returns `false`.
  bool get supportsFileCreation =>
      _context.server.clientCapabilities?.documentChanges == true &&
      _context.server.clientCapabilities?.createResourceOperations == true;

  /// Return the title of this refactoring.
  String get title;

  /// Return the result of resolving the file in which the refactoring was
  /// invoked.
  ResolvedUnitResult get unitResult => _context.resolvedUnitResult;

  /// Return the correction utilities for this refactoring.
  CorrectionUtils get utils => _context.utils;

  /// Given the [commandArguments] associated with the command, use the
  /// [builder] to generate the edits necessary to apply this refactoring.
  Future<void> compute(List<Object?> commandArguments, ChangeBuilder builder);

  /// Return `true` if this refactoring is available in the given context.
  Future<bool> isAvailable();

  /// Return `true` if the selection is inside the given [token].
  bool selectionIsInToken(Token? token) => _context.selectionIsInToken(token);

  /// Return `true` if the client has support for command parameters of the
  /// provided `kind`. Subclasses that produce command parameters of this kind
  /// that don't have a default value must not create a refactoring if this
  /// returns `false`.
  bool supportsCommandParameter(String kind) =>
      _context
          .server.clientCapabilities?.codeActionCommandParameterSupportedKinds
          .contains(kind) ??
      false;
}
