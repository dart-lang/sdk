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
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:pub_semver/pub_semver.dart';

/// A member of the interface of [owner], with a combined member signature that
/// is not the signature of any inherited member.
///
/// This member is a view of the [candidate], the first most specific inherited
/// member. The combined member signature can differ from its signature by
/// types, when the most specific members have different types that are
/// subtypes of each other, such as `Future<void>` and `Future<dynamic>`, and
/// by covariance of formal parameters, when another inherited member has them
/// covariant.
///
/// The type and the formal parameters are from the combined member signature.
/// Everything else, such as metadata, documentation, and the enclosing
/// element, is from the declaration of the candidate.
sealed class CombinedExecutableElementImpl
    extends DelegatingExecutableElementImpl {
  /// The interface element whose interface has this member.
  final InterfaceElementImpl owner;

  /// The inherited member that this member is a view of, with the type
  /// parameters of [owner].
  final InternalExecutableElement candidate;

  /// The combined member signature, with the type parameters of [owner].
  final FunctionTypeImpl signature;

  /// The substitution for the type parameters of [owner].
  final MapSubstitution substitution;

  FunctionTypeImpl? _type;
  List<InternalFormalParameterElement>? _formalParameters;

  factory forCandidate({
    required InterfaceElementImpl owner,
    required InternalExecutableElement candidate,
    required FunctionTypeImpl signature,
  }) {
    switch (candidate) {
      case InternalGetterElement():
        return CombinedGetterElementImpl._(
          owner: owner,
          candidate: candidate,
          signature: signature,
          substitution: Substitution.empty,
        );
      case InternalMethodElement():
        return CombinedMethodElementImpl._(
          owner: owner,
          candidate: candidate,
          signature: signature,
          substitution: Substitution.empty,
        );
      case InternalSetterElement():
        return CombinedSetterElementImpl._(
          owner: owner,
          candidate: candidate,
          signature: signature,
          substitution: Substitution.empty,
        );
      default:
        throw StateError('${candidate.runtimeType}');
    }
  }

  new _({
    required this.owner,
    required this.candidate,
    required this.signature,
    required this.substitution,
  }) : super(baseElement: candidate.baseElement);

  @override
  List<InternalFormalParameterElement> get formalParameters {
    if (_formalParameters case var formalParameters?) {
      return formalParameters;
    }
    _buildType();
    return _formalParameters!;
  }

  /// For an implicit getter or setter, this is its field.
  @override
  Element get nonSynthetic => baseElement.nonSynthetic;

  @override
  TypeImpl get returnType => type.returnType;

  @override
  FunctionTypeImpl get type => _type ?? _buildType();

  @override
  List<TypeParameterElementImpl> get typeParameters => type.typeParameters;

  /// Builds [type] and [formalParameters].
  ///
  /// The formal parameters are views of the formal parameters of the
  /// candidate, so they keep its metadata, but with the types and covariance
  /// from the combined member signature. They are also the formal parameters
  /// of [type], as for declarations.
  FunctionTypeImpl _buildType() {
    var signature = substitution.mapFunctionType(this.signature);
    var signatureFormalParameters = signature.formalParameters;
    var candidateFormalParameters = candidate.formalParameters;
    var formalParameters = _formalParameters = List.generate(
      candidateFormalParameters.length,
      (index) {
        var candidateFormalParameter = candidateFormalParameters[index];
        // The signature has the same shape as the candidate.
        var signatureFormalParameter = signatureFormalParameters
            .correspondingFormalParameter(candidateFormalParameter, index)!;
        return CombinedFormalParameterElementImpl(
          baseElement: candidateFormalParameter.baseElement,
          type: signatureFormalParameter.type,
          isCovariant: signatureFormalParameter.isCovariant,
        );
      },
      growable: false,
    );
    return _type = FunctionTypeImpl(
      typeParameters: signature.typeParameters,
      formalParameters: formalParameters,
      returnType: signature.returnType,
      nullabilitySuffix: signature.nullabilitySuffix,
    );
  }

  /// Returns the substitution to use for this member substituted with
  /// [substitution].
  MapSubstitution _substitutionThen(MapSubstitution substitution) {
    // The empty substitution ignores `andThen`.
    if (this.substitution.map.isEmpty) {
      return substitution;
    }
    return this.substitution.andThen(substitution);
  }
}

/// The field of a [CombinedPropertyAccessorElementImpl].
///
/// The [accessor] is its getter or setter, and the type is from the combined
/// member signature of the [accessor]. Everything else is from the field of
/// the declaration.
///
/// The getter and the setter of a property are combined separately, so each
/// of them has its own field.
class CombinedFieldElementImpl extends DelegatingFieldElementImpl {
  /// The getter or setter of this field.
  final CombinedPropertyAccessorElementImpl accessor;

  new({required this.accessor, required super.baseElement});

  @override
  InternalGetterElement? get getter {
    return switch (accessor) {
      CombinedGetterElementImpl accessor => accessor,
      CombinedSetterElementImpl accessor => accessor.correspondingGetter,
    };
  }

  @override
  InternalSetterElement? get setter {
    return switch (accessor) {
      CombinedGetterElementImpl accessor => accessor.correspondingSetter,
      CombinedSetterElementImpl accessor => accessor,
    };
  }

  @override
  TypeImpl get type {
    return switch (accessor) {
      CombinedGetterElementImpl accessor => accessor.returnType,
      CombinedSetterElementImpl accessor =>
        accessor.formalParameters.firstOrNull?.type ?? InvalidTypeImpl.instance,
    };
  }

  @override
  InternalFieldElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    var accessor = switch (this.accessor) {
      CombinedGetterElementImpl accessor => accessor.substitute(substitution),
      CombinedSetterElementImpl accessor => accessor.substitute(substitution),
    };
    return accessor.variable as InternalFieldElement;
  }
}

/// A formal parameter of a [CombinedExecutableElementImpl].
///
/// The type and covariance are from the combined member signature. Everything
/// else is from the declaration.
class CombinedFormalParameterElementImpl
    extends DelegatingFormalParameterElementImpl {
  @override
  final TypeImpl type;

  @override
  final bool isCovariant;

  new({
    required super.baseElement,
    required this.type,
    required this.isCovariant,
  });

  @override
  InternalFormalParameterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return CombinedFormalParameterElementImpl(
      baseElement: baseElement,
      type: substitution.substituteType(type),
      isCovariant: isCovariant,
    );
  }
}

/// A getter with a combined member signature, see
/// [CombinedExecutableElementImpl].
class CombinedGetterElementImpl extends CombinedPropertyAccessorElementImpl
    with InternalGetterElement {
  new _({
    required super.owner,
    required InternalGetterElement super.candidate,
    required super.signature,
    required super.substitution,
  }) : super._();

  @override
  GetterElementImpl get baseElement => _candidate.baseElement;

  @override
  InternalSetterElement? get correspondingSetter {
    return _candidate.variable.setter?.substitute(substitution);
  }

  @override
  GetterFragmentImpl get firstFragment => _candidate.firstFragment;

  @override
  List<GetterFragmentImpl> get fragments => _candidate.fragments;

  @override
  InternalGetterElement get _candidate => candidate as InternalGetterElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, 'get $displayName');
  }

  @override
  CombinedGetterElementImpl substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return CombinedGetterElementImpl._(
      owner: owner,
      candidate: _candidate,
      signature: signature,
      substitution: _substitutionThen(substitution),
    );
  }
}

/// A method with a combined member signature, see
/// [CombinedExecutableElementImpl].
class CombinedMethodElementImpl extends CombinedExecutableElementImpl
    with InternalMethodElement {
  new _({
    required super.owner,
    required InternalMethodElement super.candidate,
    required super.signature,
    required super.substitution,
  }) : super._();

  @override
  MethodElementImpl get baseElement => _candidate.baseElement;

  @override
  MethodFragmentImpl get firstFragment => _candidate.firstFragment;

  @override
  List<MethodFragmentImpl> get fragments => _candidate.fragments;

  @override
  bool get isOperator => _candidate.isOperator;

  @override
  bool get isOriginDeclaration => false;

  @override
  bool get isOriginInterface => true;

  InternalMethodElement get _candidate => candidate as InternalMethodElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  @override
  InternalMethodElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return CombinedMethodElementImpl._(
      owner: owner,
      candidate: _candidate,
      signature: signature,
      substitution: _substitutionThen(substitution),
    );
  }
}

/// A getter or setter with a combined member signature, see
/// [CombinedExecutableElementImpl].
sealed class CombinedPropertyAccessorElementImpl
    extends CombinedExecutableElementImpl
    with InternalPropertyAccessorElement {
  InternalPropertyInducingElement? _variable;

  new _({
    required super.owner,
    required InternalPropertyAccessorElement super.candidate,
    required super.signature,
    required super.substitution,
  }) : super._();

  @override
  PropertyAccessorElementImpl get baseElement => _candidate.baseElement;

  @override
  Element get enclosingElement => _candidate.enclosingElement;

  @override
  PropertyAccessorFragmentImpl get firstFragment => _candidate.firstFragment;

  @override
  List<PropertyAccessorFragmentImpl> get fragments => _candidate.fragments;

  @override
  bool get isOriginDeclaration => false;

  @override
  bool get isOriginInterface => true;

  @override
  bool get isOriginVariable => false;

  @override
  InternalPropertyInducingElement get variable {
    if (_variable case var variable?) {
      return variable;
    }
    var variable = _candidate.variable;
    if (variable.baseElement case FieldElementImpl baseElement) {
      return _variable = CombinedFieldElementImpl(
        accessor: this,
        baseElement: baseElement,
      );
    }
    return _variable = variable;
  }

  InternalPropertyAccessorElement get _candidate {
    return candidate as InternalPropertyAccessorElement;
  }
}

/// A setter with a combined member signature, see
/// [CombinedExecutableElementImpl].
class CombinedSetterElementImpl extends CombinedPropertyAccessorElementImpl
    with InternalSetterElement {
  new _({
    required super.owner,
    required InternalSetterElement super.candidate,
    required super.signature,
    required super.substitution,
  }) : super._();

  @override
  SetterElementImpl get baseElement => _candidate.baseElement;

  @override
  InternalGetterElement? get correspondingGetter {
    return _candidate.variable.getter?.substitute(substitution);
  }

  @override
  SetterFragmentImpl get firstFragment => _candidate.firstFragment;

  @override
  List<SetterFragmentImpl> get fragments => _candidate.fragments;

  @override
  InternalSetterElement get _candidate => candidate as InternalSetterElement;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, 'set $displayName');
  }

  @override
  CombinedSetterElementImpl substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return CombinedSetterElementImpl._(
      owner: owner,
      candidate: _candidate,
      signature: signature,
      substitution: _substitutionThen(substitution),
    );
  }
}

/// An element that is a view of the declaration [baseElement].
///
/// The properties that do not depend on types are from the declaration.
sealed class DelegatingElementImpl implements Element {
  @override
  final ElementImpl baseElement;

  new({required this.baseElement});

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
  ElementKind get kind => baseElement.kind;

  @override
  String? get lookupName => baseElement.lookupName;

  @override
  String? get name => baseElement.name;

  @override
  Element get nonSynthetic => baseElement;

  @override
  AnalysisSession? get session => baseElement.session;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  String getExtendedDisplayName({String? shortName}) {
    return baseElement.getExtendedDisplayName(shortName: shortName);
  }

  @override
  bool isAccessibleIn(LibraryElement library) {
    return baseElement.isAccessibleIn(library);
  }

  @override
  bool isDeprecatedWithKind(String kind) =>
      baseElement.isDeprecatedWithKind(kind);

  @override
  Element? thisOrAncestorMatching(bool Function(Element e) predicate) {
    return baseElement.thisOrAncestorMatching(predicate);
  }

  @override
  E? thisOrAncestorOfType<E extends Element>() {
    return baseElement.thisOrAncestorOfType<E>();
  }

  @override
  String toString() {
    var builder = ElementDisplayStringBuilder(preferTypeAlias: false);
    appendTo(builder);
    return builder.toString();
  }
}

/// An executable element that is a view of the declaration [baseElement].
sealed class DelegatingExecutableElementImpl extends DelegatingElementImpl
    with InternalExecutableElement {
  new({required ExecutableElementImpl super.baseElement});

  @override
  List<Element> get children {
    return [...typeParameters, ...formalParameters];
  }

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => baseElement.enclosingElement;

  @override
  ExecutableFragmentImpl get firstFragment;

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

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  String displayString({
    bool multiline = false,
    bool preferTypeAlias = false,
    bool includePositionalParameterNames = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
      includePositionalParameterNames: includePositionalParameterNames,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    for (var child in children) {
      child.accept(visitor);
    }
  }
}

/// A field element that is a view of the declaration [baseElement].
sealed class DelegatingFieldElementImpl extends DelegatingVariableElementImpl
    with InternalPropertyInducingElement, InternalFieldElement {
  new({required FieldElementImpl super.baseElement});

  @override
  FieldElementImpl get baseElement => super.baseElement as FieldElementImpl;

  @override
  List<Element> get children => const [];

  @override
  FieldFormalParameterElementImpl? get declaringFormalParameter {
    return baseElement.declaringFormalParameter;
  }

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  InstanceElement get enclosingElement => baseElement.enclosingElement;

  @override
  FieldFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<FieldFragmentImpl> get fragments {
    return baseElement.fragments;
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
  bool get isOriginDeclaration => baseElement.isOriginDeclaration;

  @override
  bool get isOriginDeclaringFormalParameter =>
      baseElement.isOriginDeclaringFormalParameter;

  @override
  bool get isOriginEnumValues => baseElement.isOriginEnumValues;

  @override
  bool get isOriginExtensionTypeRecoveryRepresentation =>
      baseElement.isOriginExtensionTypeRecoveryRepresentation;

  @override
  bool get isOriginGetterSetter => baseElement.isOriginGetterSetter;

  @override
  bool get isPromotable => baseElement.isPromotable;

  @override
  LibraryElementImpl get library => baseElement.library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @override
  Version? get sinceSdkVersion => baseElement.sinceSdkVersion;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFieldElement(this);
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {}
}

/// A formal parameter element that is a view of the declaration
/// [baseElement].
sealed class DelegatingFormalParameterElementImpl
    extends DelegatingVariableElementImpl
    with InternalFormalParameterElement {
  new({required FormalParameterElementImpl super.baseElement});

  @override
  FormalParameterElementImpl get baseElement =>
      super.baseElement as FormalParameterElementImpl;

  @override
  List<Element> get children => [];

  @override
  String? get defaultValueCode => baseElement.defaultValueCode;

  @override
  String? get documentationComment => baseElement.documentationComment;

  @override
  Element? get enclosingElement => baseElement.enclosingElement;

  @override
  FormalParameterFragmentImpl get firstFragment => baseElement.firstFragment;

  @Deprecated('Use the function type of this parameter instead')
  @override
  List<FormalParameterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  bool get isCovariant => baseElement.isCovariant;

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
  LibraryElement? get library => baseElement.library;

  @override
  MetadataImpl get metadata => baseElement.metadata;

  @override
  String get nameShared => name!;

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
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitFormalParameterElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameterElement(this);
  }

  @override
  void visitChildren<T>(ElementVisitor2<T> visitor) {
    baseElement.visitChildren(visitor);
  }
}

/// A variable element that is a view of the declaration [baseElement].
sealed class DelegatingVariableElementImpl extends DelegatingElementImpl
    with InternalVariableElement {
  new({required VariableElementImpl super.baseElement});

  @override
  VariableElementImpl get baseElement =>
      super.baseElement as VariableElementImpl;

  @V1Ast('The V2 counterpart is constantInitializer2.')
  @override
  ExpressionImpl? get constantInitializer {
    return baseElement.constantInitializer;
  }

  @override
  ExpressionImpl? get constantInitializer2 {
    return baseElement.constantInitializer2;
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
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject? computeConstantValue() {
    return baseElement.computeConstantValue();
  }

  @override
  String displayString({
    bool multiline = false,
    bool preferTypeAlias = false,
    bool includePositionalParameterNames = false,
  }) {
    return baseElement.displayString(
      multiline: multiline,
      preferTypeAlias: preferTypeAlias,
      includePositionalParameterNames: includePositionalParameterNames,
    );
  }
}

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class SubstitutedConstructorElementImpl extends SubstitutedExecutableElementImpl
    with InternalConstructorElement
    implements ConstructorElement {
  new({
    required ConstructorElementImpl super.baseElement,
    required super.substitution,
  }) : super(typeParameters: const <TypeParameterElementImpl>[]);

  @override
  ConstructorElementImpl get baseElement =>
      super.baseElement as ConstructorElementImpl;

  @override
  InterfaceElementImpl get enclosingElement => baseElement.enclosingElement;

  @override
  ConstructorFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  FirstFragmentLocation get firstFragmentLocation {
    return baseElement.firstFragmentLocation;
  }

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
  bool get isOriginDeclaration => baseElement.isOriginDeclaration;

  @override
  bool get isOriginExtensionTypeRecovery =>
      baseElement.isOriginExtensionTypeRecovery;

  @override
  bool get isOriginImplicitDefault => baseElement.isOriginImplicitDefault;

  @override
  bool get isOriginMixinApplication => baseElement.isOriginMixinApplication;

  @override
  bool get isPrimary => baseElement.isPrimary;

  @override
  LibraryElementImpl get library => baseElement.library;

  @override
  InternalConstructorElement? get redirectedConstructor {
    var element = baseElement.redirectedConstructor;
    return _redirect(element);
  }

  @override
  InterfaceTypeImpl get returnType {
    var returnType = baseElement.returnType;
    return substitution.mapInterfaceType(returnType);
  }

  @override
  InternalConstructorElement? get superConstructor {
    return _redirect(baseElement.superConstructor);
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitConstructorElement(this);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  @override
  InternalConstructorElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedConstructorElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
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
abstract interface class SubstitutedElementImpl implements Element {
  @override
  ElementImpl get baseElement;

  /// The substitution for type parameters referenced in the base element.
  MapSubstitution get substitution;
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class SubstitutedExecutableElementImpl
    extends DelegatingExecutableElementImpl
    implements SubstitutedElementImpl {
  @override
  final MapSubstitution substitution;

  @override
  final List<TypeParameterElementImpl> typeParameters;

  FunctionTypeImpl? _type;

  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [baseElement] type
  /// parameters with the provided fresh [typeParameters].
  new({
    required super.baseElement,
    required this.substitution,
    required this.typeParameters,
  });

  @override
  List<InternalFormalParameterElement> get formalParameters {
    var formalParameters = baseElement.formalParameters;
    return List.generate(formalParameters.length, (index) {
      return formalParameters[index].substitute(substitution);
    });
  }

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
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class SubstitutedFieldElementImpl extends DelegatingFieldElementImpl
    implements SubstitutedElementImpl {
  @override
  final MapSubstitution substitution;

  TypeImpl? _type;

  new({required super.baseElement, required this.substitution});

  @override
  InternalGetterElement? get getter {
    var baseGetter = baseElement.getter;
    return baseGetter?.substitute(substitution);
  }

  @override
  InternalSetterElement? get setter {
    var baseSetter = baseElement.setter;
    return baseSetter?.substitute(substitution);
  }

  @override
  TypeImpl get type {
    return _type ??= substitution.substituteType(baseElement.type);
  }

  @override
  InternalFieldElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedFieldElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedFieldFormalParameterElementImpl
    extends SubstitutedFormalParameterElementImpl
    with InternalFieldFormalParameterElement {
  new({
    required FieldFormalParameterElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  FieldFormalParameterElementImpl get baseElement =>
      super.baseElement as FieldFormalParameterElementImpl;

  @override
  FieldElement? get field {
    return baseElement.field?.substitute(substitution);
  }

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  bool get isCovariant => baseElement.isCovariant;

  @override
  bool get isDeclaring => baseElement.isDeclaring;

  @override
  String? get privateName => baseElement.privateName;

  @override
  InternalFieldFormalParameterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedFieldFormalParameterElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

/// A parameter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedFormalParameterElementImpl
    extends DelegatingFormalParameterElementImpl
    implements SubstitutedElementImpl {
  @override
  final MapSubstitution substitution;

  TypeImpl? _type;

  new({required super.baseElement, required this.substitution});

  @override
  TypeImpl get type {
    return _type ??= substitution.substituteType(baseElement.type);
  }

  @override
  InternalFormalParameterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedFormalParameterElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

/// A getter element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedGetterElementImpl
    extends SubstitutedPropertyAccessorElementImpl
    with InternalGetterElement {
  new({
    required GetterElementImpl super.baseElement,
    required super.substitution,
  }) : super._(typeParameters: const []);

  @override
  GetterElementImpl get baseElement => super.baseElement as GetterElementImpl;

  @override
  InternalSetterElement? get correspondingSetter {
    var baseSetter = baseElement.variable.setter;
    return baseSetter?.substitute(substitution);
  }

  @override
  GetterFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<GetterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  Element get nonSynthetic {
    if (isOriginVariable) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitGetterElement(this);
  }

  @override
  InternalGetterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedGetterElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class SubstitutedMethodElementImpl extends SubstitutedExecutableElementImpl
    with InternalMethodElement {
  factory({
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

  new _({
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
  bool get isOriginDeclaration => baseElement.isOriginDeclaration;

  @override
  bool get isOriginInterface => baseElement.isOriginInterface;

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitMethodElement(this);
  }

  @override
  InternalMethodElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedMethodElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
abstract class SubstitutedPropertyAccessorElementImpl
    extends SubstitutedExecutableElementImpl
    with InternalPropertyAccessorElement {
  new _({
    required PropertyAccessorElementImpl super.baseElement,
    required super.substitution,
    required super.typeParameters,
  });

  @override
  Element get enclosingElement {
    return super.enclosingElement!;
  }

  @override
  PropertyAccessorFragmentImpl get firstFragment;

  @override
  bool get isOriginDeclaration => baseElement.isOriginDeclaration;

  @override
  bool get isOriginInterface => baseElement.isOriginInterface;

  @override
  bool get isOriginVariable => baseElement.isOriginVariable;

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
  new({
    required SetterElementImpl super.baseElement,
    required super.substitution,
  }) : super._(typeParameters: const []);

  @override
  SetterElementImpl get baseElement => super.baseElement as SetterElementImpl;

  @override
  InternalGetterElement? get correspondingGetter {
    var baseGetter = baseElement.variable.getter;
    return baseGetter?.substitute(substitution);
  }

  @override
  SetterFragmentImpl get firstFragment => baseElement.firstFragment;

  @override
  List<SetterFragmentImpl> get fragments {
    return baseElement.fragments;
  }

  @override
  Element get nonSynthetic {
    if (isOriginVariable) {
      return variable.nonSynthetic;
    } else {
      return this;
    }
  }

  @override
  T? accept<T>(ElementVisitor2<T> visitor) {
    return visitor.visitSetterElement(this);
  }

  @override
  InternalSetterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedSetterElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

class SubstitutedSuperFormalParameterElementImpl
    extends SubstitutedFormalParameterElementImpl
    with InternalSuperFormalParameterElement {
  new({
    required SuperFormalParameterElementImpl super.baseElement,
    required super.substitution,
  });

  @override
  SuperFormalParameterElementImpl get baseElement =>
      super.baseElement as SuperFormalParameterElementImpl;

  @override
  bool get hasDefaultValue => baseElement.hasDefaultValue;

  @override
  InternalFormalParameterElement? get superConstructorParameter {
    var superConstructorParameter = baseElement.superConstructorParameter;
    if (superConstructorParameter == null) {
      return null;
    }

    return superConstructorParameter.substitute(substitution);
  }

  @override
  InternalSuperFormalParameterElement substitute(MapSubstitution substitution) {
    if (substitution.map.isEmpty) {
      return this;
    }
    return SubstitutedSuperFormalParameterElementImpl(
      baseElement: baseElement,
      substitution: this.substitution.andThen(substitution),
    );
  }
}

class _SubstitutedTypeParameters {
  final List<TypeParameterElementImpl> elements;
  final MapSubstitution substitution;

  factory(
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

  new _(this.elements, this.substitution);
}
