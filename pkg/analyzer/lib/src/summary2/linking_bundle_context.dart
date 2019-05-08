// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary2/reference.dart';

class LinkingBundleContext {
  /// The `dynamic` class is declared in `dart:core`, but is not a class.
  /// Also, it is static, so we cannot set `reference` for it.
  /// So, we have to push it in a separate way.
  final Reference dynamicReference;

  /// References used in all libraries being linked.
  /// Element references in nodes are indexes in this list.
  final List<Reference> references = [null];

  /// Data about [references].
  final LinkedNodeReferencesBuilder referencesBuilder =
      LinkedNodeReferencesBuilder(
    parent: [0],
    name: [''],
  );

  final Map<TypeParameterElement, int> _typeParameters = Map.identity();
  int _nextSyntheticTypeParameterId = 0x10000;

  final Map<GenericFunctionTypeElement, int> _genericFunctionTypes =
      Map.identity();
  int _nextGenericFunctionTypeId = 1;

  LinkingBundleContext(this.dynamicReference);

  int idOfGenericFunctionType(GenericFunctionTypeElement element) {
    return _genericFunctionTypes[element];
  }

  int idOfTypeParameter(TypeParameterElement element) {
    return _typeParameters[element];
  }

  int indexOfElement(Element element) {
    if (element == null) return 0;
    assert(element is! Member);

    if (identical(element, DynamicElementImpl.instance)) {
      return indexOfReference(dynamicReference);
    }

    var reference = (element as ElementImpl).reference;
    return indexOfReference(reference);
  }

  int indexOfReference(Reference reference) {
    if (reference == null) return 0;
    if (reference.parent == null) return 0;
    if (reference.index != null) return reference.index;

    var parentIndex = indexOfReference(reference.parent);
    referencesBuilder.parent.add(parentIndex);
    referencesBuilder.name.add(reference.name);

    reference.index = references.length;
    references.add(reference);
    return reference.index;
  }

  int nextGenericFunctionTypeId() {
    return _nextGenericFunctionTypeId++;
  }

  LinkedNodeTypeBuilder writeType(DartType type) {
    if (type == null) return null;

    if (type.isBottom) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.bottom,
      );
    } else if (type.isDynamic) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.dynamic_,
      );
    } else if (type is FunctionType) {
      return _writeFunctionType(type);
    } else if (type is InterfaceType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: indexOfElement(type.element),
        interfaceTypeArguments: type.typeArguments.map(writeType).toList(),
        nullabilitySuffix: _nullabilitySuffix(type),
      );
    } else if (type is TypeParameterType) {
      TypeParameterElementImpl element = type.element;
      var id = _typeParameters[element];
      if (id != null) {
        return LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.typeParameter,
          nullabilitySuffix: _nullabilitySuffix(type),
          typeParameterId: id,
        );
      } else {
        var index = indexOfElement(element);
        return LinkedNodeTypeBuilder(
          kind: LinkedNodeTypeKind.typeParameter,
          nullabilitySuffix: _nullabilitySuffix(type),
          typeParameterElement: index,
        );
      }
    } else if (type is VoidType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.void_,
      );
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  LinkedNodeFormalParameterKind _formalParameterKind(ParameterElement p) {
    if (p.isRequiredPositional) {
      return LinkedNodeFormalParameterKind.requiredPositional;
    } else if (p.isRequiredNamed) {
      return LinkedNodeFormalParameterKind.requiredNamed;
    } else if (p.isOptionalPositional) {
      return LinkedNodeFormalParameterKind.optionalPositional;
    } else if (p.isOptionalNamed) {
      return LinkedNodeFormalParameterKind.optionalNamed;
    } else {
      throw StateError('Unexpected parameter kind: $p');
    }
  }

  FunctionType _toSyntheticFunctionType(FunctionType type) {
    var typeParameters = type.typeFormals;

    if (typeParameters.isEmpty) return type;

    var onlySyntheticTypeParameters = typeParameters.every((e) {
      return e is TypeParameterElementImpl && e.linkedNode == null;
    });
    if (onlySyntheticTypeParameters) return type;

    var parameters = getFreshTypeParameters(typeParameters);
    return parameters.applyToFunctionType(type);
  }

  LinkedNodeTypeBuilder _writeFunctionType(FunctionType type) {
    type = _toSyntheticFunctionType(type);

    var typeParameterBuilders = <LinkedNodeTypeTypeParameterBuilder>[];

    var typeParameters = type.typeFormals;
    for (var i = 0; i < typeParameters.length; ++i) {
      var typeParameter = typeParameters[i];
      _typeParameters[typeParameter] = _nextSyntheticTypeParameterId++;
      typeParameterBuilders.add(
        LinkedNodeTypeTypeParameterBuilder(name: typeParameter.name),
      );
    }

    for (var i = 0; i < typeParameters.length; ++i) {
      var typeParameter = typeParameters[i];
      typeParameterBuilders[i].bound = writeType(typeParameter.bound);
    }

    var result = LinkedNodeTypeBuilder(
      kind: LinkedNodeTypeKind.function,
      functionFormalParameters: type.parameters
          .map((p) => LinkedNodeTypeFormalParameterBuilder(
                kind: _formalParameterKind(p),
                name: p.name,
                type: writeType(p.type),
              ))
          .toList(),
      functionReturnType: writeType(type.returnType),
      functionTypeParameters: typeParameterBuilders,
      nullabilitySuffix: _nullabilitySuffix(type),
    );

    for (var typeParameter in typeParameters) {
      _typeParameters.remove(typeParameter);
      --_nextSyntheticTypeParameterId;
    }

    return result;
  }

  static EntityRefNullabilitySuffix _nullabilitySuffix(DartType type) {
    var nullabilitySuffix = (type as TypeImpl).nullabilitySuffix;
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return EntityRefNullabilitySuffix.question;
      case NullabilitySuffix.star:
        return EntityRefNullabilitySuffix.starOrIrrelevant;
      case NullabilitySuffix.none:
        return EntityRefNullabilitySuffix.none;
      default:
        throw StateError('$nullabilitySuffix');
    }
  }
}
