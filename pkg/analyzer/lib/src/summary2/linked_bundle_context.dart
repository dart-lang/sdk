// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/linked_unit_context.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// The context of a linked bundle, with shared references.
class LinkedBundleContext {
  final LinkedElementFactory elementFactory;
  final LinkedNodeBundle _bundle;
  final List<Reference> _references;
  final Map<String, LinkedLibraryContext> libraryMap = {};

  LinkedBundleContext(this.elementFactory, this._bundle)
      : _references = List<Reference>(_bundle.references.name.length) {
    for (var library in _bundle.libraries) {
      var libraryContext = LinkedLibraryContext(library.uriStr, this, library);
      libraryMap[library.uriStr] = libraryContext;

      var units = library.units;
      for (var unitIndex = 0; unitIndex < units.length; ++unitIndex) {
        var unit = units[unitIndex];
        var unitContext = LinkedUnitContext(
          this,
          libraryContext,
          unitIndex,
          unit.uriStr,
          unit,
        );
        libraryContext.units.add(unitContext);
      }
    }
  }

  LinkedBundleContext.forAst(this.elementFactory, this._references)
      : _bundle = null;

  LinkedLibraryContext addLinkingLibrary(String uriStr,
      LinkedNodeLibraryBuilder data, Map<String, CompilationUnit> unitMap) {
    var uriStr = data.uriStr;
    var libraryContext = LinkedLibraryContext(uriStr, this, data);
    libraryMap[uriStr] = libraryContext;

    var uriUriStrList = unitMap.keys.toList();
    for (var unitIndex = 0; unitIndex < uriUriStrList.length; ++unitIndex) {
      var unitUriStr = uriUriStrList[unitIndex];
      var unit = unitMap[unitUriStr];
      var unitContext = LinkedUnitContext(
        this,
        libraryContext,
        unitIndex,
        unitUriStr,
        null,
        unit: unit,
      );
      libraryContext.units.add(unitContext);
    }
    return libraryContext;
  }

  T elementOfIndex<T extends Element>(int index) {
    var reference = referenceOfIndex(index);
    return elementFactory.elementOfReference(reference);
  }

  List<T> elementsOfIndexes<T extends Element>(List<int> indexList) {
    var result = List<T>(indexList.length);
    for (var i = 0; i < indexList.length; ++i) {
      var index = indexList[i];
      result[i] = elementOfIndex(index);
    }
    return result;
  }

  InterfaceType getInterfaceType(LinkedNodeType linkedType) {
    var type = getType(linkedType);
    if (type is InterfaceType && !type.element.isEnum) {
      return type;
    }
    return null;
  }

  DartType getType(LinkedNodeType linkedType) {
    var kind = linkedType.kind;
    if (kind == LinkedNodeTypeKind.dynamic_) {
      return DynamicTypeImpl.instance;
    } else if (kind == LinkedNodeTypeKind.genericTypeAlias) {
      var reference = referenceOfIndex(linkedType.genericTypeAliasReference);
      return GenericTypeAliasElementImpl.typeAfterSubstitution(
        elementFactory.elementOfReference(reference),
        linkedType.genericTypeAliasTypeArguments.map(getType).toList(),
      );
    } else if (kind == LinkedNodeTypeKind.function) {
      var returnType = getType(linkedType.functionReturnType);
      var formalParameters = linkedType.functionFormalParameters.map((p) {
        return ParameterElementImpl.synthetic(
          p.name,
          getType(p.type),
          _formalParameterKind(p.kind),
        );
      }).toList();
      return FunctionElementImpl.synthetic(formalParameters, returnType).type;
    } else if (kind == LinkedNodeTypeKind.interface) {
      var reference = referenceOfIndex(linkedType.interfaceClass);
      Element element = elementFactory.elementOfReference(reference);
      return InterfaceTypeImpl.explicit(
        element,
        linkedType.interfaceTypeArguments.map(getType).toList(),
      );
    } else if (kind == LinkedNodeTypeKind.typeParameter) {
      var reference = referenceOfIndex(linkedType.typeParameterParameter);
      Element element = elementFactory.elementOfReference(reference);
      return TypeParameterTypeImpl(element);
    } else if (kind == LinkedNodeTypeKind.void_) {
      return VoidTypeImpl.instance;
    } else {
      throw UnimplementedError('$kind');
    }
  }

  Reference referenceOfIndex(int index) {
    var reference = _references[index];
    if (reference != null) return reference;

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var parentIndex = _bundle.references.parent[index];
    var parent = referenceOfIndex(parentIndex);

    var name = _bundle.references.name[index];
    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }

  ParameterKind _formalParameterKind(LinkedNodeFormalParameterKind kind) {
    if (kind == LinkedNodeFormalParameterKind.optionalNamed) {
      return ParameterKind.NAMED;
    }
    if (kind == LinkedNodeFormalParameterKind.optionalPositional) {
      return ParameterKind.POSITIONAL;
    }
    return ParameterKind.REQUIRED;
  }
}

class LinkedLibraryContext {
  final String uriStr;
  final LinkedBundleContext context;
  final LinkedNodeLibrary node;
  final List<LinkedUnitContext> units = [];

  LinkedLibraryContext(this.uriStr, this.context, this.node);

  LinkedUnitContext get definingUnit => units.first;
}
