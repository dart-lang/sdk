// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/protocol_server.dart' show SourceEdit;
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:collection/collection.dart';

/// The root of a set of classes that support testing for lint fixes.
///
/// These classes work as a sequence:
/// 1. Create this tested with necessary SDK and package config.
/// 2. Configure any overlays on top of the file system with [updateFile].
/// 3. Request fixes for a file using [fixesForSingleLint].
/// 4. Use the [LintFixTesterWithFixes] to check how many fixes there are.
/// 5. If there is a single fix, use [LintFixTesterWithSingleFix] to verify
///    the fixed content for specific files.
class LintFixTester {
  final OverlayResourceProvider _resourceProvider;
  final String sdkPath;
  final String? packageConfigPath;

  /// If `false`, then we have already computed lints for this tester,
  /// and updating the file system (as much as we can observe it) should
  /// not be allowed.
  bool _canUpdateResourceProvider = true;

  LintFixTester({
    required ResourceProvider resourceProvider,
    required this.sdkPath,
    required this.packageConfigPath,
  }) : _resourceProvider = OverlayResourceProvider(resourceProvider);

  /// Prepare fixes for a single lint in the file with the [path]
  ///
  /// If [inFile] is `false`, there must be exactly one diagnostic in the file,
  /// and it is a lint.
  ///
  /// If [inFile] is `true`, there must be one or more diagnostics, but all
  /// of them must have the same error code, and it must be a lint.
  ///
  /// Throws [StateError] if an expectation is not satisfied.
  Future<LintFixTesterWithFixes> fixesForSingleLint({
    required String path,
    required bool inFile,
  }) async {
    _canUpdateResourceProvider = true;

    var collection = AnalysisContextCollectionImpl(
      includedPaths: [path],
      resourceProvider: _resourceProvider,
      sdkPath: sdkPath,
      packagesFile: packageConfigPath,
    );
    var analysisContext = collection.contextFor(path);
    var analysisSession = analysisContext.currentSession;

    var unitResult = await analysisSession.getResolvedUnit(path);
    unitResult as ResolvedUnitResult;

    AnalysisError error;
    var errors = unitResult.errors;
    if (inFile) {
      var groups = errors.groupListsBy((error) => error.errorCode);
      if (groups.length != 1) {
        throw StateError(
          'Exactly one error code expected:'
          '\n$errors\n${groups.keys.toList()}',
        );
      }
      error = errors.first;
    } else {
      if (errors.length != 1) {
        throw StateError('Exactly one lint expected: $errors');
      }
      error = errors.single;
    }

    if (error.errorCode is! LintCode) {
      throw StateError('A lint expected: $errors');
    }

    var workspace = DartChangeWorkspace([analysisSession]);
    var context = DartFixContextImpl(
      InstrumentationService.NULL_SERVICE,
      workspace,
      unitResult,
      error,
    );

    List<Fix> fixes;
    if (inFile) {
      var fixInFileProcessor = FixInFileProcessor(context);
      fixes = await fixInFileProcessor.compute();
    } else {
      fixes = await FixProcessor(context).compute();
      fixes.removeWhere(
        (fix) =>
            fix.kind == DartFixKind.IGNORE_ERROR_LINE ||
            fix.kind == DartFixKind.IGNORE_ERROR_FILE,
      );
    }

    return LintFixTesterWithFixes(parent: this, fixes: fixes);
  }

  /// Update the view on the file system so that the final with the [path]
  /// is considered to have the given [content]. The actual file system is
  /// not changed.
  ///
  /// This method should not be used after any analysis is performed, such
  /// as invocation of [fixesForSingleLint], will throw [StateError].
  void updateFile({
    required String path,
    required String content,
  }) {
    if (!_canUpdateResourceProvider) {
      throw StateError('Diagnostics were already computed.');
    }

    _resourceProvider.setOverlay(
      path,
      content: content,
      modificationStamp: 0,
    );
  }
}

class LintFixTesterWithFixes {
  final LintFixTester _parent;
  final List<Fix> fixes;

  LintFixTesterWithFixes({
    required LintFixTester parent,
    required this.fixes,
  }) : _parent = parent;

  void assertNoFixes() {
    if (fixes.isNotEmpty) {
      throw StateError('Must have exactly zero fixes: $fixes');
    }
  }

  LintFixTesterWithSingleFix assertSingleFix() {
    if (fixes.length != 1) {
      throw StateError('Must have exactly one fix: $fixes');
    }

    return LintFixTesterWithSingleFix(
      parent: this,
      fix: fixes.single,
    );
  }
}

class LintFixTesterWithSingleFix {
  final LintFixTesterWithFixes _parent;
  final Fix fix;

  LintFixTesterWithSingleFix({
    required LintFixTesterWithFixes parent,
    required this.fix,
  }) : _parent = parent;

  void assertFixedContentOfFile({
    required String path,
    required String fixedContent,
  }) {
    var fileEdits = fix.change.edits;
    var fileEdit = fileEdits.singleWhere(
      (fileEdit) => fileEdit.file == path,
    );

    var resourceProvider = _parent._parent._resourceProvider;
    var file = resourceProvider.getFile(path);
    var fileContent = file.readAsStringSync();

    var actualFixedContent = SourceEdit.applySequence(
      fileContent,
      fileEdit.edits,
    );
    if (actualFixedContent != fixedContent) {
      throw StateError('Not expected content:\n$actualFixedContent');
    }
  }

  void assertNoFileEdit({required String path}) {
    var fileEdits = fix.change.edits;
    var filtered = fileEdits.where(
      (fileEdit) => fileEdit.file == path,
    );
    if (filtered.isNotEmpty) {
      throw StateError('Expected no edit for $path: $fix');
    }
  }
}
