// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Prefer final for variable declarations if they are not reassigned.';

const _details = r'''
**DO** prefer declaring variables as final if they are not reassigned later in
the code.

Declaring variables as final when possible is a good practice because it helps
avoid accidental reassignments and allows the compiler to do optimizations.

**BAD:**
```dart
void badMethod() {
  var label = 'hola mundo! badMethod'; // LINT
  print(label);
}
```

**GOOD:**
```dart
void goodMethod() {
  final label = 'hola mundo! goodMethod';
  print(label);
}
```

**GOOD:**
```dart
void mutableCase() {
  var label = 'hola mundo! mutableCase';
  print(label);
  label = 'hello world';
  print(label);
}
```

''';

class PreferFinalLocals extends LintRule {
  static const LintCode code = LintCode(
      'prefer_final_locals', 'Local variables should be final.',
      correctionMessage: 'Try making the variable final.');

  PreferFinalLocals()
      : super(
            name: 'prefer_final_locals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['unnecessary_final'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addListPattern(this, visitor);
    registry.addMapPattern(this, visitor);
    registry.addObjectPattern(this, visitor);
    registry.addRecordPattern(this, visitor);
    registry.addVariableDeclarationList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void checkPatternFields(DartPattern node) {
    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    late NodeList<PatternField> fields;
    if (node is RecordPattern) fields = node.fields;
    if (node is ObjectPattern) fields = node.fields;

    var parent = node.unParenthesized.parent;
    var inPatternVariableDeclaration = false;
    if (parent is PatternVariableDeclaration) {
      if (parent.keyword.keyword == Keyword.FINAL) return;
      inPatternVariableDeclaration = true;
    }

    for (var field in fields) {
      var pattern = field.pattern.declaredVariablePattern;
      if (pattern is DeclaredVariablePattern) {
        var element = pattern.declaredElement;
        if (element == null) continue;
        if (function.isPotentiallyMutatedInScope(element)) {
          if (inPatternVariableDeclaration) {
            return;
          } else {
            continue;
          }
        }
        if (inPatternVariableDeclaration) {
          rule.reportLint((parent! as PatternVariableDeclaration).expression);
          return;
        } else {
          if (!pattern.keyword.isFinal) {
            rule.reportLintForToken(pattern.name);
          }
        }
      }
    }
  }

  bool isDeclaredFinal(AstNode node) {
    var declaration = node.thisOrAncestorOfType<PatternVariableDeclaration>();
    if (declaration == null) return false; // To be safe.
    return declaration.keyword.isFinal;
  }

  bool isPotentiallyMutated(AstNode pattern, FunctionBody function) {
    if (pattern is DeclaredVariablePattern) {
      var element = pattern.declaredElement;
      if (element == null || function.isPotentiallyMutatedInScope(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  void visitListPattern(ListPattern node) {
    if (isDeclaredFinal(node)) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    for (var element in node.elements) {
      if (isPotentiallyMutated(element, function)) return;
    }

    rule.reportLint(node);
  }

  @override
  void visitMapPattern(MapPattern node) {
    if (isDeclaredFinal(node)) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    for (var element in node.elements) {
      if (element is MapPatternEntry) {
        if (isPotentiallyMutated(element.value, function)) return;
      }
    }

    rule.reportLint(node);
  }

  @override
  void visitObjectPattern(ObjectPattern node) {
    checkPatternFields(node);
  }

  @override
  void visitRecordPattern(RecordPattern node) {
    checkPatternFields(node);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.isConst || node.isFinal) return;

    var function = node.thisOrAncestorOfType<FunctionBody>();
    if (function == null) return;

    for (var variable in node.variables) {
      if (variable.equals == null || variable.initializer == null) {
        return;
      }
      var declaredElement = variable.declaredElement;
      if (declaredElement != null &&
          function.isPotentiallyMutatedInScope(declaredElement)) {
        return;
      }
    }
    if (node.keyword != null) {
      rule.reportLintForToken(node.keyword);
    } else if (node.type != null) {
      rule.reportLint(node.type);
    }
  }
}

extension on Token? {
  bool get isFinal {
    var self = this;
    if (self == null) return false;
    return self.keyword == Keyword.FINAL;
  }
}

extension on DartPattern {
  DeclaredVariablePattern? get declaredVariablePattern {
    var self = this;
    if (self is DeclaredVariablePattern) return self;
    // todo(pq): more cases?
    if (self is LogicalAndPattern) {
      return self.rightOperand.declaredVariablePattern;
    }
    return null;
  }
}
