// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.contributor.dart.library_member;

import 'dart:async';

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_target.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

import '../../../protocol_server.dart'
    show CompletionSuggestion, CompletionSuggestionKind;

/**
 * A contributor for calculating prefixed import library member suggestions
 * `completion.getSuggestions` request results.
 */
class LibraryMemberContributor extends DartCompletionContributor {
  @override
  Future<List<CompletionSuggestion>> computeSuggestions(
      DartCompletionRequest request) async {
    // Determine if the target looks like a prefixed identifier,
    // a method invocation, or a property access
    SimpleIdentifier targetId = _getTargetId(request.target);
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Resolve the expression and the containing library
    await request.resolveExpression(targetId);
    LibraryElement containingLibrary = await request.libraryElement;
    // Gracefully degrade if the library could not be determined
    // e.g. detached part file or source change
    if (containingLibrary == null) {
      return EMPTY_LIST;
    }

    // Recompute the target since resolution may have changed it
    targetId = _getTargetId(request.target);
    if (targetId == null) {
      return EMPTY_LIST;
    }

    // Build the suggestions
    Element elem = targetId.bestElement;
    if (elem is PrefixElement) {
      List<CompletionSuggestion> suggestions = <CompletionSuggestion>[];

      // Find the import directive with the given prefix
      for (Directive directive in request.target.unit.directives) {
        if (directive is ImportDirective) {
          if (directive.prefix != null) {
            if (directive.prefix.name == elem.name) {
              LibraryElement library = directive.uriElement;
              if (library != null) {
                // Suggest elements from the imported library
                AstNode parent = request.target.containingNode.parent;
                bool isConstructor = parent.parent is ConstructorName;
                bool typesOnly = parent is TypeName;
                bool instCreation = typesOnly && isConstructor;
                library.visitChildren(new _SuggestionBuilder(
                    suggestions, typesOnly, instCreation));

                // If the import is 'deferred' then suggest 'loadLibrary'
                if (directive.deferredKeyword != null) {
                  FunctionElement loadLibFunct = library.loadLibraryFunction;
                  suggestions.add(createSuggestion(loadLibFunct));
                }
              }
            }
          }
        }
      }
      return suggestions;
    }
    return EMPTY_LIST;
  }

  /**
   * Return the identifier to the left of the 'dot' or `null` if none.
   */
  SimpleIdentifier _getTargetId(CompletionTarget target) {
    AstNode node = target.containingNode;
    if (node is MethodInvocation) {
      if (identical(node.methodName, target.entity)) {
        Expression target = node.realTarget;
        if (target is SimpleIdentifier) {
          return target;
        }
      } else {
        return null;
      }
    }
    if (node is PrefixedIdentifier) {
      if (identical(node.identifier, target.entity)) {
        return node.prefix;
      } else {
        return null;
      }
    }
    return null;
  }
}

/**
 * This class visits elements in a library and provides suggestions based upon
 * the visible members in that library.
 */
class _SuggestionBuilder extends GeneralizingElementVisitor {
  final List<CompletionSuggestion> suggestions;
  final bool typesOnly;
  final bool instCreation;

  _SuggestionBuilder(this.suggestions, this.typesOnly, this.instCreation);

  @override
  visitClassElement(ClassElement element) {
    if (instCreation) {
      element.visitChildren(this);
    } else {
      _addSuggestion(element);
    }
  }

  @override
  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
    LibraryElement containingLibrary = element.library;
    if (containingLibrary != null) {
      for (var lib in containingLibrary.exportedLibraries) {
        lib.visitChildren(this);
      }
    }
  }

  @override
  visitConstructorElement(ConstructorElement element) {
    if (instCreation) {
      ClassElement classElem = element.enclosingElement;
      if (classElem != null) {
        String prefix = classElem.name;
        if (prefix != null && prefix.length > 0) {
          _addSuggestion(element, prefix: prefix);
        }
      }
    }
  }

  @override
  visitElement(Element element) {
    // ignored
  }

  @override
  visitFunctionElement(FunctionElement element) {
    if (!typesOnly) {
      _addSuggestion(element);
    }
  }

  @override
  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    if (!instCreation) {
      _addSuggestion(element);
    }
  }

  @override
  visitTopLevelVariableElement(TopLevelVariableElement element) {
    if (!typesOnly) {
      _addSuggestion(element);
    }
  }

  void _addSuggestion(Element element, {String prefix}) {
    if (element.isPrivate) {
      return;
    }
    String completion = element.displayName;
    if (prefix != null && prefix.length > 0) {
      if (completion == null || completion.length <= 0) {
        completion = prefix;
      } else {
        completion = '$prefix.$completion';
      }
    }
    if (completion != null && completion.length > 0) {
      CompletionSuggestion suggestion = createSuggestion(element,
          completion: completion,
          kind: CompletionSuggestionKind.INVOCATION,
          relevance: DART_RELEVANCE_DEFAULT);
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }
  }
}
