// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element,
    ElementKind;
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedComputer extends DartCompletionComputer {

  @override
  bool computeFast(DartCompletionRequest request) {
    // TODO: implement computeFast
    // - compute results based upon current search, then replace those results
    // during the full compute phase
    // - filter results based upon completion offset
    return false;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    return request.node.accept(new _ImportedVisitor(request));
  }
}

/**
 * A visitor for determining which imported classes and top level variables
 * should be suggested and building those suggestions.
 */
class _ImportedVisitor extends GeneralizingAstVisitor<Future<bool>> {
  final DartCompletionRequest request;

  _ImportedVisitor(this.request);

  @override
  Future<bool> visitArgumentList(ArgumentList node) {
    return _addImportedElementSuggestions(node, excludeVoidReturn: true);
  }

  @override
  Future<bool> visitBlock(Block node) {
    return _addImportedElementSuggestions(node);
  }

  @override
  Future<bool> visitCascadeExpression(CascadeExpression node) {
    // Make suggestions for the target, but not for the selector
    // InvocationComputer makes selector suggestions
    Expression target = node.target;
    if (target != null && request.offset <= target.end) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    Token leftBracket = node.leftBracket;
    if (leftBracket != null && request.offset >= leftBracket.end) {
      return _addImportedElementSuggestions(node);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitExpression(Expression node) {
    return _addImportedElementSuggestions(node, excludeVoidReturn: true);
  }

  @override
  Future<bool> visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    // A pre-variable declaration (e.g. C ^) is parsed as an expression
    // statement. Do not make suggestions for the variable name.
    if (expression is SimpleIdentifier && request.offset <= expression.end) {
      return _addImportedElementSuggestions(node);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitFormalParameterList(FormalParameterList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset > leftParen.offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return _addImportedElementSuggestions(node);
      }
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitForStatement(ForStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      return _addImportedElementSuggestions(node);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitIfStatement(IfStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return _addImportedElementSuggestions(node, excludeVoidReturn: true);
      }
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitInterpolationExpression(InterpolationExpression node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period == null || request.offset <= period.offset) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitNode(AstNode node) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Make suggestions for the prefix, but not for the selector
    // InvocationComputer makes selector suggestions
    Token period = node.period;
    if (period != null && request.offset <= period.offset) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitPropertyAccess(PropertyAccess node) {
    // Make suggestions for the target, but not for the property name
    // InvocationComputer makes property name suggestions
    var operator = node.operator;
    if (operator != null && request.offset < operator.offset) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }

  @override
  Future<bool> visitStringLiteral(StringLiteral node) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitTypeName(TypeName node) {
    return _addImportedElementSuggestions(node, typesOnly: true);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    Token equals = node.equals;
    // Make suggestions for the RHS of a variable declaration
    if (equals != null && request.offset >= equals.end) {
      return _addImportedElementSuggestions(node, excludeVoidReturn: true);
    }
    return new Future.value(false);
  }

  void _addElementSuggestion(Element element, bool typesOnly,
      bool excludeVoidReturn, CompletionRelevance relevance) {

    if (element is ExecutableElement) {
      if (element.isOperator) {
        return;
      }
      if (excludeVoidReturn) {
        DartType returnType = element.returnType;
        if (returnType != null && returnType.isVoid) {
          return;
        }
      }
    }
    if (typesOnly && element is! ClassElement) {
      return;
    }

    String completion = element.displayName;
    CompletionSuggestion suggestion = new CompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        element.isDeprecated ? CompletionRelevance.LOW : relevance,
        completion,
        completion.length,
        0,
        element.isDeprecated,
        false);

    suggestion.element = newElement_fromEngine(element);

    DartType type;
    if (element is FunctionElement) {
      type = element.returnType;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      type = element.returnType;
    } else if (element is TopLevelVariableElement) {
      type = element.type;
    }
    if (type != null) {
      String name = type.displayName;
      if (name != null && name.length > 0 && name != 'dynamic') {
        suggestion.returnType = name;
      }
    }

    request.suggestions.add(suggestion);
  }

  void _addElementSuggestions(List<Element> elements, bool typesOnly,
      bool excludeVoidReturn) {
    elements.forEach((Element elem) {
      _addElementSuggestion(
          elem,
          typesOnly,
          excludeVoidReturn,
          CompletionRelevance.DEFAULT);
    });
  }

  Future<bool> _addImportedElementSuggestions(AstNode node, {bool typesOnly:
      false, bool excludeVoidReturn: false}) {

    // Exclude elements from local library
    // because they are provided by LocalComputer
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(request.unit.element.enclosingElement);

    // Include explicitly imported elements
    Map<String, ClassElement> classMap = new Map<String, ClassElement>();
    request.unit.directives.forEach((Directive directive) {
      if (directive is ImportDirective) {
        ImportElement importElem = directive.element;
        if (importElem != null && importElem.importedLibrary != null) {
          if (directive.prefix == null) {
            Namespace importNamespace =
                new NamespaceBuilder().createImportNamespaceForDirective(importElem);
            // Include top level elements
            importNamespace.definedNames.forEach((String name, Element elem) {
              if (elem is ClassElement) {
                classMap[name] = elem;
              }
              _addElementSuggestion(
                  elem,
                  typesOnly,
                  excludeVoidReturn,
                  CompletionRelevance.DEFAULT);
            });
          } else {
            // Exclude elements from prefixed imports
            // because they are provided by InvocationComputer
            excludedLibs.add(importElem.importedLibrary);
            _addLibraryPrefixSuggestion(importElem);
          }
        }
      }
    });

    // Include implicitly imported dart:core elements
    Source coreUri = request.context.sourceFactory.forUri('dart:core');
    LibraryElement coreLib = request.context.getLibraryElement(coreUri);
    Namespace coreNamespace =
        new NamespaceBuilder().createPublicNamespaceForLibrary(coreLib);
    coreNamespace.definedNames.forEach((String name, Element elem) {
      if (elem is ClassElement) {
        classMap[name] = elem;
      }
      _addElementSuggestion(
          elem,
          typesOnly,
          excludeVoidReturn,
          CompletionRelevance.DEFAULT);
    });

    // Build a list of inherited types that are imported
    // and include any inherited imported members
    var classDecl = node.getAncestor((p) => p is ClassDeclaration);
    if (classDecl is ClassDeclaration) {
      List<String> inheritedTypes = new List<String>();
      visitInheritedTypes(classDecl, (ClassDeclaration classDecl) {
        // ignored
      }, (String typeName) {
        inheritedTypes.add(typeName);
      });
      Set<String> visited = new Set<String>();
      while (inheritedTypes.length > 0) {
        String name = inheritedTypes.removeLast();
        ClassElement elem = classMap[name];
        if (visited.add(name) && elem != null) {
          _addElementSuggestions(elem.accessors, typesOnly, excludeVoidReturn);
          _addElementSuggestions(elem.methods, typesOnly, excludeVoidReturn);
          elem.allSupertypes.forEach((InterfaceType type) {
            if (visited.add(type.name)) {
              _addElementSuggestions(
                  type.accessors,
                  typesOnly,
                  excludeVoidReturn);
              _addElementSuggestions(
                  type.methods,
                  typesOnly,
                  excludeVoidReturn);
            }
          });
        }
      }
    }

    // Add non-imported elements as low relevance
    var future = request.searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      Set<String> completionSet = new Set<String>();
      request.suggestions.forEach((CompletionSuggestion suggestion) {
        completionSet.add(suggestion.completion);
      });
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic &&
              !excludedLibs.contains(element.library) &&
              !completionSet.contains(element.displayName)) {
            if (!typesOnly || element is ClassElement) {
              _addElementSuggestion(
                  element,
                  typesOnly,
                  excludeVoidReturn,
                  CompletionRelevance.LOW);
            }
          }
        }
      });
      return true;
    });
  }

  void _addLibraryPrefixSuggestion(ImportElement importElem) {
    String completion = importElem.prefix.displayName;
    if (completion != null && completion.length > 0) {
      CompletionSuggestion suggestion = new CompletionSuggestion(
          CompletionSuggestionKind.INVOCATION,
          CompletionRelevance.DEFAULT,
          completion,
          completion.length,
          0,
          importElem.isDeprecated,
          false);
      LibraryElement lib = importElem.importedLibrary;
      if (lib != null) {
        suggestion.element = newElement_fromEngine(lib);
      }
      request.suggestions.add(suggestion);
    }
  }
}
