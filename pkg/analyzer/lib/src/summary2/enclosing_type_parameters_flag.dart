// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Computes precise values for `hasEnclosingTypeParameterReference`.
///
/// Executable and field elements are created with this flag set conservatively
/// to `true`. During linking, member signatures can still change due to type
/// inference, overridden member inference, and other resolution steps.
///
/// Premature `false` would cause member substitution return the base
/// declaration even if the final signature later contains a type parameter of
/// the enclosing class.
///
/// For example:
///
///     abstract class A<T> {
///       T foo();
///     }
///
///     class C<T> implements A<T> {
///       foo() => throw UnimplementedError();
///     }
///
/// Instance member override inference gives `C.foo` return type `T`. Lookup
/// through the instantiated type `C<int>` must therefore use a substituted
/// member whose return type is `int`. If this flag were set to `false` before
/// inference finished, member substitution could return the base declaration
/// instead, leaving the lookup with the unsubstituted return type `T`.
///
/// This pass runs after those signatures are finalized and replaces the
/// conservative value with an exact one before summary writing. Until this
/// point, extra substituted member wrappers are acceptable linking-time churn.
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
              if (instanceElement is InterfaceElementImpl)
                ...instanceElement.constructors,
              ...instanceElement.getters,
              ...instanceElement.setters,
              ...instanceElement.methods,
            ];
            for (var executable in executables) {
              var result = hasTypeParameterReference(executable.type);
              executable.hasEnclosingTypeParameterReference = result;
            }
          case PropertyAccessorElementImpl():
            // Top-level accessors don't have enclosing type parameters.
            topElement.hasEnclosingTypeParameterReference = false;
          case TopLevelFunctionElementImpl():
            // Top-level functions have no enclosing type parameters.
            topElement.hasEnclosingTypeParameterReference = false;
          case TopLevelVariableElementImpl():
            // Top-level variables have no enclosing type parameters.
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
