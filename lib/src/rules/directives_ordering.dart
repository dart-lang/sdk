// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.directives_ordering;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Adhere to Effective Dart Guide directives sorting conventions.';
const _dartImportGoFirst = r"Place 'dart:' imports before other imports.";
const _packageImportBeforeRelative =
    r"Place 'package:' imports before relative imports.";
const _details =
    r'''**DO** follow the conventions in the [Effective Dart Guide](https://www.dartlang.org/guides/language/effective-dart/style#ordering)

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

''';

bool _isDartImport(Directive node) =>
    (node as ImportDirective).uriContent.startsWith("dart:");

bool _isImportDirective(Directive node) => node is ImportDirective;

bool _isNotDartImport(Directive node) => !_isDartImport(node);

bool _isPackageImport(Directive node) =>
    (node as ImportDirective).uriContent.startsWith("package:");

bool _isAbsoluteImport(Directive node) =>
    (node as ImportDirective).uriContent.contains(":");

class DirectivesOrdering extends LintRule {
  _Visitor _visitor;

  DirectivesOrdering()
      : super(
            name: 'directives_ordering',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;

  void _reportLintWithDartImportGoFirstMessage(AstNode node) {
    _reportLintWithDescription(node, _dartImportGoFirst);
  }

  void _reportLintWithDescription(AstNode node, String description) {
    if (node == null) {
      return;
    }
    reporter.reportErrorForNode(new LintCode(name, description), node, []);
  }

  void _reportLintWithPackageImportBeforeRelativeMessage(AstNode node) {
    _reportLintWithDescription(node, _packageImportBeforeRelative);
  }
}

class _Visitor extends SimpleAstVisitor {
  final DirectivesOrdering rule;
  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    _checkDartImportGoFirst(node);
    _checkPackageImportBeforeRelative(node);
  }

  void _checkDartImportGoFirst(CompilationUnit node) {
    node.directives
        .where(_isImportDirective)
        .skipWhile(_isDartImport)
        .where(_isDartImport)
        .forEach(rule._reportLintWithDartImportGoFirstMessage);
  }

  void _checkPackageImportBeforeRelative(CompilationUnit node) {
    node.directives
        .where(_isImportDirective)
        .where(_isNotDartImport)
        .skipWhile(_isAbsoluteImport)
        .where(_isPackageImport)
        .forEach(rule._reportLintWithPackageImportBeforeRelativeMessage);
  }
}
