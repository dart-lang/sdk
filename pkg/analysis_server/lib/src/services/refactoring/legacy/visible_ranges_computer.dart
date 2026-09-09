// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Computer of local elements and source ranges in which they are visible.
class VisibleRangesComputer extends GeneralizingAstVisitor<void> {
  final Map<LocalElement, SourceRange> _map = {};

  @override
  void visitCatchClause(CatchClause node) {
    _addLocalVariable(node, node.exceptionParameter?.declaredFragment?.element);
    _addLocalVariable(
      node,
      node.stackTraceParameter?.declaredFragment?.element,
    );
    node.body.accept(this);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    var visibleRange = _patternVariableRange(node);
    if (visibleRange != null) {
      _addLocalVariableRange(visibleRange, node.declaredFragment?.element);
    }

    super.visitDeclaredVariablePattern(node);
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    // Unlike the parts of a `for` loop, the iterable is evaluated outside the
    // scope of the loop variable, so the variable is only visible in the body.
    var loop = node.parent;
    _addLocalVariable(loop.body, node.loopVariable.declaredFragment?.element);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitFormalParameter(FormalParameter node) {
    var element = node.declaredFragment?.element;
    if (element is FormalParameterElement) {
      var body = _getFunctionBody(node);
      if (body is BlockFunctionBody) {
        _map[element] = range.node(body);
      } else if (body is ExpressionFunctionBody) {
        _map[element] = range.node(body);
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    var loop = node.parent;
    for (var variable in node.variables.variables) {
      _addLocalVariable(loop, variable.declaredFragment?.element);
      variable.initializer?.accept(this);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    var block = node.parent?.parent;
    if (block is Block) {
      var element = node.declaredFragment?.element as LocalFunctionElement;
      _map[element] = range.node(block);
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    var block = node.parent;
    if (block != null) {
      for (var variable in node.variables.variables) {
        _addLocalVariable(block, variable.declaredFragment?.element);
        variable.initializer?.accept(this);
      }
    }
  }

  void _addLocalVariable(AstNode scopeNode, Element? element) {
    _addLocalVariableRange(range.node(scopeNode), element);
  }

  void _addLocalVariableRange(SourceRange visibleRange, Element? element) {
    // TODO(brianwilkerson): Figure out whether this should be testing for
    //  `PromotableElement`. The test is missing parameter elements.
    if (element is LocalElement) {
      _map[element] = visibleRange;
    }
  }

  static Map<LocalElement, SourceRange> forNode(AstNode unit) {
    var computer = VisibleRangesComputer();
    unit.accept(computer);
    return computer._map;
  }

  /// Return the body of the function that contains the given [parameter], or
  /// `null` if no function body could be found.
  static FunctionBody? _getFunctionBody(FormalParameter parameter) {
    var parent = parameter.parent?.parent;
    if (parent is ConstructorDeclaration) {
      return parent.body;
    } else if (parent is FunctionExpression) {
      return parent.body;
    } else if (parent is MethodDeclaration) {
      return parent.body;
    }
    return null;
  }

  /// Returns the last member of the group of switch members that share the
  /// statements of the group containing [member].
  ///
  /// Members other than the last in a group have no statements of their own,
  /// as in `case a: case b: statements`.
  static SwitchMember _lastMemberOfGroup(SwitchMember member) {
    var parent = member.parent;
    if (parent is! SwitchStatement) {
      return member;
    }
    var members = parent.members;
    var index = members.indexOf(member);
    if (index < 0) {
      return member;
    }
    for (var i = index; i < members.length; i++) {
      if (members[i].statements.isNotEmpty) {
        return members[i];
      }
    }
    return members.last;
  }

  /// Returns the range in which the variable declared by [node] is visible, or
  /// `null` if the pattern isn't in a construct that declares variables.
  static SourceRange? _patternVariableRange(DeclaredVariablePattern node) {
    // Walk out of the (possibly nested) pattern to the construct introducing
    // the variables it declares.
    for (
      AstNode? current = node.parent;
      current != null;
      current = current.parent
    ) {
      switch (current) {
        // `if (x case p) then else otherwise`, or the collection element
        // equivalent. The variables are visible in the guard and the `then`
        // branch, but not in the `else` branch.
        case CaseClause caseClause:
          return switch (caseClause.parent) {
            IfStatement ifStatement => range.startEnd(
              caseClause,
              ifStatement.thenStatement,
            ),
            IfElement ifElement => range.startEnd(
              caseClause,
              ifElement.thenElement,
            ),
            _ => null,
          };
        // `for (var p in iterable)`. The iterable is evaluated outside the
        // scope of the variables, so they're only visible in the body.
        case ForEachPartsWithPattern forEachParts:
          return range.node(forEachParts.parent.body);
        case PatternVariableDeclaration declaration:
          var parent = declaration.parent;
          // `var p = expression;`, visible in the enclosing block.
          if (parent is PatternVariableDeclarationStatement) {
            var block = parent.parent;
            return block != null ? range.node(block) : null;
          }
          // `for (var p = expression; ...; ...)`. Unlike the iterable of a
          // for-each loop, the rest of the loop is in the scope of the
          // variables, so they're visible in the whole loop.
          if (parent is ForPartsWithPattern) {
            return range.node(parent.parent);
          }
          return null;
        // `case p when guard => expression`. The variables are visible in the
        // guard and the expression.
        case SwitchExpressionCase switchCase:
          return range.node(switchCase);
        // `case p when guard: statements`. The variables are visible in the
        // guard and in the statements shared by the group of members.
        case SwitchPatternCase switchCase:
          return range.startEnd(switchCase, _lastMemberOfGroup(switchCase));
      }
    }
    return null;
  }
}
