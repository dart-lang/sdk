// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

extension ElementExtension on Element {
  /// Return `true` if this element is an instance member.
  ///
  /// Only [MethodElement]s and [PropertyAccessorElement]s are supported.
  /// We intentionally exclude [ConstructorElement]s - they can only be
  /// invoked in instance creation expressions, and [FieldElement]s - they
  /// cannot be invoked directly and are always accessed using corresponding
  /// [PropertyAccessorElement]s.
  bool get isInstanceMember {
    var this_ = this;
    var enclosing = this_.enclosingElement;
    if (enclosing is ClassElement || enclosing is ExtensionElement) {
      return this_ is MethodElement && !this_.isStatic ||
          this_ is PropertyAccessorElement && !this_.isStatic;
    }
    return false;
  }

  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@doNotStore`
  /// annotation.
  bool get hasOrInheritsDoNotStore {
    if (hasDoNotStore) {
      return true;
    }
    var ancestor = enclosingElement;
    if (ancestor is ClassElement || ancestor is ExtensionElement) {
      if (ancestor.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    }
    return ancestor is CompilationUnitElement &&
        ancestor.enclosingElement.hasDoNotStore;
  }
}

extension ParameterElementExtensions on ParameterElement {
  /// Return [ParameterElement] with the specified properties replaced.
  ParameterElement copyWith({DartType type, ParameterKind kind}) {
    return ParameterElementImpl.synthetic(
      name,
      type ?? this.type,
      // ignore: deprecated_member_use_from_same_package
      kind ?? parameterKind,
    )..isExplicitlyCovariant = isCovariant;
  }
}
