// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: analyzer_use_new_elements

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer/src/utilities/extensions/object.dart';
import 'package:collection/collection.dart';

/// Returns a [List] of fixed length with given types.
List<DartType> fixedTypeList(DartType e1, [DartType? e2]) {
  if (e2 != null) {
    var result = List<DartType>.filled(2, e1);
    result[1] = e2;
    return result;
  } else {
    return List<DartType>.filled(1, e1);
  }
}

/// The [Type] representing the type `dynamic`.
class DynamicTypeImpl extends TypeImpl
    implements DynamicType, SharedDynamicType {
  /// The unique instance of this class.
  static final DynamicTypeImpl instance = DynamicTypeImpl._();

  /// Prevent the creation of instances of this class.
  DynamicTypeImpl._();

  @override
  DynamicElementImpl get element => DynamicElementImpl.instance;

  @override
  DynamicElementImpl2 get element3 => DynamicElementImpl2.instance;

  @override
  int get hashCode => 1;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitDynamicType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitDynamicType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeDynamicType();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    // The dynamic type is always nullable.
    return this;
  }
}

/// The type of a function, method, constructor, getter, or setter.
class FunctionTypeImpl extends TypeImpl
    implements FunctionType, SharedFunctionType {
  @override
  late int hashCode = _computeHashCode();

  @override
  final TypeImpl returnType;

  @override
  final List<TypeParameterElementImpl> typeFormals;

  @override
  final List<ParameterElement> parameters;

  @override
  final NullabilitySuffix nullabilitySuffix;

  @override
  final List<TypeImpl> positionalParameterTypes;

  @override
  final int requiredPositionalParameterCount;

  @override
  final List<ParameterElementMixin> sortedNamedParameters;

  factory FunctionTypeImpl({
    required List<TypeParameterElement> typeFormals,
    required List<ParameterElement> parameters,
    required DartType returnType,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElement? alias,
  }) {
    int? firstNamedParameterIndex;
    var requiredPositionalParameterCount = 0;
    var positionalParameterTypes = <TypeImpl>[];
    List<ParameterElement> sortedNamedParameters;

    // Check if already sorted.
    var namedParametersAlreadySorted = true;
    var lastNamedParameterName = '';
    for (var i = 0; i < parameters.length; ++i) {
      var parameter = parameters[i];
      if (parameter.isNamed) {
        firstNamedParameterIndex ??= i;
        var name = parameter.name;
        if (lastNamedParameterName.compareTo(name) > 0) {
          namedParametersAlreadySorted = false;
          break;
        }
        lastNamedParameterName = name;
      } else {
        // TODO(paulberry): get rid of this cast by changing the type of
        // `parameters` to `List<ParameterElementMixin>`.
        positionalParameterTypes.add(parameter.type as TypeImpl);
        if (parameter.isRequiredPositional) {
          requiredPositionalParameterCount++;
        }
      }
    }
    sortedNamedParameters = firstNamedParameterIndex == null
        ? const []
        : parameters.sublist(firstNamedParameterIndex, parameters.length);
    if (!namedParametersAlreadySorted) {
      // Sort named parameters.
      sortedNamedParameters.sort((a, b) => a.name.compareTo(b.name));

      // Combine into a new list, with sorted named parameters.
      parameters = parameters.toList();
      parameters.replaceRange(
          firstNamedParameterIndex!, parameters.length, sortedNamedParameters);
    }
    return FunctionTypeImpl._(
        // TODO(paulberry): eliminate this cast by changing the type of the
        // `typeFormals` parameter.
        typeFormals: typeFormals.cast(),
        parameters: parameters,
        // TODO(paulberry): eliminate this cast by changing the type of
        // `returnType`.
        returnType: returnType as TypeImpl,
        nullabilitySuffix: nullabilitySuffix,
        positionalParameterTypes: positionalParameterTypes,
        requiredPositionalParameterCount: requiredPositionalParameterCount,
        // TODO(paulberry): avoid the cast by changing the type of
        // `sortedNamedParameters`.
        sortedNamedParameters: sortedNamedParameters.cast(),
        alias: alias);
  }

  factory FunctionTypeImpl.v2({
    required List<TypeParameterElement2> typeParameters,
    required List<FormalParameterElement> formalParameters,
    required DartType returnType,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElement? alias,
  }) {
    return FunctionTypeImpl(
      typeFormals: typeParameters.map((e) => e.asElement).toList(),
      parameters: formalParameters is List<FormalParameterElementImpl>
          ? formalParameters.map((e) => e.asElement).toList()
          : formalParameters.map((e) => e.asElement).toList(),
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
      alias: alias,
    );
  }

  FunctionTypeImpl._({
    required this.typeFormals,
    required this.parameters,
    required this.returnType,
    required this.nullabilitySuffix,
    required this.positionalParameterTypes,
    required this.requiredPositionalParameterCount,
    required this.sortedNamedParameters,
    super.alias,
  });

  @override
  Null get element => null;

  @override
  Null get element3 => null;

  @override
  List<FormalParameterElementMixin> get formalParameters {
    return parameters.map((p) => p.asElement2).toList(growable: false);
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String? get name => null;

  @override
  Map<String, DartType> get namedParameterTypes => {
        for (var parameter in sortedNamedParameters)
          parameter.name: parameter.type
      };

  @override
  List<DartType> get normalParameterTypes =>
      positionalParameterTypes.sublist(0, requiredPositionalParameterCount);

  @override
  List<DartType> get optionalParameterTypes =>
      positionalParameterTypes.sublist(requiredPositionalParameterCount);

  @override
  List<TypeImpl> get positionalParameterTypesShared => positionalParameterTypes;

  @override
  TypeImpl get returnTypeShared => returnType;

  @override
  // TODO(paulberry): see if this type can be changed to
  // `List<FormalParameterElementImpl>`. See
  // https://dart-review.googlesource.com/c/sdk/+/402341/comment/b1669e20_15938fcd/.
  List<FormalParameterElementMixin> get sortedNamedParametersShared =>
      sortedNamedParameters.map((p) => p.asElement2).toList();

  @override
  List<TypeParameterElementImpl2> get typeParameters =>
      typeFormals.map((fragment) => fragment.element).toList();

  @override
  List<TypeParameterElementImpl2> get typeParametersShared => typeParameters;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is FunctionTypeImpl) {
      if (other.nullabilitySuffix != nullabilitySuffix) {
        return false;
      }

      if (other.typeFormals.length != typeFormals.length) {
        return false;
      }
      // `<T>T -> T` should be equal to `<U>U -> U`
      // To test this, we instantiate both types with the same (unique) type
      // variables, and see if the result is equal.
      if (typeFormals.isNotEmpty) {
        var freshVariables =
            FunctionTypeImpl.relateTypeFormals(this, other, (t, s) => t == s);
        if (freshVariables == null) {
          return false;
        }
        return instantiate(freshVariables) == other.instantiate(freshVariables);
      }

      return other.returnType == returnType &&
          _equalParameters(other.parameters, parameters);
    }
    return false;
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitFunctionType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitFunctionType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeFunctionType(this);
  }

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes) {
    if (argumentTypes.length != typeFormals.length) {
      throw ArgumentError("argumentTypes.length (${argumentTypes.length}) != "
          "typeFormals.length (${typeFormals.length})");
    }
    if (argumentTypes.isEmpty) {
      return this;
    }

    var substitution = Substitution.fromPairs(typeFormals, argumentTypes);

    return FunctionTypeImpl(
      returnType: substitution.substituteType(returnType),
      typeFormals: const [],
      parameters: parameters
          .map((p) => ParameterMember.from(p, substitution))
          .toFixedList(),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  bool referencesAny(Set<TypeParameterElement> parameters) {
    if (typeFormals.any((element) {
      assert(!parameters.contains(element));

      var bound = element.bound;
      if (bound != null && bound.referencesAny(parameters)) {
        return true;
      }

      var defaultType = element.defaultType as TypeImpl;
      return defaultType.referencesAny(parameters);
    })) {
      return true;
    }

    if (this.parameters.any((element) {
      var type = element.type as TypeImpl;
      return type.referencesAny(parameters);
    })) {
      return true;
    }

    return returnType.referencesAny(parameters);
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl2> parameters) {
    if (typeFormals.any((element) {
      assert(!parameters.contains(element.asElement2));

      var bound = element.bound;
      if (bound != null && bound.referencesAny2(parameters)) {
        return true;
      }

      var defaultType = element.defaultType as TypeImpl;
      return defaultType.referencesAny2(parameters);
    })) {
      return true;
    }

    if (this.parameters.any((element) {
      var type = element.type as TypeImpl;
      return type.referencesAny2(parameters);
    })) {
      return true;
    }

    return returnType.referencesAny2(parameters);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return FunctionTypeImpl._(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
      positionalParameterTypes: positionalParameterTypes,
      requiredPositionalParameterCount: requiredPositionalParameterCount,
      sortedNamedParameters: sortedNamedParameters,
      alias: alias,
    );
  }

  int _computeHashCode() {
    if (typeFormals.isNotEmpty) {
      // Two generic function types are considered equivalent even if their type
      // formals have different names, so we need to normalize to a standard set
      // of type formals before taking the hash code.
      //
      // Note: when creating the standard set of type formals, we ignore bounds.
      // This means that two function types that differ only in their type
      // parameter bounds will receive the same hash code; this should be rare
      // enough that it won't be a problem.
      return instantiate([
        for (var i = 0; i < typeFormals.length; i++)
          TypeParameterTypeImpl(
              element: TypeParameterElementImpl.synthetic('T$i'),
              nullabilitySuffix: NullabilitySuffix.none)
      ]).hashCode;
    }

    List<Object>? namedParameterInfo;
    if (sortedNamedParameters.isNotEmpty) {
      namedParameterInfo = [];
      for (var namedParameter in sortedNamedParameters) {
        namedParameterInfo.add(namedParameter.isRequired);
        namedParameterInfo.add(namedParameter.name);
      }
    }

    return Object.hash(
      nullabilitySuffix,
      returnType,
      requiredPositionalParameterCount,
      namedParameterInfo,
    );
  }

  /// Given two functions [f1] and [f2] where f1 and f2 are known to be
  /// generic function types (both have type formals), this checks that they
  /// have the same number of formals, and that those formals have bounds
  /// (e.g. `<T extends LowerBound>`) that satisfy [relation].
  ///
  /// The return value will be a new list of fresh type variables, that can be
  /// used to instantiate both function types, allowing further comparison.
  /// For example, given `<T>T -> T` and `<U>U -> U` we can instantiate them
  /// with `F` to get `F -> F` and `F -> F`, which we can see are equal.
  static List<TypeParameterType>? relateTypeFormals(
      FunctionType f1,
      FunctionType f2,
      bool Function(DartType bound2, DartType bound1) relation) {
    List<TypeParameterElement> params1 = f1.typeFormals;
    List<TypeParameterElement> params2 = f2.typeFormals;
    return relateTypeFormals2(params1, params2, relation);
  }

  static List<TypeParameterType>? relateTypeFormals2(
      List<TypeParameterElement> params1,
      List<TypeParameterElement> params2,
      bool Function(DartType bound2, DartType bound1) relation) {
    int count = params1.length;
    if (params2.length != count) {
      return null;
    }
    // We build up a substitution matching up the type parameters
    // from the two types, {variablesFresh/variables1} and
    // {variablesFresh/variables2}
    List<TypeParameterElement> variables1 = <TypeParameterElement>[];
    List<TypeParameterElement> variables2 = <TypeParameterElement>[];
    var variablesFresh = <TypeParameterType>[];
    for (int i = 0; i < count; i++) {
      TypeParameterElement p1 = params1[i];
      TypeParameterElement p2 = params2[i];
      TypeParameterElementImpl pFresh =
          TypeParameterElementImpl.synthetic(p2.name);

      var variableFresh = pFresh.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );

      variables1.add(p1);
      variables2.add(p2);
      variablesFresh.add(variableFresh);

      DartType bound1 = p1.bound ?? DynamicTypeImpl.instance;
      DartType bound2 = p2.bound ?? DynamicTypeImpl.instance;
      bound1 = Substitution.fromPairs(variables1, variablesFresh)
          .substituteType(bound1);
      bound2 = Substitution.fromPairs(variables2, variablesFresh)
          .substituteType(bound2);
      if (!relation(bound2, bound1)) {
        return null;
      }

      if (bound2 is! DynamicType) {
        pFresh.bound = bound2;
      }
    }
    return variablesFresh;
  }

  /// Return `true` if given lists of parameters are semantically - have the
  /// same kinds (required, optional position, named, required named), and
  /// the same types. Named parameters must also have same names. Named
  /// parameters must be sorted in the given lists.
  static bool _equalParameters(
    List<ParameterElement> firstParameters,
    List<ParameterElement> secondParameters,
  ) {
    if (firstParameters.length != secondParameters.length) {
      return false;
    }
    for (var i = 0; i < firstParameters.length; ++i) {
      var firstParameter = firstParameters[i];
      var secondParameter = secondParameters[i];
      // ignore: deprecated_member_use_from_same_package
      if (firstParameter.parameterKind != secondParameter.parameterKind) {
        return false;
      }
      if (firstParameter.type != secondParameter.type) {
        return false;
      }
      if (firstParameter.isNamed &&
          firstParameter.name != secondParameter.name) {
        return false;
      }
    }
    return true;
  }
}

/// A concrete implementation of [DartType] representing types of the form
/// `FutureOr<...>`.
class FutureOrTypeImpl extends InterfaceTypeImpl {
  FutureOrTypeImpl({
    required super.element3,
    required super.typeArgument,
    required super.nullabilitySuffix,
    super.alias,
  }) : super._futureOr();

  @override
  bool get isDartAsyncFutureOr => true;

  TypeImpl get typeArgument => typeArguments[0];

  @override
  InterfaceTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;

    return FutureOrTypeImpl(
      element3: element3,
      typeArgument: typeArgument,
      nullabilitySuffix: nullabilitySuffix,
      alias: alias,
    );
  }
}

class InstantiatedTypeAliasElementImpl implements InstantiatedTypeAliasElement {
  @override
  final TypeAliasElement element;

  @override
  final List<DartType> typeArguments;

  InstantiatedTypeAliasElementImpl({
    required this.element,
    required this.typeArguments,
  });

  factory InstantiatedTypeAliasElementImpl.v2({
    required TypeAliasElement2 element,
    required List<DartType> typeArguments,
  }) {
    return InstantiatedTypeAliasElementImpl(
      element: element.asElement,
      typeArguments: typeArguments,
    );
  }

  @override
  TypeAliasElement2 get element2 => (element as TypeAliasFragment).element;
}

/// A concrete implementation of an [InterfaceType].
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  @override
  final InterfaceElementImpl2 element3;

  @override
  final List<TypeImpl> typeArguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Cached [ConstructorElement]s - members or raw elements.
  List<ConstructorElement>? _constructors;

  /// Cached [PropertyAccessorElement]s - members or raw elements.
  List<PropertyAccessorElement>? _accessors;

  /// Cached [MethodElement]s - members or raw elements.
  List<MethodElement>? _methods;

  factory InterfaceTypeImpl({
    required InterfaceElementImpl2 element,
    required List<DartType> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElement? alias,
  }) {
    if (element.name3 == 'FutureOr' && element.library2.isDartAsync) {
      return FutureOrTypeImpl(
        element3: element,
        // TODO(paulberry): avoid this cast by changing the type of
        // `typeArguments`.
        typeArgument: typeArguments.isNotEmpty
            ? typeArguments[0] as TypeImpl
            : InvalidTypeImpl.instance,
        nullabilitySuffix: nullabilitySuffix,
        alias: alias,
      );
    } else if (element.name3 == 'Null' && element.library2.isDartCore) {
      return NullTypeImpl(
        element3: element,
        alias: alias,
      );
    } else {
      // TODO(paulberry): avoid this cast by changing the type of
      // `typeArguments`.
      return InterfaceTypeImpl._(
        element3: element,
        typeArguments: typeArguments.cast(),
        nullabilitySuffix: nullabilitySuffix,
        alias: alias,
      );
    }
  }

  InterfaceTypeImpl._({
    required this.element3,
    required this.typeArguments,
    required this.nullabilitySuffix,
    required super.alias,
  });

  InterfaceTypeImpl._futureOr({
    required this.element3,
    required TypeImpl typeArgument,
    required this.nullabilitySuffix,
    super.alias,
  }) : typeArguments = [typeArgument] {
    assert(element3.name3 == 'FutureOr' && element3.library2.isDartAsync);
    assert(this is FutureOrTypeImpl);
  }

  InterfaceTypeImpl._null({
    required this.element3,
    super.alias,
  })  : typeArguments = const [],
        nullabilitySuffix = NullabilitySuffix.none {
    assert(element3.name3 == 'Null' && element3.library2.isDartCore);
    assert(this is NullTypeImpl);
  }

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors == null) {
      List<PropertyAccessorElement> accessors = element.accessors;
      var members = <PropertyAccessorElement>[];
      for (int i = 0; i < accessors.length; i++) {
        members.add(PropertyAccessorMember.from(accessors[i], this)!);
      }
      _accessors = members;
    }
    return _accessors!;
  }

  @override
  List<InterfaceTypeImpl> get allSupertypes {
    var substitution = Substitution.fromInterfaceType(this);
    return element.allSupertypes
        .map((t) => (substitution.substituteType(t) as InterfaceTypeImpl)
            .withNullability(nullabilitySuffix))
        .toList();
  }

  @override
  List<ConstructorElement> get constructors {
    return _constructors ??= element.constructors.map((constructor) {
      return ConstructorMember.from(constructor, this);
    }).toFixedList();
  }

  @override
  List<ConstructorElement2> get constructors2 => constructors
      .map((fragment) => switch (fragment) {
            ConstructorFragment(:var element) => element,
            ConstructorMember() => fragment,
            _ => throw StateError(
                'unexpected fragment type: ${fragment.runtimeType}',
              )
          })
      .toList();

  @override
  InterfaceElementImpl get element => element3.asElement;

  @override
  List<GetterElement> get getters => accessors
      .where((accessor) => accessor.isGetter)
      .map((fragment) => switch (fragment) {
            GetterFragment(:var element) => element as GetterElement,
            GetterMember() => fragment,
            _ => throw StateError(
                'unexpected fragment type: ${fragment.runtimeType}',
              )
          })
      .toList();

  @override
  int get hashCode {
    return element.hashCode;
  }

  @override
  List<InterfaceType> get interfaces {
    return _instantiateSuperTypes(element.interfaces);
  }

  @override
  bool get isDartAsyncFuture {
    return element.name == "Future" && element.library.isDartAsync;
  }

  @override
  bool get isDartAsyncStream {
    return element.name == "Stream" && element.library.isDartAsync;
  }

  @override
  bool get isDartCoreBool {
    return element.name == "bool" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreDouble {
    return element.name == "double" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreEnum {
    var element = this.element;
    return element is ClassElementImpl && element.isDartCoreEnum;
  }

  @override
  bool get isDartCoreFunction {
    return element.name == "Function" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreInt {
    return element.name == "int" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreIterable {
    return element.name == "Iterable" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreList {
    return element.name == "List" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreMap {
    return element.name == "Map" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreNum {
    return element.name == "num" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreObject {
    return element.name == "Object" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreRecord {
    return element.name == "Record" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreSet {
    return element.name == "Set" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreString {
    return element.name == "String" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreSymbol {
    return element.name == "Symbol" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreType {
    return element.name == "Type" && element.library.isDartCore;
  }

  @override
  List<MethodElement> get methods {
    if (_methods == null) {
      List<MethodElement> methods = element.methods;
      var members = <MethodElement>[];
      for (int i = 0; i < methods.length; i++) {
        members.add(MethodMember.from(methods[i], this)!);
      }
      _methods = members;
    }
    return _methods!;
  }

  @override
  List<MethodElement2> get methods2 =>
      methods.map((e) => e.asElement2).toList();

  @override
  List<InterfaceType> get mixins {
    return _instantiateSuperTypes(element.mixins);
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => element.name;

  /// The instantiated representation type, if [element] is an extension type.
  DartType? get representationType {
    if (element case ExtensionTypeElement element) {
      var substitution = Substitution.fromInterfaceType(this);
      var representationType = element.representation.type;
      return substitution.substituteType(representationType);
    }
    return null;
  }

  @override
  List<SetterElement> get setters => accessors
      .where((accessor) => accessor.isSetter)
      .map((fragment) => switch (fragment) {
            SetterFragment(:var element) => element as SetterElement,
            SetterMember() => fragment,
            _ => throw StateError(
                'unexpected fragment type: ${fragment.runtimeType}',
              )
          })
      .toList();

  @override
  InterfaceType? get superclass {
    var supertype = element.supertype;
    if (supertype == null) {
      return null;
    }

    return (Substitution.fromInterfaceType(this).substituteType(supertype)
            as InterfaceTypeImpl)
        .withNullability(nullabilitySuffix);
  }

  @override
  List<InterfaceTypeImpl> get superclassConstraints {
    var element = this.element;
    var augmented = element.augmented;
    if (augmented is MixinElementImpl2) {
      var constraints = augmented.superclassConstraints;
      return _instantiateSuperTypes(constraints);
    } else {
      return [];
    }
  }

  InheritanceManager3 get _inheritanceManager =>
      element.library.session.inheritanceManager;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is InterfaceTypeImpl) {
      if (!identical(other.element, element)) {
        return false;
      }
      if (other.nullabilitySuffix != nullabilitySuffix) {
        return false;
      }
      return TypeImpl.equalArrays(other.typeArguments, typeArguments);
    }
    return false;
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitInterfaceType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitInterfaceType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeInterfaceType(this);
  }

  @override
  InterfaceTypeImpl? asInstanceOf(InterfaceElement targetElement) {
    if (element == targetElement) {
      return this;
    }

    for (var rawInterface in element.allSupertypes) {
      if (rawInterface.element == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.substituteType(rawInterface) as InterfaceTypeImpl;
      }
    }

    return null;
  }

  @override
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement2 targetElement) {
    if ((element as InterfaceFragment).element == targetElement) {
      return this;
    }

    for (var rawInterface in element.allSupertypes) {
      var realElement = (rawInterface.element as InterfaceFragment).element;
      if (realElement == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.substituteType(rawInterface) as InterfaceTypeImpl;
      }
    }

    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) =>
      PropertyAccessorMember.from(element.getGetter(getterName), this);

  @override
  MethodElementOrMember? getMethod(String methodName) =>
      MethodMember.from(element.getMethod(methodName), this);

  @override
  MethodElement2? getMethod2(String methodName) {
    return getMethod(methodName)?.asElement2;
  }

  @override
  PropertyAccessorElement? getSetter(String setterName) =>
      PropertyAccessorMember.from(element.getSetter(setterName), this);

  @override
  ConstructorElement? lookUpConstructor(
      String? constructorName, LibraryElement library) {
    var augmented = element.augmented;

    // prepare base ConstructorElement
    ConstructorElement? constructorElement;
    if (constructorName == null) {
      constructorElement = augmented.unnamedConstructor;
    } else {
      constructorElement = augmented.getNamedConstructor(constructorName);
    }
    // not found or not accessible
    if (constructorElement == null ||
        !constructorElement.isAccessibleIn(library)) {
      return null;
    }
    // return member
    return ConstructorMember.from(constructorElement, this);
  }

  @override
  PropertyAccessorElement? lookUpGetter2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.source.uri, name);

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember(this, nameObj, forSuper: inherited);
        if (result is PropertyAccessorElementOrMember) {
          return result;
        }
      } else {
        var result = inheritance.getInherited(this, nameObj);
        if (result is PropertyAccessorElement) {
          return result;
        }
      }
      return null;
    }

    var result = inheritance.getMember(this, nameObj, concrete: concrete);
    if (result is PropertyAccessorElementOrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element.lookupStaticGetter(name, library);
    }

    return null;
  }

  @override
  GetterElement? lookUpGetter3(
    String name,
    LibraryElement2 library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    return lookUpGetter2(
      name,
      library.asElement,
      concrete: concrete,
      inherited: inherited,
      recoveryStatic: recoveryStatic,
    )?.asElement2.ifTypeOrNull();
  }

  @override
  MethodElement? lookUpMethod2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.source.uri, name);

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember(this, nameObj, forSuper: inherited);
        if (result is MethodElementOrMember) {
          return result;
        }
      } else {
        var result = inheritance.getInherited(this, nameObj);
        if (result is MethodElement) {
          return result;
        }
      }
      return null;
    }

    var result = inheritance.getMember(this, nameObj, concrete: concrete);
    if (result is MethodElementOrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element.lookupStaticMethod(name, library);
    }

    return null;
  }

  @override
  MethodElement2? lookUpMethod3(
    String name,
    LibraryElement2 library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    return lookUpMethod2(
      name,
      library.asElement,
      concrete: concrete,
      inherited: inherited,
      recoveryStatic: recoveryStatic,
    )?.asElement2;
  }

  @override
  PropertyAccessorElement? lookUpSetter2(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.source.uri, '$name=');

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember(this, nameObj, forSuper: inherited);
        if (result is PropertyAccessorElementOrMember) {
          return result;
        }
      } else {
        var result = inheritance.getInherited(this, nameObj);
        if (result is PropertyAccessorElement) {
          return result;
        }
      }
      return null;
    }

    var result = inheritance.getMember(this, nameObj, concrete: concrete);
    if (result is PropertyAccessorElementOrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element.lookupStaticSetter(name, library);
    }

    return null;
  }

  @override
  SetterElement? lookUpSetter3(
    String name,
    LibraryElement2 library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    return lookUpSetter2(
      name,
      library.asElement,
      concrete: concrete,
      inherited: inherited,
      recoveryStatic: recoveryStatic,
    )?.asElement2.ifTypeOrNull();
  }

  @override
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return typeArguments.any((argument) => argument.referencesAny(parameters));
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl2> parameters) {
    return typeArguments.any((argument) => argument.referencesAny2(parameters));
  }

  @override
  InterfaceTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;

    return InterfaceTypeImpl(
      element: element3,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
      alias: alias,
    );
  }

  List<InterfaceTypeImpl> _instantiateSuperTypes(
      List<InterfaceTypeImpl> definedTypes) {
    if (definedTypes.isEmpty) return definedTypes;

    MapSubstitution? substitution;
    if (element.typeParameters.isNotEmpty) {
      substitution = Substitution.fromInterfaceType(this);
    }

    List<InterfaceTypeImpl> results = [];
    for (var definedType in definedTypes) {
      var result = substitution != null
          ? substitution.substituteType(definedType)
          : definedType;
      result as InterfaceTypeImpl;
      result = result.withNullability(nullabilitySuffix);
      results.add(result);
    }
    return results;
  }
}

class InvalidTypeImpl extends TypeImpl
    implements InvalidType, SharedInvalidType {
  /// The unique instance of this class.
  static final InvalidTypeImpl instance = InvalidTypeImpl._();

  /// Prevent the creation of instances of this class.
  InvalidTypeImpl._();

  @override
  Null get element => null;

  @override
  Null get element3 => null;

  @override
  int get hashCode => 1;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitInvalidType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitInvalidType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeInvalidType();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    return this;
  }
}

/// The type `Never` represents the uninhabited bottom type.
class NeverTypeImpl extends TypeImpl implements NeverType {
  /// The unique instance of this class, nullable.
  static final NeverTypeImpl instanceNullable =
      NeverTypeImpl._(NullabilitySuffix.question);

  /// The unique instance of this class, non-nullable.
  static final NeverTypeImpl instance = NeverTypeImpl._(NullabilitySuffix.none);

  @override
  final NeverElementImpl element = NeverElementImpl.instance;

  @override
  final NeverElementImpl2 element3 = NeverElementImpl2.instance;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Prevent the creation of instances of this class.
  NeverTypeImpl._(this.nullabilitySuffix);

  @override
  int get hashCode => 0;

  @override
  bool get isBottom => nullabilitySuffix != NullabilitySuffix.question;

  @override
  bool get isDartCoreNull {
    // `Never?` is equivalent to `Null`, so make sure it behaves the same.
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => 'Never';

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitNeverType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitNeverType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeNeverType(this);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        return instanceNullable;
      case NullabilitySuffix.star:
        // TODO(scheglov): remove together with `star`
        return instanceNullable;
      case NullabilitySuffix.none:
        return instance;
    }
  }
}

/// A concrete implementation of [DartType] representing the type `Null`, with
/// no type parameters and no nullability suffix.
class NullTypeImpl extends InterfaceTypeImpl implements SharedNullType {
  NullTypeImpl({
    required super.element3,
    super.alias,
  }) : super._null();

  @override
  bool get isDartCoreNull => true;

  @override
  NullTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;
}

abstract class RecordTypeFieldImpl implements RecordTypeField {
  @override
  final TypeImpl type;

  RecordTypeFieldImpl({
    required DartType type,
  }) :
        // TODO(paulberry): eliminate this cast by changing the type of the
        // constructor parameter to `TypeImpl`.
        type = type as TypeImpl;
}

class RecordTypeImpl extends TypeImpl implements RecordType, SharedRecordType {
  @override
  final List<RecordTypePositionalFieldImpl> positionalFields;

  @override
  final List<RecordTypeNamedFieldImpl> namedFields;

  @override
  final NullabilitySuffix nullabilitySuffix;

  @override
  late final List<TypeImpl> positionalTypes = [
    for (var field in positionalFields) field.type
  ];

  RecordTypeImpl({
    required this.positionalFields,
    required List<RecordTypeNamedFieldImpl> namedFields,
    required this.nullabilitySuffix,
    super.alias,
  }) : namedFields = _sortNamedFields(namedFields);

  factory RecordTypeImpl.fromApi({
    required List<DartType> positional,
    required Map<String, DartType> named,
    required NullabilitySuffix nullabilitySuffix,
  }) {
    return RecordTypeImpl(
      positionalFields: [
        for (var type in positional) RecordTypePositionalFieldImpl(type: type),
      ],
      namedFields: [
        for (var entry in named.entries)
          RecordTypeNamedFieldImpl(name: entry.key, type: entry.value),
      ],
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  Null get element => null;

  @override
  Null get element3 => null;

  @override
  int get hashCode {
    return Object.hash(
      positionalFields.length,
      namedFields.length,
    );
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String? get name => null;

  List<RecordTypeNamedFieldImpl> get namedTypes => namedFields;

  @override
  List<TypeImpl> get positionalTypesShared => positionalTypes;

  @override
  List<RecordTypeNamedFieldImpl> get sortedNamedTypes => namedTypes;

  @override
  List<SharedNamedType> get sortedNamedTypesShared => sortedNamedTypes;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is! RecordTypeImpl) {
      return false;
    }

    if (other.nullabilitySuffix != nullabilitySuffix) {
      return false;
    }

    var thisPositional = positionalFields;
    var otherPositional = other.positionalFields;
    if (thisPositional.length != otherPositional.length) {
      return false;
    }
    for (var i = 0; i < thisPositional.length; i++) {
      var thisField = thisPositional[i];
      var otherField = otherPositional[i];
      if (thisField.type != otherField.type) {
        return false;
      }
    }

    var thisNamed = namedFields;
    var otherNamed = other.namedFields;
    if (thisNamed.length != otherNamed.length) {
      return false;
    }
    for (var i = 0; i < thisNamed.length; i++) {
      var thisField = thisNamed[i];
      var otherField = otherNamed[i];
      if (thisField.name != otherField.name ||
          thisField.type != otherField.type) {
        return false;
      }
    }

    return true;
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitRecordType(this);
  }

  @override
  R acceptWithArgument<R, A>(
      TypeVisitorWithArgument<R, A> visitor, A argument) {
    return visitor.visitRecordType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeRecordType(this);
  }

  @override
  RecordTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) {
      return this;
    }

    return RecordTypeImpl(
      positionalFields: positionalFields,
      namedFields: namedFields,
      nullabilitySuffix: nullabilitySuffix,
      alias: alias,
    );
  }

  /// Returns [fields], if already sorted, or the sorted copy.
  static List<RecordTypeNamedFieldImpl> _sortNamedFields(
    List<RecordTypeNamedFieldImpl> fields,
  ) {
    var isSorted = true;
    String? lastName;
    for (var field in fields) {
      var name = field.name;
      if (lastName != null && lastName.compareTo(name) > 0) {
        isSorted = false;
        break;
      }
      lastName = name;
    }

    if (isSorted) {
      return fields;
    }

    return fields.sortedBy((field) => field.name);
  }
}

class RecordTypeNamedFieldImpl extends RecordTypeFieldImpl
    implements RecordTypeNamedField, SharedNamedType {
  @override
  final String name;

  RecordTypeNamedFieldImpl({
    required this.name,
    required super.type,
  });

  @override
  String get nameShared => name;

  @override
  TypeImpl get typeShared => type;
}

class RecordTypePositionalFieldImpl extends RecordTypeFieldImpl
    implements RecordTypePositionalField {
  RecordTypePositionalFieldImpl({
    required super.type,
  });
}

/// The abstract class `TypeImpl` implements the behavior common to objects
/// representing the declared type of elements in the element model.
abstract class TypeImpl implements DartType {
  @override
  final InstantiatedTypeAliasElement? alias;

  /// Initialize a newly created type.
  const TypeImpl({this.alias});

  @override
  TypeImpl get extensionTypeErasure {
    return const ExtensionTypeErasure().perform(this);
  }

  @override
  bool get isBottom => false;

  @override
  bool get isDartAsyncFuture => false;

  @override
  bool get isDartAsyncFutureOr => false;

  @override
  bool get isDartAsyncStream => false;

  @override
  bool get isDartCoreBool => false;

  @override
  bool get isDartCoreDouble => false;

  @override
  bool get isDartCoreEnum => false;

  @override
  bool get isDartCoreFunction => false;

  @override
  bool get isDartCoreInt => false;

  @override
  bool get isDartCoreIterable => false;

  @override
  bool get isDartCoreList => false;

  @override
  bool get isDartCoreMap => false;

  @override
  bool get isDartCoreNull => false;

  @override
  bool get isDartCoreNum => false;

  @override
  bool get isDartCoreObject => false;

  @override
  bool get isDartCoreRecord => false;

  @override
  bool get isDartCoreSet => false;

  @override
  bool get isDartCoreString => false;

  @override
  bool get isDartCoreSymbol => false;

  @override
  bool get isDartCoreType => false;

  @override
  NullabilitySuffix get nullabilitySuffix;

  /// Append a textual representation of this type to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  InterfaceTypeImpl? asInstanceOf(InterfaceElement targetElement) => null;

  @override
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement2 targetElement) => null;

  @override
  String getDisplayString({
    @Deprecated('Only non-nullable by default mode is supported')
    bool withNullability = true,
    bool preferTypeAlias = false,
  }) {
    var builder = ElementDisplayStringBuilder(
      // ignore:deprecated_member_use_from_same_package
      withNullability: withNullability,
      preferTypeAlias: preferTypeAlias,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  bool isStructurallyEqualTo(SharedType other) => this == other;

  /// Returns true if this type references any of the [parameters].
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return false;
  }

  bool referencesAny2(Set<TypeParameterElementImpl2> parameters) {
    return false;
  }

  @override
  String toString() {
    return getDisplayString();
  }

  /// Return the same type, but with the given [nullabilitySuffix].
  ///
  /// If the nullability of `this` already matches [nullabilitySuffix], `this`
  /// is returned.
  ///
  /// Note: this method just does low-level manipulations of the underlying
  /// type, so it is what you want if you are constructing a fresh type and want
  /// it to have the correct nullability suffix, but it is generally *not* what
  /// you want if you're manipulating existing types.  For manipulating existing
  /// types, please use the methods in [TypeSystemImpl].
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix);

  /// Return `true` if corresponding elements of the [first] and [second] lists
  /// of type arguments are all equal.
  static bool equalArrays(List<DartType> first, List<DartType> second) {
    if (first.length != second.length) {
      return false;
    }
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) {
        return false;
      }
    }
    return true;
  }
}

/// A concrete implementation of a [TypeParameterType].
class TypeParameterTypeImpl extends TypeImpl implements TypeParameterType {
  @override
  final TypeParameterElementImpl element;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [element].
  final TypeImpl? promotedBound;

  /// Initialize a newly created type parameter type to be declared by the given
  /// [element] and to have the given name.
  TypeParameterTypeImpl({
    required TypeParameterElement element,
    required this.nullabilitySuffix,
    DartType? promotedBound,
    super.alias,
  })  :
        // TODO(paulberry): change the type of the parameter `element` so
        // that this cast isn't needed.
        element = element as TypeParameterElementImpl,
        // TODO(paulberry): change the type of the parameter `promotedBound` so
        // that this cast isn't needed.
        promotedBound = promotedBound as TypeImpl?;

  /// Initialize a newly created type parameter type to be declared by the given
  /// [element] and to have the given name.
  factory TypeParameterTypeImpl.v2({
    required TypeParameterElement2 element,
    required NullabilitySuffix nullabilitySuffix,
    DartType? promotedBound,
    InstantiatedTypeAliasElement? alias,
  }) {
    return TypeParameterTypeImpl(
      element: element.asElement,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
      alias: alias,
    );
  }

  @override
  TypeImpl get bound =>
      promotedBound ?? element.bound ?? DynamicTypeImpl.instance;

  @override
  ElementLocation get definition => element.location;

  @override
  TypeParameterElementImpl2 get element3 => element.element;

  @override
  int get hashCode => element.hashCode;

  @override
  bool get isBottom {
    // In principle we ought to be able to do `return bound.isBottom;`, but that
    // goes into an infinite loop with illegal code in which type parameter
    // bounds form a loop.  So we have to be more careful.
    Set<TypeParameterElement> seenTypes = {};
    TypeParameterType type = this;
    while (seenTypes.add(type.element)) {
      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        return false;
      }
      var bound = type.bound;
      if (bound is TypeParameterType) {
        type = bound;
      } else {
        return bound.isBottom;
      }
    }
    // Infinite loop.
    return false;
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => element.name;

  TypeParameterTypeImpl get withoutPromotedBound {
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is TypeParameterTypeImpl && other.element == element) {
      if (other.nullabilitySuffix != nullabilitySuffix) {
        return false;
      }
      return other.promotedBound == promotedBound;
    }

    return false;
  }

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitTypeParameterType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitTypeParameterType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeTypeParameterType(this);
  }

  @override
  InterfaceTypeImpl? asInstanceOf(InterfaceElement targetElement) {
    return bound.asInstanceOf(targetElement);
  }

  @override
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement2 targetElement) {
    return bound.asInstanceOf2(targetElement);
  }

  @override
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return parameters.contains(element);
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl2> parameters) {
    return parameters.contains(element3);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return TypeParameterTypeImpl(
      element: element,
      nullabilitySuffix: nullabilitySuffix,
      promotedBound: promotedBound,
    );
  }
}

/// A concrete implementation of a [VoidType].
class VoidTypeImpl extends TypeImpl implements VoidType, SharedVoidType {
  /// The unique instance of this class, with indeterminate nullability.
  static final VoidTypeImpl instance = VoidTypeImpl._();

  /// Prevent the creation of instances of this class.
  VoidTypeImpl._();

  @override
  Null get element => null;

  @override
  Null get element3 => null;

  @override
  int get hashCode => 2;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.VOID.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object other) => identical(other, this);

  @override
  R accept<R>(TypeVisitor<R> visitor) {
    return visitor.visitVoidType(this);
  }

  @override
  R acceptWithArgument<R, A>(
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
    return visitor.visitVoidType(this, argument);
  }

  @override
  void appendTo(ElementDisplayStringBuilder builder) {
    builder.writeVoidType();
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    // The void type is always nullable.
    return this;
  }
}
