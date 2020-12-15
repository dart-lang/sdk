// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/null_safety_understanding_flag.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/analysis/session.dart';
import 'package:analyzer/src/dart/element/display_string_builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:meta/meta.dart';

/// Transforms the given [list] by applying [transform] to all its elements.
///
/// If no changes are made (i.e. the return value of [transform] is identical
/// to its parameter each time it is invoked), the original list is returned.
List<T> _transformOrShare<T>(List<T> list, T Function(T) transform) {
  var length = list.length;
  for (int i = 0; i < length; i++) {
    var item = list[i];
    var transformed = transform(item);
    if (!identical(item, transformed)) {
      var newList = list.toList();
      newList[i] = transformed;
      for (i++; i < length; i++) {
        newList[i] = transform(list[i]);
      }
      return newList;
    }
  }
  return list;
}

/// The [Type] representing the type `dynamic`.
class DynamicTypeImpl extends TypeImpl implements DynamicType {
  /// The unique instance of this class.
  static final DynamicTypeImpl instance = DynamicTypeImpl._();

  /// Prevent the creation of instances of this class.
  DynamicTypeImpl._() : super(DynamicElementImpl());

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.DYNAMIC.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object object) => identical(object, this);

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
  final DartType returnType;

  @override
  final List<TypeParameterElement> typeFormals;

  @override
  final List<ParameterElement> parameters;

  @override
  final List<DartType> typeArguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  FunctionTypeImpl({
    @required List<TypeParameterElement> typeFormals,
    @required List<ParameterElement> parameters,
    @required DartType returnType,
    @required NullabilitySuffix nullabilitySuffix,
    Element element,
    List<DartType> typeArguments,
  })  : typeFormals = typeFormals,
        parameters = _sortNamedParameters(parameters),
        returnType = returnType,
        nullabilitySuffix = nullabilitySuffix,
        typeArguments = typeArguments ?? const <DartType>[],
        super(element);

  @deprecated
  FunctionTypeImpl.synthetic(
      this.returnType, this.typeFormals, List<ParameterElement> parameters,
      {Element element,
      List<DartType> typeArguments,
      @required NullabilitySuffix nullabilitySuffix})
      : parameters = _sortNamedParameters(parameters),
        typeArguments = typeArguments ?? const <DartType>[],
        nullabilitySuffix = nullabilitySuffix,
        super(element);

  @override
  FunctionTypedElement get element {
    var element = super.element;
    // TODO(scheglov) Can we just construct it with the right element?
    if (element is TypeAliasElement) {
      var aliasedElement = element.aliasedElement;
      if (aliasedElement is GenericFunctionTypeElement) {
        return aliasedElement;
      }
    }
    return element;
  }

  @override
  int get hashCode {
    if (element == null) {
      return 0;
    }
    // Reference the arrays of parameters
    List<DartType> normalParameterTypes = this.normalParameterTypes;
    List<DartType> optionalParameterTypes = this.optionalParameterTypes;
    Iterable<DartType> namedParameterTypes = this.namedParameterTypes.values;
    // Generate the hashCode
    int code = returnType.hashCode;
    for (int i = 0; i < normalParameterTypes.length; i++) {
      code = (code << 1) + normalParameterTypes[i].hashCode;
    }
    for (int i = 0; i < optionalParameterTypes.length; i++) {
      code = (code << 1) + optionalParameterTypes[i].hashCode;
    }
    for (DartType type in namedParameterTypes) {
      code = (code << 1) + type.hashCode;
    }
    return code;
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => null;

  @override
  Map<String, DartType> get namedParameterTypes {
    // TODO(brianwilkerson) This implementation breaks the contract because the
    //  parameters will not necessarily be returned in the order in which they
    //  were declared.
    Map<String, DartType> types = <String, DartType>{};
    _forEachParameterType(ParameterKind.NAMED, (name, type) {
      types[name] = type;
    });
    _forEachParameterType(ParameterKind.NAMED_REQUIRED, (name, type) {
      types[name] = type;
    });
    return types;
  }

  @override
  List<String> get normalParameterNames => parameters
      .where((p) => p.isRequiredPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<DartType> get normalParameterTypes {
    List<DartType> types = <DartType>[];
    _forEachParameterType(ParameterKind.REQUIRED, (name, type) {
      types.add(type);
    });
    return types;
  }

  @override
  List<String> get optionalParameterNames => parameters
      .where((p) => p.isOptionalPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<DartType> get optionalParameterTypes {
    List<DartType> types = <DartType>[];
    _forEachParameterType(ParameterKind.POSITIONAL, (name, type) {
      types.add(type);
    });
    return types;
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is FunctionTypeImpl) {
      if (NullSafetyUnderstandingFlag.isEnabled) {
        if (other.nullabilitySuffix != nullabilitySuffix) {
          return false;
        }
      }

      if (other.typeFormals.length != typeFormals.length) {
        return false;
      }
      // `<T>T -> T` should be equal to `<U>U -> U`
      // To test this, we instantiate both types with the same (unique) type
      // variables, and see if the result is equal.
      if (typeFormals.isNotEmpty) {
        List<DartType> freshVariables = FunctionTypeImpl.relateTypeFormals(
            this, other, (t, s, _, __) => t == s);
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

    ParameterElement transformParameter(ParameterElement p) {
      return p.copyWith(
        type: substitution.substituteType(p.type),
      );
    }

    return FunctionTypeImpl(
      returnType: substitution.substituteType(returnType),
      typeFormals: const [],
      parameters: _transformOrShare(parameters, transformParameter),
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return FunctionTypeImpl(
      typeFormals: typeFormals,
      parameters: parameters,
      returnType: returnType,
      nullabilitySuffix: nullabilitySuffix,
      element: element,
      typeArguments: typeArguments,
    );
  }

  void _forEachParameterType(
      ParameterKind kind, void Function(String name, DartType type) callback) {
    for (var parameter in parameters) {
      // ignore: deprecated_member_use_from_same_package
      if (parameter.parameterKind == kind) {
        callback(parameter.name, parameter.type);
      }
    }
  }

  /// Compares two function types [t] and [s] to see if their corresponding
  /// parameter types match [parameterRelation], return types match
  /// [returnRelation], and type parameter bounds match [boundsRelation].
  ///
  /// Used for the various relations on function types which have the same
  /// structural rules for handling optional parameters and arity, but use their
  /// own relation for comparing corresponding parameters or return types.
  ///
  /// If [parameterRelation] is omitted, uses [returnRelation] for both. This
  /// is convenient for Dart 1 type system methods.
  ///
  /// If [boundsRelation] is omitted, uses [returnRelation]. This is for
  /// backwards compatibility, and convenience for Dart 1 type system methods.
  static bool relate(FunctionType t, DartType other,
      bool Function(DartType t, DartType s) returnRelation,
      {bool Function(ParameterElement t, ParameterElement s) parameterRelation,
      bool Function(DartType bound2, DartType bound1,
              TypeParameterElement formal2, TypeParameterElement formal1)
          boundsRelation}) {
    parameterRelation ??= (t, s) => returnRelation(t.type, s.type);
    boundsRelation ??= (t, s, _, __) => returnRelation(t, s);

    // Trivial base cases.
    if (other == null) {
      return false;
    } else if (identical(t, other) ||
        other.isDynamic ||
        other.isDartCoreFunction ||
        other.isDartCoreObject) {
      return true;
    } else if (other is! FunctionType) {
      return false;
    }

    // This type cast is safe, because we checked it above.
    FunctionType s = other as FunctionType;
    if (t.typeFormals.isNotEmpty) {
      List<DartType> freshVariables = relateTypeFormals(t, s, boundsRelation);
      if (freshVariables == null) {
        return false;
      }
      t = t.instantiate(freshVariables);
      s = s.instantiate(freshVariables);
    } else if (s.typeFormals.isNotEmpty) {
      return false;
    }

    // Test the return types.
    DartType sRetType = s.returnType;
    if (!sRetType.isVoid && !returnRelation(t.returnType, sRetType)) {
      return false;
    }

    // Test the parameter types.
    return relateParameters(t.parameters, s.parameters, parameterRelation);
  }

  /// Compares parameters [tParams] and [sParams] of two function types, taking
  /// corresponding parameters from the lists, and see if they match
  /// [parameterRelation].
  ///
  /// Corresponding parameters are defined as a pair `(t, s)` where `t` is a
  /// parameter from [tParams] and `s` is a parameter from [sParams], and both
  /// `t` and `s` are at the same position (for positional parameters)
  /// or have the same name (for named parameters).
  ///
  /// Used for the various relations on function types which have the same
  /// structural rules for handling optional parameters and arity, but use their
  /// own relation for comparing the parameters.
  static bool relateParameters(
      List<ParameterElement> tParams,
      List<ParameterElement> sParams,
      bool Function(ParameterElement t, ParameterElement s) parameterRelation) {
    // TODO(jmesserly): this could be implemented with less allocation if we
    // wanted, by taking advantage of the fact that positional arguments must
    // appear before named ones.
    var tRequired = <ParameterElement>[];
    var tOptional = <ParameterElement>[];
    var tNamed = <String, ParameterElement>{};
    for (var p in tParams) {
      if (p.isRequiredPositional) {
        tRequired.add(p);
      } else if (p.isOptionalPositional) {
        tOptional.add(p);
      } else {
        assert(p.isNamed);
        tNamed[p.name] = p;
      }
    }

    var sRequired = <ParameterElement>[];
    var sOptional = <ParameterElement>[];
    var sNamed = <String, ParameterElement>{};
    for (var p in sParams) {
      if (p.isRequiredPositional) {
        sRequired.add(p);
      } else if (p.isOptionalPositional) {
        sOptional.add(p);
      } else {
        assert(p.isNamed);
        sNamed[p.name] = p;
      }
    }

    // If one function has positional and the other has named parameters,
    // they don't relate.
    if (sOptional.isNotEmpty && tNamed.isNotEmpty ||
        tOptional.isNotEmpty && sNamed.isNotEmpty) {
      return false;
    }

    // If the passed function includes more named parameters than we do, we
    // don't relate.
    if (tNamed.length < sNamed.length) {
      return false;
    }

    // For each named parameter in s, make sure we have a corresponding one
    // that relates.
    for (String key in sNamed.keys) {
      var tParam = tNamed[key];
      if (tParam == null) {
        return false;
      }
      var sParam = sNamed[key];
      if (!parameterRelation(tParam, sParam)) {
        return false;
      }
    }

    // Make sure all of the positional parameters (both required and optional)
    // relate to each other.
    var tPositional = tRequired;
    var sPositional = sRequired;

    if (tOptional.isNotEmpty) {
      tPositional = tPositional.toList()..addAll(tOptional);
    }

    if (sOptional.isNotEmpty) {
      sPositional = sPositional.toList()..addAll(sOptional);
    }

    // Check that s has enough required parameters.
    if (sRequired.length < tRequired.length) {
      return false;
    }

    // Check that s does not include more positional parameters than we do.
    if (tPositional.length < sPositional.length) {
      return false;
    }

    for (int i = 0; i < sPositional.length; i++) {
      if (!parameterRelation(tPositional[i], sPositional[i])) {
        return false;
      }
    }

    return true;
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
  static List<DartType> relateTypeFormals(
      FunctionType f1,
      FunctionType f2,
      bool Function(DartType bound2, DartType bound1,
              TypeParameterElement formal2, TypeParameterElement formal1)
          relation) {
    List<TypeParameterElement> params1 = f1.typeFormals;
    List<TypeParameterElement> params2 = f2.typeFormals;
    return relateTypeFormals2(params1, params2, relation);
  }

  static List<DartType> relateTypeFormals2(
      List<TypeParameterElement> params1,
      List<TypeParameterElement> params2,
      bool Function(DartType bound2, DartType bound1,
              TypeParameterElement formal2, TypeParameterElement formal1)
          relation) {
    int count = params1.length;
    if (params2.length != count) {
      return null;
    }
    // We build up a substitution matching up the type parameters
    // from the two types, {variablesFresh/variables1} and
    // {variablesFresh/variables2}
    List<TypeParameterElement> variables1 = <TypeParameterElement>[];
    List<TypeParameterElement> variables2 = <TypeParameterElement>[];
    List<DartType> variablesFresh = <DartType>[];
    for (int i = 0; i < count; i++) {
      TypeParameterElement p1 = params1[i];
      TypeParameterElement p2 = params2[i];
      TypeParameterElementImpl pFresh =
          TypeParameterElementImpl.synthetic(p2.name);
      ElementTypeProvider.current.freshTypeParameterCreated(pFresh, p2);

      DartType variableFresh = pFresh.instantiate(
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
      if (!relation(bound2, bound1, p2, p1)) {
        return null;
      }

      if (!bound2.isDynamic) {
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

  /// If named parameters are already sorted in [parameters], return it.
  /// Otherwise, return a new list, in which named parameters are sorted.
  static List<ParameterElement> _sortNamedParameters(
    List<ParameterElement> parameters,
  ) {
    int firstNamedParameterIndex;

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
      }
    }
    if (namedParametersAlreadySorted) {
      return parameters;
    }

    // Sort named parameters.
    var namedParameters =
        parameters.sublist(firstNamedParameterIndex, parameters.length);
    namedParameters.sort((a, b) => a.name.compareTo(b.name));

    // Combine into a new list, with sorted named parameters.
    var newParameters = parameters.toList();
    newParameters.replaceRange(
        firstNamedParameterIndex, parameters.length, namedParameters);
    return newParameters;
  }
}

/// A concrete implementation of an [InterfaceType].
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  @override
  final List<DartType> typeArguments;

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Cached [ConstructorElement]s - members or raw elements.
  List<ConstructorElement> _constructors;

  /// Cached [PropertyAccessorElement]s - members or raw elements.
  List<PropertyAccessorElement> _accessors;

  /// Cached [MethodElement]s - members or raw elements.
  List<MethodElement> _methods;

  InterfaceTypeImpl({
    @required ClassElement element,
    @required this.typeArguments,
    @required this.nullabilitySuffix,
  }) : super(element);

  @override
  List<PropertyAccessorElement> get accessors {
    if (_accessors == null) {
      List<PropertyAccessorElement> accessors = element.accessors;
      List<PropertyAccessorElement> members =
          List<PropertyAccessorElement>.filled(accessors.length, null);
      for (int i = 0; i < accessors.length; i++) {
        members[i] = PropertyAccessorMember.from(accessors[i], this);
      }
      _accessors = members;
    }
    return _accessors;
  }

  @override
  List<InterfaceType> get allSupertypes {
    var substitution = Substitution.fromInterfaceType(this);
    return element.allSupertypes
        .map((t) => substitution.substituteType(t) as InterfaceType)
        .toList();
  }

  @override
  List<ConstructorElement> get constructors {
    if (_constructors == null) {
      List<ConstructorElement> constructors = element.constructors;
      List<ConstructorElement> members =
          List<ConstructorElement>.filled(constructors.length, null);
      for (int i = 0; i < constructors.length; i++) {
        members[i] = ConstructorMember.from(constructors[i], this);
      }
      _constructors = members;
    }
    return _constructors;
  }

  @override
  ClassElement get element => super.element;

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
  bool get isDartCoreBool {
    return element.name == "bool" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreDouble {
    return element.name == "double" && element.library.isDartCore;
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
  List<MethodElement> get methods {
    if (_methods == null) {
      List<MethodElement> methods = element.methods;
      List<MethodElement> members =
          List<MethodElement>.filled(methods.length, null);
      for (int i = 0; i < methods.length; i++) {
        members[i] = MethodMember.from(methods[i], this);
      }
      _methods = members;
    }
    return _methods;
  }

  @override
  List<InterfaceType> get mixins {
    List<InterfaceType> mixins = element.mixins;
    return _instantiateSuperTypes(mixins);
  }

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => element.name;

  @override
  InterfaceType get superclass {
    InterfaceType supertype = element.supertype;
    if (supertype == null) {
      return null;
    }

    return Substitution.fromInterfaceType(this).substituteType(supertype);
  }

  @override
  List<InterfaceType> get superclassConstraints {
    List<InterfaceType> constraints = element.superclassConstraints;
    return _instantiateSuperTypes(constraints);
  }

  InheritanceManager3 get _inheritanceManager =>
      (element.library.session as AnalysisSessionImpl).inheritanceManager;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    if (other is InterfaceTypeImpl) {
      if (NullSafetyUnderstandingFlag.isEnabled) {
        if (other.nullabilitySuffix != nullabilitySuffix) {
          return false;
        }
      }
      return other.element == element &&
          TypeImpl.equalArrays(other.typeArguments, typeArguments);
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
  InterfaceType asInstanceOf(ClassElement targetElement) {
    if (element == targetElement) {
      return this;
    }

    for (var rawInterface in element.allSupertypes) {
      if (rawInterface.element == targetElement) {
        var substitution = Substitution.fromInterfaceType(this);
        return substitution.substituteType(rawInterface);
      }
    }

    return null;
  }

  @override
  PropertyAccessorElement getGetter(String getterName) =>
      PropertyAccessorMember.from(element.getGetter(getterName), this);

  @override
  MethodElement getMethod(String methodName) =>
      MethodMember.from(element.getMethod(methodName), this);

  @override
  PropertyAccessorElement getSetter(String setterName) =>
      PropertyAccessorMember.from(element.getSetter(setterName), this);

  @override
  ConstructorElement lookUpConstructor(
      String constructorName, LibraryElement library) {
    // prepare base ConstructorElement
    ConstructorElement constructorElement;
    if (constructorName == null) {
      constructorElement = element.unnamedConstructor;
    } else {
      constructorElement = element.getNamedConstructor(constructorName);
    }
    // not found or not accessible
    if (constructorElement == null ||
        !constructorElement.isAccessibleIn(library)) {
      return null;
    }
    // return member
    return ConstructorMember.from(constructorElement, this);
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpGetter(
      String getterName, LibraryElement library) {
    PropertyAccessorElement element = getGetter(getterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpGetterInSuperclass(getterName, library);
  }

  @override
  PropertyAccessorElement lookUpGetter2(
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
      var element = this.element as AbstractClassElementImpl;
      return element.lookupStaticGetter(name, library);
    }

    return null;
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpGetterInSuperclass(
      String getterName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      PropertyAccessorElement element = mixin.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    for (InterfaceType constraint in superclassConstraints) {
      PropertyAccessorElement element = constraint.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype?.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getGetter(getterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getGetter(getterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype?.element;
    }
    return null;
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType = true}) {
    PropertyAccessorElement result;
    if (thisType) {
      result = lookUpGetter(name, library);
    } else {
      result = lookUpGetterInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        HashSet<ClassElement>(), (InterfaceType t) => t.getGetter(name));
  }

  @deprecated
  @override
  ExecutableElement lookUpInheritedGetterOrMethod(String name,
      {LibraryElement library}) {
    ExecutableElement result =
        lookUpGetter(name, library) ?? lookUpMethod(name, library);

    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(
        this,
        false,
        library,
        HashSet<ClassElement>(),
        (InterfaceType t) => t.getGetter(name) ?? t.getMethod(name));
  }

  @deprecated
  ExecutableElement lookUpInheritedMember(String name, LibraryElement library,
      {bool concrete = false,
      bool forSuperInvocation = false,
      int startMixinIndex,
      bool setter = false,
      bool thisType = false}) {
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();

    /// TODO(scheglov) Remove [includeSupers]. It is used only to work around
    /// the problem with Flutter code base (using old super-mixins).
    ExecutableElement lookUpImpl(InterfaceTypeImpl type,
        {bool acceptAbstract = false,
        bool includeType = true,
        bool inMixin = false,
        int startMixinIndex}) {
      if (type == null || !visitedClasses.add(type.element)) {
        return null;
      }

      if (includeType) {
        ExecutableElement result;
        if (setter) {
          result = type.getSetter(name);
        } else {
          result = type.getMethod(name);
          result ??= type.getGetter(name);
        }
        if (result != null && result.isAccessibleIn(library)) {
          if (!concrete || acceptAbstract || !result.isAbstract) {
            return result;
          }
        }
      }

      if (!inMixin || acceptAbstract) {
        var mixins = type.mixins;
        startMixinIndex ??= mixins.length;
        for (var i = startMixinIndex - 1; i >= 0; i--) {
          var result = lookUpImpl(
            mixins[i],
            acceptAbstract: acceptAbstract,
            inMixin: true,
          );
          if (result != null) {
            return result;
          }
        }
      }

      // We were not able to find the concrete dispatch target.
      // It is OK to look into interfaces, we need just some resolution now.
      if (!concrete) {
        for (InterfaceType mixin in type.interfaces) {
          var result = lookUpImpl(mixin, acceptAbstract: acceptAbstract);
          if (result != null) {
            return result;
          }
        }
      }

      if (!inMixin || acceptAbstract) {
        return lookUpImpl(type.superclass,
            acceptAbstract: acceptAbstract, inMixin: inMixin);
      }

      return null;
    }

    if (element.isMixin) {
      // TODO(scheglov) We should choose the most specific signature.
      // Not just the first signature.
      for (InterfaceType constraint in superclassConstraints) {
        var result = lookUpImpl(constraint, acceptAbstract: true);
        if (result != null) {
          return result;
        }
      }
      return null;
    } else {
      return lookUpImpl(
        this,
        includeType: thisType,
        startMixinIndex: startMixinIndex,
      );
    }
  }

  @deprecated
  @override
  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType = true}) {
    MethodElement result;
    if (thisType) {
      result = lookUpMethod(name, library);
    } else {
      result = lookUpMethodInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        HashSet<ClassElement>(), (InterfaceType t) => t.getMethod(name));
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType = true}) {
    PropertyAccessorElement result;
    if (thisType) {
      result = lookUpSetter(name, library);
    } else {
      result = lookUpSetterInSuperclass(name, library);
    }
    if (result != null) {
      return result;
    }
    return _lookUpMemberInInterfaces(this, false, library,
        HashSet<ClassElement>(), (t) => t.getSetter(name));
  }

  @deprecated
  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    MethodElement element = getMethod(methodName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpMethodInSuperclass(methodName, library);
  }

  @override
  MethodElement lookUpMethod2(
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
      var element = this.element as AbstractClassElementImpl;
      return element.lookupStaticMethod(name, library);
    }

    return null;
  }

  @deprecated
  @override
  MethodElement lookUpMethodInSuperclass(
      String methodName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      MethodElement element = mixin.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    for (InterfaceType constraint in superclassConstraints) {
      MethodElement element = constraint.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype?.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      MethodElement element = supertype.getMethod(methodName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getMethod(methodName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype?.element;
    }
    return null;
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpSetter(
      String setterName, LibraryElement library) {
    PropertyAccessorElement element = getSetter(setterName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpSetterInSuperclass(setterName, library);
  }

  @override
  PropertyAccessorElement lookUpSetter2(
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
      var element = this.element as AbstractClassElementImpl;
      return element.lookupStaticSetter(name, library);
    }

    return null;
  }

  @deprecated
  @override
  PropertyAccessorElement lookUpSetterInSuperclass(
      String setterName, LibraryElement library) {
    for (InterfaceType mixin in mixins.reversed) {
      PropertyAccessorElement element = mixin.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    for (InterfaceType constraint in superclassConstraints) {
      PropertyAccessorElement element = constraint.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
    }
    HashSet<ClassElement> visitedClasses = HashSet<ClassElement>();
    InterfaceType supertype = superclass;
    ClassElement supertypeElement = supertype?.element;
    while (supertype != null && !visitedClasses.contains(supertypeElement)) {
      visitedClasses.add(supertypeElement);
      PropertyAccessorElement element = supertype.getSetter(setterName);
      if (element != null && element.isAccessibleIn(library)) {
        return element;
      }
      for (InterfaceType mixin in supertype.mixins.reversed) {
        element = mixin.getSetter(setterName);
        if (element != null && element.isAccessibleIn(library)) {
          return element;
        }
      }
      supertype = supertype.superclass;
      supertypeElement = supertype?.element;
    }
    return null;
  }

  @override
  InterfaceTypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;

    return InterfaceTypeImpl(
      element: element,
      typeArguments: typeArguments,
      nullabilitySuffix: nullabilitySuffix,
    );
  }

  List<InterfaceType> _instantiateSuperTypes(List<InterfaceType> defined) {
    if (defined.isEmpty) return defined;

    var typeParameters = element.typeParameters;
    if (typeParameters.isEmpty) return defined;

    var substitution = Substitution.fromInterfaceType(this);
    var result = List<InterfaceType>.filled(defined.length, null);
    for (int i = 0; i < defined.length; i++) {
      result[i] = substitution.substituteType(defined[i]);
    }
    return result;
  }

  /// If there is a single type which is at least as specific as all of the
  /// types in [types], return it.  Otherwise return `null`.
  static DartType findMostSpecificType(
      List<DartType> types, TypeSystemImpl typeSystem) {
    // The << relation ("more specific than") is a partial ordering on types,
    // so to find the most specific type of a set, we keep a bucket of the most
    // specific types seen so far such that no type in the bucket is more
    // specific than any other type in the bucket.
    List<DartType> bucket = <DartType>[];

    // Then we consider each type in turn.
    for (DartType type in types) {
      // If any existing type in the bucket is more specific than this type,
      // then we can ignore this type.
      if (bucket.any((DartType t) => typeSystem.isSubtypeOf2(t, type))) {
        continue;
      }
      // Otherwise, we need to add this type to the bucket and remove any types
      // that are less specific than it.
      bool added = false;
      int i = 0;
      while (i < bucket.length) {
        if (typeSystem.isSubtypeOf2(type, bucket[i])) {
          if (added) {
            if (i < bucket.length - 1) {
              bucket[i] = bucket.removeLast();
            } else {
              bucket.removeLast();
            }
          } else {
            bucket[i] = type;
            i++;
            added = true;
          }
        } else {
          i++;
        }
      }
      if (!added) {
        bucket.add(type);
      }
    }

    // Now that we are finished, if there is exactly one type left in the
    // bucket, it is the most specific type.
    if (bucket.length == 1) {
      return bucket[0];
    }

    // Otherwise, there is no single type that is more specific than the
    // others.
    return null;
  }

  /// Returns a "smart" version of the "least upper bound" of the given types.
  ///
  /// If these types have the same element and differ only in terms of the type
  /// arguments, attempts to find a compatible set of type arguments.
  ///
  /// Otherwise, calls [DartType.getLeastUpperBound].
  static InterfaceType getSmartLeastUpperBound(
      InterfaceType first, InterfaceType second) {
    // TODO(paulberry): this needs to be deprecated and replaced with a method
    // in [TypeSystem], since it relies on the deprecated functionality of
    // [DartType.getLeastUpperBound].
    if (first.element == second.element) {
      return _leastUpperBound(first, second);
    }
    TypeSystemImpl typeSystem = first.element.library.typeSystem;
    return typeSystem.getLeastUpperBound(first, second);
  }

  /// Return the "least upper bound" of the given types under the assumption
  /// that the types have the same element and differ only in terms of the type
  /// arguments.
  ///
  /// The resulting type is composed by comparing the corresponding type
  /// arguments, keeping those that are the same, and using 'dynamic' for those
  /// that are different.
  static InterfaceType _leastUpperBound(
      InterfaceType firstType, InterfaceType secondType) {
    ClassElement firstElement = firstType.element;
    ClassElement secondElement = secondType.element;
    if (firstElement != secondElement) {
      throw ArgumentError('The same elements expected, but '
          '$firstElement and $secondElement are given.');
    }
    if (firstType == secondType) {
      return firstType;
    }
    List<DartType> firstArguments = firstType.typeArguments;
    List<DartType> secondArguments = secondType.typeArguments;
    int argumentCount = firstArguments.length;
    if (argumentCount == 0) {
      return firstType;
    }
    List<DartType> lubArguments = List<DartType>.filled(argumentCount, null);
    for (int i = 0; i < argumentCount; i++) {
      //
      // Ideally we would take the least upper bound of the two argument types,
      // but this can cause an infinite recursion (such as when finding the
      // least upper bound of String and num).
      //
      if (firstArguments[i] == secondArguments[i]) {
        lubArguments[i] = firstArguments[i];
      }
      if (lubArguments[i] == null) {
        lubArguments[i] = DynamicTypeImpl.instance;
      }
    }

    NullabilitySuffix computeNullability() {
      NullabilitySuffix first = firstType.nullabilitySuffix;
      NullabilitySuffix second = secondType.nullabilitySuffix;
      if (first == NullabilitySuffix.question ||
          second == NullabilitySuffix.question) {
        return NullabilitySuffix.question;
      } else if (first == NullabilitySuffix.star ||
          second == NullabilitySuffix.star) {
        return NullabilitySuffix.star;
      }
      return NullabilitySuffix.none;
    }

    return InterfaceTypeImpl(
      element: firstElement,
      typeArguments: lubArguments,
      nullabilitySuffix: computeNullability(),
    );
  }

  /// Look up the getter with the given name in the interfaces implemented by
  /// the given [targetType], either directly or indirectly. Return the element
  /// representing the getter that was found, or `null` if there is no getter
  /// with the given name. The flag [includeTargetType] should be `true` if the
  /// search should include the target type. The [visitedInterfaces] is a set
  /// containing all of the interfaces that have been examined, used to prevent
  /// infinite recursion and to optimize the search.
  static T _lookUpMemberInInterfaces<T extends ExecutableElement>(
      InterfaceType targetType,
      bool includeTargetType,
      LibraryElement library,
      HashSet<ClassElement> visitedInterfaces,
      T Function(InterfaceType type) getMember) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (!visitedInterfaces.add(targetClass)) {
      return null;
    }
    if (includeTargetType) {
      ExecutableElement member = getMember(targetType);
      if (member != null && member.isAccessibleIn(library)) {
        return member;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      ExecutableElement member = _lookUpMemberInInterfaces(
          interfaceType, true, library, visitedInterfaces, getMember);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType constraint in targetType.superclassConstraints) {
      ExecutableElement member = _lookUpMemberInInterfaces(
          constraint, true, library, visitedInterfaces, getMember);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      ExecutableElement member = _lookUpMemberInInterfaces(
          mixinType, true, library, visitedInterfaces, getMember);
      if (member != null) {
        return member;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpMemberInInterfaces(
        superclass, true, library, visitedInterfaces, getMember);
  }
}

/// The type `Never` represents the uninhabited bottom type.
class NeverTypeImpl extends TypeImpl implements NeverType {
  /// The unique instance of this class, nullable.
  ///
  /// This behaves equivalently to the `Null` type, but we distinguish it for
  /// two reasons: (1) there are circumstances where we need access to this
  /// type, but we don't have access to the type provider, so using `Never?` is
  /// a convenient solution.  (2) we may decide that the distinction is
  /// convenient in diagnostic messages (this is TBD).
  static final NeverTypeImpl instanceNullable =
      NeverTypeImpl._(NullabilitySuffix.question);

  /// The unique instance of this class, starred.
  ///
  /// This behaves like a version of the Null* type that could be conceivably
  /// migrated to be of type Never. Therefore, it's the bottom of all legacy
  /// types, and also assignable to the true bottom. Note that Never? and Never*
  /// are not the same type, as Never* is a subtype of Never, while Never? is
  /// not.
  static final NeverTypeImpl instanceLegacy =
      NeverTypeImpl._(NullabilitySuffix.star);

  /// The unique instance of this class, non-nullable.
  static final NeverTypeImpl instance = NeverTypeImpl._(NullabilitySuffix.none);

  @override
  final NullabilitySuffix nullabilitySuffix;

  /// Prevent the creation of instances of this class.
  NeverTypeImpl._(this.nullabilitySuffix) : super(NeverElementImpl());

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
  bool operator ==(Object object) => identical(object, this);

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
        return instanceLegacy;
      case NullabilitySuffix.none:
        return instance;
    }
    throw StateError('Unexpected nullabilitySuffix: $nullabilitySuffix');
  }
}

/// The abstract class `TypeImpl` implements the behavior common to objects
/// representing the declared type of elements in the element model.
abstract class TypeImpl implements DartType {
  @override
  final List<DartType> aliasArguments;

  @override
  final TypeAliasElement aliasElement;

  /// The element representing the declaration of this type, or `null` if the
  /// type has not, or cannot, be associated with an element.
  final Element _element;

  /// Initialize a newly created type to be declared by the given [element].
  TypeImpl(this._element, {this.aliasElement, this.aliasArguments});

  @deprecated
  @override
  String get displayName {
    return getDisplayString(
      withNullability: false,
      skipAllDynamicArguments: true,
    );
  }

  @override
  Element get element => _element;

  @override
  bool get isBottom => false;

  @override
  bool get isDartAsyncFuture => false;

  @override
  bool get isDartAsyncFutureOr => false;

  @override
  bool get isDartCoreBool => false;

  @override
  bool get isDartCoreDouble => false;

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
  bool get isDartCoreSet => false;

  @override
  bool get isDartCoreString => false;

  @override
  bool get isDartCoreSymbol => false;

  @override
  bool get isDynamic => false;

  @override
  bool get isVoid => false;

  @override
  NullabilitySuffix get nullabilitySuffix;

  /// Append a textual representation of this type to the given [builder].
  void appendTo(ElementDisplayStringBuilder builder);

  @override
  InterfaceType asInstanceOf(ClassElement element) => null;

  @override
  String getDisplayString({
    bool skipAllDynamicArguments = false,
    @required bool withNullability,
  }) {
    var builder = ElementDisplayStringBuilder(
      skipAllDynamicArguments: skipAllDynamicArguments,
      withNullability: withNullability,
    );
    appendTo(builder);
    return builder.toString();
  }

  @override
  DartType resolveToBound(DartType objectType) => this;

  @override
  String toString() {
    return getDisplayString(withNullability: true);
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
      if (first[i] == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo('Found null type argument in TypeImpl.equalArrays');
        return second[i] == null;
      } else if (second[i] == null) {
        AnalysisEngine.instance.instrumentationService
            .logInfo('Found null type argument in TypeImpl.equalArrays');
        return false;
      }
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
  final NullabilitySuffix nullabilitySuffix;

  /// An optional promoted bound on the type parameter.
  ///
  /// 'null' indicates that the type parameter's bound has not been promoted and
  /// is therefore the same as the bound of [element].
  final DartType promotedBound;

  /// Initialize a newly created type parameter type to be declared by the given
  /// [element] and to have the given name.
  TypeParameterTypeImpl({
    @required TypeParameterElement element,
    @required this.nullabilitySuffix,
    this.promotedBound,
  }) : super(element);

  @override
  DartType get bound =>
      promotedBound ?? element.bound ?? DynamicTypeImpl.instance;

  @override
  ElementLocation get definition => element.location;

  @override
  TypeParameterElement get element => super.element as TypeParameterElement;

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

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }

    if (other is TypeParameterTypeImpl && other.element == element) {
      if (NullSafetyUnderstandingFlag.isEnabled) {
        if (other.nullabilitySuffix != nullabilitySuffix) {
          return false;
        }
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
  InterfaceType asInstanceOf(ClassElement element) {
    return bound?.asInstanceOf(element);
  }

  @override
  DartType resolveToBound(DartType objectType) {
    if (promotedBound != null) {
      return promotedBound;
    }

    if (element.bound == null) {
      return objectType;
    }

    NullabilitySuffix newNullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question ||
        element.bound.nullabilitySuffix == NullabilitySuffix.question) {
      newNullabilitySuffix = NullabilitySuffix.question;
    } else if (nullabilitySuffix == NullabilitySuffix.star ||
        element.bound.nullabilitySuffix == NullabilitySuffix.star) {
      newNullabilitySuffix = NullabilitySuffix.star;
    } else {
      newNullabilitySuffix = NullabilitySuffix.none;
    }

    return (element.bound.resolveToBound(objectType) as TypeImpl)
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
class VoidTypeImpl extends TypeImpl implements VoidType {
  /// The unique instance of this class, with indeterminate nullability.
  static final VoidTypeImpl instance = VoidTypeImpl._();

  /// Prevent the creation of instances of this class.
  VoidTypeImpl._() : super(null);

  @override
  int get hashCode => 2;

  @override
  bool get isVoid => true;

  @Deprecated('Check element, or use getDisplayString()')
  @override
  String get name => Keyword.VOID.lexeme;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object object) => identical(object, this);

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
