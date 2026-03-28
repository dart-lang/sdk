// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'Use simple directive paths.';

class SimpleDirectivePaths extends AnalysisRule {
  SimpleDirectivePaths()
    : super(name: LintNames.simple_directive_paths, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.simpleDirectivePaths;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConfiguration(this, visitor);
    registry.addExportDirective(this, visitor);
    registry.addImportDirective(this, visitor);
    registry.addPartDirective(this, visitor);
    registry.addPartOfDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final SimpleDirectivePaths rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitConfiguration(Configuration node) {
    _check(node.uri);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _check(node.uri);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    _check(node.uri);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _check(node.uri);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    var uri = node.uri;
    if (uri != null) {
      _check(uri);
    }
  }

  void _check(StringLiteral uriNode) {
    var uriString = uriNode.stringValue;
    if (uriString == null || uriString.isEmpty) return;

    var parsedUri = Uri.tryParse(uriString);
    if (parsedUri == null) return;

    // 1. Check for general URI normalization (handles '.', '..', and unnecessary
    // escapes like '%41' instead of 'A').
    if (uriString != parsedUri.toString()) {
      rule.reportAtNode(uriNode);
      return;
    }

    // 2. Check for relative path minimality.
    // Absolute paths (starting with '/') are not forced to be relative here,
    // but they must be normalized (handled above).
    if (!parsedUri.hasScheme &&
        !parsedUri.hasAuthority &&
        !parsedUri.hasAbsolutePath &&
        parsedUri.path.isNotEmpty) {
      var contextUri = context.currentUnit?.unit.declaredFragment?.source.uri;
      if (contextUri == null) return;

      var resolvedUri = contextUri.resolveUri(parsedUri);
      var relativePath = path.url.relative(
        resolvedUri.path,
        from: path.url.dirname(contextUri.path),
      );
      if (relativePath != uriString) {
        rule.reportAtNode(uriNode);
      }
    }
  }
}
