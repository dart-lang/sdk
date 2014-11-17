// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.local;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart' as protocol show Element,
    ElementKind;
import 'package:analysis_server/src/protocol.dart' hide Element, ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';

/**
 * A computer for calculating `completion.getSuggestions` request results
 * for the local library in which the completion is requested.
 */
class LocalComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {

    // Collect suggestions from the specific child [AstNode] that contains
    // the completion offset and all of its parents recursively.
    request.node.accept(new _LocalVisitor(request, request.offset));

    // If the unit is not a part and does not reference any parts
    // then work is complete
    return !request.unit.directives.any(
        (Directive directive) =>
            directive is PartOfDirective || directive is PartDirective);
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    // TODO: implement computeFull
    // include results from part files that are included in the library
    return new Future.value(false);
  }
}

/**
 * A visitor for collecting suggestions from the most specific child [AstNode]
 * that contains the completion offset to the [CompilationUnit].
 */
class _LocalVisitor extends LocalDeclarationVisitor {
  static const DYNAMIC = 'dynamic';

  static final TypeName NO_RETURN_TYPE = new TypeName(
      new SimpleIdentifier(new StringToken(TokenType.IDENTIFIER, '', 0)),
      null);

  final DartCompletionRequest request;
  bool typesOnly = false;
  bool excludeVoidReturn;

  _LocalVisitor(this.request, int offset) : super(offset) {
    excludeVoidReturn = _computeExcludeVoidReturn(request.node);
  }

  @override
  void declaredClass(ClassDeclaration declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion =
        _addSuggestion(declaration.name, null, null, isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.CLASS,
          declaration.name,
          null,
          _LocalVisitor.NO_RETURN_TYPE,
          declaration.isAbstract,
          isDeprecated);
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion =
        _addSuggestion(declaration.name, null, null, isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.CLASS_TYPE_ALIAS,
          declaration.name,
          null,
          NO_RETURN_TYPE,
          true,
          isDeprecated);
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (typesOnly) {
      return;
    }
    bool isDeprecated = _isDeprecated(fieldDecl) || _isDeprecated(varDecl);
    CompletionSuggestion suggestion = _addSuggestion(
        varDecl.name,
        fieldDecl.fields.type,
        fieldDecl.parent,
        isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.GETTER,
          varDecl.name,
          '()',
          fieldDecl.fields.type,
          false,
          isDeprecated);
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (typesOnly) {
      return;
    }
    if (excludeVoidReturn && _isVoid(declaration.returnType)) {
      return;
    }
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion =
        _addSuggestion(declaration.name, declaration.returnType, null, isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.FUNCTION,
          declaration.name,
          declaration.functionExpression.parameters.toSource(),
          declaration.returnType,
          false,
          isDeprecated);
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion =
        _addSuggestion(declaration.name, declaration.returnType, null, isDeprecated);
    if (suggestion != null) {
      // TODO (danrubel) determine parameters and return type
      suggestion.element = _createElement(
          protocol.ElementKind.FUNCTION_TYPE_ALIAS,
          declaration.name,
          null,
          NO_RETURN_TYPE,
          true,
          isDeprecated);
    }
  }

  @override
  void declaredLabel(Label label) {
    // ignored
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion = _addSuggestion(name, type, null, false);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.LOCAL_VARIABLE,
          name,
          null,
          type,
          false,
          false);
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (typesOnly) {
      return;
    }
    protocol.ElementKind kind;
    String parameters;
    if (declaration.isGetter) {
      kind = protocol.ElementKind.GETTER;
      parameters = '()';
    } else if (declaration.isSetter) {
      if (excludeVoidReturn) {
        return;
      }
      kind = protocol.ElementKind.SETTER;
      parameters = '(${declaration.returnType.toSource()} value)';
    } else {
      if (excludeVoidReturn && _isVoid(declaration.returnType)) {
        return;
      }
      kind = protocol.ElementKind.METHOD;
      parameters = declaration.parameters.toSource();
    }
    bool isDeprecated = _isDeprecated(declaration);
    CompletionSuggestion suggestion = _addSuggestion(
        declaration.name,
        declaration.returnType,
        declaration.parent,
        isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          kind,
          declaration.name,
          parameters,
          declaration.returnType,
          declaration.isAbstract,
          isDeprecated);
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    if (typesOnly) {
      return;
    }
    CompletionSuggestion suggestion = _addSuggestion(name, type, null, false);
    if (suggestion != null) {
      suggestion.element =
          _createElement(protocol.ElementKind.PARAMETER, name, null, type, false, false);
    }
  }

  @override
  void declaredTopLevelVar(VariableDeclarationList varList,
      VariableDeclaration varDecl) {
    if (typesOnly) {
      return;
    }
    bool isDeprecated = _isDeprecated(varList) || _isDeprecated(varDecl);
    CompletionSuggestion suggestion =
        _addSuggestion(varDecl.name, varList.type, null, isDeprecated);
    if (suggestion != null) {
      suggestion.element = _createElement(
          protocol.ElementKind.TOP_LEVEL_VARIABLE,
          varDecl.name,
          null,
          varList.type,
          false,
          isDeprecated);
    }
  }

  @override
  bool visitCascadeExpression(CascadeExpression node) {
    Expression target = node.target;
    // This computer handles the expression
    // while InvocationComputer handles the cascade selector
    if (target != null && offset <= target.end) {
      return visitNode(node);
    } else {
      return finished;
    }
  }

  @override
  visitCombinator(Combinator node) {
    // Handled by CombinatorComputer
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    // InvocationComputer adds suggestions for method selector
    Token period = node.period;
    if (period != null && period.offset < request.offset) {
      ArgumentList argumentList = node.argumentList;
      if (argumentList == null || request.offset <= argumentList.offset) {
        return;
      }
    }
    visitNode(node);
  }

  @override
  bool visitNamespaceDirective(NamespaceDirective node) {
    // No suggestions
    return finished;
  }

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    // InvocationComputer adds suggestions for prefixed elements
    // but this computer adds suggestions for the prefix itself
    SimpleIdentifier prefix = node.prefix;
    if (prefix == null || request.offset <= prefix.end) {
      visitNode(node);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    // InvocationComputer adds suggestions for property access selector
  }

  @override
  bool visitStringLiteral(StringLiteral node) {
    // ignore
    return finished;
  }

  @override
  visitTypeName(TypeName node) {
    // If suggesting completions within a TypeName node
    // then limit suggestions to only types
    typesOnly = true;
    return visitNode(node);
  }

  @override
  bool visitVariableDeclaration(VariableDeclaration node) {
    // Do not add suggestions if editing the name in a var declaration
    SimpleIdentifier name = node.name;
    if (name == null || name.offset < offset || offset > name.end) {
      return visitNode(node);
    } else {
      return finished;
    }
  }

  CompletionSuggestion _addSuggestion(SimpleIdentifier id, TypeName typeName,
      ClassDeclaration classDecl, bool isDeprecated) {
    if (id != null) {
      String completion = id.name;
      if (completion != null && completion.length > 0 && completion != '_') {
        CompletionSuggestion suggestion = new CompletionSuggestion(
            CompletionSuggestionKind.INVOCATION,
            isDeprecated ? CompletionRelevance.LOW : CompletionRelevance.DEFAULT,
            completion,
            completion.length,
            0,
            false,
            false);
        if (classDecl != null) {
          SimpleIdentifier identifier = classDecl.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.declaringType = name;
            }
          }
        }
        if (typeName != null) {
          Identifier identifier = typeName.name;
          if (identifier != null) {
            String name = identifier.name;
            if (name != null && name.length > 0) {
              suggestion.returnType = name;
            }
          }
        }
        request.suggestions.add(suggestion);
        return suggestion;
      }
    }
    return null;
  }

  bool _computeExcludeVoidReturn(AstNode node) {
    if (node is Block) {
      return false;
    } else if (node is SimpleIdentifier) {
      return node.parent is ExpressionStatement ? false : true;
    } else {
      return true;
    }
  }


  /**
   * Create a new protocol Element for inclusion in a completion suggestion.
   */
  protocol.Element _createElement(protocol.ElementKind kind,
      SimpleIdentifier id, String parameters, TypeName returnType, bool isAbstract,
      bool isDeprecated) {
    String name = id.name;
    int flags = protocol.Element.makeFlags(
        isAbstract: isAbstract,
        isDeprecated: isDeprecated,
        isPrivate: Identifier.isPrivateName(name));
    return new protocol.Element(
        kind,
        name,
        flags,
        parameters: parameters,
        returnType: _nameForType(returnType));
  }

  /**
   * Return `true` if the @deprecated annotation is present
   */
  bool _isDeprecated(AnnotatedNode node) {
    if (node != null) {
      NodeList<Annotation> metadata = node.metadata;
      if (metadata != null) {
        return metadata.any((Annotation a) {
          return a.name is SimpleIdentifier && a.name.name == 'deprecated';
        });
      }
    }
    return false;
  }

  bool _isVoid(TypeName returnType) {
    if (returnType != null) {
      Identifier id = returnType.name;
      if (id != null && id.name == 'void') {
        return true;
      }
    }
    return false;
  }

  /**
   * Return the name for the given type.
   */
  String _nameForType(TypeName type) {
    if (type == NO_RETURN_TYPE) {
      return null;
    }
    if (type == null) {
      return DYNAMIC;
    }
    Identifier id = type.name;
    if (id == null) {
      return DYNAMIC;
    }
    String name = id.name;
    if (name == null || name.length <= 0) {
      return DYNAMIC;
    }
    TypeArgumentList typeArgs = type.typeArguments;
    if (typeArgs != null) {
      //TODO (danrubel) include type arguments
    }
    return name;
  }
}
