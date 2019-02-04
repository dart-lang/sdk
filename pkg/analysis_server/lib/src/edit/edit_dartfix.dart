// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_int_literals_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show Location, SourceChange, SourceEdit, SourceFileEdit;
import 'package:front_end/src/fasta/fasta_codes.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:source_span/src/span.dart';

const doubleToInt = 'double-to-int';
const fixNamedConstructorTypeArgs = 'fix-named-constructor-type-arguments';
const nonNullable = 'non-nullable';
const useMixin = 'use-mixin';

const allFixes = <String>[
  doubleToInt,
  fixNamedConstructorTypeArgs,
  // TODO(danrubel) enable this by default when NNBD fix is ready
  //nonNullable,
  useMixin,
];

const requiredFixes = <String>[
  fixNamedConstructorTypeArgs,
  useMixin,
];

List<DartFix> get dartfixInfo {
  final fixes = <DartFix>[];

  void addFix(String name, String description) {
    if (!allFixes.contains(name)) {
      description = 'Experimental: $description\n'
          'This is not applied unless explicitly included.';
    }
    final fix = new DartFix(name, description: description);
    if (requiredFixes.contains(name)) {
      fix.isRequired = true;
    }
    fixes.add(fix);
  }

  addFix(
    doubleToInt,
    'Find double literals ending in .0 and remove the .0\n'
        'wherever double context can be inferred.',
  );
  addFix(
    fixNamedConstructorTypeArgs,
    'Move named constructor type arguments from the name to the type.',
  );
  addFix(
    nonNullable,
    'Update sources to be non-nullable by default.\n'
        // TODO(danrubel) remove this when NNBD fix is ready
        'Requires the experimental non-nullable flag to be enabled.',
  );
  addFix(
    useMixin,
    'Convert classes used as a mixin to the new mixin syntax.',
  );

  return fixes;
}

class EditDartFix {
  final AnalysisServer server;
  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];
  final fixesToApply = new Set<String>();

  List<DartFixSuggestion> suggestions;
  List<DartFixSuggestion> otherSuggestions;
  SourceChange sourceChange;

  EditDartFix(this.server, this.request);

  void addSourceChange(
      String description, Location location, SourceChange change) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceFileEdit fileEdit in change.edits) {
      for (SourceEdit sourceEdit in fileEdit.edits) {
        sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
      }
    }
  }

  void addSourceFileEdit(
      String description, Location location, SourceFileEdit fileEdit) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceEdit sourceEdit in fileEdit.edits) {
      sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
    }
  }

  void addRecommendation(String description, [Location location]) {
    otherSuggestions
        .add(new DartFixSuggestion(description, location: location));
  }

  Future<Response> compute() async {
    final params = new EditDartfixParams.fromRequest(request);

    // Determine the fixes to be applied
    if (params.includeRequiredFixes == true) {
      fixesToApply.addAll(requiredFixes);
    }
    if (params.includedFixes != null) {
      fixesToApply.addAll(params.includedFixes);
    }
    if (fixesToApply.isEmpty) {
      fixesToApply.addAll(allFixes);
    }
    if (params.excludedFixes != null) {
      for (String fixName in params.excludedFixes) {
        fixesToApply.remove(fixName);
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
    if (fixesToApply.contains(useMixin)) {
      final preferMixin = lintRules['prefer_mixin'];
      final preferMixinFix = new PreferMixinFix(this);
      preferMixin.reporter = preferMixinFix;
      linters.add(preferMixin);
      fixes.add(preferMixinFix);
    }
    if (fixesToApply.contains(doubleToInt)) {
      final preferIntLiterals = lintRules['prefer_int_literals'];
      final preferIntLiteralsFix = new PreferIntLiteralsFix(this);
      preferIntLiterals.reporter = preferIntLiteralsFix;
      linters.add(preferIntLiterals);
      fixes.add(preferIntLiteralsFix);
    }

    final nonNullableFix = new NonNullableFix(this);

    final lintVisitorsBySession = <AnalysisSession, _LintVisitors>{};

    // TODO(danrubel): Determine if a lint is configured to run as part of
    // standard analysis and use those results if available instead of
    // running the lint again.

    // Analyze each source file.
    final resources = <Resource>[];
    for (String rootPath in contextManager.includedPaths) {
      resources.add(resourceProvider.getResource(rootPath));
    }
    suggestions = <DartFixSuggestion>[];
    otherSuggestions = <DartFixSuggestion>[];
    sourceChange = new SourceChange('dartfix');
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

      const maxAttempts = 3;
      int attempt = 0;
      while (attempt < maxAttempts) {
        ResolvedUnitResult result = await server.getResolvedUnit(res.path);

        // TODO(danrubel): Investigate why InconsistentAnalysisException occurs
        // and whether this is an appropriate way to handle the situation
        ++attempt;
        try {
          CompilationUnit unit = result?.unit;
          if (unit != null) {
            if (!hasErrors) {
              for (AnalysisError error in result.errors) {
                if (!(await fixError(result, error))) {
                  if (error.errorCode.type == ErrorType.SYNTACTIC_ERROR) {
                    hasErrors = true;
                  }
                }
              }
            }
            Source source = result.unit.declaredElement.source;
            for (Linter linter in linters) {
              if (linter != null) {
                linter.reporter.source = source;
              }
            }
            var lintVisitors = lintVisitorsBySession[result.session] ??=
                await _setupLintVisitors(result, linters);
            if (lintVisitors.astVisitor != null) {
              unit.accept(lintVisitors.astVisitor);
            }
            unit.accept(lintVisitors.linterVisitor);
            for (LinterFix fix in fixes) {
              await fix.applyLocalFixes(result);
            }
            if (isIncluded(source.fullName) &&
                fixesToApply.contains(nonNullable)) {
              nonNullableFix.applyLocalFixes(result);
            }
          }
          break;
        } on InconsistentAnalysisException catch (_) {
          if (attempt == maxAttempts) {
            // TODO(danrubel): Consider improving the edit.dartfix protocol
            // to gracefully report inconsistent results for a particular
            // file rather than aborting the entire operation.
            rethrow;
          }
          // try again
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

    return new EditDartfixResult(
            suggestions, otherSuggestions, hasErrors, sourceChange.edits)
        .toResponse(request.id);
  }

  Future<bool> fixError(ResolvedUnitResult result, AnalysisError error) async {
    const errorCodeToFixName = <ErrorCode, String>{
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR:
          fixNamedConstructorTypeArgs,
    };

    final fixName = errorCodeToFixName[error.errorCode];
    if (!fixesToApply.contains(fixName)) {
      return false;
    }

    final workspace = DartChangeWorkspace(server.currentSessions);
    final dartContext = new DartFixContextImpl(workspace, result, error);
    final processor = new FixProcessor(dartContext);
    Fix fix = await processor.computeFix();
    final location = locationFor(result, error.offset, error.length);
    if (fix != null) {
      addSourceChange(fix.change.message, location, fix.change);
    } else {
      // TODO(danrubel): Determine why the fix could not be applied
      // and report that in the description.
      addRecommendation('Could not fix "${error.message}"', location);
    }
    return true;
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

  Location locationFor(ResolvedUnitResult result, int offset, int length) {
    final locInfo = result.unit.lineInfo.getLocation(offset);
    final location = new Location(
        result.path, offset, length, locInfo.lineNumber, locInfo.columnNumber);
    return location;
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
  final EditDartFix dartFix;

  @override
  Source source;

  LinterFix(this.dartFix);

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
