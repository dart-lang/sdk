// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/dartfix_info.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_int_literals_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:source_span/src/span.dart';

// TODO(danrubel): Replace these consts with DartFixInfo
const doubleToInt = 'double-to-int';
const nonNullable = 'non-nullable';
const useMixin = 'use-mixin';

class EditDartFix with FixErrorProcessor implements DartFixRegistrar {
  @override
  final AnalysisServer server;

  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];
  // TODO(danrubel): replace with is a list of DartFixInfo
  final namesOfFixesToApply = new Set<String>();

  DartFixListener listener;

  EditDartFix(this.server, this.request) {
    listener = new DartFixListener(server);
  }

  Future<Response> compute() async {
    final params = new EditDartfixParams.fromRequest(request);

    // Determine the fixes to be applied
    final fixInfo = <DartFixInfo>[];
    if (params.includeRequiredFixes == true) {
      fixInfo.addAll(allFixes.where((i) => i.isRequired));
    }
    if (params.includedFixes != null) {
      for (String key in params.includedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.add(info);
        } else {
          // TODO(danrubel): Report unknown fix to the user
        }
      }
    }
    if (fixInfo.isEmpty) {
      fixInfo.addAll(allFixes.where((i) => i.isDefault));
    }
    if (params.excludedFixes != null) {
      for (String key in params.excludedFixes) {
        var info = allFixes.firstWhere((i) => i.key == key, orElse: () => null);
        if (info != null) {
          fixInfo.remove(info);
        } else {
          // TODO(danrubel): Report unknown fix to the user
        }
      }
    }
    for (DartFixInfo info in fixInfo) {
      String key = info.setup(this, listener);
      if (key != null) {
        // TODO(danrubel) replace returned strings with task registration.
        namesOfFixesToApply.add(key);
      }
    }

    // Validate each included file and directory.
    final resourceProvider = server.resourceProvider;
    final contextManager = server.contextManager;
    for (String filePath in params.included) {
      if (!server.isValidFilePath(filePath)) {
        return new Response.invalidFilePathFormat(request, filePath);
      }
      Resource res = resourceProvider.getResource(filePath);
      if (!res.exists ||
          !(contextManager.includedPaths.contains(filePath) ||
              contextManager.isInAnalysisRoot(filePath))) {
        return new Response.fileNotAnalyzed(request, filePath);
      }
      if (res is Folder) {
        fixFolders.add(res);
      } else {
        fixFiles.add(res);
      }
    }

    // Setup lints
    final lintRules = Registry.ruleRegistry;
    final linters = <Linter>[];
    final fixes = <LinterFix>[];
    if (namesOfFixesToApply.contains(useMixin)) {
      final preferMixin = lintRules['prefer_mixin'];
      final preferMixinFix = new PreferMixinFix(listener);
      preferMixin.reporter = preferMixinFix;
      linters.add(preferMixin);
      fixes.add(preferMixinFix);
    }
    if (namesOfFixesToApply.contains(doubleToInt)) {
      final preferIntLiterals = lintRules['prefer_int_literals'];
      final preferIntLiteralsFix = new PreferIntLiteralsFix(listener);
      preferIntLiterals.reporter = preferIntLiteralsFix;
      linters.add(preferIntLiterals);
      fixes.add(preferIntLiteralsFix);
    }

    final nonNullableFix = namesOfFixesToApply.contains(nonNullable)
        ? new NonNullableFix(listener)
        : null;

    // TODO(danrubel): Determine if a lint is configured to run as part of
    // standard analysis and use those results if available instead of
    // running the lint again.

    // Analyze each source file.
    final resources = <Resource>[];
    for (String rootPath in contextManager.includedPaths) {
      resources.add(resourceProvider.getResource(rootPath));
    }
    bool hasErrors = false;
    while (resources.isNotEmpty) {
      Resource res = resources.removeLast();
      if (res is Folder) {
        for (Resource child in res.getChildren()) {
          if (!child.shortName.startsWith('.') &&
              contextManager.isInAnalysisRoot(child.path) &&
              !contextManager.isIgnored(child.path)) {
            resources.add(child);
          }
        }
        continue;
      }
      if (!isIncluded(res.path)) {
        continue;
      }

      ResolvedUnitResult result = await server.getResolvedUnit(res.path);

      CompilationUnit unit = result?.unit;
      if (unit != null) {
        if (await processErrors(result)) {
          hasErrors = true;
        }
        Source source = result.unit.declaredElement.source;
        for (Linter linter in linters) {
          if (linter != null) {
            linter.reporter.source = source;
          }
        }
        var lintVisitors = await _setupLintVisitors(result, linters);
        if (lintVisitors.astVisitor != null) {
          unit.accept(lintVisitors.astVisitor);
        }
        unit.accept(lintVisitors.linterVisitor);
        for (LinterFix fix in fixes) {
          await fix.applyLocalFixes(result);
        }
        if (isIncluded(source.fullName)) {
          nonNullableFix?.applyLocalFixes(result);
        }
      }
    }

    // Cleanup
    for (Linter linter in linters) {
      if (linter != null) {
        linter.reporter.source = null;
        linter.reporter = null;
      }
    }

    // Apply distributed fixes
    for (LinterFix fix in fixes) {
      await fix.applyRemainingFixes();
    }
    nonNullableFix?.applyRemainingFixes();

    return new EditDartfixResult(
      listener.suggestions,
      listener.otherSuggestions,
      hasErrors,
      listener.sourceChange.edits,
    ).toResponse(request.id);
  }

  /// Return `true` if the path in within the set of `included` files
  /// or is within an `included` directory.
  bool isIncluded(String filePath) {
    if (filePath != null) {
      for (File file in fixFiles) {
        if (file.path == filePath) {
          return true;
        }
      }
      for (Folder folder in fixFolders) {
        if (folder.contains(filePath)) {
          return true;
        }
      }
    }
    return false;
  }

  Future<_LintVisitors> _setupLintVisitors(
      ResolvedUnitResult result, List<Linter> linters) async {
    final visitors = <AstVisitor>[];
    final registry = new NodeLintRegistry(false);
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
    var context = LinterContextImpl(allUnits, currentUnit,
        session.declaredVariables, result.typeProvider, result.typeSystem);
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
    final AstVisitor astVisitor = visitors.isNotEmpty
        ? new ExceptionHandlingDelegatingAstVisitor(
            visitors, ExceptionHandlingDelegatingAstVisitor.logException)
        : null;
    final AstVisitor linterVisitor = new LinterVisitor(
        registry, ExceptionHandlingDelegatingAstVisitor.logException);
    return _LintVisitors(astVisitor, linterVisitor);
  }
}

abstract class LinterFix implements ErrorReporter {
  final DartFixListener listener;

  @override
  Source source;

  LinterFix(this.listener);

  /// Apply fixes for the current compilation unit.
  Future<void> applyLocalFixes(ResolvedUnitResult result);

  /// Apply any fixes remaining after analysis is complete.
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

class _LintVisitors {
  final AstVisitor astVisitor;

  final AstVisitor linterVisitor;

  _LintVisitors(this.astVisitor, this.linterVisitor);
}
