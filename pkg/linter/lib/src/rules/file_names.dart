// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Name source files using `lowercase_with_underscores`.';

class FileNames extends LintRule {
  FileNames()
      : super(
          name: LintNames.file_names,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.file_names;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    var element = node.declaredFragment?.element;
    if (element != null) {
      var fileName = element.library2.firstFragment.source.shortName;
      if (!isValidDartFileName(fileName)) {
        rule.reportLintForOffset(0, 0, arguments: [fileName]);
      }
    }
  }
}
