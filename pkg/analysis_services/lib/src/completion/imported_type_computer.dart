// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.completion.computer.dart.toplevel;

import 'dart:async';

import 'package:analysis_services/completion/completion_computer.dart';
import 'package:analysis_services/completion/completion_suggestion.dart';
import 'package:analysis_services/search/search_engine.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';

/**
 * A computer for calculating imported class and top level variable
 * `completion.getSuggestions` request results.
 */
class ImportedTypeComputer extends CompletionComputer {

  @override
  bool computeFast(CompilationUnit unit, AstNode node,
      List<CompletionSuggestion> suggestions) {
    // TODO: implement computeFast
    // - compute results based upon current search, then replace those results
    // during the full compute phase
    // - filter results based upon completion offset
    return false;
  }

  @override
  Future<bool> computeFull(CompilationUnit unit, AstNode node,
      List<CompletionSuggestion> suggestions) {
    return node.accept(
        new _ImportedTypeVisitor(searchEngine, unit, offset, suggestions));
  }
}

/**
 * Visits the node at which the completion is requested
 * and builds the list of suggestions.
 */
class _ImportedTypeVisitor extends GeneralizingAstVisitor<Future<bool>> {
  final SearchEngine searchEngine;
  final CompilationUnit unit;
  final int offset;
  final List<CompletionSuggestion> suggestions;

  _ImportedTypeVisitor(this.searchEngine, this.unit, this.offset,
      this.suggestions);

  Future<bool> visitCombinator(Combinator node) {
    var directive = node.getAncestor((parent) => parent is NamespaceDirective);
    if (directive is NamespaceDirective) {
      return _addLibraryElements(directive.uriElement);
    }
    return new Future.value(true);
  }

  Future<bool> visitNode(AstNode node) {
    return _addImportedElements();
  }

  Future<bool> visitSimpleIdentifier(SimpleIdentifier node) {
    return node.parent.accept(this);
  }

  Future<bool> visitVariableDeclaration(VariableDeclaration node) {
    // Do not add suggestions if editing the name in a var declaration
    SimpleIdentifier name = node.name;
    if (name == null || name.offset < offset || offset > name.end) {
      return visitNode(node);
    }
    return new Future.value(false);
  }

  Future<bool> _addImportedElements() {
    var future = searchEngine.searchTopLevelDeclarations('');
    return future.then((List<SearchMatch> matches) {

      Set<LibraryElement> visibleLibs = new Set<LibraryElement>();
      Set<LibraryElement> excludedLibs = new Set<LibraryElement>();

      Map<LibraryElement, Set<String>> showNames =
          new Map<LibraryElement, Set<String>>();
      Map<LibraryElement, Set<String>> hideNames =
          new Map<LibraryElement, Set<String>>();

      // Exclude elements from the local library
      // as they will be included by the LocalComputer
      excludedLibs.add(unit.element.library);
      unit.directives.forEach((Directive directive) {
        if (directive is ImportDirective) {
          LibraryElement lib = directive.element.importedLibrary;
          if (directive.prefix == null) {
            visibleLibs.add(lib);
            directive.combinators.forEach((Combinator combinator) {
              if (combinator is ShowCombinator) {
                showNames[lib] = combinator.shownNames.map(
                    (SimpleIdentifier id) => id.name).toSet();
              } else if (combinator is HideCombinator) {
                hideNames[lib] = combinator.hiddenNames.map(
                    (SimpleIdentifier id) => id.name).toSet();
              }
            });
          } else {
            excludedLibs.add(lib);
          }
        }
      });

      // Compute the set of possible classes, functions, and top level variables
      matches.forEach((SearchMatch match) {
        if (match.kind == MatchKind.DECLARATION) {
          Element element = match.element;
          LibraryElement lib = element.library;
          if (element.isPublic && !excludedLibs.contains(lib)) {
            String completion = element.displayName;
            Set<String> show = showNames[lib];
            Set<String> hide = hideNames[lib];
            if ((show == null || show.contains(completion)) &&
                (hide == null || !hide.contains(completion))) {
              suggestions.add(
                  new CompletionSuggestion(
                      CompletionSuggestionKind.fromElementKind(element.kind),
                      visibleLibs.contains(lib) || lib.isDartCore ?
                          CompletionRelevance.DEFAULT :
                          CompletionRelevance.LOW,
                      completion,
                      completion.length,
                      0,
                      element.isDeprecated,
                      false // isPotential
              ));
            }
          }
        }
      });
      return true;
    });
  }

  Future<bool> _addLibraryElements(LibraryElement library) {
    library.visitChildren(new _LibraryElementVisitor(suggestions));
    return new Future.value(true);
  }
}

/**
 * Provides suggestions from a single library for the show/hide combinators
 * as in `import "foo.dart" show ` where the completion offset is after
 * the `show`.
 */
class _LibraryElementVisitor extends GeneralizingElementVisitor {
  final List<CompletionSuggestion> suggestions;

  _LibraryElementVisitor(this.suggestions);

  visitClassElement(ClassElement element) {
    _addSuggestion(element);
  }

  visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
  }

  visitElement(Element element) {
    // ignored
  }

  visitFunctionTypeAliasElement(FunctionTypeAliasElement element) {
    _addSuggestion(element);
  }

  visitTopLevelVariableElement(TopLevelVariableElement element) {
    _addSuggestion(element);
  }

  void _addSuggestion(Element element) {
    if (element != null) {
      String completion = element.name;
      if (completion != null && completion.length > 0) {
        suggestions.add(
            new CompletionSuggestion(
                CompletionSuggestionKind.fromElementKind(element.kind),
                CompletionRelevance.DEFAULT,
                completion,
                completion.length,
                0,
                element.isDeprecated,
                false // isPotential
        ));
      }
    }
  }
}
