// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';

typedef SuggestionsFilter = int Function(DartType dartType, int relevance);

/// An [AstVisitor] for determining whether top level suggestions or invocation
/// suggestions should be made based upon the type of node in which the
/// suggestions were requested.
class OpType {
  /// The [TypeSystem] used during resolution of the current unit.
  TypeSystem _typeSystem;

  /// Indicates whether constructor suggestions should be included.
  bool includeConstructorSuggestions = false;

  /// Indicates whether type names should be suggested.
  bool includeTypeNameSuggestions = false;

  /// If [includeTypeNameSuggestions] is set to true, then this function may
  /// be set to a non-default function to filter out potential suggestions
  /// (null) based on their static [DartType], or change the relative relevance
  /// by returning a higher or lower relevance.
  SuggestionsFilter typeNameSuggestionsFilter =
      (DartType _, int relevance) => relevance;

  /// Indicates whether setters along with methods and functions that
  /// have a [void] return type should be suggested.
  bool includeVoidReturnSuggestions = false;

  /// Indicates whether fields and getters along with methods and functions that
  /// have a non-[void] return type should be suggested.
  bool includeReturnValueSuggestions = false;

  /// Indicates whether named arguments should be suggested.
  bool includeNamedArgumentSuggestions = false;

  /// Indicates whether statement labels should be suggested.
  bool includeStatementLabelSuggestions = false;

  /// Indicates whether case labels should be suggested.
  bool includeCaseLabelSuggestions = false;

  /// Indicates whether variable names should be suggested.
  bool includeVarNameSuggestions = false;

  /// Indicates whether the completion location is in a field declaration.
  bool inFieldDeclaration = false;

  /// Indicates whether the completion location is in a top-level variable
  /// declaration.
  bool inTopLevelVariableDeclaration = false;

  /// Indicates whether the completion location is in the body of a static
  /// method.
  bool inStaticMethodBody = false;

  /// Indicates whether the completion target is prefixed.
  bool isPrefixed = false;

  /// The suggested completion kind.
  CompletionSuggestionKind suggestKind = CompletionSuggestionKind.INVOCATION;

  /// An representation of the location at which completion was requested.
  String completionLocation;

  /// The type that is required by the context in which the completion was
  /// activated, or `null` if there is no such type, or it cannot be determined.
  DartType _requiredType;

  /// Determine the suggestions that should be made based upon the given
  /// [CompletionTarget] and [offset].
  factory OpType.forCompletion(CompletionTarget target, int offset) {
    var optype = OpType._();

    // Don't suggest anything right after double or integer literals.
    if (target.isDoubleOrIntLiteral()) {
      return optype;
    }

    optype._typeSystem = target.unit?.declaredElement?.library?.typeSystem;

    var targetNode = target.containingNode;
    targetNode.accept(_OpTypeAstVisitor(optype, target.entity, offset));

    var functionBody = targetNode.thisOrAncestorOfType<FunctionBody>();
    if (functionBody != null) {
      var parent = functionBody.parent;

      if (parent is MethodDeclaration) {
        optype.inStaticMethodBody = parent.isStatic;
      }
    }

    optype.inFieldDeclaration =
        targetNode.thisOrAncestorOfType<FieldDeclaration>() != null;
    optype.inTopLevelVariableDeclaration =
        targetNode.thisOrAncestorOfType<TopLevelVariableDeclaration>() != null;

    // If a value should be suggested, suggest also constructors.
    if (optype.includeReturnValueSuggestions) {
      // Careful: in angular plugin, `target.unit` may be null!
      var unitElement = target.unit?.declaredElement;
      if (unitElement != null) {
        optype.includeConstructorSuggestions = true;
      }
    }

    // Compute the type required by the context and set filters.
    optype._computeRequiredTypeAndFilters(target);

    return optype;
  }

  OpType._();

  /// Return `true` if free standing identifiers should be suggested
  bool get includeIdentifiers {
    return !isPrefixed &&
        (includeReturnValueSuggestions ||
            includeTypeNameSuggestions ||
            includeVoidReturnSuggestions ||
            includeConstructorSuggestions);
  }

  /// Indicate whether only type names should be suggested
  bool get includeOnlyNamedArgumentSuggestions =>
      includeNamedArgumentSuggestions &&
      !includeTypeNameSuggestions &&
      !includeReturnValueSuggestions &&
      !includeVoidReturnSuggestions;

  /// Try to determine the required context type, and configure filters.
  void _computeRequiredTypeAndFilters(CompletionTarget target) {
    var entity = target.entity;
    var node = target.containingNode;

    if (node is InstanceCreationExpression &&
        node.keyword != null &&
        node.constructorName == entity) {
      entity = node;
      node = node.parent;
    }

    if (node is AssignmentExpression &&
        node.operator.type == TokenType.EQ &&
        node.rightHandSide == entity) {
      _requiredType = node.leftHandSide?.staticType;
    } else if (node is BinaryExpression &&
        node.operator.type == TokenType.EQ_EQ &&
        node.rightOperand == entity) {
      _requiredType = node.leftOperand?.staticType;
    } else if (node is NamedExpression && node.expression == entity) {
      _requiredType = node.staticParameterElement?.type;
    } else if (node is SwitchCase && node.expression == entity) {
      var parent = node.parent;
      if (parent is SwitchStatement) {
        _requiredType = parent.expression?.staticType;
      }
    } else if (node is VariableDeclaration && node.initializer == entity) {
      _requiredType = node.declaredElement?.type;
    } else if (entity is Expression && entity.staticParameterElement != null) {
      _requiredType = entity.staticParameterElement.type;
    }

    if (_requiredType == null) {
      return;
    }
    if (_requiredType.isDynamic || _requiredType.isDartCoreObject) {
      _requiredType = null;
      return;
    }
  }

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool _isSubtypeOf(DartType leftType, DartType rightType) {
    if (_typeSystem == null) {
      return false;
    }

    return _typeSystem.isSubtypeOf(leftType, rightType);
  }

  /// Return the statement before [entity]
  /// where [entity] can be a statement or the `}` closing the given block.
  static Statement getPreviousStatement(Block node, Object entity) {
    if (entity == node.rightBracket) {
      return node.statements.isNotEmpty ? node.statements.last : null;
    }
    if (entity is Statement) {
      var index = node.statements.indexOf(entity);
      if (index > 0) {
        return node.statements[index - 1];
      }
      return null;
    }
    return null;
  }
}

class _OpTypeAstVisitor extends GeneralizingAstVisitor<void> {
  /// The entity (AstNode or Token) that will be replaced or displaced by the
  /// added text.
  final SyntacticEntity entity;

  /// The offset within the source at which the completion is requested.
  final int offset;

  /// The [OpType] being initialized
  final OpType optype;

  _OpTypeAstVisitor(this.optype, this.entity, this.offset);

  @override
  void visitAnnotation(Annotation node) {
    if (identical(entity, node.name)) {
      optype.completionLocation = 'Annotation_name';
      optype.includeTypeNameSuggestions = true;
      optype.includeReturnValueSuggestions = true;
    } else if (identical(entity, node.constructorName)) {
      // There is no location for the constructor name because only named
      // constructors are valid.
      // TODO(brianwilkerson) The following looks wrong. I think we want to set
      //  includeConstructorSuggestions = true, but not type names or return
      //  values. On the other hand, I can't construct a test case that reaches
      //  this point, so perhaps we should just remove this branch.
      optype.includeTypeNameSuggestions = true;
      optype.includeReturnValueSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    var parent = node.parent;
    List<ParameterElement> parameters;
    if (parent is InstanceCreationExpression) {
      Element constructor;
      var name = parent.constructorName?.name;
      if (name != null) {
        constructor = name.staticElement;
      } else {
        var classElem = parent.constructorName?.type?.name?.staticElement;
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
      var function = parent.function;
      if (function is SimpleIdentifier) {
        var elem = function.staticElement;
        if (elem is FunctionTypedElement) {
          parameters = elem.parameters;
        } else if (elem == null) {
          // If unresolved, then include named arguments
          optype.includeNamedArgumentSuggestions = true;
        }
      }
    } else if (parent is SuperConstructorInvocation) {
      parameters = parent.staticElement?.parameters;
    } else if (parent is RedirectingConstructorInvocation) {
      parameters = parent.staticElement?.parameters;
    } else if (parent is Annotation) {
      var constructor = parent.element;
      if (constructor is ConstructorElement) {
        parameters = constructor.parameters;
      } else if (constructor == null) {
        // If unresolved, then include named arguments
        optype.includeNamedArgumentSuggestions = true;
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
        var previous = node.findPrevious(node.rightParenthesis);
        if (previous?.lexeme == ',') {
          index = node.arguments.length;
        } else {
          index = node.arguments.length - 1;
        }
      } else {
        index = node.arguments.indexOf(entity as Expression);
      }
      if (0 <= index && index < parameters.length) {
        var param = parameters[index];
        if (param?.isNamed == true) {
          var context = _argumentListContext(node);
          optype.completionLocation = 'ArgumentList_${context}_named';
          optype.includeNamedArgumentSuggestions = true;
          return;
        }
      }
    }
    var context = _argumentListContext(node);
    optype.completionLocation = 'ArgumentList_${context}_unnamed';
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitAsExpression(AsExpression node) {
    if (identical(entity, node.type)) {
      optype.completionLocation = 'AsExpression_type';
      optype.includeTypeNameSuggestions = true;
      optype.typeNameSuggestionsFilter = (DartType dartType, int relevance) {
        var staticType = node.expression.staticType;
        if (staticType != null &&
            (staticType.isDynamic ||
                (optype._isSubtypeOf(dartType, staticType) &&
                    dartType != staticType))) {
          return relevance;
        } else {
          return null;
        }
      };
    }
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    if (identical(entity, node.condition)) {
      optype.completionLocation = 'AssertInitializer_condition';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.message)) {
      optype.completionLocation = 'AssertInitializer_message';
      // TODO(brianwilkerson) Consider including return value suggestions and
      //  type name suggestions here.
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (identical(entity, node.condition)) {
      optype.completionLocation = 'AssertStatement_condition';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.message)) {
      optype.completionLocation = 'AssertStatement_message';
      // TODO(brianwilkerson) Consider including return value suggestions and
      //  type name suggestions here.
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (identical(entity, node.rightHandSide)) {
      optype.completionLocation = 'AssignmentExpression_rightHandSide';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'AwaitExpression_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    if (identical(entity, node.rightOperand)) {
      optype.completionLocation =
          'BinaryExpression_${node.operator}_rightOperand';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitBlock(Block node) {
    optype.completionLocation = 'Block_statement';
    var prevStmt = OpType.getPreviousStatement(node, entity);
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
      optype.completionLocation = 'CascadeExpression_cascadeSection';
      optype.includeReturnValueSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitCatchClause(CatchClause node) {
    if (identical(entity, node.exceptionType)) {
      optype.completionLocation = 'CatchClause_exceptionType';
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    if (node.members.contains(entity) || identical(entity, node.rightBracket)) {
      optype.completionLocation = 'ClassDeclaration_member';
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitClassMember(ClassMember node) {}

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    if (identical(entity, node.superclass)) {
      optype.completionLocation = 'ClassTypeAlias_superclass';
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitCommentReference(CommentReference node) {
    optype.completionLocation = 'CommentReference_identifier';
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
    optype.includeVoidReturnSuggestions = true;
    optype.suggestKind = CompletionSuggestionKind.IDENTIFIER;
  }

  @override
  void visitCompilationUnit(CompilationUnit node) {
    if (entity is! CommentToken) {
      int declarationStart() {
        var declarations = node.declarations;
        if (declarations.isNotEmpty) {
          return declarations[0].offset;
        }
        var directives = node.directives;
        if (directives.isNotEmpty) {
          return directives.last.end;
        }
        return node.end;
      }

      if (entity != null) {
        if (entity.offset <= declarationStart()) {
          optype.completionLocation = 'CompilationUnit_declaration';
        } else {
          optype.completionLocation = 'CompilationUnit_declaration';
        }
      }
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    if (identical(entity, node.thenExpression)) {
      optype.completionLocation = 'ConditionalExpression_thenExpression';
    } else if (identical(entity, node.elseExpression)) {
      optype.completionLocation = 'ConditionalExpression_elseExpression';
    }
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (identical(entity, node.returnType)) {
      optype.completionLocation = 'ConstructorDeclaration_returnType';
      optype.includeTypeNameSuggestions = true;
    } else if (node.initializers.contains(entity)) {
      optype.completionLocation = 'ConstructorDeclaration_initializer';
    }
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'ConstructorFieldInitializer_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitConstructorName(ConstructorName node) {
    // some PrefixedIdentifier nodes are transformed into
    // ConstructorName nodes during the resolution process.
    if (identical(entity, node.name)) {
      var type = node.type;
      if (type != null) {
        var prefix = type.name;
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
      optype.completionLocation = 'DefaultFormalParameter_defaultValue';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitDoStatement(DoStatement node) {
    if (identical(entity, node.body)) {
      optype.completionLocation = 'DoStatement_body';
    } else if (identical(entity, node.condition)) {
      optype.completionLocation = 'DoStatement_condition';
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
      optype.completionLocation = 'ExpressionFunctionBody_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    optype.completionLocation = 'ExpressionStatement_expression';
    // Given f[], the parser drops the [] from the expression statement
    // but the [] token is the CompletionTarget entity
    if (entity is Token) {
      var token = entity as Token;
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
      optype.completionLocation = 'ExtendsClause_superclass';
      optype.includeTypeNameSuggestions = true;
      optype.typeNameSuggestionsFilter = _nonMixinClasses;
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    if (identical(entity, node.extendedType)) {
      optype.completionLocation = 'ExtensionDeclaration_extendedType';
      optype.includeTypeNameSuggestions = true;
    } else if (node.members.contains(entity) ||
        identical(entity, node.rightBracket)) {
      // Make suggestions in the body of the extension declaration
      optype.completionLocation = 'ExtensionDeclaration_member';
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (entity == node.fields) {
      optype.completionLocation = 'FieldDeclaration_fields';
    }
    if (offset <= node.semicolon.offset) {
      optype.includeVarNameSuggestions = true;
    }
    if (offset <= node.fields.offset) {
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
  void visitForEachParts(ForEachParts node) {
    if (identical(entity, node.inKeyword) && offset <= node.inKeyword.offset) {
      if (!(node is ForEachPartsWithIdentifier && node.identifier != null ||
          node is ForEachPartsWithDeclaration && node.loopVariable != null)) {
        optype.includeTypeNameSuggestions = true;
      }
    }
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    if (identical(entity, node.loopVariable)) {
      optype.completionLocation = 'ForEachPartsWithDeclaration_loopVariable';
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.iterable)) {
      optype.completionLocation = 'ForEachPartsWithDeclaration_iterable';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
    visitForEachParts(node);
  }

  @override
  void visitForEachPartsWithIdentifier(ForEachPartsWithIdentifier node) {
    if (identical(entity, node.identifier)) {
      optype.completionLocation = 'ForEachPartsWithIdentifier_identifier';
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.iterable)) {
      optype.completionLocation = 'ForEachPartsWithIdentifier_iterable';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
    visitForEachParts(node);
  }

  @override
  void visitForElement(ForElement node) {
    // for (^) {}
    // for (Str^ str = null;) {}
    // In theory it is possible to specify any expression in initializer,
    // but for any practical use we need only types.
    if (entity == node.forLoopParts) {
      optype.completionLocation = 'ForElement_forLoopParts';
      optype.includeTypeNameSuggestions = true;
    } else if (entity == node.body) {
      optype.completionLocation = 'ForElement_body';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    optype.completionLocation = 'FormalParameterList_parameter';
    var entity = this.entity;
    if (entity is Token) {
      var previous = node.findPrevious(entity);
      if (previous != null) {
        var type = previous.type;
        if (type == TokenType.OPEN_PAREN || type == TokenType.COMMA) {
          optype.includeTypeNameSuggestions = true;
        }
      }
    }

    // Find the containing parameter.
    var parameter = CompletionTarget.findFormalParameter(node, offset);
    if (parameter == null) return;

    // Handle default normal parameter just as a normal parameter.
    if (parameter is DefaultFormalParameter) {
      parameter = (parameter as DefaultFormalParameter).parameter;
    }

    // "(^ this.field)"
    if (parameter is FieldFormalParameter) {
      if (offset < parameter.thisKeyword.offset) {
        optype.includeTypeNameSuggestions = true;
      }
      return;
    }

    // "(Type name)"
    if (parameter is SimpleFormalParameter) {
      visitSimpleFormalParameter(parameter);
    }
  }

  @override
  void visitForParts(ForParts node) {
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
      if (entity == node.condition) {
        // for (; ^) {}
        optype.completionLocation = 'ForParts_condition';
        optype.includeTypeNameSuggestions = true;
        optype.includeReturnValueSuggestions = true;
      } else if (node.updaters.contains(entity)) {
        // for (; ; ^) {}
        optype.completionLocation = 'ForParts_updater';
        optype.includeTypeNameSuggestions = true;
        optype.includeReturnValueSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitForStatement(ForStatement node) {
    // for (^) {}
    // for (Str^ str = null;) {}
    // In theory it is possible to specify any expression in initializer,
    // but for any practical use we need only types.
    if (entity == node.forLoopParts) {
      optype.completionLocation = 'ForStatement_forLoopParts';
      optype.includeTypeNameSuggestions = true;
    } else if (entity == node.body) {
      optype.completionLocation = 'ForStatement_body';
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (identical(entity, node.returnType) ||
        identical(entity, node.name) && node.returnType == null) {
      optype.completionLocation = 'FunctionDeclaration_returnType';
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
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (entity == node.functionType) {
      optype.completionLocation = 'GenericTypeAlias_functionType';
    }
  }

  @override
  void visitHideCombinator(HideCombinator node) {
    if (node.hiddenNames.contains(entity)) {
      optype.completionLocation = 'HideCombinator_hiddenName';
    }
  }

  @override
  void visitIfElement(IfElement node) {
    if (identical(entity, node.condition)) {
      optype.completionLocation = 'IfElement_condition';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.thenElement)) {
      optype.completionLocation = 'IfElement_thenElement';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    } else if (identical(entity, node.elseElement)) {
      optype.completionLocation = 'IfElement_elseElement';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_isEntityPrevTokenSynthetic()) {
      // Actual: if (var v i^)
      // Parsed: if (v) i^;
    } else if (identical(entity, node.condition)) {
      optype.completionLocation = 'IfStatement_condition';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.thenStatement)) {
      optype.completionLocation = 'IfStatement_thenStatement';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    } else if (identical(entity, node.elseStatement)) {
      optype.completionLocation = 'IfStatement_elseStatement';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitImplementsClause(ImplementsClause node) {
    optype.completionLocation = 'ImplementsClause_interface';
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    optype.completionLocation = 'IndexExpression_index';
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (identical(entity, node.constructorName)) {
      optype.completionLocation = 'InstanceCreationExpression_constructorName';
      optype.includeConstructorSuggestions = true;
    }
  }

  @override
  void visitInterpolationExpression(InterpolationExpression node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'InterpolationExpression_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitIsExpression(IsExpression node) {
    if (identical(entity, node.type)) {
      optype.completionLocation = 'IsExpression_type';
      optype.includeTypeNameSuggestions = true;
      optype.typeNameSuggestionsFilter = (DartType dartType, int relevance) {
        var staticType = node.expression.staticType;
        if (staticType != null &&
            (staticType.isDynamic ||
                (optype._isSubtypeOf(dartType, staticType) &&
                    dartType != staticType))) {
          return relevance;
        } else {
          return null;
        }
      };
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    optype.completionLocation = 'LabeledStatement_statement';
  }

  @override
  void visitLibraryIdentifier(LibraryIdentifier node) {
    // No suggestions.
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.elements.contains(entity)) {
      optype.completionLocation = 'ListLiteral_element';
    }
    visitTypedLiteral(node);
  }

  @override
  void visitMapLiteralEntry(MapLiteralEntry node) {
    optype.completionLocation = 'MapLiteralEntry_value';
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (identical(entity, node.returnType) ||
        identical(entity, node.name) && node.returnType == null) {
      optype.completionLocation = 'MethodDeclaration_returnType';
    }
    // TODO(brianwilkerson) In visitFunctionDeclaration, this is conditional. It
    //  seems like it should be the same in both places.
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var isThis = node.target is ThisExpression;
    if (identical(entity, node.operator) && offset > node.operator.offset) {
      // The cursor is between the two dots of a ".." token, so we need to
      // generate the completions we would generate after a "." token.
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = !isThis;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    } else if (identical(entity, node.methodName)) {
      optype.includeReturnValueSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    } else if (identical(entity, node.argumentList)) {
      // Note that when the cursor is in a type argument list (f<^>()), the
      // entity is (surprisingly) the invocation's argumentList (and not it's
      // typeArgumentList as you'd expect).
      if (offset < node.argumentList.offset) {
        optype.completionLocation = 'TypeArgumentList_argument';
      } else {
        var argKind = 'unnamed';
        var method = node.methodName.staticElement;
        if (method is MethodElement &&
            method.parameters.isNotEmpty &&
            method.parameters[0].isNamed) {
          argKind = 'named';
        }
        optype.completionLocation = 'ArgumentList_method_$argKind';
      }
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    // Make suggestions in the body of the mixin declaration
    if (node.members.contains(entity) || identical(entity, node.rightBracket)) {
      optype.completionLocation = 'MixinDeclaration_member';
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (identical(entity, node.expression)) {
      var context = _argumentListContext(node.parent);
      optype.completionLocation = 'ArgumentList_${context}_named';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;

      // Check for named parameters in constructor calls.
      var grandparent = node.parent.parent;
      if (grandparent is ConstructorReferenceNode) {
        var element = grandparent.staticElement;
        if (element != null) {
          var parameters = element.parameters;
          var parameterElement = parameters.firstWhere((e) {
            if (e is DefaultFieldFormalParameterElementImpl) {
              return e.field?.name == node.name.label?.name;
            }
            return e.isNamed && e.name == node.name.label?.name;
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
  void visitOnClause(OnClause node) {
    optype.completionLocation = 'OnClause_superclassConstraint';
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'ParenthesizedExpression_expression';
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
            identical(entity, node.findPrevious(node.identifier.beginToken)))) {
      if (node.prefix.isSynthetic) {
        // If the access has no target (empty string)
        // then don't suggest anything
        return;
      }
      optype.isPrefixed = true;
      if (node.parent is TypeName && node.parent.parent is ConstructorName) {
        optype.includeConstructorSuggestions = true;
      } else if (node.parent is Annotation) {
        optype.includeConstructorSuggestions = true;
      } else {
        optype.completionLocation = 'PropertyAccess_propertyName';
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
      optype.completionLocation = 'PrefixExpression_${node.operator}_operand';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.realTarget is SimpleIdentifier && node.realTarget.isSynthetic) {
      // If the access has no target (empty string)
      // then don't suggest anything
      return;
    }
    var isThis = node.target is ThisExpression;
    if (identical(entity, node.operator) && offset > node.operator.offset) {
      // The cursor is between the two dots of a ".." token, so we need to
      // generate the completions we would generate after a "." token.
      optype.completionLocation = 'PropertyAccess_propertyName';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = !isThis;
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    } else if (identical(entity, node.propertyName)) {
      optype.completionLocation = 'PropertyAccess_propertyName';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions =
          !isThis && (node.parent is! CascadeExpression);
      optype.includeVoidReturnSuggestions = true;
      optype.isPrefixed = true;
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (identical(entity, node.expression) ||
        (identical(entity, node.semicolon) && node.expression == null)) {
      optype.completionLocation = 'ReturnStatement_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.elements.contains(entity)) {
      optype.completionLocation = 'SetOrMapLiteral_element';
    }
    visitTypedLiteral(node);
  }

  @override
  void visitShowCombinator(ShowCombinator node) {
    if (node.shownNames.contains(entity)) {
      optype.completionLocation = 'ShowCombinator_shownName';
    }
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var type = node.type;
    var name = node.identifier;

    // "(Type^)" is parsed as a parameter with the _name_ "Type".
    if (type == null &&
        name != null &&
        name.offset <= offset &&
        offset <= name.end) {
      optype.includeTypeNameSuggestions = true;
      return;
    }

    // If "(^ Type)", then include types.
    if (type == null && offset < name.offset) {
      optype.includeTypeNameSuggestions = true;
      return;
    }

    // If "(Type ^)", then include parameter names.
    if (type == null && name.end < offset && offset <= name.token.next.offset) {
      optype.includeVarNameSuggestions = true;
      return;
    }

    // If inside of "Type" in "(Type^ name)", then include types.
    if (type != null && type.offset <= offset && offset <= type.end) {
      optype.includeTypeNameSuggestions = true;
      return;
    }

    // If "(Type name^)", then include parameter names.
    if (type != null &&
        name != null &&
        name.offset <= offset &&
        offset <= name.end) {
      optype.includeVarNameSuggestions = true;
      return;
    }

    if (_isParameterOfGenericFunctionType(node) && type != null) {
      // If "Function(^ Type)", then include types.
      if (offset < type.offset) {
        optype.includeTypeNameSuggestions = true;
        return;
      }
      // If "Function(Type ^)", then include parameter names.
      if (name == null && type.end < offset) {
        optype.includeVarNameSuggestions = true;
        return;
      }
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
  void visitSpreadElement(SpreadElement node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'SpreadElement_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    // no suggestions
  }

  @override
  void visitSwitchCase(SwitchCase node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'SwitchCase_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (node.statements.contains(entity)) {
      optype.completionLocation = 'SwitchMember_statement';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
      optype.includeVoidReturnSuggestions = true;
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'SwitchStatement_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
    if (identical(entity, node.rightBracket)) {
      if (node.members.isNotEmpty) {
        optype.completionLocation = 'SwitchMember_statement';
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
    if (entity is SwitchMember && entity != node.members.first) {
      var member = entity as SwitchMember;
      if (offset <= member.offset) {
        optype.completionLocation = 'SwitchMember_statement';
        optype.includeReturnValueSuggestions = true;
        optype.includeTypeNameSuggestions = true;
        optype.includeVoidReturnSuggestions = true;
      }
    }
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    optype.completionLocation = 'ThrowExpression_expression';
    optype.includeReturnValueSuggestions = true;
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    if (entity is Token) {
      var token = entity as Token;
      if (token.isSynthetic || token.lexeme == ';') {
        optype.includeVarNameSuggestions = true;
      }
    }
    if (offset <= node.variables.offset) {
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitTypeArgumentList(TypeArgumentList node) {
    var arguments = node.arguments;
    for (var type in arguments) {
      if (identical(entity, type)) {
        optype.completionLocation = 'TypeArgumentList_argument';
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
    // CompletionTarget would have chosen an edge higher in the parse tree. So
    // it must be node.typeArguments, meaning that the cursor is between the
    // type name and the "<" that starts the type arguments. In this case,
    // we have no completions to offer.
    assert(identical(entity, node.typeArguments));
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    if (entity == node.bound) {
      optype.completionLocation = 'TypeParameter_bound';
    }
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    // Make suggestions for the RHS of a variable declaration
    if (identical(entity, node.initializer)) {
      optype.completionLocation = 'VariableDeclaration_initializer';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.keyword == null || node.keyword.lexeme != 'var') {
      if (node.type == null || identical(entity, node.type)) {
        optype.completionLocation = 'VariableDeclarationList_type';
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
      optype.completionLocation = 'WhileStatement_condition';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    } else if (identical(entity, node.body)) {
      optype.completionLocation = 'WhileStatement_body';
    }
  }

  @override
  void visitWithClause(WithClause node) {
    if (node.mixinTypes.contains(entity)) {
      optype.completionLocation = 'WithClause_mixinType';
    }
    optype.includeTypeNameSuggestions = true;
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    if (identical(entity, node.expression)) {
      optype.completionLocation = 'YieldStatement_expression';
      optype.includeReturnValueSuggestions = true;
      optype.includeTypeNameSuggestions = true;
    }
  }

  /// Return the context in which the [node] occurs. The [node] is expected to
  /// be the parent of the argument expression.
  String _argumentListContext(AstNode node) {
    if (node is ArgumentList) {
      var parent = node.parent;
      if (parent is Annotation) {
        return 'annotation';
      } else if (parent is ExtensionOverride) {
        return 'extensionOverride';
      } else if (parent is FunctionExpressionInvocation) {
        return 'function';
      } else if (parent is InstanceCreationExpression) {
        // TODO(brianwilkerson) Enable this case.
//        if (flutter.isWidgetType(parent.staticType)) {
//          return 'widgetConstructor';
//        }
        return 'constructor';
      } else if (parent is MethodInvocation) {
        return 'method';
      } else if (parent is RedirectingConstructorInvocation) {
        return 'constructorRedirect';
      } else if (parent is SuperConstructorInvocation) {
        return 'constructorRedirect';
      }
    } else if (node is AssignmentExpression ||
        node is BinaryExpression ||
        node is PrefixExpression ||
        node is PostfixExpression) {
      return 'operator';
    } else if (node is IndexExpression) {
      return 'index';
    }
    throw ArgumentError(
        'Unknown parent of ${node.runtimeType}: ${node.parent.runtimeType}');
  }

  bool _isEntityPrevTokenSynthetic() {
    var entity = this.entity;
    if (entity is AstNode) {
      var previous = entity.findPrevious(entity.beginToken);
      if (previous?.isSynthetic ?? false) {
        return true;
      }
    }
    return false;
  }

  /// A filter used to disable everything except classes (such as functions and
  /// mixins).
  int _nonMixinClasses(DartType type, int relevance) {
    if (type is InterfaceType) {
      if (type.element.isMixin) {
        return null;
      }
      return relevance;
    }
    return null;
  }

  static bool _isParameterOfGenericFunctionType(FormalParameter node) {
    var parameterList = node.parent;
    if (parameterList is DefaultFormalParameter) {
      parameterList = parameterList.parent;
    }
    return parameterList is FormalParameterList &&
        parameterList.parent is GenericFunctionType;
  }
}
