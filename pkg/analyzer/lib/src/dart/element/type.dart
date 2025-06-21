// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
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
import 'package:collection/collection.dart';

/// Returns a [List] of fixed length with given types.
List<TypeImpl> fixedTypeList(TypeImpl e1, [TypeImpl? e2]) {
  if (e2 != null) {
    var result = List<TypeImpl>.filled(2, e1);
    result[1] = e2;
    return result;
  } else {
    return List<TypeImpl>.filled(1, e1);
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
  DynamicElementImpl get element3 => DynamicElementImpl.instance;

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

  /// The formal type parameters of this generic function; for example,
  /// `<T> T -> T`.
  final List<TypeParameterFragmentImpl> typeFormals;

  /// A list containing the parameters elements of this type of function.
  ///
  /// The parameter types are not necessarily in the same order as they appear
  /// in the declaration of the function.
  final List<FormalParameterElementMixin> parameters;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// All the positional parameter types, starting with the required ones, and
  /// followed by the optional ones.
  ///
  /// Deprecated: this getter is a part of the analyzer's private
  /// implementation, and was exposed by accident (see
  /// https://github.com/dart-lang/sdk/issues/59763). Please use
  /// [normalParameterTypes] and [optionalParameterTypes] instead.
  final List<TypeImpl> positionalParameterTypes;

  @override
  final int requiredPositionalParameterCount;

  /// All the named parameters, sorted by name.
  ///
  /// Deprecated: this getter is a part of the analyzer's private
  /// implementation, and was exposed by accident (see
  /// https://github.com/dart-lang/sdk/issues/59763). Please use [parameters]
  /// instead.
  final List<FormalParameterElementMixin> sortedNamedParameters;

  factory FunctionTypeImpl({
    required List<TypeParameterFragmentImpl> typeFormals,
    required List<FormalParameterElementMixin> parameters,
    required TypeImpl returnType,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElementImpl? alias,
  }) {
    int? firstNamedParameterIndex;
    var requiredPositionalParameterCount = 0;
    var positionalParameterTypes = <TypeImpl>[];
    List<FormalParameterElementMixin> sortedNamedParameters;

    // Check if already sorted.
    var namedParametersAlreadySorted = true;
    var lastNamedParameterName = '';
    for (var i = 0; i < parameters.length; ++i) {
      var parameter = parameters[i];
      if (parameter.isNamed) {
        firstNamedParameterIndex ??= i;
        var name = parameter.name3 ?? '';
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
    sortedNamedParameters =
        firstNamedParameterIndex == null
            ? const []
            : parameters.sublist(firstNamedParameterIndex, parameters.length);
    if (!namedParametersAlreadySorted) {
      // Sort named parameters.
      sortedNamedParameters.sort(
        (a, b) => (a.name3 ?? '').compareTo(b.name3 ?? ''),
      );

      // Combine into a new list, with sorted named parameters.
      parameters = parameters.toList();
      parameters.replaceRange(
        firstNamedParameterIndex!,
        parameters.length,
        sortedNamedParameters,
      );
    }
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

  factory FunctionTypeImpl.v2({
    required List<TypeParameterElementImpl> typeParameters,
    required List<FormalParameterElementMixin> formalParameters,
    required TypeImpl returnType,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElementImpl? alias,
  }) {
    return FunctionTypeImpl(
      typeFormals: typeParameters.map((e) => e.asElement).toList(),
      parameters: formalParameters,
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
  Null get element3 => null;

  @override
  List<FormalParameterElementMixin> get formalParameters {
    return parameters;
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String? get name => null;

  @override
  Map<String, TypeImpl> get namedParameterTypes => {
    for (var parameter in sortedNamedParameters)
      parameter.name3 ?? '': parameter.type,
  };

  @override
  List<TypeImpl> get normalParameterTypes =>
      positionalParameterTypes.sublist(0, requiredPositionalParameterCount);

  @override
  List<TypeImpl> get optionalParameterTypes =>
      positionalParameterTypes.sublist(requiredPositionalParameterCount);

  @override
  List<TypeImpl> get positionalParameterTypesShared => positionalParameterTypes;

  @override
  TypeImpl get returnTypeShared => returnType;

  @override
  List<FormalParameterElementMixin> get sortedNamedParametersShared =>
      sortedNamedParameters;

  @override
  List<TypeParameterElementImpl> get typeParameters =>
      typeFormals.map((fragment) => fragment.element).toList();

  @override
  List<TypeParameterElementImpl> get typeParametersShared => typeParameters;

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
        var freshVariables = FunctionTypeImpl.relateTypeFormals(
          this,
          other,
          (t, s) => t == s,
        );
        if (freshVariables == null) {
          return false;
        }
        return instantiate(freshVariables) == other.instantiate(freshVariables);
      }

      return other.returnType == returnType &&
          _equalParameters(other.formalParameters, formalParameters);
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
    if (argumentTypes.length != typeParameters.length) {
      throw ArgumentError(
        "argumentTypes.length (${argumentTypes.length}) != "
        "typeFormals.length (${typeParameters.length})",
      );
    }
    if (argumentTypes.isEmpty) {
      return this;
    }

    var substitution = Substitution.fromPairs2(typeParameters, argumentTypes);

    return FunctionTypeImpl(
      returnType: substitution.substituteType(returnType),
      typeFormals: const [],
      parameters:
          parameters
              .map((p) => ParameterMember.from2(p, substitution))
              .toFixedList(),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @Deprecated('Use referencesAny2() instead')
  @override
  bool referencesAny(Set<TypeParameterFragmentImpl> parameters) {
    if (typeFormals.any((element) {
      assert(!parameters.contains(element));

      var bound = element.bound;
      if (bound != null && bound.referencesAny(parameters)) {
        return true;
      }

      var defaultType = element.defaultType;
      return defaultType != null && defaultType.referencesAny(parameters);
    })) {
      return true;
    }

    if (this.parameters.any((element) {
      var type = element.type;
      return type.referencesAny(parameters);
    })) {
      return true;
    }

    return returnType.referencesAny(parameters);
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl> parameters) {
    if (typeFormals.any((element) {
      assert(!parameters.contains(element.asElement2));

      var bound = element.bound;
      if (bound != null && bound.referencesAny2(parameters)) {
        return true;
      }

      var defaultType = element.defaultType;
      return defaultType != null && defaultType.referencesAny2(parameters);
    })) {
      return true;
    }

    if (this.parameters.any((element) {
      var type = element.type;
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
            element3: TypeParameterFragmentImpl.synthetic(name2: 'T$i').element,
            nullabilitySuffix: NullabilitySuffix.none,
          ),
      ]).hashCode;
    }

    List<Object>? namedParameterInfo;
    if (sortedNamedParameters.isNotEmpty) {
      namedParameterInfo = [];
      for (var namedParameter in sortedNamedParameters) {
        namedParameterInfo.add(namedParameter.isRequired);
        namedParameterInfo.add(namedParameter.name3 ?? '');
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
    bool Function(DartType bound2, DartType bound1) relation,
  ) {
    List<TypeParameterElement> params1 = f1.typeParameters;
    List<TypeParameterElement> params2 = f2.typeParameters;

    int count = params1.length;
    if (params2.length != count) {
      return null;
    }
    // We build up a substitution matching up the type parameters
    // from the two types, {variablesFresh/variables1} and
    // {variablesFresh/variables2}
    List<TypeParameterElement> variables1 = <TypeParameterElement>[];
    List<TypeParameterElement> variables2 = <TypeParameterElement>[];
    List<TypeParameterType> variablesFresh = <TypeParameterType>[];
    for (int i = 0; i < count; i++) {
      TypeParameterElement p1 = params1[i];
      TypeParameterElement p2 = params2[i];
      TypeParameterFragmentImpl pFresh = TypeParameterFragmentImpl.synthetic(
        name2: p2.name3,
      );

      TypeParameterTypeImpl variableFresh = pFresh.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );

      variables1.add(p1);
      variables2.add(p2);
      variablesFresh.add(variableFresh);

      DartType bound1 = p1.bound ?? DynamicTypeImpl.instance;
      DartType bound2 = p2.bound ?? DynamicTypeImpl.instance;
      bound1 = Substitution.fromPairs2(
        variables1,
        variablesFresh,
      ).substituteType(bound1);
      bound2 = Substitution.fromPairs2(
        variables2,
        variablesFresh,
      ).substituteType(bound2);
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
    List<FormalParameterElement> firstParameters,
    List<FormalParameterElement> secondParameters,
  ) {
    if (firstParameters.length != secondParameters.length) {
      return false;
    }
    for (var i = 0; i < firstParameters.length; ++i) {
      var firstParameter = firstParameters[i];
      var secondParameter = secondParameters[i];
      if (firstParameter.isPositional != secondParameter.isPositional) {
        return false;
      }
      if (firstParameter.isOptional != secondParameter.isOptional) {
        return false;
      }
      if (firstParameter.type != secondParameter.type) {
        return false;
      }
      if (firstParameter.isNamed &&
          firstParameter.name3 != secondParameter.name3) {
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
  final TypeAliasElementImpl element2;

  @override
  final List<TypeImpl> typeArguments;

  InstantiatedTypeAliasElementImpl({
    required this.element2,
    required this.typeArguments,
  });
}

/// A concrete implementation of an [InterfaceType].
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  @override
  final InterfaceElementImpl element3;

  @override
  final List<TypeImpl> typeArguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Cached [ConstructorElementMixin2]s - members or raw elements.
  List<ConstructorElementMixin2>? _constructors;

  /// Cached [GetterElement2OrMember]s - members or raw elements.
  List<GetterElement2OrMember>? _getters;

  /// Cached [SetterElement2OrMember]s - members or raw elements.
  List<SetterElement2OrMember>? _setters;

  /// Cached [MethodElement2OrMember]s - members or raw elements.
  List<MethodElement2OrMember>? _methods;

  factory InterfaceTypeImpl({
    required InterfaceElementImpl element,
    required List<TypeImpl> typeArguments,
    required NullabilitySuffix nullabilitySuffix,
    InstantiatedTypeAliasElementImpl? alias,
  }) {
    if (element.name3 == 'FutureOr' && element.library2.isDartAsync) {
      return FutureOrTypeImpl(
        element3: element,
        typeArgument:
            typeArguments.isNotEmpty
                ? typeArguments[0]
                : InvalidTypeImpl.instance,
        nullabilitySuffix: nullabilitySuffix,
        alias: alias,
      );
    } else if (element.name3 == 'Null' && element.library2.isDartCore) {
      return NullTypeImpl(element3: element, alias: alias);
    } else {
      return InterfaceTypeImpl._(
        element3: element,
        typeArguments: typeArguments,
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

  InterfaceTypeImpl._null({required this.element3, super.alias})
    : typeArguments = const [],
      nullabilitySuffix = NullabilitySuffix.none {
    assert(element3.name3 == 'Null' && element3.library2.isDartCore);
    assert(this is NullTypeImpl);
  }

  @override
  List<InterfaceTypeImpl> get allSupertypes {
    var substitution = Substitution.fromInterfaceType(this);
    return element3.allSupertypes.map((interface) {
      return substitution
          .mapInterfaceType(interface)
          .withNullability(nullabilitySuffix);
    }).toList();
  }

  @override
  List<ConstructorElementMixin2> get constructors2 {
    return _constructors ??=
        element3.constructors.map((constructor) {
          return ConstructorMember.from2(constructor, this);
        }).toFixedList();
  }

  @override
  List<GetterElement2OrMember> get getters {
    return _getters ??=
        element3.getters.map((e) {
          return GetterMember.forTargetType(e, this);
        }).toFixedList();
  }

  @override
  int get hashCode {
    return element3.hashCode;
  }

  @override
  List<InterfaceTypeImpl> get interfaces {
    return _instantiateSuperTypes(element3.interfaces);
  }

  @override
  bool get isDartAsyncFuture {
    return element3.name3 == "Future" && element3.library2.isDartAsync;
  }

  @override
  bool get isDartAsyncStream {
    return element3.name3 == "Stream" && element3.library2.isDartAsync;
  }

  @override
  bool get isDartCoreBool {
    return element3.name3 == "bool" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreDouble {
    return element3.name3 == "double" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreEnum {
    var element = element3;
    return element is ClassElementImpl && element.isDartCoreEnum;
  }

  @override
  bool get isDartCoreFunction {
    return element3.name3 == "Function" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreInt {
    return element3.name3 == "int" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreIterable {
    return element3.name3 == "Iterable" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreList {
    return element3.name3 == "List" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreMap {
    return element3.name3 == "Map" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreNum {
    return element3.name3 == "num" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreObject {
    return element3.name3 == "Object" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreRecord {
    return element3.name3 == "Record" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreSet {
    return element3.name3 == "Set" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreString {
    return element3.name3 == "String" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreSymbol {
    return element3.name3 == "Symbol" && element3.library2.isDartCore;
  }

  @override
  bool get isDartCoreType {
    return element3.name3 == "Type" && element3.library2.isDartCore;
  }

  @override
  List<MethodElement2OrMember> get methods2 {
    return _methods ??=
        element3.methods.map((e) {
          return MethodMember.forTargetType(e, this);
        }).toFixedList();
  }

  @override
  List<InterfaceTypeImpl> get mixins {
    return _instantiateSuperTypes(element3.mixins);
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => element3.name3!;

  /// The instantiated representation type, if [element3] is an extension type.
  TypeImpl? get representationType {
    if (element3 case ExtensionTypeElement element) {
      var substitution = Substitution.fromInterfaceType(this);
      var representationType = element.representation.type;
      return substitution.substituteType(representationType);
    }
    return null;
  }

  @override
  List<SetterElement2OrMember> get setters {
    return _setters ??=
        element3.setters.map((e) {
          return SetterMember.forTargetType(e, this);
        }).toFixedList();
  }

  @override
  InterfaceTypeImpl? get superclass {
    var supertype = element3.supertype;
    if (supertype == null) {
      return null;
    }

    return Substitution.fromInterfaceType(
      this,
    ).mapInterfaceType(supertype).withNullability(nullabilitySuffix);
  }

  @override
  List<InterfaceTypeImpl> get superclassConstraints {
    var element = element3;
    if (element is MixinElementImpl) {
      var constraints = element.superclassConstraints;
      return _instantiateSuperTypes(constraints);
    } else {
      return [];
    }
  }

  InheritanceManager3 get _inheritanceManager =>
      element3.library2.session.inheritanceManager;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is InterfaceTypeImpl) {
      if (!identical(other.element3, element3)) {
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
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement targetElement) {
    if (element3 == targetElement) {
      return this;
    }

    for (var rawInterface in element3.allSupertypes) {
      if (rawInterface.element3 == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.mapInterfaceType(rawInterface);
      }
    }

    return null;
  }

  @override
  GetterElement2OrMember? getGetter2(String getterName) {
    var element = element3.getGetter(getterName);
    return element != null ? GetterMember.forTargetType(element, this) : null;
  }

  @override
  MethodElement2OrMember? getMethod2(String methodName) {
    var element = element3.getMethod(methodName);
    return element != null ? MethodMember.forTargetType(element, this) : null;
  }

  @override
  SetterElement2OrMember? getSetter2(String setterName) {
    var element = element3.getSetter(setterName);
    return element != null ? SetterMember.forTargetType(element, this) : null;
  }

  @override
  ConstructorElementMixin2? lookUpConstructor2(
    String? constructorName,
    LibraryElement library,
  ) {
    // prepare base ConstructorElement
    ConstructorElementImpl? constructorElement;
    if (constructorName == null) {
      constructorElement = element3.unnamedConstructor2;
    } else {
      constructorElement = element3.getNamedConstructor2(constructorName);
    }
    // not found or not accessible
    if (constructorElement == null ||
        !constructorElement.isAccessibleIn2(library)) {
      return null;
    }
    // return member
    return ConstructorMember.from2(constructorElement, this);
  }

  @override
  GetterElement2OrMember? lookUpGetter3(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.uri, name);

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember3(this, nameObj, forSuper: inherited);
        if (result is GetterElement2OrMember) {
          return result;
        }
      } else {
        var rawElement = inheritance.getInherited(element3, nameObj);
        if (rawElement is GetterElement2OrMember) {
          return GetterMember.forTargetType(rawElement, this);
        }
      }
      return null;
    }

    var result = inheritance.getMember3(this, nameObj, concrete: concrete);
    if (result is GetterElement2OrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element3.lookupStaticGetter(name, library);
    }

    return null;
  }

  @override
  MethodElement2OrMember? lookUpMethod3(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.uri, name);

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember3(this, nameObj, forSuper: inherited);
        if (result is MethodElement2OrMember) {
          return result;
        }
      } else {
        var rawElement = inheritance.getInherited(element3, nameObj);
        if (rawElement is MethodElement2OrMember) {
          return MethodMember.forTargetType(rawElement, this);
        }
      }
      return null;
    }

    var result = inheritance.getMember3(this, nameObj, concrete: concrete);
    if (result is MethodElement2OrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element3.lookupStaticMethod(name, library);
    }

    return null;
  }

  @override
  SetterElement2OrMember? lookUpSetter3(
    String name,
    LibraryElement library, {
    bool concrete = false,
    bool inherited = false,
    bool recoveryStatic = false,
  }) {
    var inheritance = _inheritanceManager;
    var nameObj = Name(library.uri, '$name=');

    if (inherited) {
      if (concrete) {
        var result = inheritance.getMember3(this, nameObj, forSuper: inherited);
        if (result is SetterElement2OrMember) {
          return result;
        }
      } else {
        var rawElement = inheritance.getInherited(element3, nameObj);
        if (rawElement is SetterElement2OrMember) {
          return SetterMember.forTargetType(rawElement, this);
        }
      }
      return null;
    }

    var result = inheritance.getMember3(this, nameObj, concrete: concrete);
    if (result is SetterElement2OrMember) {
      return result;
    }

    if (recoveryStatic) {
      return element3.lookupStaticSetter(name, library);
    }

    return null;
  }

  @Deprecated('Use referencesAny2() instead')
  @override
  bool referencesAny(Set<TypeParameterFragmentImpl> parameters) {
    return typeArguments.any((argument) => argument.referencesAny(parameters));
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl> parameters) {
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
    List<InterfaceTypeImpl> definedTypes,
  ) {
    if (definedTypes.isEmpty) return definedTypes;

    MapSubstitution? substitution;
    if (element3.typeParameters2.isNotEmpty) {
      substitution = Substitution.fromInterfaceType(this);
    }

    List<InterfaceTypeImpl> results = [];
    for (var definedType in definedTypes) {
      var result =
          substitution != null
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
  static final NeverTypeImpl instanceNullable = NeverTypeImpl._(
    NullabilitySuffix.question,
  );

  /// The unique instance of this class, non-nullable.
  static final NeverTypeImpl instance = NeverTypeImpl._(NullabilitySuffix.none);

  @override
  final NeverElementImpl element3 = NeverElementImpl.instance;

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
  NeverTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
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
  NullTypeImpl({required super.element3, super.alias}) : super._null();

  @override
  bool get isDartCoreNull => true;

  @override
  NullTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;
}

abstract class RecordTypeFieldImpl implements RecordTypeField {
  @override
  final TypeImpl type;

  RecordTypeFieldImpl({required DartType type})
    : // TODO(paulberry): eliminate this cast by changing the type of the
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
  late final List<TypeImpl> positionalTypesShared = [
    for (var field in positionalFields) field.type,
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
  Null get element3 => null;

  @override
  int get hashCode {
    return Object.hash(positionalFields.length, namedFields.length);
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String? get name => null;

  List<RecordTypeNamedFieldImpl> get namedTypes => namedFields;

  @override
  List<SharedNamedType> get sortedNamedTypesShared => namedTypes;

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
    TypeVisitorWithArgument<R, A> visitor,
    A argument,
  ) {
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

  RecordTypeNamedFieldImpl({required this.name, required super.type});

  @override
  String get nameShared => name;

  @override
  TypeImpl get typeShared => type;
}

class RecordTypePositionalFieldImpl extends RecordTypeFieldImpl
    implements RecordTypePositionalField {
  RecordTypePositionalFieldImpl({required super.type});
}

/// The abstract class `TypeImpl` implements the behavior common to objects
/// representing the declared type of elements in the element model.
abstract class TypeImpl implements DartType, SharedType {
  @override
  final InstantiatedTypeAliasElementImpl? alias;

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
  bool get isQuestionType => nullabilitySuffix != NullabilitySuffix.none;

  @override
  NullabilitySuffix get nullabilitySuffix;

  /// Append a textual representation of this type to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement targetElement) => null;

  @override
  TypeImpl asQuestionType(bool isQuestionType) => withNullability(
    isQuestionType ? NullabilitySuffix.question : NullabilitySuffix.none,
  );

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
  bool isStructurallyEqualTo(Object other) => this == other;

  /// Returns true if this type references any of the [parameters].
  @Deprecated('Use referencesAny2() instead')
  bool referencesAny(Set<TypeParameterFragmentImpl> parameters) {
    return false;
  }

  bool referencesAny2(Set<TypeParameterElementImpl> parameters) {
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
  final TypeParameterElementImpl element3;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [element3].
  final TypeImpl? promotedBound;

  /// Initialize a newly created type parameter type to be declared by the given
  /// [element3] and to have the given name.
  TypeParameterTypeImpl({
    required this.element3,
    required this.nullabilitySuffix,
    DartType? promotedBound,
    super.alias,
  }) : // TODO(paulberry): change the type of the parameter `promotedBound` so
       // that this cast isn't needed.
       promotedBound = promotedBound as TypeImpl?;

  @override
  TypeImpl get bound =>
      promotedBound ?? element3.bound ?? DynamicTypeImpl.instance;

  @override
  int get hashCode => element3.hashCode;

  @override
  bool get isBottom {
    // In principle we ought to be able to do `return bound.isBottom;`, but that
    // goes into an infinite loop with illegal code in which type parameter
    // bounds form a loop.  So we have to be more careful.
    Set<TypeParameterElement> seenTypes = {};
    TypeParameterType type = this;
    while (seenTypes.add(type.element3)) {
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
  String get name => element3.name3!;

  TypeParameterTypeImpl get withoutPromotedBound {
    return TypeParameterTypeImpl(
      element3: element3,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is TypeParameterTypeImpl && other.element3 == element3) {
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
  InterfaceTypeImpl? asInstanceOf2(InterfaceElement targetElement) {
    return bound.asInstanceOf2(targetElement);
  }

  @override
  bool referencesAny2(Set<TypeParameterElementImpl> parameters) {
    return parameters.contains(element3);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return TypeParameterTypeImpl(
      element3: element3,
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
