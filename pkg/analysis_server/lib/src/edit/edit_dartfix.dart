// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:source_span/src/span.dart';

class EditDartFix {
  final AnalysisServer server;
  final Request request;
  final fixFolders = <Folder>[];
  final fixFiles = <File>[];

  EditDartFix(this.server, this.request);

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
          request, 'Missing PreferMixin lint', null);
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

    // Reporting
    final descriptions = <String>[];
    for (LinterFix fix in fixes) {
      fix.updateResponse(descriptions);
    }
    return new EditDartfixResult(descriptions, []).toResponse(request.id);
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

  void updateResponse(List<String> descriptions);
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
    if (dartFix.isIncluded(path)) {
      // Only report classes that are `included`
      classesToConvert.add(element);
    }
  }

  @override
  void updateResponse(List<String> descriptions) {
    final sorted = classesToConvert.toList()
      ..sort((c1, c2) => c1.name.compareTo(c2.name));
    for (Element elem in sorted) {
      descriptions.add('Convert class to mixin: ${elem.name}');
    }
  }
}
