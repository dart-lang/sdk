// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_collector.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// A helper class that produces candidate suggestions for all of the
/// declarations that are in scope at the completion location.
class DeclarationHelper {
  /// The regular expression used to detect an unused identifier (a sequence of
  /// one or more underscodes with no other characters).
  static final RegExp UnusedIdentifier = RegExp(r'^_+$');

  /// The suggestion collector to which suggestions will be added.
  final SuggestionCollector collector;

  /// The offset of the completion location.
  final int offset;

  /// The visibility tracker used to prevent suggesting elements that have been
  /// shadowed by local declarations.
  final _VisibilityTracker _visibilityTracker = _VisibilityTracker();

  /// A flag indicating whether suggestions should be limited to only include
  /// valid constants.
  bool mustBeConstant = false;

  /// The number of local variables that have already been suggested.
  int _variableDistance = 0;

  /// Initialize a newly created helper to add suggestions to the [collector].
  DeclarationHelper({required this.collector, required this.offset});

  /// Add any declarations that are visible at the completion location,
  /// given that the completion location is within the [node]. This includes
  /// local variables, local functions, and parameters. If [mustBeConstant] is `true`, then
  /// only constants will be suggested.
  void addLexicalDeclarations(AstNode node, {bool mustBeConstant = false}) {
    this.mustBeConstant = mustBeConstant;
    _addLocalDeclarations(node);
  }

  void addMembersOfType(DartType type) {
    // TODO(brianwilkerson) Implement this.
  }

  /// Add any local declarations that are visible at the completion location,
  /// given that the completion location is within the [node]. This includes
  /// local variables, local functions, and parameters. Return the member
  /// containing the local declarations that were added, or `null` if there is
  /// an error such as the AST being malformed or we encountered an AST
  /// structure that isn't handled correctly.
  AstNode? _addLocalDeclarations(AstNode node) {
    AstNode? previousNode;
    AstNode? currentNode = node;
    while (currentNode != null) {
      switch (currentNode) {
        case Block():
          _visitStatements(currentNode.statements, previousNode);
        case CatchClause():
          _visitCatchClause(currentNode);
        case CommentReference():
          return _visitCommentReference(currentNode);
        case ConstructorDeclaration():
          _visitParameterList(currentNode.parameters);
          return currentNode;
        case DeclaredVariablePattern():
          _visitDeclaredVariablePattern(currentNode);
        case FieldDeclaration():
          return currentNode;
        case ForElement(forLoopParts: var parts):
        case ForStatement(forLoopParts: var parts):
          if (parts != previousNode) {
            _visitForLoopParts(parts);
          }
        case ForPartsWithDeclarations(:var variables):
          if (variables != previousNode) {
            _visitForLoopParts(currentNode);
          }
        case FunctionDeclaration(:var parent):
          if (parent is! FunctionDeclarationStatement) {
            return currentNode;
          }
        case FunctionExpression():
          _visitParameterList(currentNode.parameters);
        case IfElement():
          _visitIfElement(currentNode);
        case IfStatement():
          _visitIfStatement(currentNode);
        case MethodDeclaration():
          _visitParameterList(currentNode.parameters);
          return currentNode;
        case SwitchCase():
          _visitStatements(currentNode.statements, previousNode);
        case SwitchDefault():
          _visitStatements(currentNode.statements, previousNode);
        case SwitchExpressionCase():
          _visitSwitchExpressionCase(currentNode);
        case SwitchPatternCase():
          _visitSwitchPatternCase(currentNode, previousNode);
        case VariableDeclarationList():
          _visitVariableDeclarationList(currentNode, previousNode);
      }
      previousNode = currentNode;
      currentNode = currentNode.parent;
    }
    return currentNode;
  }

  /// Return `true` if the [identifier] is composed of one or more underscore
  /// characters and nothing else.
  bool _isUnused(String identifier) => UnusedIdentifier.hasMatch(identifier);

  /// Add a suggestion for the local function represented by the [element].
  void _suggestFunction(ExecutableElement element) {
    if (_visibilityTracker.isVisible(element)) {
      var suggestion = LocalFunctionSuggestion(element);
      collector.addSuggestion(suggestion);
    }
  }

  /// Add a suggestion for the parameter represented by the [element].
  void _suggestParameter(ParameterElement element) {
    if (mustBeConstant && !element.isConst) {
      return;
    }
    if (_visibilityTracker.isVisible(element) && !_isUnused(element.name)) {
      var suggestion = FormalParameterSuggestion(element);
      collector.addSuggestion(suggestion);
    }
  }

  /// Add a suggestion for the local variable represented by the [element].
  void _suggestVariable(LocalVariableElement element) {
    if (mustBeConstant && !element.isConst) {
      return;
    }
    if (_visibilityTracker.isVisible(element)) {
      var suggestion = LocalVariableSuggestion(element, _variableDistance++);
      collector.addSuggestion(suggestion);
    }
  }

  void _visitCatchClause(CatchClause node) {
    var exceptionElement = node.exceptionParameter?.declaredElement;
    if (exceptionElement != null) {
      _suggestVariable(exceptionElement);
    }

    var stackTraceElement = node.stackTraceParameter?.declaredElement;
    if (stackTraceElement != null) {
      _suggestVariable(stackTraceElement);
    }
  }

  AstNode? _visitCommentReference(CommentReference node) {
    var member = node.parent?.parent;
    switch (member) {
      case ConstructorDeclaration():
        _visitParameterList(member.parameters);
      case FunctionExpression():
        _visitParameterList(member.parameters);
      case MethodDeclaration():
        _visitParameterList(member.parameters);
    }
    return member;
  }

  void _visitDeclaredVariablePattern(DeclaredVariablePattern pattern) {
    var declaredElement = pattern.declaredElement;
    if (declaredElement != null) {
      _suggestVariable(declaredElement);
    }
  }

  void _visitForLoopParts(ForLoopParts node) {
    if (node is ForEachPartsWithDeclaration) {
      var declaredElement = node.loopVariable.declaredElement;
      if (declaredElement != null) {
        _suggestVariable(declaredElement);
      }
    } else if (node is ForPartsWithDeclarations) {
      var variables = node.variables;
      for (var variable in variables.variables) {
        var declaredElement = variable.declaredElement;
        if (declaredElement is LocalVariableElement) {
          _suggestVariable(declaredElement);
        }
      }
    }
  }

  void _visitIfElement(IfElement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitPattern(pattern);
      }
    }
  }

  void _visitIfStatement(IfStatement node) {
    var elseKeyword = node.elseKeyword;
    if (elseKeyword == null || offset < elseKeyword.offset) {
      var pattern = node.caseClause?.guardedPattern.pattern;
      if (pattern != null) {
        _visitPattern(pattern);
      }
    }
  }

  void _visitParameterList(FormalParameterList? parameterList) {
    if (parameterList != null) {
      for (var param in parameterList.parameters) {
        var declaredElement = param.declaredElement;
        if (declaredElement != null) {
          _suggestParameter(declaredElement);
        }
      }
    }
  }

  void _visitPattern(DartPattern pattern) {
    switch (pattern) {
      case CastPattern(:var pattern):
        _visitPattern(pattern);
      case DeclaredVariablePattern():
        _visitDeclaredVariablePattern(pattern);
      case ListPattern():
        for (var element in pattern.elements) {
          if (element is DartPattern) {
            _visitPattern(element);
          } else if (element is RestPatternElement) {
            var elementPattern = element.pattern;
            if (elementPattern != null) {
              _visitPattern(elementPattern);
            }
          }
        }
      case LogicalAndPattern():
        _visitPattern(pattern.leftOperand);
        _visitPattern(pattern.rightOperand);
      case LogicalOrPattern():
        _visitPattern(pattern.leftOperand);
        _visitPattern(pattern.rightOperand);
      case MapPattern():
        for (var element in pattern.elements) {
          if (element is MapPatternEntry) {
            _visitPattern(element.value);
          } else if (element is RestPatternElement) {
            var elementPattern = element.pattern;
            if (elementPattern != null) {
              _visitPattern(elementPattern);
            }
          }
        }
      case NullAssertPattern():
        _visitPattern(pattern.pattern);
      case NullCheckPattern():
        _visitPattern(pattern.pattern);
      case ObjectPattern():
        for (var field in pattern.fields) {
          _visitPattern(field.pattern);
        }
      case ParenthesizedPattern():
        _visitPattern(pattern.pattern);
      case RecordPattern():
        for (var field in pattern.fields) {
          _visitPattern(field.pattern);
        }
      case _:
      // Do nothing
    }
  }

  void _visitStatements(NodeList<Statement> statements, AstNode? child) {
    // Visit the statements in reverse order so that shadowing declarations are
    // found before the declarations they shadow.
    for (var i = statements.length - 1; i >= 0; i--) {
      var statement = statements[i];
      if (statement == child) {
        // Skip the child that was passed in because we will have already
        // visited it and don't want to suggest declared variables twice.
        continue;
      }
      // TODO(brianwilkerson) I think we need to compare to the end of the
      //  statement for variable declarations and the offset for functions.
      if (statement.offset < offset) {
        if (statement is VariableDeclarationStatement) {
          var variables = statement.variables;
          for (var variable in variables.variables) {
            if (variable.end < offset) {
              var declaredElement = variable.declaredElement;
              if (declaredElement is LocalVariableElement) {
                _suggestVariable(declaredElement);
              }
            }
          }
        } else if (statement is FunctionDeclarationStatement) {
          var declaration = statement.functionDeclaration;
          if (declaration.offset < offset) {
            var name = declaration.name.lexeme;
            if (name.isNotEmpty) {
              var declaredElement = declaration.declaredElement;
              if (declaredElement != null) {
                _suggestFunction(declaredElement);
              }
            }
          }
        } else if (statement is PatternVariableDeclarationStatement) {
          var declaration = statement.declaration;
          if (declaration.end < offset) {
            _visitPattern(declaration.pattern);
          }
        }
      }
    }
  }

  void _visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (offset >= node.arrow.end) {
      _visitPattern(node.guardedPattern.pattern);
    }
  }

  void _visitSwitchPatternCase(SwitchPatternCase node, AstNode? child) {
    if (offset >= node.colon.end) {
      _visitStatements(node.statements, child);
      _visitPattern(node.guardedPattern.pattern);
      var parent = node.parent;
      if (parent is SwitchStatement) {
        var members = parent.members;
        var index = members.indexOf(node) - 1;
        while (index >= 0) {
          var member = members[index];
          if (member is SwitchPatternCase && member.statements.isEmpty) {
            _visitPattern(member.guardedPattern.pattern);
          } else {
            break;
          }
          index--;
        }
      }
    }
  }

  void _visitVariableDeclarationList(
      VariableDeclarationList node, AstNode? child) {
    var variables = node.variables;
    if (child is VariableDeclaration) {
      var index = variables.indexOf(child);
      for (var i = index - 1; i >= 0; i--) {
        var element = variables[i].declaredElement;
        if (element is LocalVariableElement) {
          _suggestVariable(element);
        }
      }
    }
  }
}

/// This class tracks the set of names already added in the completion list in
/// order to prevent suggesting elements that have been shadowed by local
/// declarations.
class _VisibilityTracker {
  /// The set of known previously declared names in this contributor.
  final Set<String> declaredNames = {};

  /// Before completions are added by this contributor, we verify with this
  /// method if the element has already been added, this prevents suggesting
  /// [Element]s that are shadowed.
  bool isVisible(Element? element) {
    var name = element?.name;
    return name != null && declaredNames.add(name);
  }
}
