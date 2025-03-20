// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:pub_semver/pub_semver.dart';

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class ConstructorMember extends ExecutableMember
    with ConstructorElementMixin, ConstructorElementMixin2
    implements ConstructorElement, ConstructorElement2 {
  /// Initialize a newly created element to represent a constructor, based on
  /// the [declaration], and applied [substitution].
  ConstructorMember({
    required ConstructorElementImpl super.declaration,
    required super.substitution,
  }) : super(
          typeParameters: const <TypeParameterElementImpl>[],
        );

  @override
  ConstructorElementImpl2 get baseElement => _element2;

  @override
  ConstructorElementImpl get declaration =>
      _declaration as ConstructorElementImpl;

  @override
  String get displayName => declaration.displayName;

  @override
  InterfaceElementImpl2 get enclosingElement2 => _element2.enclosingElement2;

  @override
  InterfaceElement get enclosingElement3 => declaration.enclosingElement3;

  @override
  ConstructorFragment get firstFragment => _element2.firstFragment;

  @override
  List<ConstructorFragment> get fragments {
    return [
      for (ConstructorFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isFactory => declaration.isFactory;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  String get name => declaration.name;

  @override
  String? get name3 => _element2.name3;

  @override
  int? get nameEnd => declaration.nameEnd;

  @override
  int? get periodOffset => declaration.periodOffset;

  @override
  ConstructorElementMixin? get redirectedConstructor {
    var element = declaration.redirectedConstructor;
    return _redirect(element);
  }

  @override
  ConstructorElement2? get redirectedConstructor2 {
    var element = redirectedConstructor.asElement2;
    return switch (element) {
      ConstructorElement2() => element,
      _ => null,
    };
  }

  @override
  InterfaceTypeImpl get returnType =>
      // TODO(paulberry): eliminate this cast by changing the type of `type` to
      // `FunctionTypeImpl`.
      type.returnType as InterfaceTypeImpl;

  @override
  Source get source => _declaration.source!;

  @override
  ConstructorElement? get superConstructor {
    var element = declaration.superConstructor;
    return _redirect(element);
  }

  @override
  ConstructorElement2? get superConstructor2 => superConstructor?.asElement2;

  @override
  ConstructorElementImpl2 get _element2 => declaration.asElement2;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitConstructorElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  ConstructorElementMixin? _redirect(ConstructorElementMixin? element) {
    switch (element) {
      case null:
        return null;
      case ConstructorElementImpl():
        return element;
      case ConstructorMember():
        var memberMap = element.substitution.map;
        var map = <TypeParameterElement2, DartType>{
          for (var MapEntry(:key, :value) in memberMap.entries)
            key: substitution.substituteType(value),
        };
        return ConstructorMember(
          declaration: element.declaration,
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
  static ConstructorElementMixin from(
    ConstructorElementImpl element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return ConstructorMember(
      declaration: element,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }

  /// If the given [element]'s type is different when any type parameters
  /// from the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a constructor member
  /// representing the given constructor. Return the member that was created, or
  /// the original constructor if no member was created.
  static ConstructorElementMixin2 from2(
    ConstructorElementImpl2 element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return ConstructorMember(
      declaration: element.asElement,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class ExecutableMember extends Member
    implements ExecutableElementOrMember, ExecutableElement2OrMember {
  @override
  final List<TypeParameterElementImpl> typeParameters;

  FunctionTypeImpl? _type;

  /// Initialize a newly created element to represent a callable element (like a
  /// method or function or property), based on the [declaration], and applied
  /// [substitution].
  ///
  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [declaration] type
  /// parameters with the provided fresh [typeParameters].
  ExecutableMember({
    required ExecutableElement super.declaration,
    required super.substitution,
    required this.typeParameters,
  });

  @override
  List<Element> get children => parameters;

  @override
  List<Element2> get children2 =>
      children.map((fragment) => fragment.asElement2).nonNulls.toList();

  @override
  ExecutableElementImpl get declaration =>
      _declaration as ExecutableElementImpl;

  @override
  String get displayName => declaration.displayName;

  @override
  Element2? get enclosingElement2 => _element2.enclosingElement2;

  @override
  List<FormalParameterElementMixin> get formalParameters =>
      parameters.map((fragment) => fragment.asElement2).toList();

  @override
  List<ExecutableFragment> get fragments {
    return [
      for (ExecutableFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  bool get hasImplicitReturnType => declaration.hasImplicitReturnType;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isAsynchronous => declaration.isAsynchronous;

  @override
  bool get isAugmentation => declaration.isAugmentation;

  @override
  bool get isExtensionTypeMember => declaration.isExtensionTypeMember;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  bool get isGenerator => declaration.isGenerator;

  @override
  bool get isOperator => declaration.isOperator;

  @override
  bool get isSimplyBounded => declaration.isSimplyBounded;

  @override
  bool get isStatic => declaration.isStatic;

  @override
  bool get isSynchronous => declaration.isSynchronous;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  LibraryElement2 get library2 => _element2.library2;

  @override
  Source get librarySource => _declaration.librarySource!;

  @override
  int get nameOffset => declaration.nameOffset;

  @override
  Element2 get nonSynthetic2 => _element2;

  @override
  List<ParameterElementMixin> get parameters {
    return declaration.parameters.map<ParameterElementMixin>((element) {
      switch (element) {
        case FieldFormalParameterElementImpl():
          return FieldFormalParameterMember(
            declaration: element,
            substitution: substitution,
          );
        case SuperFormalParameterElementImpl():
          return SuperFormalParameterMember(
            declaration: element,
            substitution: substitution,
          );
        default:
          return ParameterMember(
            declaration: element,
            substitution: substitution,
          );
      }
    }).toList();
  }

  @override
  TypeImpl get returnType {
    var result = declaration.returnType;
    result = substitution.substituteType(result);
    return result;
  }

  @override
  FunctionTypeImpl get type {
    if (_type != null) return _type!;

    _type = substitution.substituteType(declaration.type) as FunctionTypeImpl;
    return _type!;
  }

  @override
  List<TypeParameterElement2> get typeParameters2 => typeParameters
      .map((fragment) => fragment.asElement2 as TypeParameterElement2?)
      .nonNulls
      .toList();

  @override
  ExecutableElement2 get _element2 => declaration.asElement2;

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
  bool isAccessibleIn2(LibraryElement2 library) =>
      _element2.isAccessibleIn2(library);

  @override
  Element2? thisOrAncestorMatching2(bool Function(Element2 p1) predicate) =>
      _element2.thisOrAncestorMatching2(predicate);

  @override
  E? thisOrAncestorOfType2<E extends Element2>() =>
      _element2.thisOrAncestorOfType2();

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    for (var child in children2) {
      child.accept2(visitor);
    }
  }

  static ExecutableElement2OrMember from(
    ExecutableElement2 element,
    MapSubstitution substitution,
  ) {
    return from2(element.asElement, substitution).asElement2;
  }

  static ExecutableElementOrMember from2(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    // TODO(scheglov): There is (E, E) substitution in `test_rewrite_without_target`.
    // TODO(scheglov): Shortcut on `_NullSubstitution`.

    ExecutableElementImpl declaration;
    var combined = substitution;
    if (element is ExecutableMember) {
      ExecutableMember member = element;
      declaration = member.declaration;

      var map = <TypeParameterElement2, DartType>{
        for (var MapEntry(:key, :value) in member.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap2(map);
    } else {
      declaration = element as ExecutableElementImpl;
    }

    if (combined.map.isEmpty) {
      // TODO(paulberry): eliminate this cast by changing the type of the
      // parameter `element`.
      return element as ExecutableElementOrMember;
    }

    switch (declaration) {
      case ConstructorElementImpl():
        return ConstructorMember(
          declaration: declaration,
          substitution: combined,
        );
      case MethodElementImpl():
        return MethodMember(
          declaration: declaration,
          substitution: combined,
        );
      case PropertyAccessorElementImpl():
        return PropertyAccessorMember(
          declaration: declaration,
          substitution: combined,
        );
      default:
        throw UnimplementedError('(${declaration.runtimeType}) $element');
    }
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class FieldFormalParameterMember extends ParameterMember
    implements FieldFormalParameterElement {
  factory FieldFormalParameterMember({
    required FieldFormalParameterElement declaration,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return FieldFormalParameterMember._(
      declaration: declaration,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  FieldFormalParameterMember._({
    required FieldFormalParameterElement super.declaration,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  FieldElementOrMember? get field {
    var field = (declaration as FieldFormalParameterElement).field;
    if (field == null) {
      return null;
    }

    return FieldMember(
      declaration: field,
      substitution: substitution,
    );
  }

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class FieldMember extends VariableMember
    implements FieldElementOrMember, FieldElement2OrMember {
  /// Initialize a newly created element to represent a field, based on the
  /// [declaration], with applied [substitution].
  FieldMember({
    required FieldElement super.declaration,
    required super.substitution,
  });

  @override
  FieldElement2 get baseElement => _element2;

  @override
  List<Element2> get children2 =>
      children.map((fragment) => fragment.asElement2).nonNulls.toList();

  @override
  ConstantInitializer? get constantInitializer2 {
    return baseElement.constantInitializer2;
  }

  @override
  FieldElementImpl get declaration => _declaration as FieldElementImpl;

  @override
  String get displayName => declaration.displayName;

  @override
  InstanceElement2 get enclosingElement2 => _element2.enclosingElement2;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  FieldFragment get firstFragment => _element2.firstFragment;

  @override
  List<FieldFragment> get fragments {
    return [
      for (FieldFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  PropertyAccessorElement? get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
      declaration: baseGetter,
      substitution: substitution,
    );
  }

  @override
  GetterElement2OrMember? get getter2 {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return GetterMember._(
      declaration: baseGetter,
      substitution: substitution,
      typeParameters: baseGetter.typeParameters,
    );
  }

  @override
  bool get hasInitializer => declaration.hasInitializer;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isAugmentation => declaration.isAugmentation;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isEnumConstant => declaration.isEnumConstant;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  bool get isPromotable => declaration.isPromotable;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  LibraryElement2 get library2 => _element2.library2;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  String get name => declaration.name;

  @override
  String? get name3 => _element2.name3;

  @override
  Element2 get nonSynthetic2 => _element2.nonSynthetic2;

  @override
  PropertyAccessorElement? get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
      declaration: baseSetter,
      substitution: substitution,
    );
  }

  @override
  SetterElement2OrMember? get setter2 {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return SetterMember._(
      declaration: baseSetter,
      substitution: substitution,
      typeParameters: baseSetter.typeParameters,
    );
  }

  @override
  Source? get source => _declaration.source;

  @override
  FieldElement2 get _element2 => declaration.asElement2;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFieldElement(this);
  }

  @override
  String displayString2(
      {bool multiline = false, bool preferTypeAlias = false}) {
    return _element2.displayString2(
        multiline: multiline, preferTypeAlias: preferTypeAlias);
  }

  @override
  bool isAccessibleIn2(LibraryElement2 library) {
    return _element2.isAccessibleIn2(library);
  }

  @override
  Element2? thisOrAncestorMatching2(bool Function(Element2 e) predicate) {
    return _element2.thisOrAncestorMatching2(predicate);
  }

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    return _element2.thisOrAncestorOfType2<E>();
  }

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {}

  /// If the given [field]'s type is different when any type parameters from the
  /// defining type's declaration are replaced with the actual type arguments
  /// from the [definingType], create a field member representing the given
  /// field. Return the member that was created, or the base field if no member
  /// was created.
  static FieldElementOrMember from(
      FieldElementOrMember field, InterfaceType definingType) {
    if (definingType.typeArguments.isEmpty) {
      return field;
    }
    return FieldMember(
      declaration: field,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }

  static FieldElement from2(
    FieldElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return FieldMember(
      declaration: element,
      substitution: substitution,
    );
  }
}

/// A getter element defined in a parameterized type where the values of the
/// type parameters are known.
class GetterMember extends PropertyAccessorMember
    implements GetterElement2OrMember {
  GetterMember._({
    required super.declaration,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  GetterElement get baseElement => _element2;

  @override
  SetterElement? get correspondingSetter2 {
    var setter = correspondingSetter;
    if (setter is SetterMember) {
      return setter;
    }
    return setter.asElement2 as SetterElement?;
  }

  @override
  GetterFragment get firstFragment => _element2.firstFragment;

  @override
  List<GetterFragment> get fragments {
    return [
      for (GetterFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  String? get lookupName => _element2.lookupName;

  @override
  Element2 get nonSynthetic2 {
    if (!isSynthetic) {
      return this;
    } else if (variable3 case var variable?) {
      return variable.nonSynthetic2;
    }
    throw StateError('Synthetic getter has no variable');
  }

  @override
  PropertyInducingElement2OrMember? get variable3 =>
      variable2.asElement2 as PropertyInducingElement2OrMember?;

  @override
  GetterElement get _element2 => declaration.asElement2 as GetterElement;

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  static GetterElement2OrMember from(
    GetterElementImpl element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return GetterMember._(
      declaration: element.asElement,
      substitution: Substitution.fromInterfaceType(definingType),
      typeParameters: const [],
    );
  }
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class Member implements Element, ElementOrMember {
  /// The element on which the parameterized element was created.
  final Element _declaration;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution substitution;

  /// Initialize a newly created element to represent a member, based on the
  /// [declaration], and applied [substitution].
  Member({
    required Element declaration,
    required this.substitution,
  }) : _declaration = declaration {
    if (_declaration is Member) {
      throw StateError('Members must be created from a declaration, but is '
          '(${_declaration.runtimeType}) "$_declaration".');
    }
  }

  @override
  List<Element> get children => const [];

  @override
  AnalysisContext get context => _declaration.context;

  @override
  ElementImpl get declaration => _declaration as ElementImpl;

  @override
  String get displayName => _declaration.displayName;

  @override
  String? get documentationComment => _declaration.documentationComment;

  @override
  Element? get enclosingElement3 => _declaration.enclosingElement3;

  @override
  bool get hasAlwaysThrows => _declaration.hasAlwaysThrows;

  @override
  bool get hasDeprecated => _declaration.hasDeprecated;

  @override
  bool get hasDoNotStore => _declaration.hasDoNotStore;

  @override
  bool get hasDoNotSubmit => _declaration.hasDoNotSubmit;

  @override
  bool get hasFactory => _declaration.hasFactory;

  @override
  bool get hasImmutable => _declaration.hasImmutable;

  @override
  bool get hasInternal => _declaration.hasInternal;

  @override
  bool get hasIsTest => _declaration.hasIsTest;

  @override
  bool get hasIsTestGroup => _declaration.hasIsTestGroup;

  @override
  bool get hasJS => _declaration.hasJS;

  @override
  bool get hasLiteral => _declaration.hasLiteral;

  @override
  bool get hasMustBeConst => _declaration.hasMustBeConst;

  @override
  bool get hasMustBeOverridden => _declaration.hasMustBeOverridden;

  @override
  bool get hasMustCallSuper => _declaration.hasMustCallSuper;

  @override
  bool get hasNonVirtual => _declaration.hasNonVirtual;

  @override
  bool get hasOptionalTypeArgs => _declaration.hasOptionalTypeArgs;

  @override
  bool get hasOverride => _declaration.hasOverride;

  @override
  bool get hasProtected => _declaration.hasProtected;

  @override
  bool get hasRedeclare => _declaration.hasRedeclare;

  @override
  bool get hasReopen => _declaration.hasReopen;

  @override
  bool get hasRequired => _declaration.hasRequired;

  @override
  bool get hasSealed => _declaration.hasSealed;

  @override
  bool get hasUseResult => _declaration.hasUseResult;

  @override
  bool get hasVisibleForOverriding => _declaration.hasVisibleForOverriding;

  @override
  bool get hasVisibleForTemplate => _declaration.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => _declaration.hasVisibleForTesting;

  @override
  bool get hasVisibleOutsideTemplate => _declaration.hasVisibleOutsideTemplate;

  @override
  int get id => _declaration.id;

  @override
  bool get isPrivate => _declaration.isPrivate;

  @override
  bool get isPublic => _declaration.isPublic;

  @override
  bool get isSynthetic => _declaration.isSynthetic;

  @override
  ElementKind get kind => _declaration.kind;

  @override
  LibraryElement? get library => _declaration.library;

  @override
  Source? get librarySource => _declaration.librarySource;

  @override
  ElementLocation get location => _declaration.location!;

  @override
  List<ElementAnnotation> get metadata => _declaration.metadata;

  Metadata get metadata2 => (_declaration as ElementImpl).metadata2;

  @override
  String? get name => _declaration.name;

  @override
  int get nameLength => _declaration.nameLength;

  @override
  int get nameOffset => _declaration.nameOffset;

  @override
  Element get nonSynthetic => _declaration.nonSynthetic;

  @override
  AnalysisSession? get session => _declaration.session;

  @override
  Version? get sinceSdkVersion => _declaration.sinceSdkVersion;

  Element2 get _element2;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  String getDisplayString({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
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
  String getExtendedDisplayName(String? shortName) =>
      _declaration.getExtendedDisplayName(shortName);

  String getExtendedDisplayName2({String? shortName}) {
    return _element2.getExtendedDisplayName2(
      shortName: shortName,
    );
  }

  @override
  bool isAccessibleIn(LibraryElement library) =>
      _declaration.isAccessibleIn(library);

  @override
  E? thisOrAncestorMatching<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return declaration.thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorMatching3<E extends Element>(
    bool Function(Element) predicate,
  ) {
    return declaration.thisOrAncestorMatching3(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() =>
      declaration.thisOrAncestorOfType<E>();

  @override
  E? thisOrAncestorOfType3<E extends Element>() =>
      declaration.thisOrAncestorOfType3<E>();

  @override
  String toString() {
    return getDisplayString();
  }

  /// Use the given [visitor] to visit all of the children of this element.
  /// There is no guarantee of the order in which the children will be visited.
  @Deprecated('Use Element2 and visitChildren2() instead')
  @override
  void visitChildren(ElementVisitor visitor) {
    for (Element child in children) {
      child.accept(visitor);
    }
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class MethodMember extends ExecutableMember
    implements MethodElementOrMember, MethodElement2OrMember {
  factory MethodMember({
    required MethodElementImpl declaration,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return MethodMember._(
      declaration: declaration,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  MethodMember._({
    required MethodElementImpl super.declaration,
    required super.substitution,
    required super.typeParameters,
  });

  @override
  MethodElementImpl2 get baseElement => _element2;

  @override
  MethodElementImpl get declaration => _declaration as MethodElementImpl;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  MethodFragment get firstFragment => _element2.firstFragment;

  @override
  List<MethodFragment> get fragments {
    return [
      for (MethodFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  LibraryElement2 get library2 => _element2.library2;

  @override
  String? get lookupName => name3;

  @override
  String get name => declaration.name;

  @override
  String? get name3 => _element2.name3;

  @override
  Source get source => _declaration.source!;

  @override
  MethodElementImpl2 get _element2 => declaration.asElement2;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  /// If [definingType] has type parameters, returns [MethodMember] with
  /// type substitutions. Otherwise returns [element] as is.
  static MethodElement2OrMember from2(
    MethodElementImpl2 element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return MethodMember(
      declaration: element.asElement,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class ParameterMember extends VariableMember
    with ParameterElementMixin, FormalParameterElementMixin
    implements ParameterElement {
  @override
  final List<TypeParameterElement> typeParameters;

  factory ParameterMember({
    required ParameterElement declaration,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return ParameterMember._(
      declaration: declaration,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  /// Initialize a newly created element to represent a parameter, based on the
  /// [declaration], with applied [substitution].
  ParameterMember._({
    required ParameterElement super.declaration,
    required super.substitution,
    required this.typeParameters,
  });

  @override
  FormalParameterElement get baseElement => _element2;

  @override
  List<Element> get children => parameters;

  @override
  List<Element2> get children2 =>
      children.map((fragment) => fragment.asElement2).nonNulls.toList();

  @override
  ConstantInitializer? get constantInitializer2 {
    return baseElement.constantInitializer2;
  }

  @override
  ParameterElementImpl get declaration => _declaration as ParameterElementImpl;

  @override
  String? get defaultValueCode => declaration.defaultValueCode;

  @override
  FormalParameterElementImpl get element => declaration.element;

  @override
  Element2? get enclosingElement2 => _element2.enclosingElement2;

  @override
  Element? get enclosingElement3 => declaration.enclosingElement3;

  @override
  FormalParameterFragment get firstFragment => _element2.firstFragment;

  @override
  // TODO(brianwilkerson): This loses type information.
  List<FormalParameterElement> get formalParameters =>
      _element2.formalParameters;

  @override
  List<FormalParameterFragment> get fragments {
    return [
      for (FormalParameterFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isInitializingFormal => declaration.isInitializingFormal;

  @override
  bool get isSuperFormal => declaration.isSuperFormal;

  @override
  LibraryElement2? get library2 => _element2.library2;

  @override
  String? get lookupName => _element2.lookupName;

  @override
  String get name => declaration.name;

  @override
  String? get name3 => _element2.name3;

  @override
  String get nameShared => name;

  @override
  Element2 get nonSynthetic2 => _element2;

  @deprecated
  @override
  ParameterKind get parameterKind {
    return declaration.parameterKind;
  }

  @override
  List<ParameterElement> get parameters {
    var type = this.type;
    if (type is FunctionTypeImpl) {
      return type.parameters;
    }
    return const <ParameterElement>[];
  }

  @override
  Source? get source => _declaration.source;

  @override
  List<TypeParameterElement2> get typeParameters2 => _element2.typeParameters2;

  @override
  TypeImpl get typeShared => type;

  @override
  FormalParameterElement get _element2 => declaration.asElement2;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitParameterElement(this);

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFormalParameterElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  @override
  String displayString2(
      {bool multiline = false, bool preferTypeAlias = false}) {
    return _element2.displayString2(
        multiline: multiline, preferTypeAlias: preferTypeAlias);
  }

  @override
  bool isAccessibleIn2(LibraryElement2 library) =>
      _element2.isAccessibleIn2(library);

  @override
  Element2? thisOrAncestorMatching2(bool Function(Element2 p1) predicate) {
    return _element2.thisOrAncestorMatching2(predicate);
  }

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    return _element2.thisOrAncestorOfType2();
  }

  @override
  void visitChildren2<T>(ElementVisitor2<T> visitor) {
    _element2.visitChildren2(visitor);
  }

  static ParameterElementMixin from(
      ParameterElementMixin element, MapSubstitution substitution) {
    var combined = substitution;
    if (element is ParameterMember) {
      var member = element;
      element = member.declaration;

      var map = <TypeParameterElement2, DartType>{
        for (var MapEntry(:key, :value) in member.substitution.map.entries)
          key: substitution.substituteType(value),
      };
      combined = Substitution.fromMap2(map);
    }

    if (combined.map.isEmpty) {
      return element;
    }

    return ParameterMember(
      declaration: element,
      substitution: combined,
    );
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
abstract class PropertyAccessorMember extends ExecutableMember
    implements
        PropertyAccessorElementOrMember,
        PropertyAccessorElement2OrMember {
  factory PropertyAccessorMember({
    required PropertyAccessorElement declaration,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    if (declaration.isGetter) {
      return GetterMember._(
        declaration: declaration,
        substitution: freshTypeParameters.substitution,
        typeParameters: freshTypeParameters.elements,
      );
    } else {
      return SetterMember._(
        declaration: declaration,
        substitution: freshTypeParameters.substitution,
        typeParameters: freshTypeParameters.elements,
      );
    }
  }

  PropertyAccessorMember._({
    required PropertyAccessorElement super.declaration,
    required super.substitution,
    required super.typeParameters,
  });

  @override
  PropertyAccessorElement? get correspondingGetter {
    var baseGetter = declaration.correspondingGetter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
      declaration: baseGetter,
      substitution: substitution,
    );
  }

  @override
  PropertyAccessorElement? get correspondingSetter {
    var baseSetter = declaration.correspondingSetter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
      declaration: baseSetter,
      substitution: substitution,
    );
  }

  @override
  PropertyAccessorElementImpl get declaration =>
      _declaration as PropertyAccessorElementImpl;

  @override
  Element2 get enclosingElement2 {
    return super.enclosingElement2!;
  }

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  bool get isGetter => declaration.isGetter;

  @override
  bool get isSetter => declaration.isSetter;

  @override
  String get name => declaration.name;

  @override
  String? get name3 => _element2.name3;

  @override
  Source get source => _declaration.source!;

  @override
  PropertyInducingElementOrMember? get variable2 {
    // TODO(scheglov): revisit
    var variable = declaration.variable2;
    if (variable is FieldElementImpl) {
      return FieldMember(
        declaration: variable,
        substitution: substitution,
      );
    } else if (variable is TopLevelVariableElementImpl) {
      return variable;
    }
    return variable;
  }

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + displayName,
    );
  }

  /// If the given [accessor]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create an accessor member representing
  /// the given accessor. Return the member that was created, or the base
  /// accessor if no member was created.
  static PropertyAccessorElementOrMember? from(
      PropertyAccessorElementOrMember? accessor, InterfaceType definingType) {
    if (accessor == null || definingType.typeArguments.isEmpty) {
      return accessor;
    }

    return PropertyAccessorMember(
      declaration: accessor,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// A setter element defined in a parameterized type where the values of the
/// type parameters are known.
class SetterMember extends PropertyAccessorMember
    implements SetterElement2OrMember {
  SetterMember._({
    required super.declaration,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  SetterElement get baseElement => _element2;

  @override
  GetterElement? get correspondingGetter2 {
    var getter = correspondingGetter;
    if (getter is GetterMember) {
      return getter;
    }
    return getter.asElement2 as GetterElement?;
  }

  @override
  SetterFragment get firstFragment => _element2.firstFragment;

  @override
  List<SetterFragment> get fragments {
    return [
      for (SetterFragment? fragment = firstFragment;
          fragment != null;
          fragment = fragment.nextFragment)
        fragment,
    ];
  }

  @override
  String? get lookupName => _element2.lookupName;

  @override
  Element2 get nonSynthetic2 {
    if (!isSynthetic) {
      return this;
    } else if (variable3 case var variable?) {
      return variable.nonSynthetic2;
    }
    throw StateError('Synthetic setter has no variable');
  }

  @override
  PropertyInducingElement2OrMember? get variable3 =>
      variable2.asElement2 as PropertyInducingElement2OrMember?;

  @override
  SetterElement get _element2 => declaration.asElement2 as SetterElement;

  @override
  T? accept2<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  static SetterElement2OrMember from(
    SetterElementImpl element,
    InterfaceType definingType,
  ) {
    if (definingType.typeArguments.isEmpty) {
      return element;
    }

    return SetterMember._(
      declaration: element.asElement,
      substitution: Substitution.fromInterfaceType(definingType),
      typeParameters: const [],
    );
  }
}

class SuperFormalParameterMember extends ParameterMember
    implements SuperFormalParameterElement {
  factory SuperFormalParameterMember({
    required SuperFormalParameterElement declaration,
    required MapSubstitution substitution,
  }) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return SuperFormalParameterMember._(
      declaration: declaration,
      substitution: freshTypeParameters.substitution,
      typeParameters: freshTypeParameters.elements,
    );
  }

  SuperFormalParameterMember._({
    required SuperFormalParameterElement super.declaration,
    required super.substitution,
    required super.typeParameters,
  }) : super._();

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  ParameterElement? get superConstructorParameter {
    var superConstructorParameter =
        (declaration as SuperFormalParameterElementImpl)
            .superConstructorParameter;
    if (superConstructorParameter == null) {
      return null;
    }

    return ParameterMember.from(superConstructorParameter, substitution);
  }

  FormalParameterElement? get superConstructorParameter2 =>
      superConstructorParameter?.asElement2;

  @Deprecated('Use Element2 and accept2() instead')
  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitSuperFormalParameterElement(this);
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class VariableMember extends Member
    implements VariableElementOrMember {
  TypeImpl? _type;

  /// Initialize a newly created element to represent a variable, based on the
  /// [declaration], with applied [substitution].
  VariableMember({
    required VariableElement super.declaration,
    required super.substitution,
  });

  @override
  VariableElementImpl get declaration => _declaration as VariableElementImpl;

  @override
  bool get hasImplicitType => declaration.hasImplicitType;

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isFinal => declaration.isFinal;

  @override
  bool get isLate => declaration.isLate;

  @override
  bool get isStatic => declaration.isStatic;

  @override
  TypeImpl get type {
    if (_type != null) return _type!;

    var result = declaration.type;
    result = substitution.substituteType(result);
    return _type = result;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() => declaration.computeConstantValue();
}

class _SubstitutedTypeParameters {
  final List<TypeParameterElementImpl> elements;
  final MapSubstitution substitution;

  factory _SubstitutedTypeParameters(
    List<TypeParameterElement> elements,
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
      var element = elements[i];
      var newElement = TypeParameterElementImpl.synthetic(element.name);
      newElements.add(newElement);
      newTypes.add(
        newElement.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        ),
      );
    }

    // Update bounds to reference new TypeParameterElement(s).
    // TODO(scheglov): remove the cast
    var substitution2 = Substitution.fromPairs(elements.cast(), newTypes);
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
      Substitution.fromMap2({
        ...substitution.map,
        ...substitution2.map,
      }),
    );
  }

  _SubstitutedTypeParameters._(this.elements, this.substitution);
}
