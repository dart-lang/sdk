// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.directives_ordering;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _dartImportGoFirst = r"Place 'dart:' imports before other imports.";

const _desc = r'Adhere to Effective Dart Guide directives sorting conventions.';

const _details = r'''**DO** follow the conventions in the [Effective Dart Guide]
(https://www.dartlang.org/guides/language/effective-dart/style#ordering)

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

''';

bool _isDartImport(Directive node) =>
    (node as ImportDirective).uriContent.startsWith("dart:");

bool _isImportDirective(Directive node) => node is ImportDirective;

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
}

class _Visitor extends SimpleAstVisitor {
  final DirectivesOrdering rule;
  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.directives
        .where(_isImportDirective)
        .skipWhile(_isDartImport)
        .where(_isDartImport)
        .forEach(rule._reportLintWithDartImportGoFirstMessage);
  }
}
