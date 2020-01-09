// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = 'Prefer int literals over double literals.';

const _details = '''

**DO** use int literals rather than the corresponding double literal.

**BAD:**
```
const double myDouble = 8.0;
final anotherDouble = myDouble + 7.0e2;
main() {
  someMethod(6.0);
}
```

**GOOD:**
```
const double myDouble = 8;
final anotherDouble = myDouble + 700;
main() {
  someMethod(6);
}
```

''';

class PreferIntLiterals extends LintRule implements NodeLintRule {
  PreferIntLiterals()
      : super(
            name: 'prefer_int_literals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    registry.addDoubleLiteral(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  /// Determine if the given literal can be replaced by an int literal.
  bool canReplaceWithIntLiteral(DoubleLiteral literal) {
    // TODO(danrubel): Consider moving this into analyzer
    final parent = literal.parent;
    if (parent is PrefixExpression) {
      if (parent.operator?.lexeme == '-') {
        return hasTypeDouble(parent);
      } else {
        return false;
      }
    }
    return hasTypeDouble(literal);
  }

  bool hasReturnTypeDouble(AstNode node) {
    if (node is FunctionExpression) {
      final functionDeclaration = node.parent;
      if (functionDeclaration is FunctionDeclaration) {
        return _isDartCoreDoubleTypeAnnotation(functionDeclaration.returnType);
      }
    } else if (node is MethodDeclaration) {
      return _isDartCoreDoubleTypeAnnotation(node.returnType);
    }
    return false;
  }

  bool hasTypeDouble(Expression expression) {
    final parent = expression.parent;
    if (parent is ArgumentList) {
      return _isDartCoreDouble(expression.staticParameterElement?.type);
    } else if (parent is ListLiteral) {
      final typeArguments = parent.typeArguments?.arguments;
      return typeArguments?.length == 1 &&
          _isDartCoreDoubleTypeAnnotation(typeArguments[0]);
    } else if (parent is NamedExpression) {
      final argList = parent.parent;
      if (argList is ArgumentList) {
        return _isDartCoreDouble(parent.staticParameterElement?.type);
      }
    } else if (parent is ExpressionFunctionBody) {
      return hasReturnTypeDouble(parent.parent);
    } else if (parent is ReturnStatement) {
      final body = parent.thisOrAncestorOfType<BlockFunctionBody>();
      return hasReturnTypeDouble(body.parent);
    } else if (parent is VariableDeclaration) {
      final varList = parent.parent;
      if (varList is VariableDeclarationList) {
        return _isDartCoreDoubleTypeAnnotation(varList.type);
      }
    }
    return false;
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    // Check if the double can be represented as an int
    try {
      final value = node.value;
      if (value == null || value != value.truncate()) {
        return;
      }
      // ignore: avoid_catching_errors
    } on UnsupportedError catch (_) {
      // The double cannot be represented as an int
      return;
    }

    // Ensure that replacing the double would not change the semantics
    if (canReplaceWithIntLiteral(node)) {
      rule.reportLint(node);
    }
  }

  bool _isDartCoreDouble(DartType type) => type?.isDartCoreDouble == true;

  bool _isDartCoreDoubleTypeAnnotation(TypeAnnotation annotation) =>
      _isDartCoreDouble(annotation?.type);
}
