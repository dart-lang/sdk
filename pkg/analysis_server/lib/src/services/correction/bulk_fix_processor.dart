// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/add_override.dart';
import 'package:analysis_server/src/services/correction/dart/convert_documentation_into_line.dart';
import 'package:analysis_server/src/services/correction/dart/convert_to_contains.dart';
import 'package:analysis_server/src/services/correction/dart/remove_argument.dart';
import 'package:analysis_server/src/services/correction/dart/remove_const.dart';
import 'package:analysis_server/src/services/correction/dart/remove_empty_else.dart';
import 'package:analysis_server/src/services/correction/dart/remove_initializer.dart';
import 'package:analysis_server/src/services/correction/dart/remove_type_annotation.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unnecessary_new.dart';
import 'package:analysis_server/src/services/correction/dart/replace_cascade_with_dot.dart';
import 'package:analysis_server/src/services/correction/dart/replace_colon_with_equals.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// A fix producer that produces changes to fix multiple diagnostics.
class BulkFixProcessor {
  /// A map from the name of a lint rule to a generator used to create the
  /// correction producer used to build a fix for that diagnostic. The
  /// generators used for non-lint diagnostics are in the [nonLintProducerMap].
  static const Map<String, ProducerGenerator> lintProducerMap = {
    LintNames.annotate_overrides: AddOverride.newInstance,
    LintNames.avoid_annotating_with_dynamic: RemoveTypeAnnotation.newInstance,
    LintNames.avoid_empty_else: RemoveEmptyElse.newInstance,
    LintNames.avoid_init_to_null: RemoveInitializer.newInstance,
    LintNames.avoid_redundant_argument_values: RemoveArgument.newInstance,
    LintNames.avoid_return_types_on_setters: RemoveTypeAnnotation.newInstance,
    LintNames.avoid_single_cascade_in_expression_statements:
        ReplaceCascadeWithDot.newInstance,
    LintNames.avoid_types_on_closure_parameters:
        RemoveTypeAnnotation.newInstance,
    LintNames.prefer_contains: ConvertToContains.newInstance,
    LintNames.prefer_equal_for_default_values:
        ReplaceColonWithEquals.newInstance,
    LintNames.slash_for_doc_comments: ConvertDocumentationIntoLine.newInstance,
    LintNames.unnecessary_const: RemoveUnnecessaryConst.newInstance,
    LintNames.unnecessary_new: RemoveUnnecessaryNew.newInstance,
  };

  /// A map from an error code to a generator used to create the correction
  /// producer used to build a fix for that diagnostic. The generators used for
  /// lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, ProducerGenerator> nonLintProducerMap = {};

  final DartChangeWorkspace workspace;

  /// The change builder used to build the changes required to fix the
  /// diagnostics.
  ChangeBuilder builder;

  BulkFixProcessor(this.workspace) {
    builder = ChangeBuilder(workspace: workspace);
  }

  Future<ChangeBuilder> fixErrorsInLibraries(List<String> libraryPaths) async {
    for (var path in libraryPaths) {
      var session = workspace.getSession(path);
      var libraryResult = await session.getResolvedLibrary(path);
      await _fixErrorsInLibrary(libraryResult);
    }
    return builder;
  }

  Future<void> _fixErrorsInLibrary(ResolvedLibraryResult libraryResult) async {
    for (var unitResult in libraryResult.units) {
      final fixContext = DartFixContextImpl(
        workspace,
        unitResult,
        null,
        (name) => [],
      );
      for (var error in unitResult.errors) {
        await _fixSingleError(fixContext, unitResult, error);
      }
    }
  }

  Future<void> _fixSingleError(DartFixContext fixContext,
      ResolvedUnitResult unitResult, AnalysisError error) async {
    var context = CorrectionProducerContext(
      dartFixContext: fixContext,
      diagnostic: error,
      resolvedResult: unitResult,
      selectionOffset: error.offset,
      selectionLength: error.length,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      await producer.compute(builder);
    }

    var errorCode = error.errorCode;
    if (errorCode is LintCode) {
      var generator = lintProducerMap[errorCode.name];
      if (generator != null) {
        await compute(generator());
      }
    } else {
      var generator = nonLintProducerMap[errorCode];
      if (generator != null) {
        await compute(generator());
      }
    }
  }
}
