// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';

class EnclosingTypeParameterReferenceFlag {
  final Linker _linker;

  EnclosingTypeParameterReferenceFlag(this._linker);

  void perform() {
    for (var builder in _linker.builders.values) {
      var library = builder.element;
      for (var topElement in library.children) {
        switch (topElement) {
          case InstanceElementImpl():
            for (var field in topElement.fields) {
              if (!field.isSynthetic || field.isEnumValues) {
                var result = _hasTypeParameterReference(topElement, field.type);
                field.hasEnclosingTypeParameterReference = result;
                field.getter?.hasEnclosingTypeParameterReference = result;
                field.setter?.hasEnclosingTypeParameterReference = result;
              }
            }

            var accessors = [...topElement.getters, ...topElement.setters];
            for (var propertyAccessor in accessors) {
              if (!propertyAccessor.isSynthetic) {
                var result = _hasTypeParameterReference(
                  topElement,
                  propertyAccessor.type,
                );
                propertyAccessor.hasEnclosingTypeParameterReference = result;
                if (propertyAccessor.variable case FieldElementImpl field) {
                  field.hasEnclosingTypeParameterReference = result;
                }
              }
            }

            for (var method in topElement.methods) {
              method.hasEnclosingTypeParameterReference =
                  _hasTypeParameterReference(topElement, method.type);
            }
          case PropertyAccessorElementImpl():
            // Top-level accessors don't have type parameters.
            if (!topElement.isSynthetic) {
              topElement.hasEnclosingTypeParameterReference = false;
            }
          case TopLevelVariableElementImpl():
            // Top-level variables dont have type parameters.
            if (!topElement.isSynthetic) {
              topElement.getter?.hasEnclosingTypeParameterReference = false;
              topElement.setter?.hasEnclosingTypeParameterReference = false;
            }
        }
      }
    }
  }

  static bool _hasTypeParameterReference(
    InstanceElementImpl instanceElement,
    DartType type,
  ) {
    var visitor = _ReferencesTypeParameterVisitor(instanceElement);
    type.accept(visitor);
    return visitor.result;
  }
}

class _ReferencesTypeParameterVisitor extends RecursiveTypeVisitor {
  final InstanceElementImpl instanceElement;
  bool result = false;

  _ReferencesTypeParameterVisitor(this.instanceElement)
    : super(includeTypeAliasArguments: true);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    if (type.element.enclosingElement == instanceElement) {
      result = true;
    }
    return true;
  }
}
