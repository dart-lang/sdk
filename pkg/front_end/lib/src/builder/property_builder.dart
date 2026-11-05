// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/uri_offset.dart';
import 'builder.dart';
import 'member_builder.dart';

abstract class PropertyBuilder implements MemberBuilder {
  /// Returns `true` if this property builder has a constant field declaration.
  bool get hasConstField;

  /// Returns `true` if this property is declared by an enum element.
  bool get isEnumElement;

  /// Returns a [FieldQuality] enum value that describes what kind of field this
  /// property has, if any.
  FieldQuality get fieldQuality;

  /// Returns a [GetterQuality] enum value that describes what kind of getter
  /// this property has, if any.
  GetterQuality get getterQuality;

  /// Returns a [SetterQuality] enum value that describes what kind of setter
  /// this property has, if any.
  SetterQuality get setterQuality;

  /// Returns the [UriOffsetLength]  for the introductory declaration of the
  /// getter aspect, if any.
  UriOffsetLength? get getterUriOffset;

  /// Returns the [UriOffsetLength] for the introductory declaration of the
  /// setter aspect, if any.
  UriOffsetLength? get setterUriOffset;
}

/// Enum for the different ways a property can have a field aspect.
enum FieldQuality {
  /// A property without a field declaration.
  ///
  /// For instance an explicit getter or setter:
  ///
  ///     abstract class A {
  ///       int get getter; // Absent field quality.
  ///       void set setter(int _) {} // Absent field quality.
  ///     }
  Absent,

  /// A property with a non-abstract, non-external field declaration.
  ///
  /// For instance a final or non-final field declaration:
  ///
  ///     class A {
  ///       int? field; // Concrete field quality.
  ///       final int finalField = 42; // Concrete field quality.
  ///     }
  Concrete,

  /// A property with an external field declaration.
  ///
  /// For instance a final or non-final external field declaration:
  ///
  ///     class A {
  ///       external int? field; // External field quality.
  ///       external final int finalField; // External field quality.
  ///     }
  External,

  /// A property with an abstract field declaration.
  ///
  /// For instance a final or non-final abstract field declaration:
  ///
  ///     abstract class A {
  ///       abstract int? field; // Abstract field quality.
  ///       abstract final int finalField; // Abstract field quality.
  ///     }
  Abstract,
}

/// Enum for the different ways a property can have a getter aspect.
enum GetterQuality {
  /// A property without a getter declaration.
  ///
  /// For instance an explicit setter:
  ///
  ///     class A {
  ///       void set setter(int _) {} // Absent getter quality.
  ///     }
  Absent,

  /// A property with a non-abstract, non-external, explicit getter declaration.
  ///
  /// For instance an explicit getter:
  ///
  ///     class A {
  ///       int get getter => 42; // Concrete getter quality.
  ///     }
  Concrete,

  /// A property with an external explicit getter declaration.
  ///
  /// For instance:
  ///
  ///     class A {
  ///       external int get getter; // External getter quality.
  ///     }
  External,

  /// A property with an abstract explicit getter declaration.
  ///
  /// For instance:
  ///
  ///     abstract class A {
  ///       int get getter; // Abstract getter quality.
  ///     }
  Abstract,

  /// A property with a non-abstract, non-external implicit getter declaration.
  ///
  /// For instance a final or non-final field declaration:
  ///
  ///     class A {
  ///       int? field; // Implicit getter quality.
  ///       final int finalField = 42; // Implicit getter quality.
  ///     }
  Implicit,

  /// A property with an external implicit getter declaration.
  ///
  /// For instance a final or non-final external field declaration:
  ///
  ///     class A {
  ///       external int? field; // ImplicitExternal getter quality.
  ///       external final int finalField; // ImplicitExternal getter quality.
  ///     }
  ImplicitExternal,

  /// A property with an abstract implicit getter declaration.
  ///
  /// For instance a final or non-final abstract field declaration:
  ///
  ///     abstract class A {
  ///       abstract int? field; // ImplicitAbstract getter quality.
  ///       abstract final int finalField; // ImplicitAbstract getter quality.
  ///     }
  ImplicitAbstract,
}

/// Enum for the different ways a property can have a setter aspect.
enum SetterQuality {
  /// A property without a setter declaration.
  ///
  /// For instance an explicit getter:
  ///
  ///     class A {
  ///       int get getter => 42 // Absent setter quality.
  ///     }
  Absent,

  /// A property with a non-abstract, non-external, explicit setter declaration.
  ///
  /// For instance an explicit setter:
  ///
  ///     class A {
  ///       void set setter(int _) {} // Concrete setter quality.
  ///     }
  Concrete,

  /// A property with an external explicit setter declaration.
  ///
  /// For instance:
  ///
  ///     class A {
  ///       external void set setter(int _); // External setter quality.
  ///     }
  External,

  /// A property with an abstract explicit setter declaration.
  ///
  /// For instance:
  ///
  ///     abstract class A {
  ///       void set setter(int _); // Abstract setter quality.
  ///     }
  Abstract,

  /// A property with a non-abstract, non-external implicit setter declaration.
  ///
  /// For instance a non-final field declaration:
  ///
  ///     class A {
  ///       int? field; // Implicit setter quality.
  ///     }
  Implicit,

  /// A property with an external implicit setter declaration.
  ///
  /// For instance a non-final external field declaration:
  ///
  ///     class A {
  ///       external int? field; // ImplicitExternal setter quality.
  ///     }
  ImplicitExternal,

  /// A property with an abstract implicit setter declaration.
  ///
  /// For instance a non-final abstract field declaration:
  ///
  ///     abstract class A {
  ///       abstract int? field; // ImplicitAbstract setter quality.
  ///     }
  ImplicitAbstract,
}

/// Helper extension with helpers that are derived from other properties of
/// a [PropertyBuilder].
extension PropertyBuilderExtension on PropertyBuilder {
  /// Returns `true` if this property builder has a field declaration.
  bool get hasField => fieldQuality != FieldQuality.Absent;

  /// Returns `true` if this property builder has a non-abstract, non-external
  /// field declaration.
  bool get hasConcreteField => fieldQuality == FieldQuality.Concrete;

  /// Returns `true` if this property builder has an abstract field declaration.
  bool get hasAbstractField => fieldQuality.impliesAbstract;

  /// Returns `true` if this property builder has an external field declaration.
  bool get hasExternalField => fieldQuality == FieldQuality.External;

  /// Returns `true` if this property builder has a getter.
  bool get hasGetter => getterQuality != GetterQuality.Absent;

  /// Returns `true` if this property builder declares an abstract getter,
  /// i.e. an explicit abstract getter as opposed to an abstract getter induced
  /// by an abstract field.
  bool get declaresAbstractGetter => getterQuality == GetterQuality.Abstract;

  /// Returns `true` if this property builder has an abstract getter
  /// declaration.
  bool get hasAbstractGetter => getterQuality.impliesAbstract;

  /// Returns `true` if this property builder has an explicit getter, i.e. is
  /// has a getter that is not an implicit getter from a field declaration.
  bool get hasExplicitGetter => getterQuality.impliesExplicit;

  /// Returns `true` if this property builder has a setter.
  bool get hasSetter => setterQuality != SetterQuality.Absent;

  /// Returns `true` if this property builder declares an abstract setter,
  /// i.e. an explicit abstract getter as opposed to an abstract setter induced
  /// by an abstract field.
  bool get declaresAbstractSetter => setterQuality == SetterQuality.Abstract;

  /// Returns `true` if this property builder has an abstract setter
  /// declaration.
  bool get hasAbstractSetter => setterQuality.impliesAbstract;

  /// Returns `true` if this property builder has an explicit setter, i.e. is
  /// has a setter that is not an implicit setter from a field declaration.
  bool get hasExplicitSetter => setterQuality.impliesExplicit;
}

/// Helper extension with helpers that are derived from other properties of
/// a [FieldQuality].
extension FieldQualityExtension on FieldQuality {
  /// Returns `true` if this field quality implies an abstract field
  /// declaration.
  bool get impliesAbstract => this == FieldQuality.Abstract;
}

/// Helper extension with helpers that are derived from other properties of
/// a [GetterQuality].
extension GetterQualityExtension on GetterQuality {
  /// Returns `true` if this getter quality implies an abstract getter
  /// declaration.
  bool get impliesAbstract =>
      this == GetterQuality.Abstract || this == GetterQuality.ImplicitAbstract;

  /// Returns `true` if this getter quality implies an explicit getter, i.e. is
  /// has a getter that is not an implicit getter from a field declaration.
  bool get impliesExplicit =>
      this != GetterQuality.Absent &&
      this != GetterQuality.Implicit &&
      this != GetterQuality.ImplicitAbstract &&
      this != GetterQuality.ImplicitExternal;
}

/// Helper extension with helpers that are derived from other properties of
/// a [SetterQuality].
extension SetterQualityExtension on SetterQuality {
  /// Returns `true` if this setter quality implies an abstract setter
  /// declaration.
  bool get impliesAbstract =>
      this == SetterQuality.Abstract || this == SetterQuality.ImplicitAbstract;

  /// Returns `true` if this setter quality implies an explicit setter, i.e. is
  /// has a setter that is not an implicit setter from a field declaration.
  bool get impliesExplicit =>
      this != SetterQuality.Absent &&
      this != SetterQuality.Implicit &&
      this != SetterQuality.ImplicitAbstract &&
      this != SetterQuality.ImplicitExternal;
}

/// Returns `true` is this builder should be contained in the setter map.
// TODO(johnniwinther): Remove this when fields, getters, and setters are in the
// same builder.
bool isMappedAsSetter(Builder builder) {
  return builder is PropertyBuilder &&
      builder.fieldQuality == FieldQuality.Absent &&
      builder.hasExplicitSetter;
}
