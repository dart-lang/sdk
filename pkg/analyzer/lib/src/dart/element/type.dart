// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';
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
    implements DynamicType, SharedDynamicTypeStructure<DartType> {
  /// The unique instance of this class.
  static final DynamicTypeImpl instance = DynamicTypeImpl._();

  @override
  final DynamicElementImpl element = DynamicElementImpl();

  /// Prevent the creation of instances of this class.
  DynamicTypeImpl._();

  @Deprecated('Use element instead')
  @override
  DynamicElementImpl get element2 => element;

  @override
  Element2? get element3 => (element as Fragment).element;

  @override
  int get hashCode => 1;

  @Deprecated('Use `is DynamicType` instead')
  @override
  bool get isDynamic => true;

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
class FunctionTypeImpl extends TypeImpl implements FunctionType {
  @override
  late int hashCode = _computeHashCode();

  @override
  final DartType returnType;

  @override
  final List<TypeParameterElement> typeFormals;

  @override
  final List<ParameterElement> parameters;

  @override
  final NullabilitySuffix nullabilitySuffix;

  @override
  final List<DartType> positionalParameterTypes;

  @override
  final int requiredPositionalParameterCount;

  @override
  final List<ParameterElement> sortedNamedParameters;

  factory FunctionTypeImpl({
    required List<TypeParameterElement> typeFormals,
    required List<ParameterElement> parameters,
    required DartType returnType,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElement? alias,
  }) {
    int? firstNamedParameterIndex;
    var requiredPositionalParameterCount = 0;
    var positionalParameterTypes = <DartType>[];
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
        positionalParameterTypes.add(parameter.type);
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
        typeFormals: typeFormals,
        parameters: parameters,
        returnType: returnType,
        nullabilitySuffix: nullabilitySuffix,
        positionalParameterTypes: positionalParameterTypes,
        requiredPositionalParameterCount: requiredPositionalParameterCount,
        sortedNamedParameters: sortedNamedParameters,
        alias: alias);
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

  @Deprecated('Use element instead')
  @override
  Null get element2 => element;

  @override
  Null get element3 => null;

  @override
  List<FormalParameterElement> get formalParameters => parameters
      .map((fragment) => (fragment as FormalParameterFragment).element)
      .toList();

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String? get name => null;

  @override
  Map<String, DartType> get namedParameterTypes => {
        for (var parameter in sortedNamedParameters)
          parameter.name: parameter.type
      };

  @override
  List<String> get normalParameterNames => parameters
      .where((p) => p.isRequiredPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<DartType> get normalParameterTypes =>
      positionalParameterTypes.sublist(0, requiredPositionalParameterCount);

  @override
  List<String> get optionalParameterNames => parameters
      .where((p) => p.isOptionalPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<DartType> get optionalParameterTypes =>
      positionalParameterTypes.sublist(requiredPositionalParameterCount);

  @override
  List<TypeParameterElement2> get typeParameters => typeFormals
      .map((fragment) => (fragment as TypeParameterFragment).element)
      .toList();

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
      var elementImpl = element as TypeParameterElementImpl;
      assert(!parameters.contains(elementImpl));

      var bound = elementImpl.bound as TypeImpl?;
      if (bound != null && bound.referencesAny(parameters)) {
        return true;
      }

      var defaultType = elementImpl.defaultType as TypeImpl;
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

    return (returnType as TypeImpl).referencesAny(parameters);
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
        namedParameterInfo.add(namedParameter.type);
      }
    }

    return Object.hash(
        nullabilitySuffix,
        returnType,
        requiredPositionalParameterCount,
        Object.hashAll(positionalParameterTypes),
        namedParameterInfo);
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

class InstantiatedTypeAliasElementImpl implements InstantiatedTypeAliasElement {
  @override
  final TypeAliasElement element;

  @override
  final List<DartType> typeArguments;

  InstantiatedTypeAliasElementImpl({
    required this.element,
    required this.typeArguments,
  });

  @override
  TypeAliasElement2 get element2 => (element as TypeAliasFragment).element;
}

/// A concrete implementation of an [InterfaceType].
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  @override
  final InterfaceElement element;

  @override
  final List<DartType> typeArguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Cached [ConstructorElement]s - members or raw elements.
  List<ConstructorElement>? _constructors;

  /// Cached [PropertyAccessorElement]s - members or raw elements.
  List<PropertyAccessorElement>? _accessors;

  /// Cached [MethodElement]s - members or raw elements.
  List<MethodElement>? _methods;

  InterfaceTypeImpl({
    required this.element,
    required this.typeArguments,
    required this.nullabilitySuffix,
    super.alias,
  }) {
    if (element.augmentationTarget != null) {
      throw ArgumentError(
        'InterfaceType(s) can only be created for declarations',
      );
    }
    var typeParameters = element.typeParameters;
    if (typeArguments.length != typeParameters.length) {
      throw ArgumentError(
        '[typeParameters.length: ${typeParameters.length}]'
        '[typeArguments.length: ${typeArguments.length}]'
        '[element: $element]'
        '[typeParameters: $typeParameters]'
        '[typeArguments: $typeArguments]',
      );
    }
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
  List<InterfaceType> get allSupertypes {
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
      .map((fragment) => (fragment as ConstructorFragment).element)
      .toList();

  @Deprecated('Use element instead')
  @override
  InterfaceElement get element2 => element;

  @override
  InterfaceElement2 get element3 => (element as InterfaceFragment).element;

  @override
  List<GetterElement> get getters => accessors
      .where((accessor) => accessor.isGetter)
      .map((fragment) => (fragment as GetterFragment).element as GetterElement)
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
  bool get isDartAsyncFutureOr {
    return element.name == "FutureOr" && element.library.isDartAsync;
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
    return element is ClassElement && element.isDartCoreEnum;
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
  bool get isDartCoreNull {
    return element.name == "Null" && element.library.isDartCore;
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
      methods.map((fragment) => (fragment as MethodFragment).element).toList();

  @override
  List<InterfaceType> get mixins {
    List<InterfaceType> mixins = element.mixins;
    return _instantiateSuperTypes(mixins);
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
      .map((fragment) => (fragment as SetterFragment).element as SetterElement)
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
  List<InterfaceType> get superclassConstraints {
    var element = this.element;
    var augmented = element.augmented;
    if (augmented is AugmentedMixinElement) {
      var constraints = augmented.superclassConstraints;
      return _instantiateSuperTypes(constraints);
    } else {
      return [];
    }
  }

  InheritanceManager3 get _inheritanceManager =>
      (element.library.session as AnalysisSessionImpl).inheritanceManager;

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
  InterfaceType? asInstanceOf(InterfaceElement targetElement) {
    if (element == targetElement) {
      return this;
    }

    for (var rawInterface in element.allSupertypes) {
      if (rawInterface.element == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.substituteType(rawInterface) as InterfaceType;
      }
    }

    return null;
  }

  @override
  InterfaceType? asInstanceOf2(InterfaceElement2 targetElement) {
    if ((element as InterfaceFragment).element == targetElement) {
      return this;
    }

    for (var rawInterface in element.allSupertypes) {
      var realElement = (rawInterface.element as InterfaceFragment).element;
      if (realElement == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.substituteType(rawInterface) as InterfaceType;
      }
    }

    return null;
  }

  @override
  PropertyAccessorElement? getGetter(String getterName) =>
      PropertyAccessorMember.from(element.getGetter(getterName), this);

  @override
  MethodElement? getMethod(String methodName) =>
      MethodMember.from(element.getMethod(methodName), this);

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
        if (result is PropertyAccessorElement) {
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
    if (result is PropertyAccessorElement) {
      return result;
    }

    if (recoveryStatic) {
      var element = this.element as InterfaceElementImpl;
      return element.lookupStaticGetter(name, library);
    }

    return null;
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
        if (result is MethodElement) {
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
    if (result is MethodElement) {
      return result;
    }

    if (recoveryStatic) {
      var element = this.element as InterfaceElementImpl;
      return element.lookupStaticMethod(name, library);
    }

    return null;
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
        if (result is PropertyAccessorElement) {
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
    if (result is PropertyAccessorElement) {
      return result;
    }

    if (recoveryStatic) {
      var element = this.element as InterfaceElementImpl;
      return element.lookupStaticSetter(name, library);
    }

    return null;
  }

  @override
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return typeArguments.any((argument) {
      var argumentImpl = argument as TypeImpl;
      return argumentImpl.referencesAny(parameters);
    });
  }

  @override
  InterfaceTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;

    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
      alias: alias,
    );
  }

  List<InterfaceType> _instantiateSuperTypes(List<InterfaceType> definedTypes) {
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
    implements InvalidType, SharedInvalidTypeStructure<DartType> {
  /// The unique instance of this class.
  static final InvalidTypeImpl instance = InvalidTypeImpl._();

  /// Prevent the creation of instances of this class.
  InvalidTypeImpl._();

  @override
  Null get element => null;

  @Deprecated('Use element instead')
  @override
  Null get element2 => element;

  @override
  Null get element3 => null;

  @override
  int get hashCode => 1;

  @Deprecated('Use `is DynamicType` instead')
  @override
  bool get isDynamic => true;

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
  final NullabilitySuffix nullabilitySuffix;

  /// Prevent the creation of instances of this class.
  NeverTypeImpl._(this.nullabilitySuffix);

  @Deprecated('Use element instead')
  @override
  Element? get element2 => element;

  @override
  // TODO(augmentations): Implement this.
  Element2? get element3 => throw UnimplementedError();

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

abstract class RecordTypeFieldImpl implements RecordTypeField {
  @override
  final DartType type;

  RecordTypeFieldImpl({
    required this.type,
  });
}

class RecordTypeImpl extends TypeImpl implements RecordType {
  @override
  final List<RecordTypePositionalFieldImpl> positionalFields;

  @override
  final List<RecordTypeNamedFieldImpl> namedFields;

  @override
  final NullabilitySuffix nullabilitySuffix;

  @override
  late final List<DartType> positionalTypes = [
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

  @Deprecated('Use element instead')
  @override
  Null get element2 => element;

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

  @override
  List<SharedNamedTypeStructure<DartType>> get namedTypes => namedFields;

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
    implements RecordTypeNamedField {
  @override
  final String name;

  RecordTypeNamedFieldImpl({
    required this.name,
    required super.type,
  });
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
  DartType get extensionTypeErasure {
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

  @Deprecated('Use `is DynamicType` instead')
  @override
  bool get isDynamic => false;

  @override
  bool get isVoid => false;

  @override
  NullabilitySuffix get nullabilitySuffix;

  /// Append a textual representation of this type to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  InterfaceType? asInstanceOf(InterfaceElement targetElement) => null;

  @override
  InterfaceType? asInstanceOf2(InterfaceElement2 targetElement) => null;

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
  bool isStructurallyEqualTo(SharedTypeStructure other) => this == other;

  /// Returns true if this type references any of the [parameters].
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return false;
  }

  @Deprecated('Use TypeSystem.resolveToBound() instead')
  @override
  DartType resolveToBound(DartType objectType) => this;

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
  final TypeParameterElement element;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [element].
  final DartType? promotedBound;

  /// Initialize a newly created type parameter type to be declared by the given
  /// [element] and to have the given name.
  TypeParameterTypeImpl({
    required this.element,
    required this.nullabilitySuffix,
    this.promotedBound,
    super.alias,
  });

  @override
  DartType get bound =>
      promotedBound ?? element.bound ?? DynamicTypeImpl.instance;

  @override
  ElementLocation get definition => element.location!;

  @Deprecated('Use element instead')
  @override
  TypeParameterElement get element2 => element;

  @override
  TypeParameterElement2 get element3 =>
      (element as TypeParameterFragment).element;

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
  InterfaceType? asInstanceOf(InterfaceElement targetElement) {
    return bound.asInstanceOf(targetElement);
  }

  @override
  InterfaceType? asInstanceOf2(InterfaceElement2 targetElement) {
    return bound.asInstanceOf2(targetElement);
  }

  @override
  bool referencesAny(Set<TypeParameterElement> parameters) {
    return parameters.contains(element);
  }

  @Deprecated('Use TypeSystem.resolveToBound() instead')
  @override
  DartType resolveToBound(DartType objectType) {
    var promotedBound = this.promotedBound;
    if (promotedBound != null) {
      return promotedBound.resolveToBound(objectType);
    }

    var bound = element.bound;
    if (bound == null) {
      return objectType;
    }

    NullabilitySuffix newNullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question ||
        bound.nullabilitySuffix == NullabilitySuffix.question) {
      newNullabilitySuffix = NullabilitySuffix.question;
    } else {
      newNullabilitySuffix = NullabilitySuffix.none;
    }

    return (bound.resolveToBound(objectType) as TypeImpl)
        .withNullability(newNullabilitySuffix);
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
class VoidTypeImpl extends TypeImpl
    implements VoidType, SharedVoidTypeStructure<DartType> {
  /// The unique instance of this class, with indeterminate nullability.
  static final VoidTypeImpl instance = VoidTypeImpl._();

  /// Prevent the creation of instances of this class.
  VoidTypeImpl._();

  @override
  Null get element => null;

  @Deprecated('Use element instead')
  @override
  Null get element2 => element;

  @override
  Null get element3 => null;

  @override
  int get hashCode => 2;

  @Deprecated('Use `is VoidType` instead')
  @override
  bool get isVoid => true;

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
