// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/edit/fix/prefer_int_literals_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
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

class EditDartFix {
  final AnalysisServer server;
  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];

  List<DartFixSuggestion> suggestions;
  List<DartFixSuggestion> otherSuggestions;
  SourceChange sourceChange;

  EditDartFix(this.server, this.request);

  void addFix(String description, Location location, SourceChange change) {
    suggestions.add(new DartFixSuggestion(description, location: location));
    for (SourceFileEdit fileEdit in change.edits) {
      for (SourceEdit sourceEdit in fileEdit.edits) {
        sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
      }
    }
  }

  void addRecommendation(String description, [Location location]) {
    otherSuggestions
        .add(new DartFixSuggestion(description, location: location));
  }

  Future<Response> compute() async {
    final params = new EditDartfixParams.fromRequest(request);

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

    // Get the desired lints
    final lintRules = Registry.ruleRegistry;

    final preferMixin = lintRules['prefer_mixin'];
    final preferMixinFix = new PreferMixinFix(this);
    preferMixin.reporter = preferMixinFix;

    final preferIntLiterals = lintRules['prefer_int_literals'];
    final preferIntLiteralsFix = new PreferIntLiteralsFix(this);
    preferIntLiterals?.reporter = preferIntLiteralsFix;

    // Setup
    final linters = <Linter>[
      preferMixin,
      preferIntLiterals,
    ];
    final fixes = <LinterFix>[
      preferMixinFix,
      preferIntLiteralsFix,
    ];
    final visitors = <AstVisitor>[];
    final registry = new NodeLintRegistry(false);
    for (Linter linter in linters) {
      if (linter != null) {
        final visitor = linter.getVisitor();
        if (visitor != null) {
          visitors.add(visitor);
        }
        if (linter is NodeLintRule) {
          (linter as NodeLintRule).registerNodeProcessors(registry);
        }
      }
    }
    final AstVisitor astVisitor = visitors.isNotEmpty
        ? new ExceptionHandlingDelegatingAstVisitor(
            visitors, ExceptionHandlingDelegatingAstVisitor.logException)
        : null;
    final AstVisitor linterVisitor = new LinterVisitor(
        registry, ExceptionHandlingDelegatingAstVisitor.logException);

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
              contextManager.isInAnalysisRoot(child.path)) {
            resources.add(child);
          }
        }
        continue;
      }
      ResolveResult result = await server.getAnalysisResult(res.path);
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
        if (astVisitor != null) {
          unit.accept(astVisitor);
        }
        unit.accept(linterVisitor);
        for (LinterFix fix in fixes) {
          await fix.applyLocalFixes(result);
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
    if (preferIntLiterals == null) {
      // TODO(danrubel): Remove this once linter rolled into sdk/third_party.
      addRecommendation('*** Convert double literal not available'
          ' because prefer_int_literal not found. May need to roll linter');
    }
    for (LinterFix fix in fixes) {
      await fix.applyRemainingFixes();
    }

    return new EditDartfixResult(
            suggestions, otherSuggestions, hasErrors, sourceChange.edits)
        .toResponse(request.id);
  }

  Future<bool> fixError(ResolveResult result, AnalysisError error) async {
    if (error.errorCode ==
        StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR) {
      // TODO(danrubel): Rather than comparing the error codes individually,
      // it would be better if each error code could specify
      // whether or not it could be fixed automatically.

      // Fall through to calculate and apply the fix
    } else {
      // This error cannot be automatically fixed
      return false;
    }

    final dartContext = new DartFixContextImpl(result, error);
    final processor = new FixProcessor(dartContext);
    Fix fix = await processor.computeFix();
    final location = locationFor(result, error.offset, error.length);
    if (fix != null) {
      addFix(fix.change.message, location, fix.change);
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

  Location locationFor(ResolveResult result, int offset, int length) {
    final locInfo = result.unit.lineInfo.getLocation(offset);
    final location = new Location(
        result.path, offset, length, locInfo.lineNumber, locInfo.columnNumber);
    return location;
  }
}

abstract class LinterFix implements ErrorReporter {
  final EditDartFix dartFix;

  @override
  Source source;

  LinterFix(this.dartFix);

  /// Apply fixes for the current compilation unit.
  Future<void> applyLocalFixes(ResolveResult result);

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
