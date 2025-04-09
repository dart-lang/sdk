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
      for (var topElement in library.children2) {
        switch (topElement) {
          case InstanceElementImpl2():
            for (var field in topElement.fields2) {
              if (!field.isSynthetic || field.isEnumValues) {
                var result = _hasTypeParameterReference(topElement, field.type);
                field.firstFragment.hasEnclosingTypeParameterReference = result;
                field.getter2?.firstFragment
                    .hasEnclosingTypeParameterReference = result;
                field.setter2?.firstFragment
                    .hasEnclosingTypeParameterReference = result;
              }
            }

            var accessors = [
              ...topElement.getters2,
              ...topElement.setters2,
            ];
            for (var propertyAccessor in accessors) {
              if (!propertyAccessor.isSynthetic) {
                var result = _hasTypeParameterReference(
                    topElement, propertyAccessor.type);
                propertyAccessor
                    .firstFragment.hasEnclosingTypeParameterReference = result;
                if (propertyAccessor.variable3 case FieldElementImpl2 field) {
                  field.firstFragment.hasEnclosingTypeParameterReference =
                      result;
                }
              }
            }

            for (var method in topElement.methods2) {
              method.firstFragment.hasEnclosingTypeParameterReference =
                  _hasTypeParameterReference(topElement, method.type);
            }
          case PropertyAccessorElementImpl2():
            // Top-level accessors don't have type parameters.
            if (!topElement.isSynthetic) {
              topElement.firstFragment.hasEnclosingTypeParameterReference =
                  false;
            }
          case TopLevelVariableElementImpl2():
            // Top-level variables dont have type parameters.
            if (!topElement.isSynthetic) {
              topElement.getter2?.firstFragment
                  .hasEnclosingTypeParameterReference = false;
              topElement.setter2?.firstFragment
                  .hasEnclosingTypeParameterReference = false;
            }
        }
      }
    }
  }

  static bool _hasTypeParameterReference(
    InstanceElementImpl2 instanceElement,
    DartType type,
  ) {
    var visitor = _ReferencesTypeParameterVisitor(instanceElement);
    type.accept(visitor);
    return visitor.result;
  }
}

class _ReferencesTypeParameterVisitor extends RecursiveTypeVisitor {
  final InstanceElementImpl2 instanceElement;
  bool result = false;

  _ReferencesTypeParameterVisitor(this.instanceElement)
      : super(includeTypeAliasArguments: true);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    if (type.element3.enclosingElement2 == instanceElement) {
      result = true;
    }
    return true;
  }
}
