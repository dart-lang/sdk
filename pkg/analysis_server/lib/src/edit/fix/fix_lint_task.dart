// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:source_span/src/span.dart';

/// A processor used by [EditDartFix] to manage [FixLintTask]s.
mixin FixLintProcessor {
  final linters = <Linter>[];
  final lintTasks = <FixLintTask>[];

  Future<void> finishLints() async {
    for (Linter linter in linters) {
      linter.reporter = null;
    }
    for (FixLintTask fix in lintTasks) {
      fix.source = null;
      await fix.applyRemainingFixes();
    }
  }

  Future<void> processLints(ResolvedUnitResult result) async {
    // TODO(danrubel): Determine if a lint is configured to run as part of
    // standard analysis and use those results if available instead of
    // running the lint again.

    Source source = result.unit.declaredElement.source;
    for (Linter linter in linters) {
      if (linter != null) {
        linter.reporter.source = source;
      }
    }

    // TODO(paulberry): use an API that provides this information more readily

    var unitElement = result.unit.declaredElement;
    var session = result.session;
    var currentUnit = LinterContextUnit(result.content, result.unit);
    var allUnits = <LinterContextUnit>[];
    for (var cu in unitElement.library.units) {
      if (identical(cu, unitElement)) {
        allUnits.add(currentUnit);
      } else {
        Source source = cu.source;
        if (source != null) {
          var result = await session.getResolvedUnit(source.fullName);
          allUnits.add(LinterContextUnit(result.content, result.unit));
        }
      }
    }

    final visitors = <AstVisitor>[];
    final registry = new NodeLintRegistry(false);
    var context = LinterContextImpl(
        allUnits,
        currentUnit,
        session.declaredVariables,
        result.typeProvider,
        result.typeSystem,
        InheritanceManager3(result.typeSystem),
        result.session.analysisContext.analysisOptions);
    for (Linter linter in linters) {
      if (linter != null) {
        final visitor = linter.getVisitor();
        if (visitor != null) {
          visitors.add(visitor);
        }
        if (linter is NodeLintRule) {
          (linter as NodeLintRule).registerNodeProcessors(registry, context);
        }
      }
    }

    CompilationUnit unit = result.unit;
    if (visitors.isNotEmpty) {
      unit.accept(new ExceptionHandlingDelegatingAstVisitor(
          visitors, ExceptionHandlingDelegatingAstVisitor.logException));
    }
    unit.accept(new LinterVisitor(
        registry, ExceptionHandlingDelegatingAstVisitor.logException));

    for (FixLintTask fix in lintTasks) {
      await fix.applyLocalFixes(result);
    }
  }

  void registerLintTask(LintRule lint, FixLintTask task) {
    linters.add(lint);
    lintTasks.add(task);
    lint.reporter = task;
  }
}

/// A task for fixing a particular lint.
/// Subclasses should implement [applyLocalFixes] and [applyRemainingFixes]
/// and may override any of the reportSomething() methods as needed.
abstract class FixLintTask implements ErrorReporter {
  final DartFixListener listener;

  @override
  Source source;

  FixLintTask(this.listener);

  /// Apply fixes for the current compilation unit.
  Future<void> applyLocalFixes(ResolvedUnitResult result);

  /// Apply any fixes remaining after all local changes have been applied.
  Future<void> applyRemainingFixes();

  @override
  void reportError(AnalysisError error) {
    // ignored
  }

  @override
  void reportErrorForElement(ErrorCode errorCode, Element element,
      [List<Object> arguments]) {
    // ignored
  }

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    // ignored
  }

  @override
  void reportErrorForOffset(ErrorCode errorCode, int offset, int length,
      [List<Object> arguments]) {
    // ignored
  }

  @override
  void reportErrorForSpan(ErrorCode errorCode, SourceSpan span,
      [List<Object> arguments]) {
    // ignored
  }

  @override
  void reportErrorForToken(ErrorCode errorCode, Token token,
      [List<Object> arguments]) {
    // ignored
  }

  @override
  void reportErrorMessage(
      ErrorCode errorCode, int offset, int length, Message message) {
    // ignored
  }

  @override
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    // ignored
  }
}
