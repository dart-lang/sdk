// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';

typedef int SuggestionsFilter(DartType dartType, int relevance);

/**
 * An [AstVisitor] for determining whether top level suggestions or invocation
 * suggestions should be made based upon the type of node in which the
 * suggestions were requested.
 */
class OpType {
  /**
   * Indicates whether constructor suggestions should be included.
   */
  bool includeConstructorSuggestions = false;

  /**
   * If [includeConstructorSuggestions] is set to true, then this function may
   * be set to a non-default function to filter out potential suggestions (null)
   * based on their static [DartType], or change the relative relevance by
   * returning a higher or lower relevance.
   */
  SuggestionsFilter constructorSuggestionsFilter =
      (DartType _, int relevance) => relevance;

  /**
   * Indicates whether type names should be suggested.
   */
  bool includeTypeNameSuggestions = false;

  /**
   * If [includeTypeNameSuggestions] is set to true, then this function may
   * be set to a non-default function to filter out potential suggestions (null)
   * based on their static [DartType], or change the relative relevance by
   * returning a higher or lower relevance.
   */
  SuggestionsFilter typeNameSuggestionsFilter =
      (DartType _, int relevance) => relevance;

  /**
   * Indicates whether setters along with methods and functions that
   * have a [void] return type should be suggested.
   */
  bool includeVoidReturnSuggestions = false;

  /**
   * Indicates whether fields and getters along with methods and functions that
   * have a non-[void] return type should be suggested.
   */
  bool includeReturnValueSuggestions = false;

  /**
   * If [includeReturnValueSuggestions] is set to true, then this function may
   * be set to a non-default function to filter out potential suggestions (null)
   * based on their static [DartType], or change the relative relevance by
   * returning a higher or lower relevance.
   */
  SuggestionsFilter returnValueSuggestionsFilter =
      (DartType _, int relevance) => relevance;

  /**
   * Indicates whether named arguments should be suggested.
   */
  bool includeNamedArgumentSuggestions = false;

  /**
   * Indicates whether statement labels should be suggested.
   */
  bool includeStatementLabelSuggestions = false;

  /**
   * Indicates whether case labels should be suggested.
   */
  bool includeCaseLabelSuggestions = false;

  /**
   * Indicates whether variable names should be suggested.
   */
  bool includeVarNameSuggestions = false;

  /**
   * Indicates whether the completion location is in the body of a static method.
   */
  bool inStaticMethodBody = false;

  /**
   * Indicates whether the completion target is prefixed.
   */
  bool isPrefixed = false;

  /**
   * The suggested completion kind.
   */
  CompletionSuggestionKind suggestKind = CompletionSuggestionKind.INVOCATION;

  /**
   * Determine the suggestions that should be made based upon the given
   * [CompletionTarget] and [offset].
   */
  factory OpType.forCompletion(CompletionTarget target, int offset) {
    OpType optype = new OpType._();
    target.containingNode
        .accept(new _OpTypeAstVisitor(optype, target.entity, offset));
    var mthDecl =
        target.containingNode.getAncestor((p) => p is MethodDeclaration);
    optype.inStaticMethodBody =
        mthDecl is MethodDeclaration && mthDecl.isStatic;
    return optype;
  }

  OpType._();

  /**
   * Return `true` if free standing identifiers should be suggested
   */
  bool get includeIdentifiers {
    return !isPrefixed &&
        (includeReturnValueSuggestions ||
            includeTypeNameSuggestions ||
            includeVoidReturnSuggestions ||
            includeConstructorSuggestions);
  }

  /**
   * Indicate whether only type names should be suggested
   */
  bool get includeOnlyNamedArgumentSuggestions =>
      includeNamedArgumentSuggestions &&
      !includeTypeNameSuggestions &&
      !includeReturnValueSuggestions &&
      !includeVoidReturnSuggestions;

  /**
   * Indicate whether only type names should be suggested
   */
  bool get includeOnlyTypeNameSuggestions =>
      includeTypeNameSuggestions &&
      !includeNamedArgumentSuggestions &&
      !includeReturnValueSuggestions &&
      !includeVoidReturnSuggestions;

  /// Return the statement before [entity]
  /// where [entity] can be a statement or the `}` closing the given block.
  static Statement getPreviousStatement(Block node, Object entity) {
    if (entity == node.rightBracket) {
      return node.statements.isNotEmpty ? node.statements.last : null;
    }
    if (entity is Statement) {
      int index = node.statements.indexOf(entity);
      if (index > 0) {
        return node.statements[index - 1];
      }
      return null;
    }
    return null;
  }
}

class _OpTypeAstVisitor extends GeneralizingAstVisitor {
  /**
   * The entity (AstNode or Token) which will be replaced or displaced by the
   * added text.
   */
  final Object entity;

  /**
   * The offset within the source at which the completion is requested.
   */
  final int offset;

  /**
   * The [OpType] being initialized
   */
  final OpType optype;

  _OpTypeAstVisitor(this.optype, this.entity, this.offset);

  @override
  void visitAnnotation(Annotation node) {
    if (identical(entity, node.name)) {
      optype.includeTypeNameSuggestions = true;
      optype.includeReturnValueSuggestions = true;
    } else if (identical(entity, node.constructorName)) {
      optype.includeTypeNameSuggestions = true;
      optype.includeReturnValueSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    AstNode parent = node.parent;
    List<ParameterElement> parameters;
    if (parent is InstanceCreationExpression) {
      Element constructor;
      SimpleIdentifier name = parent.constructorName?.name;
      if (name != null) {
        constructor = name.bestElement;
      } else {
        var classElem = parent.constructorName?.type?.name?.bestElement;
        if (classElem is ClassElement) {
          constructor = classElem.unnamedConstructor;
        }
      }
      if (constructor is ConstructorElement) {
        parameters = constructor.parameters;
      } else if (constructor == null) {
        // If unresolved, then include named arguments
        optype.includeNamedArgumentSuggestions = true;
      }
    } else if (parent is InvocationExpression) {
      Expression function = parent.function;
      if (function is SimpleIdentifier) {
        var elem = function.bestElement;
        if (elem is FunctionTypedElement) {
          parameters = elem.parameters;
        } else if (elem == null) {
          // If unresolved, then include named arguments
          optype.includeNamedArgumentSuggestions = true;
        }
      }
    }
    // Based upon the insertion location and declared parameters
    // determine whether only named arguments should be suggested
    if (parameters != null) {
      int index;
      if (node.arguments.isEmpty) {
        index = 0;
      } else if (entity == node.rightParenthesis) {
        // Parser ignores trailing commas
        if (node.rightParenthesis.previous?.lexeme == ',') {
          index = node.arguments.length;
        } else {
          index = node.arguments.length - 1;
        }
      } else {
        index = node.arguments.indexOf(entity);
      }
      if (0 <= index && index < parameters.length) {
        ParameterElement param = parameters[index];
        if (param?.parameterKind == ParameterKind.NAMED) {
          optype.includeNamedArgumentSuggestions = true;
          return;
        }
      }
    }
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (identical(entity, node.type)) {
      optype.includeTypeNameSuggestions = true;
      optype.typeNameSuggestionsFilter = (DartType dartType, int relevance) {
        DartType staticType = node.expression.staticType;
        if (staticType != null &&
            (staticType.isDynamic ||
                (dartType.isSubtypeOf(staticType) && dartType != staticType))) {
          return relevance;
        } else {
          return null;
        }
      };
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (identical(entity, node.condition)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (identical(entity, node.rightHandSide)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (identical(entity, node.rightOperand)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitBlock(Block node) {
    Statement prevStmt = OpType.getPreviousStatement(node, entity);
    if (prevStmt is TryStatement) {
      if (prevStmt.catchClauses.isEmpty && prevStmt.finallyBlock == null) {
        return;
      }
    }
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    if (node.label == null || identical(entity, node.label)) {
      optype.includeStatementLabelSuggestions = true;
    }
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    if (node.cascadeSections.contains(entity)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    if (identical(entity, node.exceptionType)) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    if (node.members.contains(entity) || identical(entity, node.rightBracket)) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassMember(ClassMember node) {}

  @override
  void visitCommentReference(CommentReference node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
    optype.suggestKind = CompletionSuggestionKind.IDENTIFIER;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (entity is! CommentToken) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  visitConstructorName(ConstructorName node) {
    // some PrefixedIdentifier nodes are transformed into
    // ConstructorName nodes during the resolution process.
    if (identical(entity, node.name)) {
      TypeName type = node.type;
      if (type != null) {
        SimpleIdentifier prefix = type.name;
        if (prefix != null) {
          optype.includeConstructorSuggestions = true;
          optype.isPrefixed = true;
        }
      }
    }
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    if (node.label == null || identical(entity, node.label)) {
      optype.includeStatementLabelSuggestions = true;
      optype.includeCaseLabelSuggestions = true;
    }
  }

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    if (identical(entity, node.defaultValue)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    if (identical(entity, node.condition)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
  }

  @override
  void visitExpression(Expression node) {
    // This should never be called; we should always dispatch to the visitor
    // for a particular kind of expression.
    assert(false);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    // Given f[], the parser drops the [] from the expression statement
    // but the [] token is the CompletionTarget entity
    if (entity is Token) {
      Token token = entity;
      if (token.lexeme == '[]' && offset == token.offset + 1) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
      }
      if ((token.isSynthetic || token.lexeme == ';') &&
          node.expression is Identifier) {
        optype.includeVarNameSuggestions = true;
      }
    }
  }

  @override
  void visitExtendsClause(ExtendsClause node) {
    if (identical(entity, node.superclass)) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    if (entity == node.identifier) {
      optype.isPrefixed = true;
    } else {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    if (identical(entity, node.identifier)) {
      optype.includeTypeNameSuggestions = true;
    }
    if (identical(entity, node.loopVariable)) {
      optype.includeTypeNameSuggestions = true;
    }
    if (identical(entity, node.inKeyword) && offset <= node.inKeyword.offset) {
      if (node.identifier == null && node.loopVariable == null) {
        optype.includeTypeNameSuggestions = true;
      }
    }
    if (identical(entity, node.iterable)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    dynamic entity = this.entity;
    if (entity is Token && entity.previous != null) {
      TokenType type = entity.previous.type;
      if (type == TokenType.OPEN_PAREN || type == TokenType.COMMA) {
        optype.includeTypeNameSuggestions = true;
      }
    }
    // Handle default normal parameter just as a normal parameter.
    if (entity is DefaultFormalParameter) {
      entity = entity.parameter;
    }
    // "(^ this.field)"
    if (entity is FieldFormalParameter) {
      if (offset < entity.thisKeyword.offset) {
        optype.includeTypeNameSuggestions = true;
      }
    }
    // "(Type name)"
    if (entity is SimpleFormalParameter) {
      // "(Type^)" is parsed as a parameter with the _name_ "Type".
      if (entity.type == null) {
        optype.includeTypeNameSuggestions = true;
      }
      // If inside of "Type" in "(Type^ name)", then include types.
      if (entity.type != null &&
          entity.type.offset <= offset &&
          offset <= entity.type.end) {
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    var entity = this.entity;
    if (_isEntityPrevTokenSynthetic()) {
      // Actual: for (var v i^)
      // Parsed: for (var i; i^;)
    } else if (entity is Token &&
        entity.isSynthetic &&
        node.leftSeparator == entity) {
      // Actual: for (String ^)
      // Parsed: for (String; ;)
      //                    ^
      optype.includeVarNameSuggestions = true;
    } else {
      // for (^) {}
      // for (Str^ str = null;) {}
      // In theory it is possible to specify any expression in initializer,
      // but for any practical use we need only types.
      if (entity == node.initialization || entity == node.variables) {
        optype.includeTypeNameSuggestions = true;
      }
      // for (; ^) {}
      if (entity == node.condition) {
        optype.includeTypeNameSuggestions = true;
        optype.includeReturnValueSuggestions = true;
      }
      // for (; ; ^) {}
      if (node.updaters.contains(entity)) {
        optype.includeTypeNameSuggestions = true;
        optype.includeReturnValueSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (identical(entity, node.returnType) ||
        identical(entity, node.name) && node.returnType == null) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {}

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    if (identical(entity, node.returnType) ||
        identical(entity, node.name) && node.returnType == null) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_isEntityPrevTokenSynthetic()) {
      // Actual: if (var v i^)
      // Parsed: if (v) i^;
    } else if (identical(entity, node.condition)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.thenStatement) ||
        identical(entity, node.elseStatement)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(entity, node.constructorName)) {
      optype.includeConstructorSuggestions = true;
      optype.constructorSuggestionsFilter = (DartType dartType, int relevance) {
        DartType localTypeAssertion = null;
        if (node.parent is VariableDeclaration) {
          VariableDeclaration varDeclaration =
              node.parent as VariableDeclaration;
          localTypeAssertion = resolutionMap
              .elementDeclaredByVariableDeclaration(varDeclaration)
              ?.type;
        } else if (node.parent is AssignmentExpression) {
          AssignmentExpression assignmentExpression =
              node.parent as AssignmentExpression;
          localTypeAssertion = assignmentExpression.leftHandSide.staticType;
        }
        if (localTypeAssertion == null ||
            dartType == null ||
            localTypeAssertion.isDynamic) {
          return relevance;
        } else if (localTypeAssertion == dartType) {
          return relevance + DART_RELEVANCE_INCREMENT;
        } else if (dartType.isSubtypeOf(localTypeAssertion)) {
          return relevance;
        } else {
          return null;
        }
      };
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      // Only include type names in a ${ } expression
      optype.includeTypeNameSuggestions =
          node.leftBracket != null && node.leftBracket.length > 1;
    }
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (identical(entity, node.type)) {
      optype.includeTypeNameSuggestions = true;
      optype.typeNameSuggestionsFilter = (DartType dartType, int relevance) {
        DartType staticType = node.expression.staticType;
        if (staticType != null &&
            (staticType.isDynamic ||
                (dartType.isSubtypeOf(staticType) && dartType != staticType))) {
          return relevance;
        } else {
          return null;
        }
      };
    }
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    // No suggestions.
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    bool isThis = node.target is ThisExpression;
    if (identical(entity, node.operator) && offset > node.operator.offset) {
      // The cursor is between the two dots of a ".." token, so we need to
      // generate the completions we would generate after a "." token.
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = !isThis;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    } else if (identical(entity, node.methodName)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = !isThis;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.returnValueSuggestionsFilter = (DartType dartType, int relevance) {
        DartType type = resolutionMap.elementForNamedExpression(node)?.type;
        bool isEnum = type != null &&
            type.element is ClassElement &&
            (type.element as ClassElement).isEnum;
        if (isEnum) {
          if (type == dartType) {
            return relevance + DART_RELEVANCE_INCREMENT;
          } else {
            return null;
          }
        }
        if (type != null &&
            dartType != null &&
            !type.isDynamic &&
            dartType.isSubtypeOf(type)) {
          // is correct type
          return relevance + DART_RELEVANCE_INCREMENT;
        } else {
          return relevance;
        }
      };
      optype.includeTypeNameSuggestions = true;

      // Check for named parameters in constructor calls.
      AstNode grandparent = node.parent.parent;
      if (grandparent is ConstructorReferenceNode) {
        ConstructorElement element =
            (grandparent as ConstructorReferenceNode).staticElement;
        if (element != null) {
          List<ParameterElement> parameters = element.parameters;
          ParameterElement parameterElement = parameters.firstWhere((e) {
            if (e is DefaultFieldFormalParameterElementImpl) {
              return e.field?.name == node.name.label.name;
            }
            return e.parameterKind == ParameterKind.NAMED &&
                e.name == node.name.label.name;
          }, orElse: () => null);
          // Suggest tear-offs.
          if (parameterElement?.type is FunctionType) {
            optype.includeVoidReturnSuggestions = true;
          }
        }
      }
    }
  }

  @override
  void visitNode(AstNode node) {
    // no suggestion by default
  }

  @override
  void visitNormalFormalParameter(NormalFormalParameter node) {
    if (node.identifier != entity) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (identical(entity, node.identifier) ||
        // In addition to the standard case,
        // handle the exceptional case where the parser considers the would-be
        // identifier to be a keyword and inserts a synthetic identifier
        (node.identifier != null &&
            node.identifier.isSynthetic &&
            identical(entity, node.identifier.beginToken.previous))) {
      optype.isPrefixed = true;
      if (node.parent is TypeName && node.parent.parent is ConstructorName) {
        optype.includeConstructorSuggestions = true;
      } else {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions =
            node.parent is ExpressionStatement;
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (identical(entity, node.operand)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    bool isThis = node.target is ThisExpression;
    if (node.realTarget is SimpleIdentifier && node.realTarget.isSynthetic) {
      // If the access has no target (empty string)
      // then don't suggest anything
      return;
    }
    if (identical(entity, node.operator) && offset > node.operator.offset) {
      // The cursor is between the two dots of a ".." token, so we need to
      // generate the completions we would generate after a "." token.
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = !isThis;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    } else if (identical(entity, node.propertyName)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions =
          !isThis && (node.parent is! CascadeExpression);
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // This should never happen; the containingNode will always be some node
    // higher up in the parse tree, and the SimpleIdentifier will be the
    // entity.
    assert(false);
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    // no suggestions
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (node.statements.contains(entity)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (identical(entity, node.expression)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
    if (identical(entity, node.rightBracket)) {
      if (node.members.isNotEmpty) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
    if (entity is SwitchMember && entity != node.members.first) {
      SwitchMember member = entity as SwitchMember;
      if (offset <= member.offset) {
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (entity is Token) {
      Token token = entity;
      if (token.isSynthetic || token.lexeme == ';') {
        optype.includeVarNameSuggestions = true;
      }
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    NodeList<TypeAnnotation> arguments = node.arguments;
    for (TypeAnnotation type in arguments) {
      if (identical(entity, type)) {
        optype.includeTypeNameSuggestions = true;
        break;
      }
    }
  }

  @override
  void visitTypedLiteral(TypedLiteral node) {
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitTypeName(TypeName node) {
    // The entity won't be the first child entity (node.name), since
    // CompletionTarget would have chosen an edge higher in the parse tree.  So
    // it must be node.typeArguments, meaning that the cursor is between the
    // type name and the "<" that starts the type arguments.  In this case,
    // we have no completions to offer.
    assert(identical(entity, node.typeArguments));
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // Make suggestions for the RHS of a variable declaration
    if (identical(entity, node.initializer)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.keyword == null || node.keyword.lexeme != 'var') {
      if (node.type == null || identical(entity, node.type)) {
        optype.includeTypeNameSuggestions = true;
      } else if (node.type != null && entity is VariableDeclaration) {
        optype.includeVarNameSuggestions = true;
      }
    }
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {}

  @override
  void visitWhileStatement(WhileStatement node) {
    if (identical(entity, node.condition)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitWithClause(WithClause node) {
    optype.includeTypeNameSuggestions = true;
  }

  bool _isEntityPrevTokenSynthetic() {
    Object entity = this.entity;
    if (entity is AstNode && entity.beginToken.previous?.isSynthetic ?? false) {
      return true;
    }
    return false;
  }
}
