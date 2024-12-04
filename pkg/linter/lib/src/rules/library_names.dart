// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Name libraries using `lowercase_with_underscores`.';

class LibraryNames extends LintRule {
  LibraryNames()
      : super(
          name: LintNames.library_names,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.library_names;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addLibraryDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitLibraryDirective(LibraryDirective node) {
    var name = node.name2;
    if (name != null && !isLowerCaseUnderScoreWithDots(name.toString())) {
      rule.reportLint(name, arguments: [name.toString()]);
    }
  }
}
