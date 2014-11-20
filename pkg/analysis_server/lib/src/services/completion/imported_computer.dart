// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';
import 'dart:collection';

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
  _ImportedSuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    builder = request.node.accept(new _ImportedAstVisitor(request));
    if (builder != null) {
      return builder.computeFast();
    }
    return true;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.computeFull(request.node);
    }
    return new Future.value(false);
  }
}

/**
 * [_ImportedAstVisitor] determines whether an import suggestions are needed
 * and instantiates the builder to create those suggestions.
 */
class _ImportedAstVisitor extends
    GeneralizingAstVisitor<_ImportedSuggestionBuilder> {
  final DartCompletionRequest request;

  _ImportedAstVisitor(this.request);

  @override
  _ImportedSuggestionBuilder visitArgumentList(ArgumentList node) {
    return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
  }

  @override
  _ImportedSuggestionBuilder visitBlock(Block node) {
    return new _ImportedSuggestionBuilder(request);
  }

  @override
  _ImportedSuggestionBuilder visitCascadeExpression(CascadeExpression node) {
    // Make suggestions for the target, but not for the selector
    // InvocationComputer makes selector suggestions
    Expression target = node.target;
    if (target != null && request.offset <= target.end) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitClassDeclaration(ClassDeclaration node) {
    // Make suggestions in the body of the class declaration
    Token leftBracket = node.leftBracket;
    if (leftBracket != null && request.offset >= leftBracket.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitExpression(Expression node) {
    return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
  }

  @override
  _ImportedSuggestionBuilder
      visitExpressionStatement(ExpressionStatement node) {
    Expression expression = node.expression;
    // A pre-variable declaration (e.g. C ^) is parsed as an expression
    // statement. Do not make suggestions for the variable name.
    if (expression is SimpleIdentifier && request.offset <= expression.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder
      visitFormalParameterList(FormalParameterList node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset > leftParen.offset) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return new _ImportedSuggestionBuilder(request);
      }
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitForStatement(ForStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      return new _ImportedSuggestionBuilder(request);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitIfStatement(IfStatement node) {
    Token leftParen = node.leftParenthesis;
    if (leftParen != null && request.offset >= leftParen.end) {
      Token rightParen = node.rightParenthesis;
      if (rightParen == null || request.offset <= rightParen.offset) {
        return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
      }
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder
      visitInterpolationExpression(InterpolationExpression node) {
    Expression expression = node.expression;
    if (expression is SimpleIdentifier) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitMethodInvocation(MethodInvocation node) {
    Token period = node.period;
    if (period == null || request.offset <= period.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitNode(AstNode node) {
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Make suggestions for the prefix, but not for the selector
    // InvocationComputer makes selector suggestions
    Token period = node.period;
    if (period != null && request.offset <= period.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitPropertyAccess(PropertyAccess node) {
    // Make suggestions for the target, but not for the property name
    // InvocationComputer makes property name suggestions
    var operator = node.operator;
    if (operator != null && request.offset < operator.offset) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }

  @override
  _ImportedSuggestionBuilder visitStringLiteral(StringLiteral node) {
    return null;
  }

  @override
  _ImportedSuggestionBuilder visitTypeName(TypeName node) {
    return new _ImportedSuggestionBuilder(request, typesOnly: true);
  }

  @override
  _ImportedSuggestionBuilder
      visitVariableDeclaration(VariableDeclaration node) {
    Token equals = node.equals;
    // Make suggestions for the RHS of a variable declaration
    if (equals != null && request.offset >= equals.end) {
      return new _ImportedSuggestionBuilder(request, excludeVoidReturn: true);
    }
    return null;
  }
}

/**
 * [_ImportedSuggestionBuilder] traverses the imports and builds suggestions
 * based upon imported elements.
 */
class _ImportedSuggestionBuilder {
  final DartCompletionRequest request;
  final bool typesOnly;
  final bool excludeVoidReturn;
  final HashSet<String> completions = new HashSet();
  DartCompletionCache cache;
  String importKey;

  _ImportedSuggestionBuilder(this.request, {this.typesOnly: false,
      this.excludeVoidReturn: false}) {
    cache = request.cache;
  }

  /**
   * Compute a hash of the import directives.
   */
  String get computeImportKey {
    if (importKey == null) {
      StringBuffer sb = new StringBuffer();
      request.unit.directives.forEach((Directive directive) {
        if (directive is ImportDirective) {
          sb.write(directive.toSource());
        }
      });
      importKey = sb.toString();
    }
    return importKey;
  }

  void addCachedSuggestions() {
    DartCompletionCache cache = request.cache;
    request.suggestions
        ..addAll(cache.importedTypeSuggestions)
        ..addAll(cache.libraryPrefixSuggestions);
    if (!typesOnly) {
      request.suggestions.addAll(cache.otherImportedSuggestions);
      if (!excludeVoidReturn) {
        request.suggestions.addAll(cache.importedVoidReturnSuggestions);
      }
    }
  }

  void addLibraryPrefixSuggestion(ImportElement importElem) {
    CompletionSuggestion suggestion = null;
    String completion = importElem.prefix.displayName;
    if (completion != null && completion.length > 0) {
      suggestion = new CompletionSuggestion(
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
      cache.libraryPrefixSuggestions.add(suggestion);
      completions.add(suggestion.completion);
    }
  }

  void addSuggestion(Element element, CompletionRelevance relevance) {

    if (element is ExecutableElement) {
      if (element.isOperator) {
        return;
      }
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

    if (element is ExecutableElement) {
      DartType returnType = element.returnType;
      if (returnType != null && returnType.isVoid) {
        cache.importedVoidReturnSuggestions.add(suggestion);
      } else {
        cache.otherImportedSuggestions.add(suggestion);
      }
    } else if (element is ClassElement) {
      cache.importedTypeSuggestions.add(suggestion);
    } else {
      cache.otherImportedSuggestions.add(suggestion);
    }
    completions.add(suggestion.completion);
  }

  void addSuggestions(List<Element> elements) {
    elements.forEach((Element elem) {
      addSuggestion(elem, CompletionRelevance.DEFAULT);
    });
  }

  /**
   * If the needed information is cached, then add suggestions and return `true`
   * else return `false` indicating that additional work is necessary.
   */
  bool computeFast() {
    if (cache.importKey == computeImportKey) {
      addCachedSuggestions();
      return true;
    }
    return false;
  }

  /**
   * Compute suggested based upon imported elements.
   */
  computeFull(AstNode node) {
    CompilationUnit unit = node.getAncestor((p) => p is CompilationUnit);
    cache.importedTypeSuggestions = <CompletionSuggestion>[];
    cache.libraryPrefixSuggestions = <CompletionSuggestion>[];
    cache.otherImportedSuggestions = <CompletionSuggestion>[];
    cache.importedVoidReturnSuggestions = <CompletionSuggestion>[];

    // Exclude elements from local library
    // because they are provided by LocalComputer
    Set<LibraryElement> excludedLibs = new Set<LibraryElement>();
    excludedLibs.add(unit.element.enclosingElement);

    // Include explicitly imported elements
    Map<String, ClassElement> classMap = new Map<String, ClassElement>();
    unit.directives.forEach((Directive directive) {
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
              addSuggestion(elem, CompletionRelevance.DEFAULT);
            });
          } else {
            // Exclude elements from prefixed imports
            // because they are provided by InvocationComputer
            excludedLibs.add(importElem.importedLibrary);
            addLibraryPrefixSuggestion(importElem);
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
      addSuggestion(elem, CompletionRelevance.DEFAULT);
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
          addSuggestions(elem.accessors);
          addSuggestions(elem.methods);
          elem.allSupertypes.forEach((InterfaceType type) {
            if (visited.add(type.name)) {
              addSuggestions(type.accessors);
              addSuggestions(type.methods);
            }
          });
        }
      }
    }

    // Add non-imported elements as low relevance
    var future = request.searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          if (element.isPublic &&
              !excludedLibs.contains(element.library) &&
              !completions.contains(element.displayName)) {
            addSuggestion(element, CompletionRelevance.LOW);
          }
        }
      });
      cache.importKey = computeImportKey;
      addCachedSuggestions();
      return true;
    });
  }
}
