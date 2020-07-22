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
import 'package:analyzer/src/dart/element/nullability_eliminator.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/// A constructor element defined in a parameterized type where the values of
/// the type parameters are known.
class ConstructorMember extends ExecutableMember implements ConstructorElement {
  /// Initialize a newly created element to represent a constructor, based on
  /// the [declaration], and applied [substitution].
  ConstructorMember(
    ConstructorElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) : super(declaration, substitution, isLegacy,
            const <TypeParameterElement>[]);

  @deprecated
  @override
  ConstructorElement get baseElement => declaration;

  @override
  ConstructorElement get declaration => super.declaration as ConstructorElement;

  @override
  ClassElement get enclosingElement => declaration.enclosingElement;

  @override
  bool get isConst => declaration.isConst;

  @override
  bool get isConstantEvaluated => declaration.isConstantEvaluated;

  @override
  bool get isDefaultConstructor => declaration.isDefaultConstructor;

  @override
  bool get isFactory => declaration.isFactory;

  @override
  int get nameEnd => declaration.nameEnd;

  @override
  int get periodOffset => declaration.periodOffset;

  @override
  ConstructorElement get redirectedConstructor {
    var element = this.declaration.redirectedConstructor;
    if (element == null) {
      return null;
    }

    ConstructorElement declaration;
    MapSubstitution substitution;
    if (element is ConstructorMember) {
      declaration = element._declaration;
      var map = <TypeParameterElement, DartType>{};
      var elementMap = element._substitution.map;
      for (var typeParameter in elementMap.keys) {
        var type = elementMap[typeParameter];
        map[typeParameter] = _substitution.substituteType(type);
      }
      substitution = Substitution.fromMap(map);
    } else {
      declaration = element;
      substitution = _substitution;
    }

    return ConstructorMember(declaration, substitution, false);
  }

  @override
  InterfaceType get returnType => type.returnType as InterfaceType;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitConstructorElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeConstructorElement(this);
  }

  /// If the given [constructor]'s type is different when any type parameters
  /// from the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a constructor member
  /// representing the given constructor. Return the member that was created, or
  /// the original constructor if no member was created.
  static ConstructorElement from(
      ConstructorElement constructor, InterfaceType definingType) {
    if (constructor == null || definingType.typeArguments.isEmpty) {
      return constructor;
    }

    FunctionType baseType = constructor.type;
    if (baseType == null) {
      // TODO(brianwilkerson) We need to understand when this can happen.
      return constructor;
    }

    var isLegacy = false;
    if (constructor is ConstructorMember) {
      isLegacy = (constructor as ConstructorMember).isLegacy;
      constructor = constructor.declaration;
    }

    return ConstructorMember(
      constructor,
      Substitution.fromInterfaceType(definingType),
      isLegacy,
    );
  }
}

/// An executable element defined in a parameterized type where the values of
/// the type parameters are known.
abstract class ExecutableMember extends Member implements ExecutableElement {
  @override
  final List<TypeParameterElement> typeParameters;

  FunctionType _type;

  /// Initialize a newly created element to represent a callable element (like a
  /// method or function or property), based on the [declaration], and applied
  /// [substitution].
  ///
  /// The [typeParameters] are fresh, and [substitution] is already applied to
  /// their bounds.  The [substitution] includes replacing [declaration] type
  /// parameters with the provided fresh [typeParameters].
  ExecutableMember(
    ExecutableElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
    this.typeParameters,
  ) : super(declaration, substitution, isLegacy);

  @deprecated
  @override
  ExecutableElement get baseElement => declaration;

  @override
  ExecutableElement get declaration => super.declaration as ExecutableElement;

  @override
  bool get hasImplicitReturnType => declaration.hasImplicitReturnType;

  @override
  bool get isAbstract => declaration.isAbstract;

  @override
  bool get isAsynchronous => declaration.isAsynchronous;

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
  List<ParameterElement> get parameters {
    return declaration.parameters.map<ParameterElement>((p) {
      if (p is FieldFormalParameterElement) {
        return FieldFormalParameterMember(p, _substitution, isLegacy);
      }
      return ParameterMember(p, _substitution, isLegacy);
    }).toList();
  }

  @override
  DartType get returnType => type.returnType;

  @override
  FunctionType get type {
    if (_type != null) return _type;

    _type = _substitution.substituteType(declaration.type);
    _type = _toLegacyType(_type);
    return _type;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeExecutableElement(this, displayName);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // TODO(brianwilkerson) We need to finish implementing the accessors used
    // below so that we can safely invoke them.
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }

  static ExecutableElement from2(
    ExecutableElement element,
    MapSubstitution substitution,
  ) {
    if (element == null) {
      return null;
    }

    var isLegacy = false;
    var combined = substitution;
    if (element is ExecutableMember) {
      ExecutableMember member = element;
      element = member.declaration;

      isLegacy = member.isLegacy;

      var map = <TypeParameterElement, DartType>{};
      for (var entry in member._substitution.map.entries) {
        map[entry.key] = substitution.substituteType(entry.value);
      }
      map.addAll(substitution.map);
      combined = Substitution.fromMap(map);
    }

    if (!isLegacy && combined.map.isEmpty) {
      return element;
    }

    if (element is ConstructorElement) {
      return ConstructorMember(element, combined, isLegacy);
    } else if (element is MethodElement) {
      return MethodMember(element, combined, isLegacy);
    } else if (element is PropertyAccessorElement) {
      return PropertyAccessorMember(element, combined, isLegacy);
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
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return FieldFormalParameterMember._(
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  FieldFormalParameterMember._(
    FieldFormalParameterElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
    List<TypeParameterElement> typeParameters,
  ) : super._(declaration, substitution, isLegacy, typeParameters);

  @override
  FieldElement get field {
    var field = (declaration as FieldFormalParameterElement).field;
    if (field == null) {
      return null;
    }

    return FieldMember(field, _substitution, isLegacy);
  }

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
      visitor.visitFieldFormalParameterElement(this);
}

/// A field element defined in a parameterized type where the values of the type
/// parameters are known.
class FieldMember extends VariableMember implements FieldElement {
  /// Initialize a newly created element to represent a field, based on the
  /// [declaration], with applied [substitution].
  FieldMember(
    FieldElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) : super(declaration, substitution, isLegacy);

  @deprecated
  @override
  FieldElement get baseElement => declaration;

  @override
  FieldElement get declaration => super.declaration as FieldElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  PropertyAccessorElement get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseGetter, _substitution, isLegacy);
  }

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isEnumConstant => declaration.isEnumConstant;

  @override
  PropertyAccessorElement get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseSetter, _substitution, isLegacy);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitFieldElement(this);

  /// If the given [field]'s type is different when any type parameters from the
  /// defining type's declaration are replaced with the actual type arguments
  /// from the [definingType], create a field member representing the given
  /// field. Return the member that was created, or the base field if no member
  /// was created.
  static FieldElement from(FieldElement field, InterfaceType definingType) {
    if (field == null || definingType.typeArguments.isEmpty) {
      return field;
    }
    return FieldMember(
      field,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }

  static FieldElement from2(
    FieldElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return FieldMember(element, substitution, false);
  }
}

class FunctionMember extends ExecutableMember implements FunctionElement {
  FunctionMember(FunctionElement declaration, bool isLegacy)
      : super(
          declaration,
          Substitution.empty,
          isLegacy,
          declaration.typeParameters,
        );

  @override
  FunctionElement get declaration => super.declaration;

  @override
  bool get isEntryPoint => declaration.isEntryPoint;

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitFunctionElement(this);
  }
}

/// An element defined in a parameterized type where the values of the type
/// parameters are known.
abstract class Member implements Element {
  /// The element on which the parameterized element was created.
  final Element _declaration;

  /// The substitution for type parameters referenced in the base element.
  final MapSubstitution _substitution;

  /// If `true`, then this is a legacy view on a NNBD element.
  final bool isLegacy;

  /// Initialize a newly created element to represent a member, based on the
  /// [declaration], and applied [_substitution].
  Member(this._declaration, this._substitution, this.isLegacy) {
    if (_declaration is Member) {
      throw StateError('Members must be created from a declarations.');
    }
  }

  /// Return the element on which the parameterized element was created.
  @Deprecated('Use Element.declaration instead')
  Element get baseElement => _declaration;

  @override
  AnalysisContext get context => _declaration.context;

  @override
  Element get declaration => _declaration;

  @override
  String get displayName => _declaration.displayName;

  @override
  String get documentationComment => _declaration.documentationComment;

  @override
  Element get enclosingElement => _declaration.enclosingElement;

  @override
  bool get hasAlwaysThrows => _declaration.hasAlwaysThrows;

  @override
  bool get hasDeprecated => _declaration.hasDeprecated;

  @override
  bool get hasFactory => _declaration.hasFactory;

  @override
  bool get hasIsTest => _declaration.hasIsTest;

  @override
  bool get hasIsTestGroup => _declaration.hasIsTestGroup;

  @override
  bool get hasJS => _declaration.hasJS;

  @override
  bool get hasLiteral => _declaration.hasLiteral;

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
  bool get hasRequired => _declaration.hasRequired;

  @override
  bool get hasSealed => _declaration.hasSealed;

  @override
  bool get hasVisibleForTemplate => _declaration.hasVisibleForTemplate;

  @override
  bool get hasVisibleForTesting => _declaration.hasVisibleForTesting;

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
  LibraryElement get library => _declaration.library;

  @override
  Source get librarySource => _declaration.librarySource;

  @override
  ElementLocation get location => _declaration.location;

  @override
  List<ElementAnnotation> get metadata => _declaration.metadata;

  @override
  String get name => _declaration.name;

  @override
  int get nameLength => _declaration.nameLength;

  @override
  int get nameOffset => _declaration.nameOffset;

  @override
  AnalysisSession get session => _declaration.session;

  @override
  Source get source => _declaration.source;

  /// The substitution for type parameters referenced in the base element.
  MapSubstitution get substitution => _substitution;

  /// Append a textual representation of this element to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @Deprecated('Use either thisOrAncestorMatching or thisOrAncestorOfType')
  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) =>
      declaration.getAncestor(predicate);

  @override
  String getDisplayString({@required bool withNullability}) {
    var builder = ElementDisplayStringBuilder(
      skipAllDynamicArguments: false,
      withNullability: withNullability,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  String getExtendedDisplayName(String shortName) =>
      _declaration.getExtendedDisplayName(shortName);

  @override
  bool isAccessibleIn(LibraryElement library) =>
      _declaration.isAccessibleIn(library);

  /// Use the given [visitor] to visit all of the [children].
  void safelyVisitChildren(List<Element> children, ElementVisitor visitor) {
    // TODO(brianwilkerson) Make this private
    if (children != null) {
      for (Element child in children) {
        child.accept(visitor);
      }
    }
  }

  @override
  E thisOrAncestorMatching<E extends Element>(Predicate<Element> predicate) =>
      declaration.thisOrAncestorMatching(predicate);

  @override
  E thisOrAncestorOfType<E extends Element>() =>
      declaration.thisOrAncestorOfType<E>();

  @override
  String toString() {
    return getDisplayString(withNullability: false);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // There are no children to visit
  }

  /// If this member is a legacy view, erase nullability from the [type].
  /// Otherwise, return the type unchanged.
  DartType _toLegacyType(DartType type) {
    if (isLegacy) {
      var typeProvider = declaration.library.typeProvider;
      return NullabilityEliminator.perform(typeProvider, type);
    } else {
      return type;
    }
  }

  /// Return the legacy view of them [element], so that all its types, and
  /// types of any elements that are returned from it, are legacy types.
  ///
  /// If the [element] is declared in a legacy library, return it unchanged.
  static Element legacy(Element element) {
    if (element is ConstructorElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return ConstructorMember(
          member._declaration,
          member._substitution,
          true,
        );
      } else {
        return ConstructorMember(element, Substitution.empty, true);
      }
    } else if (element is FunctionElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else {
        return FunctionMember(element.declaration, true);
      }
    } else if (element is MethodElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return MethodMember(
          member._declaration,
          member._substitution,
          true,
        );
      } else {
        return MethodMember(element, Substitution.empty, true);
      }
    } else if (element is PropertyAccessorElement) {
      if (!element.library.isNonNullableByDefault) {
        return element;
      } else if (element is Member) {
        var member = element as Member;
        return PropertyAccessorMember(
          member._declaration,
          member._substitution,
          true,
        );
      } else {
        return PropertyAccessorMember(element, Substitution.empty, true);
      }
    } else {
      return element;
    }
  }
}

/// A method element defined in a parameterized type where the values of the
/// type parameters are known.
class MethodMember extends ExecutableMember implements MethodElement {
  factory MethodMember(
    MethodElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return MethodMember._(
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  MethodMember._(
    MethodElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
    List<TypeParameterElement> typeParameters,
  ) : super(declaration, substitution, isLegacy, typeParameters);

  @deprecated
  @override
  MethodElement get baseElement => declaration;

  @override
  MethodElement get declaration => super.declaration as MethodElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitMethodElement(this);

  /// If the given [method]'s type is different when any type parameters from
  /// the defining type's declaration are replaced with the actual type
  /// arguments from the [definingType], create a method member representing the
  /// given method. Return the member that was created, or the base method if no
  /// member was created.
  static MethodElement from(MethodElement method, InterfaceType definingType) {
    if (method == null || definingType.typeArguments.isEmpty) {
      return method;
    }

    return MethodMember(
      method,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }

  static MethodElement from2(
    MethodElement element,
    MapSubstitution substitution,
  ) {
    if (substitution.map.isEmpty) {
      return element;
    }
    return MethodMember(element, substitution, false);
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
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return ParameterMember._(
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  /// Initialize a newly created element to represent a parameter, based on the
  /// [declaration], with applied [substitution].
  ParameterMember._(
    ParameterElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
    this.typeParameters,
  ) : super(declaration, substitution, isLegacy);

  @deprecated
  @override
  ParameterElement get baseElement => declaration;

  @override
  ParameterElement get declaration => super.declaration as ParameterElement;

  @override
  String get defaultValueCode => declaration.defaultValueCode;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  int get hashCode => declaration.hashCode;

  @override
  bool get isCovariant => declaration.isCovariant;

  @override
  bool get isInitializingFormal => declaration.isInitializingFormal;

  @override
  bool get isRequiredNamed {
    if (isLegacy) {
      return false;
    }
    return super.isRequiredNamed;
  }

  @deprecated
  @override
  ParameterKind get parameterKind => declaration.parameterKind;

  @override
  List<ParameterElement> get parameters {
    DartType type = this.type;
    if (type is FunctionType) {
      return type.parameters;
    }
    return const <ParameterElement>[];
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) => visitor.visitParameterElement(this);

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFormalParameter(this);
  }

  @Deprecated('Use either thisOrAncestorMatching or thisOrAncestorOfType')
  @override
  E getAncestor<E extends Element>(Predicate<Element> predicate) {
    Element element = declaration.getAncestor(predicate);
    if (element is ExecutableElement) {
      return ExecutableMember.from2(element, _substitution) as E;
    }
    return element as E;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    super.visitChildren(visitor);
    safelyVisitChildren(parameters, visitor);
  }
}

/// A property accessor element defined in a parameterized type where the values
/// of the type parameters are known.
class PropertyAccessorMember extends ExecutableMember
    implements PropertyAccessorElement {
  factory PropertyAccessorMember(
    PropertyAccessorElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) {
    var freshTypeParameters = _SubstitutedTypeParameters(
      declaration.typeParameters,
      substitution,
    );
    return PropertyAccessorMember._(
      declaration,
      freshTypeParameters.substitution,
      isLegacy,
      freshTypeParameters.elements,
    );
  }

  PropertyAccessorMember._(
    PropertyAccessorElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
    List<TypeParameterElement> typeParameters,
  ) : super(declaration, substitution, isLegacy, typeParameters);

  @deprecated
  @override
  PropertyAccessorElement get baseElement => declaration;

  @override
  PropertyAccessorElement get correspondingGetter {
    var baseGetter = declaration.correspondingGetter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseGetter, _substitution, isLegacy);
  }

  @override
  PropertyAccessorElement get correspondingSetter {
    var baseSetter = declaration.correspondingSetter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseSetter, _substitution, isLegacy);
  }

  @override
  PropertyAccessorElement get declaration =>
      super.declaration as PropertyAccessorElement;

  @override
  Element get enclosingElement => declaration.enclosingElement;

  @override
  bool get isGetter => declaration.isGetter;

  @override
  bool get isSetter => declaration.isSetter;

  @override
  PropertyInducingElement get variable {
    // TODO
    PropertyInducingElement variable = declaration.variable;
    if (variable is FieldElement) {
      return FieldMember(variable, _substitution, isLegacy);
    } else if (variable is TopLevelVariableElement) {
      return TopLevelVariableMember(variable, _substitution, isLegacy);
    }
    return variable;
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) =>
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
  static PropertyAccessorElement from(
      PropertyAccessorElement accessor, InterfaceType definingType) {
    if (accessor == null || definingType.typeArguments.isEmpty) {
      return accessor;
    }

    return PropertyAccessorMember(
      accessor,
      Substitution.fromInterfaceType(definingType),
      false,
    );
  }
}

class TopLevelVariableMember extends VariableMember
    implements TopLevelVariableElement {
  TopLevelVariableMember(
    VariableElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) : super(declaration, substitution, isLegacy);

  @override
  TopLevelVariableElement get declaration => _declaration;

  @override
  PropertyAccessorElement get getter {
    var baseGetter = declaration.getter;
    if (baseGetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseGetter, _substitution, isLegacy);
  }

  @override
  PropertyAccessorElement get setter {
    var baseSetter = declaration.setter;
    if (baseSetter == null) {
      return null;
    }
    return PropertyAccessorMember(baseSetter, _substitution, isLegacy);
  }

  @override
  T accept<T>(ElementVisitor<T> visitor) {
    return visitor.visitTopLevelVariableElement(this);
  }
}

/// A variable element defined in a parameterized type where the values of the
/// type parameters are known.
abstract class VariableMember extends Member implements VariableElement {
  DartType _type;

  /// Initialize a newly created element to represent a variable, based on the
  /// [declaration], with applied [substitution].
  VariableMember(
    VariableElement declaration,
    MapSubstitution substitution,
    bool isLegacy,
  ) : super(declaration, substitution, isLegacy);

  @deprecated
  @override
  VariableElement get baseElement => declaration;

  @Deprecated('Use computeConstantValue() instead')
  @override
  DartObject get constantValue => declaration.constantValue;

  @override
  VariableElement get declaration => super.declaration as VariableElement;

  @override
  bool get hasImplicitType => declaration.hasImplicitType;

  @override
  FunctionElement get initializer {
    //
    // Elements within this element should have type parameters substituted,
    // just like this element.
    //
    throw UnsupportedError('initializer');
    //    return getBaseElement().getInitializer();
  }

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
    if (_type != null) return _type;

    _type = _substitution.substituteType(declaration.type);
    _type = _toLegacyType(_type);
    return _type;
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVariableElement(this);
  }

  @override
  DartObject computeConstantValue() => declaration.computeConstantValue();

  @override
  void visitChildren(ElementVisitor visitor) {
    // TODO(brianwilkerson) We need to finish implementing the accessors used
    // below so that we can safely invoke them.
    super.visitChildren(visitor);
    declaration.initializer?.accept(visitor);
  }
}

class _SubstitutedTypeParameters {
  final List<TypeParameterElement> elements;
  final Substitution substitution;

  factory _SubstitutedTypeParameters(
    List<TypeParameterElement> elements,
    MapSubstitution substitution,
  ) {
    if (elements.isEmpty) {
      return _SubstitutedTypeParameters._(elements, substitution);
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    var newElements = List<TypeParameterElement>(elements.length);
    var newTypes = List<TypeParameterType>(elements.length);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var newElement = TypeParameterElementImpl.synthetic(element.name);
      newElements[i] = newElement;
      newTypes[i] = newElement.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
    }

    // Update bounds to reference new TypeParameterElement(s).
    var substitution2 = Substitution.fromPairs(elements, newTypes);
    for (int i = 0; i < newElements.length; i++) {
      var element = elements[i];
      var newElement = newElements[i] as TypeParameterElementImpl;
      var bound = element.bound;
      if (bound != null) {
        var newBound = substitution.substituteType(bound);
        newBound = substitution2.substituteType(newBound);
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
