// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
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

  LinkingBundleContext(this.dynamicReference);

  int indexOfReference(Reference reference) {
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
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.function,
        functionFormalParameters: _getReferences(type.parameters),
        functionReturnType: writeType(type.returnType),
        functionTypeParameters: _getReferences(type.typeParameters),
      );
    } else if (type is InterfaceType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.interface,
        interfaceClass: _getReferenceIndex(type.element),
        interfaceTypeArguments: type.typeArguments.map(writeType).toList(),
      );
    } else if (type is TypeParameterType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.typeParameter,
        typeParameterParameter: _getReferenceIndex(type.element),
      );
    } else if (type is VoidType) {
      return LinkedNodeTypeBuilder(
        kind: LinkedNodeTypeKind.void_,
      );
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
  }

  int _getReferenceIndex(Element element) {
    if (element == null) return 0;

    var reference = (element as ElementImpl).reference;
    return indexOfReference(reference);
  }

  List<int> _getReferences(List<Element> elements) {
    var result = List<int>(elements.length);
    for (var i = 0; i < elements.length; ++i) {
      var element = elements[i];
      result[i] = _getReferenceIndex(element);
    }
    return result;
  }
}
