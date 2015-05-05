// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.invocation;

import 'dart:async';

import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_declaration_visitor.dart';
import 'package:analysis_server/src/services/completion/local_suggestion_builder.dart';
import 'package:analysis_server/src/services/completion/optype.dart';
import 'package:analysis_server/src/services/completion/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;
import '../../protocol_server.dart' as protocol;

/**
 * A contributor for calculating invocation / access suggestions
 * `completion.getSuggestions` request results.
 */
class PrefixedElementContributor extends DartCompletionContributor {
  SuggestionBuilder builder;

  @override
  bool computeFast(DartCompletionRequest request) {
    OpType optype = request.optype;
    if (optype.isPrefixed) {
      builder = request.target.containingNode
          .accept(new _InvocationAstVisitor(request));
      if (builder != null) {
        return builder.computeFast(request.target.containingNode);
      }
    }

    return true;
  }

  @override
  Future<bool> computeFull(DartCompletionRequest request) {
    if (builder != null) {
      return builder.computeFull(request.target.containingNode);
    }
    return new Future.value(false);
  }
}

class _ExpressionSuggestionBuilder implements SuggestionBuilder {
  final DartCompletionRequest request;

  _ExpressionSuggestionBuilder(this.request);

  @override
  bool computeFast(AstNode node) {
    return false;
  }

  @override
  Future<bool> computeFull(AstNode node) {
    if (node is MethodInvocation) {
      node = (node as MethodInvocation).realTarget;
    } else if (node is PropertyAccess) {
      node = (node as PropertyAccess).realTarget;
    }
    if (node is Identifier) {
      Element elem = node.bestElement;
      if (elem is ClassElement || elem is PrefixElement) {
        elem.accept(new _PrefixedIdentifierSuggestionBuilder(request));
        return new Future.value(true);
      }
    }
    if (node is Expression) {
      InterfaceTypeSuggestionBuilder.suggestionsFor(request, node.bestType);
      return new Future.value(true);
    }
    return new Future.value(false);
  }
}

/**
 * A suggestion builder for 'this.' constructor arguments.
 */
class _FieldFormalSuggestionBuilder implements SuggestionBuilder {
  final DartCompletionRequest request;

  _FieldFormalSuggestionBuilder(this.request);

  @override
  bool computeFast(AstNode node) {
    if (node is FieldFormalParameter) {
      ConstructorDeclaration constructorDecl =
          node.getAncestor((p) => p is ConstructorDeclaration);
      if (constructorDecl != null) {

        // Compute fields already referenced
        List<String> referencedFields = new List<String>();
        for (FormalParameter param in constructorDecl.parameters.parameters) {
          if (param is FieldFormalParameter) {
            SimpleIdentifier fieldId = param.identifier;
            if (fieldId != null && fieldId != request.target.entity) {
              String fieldName = fieldId.name;
              if (fieldName != null && fieldName.length > 0) {
                referencedFields.add(fieldName);
              }
            }
          }
        }

        // Add suggestions for fields that are not already referenced
        ClassDeclaration classDecl =
            constructorDecl.getAncestor((p) => p is ClassDeclaration);
        for (ClassMember member in classDecl.members) {
          if (member is FieldDeclaration) {
            for (VariableDeclaration varDecl in member.fields.variables) {
              SimpleIdentifier fieldId = varDecl.name;
              if (fieldId != null) {
                String fieldName = fieldId.name;
                if (fieldName != null && fieldName.length > 0) {
                  if (!referencedFields.contains(fieldName)) {
                    CompletionSuggestion suggestion =
                        createFieldSuggestion(member, varDecl);
                    if (suggestion != null) {
                      request.addSuggestion(suggestion);
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      // This should never be called with a case not handled above.
      assert(false);
    }
    return true;
  }

  @override
  Future<bool> computeFull(AstNode node) {
    // This should never be called; we should always be able to compute
    // suggestions and return true in computeFast method.
    assert(false);
    return null;
  }
}

/**
 * An [AstNode] vistor for determining which suggestion builder
 * should be used to build invocation/access suggestions.
 */
class _InvocationAstVisitor extends GeneralizingAstVisitor<SuggestionBuilder> {
  final DartCompletionRequest request;

  _InvocationAstVisitor(this.request);

  @override
  SuggestionBuilder visitConstructorName(ConstructorName node) {
    // some PrefixedIdentifier nodes are transformed into
    // ConstructorName nodes during the resolution process.
    return new _PrefixedIdentifierSuggestionBuilder(request);
  }

  @override
  SuggestionBuilder visitFieldFormalParameter(FieldFormalParameter node) {
    return new _FieldFormalSuggestionBuilder(request);
  }

  @override
  SuggestionBuilder visitMethodInvocation(MethodInvocation node) {
    return new _ExpressionSuggestionBuilder(request);
  }

  @override
  SuggestionBuilder visitNode(AstNode node) {
    return null;
  }

  @override
  SuggestionBuilder visitPrefixedIdentifier(PrefixedIdentifier node) {
    // some PrefixedIdentifier nodes are transformed into
    // ConstructorName nodes during the resolution process.
    return new _PrefixedIdentifierSuggestionBuilder(request);
  }

  @override
  SuggestionBuilder visitPropertyAccess(PropertyAccess node) {
    return new _ExpressionSuggestionBuilder(request);
  }
}

/**
 * An [AstVisitor] which looks for a declaration with the given name
 * and if found, tries to determine a type for that declaration.
 */
class _LocalBestTypeVisitor extends LocalDeclarationVisitor {

  /**
   * The name for the declaration to be found.
   */
  final String targetName;

  /**
   * The best type for the found declaration,
   * or `null` if no declaration found or failed to determine a type.
   */
  DartType typeFound;

  /**
   * Construct a new instance to search for a declaration
   */
  _LocalBestTypeVisitor(this.targetName, int offset) : super(offset);

  @override
  void declaredClass(ClassDeclaration declaration) {
    if (declaration.name.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredClassTypeAlias(ClassTypeAlias declaration) {
    if (declaration.name.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredField(FieldDeclaration fieldDecl, VariableDeclaration varDecl) {
    if (varDecl.name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }

  @override
  void declaredFunction(FunctionDeclaration declaration) {
    if (declaration.name.name == targetName) {
      TypeName typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredFunctionTypeAlias(FunctionTypeAlias declaration) {
    if (declaration.name.name == targetName) {
      TypeName typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredLabel(Label label, bool isCaseLabel) {
    if (label.label.name == targetName) {
      // no type
      finished();
    }
  }

  @override
  void declaredLocalVar(SimpleIdentifier name, TypeName type) {
    if (name.name == targetName) {
      typeFound = name.bestType;
      finished();
    }
  }

  @override
  void declaredMethod(MethodDeclaration declaration) {
    if (declaration.name.name == targetName) {
      TypeName typeName = declaration.returnType;
      if (typeName != null) {
        typeFound = typeName.type;
      }
      finished();
    }
  }

  @override
  void declaredParam(SimpleIdentifier name, TypeName type) {
    if (name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }

  @override
  void declaredTopLevelVar(
      VariableDeclarationList varList, VariableDeclaration varDecl) {
    if (varDecl.name.name == targetName) {
      // Type provided by the element in computeFull above
      finished();
    }
  }
}

/**
 * An [Element] visitor for determining the appropriate invocation/access
 * suggestions based upon the element for which the completion is requested.
 */
class _PrefixedIdentifierSuggestionBuilder
    extends GeneralizingElementVisitor<Future<bool>>
    implements SuggestionBuilder {
  final DartCompletionRequest request;

  _PrefixedIdentifierSuggestionBuilder(this.request);

  @override
  bool computeFast(AstNode node) {
    return false;
  }

  @override
  Future<bool> computeFull(AstNode node) {
    if (node is ConstructorName) {
      // some PrefixedIdentifier nodes are transformed into
      // ConstructorName nodes during the resolution process.
      return new NamedConstructorSuggestionBuilder(request).computeFull(node);
    }
    if (node is PrefixedIdentifier) {
      SimpleIdentifier prefix = node.prefix;
      if (prefix != null) {
        Element element = prefix.bestElement;
        DartType type = prefix.bestType;
        if (element is! ClassElement) {
          if (type == null || type.isDynamic) {
            //
            // Given `g. int y = 0;`, the parser interprets `g` as a prefixed
            // identifier with no type.
            // If the user is requesting completions for `g`,
            // then check for a function, getter, or similar with a type.
            //
            _LocalBestTypeVisitor visitor =
                new _LocalBestTypeVisitor(prefix.name, request.offset);
            if (visitor.visit(prefix)) {
              type = visitor.typeFound;
            }
          }
          if (type != null && !type.isDynamic) {
            InterfaceTypeSuggestionBuilder.suggestionsFor(request, type);
            return new Future.value(true);
          }
        }
        if (element != null) {
          return element.accept(this);
        }
      }
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitClassElement(ClassElement element) {
    if (element != null) {
      InterfaceType type = element.type;
      if (type != null) {
        StaticClassElementSuggestionBuilder.suggestionsFor(
            request, type.element);
      }
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitElement(Element element) {
    return new Future.value(false);
  }

  @override
  Future<bool> visitPrefixElement(PrefixElement element) {
    bool modified = false;
    // Find the import directive with the given prefix
    for (Directive directive in request.unit.directives) {
      if (directive is ImportDirective) {
        if (directive.prefix != null) {
          if (directive.prefix.name == element.name) {
            // Suggest elements from the imported library
            LibraryElement library = directive.uriElement;
            LibraryElementSuggestionBuilder.suggestionsFor(request,
                CompletionSuggestionKind.INVOCATION, library,
                request.target.containingNode.parent is TypeName);
            modified = true;
            if (directive.deferredKeyword != null) {
              String completion = 'loadLibrary';
              CompletionSuggestion suggestion = new CompletionSuggestion(
                  CompletionSuggestionKind.INVOCATION, DART_RELEVANCE_DEFAULT,
                  completion, completion.length, 0, false, false,
                  parameterNames: [],
                  parameterTypes: [],
                  requiredParameterCount: 0,
                  hasNamedParameters: false,
                  returnType: 'void');
              suggestion.element = new protocol.Element(
                  protocol.ElementKind.FUNCTION, completion,
                  protocol.Element.makeFlags(),
                  parameters: '()', returnType: 'void');
              request.addSuggestion(suggestion);
            }
          }
        }
      }
    }
    return new Future.value(modified);
  }

  @override
  Future<bool> visitPropertyAccessorElement(PropertyAccessorElement element) {
    if (element != null) {
      PropertyInducingElement elemVar = element.variable;
      if (elemVar != null) {
        InterfaceTypeSuggestionBuilder.suggestionsFor(request, elemVar.type);
      }
      return new Future.value(true);
    }
    return new Future.value(false);
  }

  @override
  Future<bool> visitVariableElement(VariableElement element) {
    InterfaceTypeSuggestionBuilder.suggestionsFor(request, element.type);
    return new Future.value(true);
  }
}
