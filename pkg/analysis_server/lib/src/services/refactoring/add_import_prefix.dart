// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Keyword;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analysis_server/src/utilities/extensions/selection.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source.dart' show Source;
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:path/path.dart' as path;

/// The refactoring that adds a prefix to an import directive.
class AddImportPrefix extends RefactoringProducer {
  static const String commandName = 'dart.refactor_add.import_prefix';

  static const String constTitle = 'Add a prefix to the import';

  final String _defaultPrefix = 'prefix';

  AddImportPrefix(super.context);

  @override
  bool get isExperimental => false;

  @override
  CodeActionKind get kind => DartCodeActionKind.refactorAdd;

  @override
  List<CommandParameter> get parameters => const <CommandParameter>[];

  @override
  String get title => constTitle;

  @override
  Future<ComputeStatus> compute(
    List<Object?> commandArguments,
    ChangeBuilder builder,
  ) async {
    var element = selection?.importDirective(mustNotHavePrefix: true);
    if (element == null) {
      // This should never happen because `isAvailable` would have returned
      // `false`, so this method wouldn't have been called.
      return ComputeStatusFailure();
    }

    var refactoring = _createRefactoring(element);
    if (refactoring == null) {
      return ComputeStatusFailure();
    }
    refactoring.newName = _computeName(element);
    var status = await refactoring.checkAllConditions();
    if (status.hasError) {
      return ComputeStatusFailure();
    }
    await refactoring.createChange(builder: builder);
    return ComputeStatusSuccess();
  }

  @override
  bool isAvailable() {
    return selection?.importDirective(mustNotHavePrefix: true) != null;
  }

  /// Compute a prefix/name for the import.
  String _computeName(LibraryImport import) {
    // Use posix path context because we pass a URI path to this, but for file
    // names we use shortName which never has separators.
    var pathContext = path.posix;
    var prefixOrNull = switch (import.uri) {
      DirectiveUriWithSource(source: Source(:var shortName)) =>
        pathContext.basenameWithoutExtension(shortName),
      DirectiveUriWithRelativeUri(relativeUri: var uri) =>
        pathContext.basenameWithoutExtension(uri.path),
      _ => null, // Required because DirectiveUri is not sealed?
    };

    var prefix = _makeValidPrefix(prefixOrNull ?? '');
    return _getUniquePrefix(import.libraryFragment, prefix);
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

  /// Ensures [prefix] is a unique name within [libraryFragment] by appending
  /// a number.
  String _getUniquePrefix(LibraryFragment libraryFragment, String prefix) {
    var usedPrefixes = libraryFragment.libraryImports
        .map((import) => import.prefix?.name)
        .nonNulls
        .toSet();

    var maxAttempts = 1000;

    if (usedPrefixes.contains(prefix)) {
      for (var i = 1; i < maxAttempts; i++) {
        var possiblePrefix = '$prefix$i';
        if (!usedPrefixes.contains(possiblePrefix)) {
          return possiblePrefix;
        }
      }
    }

    return prefix;
  }

  /// Creates a valid name to use as prefix from [input].
  String _makeValidPrefix(String input) {
    var identifier = input
        // Replace invalid characters with underscores
        .replaceAll(RegExp(r'[^a-zA-Z0-9_$]'), '_')
        // Remove multiple underscores
        .replaceAll(RegExp(r'_+'), '_')
        // Remove any leading numerics or underscores
        .replaceAll(RegExp(r'^[\d_]+'), '')
        // Remove any trailing underscores
        .replaceAll(RegExp(r'_+$'), '')
        .toLowerCase();

    if (identifier.isEmpty || Keyword.keywords.containsKey(identifier)) {
      return _defaultPrefix;
    }

    return identifier;
  }
}
