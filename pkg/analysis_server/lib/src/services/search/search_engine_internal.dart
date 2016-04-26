// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.src.services.search.search_engine_internal;

import 'dart:async';

import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/resolver.dart' show NamespaceBuilder;
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:analyzer/src/summary/idl.dart';

/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl implements SearchEngine {
  final Index _index;

  SearchEngineImpl(this._index);

  @override
  Future<List<SearchMatch>> searchAllSubtypes(ClassElement type) async {
    List<SearchMatch> matches = <SearchMatch>[];
    await _addMatches(
        matches, type, IndexRelationKind.IS_ANCESTOR_OF, MatchKind.DECLARATION);
    return matches;
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String pattern) {
    return _searchDefinedNames(pattern, IndexNameKind.classMember);
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) async {
    List<Location> locations = await _index.getUnresolvedMemberReferences(name);
    return locations.map((location) {
      return _newMatchForLocation(location, null);
    }).toList();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) {
    ElementKind kind = element.kind;
    if (kind == ElementKind.CLASS ||
        kind == ElementKind.COMPILATION_UNIT ||
        kind == ElementKind.CONSTRUCTOR ||
        kind == ElementKind.FUNCTION_TYPE_ALIAS ||
        kind == ElementKind.SETTER) {
      return _searchReferences(element);
    } else if (kind == ElementKind.GETTER) {
      return _searchReferences_Getter(element);
    } else if (kind == ElementKind.FIELD ||
        kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return _searchReferences_Field(element);
    } else if (kind == ElementKind.FUNCTION || kind == ElementKind.METHOD) {
      if (element.enclosingElement is ExecutableElement) {
        return _searchReferences_Local(element, (n) => n is Block);
      }
      return _searchReferences_Function(element);
    } else if (kind == ElementKind.IMPORT) {
      return _searchReferences_Import(element);
    } else if (kind == ElementKind.LABEL ||
        kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_Local(element, (n) => n is Block);
    } else if (kind == ElementKind.LIBRARY) {
      return _searchReferences_Library(element);
    } else if (kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element);
    } else if (kind == ElementKind.PREFIX) {
      return _searchReferences_Prefix(element);
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_Local(element, (n) => n is ClassDeclaration);
    }
    return new Future.value(<SearchMatch>[]);
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) async {
    List<SearchMatch> matches = <SearchMatch>[];
    await _addMatches(
        matches, type, IndexRelationKind.IS_EXTENDED_BY, MatchKind.REFERENCE);
    await _addMatches(
        matches, type, IndexRelationKind.IS_MIXED_IN_BY, MatchKind.REFERENCE);
    await _addMatches(matches, type, IndexRelationKind.IS_IMPLEMENTED_BY,
        MatchKind.REFERENCE);
    return matches;
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) {
    return _searchDefinedNames(pattern, IndexNameKind.topLevel);
  }

  _addMatches(List<SearchMatch> matches, Element element,
      IndexRelationKind relationKind, MatchKind kind) async {
    List<Location> locations = await _index.getRelations(element, relationKind);
    for (Location location in locations) {
      SearchMatch match = _newMatchForLocation(location, kind);
      matches.add(match);
    }
  }

  SearchMatch _newMatchForLocation(Location location, MatchKind kind) {
    if (kind == null) {
      IndexRelationKind relationKind = location.kind;
      if (relationKind == IndexRelationKind.IS_INVOKED_BY) {
        kind = MatchKind.INVOCATION;
      } else if (relationKind == IndexRelationKind.IS_REFERENCED_BY) {
        kind = MatchKind.REFERENCE;
      } else if (relationKind == IndexRelationKind.IS_READ_BY) {
        kind = MatchKind.READ;
      } else if (relationKind == IndexRelationKind.IS_READ_WRITTEN_BY) {
        kind = MatchKind.READ_WRITE;
      } else if (relationKind == IndexRelationKind.IS_WRITTEN_BY) {
        kind = MatchKind.WRITE;
      } else {
        throw new ArgumentError('Unsupported relation kind $relationKind');
      }
    }
    return new SearchMatch(
        location.context,
        location.libraryUri,
        location.unitUri,
        kind,
        new SourceRange(location.offset, location.length),
        location.isResolved,
        location.isQualified);
  }

  Future<List<SearchMatch>> _searchDefinedNames(
      String pattern, IndexNameKind nameKind) async {
    RegExp regExp = new RegExp(pattern);
    List<Location> locations = await _index.getDefinedNames(regExp, nameKind);
    return locations.map((location) {
      return _newMatchForLocation(location, MatchKind.DECLARATION);
    }).toList();
  }

  Future<List<SearchMatch>> _searchReferences(Element element) async {
    List<SearchMatch> matches = <SearchMatch>[];
    await _addMatches(matches, element, IndexRelationKind.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Field(
      PropertyInducingElement field) async {
    List<SearchMatch> matches = <SearchMatch>[];
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
    // field itself
    if (!field.isSynthetic) {
      await _addMatches(
          matches, field, IndexRelationKind.IS_WRITTEN_BY, MatchKind.WRITE);
      await _addMatches(matches, field, IndexRelationKind.IS_REFERENCED_BY,
          MatchKind.REFERENCE);
    }
    // getter
    if (getter != null) {
      await _addMatches(
          matches, getter, IndexRelationKind.IS_REFERENCED_BY, MatchKind.READ);
      await _addMatches(matches, getter, IndexRelationKind.IS_INVOKED_BY,
          MatchKind.INVOCATION);
    }
    // setter
    if (setter != null) {
      await _addMatches(
          matches, setter, IndexRelationKind.IS_REFERENCED_BY, MatchKind.WRITE);
    }
    // done
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Function(Element element) async {
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    List<SearchMatch> matches = <SearchMatch>[];
    await _addMatches(matches, element, IndexRelationKind.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    await _addMatches(matches, element, IndexRelationKind.IS_INVOKED_BY,
        MatchKind.INVOCATION);
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Getter(
      PropertyAccessorElement getter) async {
    List<SearchMatch> matches = <SearchMatch>[];
    await _addMatches(matches, getter, IndexRelationKind.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    await _addMatches(
        matches, getter, IndexRelationKind.IS_INVOKED_BY, MatchKind.INVOCATION);
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Import(
      ImportElement element) async {
    List<SearchMatch> matches = <SearchMatch>[];
    LibraryElement libraryElement = element.library;
    Source librarySource = libraryElement.source;
    AnalysisContext context = libraryElement.context;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      Source unitSource = unitElement.source;
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, librarySource);
      _ImportElementReferencesVisitor visitor =
          new _ImportElementReferencesVisitor(
              element, unitSource.uri.toString());
      unit.accept(visitor);
      matches.addAll(visitor.matches);
    }
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Library(Element element) async {
    List<SearchMatch> matches = <SearchMatch>[];
    LibraryElement libraryElement = element.library;
    Source librarySource = libraryElement.source;
    AnalysisContext context = libraryElement.context;
    for (CompilationUnitElement unitElement in libraryElement.parts) {
      Source unitSource = unitElement.source;
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, librarySource);
      for (Directive directive in unit.directives) {
        if (directive is PartOfDirective &&
            directive.element == libraryElement) {
          matches.add(new SearchMatch(
              context,
              librarySource.uri.toString(),
              unitSource.uri.toString(),
              MatchKind.REFERENCE,
              rangeNode(directive.libraryName),
              true,
              false));
        }
      }
    }
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Local(
      Element element, bool isRootNode(AstNode n)) async {
    _LocalReferencesVisitor visitor = new _LocalReferencesVisitor(element);
    AstNode node = element.computeNode();
    AstNode enclosingNode = node?.getAncestor(isRootNode);
    enclosingNode?.accept(visitor);
    return visitor.matches;
  }

  Future<List<SearchMatch>> _searchReferences_Parameter(
      ParameterElement parameter) async {
    List<SearchMatch> matches = <SearchMatch>[];
    matches.addAll(await _searchReferences(parameter));
    matches.addAll(await _searchReferences_Local(
        parameter,
        (n) =>
            n is ConstructorDeclaration ||
            n is MethodDeclaration ||
            n is FunctionExpression));
    return matches;
  }

  Future<List<SearchMatch>> _searchReferences_Prefix(
      PrefixElement element) async {
    List<SearchMatch> matches = <SearchMatch>[];
    LibraryElement libraryElement = element.library;
    Source librarySource = libraryElement.source;
    AnalysisContext context = libraryElement.context;
    for (CompilationUnitElement unitElement in libraryElement.units) {
      Source unitSource = unitElement.source;
      CompilationUnit unit =
          context.resolveCompilationUnit2(unitSource, librarySource);
      _LocalReferencesVisitor visitor =
          new _LocalReferencesVisitor(element, unitSource.uri.toString());
      unit.accept(visitor);
      matches.addAll(visitor.matches);
    }
    return matches;
  }
}

/**
 * Visitor that adds [SearchMatch]es for [importElement], both with an explicit
 * prefix or an implicit one.
 */
class _ImportElementReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchMatch> matches = <SearchMatch>[];

  final ImportElement importElement;
  final AnalysisContext context;
  final String libraryUri;
  final String unitUri;
  Set<Element> importedElements;

  _ImportElementReferencesVisitor(ImportElement element, this.unitUri)
      : importElement = element,
        context = element.context,
        libraryUri = element.library.source.uri.toString() {
    importedElements = new NamespaceBuilder()
        .createImportNamespaceForDirective(element)
        .definedNames
        .values
        .toSet();
  }

  @override
  visitExportDirective(ExportDirective node) {}

  @override
  visitImportDirective(ImportDirective node) {}

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (importElement.prefix != null) {
      if (node.staticElement == importElement.prefix) {
        AstNode parent = node.parent;
        if (parent is PrefixedIdentifier && parent.prefix == node) {
          if (importedElements.contains(parent.staticElement)) {
            _addMatchForPrefix(node, parent.identifier);
          }
        }
        if (parent is MethodInvocation && parent.target == node) {
          if (importedElements.contains(parent.methodName.staticElement)) {
            _addMatchForPrefix(node, parent.methodName);
          }
        }
      }
    } else {
      if (importedElements.contains(node.staticElement)) {
        SourceRange range = rangeStartLength(node, 0);
        _addMatchForRange(range);
      }
    }
  }

  void _addMatchForPrefix(SimpleIdentifier prefixNode, AstNode nextNode) {
    SourceRange range = rangeStartStart(prefixNode, nextNode);
    _addMatchForRange(range);
  }

  void _addMatchForRange(SourceRange range) {
    matches.add(new SearchMatch(
        context, libraryUri, unitUri, MatchKind.REFERENCE, range, true, false));
  }
}

/**
 * Visitor that adds [SearchMatch]es for local elements of a block, method,
 * class or a library - labels, local functions, local variables and parameters,
 * type parameters, import prefixes.
 */
class _LocalReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchMatch> matches = <SearchMatch>[];

  final Element element;
  final AnalysisContext context;
  final String libraryUri;
  final String unitUri;

  _LocalReferencesVisitor(Element element, [String unitUri])
      : element = element,
        context = element.context,
        libraryUri = element.library.source.uri.toString(),
        unitUri = unitUri ?? element.source.uri.toString();

  @override
  visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.inDeclarationContext()) {
      return;
    }
    if (node.bestElement == element) {
      AstNode parent = node.parent;
      MatchKind kind = MatchKind.REFERENCE;
      if (element is FunctionElement) {
        if (parent is MethodInvocation && parent.methodName == node) {
          kind = MatchKind.INVOCATION;
        }
      } else if (element is VariableElement) {
        bool isGet = node.inGetterContext();
        bool isSet = node.inSetterContext();
        if (isGet && isSet) {
          kind = MatchKind.READ_WRITE;
        } else if (isGet) {
          if (parent is MethodInvocation && parent.methodName == node) {
            kind = MatchKind.INVOCATION;
          } else {
            kind = MatchKind.READ;
          }
        } else if (isSet) {
          kind = MatchKind.WRITE;
        }
      }
      _addMatch(node, kind);
    }
  }

  void _addMatch(AstNode node, MatchKind kind) {
    bool isQualified = node is SimpleIdentifier && node.isQualified;
    matches.add(new SearchMatch(context, libraryUri, unitUri, kind,
        rangeNode(node), true, isQualified));
  }
}
