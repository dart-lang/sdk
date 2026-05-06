// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/extensions/selection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

/// The refactoring that removes a prefix from an import directive.
class RemoveImportPrefix extends RefactoringProducer {
  static const String commandName = 'dart.refactor.remove_import_prefix';

  static const String constTitle = 'Remove the prefix from the import';

  RemoveImportPrefix(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => DartCodeActionKind.refactorRemove;

  @override
  List<CommandParameter> get parameters => const <CommandParameter>[];

  @override
  String get title => constTitle;

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var element = selection?.importDirective(mustHavePrefix: true);
    if (element == null) {
      // This should never happen because `isAvailable` would have returned
      // `false`, so this method wouldn't have been called.
      return ComputeStatusFailure();
    }

    var refactoring = _createRefactoring(element);
    if (refactoring == null) {
      return ComputeStatusFailure();
    }
    refactoring.newName = '';
    var status = await refactoring.checkAllConditions();
    if (status.hasError) {
      return ComputeStatusFailure();
    }
    await refactoring.createChange(builder: builder);
    return ComputeStatusSuccess();
  }

  @override
  bool isAvailable() {
    var import = selection?.importDirective(
      mustHavePrefix: true,
      mustNotBeDeferred: true,
    );
    return import != null;
  }

  RenameRefactoring? _createRefactoring(LibraryImport import) {
    var analysisContext = libraryResult.session.analysisContext;
    if (analysisContext is! DriverBasedAnalysisContext) {
      return null;
    }
    var driver = analysisContext.driver;
    var searchEngine = SearchEngineImpl([driver]);
    return RenameRefactoring.create(
      RefactoringWorkspace([driver], searchEngine),
      unitResult,
      MockLibraryImportElement(import),
    );
  }
}
