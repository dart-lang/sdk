// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/services/interactive_forms/interactive_forms.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/extensions/selection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The refactoring that adds a name to an unnamed constructor.
class AddConstructorName extends ParameterizedRefactoringProducer {
  static const String commandName = 'dart.refactor.add_constructor_name';

  static const String constTitle = 'Add a name to the constructor';

  new(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => DartCodeActionKind.refactorAdd;

  @override
  /// This refactor supports input using the new system (see
  /// [buildInteractiveForm]) but not using the old one, so there are no
  /// parameters.
  List<CommandParameter> get parameters => [];

  @override
  String get title => constTitle;

  /// Builds the [InteractiveForm] to collect input for this refactor.
  @override
  ErrorOr<InteractiveForm> buildInteractiveForm() {
    var element = selection?.constructor(mustNotHaveName: true);
    if (element == null) {
      // We shouldn't have gotten here if the selection was not valid for this
      // refactor, but return a useful error to aid debugging if so.
      return error(
        ErrorCodes.InvalidParams,
        'The selection is not valid for adding a constructor name',
      );
    }

    var nameField = ValidatableFormField(
      id: 'name',
      description: 'Constructor Name',
      required: true,
      defaultValue: _computeName(element),
      type: FormFieldTypeString(),
      validate: wrapRefactorValidationFunction(validateConstructorName),
    );

    return success(createForm([nameField]));
  }

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    // Handle optional name in the arguments (if Interactive Forms were used).
    var constructorName = switch (commandArguments) {
      [String name] => name,
      _ => null,
    };

    var element = selection?.constructor(mustNotHaveName: true);
    if (element == null) {
      // This should never happen because `isAvailable` would have returned
      // `false`, so this method wouldn't have been called.
      return ComputeStatusFailure();
    }

    var refactoring = _createRefactoring(element);
    if (refactoring == null) {
      return ComputeStatusFailure();
    }
    constructorName ??= _computeName(element);
    refactoring.newName = constructorName;
    var status = await refactoring.checkAllConditions();
    if (status.hasError) {
      return ComputeStatusFailure();
    }
    await refactoring.createChange(builder: builder);
    return ComputeStatusSuccess();
  }

  @override
  bool isAvailable() {
    return selection?.constructor(mustNotHaveName: true) != null;
  }

  /// Compute a name for the new constructor.
  String _computeName(ConstructorElement element) {
    var enclosingElement = element.enclosingElement;
    var usedNames = <String>{};
    usedNames.addAll(enclosingElement.constructors.map((c) => c.name ?? ''));
    usedNames.addAll(enclosingElement.methods.map((m) => m.name ?? ''));
    usedNames.addAll(enclosingElement.fields.map((f) => f.name ?? ''));
    var candidate = 'name';
    var index = 1;
    while (usedNames.contains(candidate)) {
      candidate = 'name$index';
      index++;
    }
    return candidate;
  }

  RenameRefactoring? _createRefactoring(ConstructorElement element) {
    var analysisContext = libraryResult.session.analysisContext;
    if (analysisContext is! DriverBasedAnalysisContext) {
      return null;
    }
    var driver = analysisContext.driver;
    var searchEngine = SearchEngineImpl([driver]);
    return RenameRefactoring.create(
      RefactoringWorkspace([driver], searchEngine),
      unitResult,
      element,
    );
  }
}
