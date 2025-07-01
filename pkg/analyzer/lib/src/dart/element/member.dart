// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:pub_semver/pub_semver.dart';

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class ConstructorMember extends ExecutableMember
    with ConstructorElementMixin2
    implements ConstructorElement {
  /// Initialize a newly created element to represent a constructor, based on
  /// the [declaration], and applied [substitution].
  ConstructorMember({
    required ConstructorElementImpl super.baseElement,
    required super.substitution,
  }) : super(typeParameters2: const <TypeParameterElementImpl>[]);

  @override
  ConstructorElementImpl get baseElement =>
      super.baseElement as ConstructorElementImpl;

  @override
  String get displayName => baseElement.displayName;

  @override
  InterfaceElementImpl get enclosingElement => _element2.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InterfaceElementImpl get enclosingElement2 => enclosingElement;

  @override
  ConstructorFragment get firstFragment => _element2.firstFragment;

  @override
  List<ConstructorFragment> get fragments {
    return [
      for (
        ConstructorFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isConst => baseElement.isConst;

  @override
  bool get isDefaultConstructor => baseElement.isConst;

  @override
  bool get isFactory => baseElement.isFactory;

  @override
  bool get isGenerative => baseElement.isGenerative;

  @override
  LibraryElementImpl get library => baseElement.library;

  @Deprecated('Use library instead')
  @override
  LibraryElementImpl get library2 => library;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  String? get name3 => _element2.name3;

  @override
  ConstructorElementMixin2? get redirectedConstructor2 {
    var element = baseElement.redirectedConstructor2;
    return _redirect(element);
  }

  @override
  InterfaceTypeImpl get returnType {
    var returnType = baseElement.returnType;
    return substitution.mapInterfaceType(returnType);
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  ConstructorElementMixin2? get superConstructor2 {
    return _redirect(baseElement.superConstructor2);
  }

  @override
  ConstructorElementImpl get _element2 => baseElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitConstructorElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  ConstructorElementMixin2? _redirect(ConstructorElementMixin2? element) {
    switch (element) {
      case null:
        return null;
      case ConstructorElementImpl():
        return element;
      case ConstructorMember():
        var memberMap = element.substitution.map;
        var map = <TypeParameterElement, DartType>{
          for (var MapEntry(:key, :value) in memberMap.entries)
            key: substitution.substituteType(value),
        };
        return ConstructorMember(
          baseElement: element.baseElement,
          substitution: Substitution.fromMap2(map),
        );
      default:
        throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  /// If the given [element]'s type is different when any type parameters
  /// from the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a constructor member
  /// representing the given constructor. Return the member that was created, or
  /// the original constructor if no member was created.
  static ConstructorElementMixin2 from2(
    ConstructorElementImpl element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return ConstructorMember(
      baseElement: element,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class ExecutableMember extends Member
    implements ExecutableElement2OrMember {
  @override
  final List<TypeParameterElementImpl> typeParameters2;

  FunctionTypeImpl? _type;

  /// Initialize a newly created element to represent a callable element (like a
  /// method or function or property), based on the [declaration], and applied
  /// [substitution].
  ///
  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [declaration] type
  /// parameters with the provided fresh [typeParameters].
  ExecutableMember({
    required ExecutableElementImpl super.baseElement,
    required super.substitution,
    required this.typeParameters2,
  });

  @override
  List<Element> get children2 {
    return [...typeParameters2, ...formalParameters];
  }

  @override
  String get displayName => baseElement.displayName;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => _element2.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  ExecutableFragment get firstFragment;

  @override
  List<FormalParameterElementMixin> get formalParameters {
    return baseElement.formalParameters.map<FormalParameterElementMixin>((
      element,
    ) {
      switch (element) {
        case FieldFormalParameterElementImpl():
          return FieldFormalParameterMember(
            baseElement: element,
            substitution: substitution,
          );
        case SuperFormalParameterElementImpl():
          return SuperFormalParameterMember(
            baseElement: element,
            substitution: substitution,
          );
        default:
          return ParameterMember(
            baseElement: element as FormalParameterElementImpl,
            substitution: substitution,
          );
      }
    }).toList();
  }

  @override
  List<ExecutableFragment> get fragments {
    return [
      for (
        ExecutableFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get hasImplicitReturnType => baseElement.hasImplicitReturnType;

  @override
  bool get isAbstract => baseElement.isAbstract;

  @override
  bool get isExtensionTypeMember => baseElement.isExtensionTypeMember;

  @override
  bool get isExternal => baseElement.isExternal;

  @override
  bool get isSimplyBounded => baseElement.isSimplyBounded;

  @override
  bool get isStatic => baseElement.isStatic;

  @override
  LibraryElement get library => _element2.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  Element get nonSynthetic => _element2;

  @Deprecated('Use nonSynthetic instead')
  @override
  Element get nonSynthetic2 => nonSynthetic;

  @override
  TypeImpl get returnType {
    var result = baseElement.returnType;
    result = substitution.substituteType(result);
    return result;
  }

  @override
  FunctionTypeImpl get type {
    return _type ??= substitution.mapFunctionType(baseElement.type);
  }

  @override
  ExecutableElement get _element2 => baseElement;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  bool isAccessibleIn2(LibraryElement library) =>
      _element2.isAccessibleIn2(library);

  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) =>
      _element2.thisOrAncestorMatching2(predicate);

  @override
  E? thisOrAncestorOfType2<E extends Element>() =>
      _element2.thisOrAncestorOfType2();

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    for (var child in children2) {
      child.accept(visitor);
    }
  }

  static ExecutableElement2OrMember from(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    if (identical(substitution, Substitution.empty)) {
      return element as ExecutableElement2OrMember;
    }

    ExecutableElementImpl baseElement;
    var combined = substitution;
    if (element is ExecutableMember) {
      baseElement = element.baseElement;

      var map = <TypeParameterElement, DartType>{
        for (var MapEntry(:key, :value) in element.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap2(map);
    } else {
      baseElement = element as ExecutableElementImpl;
      if (!baseElement.hasEnclosingTypeParameterReference) {
        return baseElement;
      }
    }

    switch (baseElement) {
      case ConstructorElementImpl():
        return ConstructorMember(
          baseElement: baseElement,
          substitution: combined,
        );
      case MethodElementImpl():
        return MethodMember(baseElement: baseElement, substitution: combined);
      case PropertyAccessorElementImpl():
        return PropertyAccessorMember(
          baseElement: baseElement,
          substitution: combined,
        );
      default:
        throw UnimplementedError('(${baseElement.runtimeType}) $element');
    }
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class FieldFormalParameterMember extends ParameterMember
    implements FieldFormalParameterElement {
  factory FieldFormalParameterMember({
    required FieldFormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters2.cast(),
      substitution,
    );
    return FieldFormalParameterMember._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters2: freshTypeParameters.elements,
    );
  }

  FieldFormalParameterMember._({
    required FieldFormalParameterElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  }) : super._();

  @override
  FieldFormalParameterElementImpl get baseElement =>
      super.baseElement as FieldFormalParameterElementImpl;

  @override
  FieldElement? get field2 {
    var field = baseElement.field2;
    if (field == null) {
      return null;
    }

    return FieldMember.from(field, substitution);
  }

  @override
  FieldFormalParameterFragment get firstFragment => baseElement.firstFragment;

  @override
  List<FieldFormalParameterFragment> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  bool get isCovariant => baseElement.isCovariant;
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class FieldMember extends VariableMember implements FieldElement2OrMember {
  /// Initialize a newly created element to represent a field, based on the
  /// [declaration], with applied [substitution].
  FieldMember({
    required FieldElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  FieldElementImpl get baseElement => super.baseElement as FieldElementImpl;

  @override
  List<Element> get children2 => const [];

  @override
  ConstantInitializer? get constantInitializer2 {
    return baseElement.constantInitializer2;
  }

  @override
  String get displayName => baseElement.displayName;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  InstanceElement get enclosingElement => _element2.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InstanceElement get enclosingElement2 => enclosingElement;

  @override
  FieldFragment get firstFragment => _element2.firstFragment;

  @override
  List<FieldFragment> get fragments {
    return [
      for (
        FieldFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  GetterElement2OrMember? get getter2 {
    var baseGetter = baseElement.getter2;
    if (baseGetter == null) {
      return null;
    }
    return GetterMember.forSubstitution(baseGetter, substitution);
  }

  @override
  bool get hasInitializer => baseElement.hasInitializer;

  @override
  bool get isAbstract => baseElement.isAbstract;

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  bool get isEnumConstant => baseElement.isEnumConstant;

  @override
  bool get isExternal => baseElement.isExternal;

  @override
  bool get isPromotable => baseElement.isPromotable;

  @override
  LibraryElement get library => _element2.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name3 => _element2.name3;

  @override
  Element get nonSynthetic => _element2.nonSynthetic;

  @Deprecated('Use nonSynthetic instead')
  @override
  Element get nonSynthetic2 => nonSynthetic;

  @override
  SetterElement2OrMember? get setter2 {
    var baseSetter = baseElement.setter2;
    if (baseSetter == null) {
      return null;
    }
    return SetterMember.forSubstitution(baseSetter, substitution);
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  FieldElementImpl get _element2 => baseElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFieldElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  DartObject? computeConstantValue() {
    return baseElement.computeConstantValue();
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return _element2.displayString2(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  bool isAccessibleIn2(LibraryElement library) {
    return _element2.isAccessibleIn2(library);
  }

  @override
  Element? thisOrAncestorMatching2(bool Function(Element e) predicate) {
    return _element2.thisOrAncestorMatching2(predicate);
  }

  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return _element2.thisOrAncestorOfType2<E>();
  }

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {}

  static FieldElement2OrMember from(
    FieldElementImpl element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return FieldMember(baseElement: element, substitution: substitution);
  }
}

/// A getter element defined in a parameterized type where the values of the
/// type parameters are known.
class GetterMember extends PropertyAccessorMember
    implements GetterElement2OrMember {
  GetterMember._({
    required super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  }) : super._();

  @override
  GetterElementImpl get baseElement => super.baseElement as GetterElementImpl;

  @override
  SetterElement2OrMember? get correspondingSetter2 {
    var baseSetter = baseElement.variable3!.setter2;
    if (baseSetter == null) {
      return null;
    }
    return SetterMember.forSubstitution(baseSetter, substitution);
  }

  @override
  GetterFragment get firstFragment => _element2.firstFragment;

  @override
  List<GetterFragment> get fragments {
    return [
      for (
        GetterFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  String? get lookupName => _element2.lookupName;

  @override
  Element get nonSynthetic {
    if (!isSynthetic) {
      return this;
    } else if (variable3 case var variable?) {
      return variable.nonSynthetic;
    }
    throw StateError('Synthetic getter has no variable');
  }

  @override
  GetterElementImpl get _element2 {
    return baseElement;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static GetterElement2OrMember forSubstitution(
    GetterElement2OrMember element,
    MapSubstitution substitution,
  ) {
    // TODO(scheglov): avoid type cast
    return ExecutableMember.from(element, substitution)
        as GetterElement2OrMember;
  }

  static GetterElement2OrMember forTargetType(
    GetterElement2OrMember element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    return forSubstitution(element, substitution);
  }
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class Member implements Element {
  @override
  final ElementImpl baseElement;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution substitution;

  /// Initialize a newly created element to represent a member, based on the
  /// [declaration], and applied [substitution].
  Member({required this.baseElement, required this.substitution});

  @override
  int get id => baseElement.id;

  @override
  bool get isPrivate => baseElement.isPrivate;

  @override
  bool get isPublic => baseElement.isPublic;

  @override
  bool get isSynthetic => baseElement.isSynthetic;

  @override
  ElementKind get kind => baseElement.kind;

  @override
  AnalysisSession? get session => baseElement.session;

  Element get _element2;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  String getExtendedDisplayName2({String? shortName}) {
    return _element2.getExtendedDisplayName2(shortName: shortName);
  }

  @override
  String toString() {
    var builder = ElementDisplayStringBuilder(preferTypeAlias: false);
    appendTo(builder);
    return builder.toString();
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class MethodMember extends ExecutableMember implements MethodElement2OrMember {
  factory MethodMember({
    required MethodElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      // TODO(scheglov): avoid the cast
      baseElement.typeParameters2.cast(),
      substitution,
    );
    return MethodMember._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters2: freshTypeParameters.elements,
    );
  }

  MethodMember._({
    required MethodElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  });

  @override
  MethodElementImpl get baseElement => super.baseElement as MethodElementImpl;

  @override
  MethodFragment get firstFragment => _element2.firstFragment;

  @override
  List<MethodFragment> get fragments {
    return [
      for (
        MethodFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get isOperator => baseElement.isOperator;

  @override
  LibraryElement get library => _element2.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  String? get lookupName => name3;

  @override
  String? get name3 => _element2.name3;

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  MethodElementImpl get _element2 => baseElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static MethodElement2OrMember forTargetType(
    MethodElement2OrMember element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    // TODO(scheglov): avoid type cast
    return ExecutableMember.from(element, substitution)
        as MethodElement2OrMember;
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class ParameterMember extends VariableMember with FormalParameterElementMixin {
  @override
  final List<TypeParameterElementImpl> typeParameters2;

  factory ParameterMember({
    required FormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters2.cast(),
      substitution,
    );
    return ParameterMember._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters2: freshTypeParameters.elements,
    );
  }

  /// Initialize a newly created element to represent a parameter, based on the
  /// [declaration], with applied [substitution].
  ParameterMember._({
    required FormalParameterElementImpl super.baseElement,
    required super.substitution,
    required this.typeParameters2,
  });

  @override
  FormalParameterElementImpl get baseElement =>
      super.baseElement as FormalParameterElementImpl;

  @override
  List<Element> get children2 {
    return [...typeParameters2, ...formalParameters];
  }

  @override
  ConstantInitializer? get constantInitializer2 {
    return baseElement.constantInitializer2;
  }

  @override
  String? get defaultValueCode => baseElement.defaultValueCode;

  @override
  String get displayName => baseElement.displayName;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => _element2.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  FormalParameterFragment get firstFragment => _element2.firstFragment;

  @override
  List<FormalParameterElementImpl> get formalParameters =>
      _element2.formalParameters;

  @override
  List<FormalParameterFragment> get fragments {
    return [
      for (
        FormalParameterFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  bool get isInitializingFormal => baseElement.isInitializingFormal;

  @override
  bool get isNamed => baseElement.isNamed;

  @override
  bool get isOptional => baseElement.isOptional;

  @override
  bool get isOptionalNamed => baseElement.isOptionalNamed;

  @override
  bool get isOptionalPositional => baseElement.isOptionalPositional;

  @override
  bool get isPositional => baseElement.isPositional;

  @override
  bool get isRequired => baseElement.isRequired;

  @override
  bool get isRequiredNamed => baseElement.isRequiredNamed;

  @override
  bool get isRequiredPositional => baseElement.isRequiredPositional;

  @override
  bool get isSuperFormal => baseElement.isSuperFormal;

  @override
  LibraryElement? get library => _element2.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement? get library2 => library;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String? get name3 => _element2.name3;

  @override
  String get nameShared => name3!;

  @override
  Element get nonSynthetic => _element2;

  @Deprecated('Use nonSynthetic instead')
  @override
  Element get nonSynthetic2 => nonSynthetic;

  @deprecated
  @override
  ParameterKind get parameterKind {
    return baseElement.parameterKind;
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  TypeImpl get typeShared => type;

  @override
  FormalParameterElementImpl get _element2 => baseElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFormalParameterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter2(this);
  }

  @override
  DartObject? computeConstantValue() {
    return baseElement.computeConstantValue();
  }

  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return _element2.displayString2(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  bool isAccessibleIn2(LibraryElement library) =>
      _element2.isAccessibleIn2(library);

  @override
  Element? thisOrAncestorMatching2(bool Function(Element p1) predicate) {
    return _element2.thisOrAncestorMatching2(predicate);
  }

  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return _element2.thisOrAncestorOfType2();
  }

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    _element2.visitChildren2(visitor);
  }

  static FormalParameterElementMixin from2(
    FormalParameterElementMixin element,
    MapSubstitution substitution,
  ) {
    FormalParameterElementImpl baseElement;
    var combined = substitution;
    if (element is ParameterMember) {
      var member = element;
      baseElement = member.baseElement;

      var map = <TypeParameterElement, DartType>{
        for (var MapEntry(:key, :value) in member.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap2(map);
    } else {
      baseElement = element as FormalParameterElementImpl;
    }

    if (combined.map.isEmpty) {
      return element;
    }

    return ParameterMember(baseElement: baseElement, substitution: combined);
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
abstract class PropertyAccessorMember extends ExecutableMember
    implements PropertyAccessorElement2OrMember {
  factory PropertyAccessorMember({
    required PropertyAccessorElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      // TODO(scheglov): avoid the cast
      baseElement.typeParameters2.cast(),
      substitution,
    );
    if (baseElement is GetterElementImpl) {
      return GetterMember._(
        baseElement: baseElement,
        substitution: freshTypeParameters.substitution,
        typeParameters2: freshTypeParameters.elements,
      );
    } else {
      return SetterMember._(
        baseElement: baseElement,
        substitution: freshTypeParameters.substitution,
        typeParameters2: freshTypeParameters.elements,
      );
    }
  }

  PropertyAccessorMember._({
    required PropertyAccessorElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  });

  @override
  Element get enclosingElement {
    return super.enclosingElement!;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element get enclosingElement2 => enclosingElement;

  @override
  PropertyAccessorFragment get firstFragment;

  @override
  String? get name3 => _element2.name3;

  @override
  PropertyInducingElement2OrMember? get variable3 {
    var variable = baseElement.variable3;
    switch (variable) {
      case FieldElementImpl():
        return FieldMember(baseElement: variable, substitution: substitution);
      default:
        return variable;
    }
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (this is GetterElement ? 'get ' : 'set ') + displayName,
    );
  }
}

/// A setter element defined in a parameterized type where the values of the
/// type parameters are known.
class SetterMember extends PropertyAccessorMember
    implements SetterElement2OrMember {
  SetterMember._({
    required super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  }) : super._();

  @override
  SetterElementImpl get baseElement => super.baseElement as SetterElementImpl;

  @override
  GetterElement2OrMember? get correspondingGetter2 {
    var baseGetter = baseElement.variable3!.getter2;
    if (baseGetter == null) {
      return null;
    }
    return GetterMember.forSubstitution(baseGetter, substitution);
  }

  @override
  SetterFragment get firstFragment => _element2.firstFragment;

  @override
  List<SetterFragment> get fragments {
    return [
      for (
        SetterFragment? fragment = firstFragment;
        fragment != null;
        fragment = fragment.nextFragment
      )
        fragment,
    ];
  }

  @override
  String? get lookupName => _element2.lookupName;

  @override
  Element get nonSynthetic {
    if (!isSynthetic) {
      return this;
    } else if (variable3 case var variable?) {
      return variable.nonSynthetic;
    }
    throw StateError('Synthetic setter has no variable');
  }

  @override
  SetterElementImpl get _element2 {
    return baseElement;
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static SetterElement2OrMember forSubstitution(
    SetterElement2OrMember element,
    MapSubstitution substitution,
  ) {
    // TODO(scheglov): avoid type cast
    return ExecutableMember.from(element, substitution)
        as SetterElement2OrMember;
  }

  static SetterElement2OrMember forTargetType(
    SetterElement2OrMember element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    return forSubstitution(element, substitution);
  }
}

class SuperFormalParameterMember extends ParameterMember
    implements SuperFormalParameterElement {
  factory SuperFormalParameterMember({
    required SuperFormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters2.cast(),
      substitution,
    );
    return SuperFormalParameterMember._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters2: freshTypeParameters.elements,
    );
  }

  SuperFormalParameterMember._({
    required SuperFormalParameterElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters2,
  }) : super._();

  @override
  SuperFormalParameterElementImpl get baseElement =>
      super.baseElement as SuperFormalParameterElementImpl;

  @override
  SuperFormalParameterFragment get firstFragment => baseElement.firstFragment;

  @override
  List<SuperFormalParameterFragment> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  FormalParameterElementMixin? get superConstructorParameter2 {
    var superConstructorParameter = baseElement.superConstructorParameter2;
    if (superConstructorParameter == null) {
      return null;
    }

    return ParameterMember.from2(superConstructorParameter, substitution);
  }
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class VariableMember extends Member
    implements VariableElement2OrMember {
  TypeImpl? _type;

  /// Initialize a newly created element to represent a variable, based on the
  /// [declaration], with applied [substitution].
  VariableMember({
    required VariableElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  VariableElementImpl get baseElement =>
      super.baseElement as VariableElementImpl;

  @override
  bool get hasImplicitType => baseElement.hasImplicitType;

  @override
  bool get isConst => baseElement.isConst;

  @override
  bool get isFinal => baseElement.isFinal;

  @override
  bool get isLate => baseElement.isLate;

  @override
  bool get isStatic => baseElement.isStatic;

  @override
  TypeImpl get type {
    if (_type != null) return _type!;

    var result = baseElement.type;
    result = substitution.substituteType(result);
    return _type = result;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement2(this);
  }
}

class _SubstitutedTypeParameters {
  final List<TypeParameterElementImpl> elements;
  final MapSubstitution substitution;

  factory _SubstitutedTypeParameters(
    List<TypeParameterElementImpl> elements,
    MapSubstitution substitution,
  ) {
    if (elements.isEmpty) {
      return _SubstitutedTypeParameters._(const [], substitution);
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    var newElements = <TypeParameterElementImpl>[];
    var newTypes = <TypeParameterType>[];
    for (int i = 0; i < elements.length; i++) {
      var newElement = elements[i].freshCopy();
      newElements.add(newElement);
      newTypes.add(
        newElement.instantiate(nullabilitySuffix: NullabilitySuffix.none),
      );
    }

    // Update bounds to reference new TypeParameterElement(s).
    var substitution2 = Substitution.fromPairs2(elements, newTypes);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var newElement = newElements[i];
      var bound = element.bound;
      if (bound != null) {
        var newBound = substitution2.substituteType(bound);
        newBound = substitution.substituteType(newBound);
        newElement.bound = newBound;
      }
    }

    if (substitution.map.isEmpty) {
      return _SubstitutedTypeParameters._(newElements, substitution2);
    }

    return _SubstitutedTypeParameters._(
      newElements,
      Substitution.fromMap2({...substitution.map, ...substitution2.map}),
    );
  }

  _SubstitutedTypeParameters._(this.elements, this.substitution);
}
