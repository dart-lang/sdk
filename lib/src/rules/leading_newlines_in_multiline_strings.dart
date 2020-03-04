// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Start multiline strings with a newline.';

const _details = r"""
Multiline strings are easier to read when they start with a newline (a newline
starting a multiline string is ignored).

**BAD:**
```
var s1 = '''{
  "a": 1,
  "b": 2
}''';
```

**GOOD:**
```
var s1 = '''
{
  "a": 1,
  "b": 2
}''';

var s2 = '''This onliner multiline string is ok. It usually allows to escape both ' and " in the string.''';
```

""";

class LeadingNewlinesInMultilineStrings extends LintRule
    implements NodeLintRule {
  LeadingNewlinesInMultilineStrings()
      : super(
            name: 'leading_newlines_in_multiline_strings',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = _Visitor(this);
    registry.addCompilationUnit(this, visitor);
    registry.addSimpleStringLiteral(this, visitor);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final LintRule rule;

  LineInfo lineInfo;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    lineInfo = node.lineInfo;
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    _visitSingleStringLiteral(node, node.literal.lexeme);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    _visitSingleStringLiteral(
        node, (node.elements.first as InterpolationString).contents.lexeme);
  }

  void _visitSingleStringLiteral(SingleStringLiteral node, String lexeme) {
    if (node.isMultiline &&
        lineInfo.getLocation(node.offset).lineNumber !=
            lineInfo.getLocation(node.end).lineNumber) {
      bool startWithNewLine(int index) =>
          lexeme.startsWith('\n', index) || lexeme.startsWith('\r', index);
      if (!startWithNewLine(node.isRaw ? 4 : 3)) {
        rule.reportLint(node);
      }
    }
  }
}
