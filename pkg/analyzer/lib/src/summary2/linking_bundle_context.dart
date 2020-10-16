// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
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

  final _TypeParameterIndexer typeParameterIndexer = _TypeParameterIndexer();

  LinkingBundleContext(this.dynamicReference);

  /// We need indexes for references during linking, but once we are done,
  /// we must clear indexes to make references ready for linking a next bundle.
  void clearIndexes() {
    for (var reference in references) {
      if (reference != null) {
        reference.index = null;
      }
    }
  }

  int indexOfElement(Element element) {
    if (element == null) return 0;
    if (element is MultiplyDefinedElement) return 0;
    assert(element is! Member);

    if (element is TypeParameterElement) {
      return typeParameterIndexer[element] << 1 | 0x1;
    }

    if (identical(element, DynamicElementImpl.instance)) {
      return indexOfReference(dynamicReference) << 1;
    }

    var reference = (element as ElementImpl).reference;
    return indexOfReference(reference) << 1;
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

  LinkedNodeTypeBuilder writeType(DartType type) {
    if (type == null) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.null_,
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
    } else if (type is NeverType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.never,
        nullabilitySuffix: _nullabilitySuffix(type),
      );
    } else if (type is TypeParameterType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.typeParameter,
        nullabilitySuffix: _nullabilitySuffix(type),
        typeParameterId: indexOfElement(type.element),
      );
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
    typeParameterIndexer.enter(typeParameters);

    for (var i = 0; i < typeParameters.length; ++i) {
      var typeParameter = typeParameters[i];
      typeParameterBuilders.add(
        LinkedNodeTypeTypeParameterBuilder(
          name: typeParameter.name,
          bound: writeType(typeParameter.bound),
        ),
      );
    }

    Element typedefElement;
    List<DartType> typedefTypeArguments = const <DartType>[];
    if (type.element is FunctionTypeAliasElement) {
      typedefElement = type.element;
      typedefTypeArguments = type.typeArguments;
    }
    // TODO(scheglov) Cleanup to always use FunctionTypeAliasElement.
    if (type.element is GenericFunctionTypeElement &&
        type.element.enclosingElement is FunctionTypeAliasElement) {
      typedefElement = type.element.enclosingElement;
      typedefTypeArguments = type.typeArguments;
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
      functionTypedef: indexOfElement(typedefElement),
      functionTypedefTypeArguments:
          typedefTypeArguments.map(writeType).toList(),
      nullabilitySuffix: _nullabilitySuffix(type),
    );

    typeParameterIndexer.exit(typeParameters);

    return result;
  }

  static EntityRefNullabilitySuffix _nullabilitySuffix(DartType type) {
    var nullabilitySuffix = type.nullabilitySuffix;
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

class _TypeParameterIndexer {
  final Map<TypeParameterElement, int> _index = Map.identity();
  int _stackHeight = 0;

  int operator [](TypeParameterElement parameter) {
    return _index[parameter] ??
        (throw ArgumentError('Type parameter $parameter is not indexed'));
  }

  void enter(List<TypeParameterElement> typeParameters) {
    for (var i = 0; i < typeParameters.length; i++) {
      var parameter = typeParameters[i];
      _index[parameter] = _stackHeight++;
    }
  }

  void exit(List<TypeParameterElement> typeParameters) {
    _stackHeight -= typeParameters.length;
    for (var i = 0; i < typeParameters.length; i++) {
      _index.remove(typeParameters[i]);
    }
  }
}
