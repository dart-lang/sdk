// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.search.search_engine;

import 'dart:async';

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/indexable_element.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl implements SearchEngine {
  final Index _index;

  SearchEngineImpl(this._index);

  @override
  Future<List<SearchMatch>> searchAllSubtypes(ClassElement type) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(
        type, IndexConstants.HAS_ANCESTOR, MatchKind.DECLARATION);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchElementDeclarations(String name) {
    IndexableName indexableName = new IndexableName(name);
    _Requestor requestor = new _Requestor(_index);
    requestor.add(indexableName, IndexConstants.NAME_IS_DEFINED_BY,
        MatchKind.DECLARATION);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchMemberDeclarations(String name) {
    return searchElementDeclarations(name).then((matches) {
      return matches.where((match) {
        return match.element.enclosingElement is ClassElement;
      }).toList();
    });
  }

  @override
  Future<List<SearchMatch>> searchMemberReferences(String name) {
    IndexableName indexableName = new IndexableName(name);
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        indexableName, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    requestor.add(indexableName, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.add(
        indexableName, IndexConstants.IS_READ_WRITTEN_BY, MatchKind.READ_WRITE);
    requestor.add(indexableName, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) {
    if (element.kind == ElementKind.CLASS) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.COMPILATION_UNIT) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.CONSTRUCTOR) {
      return _searchReferences_Constructor(element as ConstructorElement);
    } else if (element.kind == ElementKind.FIELD ||
        element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return _searchReferences_Field(element as PropertyInducingElement);
    } else if (element.kind == ElementKind.FUNCTION) {
      return _searchReferences_Function(element as FunctionElement);
    } else if (element.kind == ElementKind.GETTER ||
        element.kind == ElementKind.SETTER) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.IMPORT) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.LABEL) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.LIBRARY) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_LocalVariable(element as LocalVariableElement);
    } else if (element.kind == ElementKind.METHOD) {
      return _searchReferences_Method(element as MethodElement);
    } else if (element.kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element as ParameterElement);
    } else if (element.kind == ElementKind.PREFIX) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
      return _searchReferences(element);
    } else if (element.kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences(element);
    }
    return new Future.value(<SearchMatch>[]);
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(
        type, IndexConstants.IS_EXTENDED_BY, MatchKind.REFERENCE);
    requestor.addElement(
        type, IndexConstants.IS_MIXED_IN_BY, MatchKind.REFERENCE);
    requestor.addElement(
        type, IndexConstants.IS_IMPLEMENTED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) {
    RegExp regExp = new RegExp(pattern);
    List<Element> elements =
        _index.getTopLevelDeclarations((String name) => regExp.hasMatch(name));
    List<SearchMatch> matches = <SearchMatch>[];
    for (Element element in elements) {
      matches.add(new SearchMatch(
          element.context,
          element.library.source.uri.toString(),
          element.source.uri.toString(),
          MatchKind.DECLARATION,
          rangeElementName(element),
          true,
          false));
    }
    return new Future.value(matches);
  }

  Future<List<SearchMatch>> _searchReferences(Element element) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(
        element, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Constructor(
      ConstructorElement constructor) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(
        constructor, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Field(
      PropertyInducingElement field) {
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
    _Requestor requestor = new _Requestor(_index);
    // field itself
    requestor.addElement(
        field, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.addElement(field, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    // getter
    if (getter != null) {
      requestor.addElement(
          getter, IndexConstants.IS_REFERENCED_BY, MatchKind.READ);
      requestor.addElement(
          getter, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    }
    // setter
    if (setter != null) {
      requestor.addElement(
          setter, IndexConstants.IS_REFERENCED_BY, MatchKind.WRITE);
    }
    // done
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Function(
      FunctionElement function) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(
        function, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.addElement(
        function, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_LocalVariable(
      LocalVariableElement variable) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(variable, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.addElement(
        variable, IndexConstants.IS_READ_WRITTEN_BY, MatchKind.READ_WRITE);
    requestor.addElement(
        variable, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    requestor.addElement(
        variable, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Method(MethodElement method) {
    _Requestor requestor = new _Requestor(_index);
    if (method is MethodMember) {
      method = (method as MethodMember).baseElement;
    }
    requestor.addElement(
        method, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.addElement(
        method, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Parameter(
      ParameterElement parameter) {
    _Requestor requestor = new _Requestor(_index);
    requestor.addElement(parameter, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.addElement(
        parameter, IndexConstants.IS_READ_WRITTEN_BY, MatchKind.READ_WRITE);
    requestor.addElement(
        parameter, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    requestor.addElement(
        parameter, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.addElement(
        parameter, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }
}

class _Requestor {
  final List<Future<List<SearchMatch>>> futures = <Future<List<SearchMatch>>>[];
  final Index index;

  _Requestor(this.index);

  void add(IndexableObject indexable, RelationshipImpl relationship,
      MatchKind kind) {
    Future relationsFuture = index.getRelationships(indexable, relationship);
    Future matchesFuture = relationsFuture.then((List<LocationImpl> locations) {
      List<SearchMatch> matches = <SearchMatch>[];
      for (LocationImpl location in locations) {
        IndexableObject indexable = location.indexable;
        if (indexable is IndexableElement) {
          Element element = indexable.element;
          matches.add(new SearchMatch(
              element.context,
              element.library.source.uri.toString(),
              element.source.uri.toString(),
              kind,
              new SourceRange(location.offset, location.length),
              location.isResolved,
              location.isQualified));
        }
      }
      return matches;
    });
    futures.add(matchesFuture);
  }

  void addElement(
      Element element, RelationshipImpl relationship, MatchKind kind) {
    IndexableElement indexable = new IndexableElement(element);
    add(indexable, relationship, kind);
  }

  Future<List<SearchMatch>> merge() {
    return Future.wait(futures).then((List<List<SearchMatch>> matchesList) {
      return matchesList.expand((matches) => matches).toList();
    });
  }
}
