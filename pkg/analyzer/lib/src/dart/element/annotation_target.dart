// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta_meta.dart';

const Set<TargetKind> _overrideTargetKinds = {
  TargetKind.field,
  TargetKind.getter,
  TargetKind.method,
  TargetKind.setter,
};

final Map<String, TargetKind> _targetKindsByName = {
  for (var kind in TargetKind.values) kind.name: kind,
};

bool? isAnnotationValidAtElement(
  ElementAnnotation annotation,
  Element element,
) {
  var kinds = annotation.targetKinds;
  if (kinds == null) {
    return null;
  }
  return isValidAnnotationTargetElement(element, kinds);
}

bool isValidAnnotationTargetElement(Element element, Set<TargetKind> kinds) {
  if (kinds.contains(TargetKind.overridableMember) &&
      _isOverridableMember(element)) {
    return true;
  }

  return switch (element) {
    ClassElement() =>
      kinds.contains(TargetKind.classType) || kinds.contains(TargetKind.type),
    ConstructorElement() => kinds.contains(TargetKind.constructor),
    EnumElement() =>
      kinds.contains(TargetKind.enumType) || kinds.contains(TargetKind.type),
    ExtensionElement() => kinds.contains(TargetKind.extension),
    ExtensionTypeElement() => kinds.contains(TargetKind.extensionType),
    FieldElement(:var isEnumConstant) =>
      isEnumConstant
          ? kinds.contains(TargetKind.enumValue)
          : kinds.contains(TargetKind.field),
    FormalParameterElement(:var isOptional) =>
      kinds.contains(TargetKind.parameter) ||
          isOptional && kinds.contains(TargetKind.optionalParameter),
    GetterElement() => kinds.contains(TargetKind.getter),
    LibraryElement() => kinds.contains(TargetKind.library),
    LocalFunctionElement() ||
    TopLevelFunctionElement() => kinds.contains(TargetKind.function),
    MethodElement() => kinds.contains(TargetKind.method),
    MixinElement() =>
      kinds.contains(TargetKind.mixinType) || kinds.contains(TargetKind.type),
    SetterElement() => kinds.contains(TargetKind.setter),
    TopLevelVariableElement() => kinds.contains(TargetKind.topLevelVariable),
    TypeAliasElement() =>
      kinds.contains(TargetKind.typedefType) || kinds.contains(TargetKind.type),
    TypeParameterElement() => kinds.contains(TargetKind.typeParameter),
    _ => false,
  };
}

bool _isOverridableMember(Element element) {
  if (element case FieldElement(:var isStatic, :var enclosingElement)) {
    return !isStatic && _isOverridableMemberContainer(enclosingElement);
  }

  if (element case GetterElement(:var isStatic, :var enclosingElement)) {
    return !isStatic && _isOverridableMemberContainer(enclosingElement);
  }

  if (element case MethodElement(:var isStatic, :var enclosingElement)) {
    return !isStatic && _isOverridableMemberContainer(enclosingElement);
  }

  if (element case SetterElement(:var isStatic, :var enclosingElement)) {
    return !isStatic && _isOverridableMemberContainer(enclosingElement);
  }

  return false;
}

bool _isOverridableMemberContainer(Element? element) {
  return element is ClassElement ||
      element is ExtensionTypeElement ||
      element is MixinElement;
}

extension ElementAnnotationTargetKinds on ElementAnnotation {
  /// Return the known target kinds for this annotation.
  ///
  /// Returns `null` if there is no known set of target kinds.
  Set<TargetKind>? get targetKinds {
    if (isOverride) {
      return _overrideTargetKinds;
    }

    var element = this.element;
    InterfaceElement? interfaceElement;
    if (element is GetterElement) {
      var type = element.returnType;
      if (type is InterfaceType) {
        interfaceElement = type.element;
      }
    } else if (element is ConstructorElement) {
      interfaceElement = element.enclosingElement;
    }

    if (interfaceElement == null) {
      return null;
    }

    for (var annotation in interfaceElement.metadata.annotations) {
      if (annotation.isTarget) {
        var value = annotation.computeConstantValue();
        if (value == null) {
          return null;
        }

        var annotationKinds = value.getField('kinds')?.toSetValue();
        if (annotationKinds == null) {
          return null;
        }

        return annotationKinds
            .map((e) {
              // Support class-based and enum-based target kind implementations.
              var field = e.getField('name') ?? e.getField('_name');
              return field?.toStringValue();
            })
            .map((name) => _targetKindsByName[name])
            .nonNulls
            .toSet();
      }
    }

    return null;
  }
}
