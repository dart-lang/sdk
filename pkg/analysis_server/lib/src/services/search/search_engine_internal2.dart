// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.search.search_engine2;

import 'dart:async';

import 'package:analysis_server/src/services/index2/index2.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/idl.dart';

/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl2 implements SearchEngine {
  final AnalysisContext context;
  final Index2 _index;

  SearchEngineImpl2(this.context, this._index);

  @override
  Future<List<SearchMatch>> searchAllSubtypes(ClassElement type) {
    // TODO: implement searchAllSubtypes
    throw new UnimplementedError();
  }

  @override
  Future<List<SearchMatch>> searchElementDeclarations(String name) {
    // TODO: implement searchElementDeclarations
    throw new UnimplementedError();
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) {
    // TODO: implement searchMemberDeclarations
    throw new UnimplementedError();
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) {
    // TODO: implement searchMemberReferences
    throw new UnimplementedError();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) {
    ElementKind kind = element.kind;
    if (kind == ElementKind.CLASS ||
        kind == ElementKind.COMPILATION_UNIT ||
        kind == ElementKind.CONSTRUCTOR ||
        kind == ElementKind.FUNCTION_TYPE_ALIAS ||
        kind == ElementKind.GETTER ||
        kind == ElementKind.SETTER) {
      return _searchReferences(element);
    } else if (kind == ElementKind.FIELD ||
        kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return _searchReferences_Field(element as PropertyInducingElement);
    } else if (kind == ElementKind.FUNCTION || kind == ElementKind.METHOD) {
      if (element.enclosingElement is ExecutableElement) {
        return _searchReferences_Local(element, (n) => n is Block);
      }
      return _searchReferences_Function(element);
    } else if (kind == ElementKind.IMPORT) {
      // TODO(scheglov) implement whole library search
      return _searchReferences(element);
    } else if (kind == ElementKind.LABEL ||
        kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_Local(element, (n) => n is Block);
    } else if (kind == ElementKind.LIBRARY) {
      // TODO(scheglov) implement whole library search
      return _searchReferences(element);
    } else if (kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element);
    } else if (kind == ElementKind.PREFIX) {
      // TODO(scheglov) implement whole library search
      return _searchReferences(element);
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_Local(element, (n) => n is ClassDeclaration);
    }
    return new Future.value(<SearchMatch>[]);
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) {
    // TODO: implement searchSubtypes
    throw new UnimplementedError();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) {
    // TODO: implement searchTopLevelDeclarations
    throw new UnimplementedError();
  }

  _addMatches(List<SearchMatch> matches, Element element,
      IndexRelationKind relationKind, MatchKind kind) async {
    List<Location> locations = await _index.getRelations(element, relationKind);
    for (Location location in locations) {
      matches.add(new SearchMatch(
          context,
          location.libraryUri,
          location.unitUri,
          kind,
          new SourceRange(location.offset, location.length),
          true,
          location.isQualified));
    }
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
    await _addMatches(matches, field, IndexRelationKind.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
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

  Future<List<SearchMatch>> _searchReferences_Local(
      Element element, bool isRootNode(AstNode n)) async {
    AstNode node = element.computeNode();
    AstNode enclosingNode = node.getAncestor(isRootNode);
    _LocalReferencesVisitor visitor = new _LocalReferencesVisitor(element);
    enclosingNode.accept(visitor);
    return visitor.matches;
  }

  Future<List<SearchMatch>> _searchReferences_Parameter(
      ParameterElement parameter) async {
    List<SearchMatch> matches = <SearchMatch>[];
    matches.addAll(await _searchReferences(parameter));
    matches.addAll(await _searchReferences_Local(
        parameter, (n) => n is MethodDeclaration || n is FunctionExpression));
    return matches;
  }
}

/**
 * Visitor that adds [SearchMatch]es for local elements - labels, local
 * functions, local variables and parameters.
 */
class _LocalReferencesVisitor extends RecursiveAstVisitor {
  final List<SearchMatch> matches = <SearchMatch>[];

  final Element element;
  final AnalysisContext context;
  final String libraryUri;
  final String unitUri;

  _LocalReferencesVisitor(Element element)
      : element = element,
        context = element.context,
        libraryUri = element.library.source.uri.toString(),
        unitUri = element.source.uri.toString();

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

  void _addMatch(SimpleIdentifier node, MatchKind kind) {
    matches.add(new SearchMatch(context, libraryUri, unitUri, kind,
        new SourceRange(node.offset, node.length), true, node.isQualified));
  }
}
