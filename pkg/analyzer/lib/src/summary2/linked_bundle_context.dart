// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/linked_element_factory.dart';
import 'package:analyzer/src/summary2/reference.dart';

/// The context of a linked bundle, with shared references.
class LinkedBundleContext {
  final LinkedElementFactory elementFactory;
  final LinkedNodeReferences referencesData;
  final List<Reference> _references;

  LinkedBundleContext(this.elementFactory, this.referencesData)
      : _references = List<Reference>.filled(referencesData.name.length, null,
            growable: true);

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
    } else if (kind == LinkedNodeTypeKind.function) {
      var returnType = getType(linkedType.functionReturnType);
      var typeParameters = linkedType.functionTypeParameters
          .map(referenceOfIndex)
          .map(elementFactory.elementOfReference)
          .cast<TypeParameterElement>()
          .toList();
      var formalParameters = linkedType.functionFormalParameters
          .map(referenceOfIndex)
          .map(elementFactory.elementOfReference)
          .cast<ParameterElement>()
          .toList();
      // TODO(scheglov) Rework this to purely synthetic types.
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
    // When we are linking a bundle, we add new references.
    // So, grow the list of references when we have data for them.
    if (index >= _references.length) {
      if (referencesData.name.length > _references.length) {
        _references.length = referencesData.name.length;
      }
    }

    var reference = _references[index];
    if (reference != null) return reference;

    if (index == 0) {
      reference = elementFactory.rootReference;
      _references[index] = reference;
      return reference;
    }

    var parentIndex = referencesData.parent[index];
    var parent = referenceOfIndex(parentIndex);

    var name = referencesData.name[index];
    reference = parent.getChild(name);
    _references[index] = reference;

    return reference;
  }
}
