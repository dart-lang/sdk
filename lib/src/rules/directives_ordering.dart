// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Adhere to Effective Dart Guide directives sorting conventions.';
const _details = r'''
**DO** follow the directive ordering conventions in
[Effective Dart](https://dart.dev/effective-dart/style#ordering):

**DO** place `dart:` imports before other imports.

**BAD:**
```dart
import 'package:bar/bar.dart';
import 'package:foo/foo.dart';

import 'dart:async';  // LINT
import 'dart:html';  // LINT
```

**BAD:**
```dart
import 'dart:html';  // OK
import 'package:bar/bar.dart';

import 'dart:async';  // LINT
import 'package:foo/foo.dart';
```

**GOOD:**
```dart
import 'dart:async';  // OK
import 'dart:html';  // OK

import 'package:bar/bar.dart';
import 'package:foo/foo.dart';
```

**DO** place `package:` imports before relative imports.

**BAD:**
```dart
import 'a.dart';
import 'b.dart';

import 'package:bar/bar.dart';  // LINT
import 'package:foo/foo.dart';  // LINT
```

**BAD:**
```dart
import 'package:bar/bar.dart';  // OK
import 'a.dart';

import 'package:foo/foo.dart';  // LINT
import 'b.dart';
```

**GOOD:**
```dart
import 'package:bar/bar.dart';  // OK
import 'package:foo/foo.dart';  // OK

import 'a.dart';
import 'b.dart';
```

**DO** specify exports in a separate section after all imports.

**BAD:**
```dart
import 'src/error.dart';
export 'src/error.dart'; // LINT
import 'src/string_source.dart';
```

**GOOD:**
```dart
import 'src/error.dart';
import 'src/string_source.dart';

export 'src/error.dart'; // OK
```

**DO** sort sections alphabetically.

**BAD:**
```dart
import 'package:foo/bar.dart'; // OK
import 'package:bar/bar.dart'; // LINT

import 'a/b.dart'; // OK
import 'a.dart'; // LINT
```

**GOOD:**
```dart
import 'package:bar/bar.dart'; // OK
import 'package:foo/bar.dart'; // OK

import 'a.dart'; // OK
import 'a/b.dart'; // OK
```
''';

const _exportKeyword = 'export';

const _importKeyword = 'import';

/// Compares directives by package then file in package.
///
/// Package is everything until the first `/`.
int compareDirectives(String a, String b) {
  if (!a.startsWith('package:') || !b.startsWith('package:')) {
    return a.compareTo(b);
  }
  var indexA = a.indexOf('/');
  var indexB = b.indexOf('/');
  if (indexA == -1 || indexB == -1) return a.compareTo(b);
  var result = a.substring(0, indexA).compareTo(b.substring(0, indexB));
  if (result != 0) return result;
  return a.substring(indexA + 1).compareTo(b.substring(indexB + 1));
}

bool _isAbsoluteDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.contains(':');
}

bool _isDartDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.startsWith('dart:');
}

bool _isExportDirective(Directive node) => node is ExportDirective;

bool _isNotDartDirective(NamespaceDirective node) => !_isDartDirective(node);

bool _isPackageDirective(NamespaceDirective node) {
  var uriContent = node.uri.stringValue;
  return uriContent != null && uriContent.startsWith('package:');
}

bool _isPartDirective(Directive node) => node is PartDirective;

bool _isRelativeDirective(NamespaceDirective node) =>
    !_isAbsoluteDirective(node);

class DirectivesOrdering extends LintRule {
  static const LintCode dartDirectiveGoFirst = LintCode(
      'directives_ordering', "Place 'dart:' {0}s before other {0}s.",
      correctionMessage: 'Try sorting the directives.');

  static const LintCode directiveSectionOrderedAlphabetically = LintCode(
      'directives_ordering', 'Sort directive sections alphabetically.',
      correctionMessage: 'Try sorting the directives.');

  static const LintCode exportDirectiveAfterImportDirectives = LintCode(
      'directives_ordering',
      'Specify exports in a separate section after all imports.',
      correctionMessage: 'Try sorting the directives.');

  static const LintCode packageDirectiveBeforeRelative = LintCode(
      'directives_ordering', "Place 'package:' {0}s before relative {0}s.",
      correctionMessage: 'Try sorting the directives.');

  DirectivesOrdering()
      : super(
            name: 'directives_ordering',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }

  void _reportLintWithDartDirectiveGoFirstMessage(AstNode node, String type) {
    reportLint(node,
        errorCode: DirectivesOrdering.dartDirectiveGoFirst, arguments: [type]);
  }

  void _reportLintWithDirectiveSectionOrderedAlphabeticallyMessage(
      AstNode node) {
    reportLint(node,
        errorCode: DirectivesOrdering.directiveSectionOrderedAlphabetically);
  }

  void _reportLintWithExportDirectiveAfterImportDirectiveMessage(AstNode node) {
    reportLint(node,
        errorCode: DirectivesOrdering.exportDirectiveAfterImportDirectives);
  }

  void _reportLintWithPackageDirectiveBeforeRelativeMessage(
      AstNode node, String type) {
    reportLint(node,
        errorCode: DirectivesOrdering.packageDirectiveBeforeRelative,
        arguments: [type]);
  }
}

// ignore: unused_element
class _PackageBox {
  final String _packageName;

  _PackageBox(this._packageName);

  // ignore: unused_element
  bool _isNotOwnPackageDirective(NamespaceDirective node) =>
      _isPackageDirective(node) && !_isOwnPackageDirective(node);

  bool _isOwnPackageDirective(NamespaceDirective node) {
    var uriContent = node.uri.stringValue;
    return uriContent != null &&
        uriContent.startsWith('package:$_packageName/');
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final DirectivesOrdering rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var lintedNodes = <AstNode>{};
    _checkDartDirectiveGoFirst(lintedNodes, node);
    _checkPackageDirectiveBeforeRelative(lintedNodes, node);
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
    var importDirectives = _getImportDirectives(node);
    var exportDirectives = _getExportDirectives(node);

    var dartImports = importDirectives.where(_isDartDirective);
    var dartExports = exportDirectives.where(_isDartDirective);

    var relativeImports = importDirectives.where(_isRelativeDirective);
    var relativeExports = exportDirectives.where(_isRelativeDirective);

    _checkSectionInOrder(lintedNodes, dartImports);
    _checkSectionInOrder(lintedNodes, dartExports);

    _checkSectionInOrder(lintedNodes, relativeImports);
    _checkSectionInOrder(lintedNodes, relativeExports);

    // See: https://github.com/dart-lang/linter/issues/3395
    // (`DartProject` removal)
    // The rub is that *all* projects are being treated as "not pub"
    // packages.  We'll want to be careful when fixing this since it
    // will have ecosystem impact.

    // Not a pub package. Package directives should be sorted in one block.
    var packageImports = importDirectives.where(_isPackageDirective);
    var packageExports = exportDirectives.where(_isPackageDirective);

    _checkSectionInOrder(lintedNodes, packageImports);
    _checkSectionInOrder(lintedNodes, packageExports);

    // The following is relying on projectName which is meant to come from
    // a `DartProject` instance (but was not since the project was always null)
    // else {
    //   var packageBox = _PackageBox(projectName);
    //
    //   var thirdPartyPackageImports =
    //       importDirectives.where(packageBox._isNotOwnPackageDirective);
    //   var thirdPartyPackageExports =
    //       exportDirectives.where(packageBox._isNotOwnPackageDirective);
    //
    //   var ownPackageImports =
    //       importDirectives.where(packageBox._isOwnPackageDirective);
    //   var ownPackageExports =
    //       exportDirectives.where(packageBox._isOwnPackageDirective);
    //
    //   _checkSectionInOrder(lintedNodes, thirdPartyPackageImports);
    //   _checkSectionInOrder(lintedNodes, thirdPartyPackageExports);
    //
    //   _checkSectionInOrder(lintedNodes, ownPackageImports);
    //   _checkSectionInOrder(lintedNodes, ownPackageExports);
    // }
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

    NamespaceDirective? previousDirective;
    for (var directive in nodes) {
      if (previousDirective != null) {
        var previousUri = previousDirective.uri.stringValue;
        var directiveUri = directive.uri.stringValue;
        if (previousUri != null &&
            directiveUri != null &&
            compareDirectives(previousUri, directiveUri) > 0) {
          reportDirective(directive);
        }
      }
      previousDirective = directive;
    }
  }

  Iterable<ExportDirective> _getExportDirectives(CompilationUnit node) =>
      node.directives.whereType<ExportDirective>();

  Iterable<ImportDirective> _getImportDirectives(CompilationUnit node) =>
      node.directives.whereType<ImportDirective>();
}
