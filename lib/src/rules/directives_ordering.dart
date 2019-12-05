// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Adhere to Effective Dart Guide directives sorting conventions.';
const _details = r'''

**DO** follow the conventions in the 
[Effective Dart Guide](https://dart.dev/guides/language/effective-dart/style#ordering)

**DO** place “dart:” imports before other imports.

**BAD:**
```
import 'package:bar/bar.dart';
import 'package:foo/foo.dart';

import 'dart:async';  // LINT
import 'dart:html';  // LINT
```

**BAD:**
```
import 'dart:html';  // OK
import 'package:bar/bar.dart';

import 'dart:async';  // LINT
import 'package:foo/foo.dart';
```

**GOOD:**
```
import 'dart:async';  // OK
import 'dart:html';  // OK

import 'package:bar/bar.dart';
import 'package:foo/foo.dart';
```

**DO** place “package:” imports before relative imports.

**BAD:**
```
import 'a.dart';
import 'b.dart';

import 'package:bar/bar.dart';  // LINT
import 'package:foo/foo.dart';  // LINT
```
**BAD:**
```
import 'package:bar/bar.dart';  // OK
import 'a.dart';

import 'package:foo/foo.dart';  // LINT
import 'b.dart';
```

**GOOD:**
```
import 'package:bar/bar.dart';  // OK
import 'package:foo/foo.dart';  // OK

import 'a.dart';
import 'b.dart';
```

**PREFER** placing “third-party” “package:” imports before other imports.

**BAD:**
```
import 'package:myapp/io.dart';
import 'package:myapp/util.dart';

import 'package:bar/bar.dart';  // LINT
import 'package:foo/foo.dart';  // LINT
```

**GOOD:**
```
import 'package:bar/bar.dart';  // OK
import 'package:foo/foo.dart';  // OK

import 'package:myapp/io.dart';
import 'package:myapp/util.dart';
```

**DO** specify exports in a separate section after all imports.

**BAD:**
```
import 'src/error.dart';
export 'src/error.dart'; // LINT
import 'src/string_source.dart';
```

**GOOD:**
```
import 'src/error.dart';
import 'src/string_source.dart';

export 'src/error.dart'; // OK
```

**DO** sort sections alphabetically.

**BAD:**
```
import 'package:foo/bar.dart'; // OK
import 'package:bar/bar.dart'; // LINT

import 'a/b.dart'; // OK
import 'a.dart'; // LINT
```

**GOOD:**
```
import 'package:bar/bar.dart'; // OK
import 'package:foo/bar.dart'; // OK

import 'a.dart'; // OK
import 'a/b.dart'; // OK

''';
const _directiveSectionOrderedAlphabetically =
    'Sort directive sections alphabetically.';

const _exportDirectiveAfterImportDirectives =
    'Specify exports in a separate section after all imports.';

const _exportKeyword = 'export';

const _importKeyword = 'import';

String _dartDirectiveGoFirst(String type) =>
    "Place 'dart:' ${type}s before other ${type}s.";

bool _isAbsoluteDirective(NamespaceDirective node) =>
    node.uriContent.contains(':');

bool _isDartDirective(NamespaceDirective node) =>
    node.uriContent.startsWith('dart:');

bool _isExportDirective(Directive node) => node is ExportDirective;

bool _isImportDirective(Directive node) => node is ImportDirective;

bool _isNotDartDirective(NamespaceDirective node) => !_isDartDirective(node);

bool _isPackageDirective(NamespaceDirective node) =>
    node.uriContent.startsWith('package:');

bool _isPartDirective(Directive node) => node is PartDirective;

bool _isRelativeDirective(NamespaceDirective node) =>
    !_isAbsoluteDirective(node);

String _packageDirectiveBeforeRelative(String type) =>
    "Place 'package:' ${type}s before relative ${type}s.";

String _thirdPartyPackageDirectiveBeforeOwn(String type) =>
    "Place 'third-party' 'package:' ${type}s before other ${type}s.";

class DirectivesOrdering extends LintRule
    implements ProjectVisitor, NodeLintRule {
  DartProject project;

  DirectivesOrdering()
      : super(
            name: 'directives_ordering',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  ProjectVisitor getProjectVisitor() => this;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }

  @override
  void visit(DartProject project) {
    this.project = project;
  }

  void _reportLintWithDartDirectiveGoFirstMessage(AstNode node, String type) {
    _reportLintWithDescription(node, _dartDirectiveGoFirst(type));
  }

  void _reportLintWithDescription(AstNode node, String description) {
    reporter.reportErrorForNode(LintCode(name, description), node, []);
  }

  void _reportLintWithDirectiveSectionOrderedAlphabeticallyMessage(
      AstNode node) {
    _reportLintWithDescription(node, _directiveSectionOrderedAlphabetically);
  }

  void _reportLintWithExportDirectiveAfterImportDirectiveMessage(AstNode node) {
    _reportLintWithDescription(node, _exportDirectiveAfterImportDirectives);
  }

  void _reportLintWithPackageDirectiveBeforeRelativeMessage(
      AstNode node, String type) {
    _reportLintWithDescription(node, _packageDirectiveBeforeRelative(type));
  }

  void _reportLintWithThirdPartyPackageDirectiveBeforeOwnMessage(
      AstNode node, String type) {
    _reportLintWithDescription(
        node, _thirdPartyPackageDirectiveBeforeOwn(type));
  }
}

class _PackageBox {
  final String _packageName;

  _PackageBox(this._packageName);

  bool _isNotOwnPackageDirective(NamespaceDirective node) =>
      _isPackageDirective(node) && !_isOwnPackageDirective(node);

  bool _isOwnPackageDirective(NamespaceDirective node) =>
      node.uriContent.startsWith('package:$_packageName/');
}

class _Visitor extends SimpleAstVisitor<void> {
  final DirectivesOrdering rule;

  _Visitor(this.rule);

  DartProject get project => rule.project;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final lintedNodes = <AstNode>{};
    _checkDartDirectiveGoFirst(lintedNodes, node);
    _checkPackageDirectiveBeforeRelative(lintedNodes, node);
    _checkThirdPartyDirectiveBeforeOwn(lintedNodes, node);
    _checkExportDirectiveAfterImportDirective(lintedNodes, node);
    _checkDirectiveSectionOrderedAlphabetically(lintedNodes, node);
  }

  void _checkDartDirectiveGoFirst(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    void reportImport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithDartDirectiveGoFirstMessage(
            directive, _importKeyword);
      }
    }

    void reportExport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithDartDirectiveGoFirstMessage(
            directive, _exportKeyword);
      }
    }

    Iterable<NamespaceDirective> getNodesToLint(
            Iterable<NamespaceDirective> directives) =>
        directives.skipWhile(_isDartDirective).where(_isDartDirective);

    getNodesToLint(_getImportDirectives(node)).forEach(reportImport);

    getNodesToLint(_getExportDirectives(node)).forEach(reportExport);
  }

  void _checkDirectiveSectionOrderedAlphabetically(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    final importDirectives = _getImportDirectives(node);
    final exportDirectives = _getExportDirectives(node);

    final dartImports = importDirectives.where(_isDartDirective);
    final dartExports = exportDirectives.where(_isDartDirective);

    final relativeImports = importDirectives.where(_isRelativeDirective);
    final relativeExports = exportDirectives.where(_isRelativeDirective);

    _checkSectionInOrder(lintedNodes, dartImports);
    _checkSectionInOrder(lintedNodes, dartExports);

    _checkSectionInOrder(lintedNodes, relativeImports);
    _checkSectionInOrder(lintedNodes, relativeExports);

    if (project != null) {
      final packageBox = _PackageBox(project.name);

      final thirdPartyPackageImports =
          importDirectives.where(packageBox._isNotOwnPackageDirective);
      final thirdPartyPackageExports =
          exportDirectives.where(packageBox._isNotOwnPackageDirective);

      final ownPackageImports =
          importDirectives.where(packageBox._isOwnPackageDirective);
      final ownPackageExports =
          exportDirectives.where(packageBox._isOwnPackageDirective);

      _checkSectionInOrder(lintedNodes, thirdPartyPackageImports);
      _checkSectionInOrder(lintedNodes, thirdPartyPackageExports);

      _checkSectionInOrder(lintedNodes, ownPackageImports);
      _checkSectionInOrder(lintedNodes, ownPackageExports);
    }
  }

  void _checkExportDirectiveAfterImportDirective(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    void reportDirective(Directive directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithExportDirectiveAfterImportDirectiveMessage(
            directive);
      }
    }

    node.directives.reversed
        .skipWhile(_isPartDirective)
        .skipWhile(_isExportDirective)
        .where(_isExportDirective)
        .forEach(reportDirective);
  }

  void _checkPackageDirectiveBeforeRelative(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    void reportImport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithPackageDirectiveBeforeRelativeMessage(
            directive, _importKeyword);
      }
    }

    void reportExport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithPackageDirectiveBeforeRelativeMessage(
            directive, _exportKeyword);
      }
    }

    Iterable<NamespaceDirective> getNodesToLint(
            Iterable<NamespaceDirective> directives) =>
        directives
            .where(_isNotDartDirective)
            .skipWhile(_isAbsoluteDirective)
            .where(_isPackageDirective);

    getNodesToLint(_getImportDirectives(node)).forEach(reportImport);

    getNodesToLint(_getExportDirectives(node)).forEach(reportExport);
  }

  void _checkSectionInOrder(
      Set<AstNode> lintedNodes, Iterable<NamespaceDirective> nodes) {
    void reportDirective(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithDirectiveSectionOrderedAlphabeticallyMessage(
            directive);
      }
    }

    NamespaceDirective previousDirective;
    for (var directive in nodes) {
      if (previousDirective != null &&
          previousDirective.uriContent.compareTo(directive.uriContent) > 0) {
        reportDirective(directive);
      }
      previousDirective = directive;
    }
  }

  void _checkThirdPartyDirectiveBeforeOwn(
      Set<AstNode> lintedNodes, CompilationUnit node) {
    if (project == null) {
      return;
    }

    void reportImport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithThirdPartyPackageDirectiveBeforeOwnMessage(
            directive, _importKeyword);
      }
    }

    void reportExport(NamespaceDirective directive) {
      if (lintedNodes.add(directive)) {
        rule._reportLintWithThirdPartyPackageDirectiveBeforeOwnMessage(
            directive, _exportKeyword);
      }
    }

    Iterable<NamespaceDirective> getNodesToLint(
        Iterable<NamespaceDirective> directives) {
      final box = _PackageBox(project.name);
      return directives
          .where(_isPackageDirective)
          .skipWhile(box._isNotOwnPackageDirective)
          .where(box._isNotOwnPackageDirective);
    }

    getNodesToLint(_getImportDirectives(node)).forEach(reportImport);

    getNodesToLint(_getExportDirectives(node)).forEach(reportExport);
  }

  Iterable<ExportDirective> _getExportDirectives(CompilationUnit node) =>
      node.directives
          .where(_isExportDirective)
          .map((e) => e as ExportDirective);

  Iterable<ImportDirective> _getImportDirectives(CompilationUnit node) =>
      node.directives
          .where(_isImportDirective)
          .map((e) => e as ImportDirective);
}
