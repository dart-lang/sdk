// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.search.search_engine;

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A [SearchEngine] implementation.
 */
class SearchEngineImpl implements SearchEngine {
  final Index _index;

  SearchEngineImpl(this._index);

  @override
  Future<List<SearchMatch>> searchElementDeclarations(String name) {
    NameElement element = new NameElement(name);
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        element,
        IndexConstants.NAME_IS_DEFINED_BY,
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
    NameElement element = new NameElement(name);
    _Requestor requestor = new _Requestor(_index);
    requestor.add(element, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    requestor.add(element, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.add(
        element,
        IndexConstants.IS_READ_WRITTEN_BY,
        MatchKind.READ_WRITE);
    requestor.add(element, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchReferences(Element element) {
    if (element.kind == ElementKind.ANGULAR_COMPONENT ||
        element.kind == ElementKind.ANGULAR_CONTROLLER ||
        element.kind == ElementKind.ANGULAR_FORMATTER ||
        element.kind == ElementKind.ANGULAR_PROPERTY ||
        element.kind == ElementKind.ANGULAR_SCOPE_PROPERTY ||
        element.kind == ElementKind.ANGULAR_SELECTOR) {
      return _searchReferences_Angular(element as AngularElement);
    } else if (element.kind == ElementKind.CLASS) {
      return _searchReferences_Class(element as ClassElement);
    } else if (element.kind == ElementKind.COMPILATION_UNIT) {
      return _searchReferences_CompilationUnit(
          element as CompilationUnitElement);
    } else if (element.kind == ElementKind.CONSTRUCTOR) {
      return _searchReferences_Constructor(element as ConstructorElement);
    } else if (element.kind == ElementKind.FIELD ||
        element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
      return _searchReferences_Field(element as PropertyInducingElement);
    } else if (element.kind == ElementKind.FUNCTION) {
      return _searchReferences_Function(element as FunctionElement);
    } else if (element.kind == ElementKind.GETTER ||
        element.kind == ElementKind.SETTER) {
      return _searchReferences_PropertyAccessor(
          element as PropertyAccessorElement);
    } else if (element.kind == ElementKind.IMPORT) {
      return _searchReferences_Import(element as ImportElement);
    } else if (element.kind == ElementKind.LABEL) {
      return _searchReferences_Label(element as LabelElement);
    } else if (element.kind == ElementKind.LIBRARY) {
      return _searchReferences_Library(element as LibraryElement);
    } else if (element.kind == ElementKind.LOCAL_VARIABLE) {
      return _searchReferences_LocalVariable(element as LocalVariableElement);
    } else if (element.kind == ElementKind.METHOD) {
      return _searchReferences_Method(element as MethodElement);
    } else if (element.kind == ElementKind.PARAMETER) {
      return _searchReferences_Parameter(element as ParameterElement);
    } else if (element.kind == ElementKind.FUNCTION_TYPE_ALIAS) {
      return _searchReferences_FunctionTypeAlias(
          element as FunctionTypeAliasElement);
    } else if (element.kind == ElementKind.TYPE_PARAMETER) {
      return _searchReferences_TypeParameter(element as TypeParameterElement);
    }
    return new Future.value(<SearchMatch>[]);
  }

  @override
  Future<List<SearchMatch>> searchSubtypes(ClassElement type) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(type, IndexConstants.IS_EXTENDED_BY, MatchKind.REFERENCE);
    requestor.add(type, IndexConstants.IS_MIXED_IN_BY, MatchKind.REFERENCE);
    requestor.add(type, IndexConstants.IS_IMPLEMENTED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  @override
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern) {
    UniverseElement universe = UniverseElement.INSTANCE;
    _Requestor requestor = new _Requestor(_index);
    requestor.add(universe, IndexConstants.DEFINES, MatchKind.DECLARATION);
    RegExp regExp = new RegExp(pattern);
    return requestor.merge().then((List<SearchMatch> matches) {
      return matches.where((SearchMatch match) {
        String name = match.element.displayName;
        return regExp.hasMatch(name);
      }).toList();
    });
  }

  Future<List<SearchMatch>> _searchReferences_Angular(AngularElement element) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        element,
        IndexConstants.ANGULAR_REFERENCE,
        MatchKind.ANGULAR_REFERENCE);
    requestor.add(
        element,
        IndexConstants.ANGULAR_CLOSING_TAG_REFERENCE,
        MatchKind.ANGULAR_CLOSING_TAG_REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Class(ClassElement clazz) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(clazz, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_CompilationUnit(CompilationUnitElement unit) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(unit, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_Constructor(ConstructorElement constructor) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        constructor,
        IndexConstants.NAME_IS_DEFINED_BY,
        MatchKind.DECLARATION);
    requestor.add(
        constructor,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_Field(PropertyInducingElement field) {
    PropertyAccessorElement getter = field.getter;
    PropertyAccessorElement setter = field.setter;
    _Requestor requestor = new _Requestor(_index);
    // field itself
    requestor.add(field, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    // getter
    if (getter != null) {
      requestor.add(getter, IndexConstants.IS_REFERENCED_BY, MatchKind.READ);
      requestor.add(getter, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    }
    // setter
    if (setter != null) {
      requestor.add(setter, IndexConstants.IS_REFERENCED_BY, MatchKind.WRITE);
    }
    // done
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_Function(FunctionElement function) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        function,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    requestor.add(function, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_FunctionTypeAlias(FunctionTypeAliasElement alias) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(alias, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Import(ImportElement imp) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(imp, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Label(LabelElement variable) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        variable,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Library(LibraryElement library) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        library,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_LocalVariable(LocalVariableElement variable) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(variable, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.add(
        variable,
        IndexConstants.IS_READ_WRITTEN_BY,
        MatchKind.READ_WRITE);
    requestor.add(variable, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    requestor.add(variable, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>> _searchReferences_Method(MethodElement method) {
    _Requestor requestor = new _Requestor(_index);
    if (method is MethodMember) {
      method = (method as MethodMember).baseElement;
    }
    requestor.add(method, IndexConstants.IS_REFERENCED_BY, MatchKind.REFERENCE);
    requestor.add(method, IndexConstants.IS_INVOKED_BY, MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_Parameter(ParameterElement parameter) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(parameter, IndexConstants.IS_READ_BY, MatchKind.READ);
    requestor.add(
        parameter,
        IndexConstants.IS_READ_WRITTEN_BY,
        MatchKind.READ_WRITE);
    requestor.add(parameter, IndexConstants.IS_WRITTEN_BY, MatchKind.WRITE);
    requestor.add(
        parameter,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    requestor.add(
        parameter,
        IndexConstants.IS_INVOKED_BY,
        MatchKind.INVOCATION);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_PropertyAccessor(PropertyAccessorElement accessor) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        accessor,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return requestor.merge();
  }

  Future<List<SearchMatch>>
      _searchReferences_TypeParameter(TypeParameterElement typeParameter) {
    _Requestor requestor = new _Requestor(_index);
    requestor.add(
        typeParameter,
        IndexConstants.IS_REFERENCED_BY,
        MatchKind.REFERENCE);
    return requestor.merge();
  }
}


class _Requestor {
  final List<Future<List<SearchMatch>>> futures = <Future<List<SearchMatch>>>[];
  final Index index;

  _Requestor(this.index);

  void add(Element element, Relationship relationship, MatchKind kind) {
    Future relationsFuture = index.getRelationships(element, relationship);
    Future matchesFuture = relationsFuture.then((List<Location> locations) {
      List<SearchMatch> matches = <SearchMatch>[];
      for (Location location in locations) {
        matches.add(
            new SearchMatch(
                kind,
                location.element,
                new SourceRange(location.offset, location.length),
                location.isResolved,
                location.isQualified));
      }
      return matches;
    });
    futures.add(matchesFuture);
  }

  Future<List<SearchMatch>> merge() {
    return Future.wait(futures).then((List<List<SearchMatch>> matchesList) {
      return matchesList.expand((matches) => matches).toList();
    });
  }
}
