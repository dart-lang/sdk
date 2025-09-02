// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta_meta.dart';

extension DartTypeExtension on DartType {
  bool get isExtensionType {
    return element is ExtensionTypeElement;
  }
}

extension Element2Extension on Element {
  TypeImpl? get firstParameterType {
    var self = this;
    if (self is InternalMethodElement) {
      return self.formalParameters.firstOrNull?.type;
    }
    return null;
  }

  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@doNotStore`
  /// annotation.
  bool get hasOrInheritsDoNotStore {
    if (metadata.hasDoNotStore) {
      return true;
    }

    var ancestor = enclosingElement;
    if (ancestor is InterfaceElement) {
      if (ancestor.metadata.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    } else if (ancestor is ExtensionElement) {
      if (ancestor.metadata.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement;
    }

    return ancestor is LibraryElement && ancestor.metadata.hasDoNotStore;
  }

  /// Return `true` if this element is an instance member of a class or mixin.
  ///
  /// Only [MethodElement]s, [GetterElement]s, and  [SetterElement]s are
  /// supported.
  ///
  /// We intentionally exclude [ConstructorElement]s - they can only be
  /// invoked in instance creation expressions, and [FieldElement]s - they
  /// cannot be invoked directly and are always accessed using corresponding
  /// [GetterElement]s or [SetterElement]s.
  bool get isInstanceMember {
    assert(
      this is! PropertyInducingElement,
      'Check the GetterElement or SetterElement instead',
    );
    var this_ = this;
    var enclosing = this_.enclosingElement;
    if (enclosing is InterfaceElement) {
      return this_ is MethodElement && !this_.isStatic ||
          this_ is GetterElement && !this_.isStatic ||
          this_ is SetterElement && !this_.isStatic;
    }
    return false;
  }

  /// Whether the use of this element is deprecated.
  bool get isUseDeprecated {
    var element = this;

    var metadata = (element is PropertyAccessorElement && element.isSynthetic)
        ? element.variable.metadata
        : element.metadata;

    var annotations = metadata.annotations.where((e) => e.isDeprecated);
    return annotations.any((annotation) {
      var value = annotation.computeConstantValue();
      var kindValue = value?.getField('_kind');
      if (kindValue == null) return true;
      var kind = kindValue.getField('_name')?.toStringValue();
      return kind == 'use';
    });
  }

  /// Whether this element is a wildcard variable.
  bool get isWildcardVariable {
    return name == '_' &&
        (this is LocalFunctionElement ||
            this is LocalVariableElement ||
            this is PrefixElement ||
            this is TypeParameterElement ||
            (this is FormalParameterElement &&
                this is! FieldFormalParameterElement &&
                this is! SuperFormalParameterElement)) &&
        library.hasWildcardVariablesFeatureEnabled;
  }

  /// Whether this Element is annotated with a `Deprecated` annotation with a
  /// `_DeprecationKind` of [kind].
  bool isDeprecatedWithKind(String kind) => metadata.annotations
      .where((e) => e.isDeprecated)
      .any((e) => e.deprecationKind == kind);
}

extension Element2OrNullExtension on Element? {
  /// Return true if this element is a wildcard variable.
  bool get isWildcardVariable {
    return this?.isWildcardVariable ?? false;
  }
}

extension ElementAnnotationExtension on ElementAnnotation {
  static final Map<String, TargetKind> _targetKindsByName = {
    for (var kind in TargetKind.values) kind.name: kind,
  };

  /// The kind of deprecation, if this annotation is a `Deprecated` annotation.
  ///
  /// `null` is returned if this is not a `Deprecated` annotation.
  String? get deprecationKind {
    if (!isDeprecated) return null;
    return computeConstantValue()
            ?.getField('_kind')
            ?.getField('_name')
            ?.toStringValue() ??
        // For SDKs where the `Deprecated` class does not have a deprecation kind.
        'use';
  }

  /// Return the target kinds defined for this [ElementAnnotation].
  Set<TargetKind> get targetKinds {
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
      return const <TargetKind>{};
    }
    for (var annotation in interfaceElement.metadata.annotations) {
      if (annotation.isTarget) {
        var value = annotation.computeConstantValue();
        if (value == null) {
          return const <TargetKind>{};
        }

        var annotationKinds = value.getField('kinds')?.toSetValue();
        if (annotationKinds == null) {
          return const <TargetKind>{};
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
    return const <TargetKind>{};
  }
}

extension ExecutableElement2Extension on ExecutableElement {
  /// Whether the enclosing element is the class `Object`.
  bool get isObjectMember {
    var enclosing = enclosingElement;
    return enclosing is ClassElement && enclosing.isDartCoreObject;
  }
}

extension FormalParameterElementMixinExtension
    on InternalFormalParameterElement {
  /// Returns [FormalParameterElementImpl] with the specified properties
  /// replaced.
  FormalParameterElementImpl copyWith({
    TypeImpl? type,
    ParameterKind? kind,
    bool? isCovariant,
  }) {
    var element = FormalParameterElementImpl.synthetic(
      name,
      type ?? this.type,
      kind ?? parameterKind,
    );
    element.firstFragment.isExplicitlyCovariant =
        isCovariant ?? this.isCovariant;
    return element;
  }
}

extension InterfaceTypeExtension on InterfaceType {
  bool get isDartCoreObjectNone {
    return isDartCoreObject && nullabilitySuffix == NullabilitySuffix.none;
  }
}

extension LibraryExtension2 on LibraryElement? {
  bool get hasWildcardVariablesFeatureEnabled =>
      this?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;
}

extension RecordTypeExtension on RecordType {
  /// A regular expression used to match positional field names.
  static final RegExp _positionalName = RegExp(r'^\$[1-9]\d*$');

  List<RecordTypeField> get fields {
    return [...positionalFields, ...namedFields];
  }

  /// The [name] is either an actual name like `foo` in `({int foo})`, or
  /// the name of a positional field like `$1` in `(int, String)`.
  RecordTypeFieldImpl? fieldByName(String name) {
    return namedField(name) ?? positionalField(name);
  }

  RecordTypeNamedFieldImpl? namedField(String name) {
    for (var field in namedFields) {
      if (field.name == name) {
        // TODO(paulberry): eliminate this cast by changing the extension to
        // only apply to `RecordTypeImpl`.
        return field as RecordTypeNamedFieldImpl;
      }
    }
    return null;
  }

  RecordTypePositionalFieldImpl? positionalField(String name) {
    var index = positionalFieldIndex(name);
    if (index != null && index < positionalFields.length) {
      // TODO(paulberry): eliminate this cast by changing the extension to only
      // apply to `RecordTypeImpl`.
      return positionalFields[index] as RecordTypePositionalFieldImpl;
    }
    return null;
  }

  /// Attempt to parse `$1`, `$2`, etc.
  static int? positionalFieldIndex(String name) {
    if (_positionalName.hasMatch(name)) {
      var positionString = name.substring(1);
      // Use `tryParse` instead of `parse`
      // even though the numeral matches the pattern `[1-9]\d*`,
      // to reject numerals too big to fit in an `int`.
      var position = int.tryParse(positionString);
      if (position != null) return position - 1;
    }
    return null;
  }
}

extension TypeParameterElementImplExtension on TypeParameterElementImpl {
  bool get isWildcardVariable {
    return name == '_' && library.hasWildcardVariablesFeatureEnabled;
  }
}
