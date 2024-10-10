// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't have a library name in a `library` declaration.";

class UnnecessaryLibraryName extends LintRule {
  UnnecessaryLibraryName()
      : super(
          name: LintNames.unnecessary_library_name,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_library_name;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.unnamedLibraries)) return;

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
    if (name != null) {
      rule.reportLint(name);
    }
  }
}
