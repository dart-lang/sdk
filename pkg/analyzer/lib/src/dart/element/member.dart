// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:pub_semver/pub_semver.dart';

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class ConstructorMember extends ExecutableMember
    with ConstructorElementMixin
    implements ConstructorElement, ConstructorElement2 {
  /// Initialize a newly created element to represent a constructor, based on
  /// the [declaration], and applied [substitution].
  ConstructorMember({
    required ConstructorElement declaration,
    required MapSubstitution augmentationSubstitution,
    required MapSubstitution substitution,
  }) : super(declaration, augmentationSubstitution, substitution,
            const <TypeParameterElement>[]);

  @override
  ConstructorElement? get augmentation {
    return declaration.augmentationTarget;
  }

  @override
  ConstructorElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  ConstructorElement2 get baseElement => _element2;

  @override
  ConstructorElement get declaration => super.declaration as ConstructorElement;

  @override
  String get displayName => declaration.displayName;

  @Deprecated('Use enclosingElement3 instead')
  @override
  InterfaceElement get enclosingElement => declaration.enclosingElement;

  @override
  InterfaceElement2 get enclosingElement2 => _element2.enclosingElement2;

  @override
  InterfaceElement get enclosingElement3 => declaration.enclosingElement3;

  @override
  ConstructorFragment? get firstFragment => _element2.firstFragment;

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isFactory => declaration.isFactory;

  @override
  String get name => declaration.name;

  @override
  int? get nameEnd => declaration.nameEnd;

  @override
  int? get periodOffset => declaration.periodOffset;

  @override
  ConstructorElement? get redirectedConstructor {
    var element = declaration.redirectedConstructor;
    return _from2(element);
  }

  @override
  ConstructorElement2? get redirectedConstructor2 =>
      redirectedConstructor.asElement2 as ConstructorElement2;

  @override
  InterfaceType get returnType => type.returnType as InterfaceType;

  @override
  Source get source => _declaration.source!;

  @override
  ConstructorElement? get superConstructor {
    var element = declaration.superConstructor;
    return _from2(element);
  }

  @override
  ConstructorElement2? get superConstructor2 =>
      superConstructor.asElement2 as ConstructorElement2;

  @override
  ConstructorElement2 get _element2 =>
      declaration.asElement2 as ConstructorElement2;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  ConstructorMember? _from2(ConstructorElement? element) {
    if (element == null) {
      return null;
    }

    ConstructorElement declaration;
    MapSubstitution substitution;
    if (element is ConstructorMember) {
      declaration = element._declaration as ConstructorElement;
      var map = <TypeParameterElement, DartType>{};
      var elementMap = element._substitution.map;
      for (var typeParameter in elementMap.keys) {
        var type = elementMap[typeParameter]!;
        map[typeParameter] = _substitution.substituteType(type);
      }
      substitution = Substitution.fromMap(map);
    } else {
      declaration = element;
      substitution = _substitution;
    }

    return ConstructorMember(
      declaration: declaration,
      augmentationSubstitution: augmentationSubstitution,
      substitution: substitution,
    );
  }

  /// If the given [constructor]'s type is different when any type parameters
  /// from the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a constructor member
  /// representing the given constructor. Return the member that was created, or
  /// the original constructor if no member was created.
  static ConstructorElement from(
      ConstructorElement constructor, InterfaceType definingType) {
    if (definingType.typeArguments.isEmpty) {
      return constructor;
    }

    var augmentationSubstitution = Substitution.empty;
    if (constructor is ConstructorMember) {
      augmentationSubstitution = constructor.augmentationSubstitution;
      constructor = constructor.declaration;
    }

    return ConstructorMember(
      declaration: constructor,
      augmentationSubstitution: augmentationSubstitution,
      substitution: Substitution.fromInterfaceType(definingType),
    );
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class ExecutableMember extends Member
    implements ExecutableElement, ExecutableElement2 {
  @override
  final List<TypeParameterElement> typeParameters;

  FunctionType? _type;

  /// Initialize a newly created element to represent a callable element (like a
  /// method or function or property), based on the [declaration], and applied
  /// [substitution].
  ///
  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [declaration] type
  /// parameters with the provided fresh [typeParameters].
  ExecutableMember(
    ExecutableElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    this.typeParameters,
  );

  @override
  List<Element> get children => parameters;

  @override
  List<Element2> get children2 =>
      children.map((fragment) => fragment.asElement2).nonNulls.toList();

  @override
  ExecutableElement get declaration => super.declaration as ExecutableElement;

  @override
  String get displayName => declaration.displayName;

  @override
  Element2? get enclosingElement2 => _element2.enclosingElement2;

  @override
  List<FormalParameterElement> get formalParameters => parameters
      .map((fragment) => fragment.asElement2 as FormalParameterElement?)
      .nonNulls
      .toList();

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
  LibraryElement2? get library2 => _element2.library2;

  @override
  Source get librarySource => _declaration.librarySource!;

  @override
  int get nameOffset => declaration.nameOffset;

  @override
  Element2 get nonSynthetic2 => _element2;

  @override
  List<ParameterElement> get parameters {
    return declaration.parameters.map<ParameterElement>((p) {
      if (p is FieldFormalParameterElement) {
        return FieldFormalParameterMember(
            p, augmentationSubstitution, _substitution);
      }
      if (p is SuperFormalParameterElement) {
        return SuperFormalParameterMember(
            p, augmentationSubstitution, _substitution);
      }
      return ParameterMember(p, augmentationSubstitution, _substitution);
    }).toList();
  }

  @override
  DartType get returnType {
    var result = declaration.returnType;
    result = augmentationSubstitution.substituteType(result);
    result = _substitution.substituteType(result);
    return result;
  }

  @override
  FunctionType get type {
    if (_type != null) return _type!;

    _type = _substitution.substituteType(declaration.type) as FunctionType;
    return _type!;
  }

  @override
  List<TypeParameterElement2> get typeParameters2 => typeParameters
      .map((fragment) => fragment.asElement2 as TypeParameterElement2?)
      .nonNulls
      .toList();

  ExecutableElement2 get _element2 =>
      declaration.asElement2 as ExecutableElement2;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
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
  E? thisOrAncestorMatching2<E extends Element2>(
          bool Function(Element2 p1) predicate) =>
      _element2.thisOrAncestorMatching2(predicate);

  @override
  E? thisOrAncestorOfType2<E extends Element2>() =>
      _element2.thisOrAncestorOfType2();

  static ExecutableElement from2(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    var augmentationSubstitution = Substitution.empty;
    var combined = substitution;
    if (element is ExecutableMember) {
      ExecutableMember member = element;
      element = member.declaration;

      augmentationSubstitution = member.augmentationSubstitution;

      var map = <TypeParameterElement, DartType>{};
      for (var entry in member._substitution.map.entries) {
        map[entry.key] = substitution.substituteType(entry.value);
      }
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    }

    if (augmentationSubstitution.map.isEmpty && combined.map.isEmpty) {
      return element;
    }

    if (element is ConstructorElement) {
      return ConstructorMember(
        declaration: element,
        augmentationSubstitution: augmentationSubstitution,
        substitution: combined,
      );
    } else if (element is MethodElement) {
      return MethodMember(element, augmentationSubstitution, combined);
    } else if (element is PropertyAccessorElement) {
      return PropertyAccessorMember(
          element, augmentationSubstitution, combined);
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }

  static ExecutableElement fromAugmentation(
    ExecutableElement element,
    MapSubstitution augmentationSubstitution,
  ) {
    if (augmentationSubstitution.map.isEmpty) {
      return element;
    }

    if (element is ConstructorElement) {
      return ConstructorMember(
        declaration: element,
        augmentationSubstitution: augmentationSubstitution,
        substitution: Substitution.empty,
      );
    } else if (element is MethodElement) {
      return MethodMember(
          element, augmentationSubstitution, Substitution.empty);
    } else if (element is PropertyAccessorElement) {
      return PropertyAccessorMember(
          element, augmentationSubstitution, Substitution.empty);
    } else {
      throw UnimplementedError('(${element.runtimeType}) $element');
    }
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class FieldFormalParameterMember extends ParameterMember
    implements FieldFormalParameterElement {
  factory FieldFormalParameterMember(
    FieldFormalParameterElement declaration,
    MapSubstitution augmentationSubstitution,
    MapSubstitution substitution,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return FieldFormalParameterMember._(
      declaration,
      augmentationSubstitution,
      freshTypeParameters.substitution,
      freshTypeParameters.elements,
    );
  }

  FieldFormalParameterMember._(
    FieldFormalParameterElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  ) : super._();

  @override
  FieldElement? get field {
    var field = (declaration as FieldFormalParameterElement).field;
    if (field == null) {
      return null;
    }

    return FieldMember(field, augmentationSubstitution, _substitution);
  }

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class FieldMember extends VariableMember
    implements FieldElement, FieldElement2 {
  /// Initialize a newly created element to represent a field, based on the
  /// [declaration], with applied [substitution].
  FieldMember(
    FieldElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
  );

  @override
  FieldElement? get augmentation {
    return declaration.augmentationTarget;
  }

  @override
  FieldElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  FieldElement2 get baseElement => _element2;

  @override
  List<Element2> get children2 =>
      children.map((fragment) => fragment.asElement2).nonNulls.toList();

  @override
  FieldElement get declaration => super.declaration as FieldElement;

  @override
  String get displayName => declaration.displayName;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  Element2? get enclosingElement2 => _element2.enclosingElement2;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  FieldFragment? get firstFragment => _element2.firstFragment;

  @override
  PropertyAccessorElement? get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseGetter, augmentationSubstitution, _substitution);
  }

  @override
  GetterElement? get getter2 {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return GetterMember._(baseGetter, augmentationSubstitution, _substitution,
        baseGetter.typeParameters);
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
  LibraryElement2? get library2 => _element2.library2;

  @override
  String get name => declaration.name;

  @override
  Element2 get nonSynthetic2 => _element2.nonSynthetic2;

  @override
  PropertyAccessorElement? get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseSetter, augmentationSubstitution, _substitution);
  }

  @override
  SetterElement? get setter2 {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return SetterMember._(baseSetter, augmentationSubstitution, _substitution,
        baseSetter.typeParameters);
  }

  @override
  Source? get source => _declaration.source;

  FieldElement2 get _element2 => declaration.asElement2 as FieldElement2;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

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
  E? thisOrAncestorMatching2<E extends Element2>(
      bool Function(Element2 e) predicate) {
    return _element2.thisOrAncestorMatching2(predicate);
  }

  @override
  E? thisOrAncestorOfType2<E extends Element2>() {
    return _element2.thisOrAncestorOfType2<E>();
  }

  /// If the given [field]'s type is different when any type parameters from the
  /// defining type's declaration are replaced with the actual type arguments
  /// from the [definingType], create a field member representing the given
  /// field. Return the member that was created, or the base field if no member
  /// was created.
  static FieldElement from(FieldElement field, InterfaceType definingType) {
    if (definingType.typeArguments.isEmpty) {
      return field;
    }
    return FieldMember(
      field,
      field is FieldMember
          ? field.augmentationSubstitution
          : Substitution.empty,
      Substitution.fromInterfaceType(definingType),
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
      element,
      element is FieldMember
          ? element.augmentationSubstitution
          : Substitution.empty,
      substitution,
    );
  }

  static FieldElement fromAugmentation(
    FieldElement element,
    MapSubstitution augmentationSubstitution,
  ) {
    if (augmentationSubstitution.map.isEmpty) {
      return element;
    }
    return FieldMember(element, augmentationSubstitution, Substitution.empty);
  }
}

@Deprecated('There is no way to create an instance of this class')
class FunctionMember extends ExecutableMember implements FunctionElement {
  FunctionMember(FunctionElement declaration)
      : super(
          declaration,
          Substitution.empty,
          Substitution.empty,
          declaration.typeParameters,
        );

  @override
  FunctionElement? get augmentation {
    return declaration.augmentationTarget;
  }

  @override
  FunctionElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  ExecutableElement2 get baseElement => throw UnimplementedError();

  @override
  FunctionElement get declaration => super.declaration as FunctionElement;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  bool get isDartCoreIdentical => declaration.isDartCoreIdentical;

  @override
  bool get isEntryPoint => declaration.isEntryPoint;

  @override
  String get name => declaration.name;

  @override
  Source get source => _declaration.source!;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitFunctionElement(this);
  }
}

/// A getter element defined in a parameterized type where the values of the
/// type parameters are known.
class GetterMember extends PropertyAccessorMember implements GetterElement {
  GetterMember._(
    super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  ) : super._();

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
  GetterFragment? get firstFragment => _element2.firstFragment;

  @override
  PropertyInducingElement2? get variable3 =>
      variable2.asElement2 as PropertyInducingElement2?;

  @override
  GetterElement get _element2 => declaration.asElement2 as GetterElement;
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class Member implements Element {
  /// The element on which the parameterized element was created.
  final Element _declaration;

  final MapSubstitution augmentationSubstitution;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution _substitution;

  /// Initialize a newly created element to represent a member, based on the
  /// [declaration], and applied [_substitution].
  Member(this._declaration, this.augmentationSubstitution, this._substitution) {
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
  Element get declaration => _declaration;

  @override
  String get displayName => _declaration.displayName;

  @override
  String? get documentationComment => _declaration.documentationComment;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element? get enclosingElement => _declaration.enclosingElement;

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

  /// The substitution for type parameters referenced in the base element.
  MapSubstitution get substitution => _substitution;

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
    implements MethodElement, MethodElement2 {
  factory MethodMember(
    MethodElement declaration,
    MapSubstitution augmentationSubstitution,
    MapSubstitution substitution,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return MethodMember._(
      declaration,
      augmentationSubstitution,
      freshTypeParameters.substitution,
      freshTypeParameters.elements,
    );
  }

  MethodMember._(
    MethodElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  );

  @override
  MethodElement? get augmentation {
    // TODO(scheglov): implement
    throw UnimplementedError();
  }

  @override
  MethodElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  MethodElement2 get baseElement => _element2;

  @override
  MethodElement get declaration => super.declaration as MethodElement;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  MethodFragment? get firstFragment => _element2.firstFragment;

  @override
  String get name => declaration.name;

  @override
  Source get source => _declaration.source!;

  @override
  MethodElement2 get _element2 => declaration.asElement2 as MethodElement2;

  @override
  T? accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  /// If the given [method]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a method member representing the
  /// given method. Return the member that was created, or the base method if no
  /// member was created.
  static MethodElement? from(
      MethodElement? method, InterfaceType definingType) {
    if (method == null || definingType.typeArguments.isEmpty) {
      return method;
    }

    return MethodMember(
      method,
      method is MethodMember
          ? method.augmentationSubstitution
          : Substitution.empty,
      Substitution.fromInterfaceType(definingType),
    );
  }

  static MethodElement from2(
    MethodElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return MethodMember(
      element,
      element is MethodMember
          ? element.augmentationSubstitution
          : Substitution.empty,
      substitution,
    );
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class ParameterMember extends VariableMember
    with ParameterElementMixin
    implements ParameterElement {
  @override
  final List<TypeParameterElement> typeParameters;

  factory ParameterMember(
    ParameterElement declaration,
    MapSubstitution augmentationSubstitution,
    MapSubstitution substitution,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return ParameterMember._(
      declaration,
      augmentationSubstitution,
      freshTypeParameters.substitution,
      freshTypeParameters.elements,
    );
  }

  /// Initialize a newly created element to represent a parameter, based on the
  /// [declaration], with applied [substitution].
  ParameterMember._(
    ParameterElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    this.typeParameters,
  );

  @override
  List<Element> get children => parameters;

  @override
  ParameterElement get declaration => super.declaration as ParameterElement;

  @override
  String? get defaultValueCode => declaration.defaultValueCode;

  @override
  // TODO(scheglov): we lose types
  FormalParameterElement get element => declaration.element;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element? get enclosingElement => declaration.enclosingElement;

  @override
  Element? get enclosingElement3 => declaration.enclosingElement3;

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isInitializingFormal => declaration.isInitializingFormal;

  @override
  bool get isSuperFormal => declaration.isSuperFormal;

  @override
  String get name => declaration.name;

  @deprecated
  @override
  ParameterKind get parameterKind {
    return declaration.parameterKind;
  }

  @override
  List<ParameterElement> get parameters {
    var type = this.type;
    if (type is FunctionType) {
      return type.parameters;
    }
    return const <ParameterElement>[];
  }

  @override
  Source? get source => _declaration.source;

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  static ParameterElement from(
      ParameterElement element, MapSubstitution substitution) {
    var combined = substitution;
    if (element is ParameterMember) {
      var member = element;
      element = member.declaration;

      var map = <TypeParameterElement, DartType>{};
      for (var entry in member._substitution.map.entries) {
        map[entry.key] = substitution.substituteType(entry.value);
      }
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    }

    if (combined.map.isEmpty) {
      return element;
    }

    return ParameterMember(
      element,
      element is ParameterMember
          ? element.augmentationSubstitution
          : Substitution.empty,
      combined,
    );
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
abstract class PropertyAccessorMember extends ExecutableMember
    implements PropertyAccessorElement {
  factory PropertyAccessorMember(
    PropertyAccessorElement declaration,
    MapSubstitution augmentationSubstitution,
    MapSubstitution substitution,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    if (declaration.isGetter) {
      return GetterMember._(
        declaration,
        augmentationSubstitution,
        freshTypeParameters.substitution,
        freshTypeParameters.elements,
      );
    } else {
      return SetterMember._(
        declaration,
        augmentationSubstitution,
        freshTypeParameters.substitution,
        freshTypeParameters.elements,
      );
    }
  }

  PropertyAccessorMember._(
    PropertyAccessorElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  );

  @override
  PropertyAccessorElement? get augmentation {
    return declaration.augmentation;
  }

  @override
  PropertyAccessorElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  PropertyAccessorElement? get correspondingGetter {
    var baseGetter = declaration.correspondingGetter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseGetter, augmentationSubstitution, _substitution);
  }

  @override
  PropertyAccessorElement? get correspondingSetter {
    var baseSetter = declaration.correspondingSetter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseSetter, augmentationSubstitution, _substitution);
  }

  @override
  PropertyAccessorElement get declaration =>
      super.declaration as PropertyAccessorElement;

  @Deprecated('Use enclosingElement3 instead')
  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  Element get enclosingElement3 => declaration.enclosingElement3;

  @override
  bool get isGetter => declaration.isGetter;

  @override
  bool get isSetter => declaration.isSetter;

  @override
  String get name => declaration.name;

  @override
  Source get source => _declaration.source!;

  @override
  PropertyInducingElement get variable {
    return variable2!;
  }

  @override
  PropertyInducingElement? get variable2 {
    // TODO(scheglov): revisit
    var variable = declaration.variable2;
    if (variable is FieldElement) {
      return FieldMember(variable, augmentationSubstitution, _substitution);
    } else if (variable is TopLevelVariableElement) {
      return TopLevelVariableMember(
          variable, augmentationSubstitution, _substitution);
    }
    return variable;
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitPropertyAccessorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(
      this,
      (isGetter ? 'get ' : 'set ') + variable.displayName,
    );
  }

  /// If the given [accessor]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create an accessor member representing
  /// the given accessor. Return the member that was created, or the base
  /// accessor if no member was created.
  static PropertyAccessorElement? from(
      PropertyAccessorElement? accessor, InterfaceType definingType) {
    if (accessor == null || definingType.typeArguments.isEmpty) {
      return accessor;
    }

    return PropertyAccessorMember(
      accessor,
      accessor is PropertyAccessorMember
          ? accessor.augmentationSubstitution
          : Substitution.empty,
      Substitution.fromInterfaceType(definingType),
    );
  }
}

/// A setter element defined in a parameterized type where the values of the
/// type parameters are known.
class SetterMember extends PropertyAccessorMember implements SetterElement {
  SetterMember._(
    super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  ) : super._();

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
  SetterFragment? get firstFragment => _element2.firstFragment;

  @override
  PropertyInducingElement2? get variable3 =>
      variable2.asElement2 as PropertyInducingElement2?;

  @override
  SetterElement get _element2 => declaration.asElement2 as SetterElement;
}

class SuperFormalParameterMember extends ParameterMember
    implements SuperFormalParameterElement {
  factory SuperFormalParameterMember(
    SuperFormalParameterElement declaration,
    MapSubstitution augmentationSubstitution,
    MapSubstitution substitution,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return SuperFormalParameterMember._(
      declaration,
      augmentationSubstitution,
      freshTypeParameters.substitution,
      freshTypeParameters.elements,
    );
  }

  SuperFormalParameterMember._(
    SuperFormalParameterElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
    super.typeParameters,
  ) : super._();

  @override
  bool get hasDefaultValue => declaration.hasDefaultValue;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  ParameterElement? get superConstructorParameter {
    var superConstructorParameter =
        (declaration as SuperFormalParameterElement).superConstructorParameter;
    if (superConstructorParameter == null) {
      return null;
    }

    return ParameterMember.from(superConstructorParameter, substitution);
  }

  @override
  T? accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitSuperFormalParameterElement(this);
}

class TopLevelVariableMember extends VariableMember
    implements TopLevelVariableElement {
  TopLevelVariableMember(
    super.declaration,
    super.augmentationSubstitution,
    super.substitution,
  );

  @override
  TopLevelVariableElement? get augmentation {
    return declaration.augmentationTarget;
  }

  @override
  TopLevelVariableElement? get augmentationTarget {
    return declaration.augmentationTarget;
  }

  @override
  TopLevelVariableElement get declaration =>
      _declaration as TopLevelVariableElement;

  @override
  String get displayName => declaration.displayName;

  @override
  PropertyAccessorElement? get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseGetter, augmentationSubstitution, _substitution);
  }

  @override
  bool get hasInitializer => declaration.hasInitializer;

  @override
  bool get isAugmentation => declaration.isAugmentation;

  @override
  bool get isExternal => declaration.isExternal;

  @override
  LibraryElement get library => _declaration.library!;

  @override
  String get name => declaration.name;

  @override
  PropertyAccessorElement? get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(
        baseSetter, augmentationSubstitution, _substitution);
  }

  @override
  Source get source => _declaration.source!;

  @override
  T? accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTopLevelVariableElement(this);
  }
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class VariableMember extends Member implements VariableElement {
  DartType? _type;

  /// Initialize a newly created element to represent a variable, based on the
  /// [declaration], with applied [substitution].
  VariableMember(
    VariableElement super.declaration,
    super.augmentationSubstitution,
    super.substitution,
  );

  @override
  VariableElement get declaration => super.declaration as VariableElement;

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
  DartType get type {
    if (_type != null) return _type!;

    var result = declaration.type;
    result = augmentationSubstitution.substituteType(result);
    result = _substitution.substituteType(result);
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
  final List<TypeParameterElement> elements;
  final MapSubstitution substitution;

  factory _SubstitutedTypeParameters(
    List<TypeParameterElement> elements,
    MapSubstitution substitution,
  ) {
    if (elements.isEmpty) {
      return _SubstitutedTypeParameters._(elements, substitution);
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    var newElements = <TypeParameterElement>[];
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
    var substitution2 = Substitution.fromPairs(elements, newTypes);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var newElement = newElements[i] as TypeParameterElementImpl;
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
      Substitution.fromMap({
        ...substitution.map,
        ...substitution2.map,
      }),
    );
  }

  _SubstitutedTypeParameters._(this.elements, this.substitution);
}
