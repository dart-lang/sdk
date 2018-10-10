// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/assist/assist_dart.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/ast_provider_driver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceChange, SourceEdit, SourceFileEdit;
import 'package:front_end/src/scanner/token.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/src/span.dart';

class EditDartFix {
  final AnalysisServer server;
  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];

  List<String> descriptionOfFixes;
  List<String> otherRecommendations;
  SourceChange sourceChange;

  EditDartFix(this.server, this.request);

  void addFix(String description, SourceChange change) {
    descriptionOfFixes.add(description);
    for (SourceFileEdit fileEdit in change.edits) {
      for (SourceEdit sourceEdit in fileEdit.edits) {
        sourceChange.addEdit(fileEdit.file, fileEdit.fileStamp, sourceEdit);
      }
    }
  }

  void addRecommendation(String recommendation) {
    otherRecommendations.add(recommendation);
  }

  Future<Response> compute() async {
    final params = new EditDartfixParams.fromRequest(request);

    // Validate each included file and directory.
    final resourceProvider = server.resourceProvider;
    final contextManager = server.contextManager;
    for (String path in params.included) {
      if (!server.isValidFilePath(path)) {
        return new Response.invalidFilePathFormat(request, path);
      }
      Resource res = resourceProvider.getResource(path);
      if (!res.exists ||
          !(contextManager.includedPaths.contains(path) ||
              contextManager.isInAnalysisRoot(path))) {
        return new Response.fileNotAnalyzed(request, path);
      }
      if (res is Folder) {
        fixFolders.add(res);
      } else {
        fixFiles.add(res);
      }
    }

    // Get the desired lints
    final LintRule preferMixin = Registry.ruleRegistry['prefer_mixin'];
    if (preferMixin == null) {
      return new Response.serverError(
          request, 'Missing prefer_mixin lint', null);
    }
    final preferMixinFix = new PreferMixinFix(this);
    preferMixin.reporter = preferMixinFix;

    // Setup
    final linters = <Linter>[
      preferMixin,
    ];
    final fixes = <LinterFix>[
      preferMixinFix,
    ];
    final visitors = <AstVisitor>[];
    final registry = new NodeLintRegistry(false);
    for (Linter linter in linters) {
      final visitor = linter.getVisitor();
      if (visitor != null) {
        visitors.add(visitor);
      }
      if (linter is NodeLintRule) {
        (linter as NodeLintRule).registerNodeProcessors(registry);
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
    descriptionOfFixes = <String>[];
    otherRecommendations = <String>[];
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
      AnalysisResult result = await server.getAnalysisResult(res.path);
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
        Source source = result.sourceFactory.forUri2(result.uri);
        for (Linter linter in linters) {
          linter.reporter.source = source;
        }
        if (astVisitor != null) {
          unit.accept(astVisitor);
        }
        unit.accept(linterVisitor);
      }
    }

    // Cleanup
    for (Linter linter in linters) {
      linter.reporter = null;
    }

    // Apply distributed fixes
    for (LinterFix fix in fixes) {
      await fix.applyFix();
    }

    return new EditDartfixResult(descriptionOfFixes, otherRecommendations,
            hasErrors, sourceChange.edits)
        .toResponse(request.id);
  }

  Future<bool> fixError(AnalysisResult result, AnalysisError error) async {
    if (error.errorCode ==
        StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR) {
      return fixConstructorTypeArguments(result, error);
    }
    return false;
  }

  Future<bool> fixConstructorTypeArguments(
      AnalysisResult result, AnalysisError error) async {
    final dartContext = new DartFixContextImpl(
        new FixContextImpl(
            server.resourceProvider, result.driver, error, result.errors),
        new AstProviderForDriver(result.driver),
        result.unit);
    final processor = new FixProcessor(dartContext);
    Fix fix = await processor.computeFix(error.errorCode);
    if (fix != null) {
      addFix(
        fix.change.message ??
            'Fix type arguments on constructor call'
            ' in ${path.basename(result.path)}',
        fix.change,
      );
    } else {
      // TODO(danrubel): Determine why the fix could not be applied
      // and report that in the description.
      addRecommendation('Could not fix type arguments on constructor call'
          ' in ${path.basename(result.path)}');
    }
    return true;
  }

  /// Return `true` if the path in within the set of `included` files
  /// or is within an `included` directory.
  bool isIncluded(String path) {
    if (path != null) {
      for (File file in fixFiles) {
        if (file.path == path) {
          return true;
        }
      }
      for (Folder folder in fixFolders) {
        if (folder.contains(path)) {
          return true;
        }
      }
    }
    return false;
  }
}

class EditDartFixAssistContext implements DartAssistContext {
  @override
  final AnalysisDriver analysisDriver;

  @override
  final int selectionLength;

  @override
  final int selectionOffset;

  @override
  final Source source;

  @override
  final CompilationUnit unit;

  EditDartFixAssistContext(
      EditDartFix dartFix, this.source, this.unit, AstNode node)
      : analysisDriver = dartFix.server.getAnalysisDriver(source.fullName),
        selectionOffset = node.offset,
        selectionLength = 0;
}

abstract class LinterFix implements ErrorReporter {
  final EditDartFix dartFix;

  @override
  Source source;

  LinterFix(this.dartFix);

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
  void reportTypeErrorForNode(
      ErrorCode errorCode, AstNode node, List<Object> arguments) {
    // ignored
  }

  void applyFix();
}

class PreferMixinFix extends LinterFix {
  final classesToConvert = new Set<Element>();

  PreferMixinFix(EditDartFix dartFix) : super(dartFix);

  @override
  void reportErrorForNode(ErrorCode errorCode, AstNode node,
      [List<Object> arguments]) {
    TypeName type = node;
    Element element = type.name.staticElement;
    String path = element.source?.fullName;
    if (path != null && dartFix.isIncluded(path)) {
      classesToConvert.add(element);
    }
  }

  @override
  void applyFix() async {
    for (Element elem in classesToConvert) {
      await convertClassToMixin(elem);
    }
  }

  void convertClassToMixin(Element elem) async {
    String path = elem.source?.fullName;
    AnalysisResult result = await dartFix.server.getAnalysisResult(path);

    // TODO(danrubel): Verify that class can be converted
    for (CompilationUnitMember declaration in result.unit.declarations) {
      if (declaration is ClassOrMixinDeclaration &&
          declaration.name.name == elem.name) {
        AssistProcessor processor = new AssistProcessor(
            new EditDartFixAssistContext(
                dartFix, elem.source, result.unit, declaration.name));
        List<Assist> assists = await processor
            .computeAssist(DartAssistKind.CONVERT_CLASS_TO_MIXIN);
        if (assists.isNotEmpty) {
          for (Assist assist in assists) {
            dartFix.addFix(
                'Convert class to mixin: ${elem.name}', assist.change);
          }
        } else {
          // TODO(danrubel): If assists is empty, then determine why
          // assist could not be performed and report that in the description.
          dartFix.addRecommendation('Could not convert ${elem.name} to a mixin'
              ' because the class contains a constructor.');
        }
      }
    }
  }
}
