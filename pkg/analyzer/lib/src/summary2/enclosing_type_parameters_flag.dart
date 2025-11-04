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
          case InstanceElementImpl instanceElement:
            bool hasTypeParameterReference(DartType type) {
              var visitor = _ReferencesTypeParameterVisitor(instanceElement);
              type.accept(visitor);
              return visitor.result;
            }

            for (var field in instanceElement.fields) {
              var result = hasTypeParameterReference(field.type);
              field.hasEnclosingTypeParameterReference = result;
            }

            var executables = [
              ...instanceElement.getters,
              ...instanceElement.setters,
              ...instanceElement.methods,
            ];
            for (var executable in executables) {
              var result = hasTypeParameterReference(executable.type);
              executable.hasEnclosingTypeParameterReference = result;
            }
          case PropertyAccessorElementImpl():
            // Top-level accessors don't have type parameters.
            topElement.hasEnclosingTypeParameterReference = false;
          case TopLevelVariableElementImpl():
            // Top-level variables dont have type parameters.
            topElement.getter?.hasEnclosingTypeParameterReference = false;
            topElement.setter?.hasEnclosingTypeParameterReference = false;
        }
      }
    }
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
