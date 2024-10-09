// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta_meta.dart';

extension DartTypeExtension on DartType {
  bool get isExtensionType {
    return element is ExtensionTypeElement;
  }
}

extension Element2Extension on Element2 {
  /// Whether this element is a wildcard variable.
  bool get isWildcardVariable {
    return name == '_' &&
        (this is LocalVariableElement2 ||
            this is PrefixElement2 ||
            this is TypeParameterElement2 ||
            (this is FormalParameterElement &&
                this is! FieldFormalParameterElement2 &&
                this is! SuperFormalParameterElement2)) &&
        library2.hasWildcardVariablesFeatureEnabled2;
  }
}

extension ElementAnnotationExtensions on ElementAnnotation {
  static final Map<String, TargetKind> _targetKindsByName = {
    for (var kind in TargetKind.values) kind.name: kind,
  };

  /// Return the target kinds defined for this [ElementAnnotation].
  Set<TargetKind> get targetKinds {
    var element = this.element;
    InterfaceElement? interfaceElement;
    if (element is PropertyAccessorElement) {
      if (element.isGetter) {
        var type = element.returnType;
        if (type is InterfaceType) {
          interfaceElement = type.element;
        }
      }
    } else if (element is ConstructorElement) {
      interfaceElement = element.enclosingElement3.augmented.declaration;
    }
    if (interfaceElement == null) {
      return const <TargetKind>{};
    }
    for (var annotation in interfaceElement.metadata) {
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

extension ElementExtension on Element {
  /// If this element is an augmentation, returns the declaration.
  Element get augmentedDeclaration {
    if (this case InstanceElement self) {
      return self.augmented.declaration;
    }
    return this;
  }

  /// Return `true` if this element, the enclosing class (if there is one), or
  /// the enclosing library, has been annotated with the `@doNotStore`
  /// annotation.
  bool get hasOrInheritsDoNotStore {
    if (hasDoNotStore) {
      return true;
    }

    var ancestor = enclosingElement3;
    if (ancestor is InterfaceElement) {
      if (ancestor.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement3;
    } else if (ancestor is ExtensionElement) {
      if (ancestor.hasDoNotStore) {
        return true;
      }
      ancestor = ancestor.enclosingElement3;
    }

    return ancestor is CompilationUnitElement && ancestor.library.hasDoNotStore;
  }

  /// Return `true` if this element is an instance member of a class or mixin.
  ///
  /// Only [MethodElement]s and [PropertyAccessorElement]s are supported.
  /// We intentionally exclude [ConstructorElement]s - they can only be
  /// invoked in instance creation expressions, and [FieldElement]s - they
  /// cannot be invoked directly and are always accessed using corresponding
  /// [PropertyAccessorElement]s.
  bool get isInstanceMember {
    assert(this is! PropertyInducingElement,
        'Check the PropertyAccessorElement instead');
    var this_ = this;
    var enclosing = this_.enclosingElement3;
    if (enclosing is InterfaceElement) {
      return this_ is MethodElement && !this_.isStatic ||
          this_ is PropertyAccessorElement && !this_.isStatic;
    }
    return false;
  }

  /// Return true if this element is a wildcard variable.
  bool get isWildcardVariable {
    return name == '_' &&
        (this is LocalVariableElement ||
            this is PrefixElement ||
            this is TypeParameterElement ||
            (this is ParameterElement &&
                this is! FieldFormalParameterElement &&
                this is! SuperFormalParameterElement)) &&
        library.hasWildcardVariablesFeatureEnabled;
  }
}

extension ExecutableElementExtension on ExecutableElement {
  /// Whether the enclosing element is the class `Object`.
  bool get isObjectMember {
    var enclosing = enclosingElement3;
    return enclosing is ClassElement && enclosing.isDartCoreObject;
  }
}

extension ExecutableElementExtensionQuestion on ExecutableElement? {
  DartType? get firstParameterType {
    var self = this;
    if (self is MethodElement) {
      return self.parameters.firstOrNull?.type;
    }
    return null;
  }
}

extension InterfaceTypeExtension on InterfaceType {
  bool get isDartCoreObjectNone {
    return isDartCoreObject && nullabilitySuffix == NullabilitySuffix.none;
  }
}

extension LibraryExtension on LibraryElement? {
  bool get hasWildcardVariablesFeatureEnabled {
    var self = this;
    return self?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;
  }
}

extension LibraryExtension2 on LibraryElement2? {
  bool get hasWildcardVariablesFeatureEnabled2 =>
      this?.featureSet.isEnabled(Feature.wildcard_variables) ?? false;
}

extension ParameterElementExtensions on ParameterElement {
  /// Return [ParameterElement] with the specified properties replaced.
  ParameterElement copyWith({
    DartType? type,
    ParameterKind? kind,
    bool? isCovariant,
  }) {
    return ParameterElementImpl.synthetic(
      name,
      type ?? this.type,
      // ignore: deprecated_member_use_from_same_package
      kind ?? parameterKind,
    )..isExplicitlyCovariant = isCovariant ?? this.isCovariant;
  }
}

extension RecordTypeExtension on RecordType {
  /// A regular expression used to match positional field names.
  static final RegExp _positionalName = RegExp(r'^\$[1-9]\d*$');

  List<RecordTypeField> get fields {
    return [
      ...positionalFields,
      ...namedFields,
    ];
  }

  /// The [name] is either an actual name like `foo` in `({int foo})`, or
  /// the name of a positional field like `$1` in `(int, String)`.
  RecordTypeField? fieldByName(String name) {
    return namedField(name) ?? positionalField(name);
  }

  RecordTypeNamedField? namedField(String name) {
    for (var field in namedFields) {
      if (field.name == name) {
        return field;
      }
    }
    return null;
  }

  RecordTypePositionalField? positionalField(String name) {
    var index = positionalFieldIndex(name);
    if (index != null && index < positionalFields.length) {
      return positionalFields[index];
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
