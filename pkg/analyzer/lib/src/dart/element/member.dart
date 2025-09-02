// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:pub_semver/pub_semver.dart';

@Deprecated('Use SubstitutedExecutableElementImpl instead')
typedef ExecutableMember = SubstitutedExecutableElementImpl;

@Deprecated('Use SubstitutedFieldElementImpl instead')
typedef FieldMember = SubstitutedFieldElementImpl;

@Deprecated('Use SubstitutedElementImpl instead')
typedef Member = SubstitutedElementImpl;

@Deprecated('Use SubstitutedFormalParameterElementImpl instead')
typedef ParameterMember = SubstitutedFormalParameterElementImpl;

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class SubstitutedConstructorElementImpl extends SubstitutedExecutableElementImpl
    with InternalConstructorElement
    implements ConstructorElement {
  SubstitutedConstructorElementImpl({
    required ConstructorElementImpl super.baseElement,
    required super.substitution,
  }) : super(typeParameters: const <TypeParameterElementImpl>[]);

  @override
  ConstructorElementImpl get baseElement =>
      super.baseElement as ConstructorElementImpl;

  @override
  InterfaceElementImpl get enclosingElement => baseElement.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InterfaceElementImpl get enclosingElement2 => enclosingElement;

  @override
  ConstructorFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<ConstructorFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get isConst => baseElement.isConst;

  @override
  bool get isDefaultConstructor => baseElement.isDefaultConstructor;

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
  InternalConstructorElement? get redirectedConstructor {
    var element = baseElement.redirectedConstructor;
    return _redirect(element);
  }

  @Deprecated('Use redirectedConstructor instead')
  @override
  InternalConstructorElement? get redirectedConstructor2 {
    return redirectedConstructor;
  }

  @override
  InterfaceTypeImpl get returnType {
    var returnType = baseElement.returnType;
    return substitution.mapInterfaceType(returnType);
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  InternalConstructorElement? get superConstructor {
    return _redirect(baseElement.superConstructor);
  }

  @Deprecated('Use superConstructor instead')
  @override
  InternalConstructorElement? get superConstructor2 {
    return superConstructor;
  }

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

  InternalConstructorElement? _redirect(InternalConstructorElement? element) {
    switch (element) {
      case null:
        return null;
      case ConstructorElementImpl():
        return element;
      case SubstitutedConstructorElementImpl():
        var memberMap = element.substitution.map;
        var map = <TypeParameterElement, DartType>{
          for (var MapEntry(:key, :value) in memberMap.entries)
            key: substitution.substituteType(value),
        };
        return SubstitutedConstructorElementImpl(
          baseElement: element.baseElement,
          substitution: Substitution.fromMap(map),
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
  static InternalConstructorElement from2(
    ConstructorElementImpl element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return SubstitutedConstructorElementImpl(
      baseElement: element,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class SubstitutedElementImpl implements Element {
  @override
  final ElementImpl baseElement;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution substitution;

  SubstitutedElementImpl({
    required this.baseElement,
    required this.substitution,
  });

  @override
  String get displayName => baseElement.displayName;

  @override
  FragmentImpl get firstFragment;

  @override
  List<FragmentImpl> get fragments;

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
  String? get lookupName => baseElement.lookupName;

  @override
  String? get name => baseElement.name;

  @Deprecated('Use name instead')
  @override
  String? get name3 => name;

  @override
  Element get nonSynthetic => baseElement;

  @Deprecated('Use nonSynthetic instead')
  @override
  Element get nonSynthetic2 => nonSynthetic;

  @override
  AnalysisSession? get session => baseElement.session;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  String getExtendedDisplayName({String? shortName}) {
    return baseElement.getExtendedDisplayName(shortName: shortName);
  }

  @Deprecated('Use getExtendedDisplayName instead')
  @override
  String getExtendedDisplayName2({String? shortName}) {
    return getExtendedDisplayName(shortName: shortName);
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return baseElement.isAccessibleIn(library);
  }

  @Deprecated('Use isAccessibleIn instead')
  @override
  bool isAccessibleIn2(LibraryElement library) {
    return isAccessibleIn(library);
  }

  @override
  Element? thisOrAncestorMatching(bool Function(Element e) predicate) {
    return baseElement.thisOrAncestorMatching(predicate);
  }

  @Deprecated('Use thisOrAncestorMatching instead')
  @override
  Element? thisOrAncestorMatching2(bool Function(Element e) predicate) {
    return thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    return baseElement.thisOrAncestorOfType<E>();
  }

  @Deprecated('Use thisOrAncestorOfType instead')
  @override
  E? thisOrAncestorOfType2<E extends Element>() {
    return thisOrAncestorOfType();
  }

  @override
  String toString() {
    var builder = ElementDisplayStringBuilder(preferTypeAlias: false);
    appendTo(builder);
    return builder.toString();
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class SubstitutedExecutableElementImpl extends SubstitutedElementImpl
    with InternalExecutableElement {
  @override
  final List<TypeParameterElementImpl> typeParameters;

  FunctionTypeImpl? _type;

  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [baseElement] type
  /// parameters with the provided fresh [typeParameters].
  SubstitutedExecutableElementImpl({
    required ExecutableElementImpl super.baseElement,
    required super.substitution,
    required this.typeParameters,
  });

  @override
  List<Element> get children {
    return [...typeParameters, ...formalParameters];
  }

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 {
    return children;
  }

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => baseElement.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  ExecutableFragmentImpl get firstFragment;

  @override
  List<InternalFormalParameterElement> get formalParameters {
    return baseElement.formalParameters.map<InternalFormalParameterElement>((
      element,
    ) {
      switch (element) {
        case FieldFormalParameterElementImpl():
          return SubstitutedFieldFormalParameterElementImpl(
            baseElement: element,
            substitution: substitution,
          );
        case SuperFormalParameterElementImpl():
          return SubstitutedSuperFormalParameterElementImpl(
            baseElement: element,
            substitution: substitution,
          );
        default:
          return SubstitutedFormalParameterElementImpl(
            baseElement: element,
            substitution: substitution,
          );
      }
    }).toList();
  }

  @override
  List<ExecutableFragmentImpl> get fragments {
    return baseElement.fragments;
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
  LibraryElement get library => baseElement.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

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

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterElementImpl> get typeParameters2 => typeParameters;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }

  @Deprecated('Use visitChildren instead')
  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    return visitChildren(visitor);
  }

  static InternalExecutableElement from(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    if (identical(substitution, Substitution.empty)) {
      return element as InternalExecutableElement;
    }

    ExecutableElementImpl baseElement;
    var combined = substitution;
    if (element is SubstitutedExecutableElementImpl) {
      baseElement = element.baseElement;

      var map = <TypeParameterElement, DartType>{
        for (var MapEntry(:key, :value) in element.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap(map);
    } else {
      baseElement = element as ExecutableElementImpl;
      if (!baseElement.hasEnclosingTypeParameterReference) {
        return baseElement;
      }
    }

    switch (baseElement) {
      case ConstructorElementImpl():
        return SubstitutedConstructorElementImpl(
          baseElement: baseElement,
          substitution: combined,
        );
      case MethodElementImpl():
        return SubstitutedMethodElementImpl(
          baseElement: baseElement,
          substitution: combined,
        );
      case PropertyAccessorElementImpl():
        return SubstitutedPropertyAccessorElementImpl(
          baseElement: baseElement,
          substitution: combined,
        );
      default:
        throw UnimplementedError('(${baseElement.runtimeType}) $element');
    }
  }
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class SubstitutedFieldElementImpl extends SubstitutedVariableElementImpl
    with InternalPropertyInducingElement, InternalFieldElement {
  SubstitutedFieldElementImpl({
    required FieldElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  FieldElementImpl get baseElement => super.baseElement as FieldElementImpl;

  @override
  List<Element> get children => const [];

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 => children;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  InstanceElement get enclosingElement => baseElement.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  InstanceElement get enclosingElement2 => enclosingElement;

  @override
  FieldFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<FieldFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  InternalGetterElement? get getter {
    var baseGetter = baseElement.getter;
    if (baseGetter == null) {
      return null;
    }
    return SubstitutedGetterElementImpl.forSubstitution(
      baseGetter,
      substitution,
    );
  }

  @Deprecated('Use getter instead')
  @override
  InternalGetterElement? get getter2 {
    return getter;
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
  LibraryElementImpl get library => baseElement.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  InternalSetterElement? get setter {
    var baseSetter = baseElement.setter;
    if (baseSetter == null) {
      return null;
    }
    return SubstitutedSetterElementImpl.forSubstitution(
      baseSetter,
      substitution,
    );
  }

  @Deprecated('Use setter instead')
  @override
  InternalSetterElement? get setter2 {
    return setter;
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFieldElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}

  @Deprecated('Use visitChildren instead')
  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    visitChildren(visitor);
  }

  static InternalFieldElement from(
    FieldElementImpl element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return SubstitutedFieldElementImpl(
      baseElement: element,
      substitution: substitution,
    );
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedFieldFormalParameterElementImpl
    extends SubstitutedFormalParameterElementImpl
    implements FieldFormalParameterElement {
  factory SubstitutedFieldFormalParameterElementImpl({
    required FieldFormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters,
      substitution,
    );
    return SubstitutedFieldFormalParameterElementImpl._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  SubstitutedFieldFormalParameterElementImpl._({
    required FieldFormalParameterElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  FieldFormalParameterElementImpl get baseElement =>
      super.baseElement as FieldFormalParameterElementImpl;

  @override
  FieldElement? get field {
    var field = baseElement.field;
    if (field == null) {
      return null;
    }

    return SubstitutedFieldElementImpl.from(field, substitution);
  }

  @Deprecated('Use field instead')
  @override
  FieldElement? get field2 {
    return field;
  }

  @override
  FieldFormalParameterFragmentImpl get firstFragment {
    return baseElement.firstFragment;
  }

  @override
  List<FieldFormalParameterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  bool get isCovariant => baseElement.isCovariant;
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedFormalParameterElementImpl
    extends SubstitutedVariableElementImpl
    with InternalFormalParameterElement {
  @override
  final List<TypeParameterElementImpl> typeParameters;

  factory SubstitutedFormalParameterElementImpl({
    required FormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters,
      substitution,
    );
    return SubstitutedFormalParameterElementImpl._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  SubstitutedFormalParameterElementImpl._({
    required FormalParameterElementImpl super.baseElement,
    required super.substitution,
    required this.typeParameters,
  });

  @override
  FormalParameterElementImpl get baseElement =>
      super.baseElement as FormalParameterElementImpl;

  @override
  List<Element> get children {
    return [...typeParameters, ...formalParameters];
  }

  @Deprecated('Use children instead')
  @override
  List<Element> get children2 {
    return children;
  }

  @override
  String? get defaultValueCode => baseElement.defaultValueCode;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => baseElement.enclosingElement;

  @Deprecated('Use enclosingElement instead')
  @override
  Element? get enclosingElement2 => enclosingElement;

  @override
  FormalParameterFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<FormalParameterElementImpl> get formalParameters =>
      baseElement.formalParameters;

  @override
  List<FormalParameterFragmentImpl> get fragments {
    return baseElement.fragments;
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
  LibraryElement? get library => baseElement.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement? get library2 => library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @Deprecated('Use metadata instead')
  @override
  MetadataImpl get metadata2 => metadata;

  @override
  String get nameShared => name!;

  @deprecated
  @override
  ParameterKind get parameterKind {
    return baseElement.parameterKind;
  }

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @Deprecated('Use typeParameters instead')
  @override
  List<TypeParameterElementImpl> get typeParameters2 => typeParameters;

  @override
  TypeImpl get typeShared => type;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFormalParameterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameterElement(this);
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    baseElement.visitChildren(visitor);
  }

  @Deprecated('Use visitChildren instead')
  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    visitChildren(visitor);
  }

  static InternalFormalParameterElement from(
    InternalFormalParameterElement element,
    MapSubstitution substitution,
  ) {
    FormalParameterElementImpl baseElement;
    var combined = substitution;
    if (element is SubstitutedFormalParameterElementImpl) {
      var member = element;
      baseElement = member.baseElement;

      var map = <TypeParameterElement, DartType>{
        for (var MapEntry(:key, :value) in member.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap(map);
    } else {
      baseElement = element as FormalParameterElementImpl;
    }

    if (combined.map.isEmpty) {
      return element;
    }

    return SubstitutedFormalParameterElementImpl(
      baseElement: baseElement,
      substitution: combined,
    );
  }
}

/// A getter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedGetterElementImpl
    extends SubstitutedPropertyAccessorElementImpl
    with InternalGetterElement {
  SubstitutedGetterElementImpl._({
    required super.baseElement,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  GetterElementImpl get baseElement => super.baseElement as GetterElementImpl;

  @override
  InternalSetterElement? get correspondingSetter {
    var baseSetter = baseElement.variable.setter;
    if (baseSetter == null) {
      return null;
    }
    return SubstitutedSetterElementImpl.forSubstitution(
      baseSetter,
      substitution,
    );
  }

  @Deprecated('Use correspondingSetter instead')
  @override
  InternalSetterElement? get correspondingSetter2 {
    return correspondingSetter;
  }

  @override
  GetterFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<GetterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static InternalGetterElement forSubstitution(
    InternalGetterElement element,
    MapSubstitution substitution,
  ) {
    // TODO(scheglov): avoid type cast
    return SubstitutedExecutableElementImpl.from(element, substitution)
        as InternalGetterElement;
  }

  static InternalGetterElement forTargetType(
    InternalGetterElement element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    return forSubstitution(element, substitution);
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedMethodElementImpl extends SubstitutedExecutableElementImpl
    with InternalMethodElement {
  factory SubstitutedMethodElementImpl({
    required MethodElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters,
      substitution,
    );
    return SubstitutedMethodElementImpl._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  SubstitutedMethodElementImpl._({
    required MethodElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters,
  });

  @override
  MethodElementImpl get baseElement => super.baseElement as MethodElementImpl;

  @override
  MethodFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<MethodFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get isOperator => baseElement.isOperator;

  @override
  LibraryElement get library => baseElement.library;

  @Deprecated('Use library instead')
  @override
  LibraryElement get library2 => library;

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static InternalMethodElement forTargetType(
    InternalMethodElement element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    // TODO(scheglov): avoid type cast
    return SubstitutedExecutableElementImpl.from(element, substitution)
        as InternalMethodElement;
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
abstract class SubstitutedPropertyAccessorElementImpl
    extends SubstitutedExecutableElementImpl
    with InternalPropertyAccessorElement {
  factory SubstitutedPropertyAccessorElementImpl({
    required PropertyAccessorElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters,
      substitution,
    );
    if (baseElement is GetterElementImpl) {
      return SubstitutedGetterElementImpl._(
        baseElement: baseElement,
        substitution: freshTypeParameters.substitution,
        typeParameters: freshTypeParameters.elements,
      );
    } else {
      return SubstitutedSetterElementImpl._(
        baseElement: baseElement,
        substitution: freshTypeParameters.substitution,
        typeParameters: freshTypeParameters.elements,
      );
    }
  }

  SubstitutedPropertyAccessorElementImpl._({
    required PropertyAccessorElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters,
  });

  @override
  Element get enclosingElement {
    return super.enclosingElement!;
  }

  @Deprecated('Use enclosingElement instead')
  @override
  Element get enclosingElement2 => enclosingElement;

  @override
  PropertyAccessorFragmentImpl get firstFragment;

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  InternalPropertyInducingElement get variable {
    var variable = baseElement.variable;
    switch (variable) {
      case FieldElementImpl():
        return SubstitutedFieldElementImpl(
          baseElement: variable,
          substitution: substitution,
        );
      default:
        return variable;
    }
  }

  @Deprecated('Use variable instead')
  @override
  InternalPropertyInducingElement? get variable3 {
    return variable;
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
class SubstitutedSetterElementImpl
    extends SubstitutedPropertyAccessorElementImpl
    with InternalSetterElement {
  SubstitutedSetterElementImpl._({
    required super.baseElement,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  SetterElementImpl get baseElement => super.baseElement as SetterElementImpl;

  @override
  InternalGetterElement? get correspondingGetter {
    var baseGetter = baseElement.variable.getter;
    if (baseGetter == null) {
      return null;
    }
    return SubstitutedGetterElementImpl.forSubstitution(
      baseGetter,
      substitution,
    );
  }

  @Deprecated('Use correspondingGetter instead')
  @override
  InternalGetterElement? get correspondingGetter2 {
    return correspondingGetter;
  }

  @override
  SetterFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<SetterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  Element get nonSynthetic {
    if (isSynthetic) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  @Deprecated('Use accept instead')
  @override
  T? accept2<T>(ElementVisitor2<T> visitor) => accept(visitor);

  static InternalSetterElement forSubstitution(
    InternalSetterElement element,
    MapSubstitution substitution,
  ) {
    // TODO(scheglov): avoid type cast
    return SubstitutedExecutableElementImpl.from(element, substitution)
        as InternalSetterElement;
  }

  static InternalSetterElement forTargetType(
    InternalSetterElement element,
    InterfaceType targetType,
  ) {
    var substitution = Substitution.fromInterfaceType(targetType);
    return forSubstitution(element, substitution);
  }
}

class SubstitutedSuperFormalParameterElementImpl
    extends SubstitutedFormalParameterElementImpl
    implements SuperFormalParameterElement {
  factory SubstitutedSuperFormalParameterElementImpl({
    required SuperFormalParameterElementImpl baseElement,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      baseElement.typeParameters,
      substitution,
    );
    return SubstitutedSuperFormalParameterElementImpl._(
      baseElement: baseElement,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  SubstitutedSuperFormalParameterElementImpl._({
    required SuperFormalParameterElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  SuperFormalParameterElementImpl get baseElement =>
      super.baseElement as SuperFormalParameterElementImpl;

  @override
  SuperFormalParameterFragmentImpl get firstFragment {
    return baseElement.firstFragment;
  }

  @override
  List<SuperFormalParameterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  InternalFormalParameterElement? get superConstructorParameter {
    var superConstructorParameter = baseElement.superConstructorParameter;
    if (superConstructorParameter == null) {
      return null;
    }

    return SubstitutedFormalParameterElementImpl.from(
      superConstructorParameter,
      substitution,
    );
  }

  @Deprecated('Use superConstructorParameter instead')
  @override
  InternalFormalParameterElement? get superConstructorParameter2 {
    return superConstructorParameter;
  }
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class SubstitutedVariableElementImpl extends SubstitutedElementImpl
    with InternalVariableElement {
  TypeImpl? _type;

  SubstitutedVariableElementImpl({
    required VariableElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  VariableElementImpl get baseElement =>
      super.baseElement as VariableElementImpl;

  @override
  ExpressionImpl? get constantInitializer {
    return baseElement.constantInitializer;
  }

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
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() {
    return baseElement.computeConstantValue();
  }

  @override
  String displayString({bool multiline = false, bool preferTypeAlias = false}) {
    return baseElement.displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
  }

  @Deprecated('Use displayString instead')
  @override
  String displayString2({
    bool multiline = false,
    bool preferTypeAlias = false,
  }) {
    return displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
    );
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
      Substitution.fromMap({...substitution.map, ...substitution2.map}),
    );
  }

  _SubstitutedTypeParameters._(this.elements, this.substitution);
}
