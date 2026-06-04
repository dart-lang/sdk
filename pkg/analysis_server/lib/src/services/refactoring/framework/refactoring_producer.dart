// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/extensions/list.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The status of running [RefactoringProducer.compute].
sealed class ComputeStatus {}

/// The supertype for any failure inside [RefactoringProducer.compute].
class ComputeStatusFailure extends ComputeStatus {
  final String? reason;

  new({this.reason});
}

/// The result that signals the success.
class ComputeStatusSuccess extends ComputeStatus {}

/// A version of [RefactoringProducer] that has parameters, allowing the user
/// to provide additional values (such as a name or target file) when executed.
abstract class ParameterizedRefactoringProducer extends RefactoringProducer {
  new(super.refactoringContext);

  /// Return a list of the parameters to send to the client.
  List<CommandParameter> get parameters;

  /// A convenience wrapper around [RefactoringProcessor.buildCommandArguments].
  List<Object?> buildCommandArguments(List<Object?> args) {
    return RefactoringProcessor.buildCommandArguments(refactoringContext, args);
  }

  /// Builds the interative form for this refactor.
  ErrorOr<InteractiveForm> buildInteractiveForm();

  /// A helper to create an [InteractiveForm] with client capabilities.
  InteractiveForm createForm(List<FormField> fields) {
    var supportedInteractiveFormInputTypes =
        refactoringContext
            .clientCapabilities
            ?.supportedInteractiveFormInputTypes ??
        {};

    return InteractiveForm(
      supportedInteractiveFormInputTypes: supportedInteractiveFormInputTypes,
      fields: fields,
    );
  }

  /// Resolves the command used for invoking this refactor by calling
  /// [buildInteractiveForm] to build the interactive form.
  Future<ErrorOr<InteractiveExecuteCommandParams>> resolve(
    InteractiveExecuteCommandParams command,
  ) async {
    var commandArguments = command.arguments;
    if (commandArguments == null) {
      return error(
        ErrorCodes.InvalidParams,
        'Refactor commands must have arguments',
      );
    }

    return buildInteractiveForm().mapResultSync((form) {
      form.processResponse(command.formAnswers ?? []);

      return success(
        InteractiveExecuteCommandParams(
          command: command.command,
          arguments: buildCommandArguments(form.answers),
          data: command.data,
          formFields: form.clientFields.nullIfEmpty,
          formAnswers: form.clientAnswers.nullIfEmpty,
        ),
      );
    });
  }

  /// Wraps a refactor validation function that returns [RefactoringStatus]
  /// to return a String error message if there are fatal errors, matching the
  /// validation of Interactive Forms.
  String? Function(Object? value) wrapRefactorValidationFunction<T>(
    RefactoringStatus Function(T name) validator,
  ) {
    return (Object? value) {
      var result = validator(value as T);
      if (result.hasFatalError) {
        return result.message ?? 'invalid value';
      }
      return null;
    };
  }
}

/// An object that can compute a refactoring in a Dart file.
abstract class RefactoringProducer {
  /// The context in which the refactoring was requested.
  final RefactoringContext refactoringContext;

  /// Initialize a newly created refactoring producer.
  new(this.refactoringContext);

  /// The most deeply nested node whose range completely includes the range of
  /// characters described by [selectionOffset] and [selectionLength].
  AstNode? get coveringNode => refactoringContext.coveringNode;

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
  ResolvedLibraryResult get libraryResult {
    return refactoringContext.resolvedLibraryResult;
  }

  /// Return the search engine used to search outside the resolved library.
  SearchEngine get searchEngine => refactoringContext.searchEngine;

  /// Return the selection, or `null` if the selection is not valid.
  Selection? get selection => refactoringContext.selection;

  /// Return the offset of the first character after the selection range.
  int get selectionEnd => refactoringContext.selectionEnd;

  /// Return the number of selected characters.
  int get selectionLength => refactoringContext.selectionLength;

  /// Return the offset of the beginning of the selection range.
  int get selectionOffset => refactoringContext.selectionOffset;

  /// Return the helper used to efficiently access resolved units.
  AnalysisSessionHelper get sessionHelper => refactoringContext.sessionHelper;

  /// Return `true` if the client has support for creating files. Subclasses
  /// that require the ability to create new files must not create a refactoring
  /// if this getter returns `false`.
  bool get supportsFileCreation {
    var capabilities = refactoringContext.clientCapabilities;
    return capabilities != null &&
        capabilities.documentChanges &&
        capabilities.createResourceOperations;
  }

  /// Return the title of this refactoring.
  String get title;

  /// Return the result of resolving the file in which the refactoring was
  /// invoked.
  ResolvedUnitResult get unitResult => refactoringContext.resolvedUnitResult;

  /// Return the correction utilities for this refactoring.
  CorrectionUtils get utils => refactoringContext.utils;

  /// Given the [commandArguments] associated with the command, use the
  /// [builder] to generate the edits necessary to apply this refactoring.
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  );

  /// Return `true` if this refactoring is available in the given context.
  bool isAvailable();

  /// Return `true` if the selection is inside the given [token].
  bool selectionIsInToken(Token? token) {
    return refactoringContext.selectionIsInToken(token);
  }
}
