// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.search.search_engine2;

import 'dart:async';

import 'package:analysis_server/src/services/index2/index2.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/source.dart' show SourceRange;
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
      return _searchReferences_Function(element);
    } else if (kind == ElementKind.IMPORT) {
      return _searchReferences(element);
    } else if (kind == ElementKind.LABEL) {
      return _searchReferences(element);
    } else if (kind == ElementKind.LIBRARY) {
      return _searchReferences(element);
    } else if (kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_LocalVariable(element as LocalVariableElement);
    } else if (kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element as ParameterElement);
    } else if (kind == ElementKind.PREFIX) {
      return _searchReferences(element);
    } else if (kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_TypeParameter(element);
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

  Future<List<SearchMatch>> _searchReferences(Element element) {
    _Requestor requestor = new _Requestor(context, _index);
    requestor.addElement(
        element, IndexRelationKind.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Field(
      PropertyInducingElement field) {
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
    _Requestor requestor = new _Requestor(context, _index);
    // field itself
    requestor.addElement(
        field, IndexRelationKind.IS_REFERENCED_BY, MatchKind.REFERENCE);
    // getter
    if (getter != null) {
      requestor.addElement(
          getter, IndexRelationKind.IS_REFERENCED_BY, MatchKind.READ);
      requestor.addElement(
          getter, IndexRelationKind.IS_INVOKED_BY, MatchKind.INVOCATION);
    }
    // setter
    if (setter != null) {
      requestor.addElement(
          setter, IndexRelationKind.IS_REFERENCED_BY, MatchKind.WRITE);
    }
    // done
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Function(Element element) {
    if (element is Member) {
      element = (element as Member).baseElement;
    }
    _Requestor requestor = new _Requestor(context, _index);
    requestor.addElement(
        element, IndexRelationKind.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.addElement(
        element, IndexRelationKind.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_LocalVariable(
      LocalVariableElement variable) {
    // TODO(scheglov) implement using AST visitor
    throw new UnimplementedError();
//    _Requestor requestor = new _Requestor(context, _index);
//    requestor.addElement(variable, IndexRelationKind.IS_READ_BY, MatchKind.READ);
//    requestor.addElement(
//        variable, IndexRelationKind.IS_READ_WRITTEN_BY, MatchKind.READ_WRITE);
//    requestor.addElement(
//        variable, IndexRelationKind.IS_WRITTEN_BY, MatchKind.WRITE);
//    requestor.addElement(
//        variable, IndexRelationKind.IS_INVOKED_BY, MatchKind.INVOCATION);
//    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Parameter(
      ParameterElement parameter) {
    // TODO(scheglov) implement using AST visitor
    throw new UnimplementedError();
//    _Requestor requestor = new _Requestor(context, _index);
//    requestor.addElement(parameter, IndexRelationKind.IS_READ_BY, MatchKind.READ);
//    requestor.addElement(
//        parameter, IndexRelationKind.IS_READ_WRITTEN_BY, MatchKind.READ_WRITE);
//    requestor.addElement(
//        parameter, IndexRelationKind.IS_WRITTEN_BY, MatchKind.WRITE);
//    requestor.addElement(
//        parameter, IndexRelationKind.IS_REFERENCED_BY, MatchKind.REFERENCE);
//    requestor.addElement(
//        parameter, IndexRelationKind.IS_INVOKED_BY, MatchKind.INVOCATION);
//    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_TypeParameter(
      ParameterElement parameter) {
    // TODO(scheglov) implement using AST visitor
    throw new UnimplementedError();
  }
}

class _Requestor {
  final AnalysisContext context;
  final Index2 index;
  final List<Future<List<SearchMatch>>> futures = <Future<List<SearchMatch>>>[];

  _Requestor(this.context, this.index);

  void addElement(
      Element element, IndexRelationKind relationKind, MatchKind kind) {
    Future relationsFuture = index.getRelations(element, relationKind);
    Future matchesFuture = relationsFuture.then((List<Location> locations) {
      List<SearchMatch> matches = <SearchMatch>[];
      for (Location location in locations) {
        matches.add(_convertLocation(location, kind));
      }
      return matches;
    });
    futures.add(matchesFuture);
  }

//  void addElement(
//      Element element, RelationshipImpl relationship, MatchKind kind) {
//    IndexableElement indexable = new IndexableElement(element);
//    add(indexable, relationship, kind);
//  }

  Future<List<SearchMatch>> merge() {
    return Future.wait(futures).then((List<List<SearchMatch>> matchesList) {
      return matchesList.expand((matches) => matches).toList();
    });
  }

  SearchMatch _convertLocation(Location location, MatchKind kind) {
    return new SearchMatch(
        context,
        location.libraryUri,
        location.unitUri,
        kind,
        new SourceRange(location.offset, location.length),
        true,
        location.isQualified);
  }
}
