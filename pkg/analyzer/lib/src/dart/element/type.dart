// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';

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

/**
 * A [Type] that represents the type 'bottom'.
 */
class BottomTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class, nullable.
   *
   * This behaves equivalently to the `Null` type, but we distinguish it for two
   * reasons: (1) there are circumstances where we need access to this type, but
   * we don't have access to the type provider, so using `Never?` is a
   * convenient solution.  (2) we may decide that the distinction is convenient
   * in diagnostic messages (this is TBD).
   */
  static final BottomTypeImpl instanceNullable =
      new BottomTypeImpl._(NullabilitySuffix.question);

  /**
   * The unique instance of this class, starred.
   *
   * This behaves like a version of the Null* type that could be conceivably
   * migrated to be of type Never. Therefore, it's the bottom of all legacy
   * types, and also assignable to the true bottom. Note that Never? and Never*
   * are not the same type, as Never* is a subtype of Never, while Never? is
   * not.
   */
  static final BottomTypeImpl instanceLegacy =
      new BottomTypeImpl._(NullabilitySuffix.star);

  /**
   * The unique instance of this class, non-nullable.
   */
  static final BottomTypeImpl instance =
      new BottomTypeImpl._(NullabilitySuffix.none);

  @override
  final NullabilitySuffix nullabilitySuffix;

  /**
   * Prevent the creation of instances of this class.
   */
  BottomTypeImpl._(this.nullabilitySuffix)
      : super(new NeverElementImpl(), "Never");

  @override
  int get hashCode => 0;

  @override
  bool get isBottom => true;

  @override
  bool get isDartCoreNull {
    // `Never?` is equivalent to `Null`, so make sure it behaves the same.
    return nullabilitySuffix == NullabilitySuffix.question;
  }

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
          [bool withDynamic = false, Set<Element> visitedElements]) =>
      true;

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => false;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    if (isCovariant) {
      return this;
    } else {
      // In theory this should never happen, since we only need to do this
      // replacement when checking super-boundedness of explicitly-specified
      // types, or types produced by mixin inference or instantiate-to-bounds,
      // and bottom can't occur in any of those cases.
      assert(false,
          'Attempted to check super-boundedness of a type including "bottom"');
      // But just in case it does, return `dynamic` since that's similar to what
      // we do with Null.
      return typeProvider.objectType;
    }
  }

  @override
  BottomTypeImpl substitute2(
          List<DartType> argumentTypes, List<DartType> parameterTypes,
          [List<FunctionTypeAliasElement> prune]) =>
      this;

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

/**
 * The type created internally if a circular reference is ever detected in a
 * function type.
 */
class CircularFunctionTypeImpl extends DynamicTypeImpl
    implements _FunctionTypeImplLazy {
  CircularFunctionTypeImpl() : super._circular();

  @override
  List<ParameterElement> get baseParameters => const <ParameterElement>[];

  @override
  DartType get baseReturnType => DynamicTypeImpl.instance;

  @override
  List<TypeParameterElement> get boundTypeParameters =>
      const <TypeParameterElement>[];

  @override
  FunctionTypedElement get element => null;

  @override
  bool get isInstantiated => false;

  @override
  Map<String, DartType> get namedParameterTypes => <String, DartType>{};

  @override
  List<FunctionTypeAliasElement> get newPrune =>
      const <FunctionTypeAliasElement>[];

  @override
  List<String> get normalParameterNames => <String>[];

  @override
  List<DartType> get normalParameterTypes => const <DartType>[];

  @override
  List<String> get optionalParameterNames => <String>[];

  @override
  List<DartType> get optionalParameterTypes => const <DartType>[];

  @override
  List<ParameterElement> get parameters => const <ParameterElement>[];

  @override
  List<FunctionTypeAliasElement> get prunedTypedefs =>
      const <FunctionTypeAliasElement>[];

  @override
  DartType get returnType => DynamicTypeImpl.instance;

  @override
  List<DartType> get typeArguments => const <DartType>[];

  @override
  List<TypeParameterElement> get typeFormals => const <TypeParameterElement>[];

  @override
  List<TypeParameterElement> get typeParameters =>
      const <TypeParameterElement>[];

  @override
  bool get _isInstantiated => false;

  @override
  List<ParameterElement> get _parameters => const <ParameterElement>[];

  @override
  DartType get _returnType => DynamicTypeImpl.instance;

  @override
  List<DartType> get _typeArguments => const <DartType>[];

  @override
  void set _typeArguments(List<DartType> arguments) {
    throw new UnsupportedError('Cannot have type arguments');
  }

  @override
  List<TypeParameterElement> get _typeParameters =>
      const <TypeParameterElement>[];

  @override
  void set _typeParameters(List<TypeParameterElement> parameters) {
    throw new UnsupportedError('Cannot have type parameters');
  }

  @override
  bool operator ==(Object object) => object is CircularFunctionTypeImpl;

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> visitedTypes,
      {bool withNullability = false}) {
    buffer.write('...');
  }

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes) => this;

  @override
  FunctionTypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  FunctionType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    return this;
  }

  @override
  FunctionTypeImpl substitute3(List<DartType> argumentTypes) => this;

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) => this;

  @override
  void _appendToWithTypeParameters(StringBuffer buffer,
      Set<TypeImpl> visitedTypes, bool withNullability, String typeParameters) {
    throw StateError('We should never get here.');
  }

  @override
  void _forEachParameterType(
      ParameterKind kind, callback(String name, DartType type)) {
    // There are no parameters.
  }

  @override
  void _freeVariablesInFunctionType(
      FunctionType type, Set<TypeParameterType> free) {
    // There are no free variables
  }

  @override
  void _freeVariablesInInterfaceType(
      InterfaceType type, Set<TypeParameterType> free) {
    // There are no free variables
  }

  @override
  void _freeVariablesInType(DartType type, Set<TypeParameterType> free) {
    // There are no free variables
  }
}

/**
 * Type created internally if a circular reference is ever detected.  Behaves
 * like `dynamic`, except that when converted to a string it is displayed as
 * `...`.
 */
class CircularTypeImpl extends DynamicTypeImpl {
  CircularTypeImpl() : super._circular();

  @override
  bool operator ==(Object object) => object is CircularTypeImpl;

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> visitedTypes,
      {bool withNullability = false}) {
    buffer.write('...');
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;
}

/**
 * The [Type] representing the type `dynamic`.
 */
class DynamicTypeImpl extends TypeImpl {
  /**
   * The unique instance of this class.
   */
  static final DynamicTypeImpl instance = new DynamicTypeImpl._();

  /**
   * Prevent the creation of instances of this class.
   */
  DynamicTypeImpl._() : super(new DynamicElementImpl(), Keyword.DYNAMIC.lexeme);

  /**
   * Constructor used by [CircularTypeImpl].
   */
  DynamicTypeImpl._circular() : super(instance.element, Keyword.DYNAMIC.lexeme);

  @override
  int get hashCode => 1;

  @override
  bool get isDynamic => true;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // T is S
    if (identical(this, type)) {
      return true;
    }
    // else
    return withDynamic;
  }

  @override
  bool isSubtypeOf(DartType type) => true;

  @override
  bool isSupertypeOf(DartType type) => true;

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    if (isCovariant) {
      return typeProvider.nullType;
    } else {
      return this;
    }
  }

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      if (parameterTypes[i] == this) {
        return argumentTypes[i];
      }
    }
    return this;
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    // The dynamic type is always nullable.
    return this;
  }
}

/**
 * The type of a function, method, constructor, getter, or setter.
 */
abstract class FunctionTypeImpl extends TypeImpl implements FunctionType {
  @override
  final NullabilitySuffix nullabilitySuffix;

  /**
   * Initialize a newly created function type to be declared by the given
   * [element], and also initialize [typeArguments] to match the
   * [typeParameters], which permits later substitution.
   */
  factory FunctionTypeImpl(FunctionTypedElement element,
      {NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star}) {
    if (element is FunctionTypeAliasElement) {
      throw new StateError('Use FunctionTypeImpl.forTypedef for typedefs');
    }
    return new _FunctionTypeImplLazy._(
        element, null, null, null, null, null, false,
        nullabilitySuffix: nullabilitySuffix);
  }

  /// Creates a function type that's not associated with any element in the
  /// element tree.
  factory FunctionTypeImpl.synthetic(DartType returnType,
      List<TypeParameterElement> typeFormals, List<ParameterElement> parameters,
      {Element element,
      List<DartType> typeArguments = const <DartType>[],
      NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star}) {
    return new _FunctionTypeImplStrict._(returnType, typeFormals, parameters,
        element: element,
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix);
  }

  FunctionTypeImpl._(Element element, String name, this.nullabilitySuffix)
      : super(element, name);

  @deprecated
  @override
  List<TypeParameterElement> get boundTypeParameters => typeFormals;

  @override
  String get displayName {
    if (name == null || name.isEmpty) {
      // Function types have an empty name when they are defined implicitly by
      // either a closure or as part of a parameter declaration.
      StringBuffer buffer = new StringBuffer();
      appendTo(buffer, new Set.identity());
      if (nullabilitySuffix == NullabilitySuffix.question) {
        buffer.write('?');
      }
      return buffer.toString();
    }

    List<DartType> typeArguments = this.typeArguments;

    bool allTypeArgumentsAreDynamic() {
      for (DartType type in typeArguments) {
        if (type != null && !type.isDynamic) {
          return false;
        }
      }
      return true;
    }

    StringBuffer buffer = new StringBuffer();
    buffer.write(name);
    // If there is at least one non-dynamic type, then list them out.
    if (!allTypeArgumentsAreDynamic()) {
      buffer.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i != 0) {
          buffer.write(", ");
        }
        DartType typeArg = typeArguments[i];
        buffer.write(typeArg.displayName);
      }
      buffer.write(">");
    }
    if (nullabilitySuffix == NullabilitySuffix.question) {
      buffer.write('?');
    }
    return buffer.toString();
  }

  @override
  FunctionTypedElement get element => super.element;

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

  /**
   * Return `true` if this type is the result of instantiating type parameters.
   */
  bool get isInstantiated;

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

  /**
   * Determine the new set of typedefs which should be pruned when expanding
   * this function type.
   */
  List<FunctionTypeAliasElement> get newPrune;

  @override
  List<DartType> get normalParameterTypes {
    List<DartType> types = <DartType>[];
    _forEachParameterType(ParameterKind.REQUIRED, (name, type) {
      types.add(type);
    });
    return types;
  }

  @override
  List<DartType> get optionalParameterTypes {
    List<DartType> types = <DartType>[];
    _forEachParameterType(ParameterKind.POSITIONAL, (name, type) {
      types.add(type);
    });
    return types;
  }

  /**
   * The set of typedefs which should not be expanded when exploring this type,
   * to avoid creating infinite types in response to self-referential typedefs.
   */
  List<FunctionTypeAliasElement> get prunedTypedefs;

  @override
  bool operator ==(Object object) {
    if (object is FunctionTypeImpl) {
      if (typeFormals.length != object.typeFormals.length) {
        return false;
      }
      // `<T>T -> T` should be equal to `<U>U -> U`
      // To test this, we instantiate both types with the same (unique) type
      // variables, and see if the result is equal.
      if (typeFormals.isNotEmpty) {
        List<DartType> freshVariables = FunctionTypeImpl.relateTypeFormals(
            this, object, (t, s, _, __) => t == s);
        if (freshVariables == null) {
          return false;
        }
        return instantiate(freshVariables) ==
            object.instantiate(freshVariables);
      }

      return returnType == object.returnType &&
          TypeImpl.equalArrays(
              normalParameterTypes, object.normalParameterTypes) &&
          TypeImpl.equalArrays(
              optionalParameterTypes, object.optionalParameterTypes) &&
          _equals(namedParameterTypes, object.namedParameterTypes) &&
          nullabilitySuffix == object.nullabilitySuffix;
    }
    return false;
  }

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> visitedTypes,
      {bool withNullability = false}) {
    // TODO(paulberry): eliminate code duplication with
    // _ElementWriter.writeType.  See issue #35818.
    if (visitedTypes.add(this)) {
      if (typeFormals.isNotEmpty) {
        StringBuffer typeParametersBuffer = StringBuffer();
        // To print a type with type variables, first make sure we have unique
        // variable names to print.
        Set<TypeParameterType> freeVariables = new HashSet<TypeParameterType>();
        _freeVariablesInFunctionType(this, freeVariables);

        Set<String> namesToAvoid = new HashSet<String>();
        for (DartType arg in freeVariables) {
          if (arg is TypeParameterType) {
            namesToAvoid.add(arg.displayName);
          }
        }

        List<DartType> instantiateTypeArgs = <DartType>[];
        List<TypeParameterElement> variables = <TypeParameterElement>[];
        typeParametersBuffer.write('<');
        for (TypeParameterElement e in typeFormals) {
          if (e != typeFormals[0]) {
            typeParametersBuffer.write(',');
          }
          String name = e.name;
          int counter = 0;
          while (!namesToAvoid.add(name)) {
            // Unicode subscript-zero is U+2080, zero is U+0030. Other digits
            // are sequential from there. Thus +0x2050 will get us the subscript.
            String subscript = new String.fromCharCodes(
                counter.toString().codeUnits.map((n) => n + 0x2050));

            name = e.name + subscript;
            counter++;
          }
          TypeParameterTypeImpl t = new TypeParameterTypeImpl(
              new TypeParameterElementImpl(name, -1),
              nullabilitySuffix: NullabilitySuffix.none);
          t.appendTo(typeParametersBuffer, visitedTypes,
              withNullability: withNullability);
          instantiateTypeArgs.add(t);
          variables.add(e);
          if (e.bound != null) {
            typeParametersBuffer.write(' extends ');
            TypeImpl renamed =
                Substitution.fromPairs(variables, instantiateTypeArgs)
                    .substituteType(e.bound);
            renamed.appendTo(typeParametersBuffer, visitedTypes);
          }
        }
        typeParametersBuffer.write('>');

        // Instantiate it and print the resulting type.
        this.instantiate(instantiateTypeArgs)._appendToWithTypeParameters(
            buffer,
            visitedTypes,
            withNullability,
            typeParametersBuffer.toString());
      } else {
        _appendToWithTypeParameters(buffer, visitedTypes, withNullability, '');
      }
      visitedTypes.remove(this);
    } else {
      buffer.write('<recursive>');
    }
  }

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes);

  @override
  bool isAssignableTo(DartType type) {
    // A function type T may be assigned to a function type S, written T <=> S,
    // iff T <: S.
    return isSubtypeOf(type);
  }

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    // Note: visitedElements is only used for breaking recursion in the type
    // hierarchy; we don't use it when recursing into the function type.
    return FunctionTypeImpl.relate(
        this,
        type,
        (DartType t, DartType s) =>
            (t as TypeImpl).isMoreSpecificThan(s, withDynamic));
  }

  @override
  bool isSubtypeOf(DartType type) {
    var typeSystem = new Dart2TypeSystem(null);
    return FunctionTypeImpl.relate(
        typeSystem.instantiateToBounds(this),
        typeSystem.instantiateToBounds(type),
        // ignore: deprecated_member_use_from_same_package
        (DartType t, DartType s) => t.isAssignableTo(s));
  }

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant: true}) {
    var returnType = (this.returnType as TypeImpl)
        .replaceTopAndBottom(typeProvider, isCovariant: isCovariant);
    ParameterElement transformParameter(ParameterElement p) {
      TypeImpl type = p.type;
      var newType =
          type.replaceTopAndBottom(typeProvider, isCovariant: !isCovariant);
      if (identical(newType, type)) return p;
      return new ParameterElementImpl.synthetic(
          p.name,
          newType,
          // ignore: deprecated_member_use_from_same_package
          p.parameterKind);
    }

    var parameters = _transformOrShare(this.parameters, transformParameter);
    if (identical(returnType, this.returnType) &&
        identical(parameters, this.parameters)) {
      return this;
    }
    return new _FunctionTypeImplStrict._(returnType, typeFormals, parameters,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  FunctionType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]);

  @override
  FunctionTypeImpl substitute3(List<DartType> argumentTypes) =>
      substitute2(argumentTypes, typeArguments);

  void _appendToWithTypeParameters(StringBuffer buffer,
      Set<TypeImpl> visitedTypes, bool withNullability, String typeParameters) {
    List<DartType> normalParameterTypes = this.normalParameterTypes;
    List<DartType> optionalParameterTypes = this.optionalParameterTypes;
    Map<String, DartType> namedParameterTypes = this.namedParameterTypes;
    DartType returnType = this.returnType;

    if (returnType == null) {
      buffer.write('null');
    } else {
      (returnType as TypeImpl)
          .appendTo(buffer, visitedTypes, withNullability: withNullability);
    }
    buffer.write(' Function');
    buffer.write(typeParameters);
    bool needsComma = false;

    void writeSeparator() {
      if (needsComma) {
        buffer.write(', ');
      } else {
        needsComma = true;
      }
    }

    void startOptionalParameters() {
      if (needsComma) {
        buffer.write(', ');
        needsComma = false;
      }
    }

    buffer.write('(');
    if (normalParameterTypes.isNotEmpty) {
      for (DartType type in normalParameterTypes) {
        writeSeparator();
        (type as TypeImpl)
            .appendTo(buffer, visitedTypes, withNullability: withNullability);
      }
    }
    if (optionalParameterTypes.isNotEmpty) {
      startOptionalParameters();
      buffer.write('[');
      for (DartType type in optionalParameterTypes) {
        writeSeparator();
        (type as TypeImpl)
            .appendTo(buffer, visitedTypes, withNullability: withNullability);
      }
      buffer.write(']');
      needsComma = true;
    }
    if (namedParameterTypes.isNotEmpty) {
      startOptionalParameters();
      buffer.write('{');
      namedParameterTypes.forEach((String name, DartType type) {
        writeSeparator();
        buffer.write(name);
        buffer.write(': ');
        (type as TypeImpl)
            .appendTo(buffer, visitedTypes, withNullability: withNullability);
      });
      buffer.write('}');
      needsComma = true;
    }
    buffer.write(')');
    if (withNullability) {
      _appendNullability(buffer);
    }
  }

  /**
   * Invokes [callback] for each parameter of [kind] with the parameter's [name]
   * and type after any type parameters have been applied.
   */
  void _forEachParameterType(
      ParameterKind kind, callback(String name, DartType type));

  void _freeVariablesInFunctionType(
      FunctionType type, Set<TypeParameterType> free) {
    // Make some fresh variables to avoid capture.
    List<DartType> typeArgs = const <DartType>[];
    if (type.typeFormals.isNotEmpty) {
      typeArgs = new List<DartType>.from(type.typeFormals.map((e) =>
          new TypeParameterTypeImpl(new TypeParameterElementImpl(e.name, -1))));

      type = type.instantiate(typeArgs);
    }

    for (ParameterElement p in type.parameters) {
      _freeVariablesInType(p.type, free);
    }
    _freeVariablesInType(type.returnType, free);

    // Remove all of our bound variables.
    free.removeAll(typeArgs);
  }

  void _freeVariablesInInterfaceType(
      InterfaceType type, Set<TypeParameterType> free) {
    for (DartType typeArg in type.typeArguments) {
      _freeVariablesInType(typeArg, free);
    }
  }

  void _freeVariablesInType(DartType type, Set<TypeParameterType> free) {
    if (type is TypeParameterType) {
      free.add(type);
    } else if (type is FunctionType) {
      _freeVariablesInFunctionType(type, free);
    } else if (type is InterfaceType) {
      _freeVariablesInInterfaceType(type, free);
    }
  }

  /**
   * Compares two function types [t] and [s] to see if their corresponding
   * parameter types match [parameterRelation], return types match
   * [returnRelation], and type parameter bounds match [boundsRelation].
   *
   * Used for the various relations on function types which have the same
   * structural rules for handling optional parameters and arity, but use their
   * own relation for comparing corresponding parameters or return types.
   *
   * If [parameterRelation] is omitted, uses [returnRelation] for both. This
   * is convenient for Dart 1 type system methods.
   *
   * If [boundsRelation] is omitted, uses [returnRelation]. This is for
   * backwards compatibility, and convenience for Dart 1 type system methods.
   */
  static bool relate(FunctionType t, DartType other,
      bool returnRelation(DartType t, DartType s),
      {bool parameterRelation(ParameterElement t, ParameterElement s),
      bool boundsRelation(DartType bound2, DartType bound1,
          TypeParameterElement formal2, TypeParameterElement formal1)}) {
    parameterRelation ??= (t, s) => returnRelation(t.type, s.type);
    boundsRelation ??= (t, s, _, __) => returnRelation(t, s);

    // Trivial base cases.
    if (other == null) {
      return false;
    } else if (identical(t, other) ||
        other.isDynamic ||
        other.isDartCoreFunction ||
        other.isObject) {
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

  /**
   * Compares parameters [tParams] and [sParams] of two function types, taking
   * corresponding parameters from the lists, and see if they match
   * [parameterRelation].
   *
   * Corresponding parameters are defined as a pair `(t, s)` where `t` is a
   * parameter from [tParams] and `s` is a parameter from [sParams], and both
   * `t` and `s` are at the same position (for positional parameters)
   * or have the same name (for named parameters).
   *
   * Used for the various relations on function types which have the same
   * structural rules for handling optional parameters and arity, but use their
   * own relation for comparing the parameters.
   */
  static bool relateParameters(
      List<ParameterElement> tParams,
      List<ParameterElement> sParams,
      bool parameterRelation(ParameterElement t, ParameterElement s)) {
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

  /**
   * Given two functions [f1] and [f2] where f1 and f2 are known to be
   * generic function types (both have type formals), this checks that they
   * have the same number of formals, and that those formals have bounds
   * (e.g. `<T extends LowerBound>`) that satisfy [relation].
   *
   * The return value will be a new list of fresh type variables, that can be
   * used to instantiate both function types, allowing further comparison.
   * For example, given `<T>T -> T` and `<U>U -> U` we can instantiate them with
   * `F` to get `F -> F` and `F -> F`, which we can see are equal.
   */
  static List<DartType> relateTypeFormals(
      FunctionType f1,
      FunctionType f2,
      bool relation(DartType bound2, DartType bound1,
          TypeParameterElement formal2, TypeParameterElement formal1)) {
    List<TypeParameterElement> params1 = f1.typeFormals;
    List<TypeParameterElement> params2 = f2.typeFormals;
    return relateTypeFormals2(params1, params2, relation);
  }

  static List<DartType> relateTypeFormals2(
      List<TypeParameterElement> params1,
      List<TypeParameterElement> params2,
      bool relation(DartType bound2, DartType bound1,
          TypeParameterElement formal2, TypeParameterElement formal1)) {
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
          new TypeParameterElementImpl.synthetic(p2.name);

      DartType variableFresh = new TypeParameterTypeImpl(pFresh);

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

  /**
   * Return `true` if all of the name/type pairs in the first map ([firstTypes])
   * are equal to the corresponding name/type pairs in the second map
   * ([secondTypes]). The maps are expected to iterate over their entries in the
   * same order in which those entries were added to the map.
   */
  static bool _equals(
      Map<String, DartType> firstTypes, Map<String, DartType> secondTypes) {
    if (secondTypes.length != firstTypes.length) {
      return false;
    }
    Iterator<String> firstKeys = firstTypes.keys.iterator;
    Iterator<String> secondKeys = secondTypes.keys.iterator;
    while (firstKeys.moveNext() && secondKeys.moveNext()) {
      String firstKey = firstKeys.current;
      String secondKey = secondKeys.current;
      TypeImpl firstType = firstTypes[firstKey];
      TypeImpl secondType = secondTypes[secondKey];
      if (firstKey != secondKey || firstType != secondType) {
        return false;
      }
    }
    return true;
  }
}

/**
 * A concrete implementation of an [InterfaceType].
 */
class InterfaceTypeImpl extends TypeImpl implements InterfaceType {
  @override
  final NullabilitySuffix nullabilitySuffix;

  /**
   * A list containing the actual types of the type arguments.
   */
  List<DartType> _typeArguments = const <DartType>[];

  /**
   * The set of typedefs which should not be expanded when exploring this type,
   * to avoid creating infinite types in response to self-referential typedefs.
   */
  final List<FunctionTypeAliasElement> prunedTypedefs;

  /**
   * The version of [element] for which members are cached.
   */
  int _versionOfCachedMembers;

  /**
   * Cached [ConstructorElement]s - members or raw elements.
   */
  List<ConstructorElement> _constructors;

  /**
   * Cached [PropertyAccessorElement]s - members or raw elements.
   */
  List<PropertyAccessorElement> _accessors;

  /**
   * Cached [MethodElement]s - members or raw elements.
   */
  List<MethodElement> _methods;

  /**
   * Initialize a newly created type to be declared by the given [element].
   */
  InterfaceTypeImpl(ClassElement element,
      {this.prunedTypedefs, this.nullabilitySuffix = NullabilitySuffix.star})
      : super(element, element.displayName);

  InterfaceTypeImpl.explicit(ClassElement element, List<DartType> typeArguments,
      {this.nullabilitySuffix = NullabilitySuffix.star})
      : prunedTypedefs = null,
        _typeArguments = typeArguments,
        super(element, element.displayName);

  /**
   * Private constructor.
   */
  InterfaceTypeImpl._(Element element, String name, this.prunedTypedefs,
      {this.nullabilitySuffix = NullabilitySuffix.star})
      : super(element, name);

  InterfaceTypeImpl._withNullability(InterfaceTypeImpl original,
      {this.nullabilitySuffix = NullabilitySuffix.star})
      : _typeArguments = original._typeArguments,
        prunedTypedefs = original.prunedTypedefs,
        super(original.element, original.name);

  @override
  List<PropertyAccessorElement> get accessors {
    _flushCachedMembersIfStale();
    if (_accessors == null) {
      List<PropertyAccessorElement> accessors = element.accessors;
      List<PropertyAccessorElement> members =
          new List<PropertyAccessorElement>(accessors.length);
      for (int i = 0; i < accessors.length; i++) {
        members[i] = PropertyAccessorMember.from(accessors[i], this);
      }
      _accessors = members;
    }
    return _accessors;
  }

  @override
  List<ConstructorElement> get constructors {
    _flushCachedMembersIfStale();
    if (_constructors == null) {
      List<ConstructorElement> constructors = element.constructors;
      List<ConstructorElement> members =
          new List<ConstructorElement>(constructors.length);
      for (int i = 0; i < constructors.length; i++) {
        members[i] = ConstructorMember.from(constructors[i], this);
      }
      _constructors = members;
    }
    return _constructors;
  }

  @override
  String get displayName {
    List<DartType> typeArguments = this.typeArguments;

    bool allTypeArgumentsAreDynamic() {
      for (DartType type in typeArguments) {
        if (type != null && !type.isDynamic) {
          return false;
        }
      }
      return true;
    }

    StringBuffer buffer = new StringBuffer();
    buffer.write(name);
    // If there is at least one non-dynamic type, then list them out.
    if (!allTypeArgumentsAreDynamic()) {
      buffer.write("<");
      for (int i = 0; i < typeArguments.length; i++) {
        if (i != 0) {
          buffer.write(", ");
        }
        DartType typeArg = typeArguments[i];
        buffer.write(typeArg.displayName);
      }
      buffer.write(">");
    }
    if (nullabilitySuffix == NullabilitySuffix.question) {
      buffer.write('?');
    }
    return buffer.toString();
  }

  @override
  ClassElement get element => super.element;

  @override
  int get hashCode {
    ClassElement element = this.element;
    if (element == null) {
      return 0;
    }
    return element.hashCode;
  }

  @override
  List<InterfaceType> get interfaces {
    return _instantiateSuperTypes(element.interfaces);
  }

  @override
  bool get isDartAsyncFuture {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Future" && element.library.isDartAsync;
  }

  @override
  bool get isDartAsyncFutureOr {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "FutureOr" && element.library.isDartAsync;
  }

  @override
  bool get isDartCoreBool {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "bool" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreDouble {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "double" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreFunction {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Function" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreInt {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "int" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreList {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "List" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreMap {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Map" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreNull {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Null" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreNum {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "num" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreObject {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Object" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreSet {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Set" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreString {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "String" && element.library.isDartCore;
  }

  @override
  bool get isDartCoreSymbol {
    ClassElement element = this.element;
    if (element == null) {
      return false;
    }
    return element.name == "Symbol" && element.library.isDartCore;
  }

  @override
  bool get isObject => element.supertype == null && !element.isMixin;

  @override
  List<MethodElement> get methods {
    _flushCachedMembersIfStale();
    if (_methods == null) {
      List<MethodElement> methods = element.methods;
      List<MethodElement> members = new List<MethodElement>(methods.length);
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

  @override
  List<DartType> get typeArguments {
    return _typeArguments;
  }

  /**
   * Set [typeArguments].
   */
  void set typeArguments(List<DartType> typeArguments) {
    _typeArguments = typeArguments;
  }

  @override
  List<TypeParameterElement> get typeParameters => element.typeParameters;

  @override
  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is InterfaceTypeImpl) {
      return element == object.element &&
          TypeImpl.equalArrays(typeArguments, object.typeArguments) &&
          nullabilitySuffix == object.nullabilitySuffix;
    }
    return false;
  }

  @override
  void appendTo(StringBuffer buffer, Set<TypeImpl> visitedTypes,
      {bool withNullability = false}) {
    if (visitedTypes.add(this)) {
      buffer.write(name);
      int argumentCount = typeArguments.length;
      if (argumentCount > 0) {
        buffer.write("<");
        for (int i = 0; i < argumentCount; i++) {
          if (i > 0) {
            buffer.write(", ");
          }
          (typeArguments[i] as TypeImpl)
              .appendTo(buffer, visitedTypes, withNullability: withNullability);
        }
        buffer.write(">");
      }
      if (withNullability) {
        _appendNullability(buffer);
      }
      visitedTypes.remove(this);
    } else {
      buffer.write('<recursive>');
    }
  }

  /**
   * Return either this type or a supertype of this type that is defined by the
   * [targetElement], or `null` if such a type does not exist. If this type
   * inherits from the target element along multiple paths, then the returned type
   * is arbitrary.
   *
   * For example, given the following definitions
   * ```
   * class A<E> {}
   * class B<E> implements A<E> {}
   * class C implements A<String> {}
   * ```
   * Asking the type `B<int>` for the type associated with `A` will return the
   * type `A<int>`. Asking the type `C` for the type associated with `A` will
   * return the type `A<String>`.
   */
  InterfaceType asInstanceOf(ClassElement targetElement) {
    return _asInstanceOf(targetElement, new Set<ClassElement>());
  }

  @override
  DartType flattenFutures(TypeSystem typeSystem) {
    // Implement the cases:
    //  - "If T = FutureOr<S> then flatten(T) = S."
    //  - "If T = Future<S> then flatten(T) = S."
    if (isDartAsyncFutureOr || isDartAsyncFuture) {
      return typeArguments.isNotEmpty
          ? typeArguments[0]
          : DynamicTypeImpl.instance;
    }

    // Implement the case: "Otherwise if T <: Future then let S be a type
    // such that T << Future<S> and for all R, if T << Future<R> then S << R.
    // Then flatten(T) = S."
    //
    // In other words, given the set of all types R such that T << Future<R>,
    // let S be the most specific of those types, if any such S exists.
    //
    // Since we only care about the most specific type, it is sufficient to
    // look at the types appearing as a parameter to Future in the type
    // hierarchy of T.  We don't need to consider the supertypes of those
    // types, since they are by definition less specific.
    List<DartType> candidateTypes =
        _searchTypeHierarchyForFutureTypeParameters();
    DartType flattenResult = findMostSpecificType(candidateTypes, typeSystem);
    if (flattenResult != null) {
      return flattenResult;
    }

    // Implement the case: "In any other circumstance, flatten(T) = T."
    return this;
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
  InterfaceTypeImpl instantiate(List<DartType> argumentTypes) =>
      substitute2(argumentTypes, typeArguments);

  @override
  bool isDirectSupertypeOf(InterfaceType type) {
    InterfaceType i = this;
    InterfaceType j = type;
    var substitution = Substitution.fromInterfaceType(j);
    ClassElement jElement = j.element;
    //
    // If J is Object, then it has no direct supertypes.
    //
    if (j.isObject) {
      return false;
    }
    //
    // I is listed in the extends clause of J.
    //
    InterfaceType supertype = jElement.supertype;
    if (supertype != null) {
      supertype = substitution.substituteType(supertype);
      if (supertype == i) {
        return true;
      }
    }
    //
    // I is listed in the on clause of J.
    //
    for (InterfaceType interfaceType in jElement.superclassConstraints) {
      interfaceType = substitution.substituteType(interfaceType);
      if (interfaceType == i) {
        return true;
      }
    }
    //
    // I is listed in the implements clause of J.
    //
    for (InterfaceType interfaceType in jElement.interfaces) {
      interfaceType = substitution.substituteType(interfaceType);
      if (interfaceType == i) {
        return true;
      }
    }
    //
    // I is listed in the with clause of J.
    //
    for (InterfaceType mixinType in jElement.mixins) {
      mixinType = substitution.substituteType(mixinType);
      if (mixinType == i) {
        return true;
      }
    }
    //
    // J is a mixin application of the mixin of I.
    //
    // TODO(brianwilkerson) Determine whether this needs to be implemented or
    // whether it is covered by the case above.
    return false;
  }

  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    //
    // T is Null and S is not Bottom.
    //
    if (isDartCoreNull && !type.isBottom) {
      return true;
    }

    // S is dynamic.
    // The test to determine whether S is dynamic is done here because dynamic
    // is not an instance of InterfaceType.
    //
    if (type.isDynamic) {
      return true;
    }
    //
    // A type T is more specific than a type S, written T << S,
    // if one of the following conditions is met:
    //
    // Reflexivity: T is S.
    //
    if (this == type) {
      return true;
    }
    if (type is InterfaceType) {
      //
      // T is bottom. (This case is handled by the class BottomTypeImpl.)
      //
      // Direct supertype: S is a direct supertype of T.
      //
      // ignore: deprecated_member_use_from_same_package
      if (type.isDirectSupertypeOf(this)) {
        return true;
      }
      //
      // Covariance: T is of the form I<T1, ..., Tn> and S is of the form
      // I<S1, ..., Sn> and Ti << Si, 1 <= i <= n.
      //
      ClassElement tElement = this.element;
      ClassElement sElement = type.element;
      if (tElement == sElement) {
        List<DartType> tArguments = typeArguments;
        List<DartType> sArguments = type.typeArguments;
        if (tArguments.length != sArguments.length) {
          return false;
        }
        for (int i = 0; i < tArguments.length; i++) {
          if (!(tArguments[i] as TypeImpl)
              .isMoreSpecificThan(sArguments[i], withDynamic)) {
            return false;
          }
        }
        return true;
      }
    }
    //
    // Transitivity: T << U and U << S.
    //
    // First check for infinite loops
    if (element == null) {
      return false;
    }
    if (visitedElements == null) {
      visitedElements = new HashSet<ClassElement>();
    } else if (visitedElements.contains(element)) {
      return false;
    }
    visitedElements.add(element);
    try {
      // Iterate over all of the types U that are more specific than T because
      // they are direct supertypes of T and return true if any of them are more
      // specific than S.
      InterfaceTypeImpl supertype = superclass;
      if (supertype != null &&
          supertype.isMoreSpecificThan(type, withDynamic, visitedElements)) {
        return true;
      }
      for (InterfaceType interfaceType in interfaces) {
        if ((interfaceType as InterfaceTypeImpl)
            .isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      for (InterfaceType mixinType in mixins) {
        if ((mixinType as InterfaceTypeImpl)
            .isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      if (element.isMixin) {
        for (InterfaceType constraint in superclassConstraints) {
          if ((constraint as InterfaceTypeImpl)
              .isMoreSpecificThan(type, withDynamic, visitedElements)) {
            return true;
          }
        }
      }
      // If a type I includes an instance method named `call`, and the type of
      // `call` is the function type F, then I is considered to be more specific
      // than F.
      MethodElement callMethod = getMethod('call');
      if (callMethod != null && !callMethod.isStatic) {
        FunctionTypeImpl callType = callMethod.type;
        if (callType.isMoreSpecificThan(type, withDynamic, visitedElements)) {
          return true;
        }
      }
      return false;
    } finally {
      visitedElements.remove(element);
    }
  }

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
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
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

  @override
  PropertyAccessorElement lookUpInheritedGetter(String name,
      {LibraryElement library, bool thisType: true}) {
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
        new HashSet<ClassElement>(), (InterfaceType t) => t.getGetter(name));
  }

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
        new HashSet<ClassElement>(),
        (InterfaceType t) => t.getGetter(name) ?? t.getMethod(name));
  }

  ExecutableElement lookUpInheritedMember(String name, LibraryElement library,
      {bool concrete: false,
      bool forSuperInvocation: false,
      int startMixinIndex,
      bool setter: false,
      bool thisType: false}) {
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();

    /// TODO(scheglov) Remove [includeSupers]. It is used only to work around
    /// the problem with Flutter code base (using old super-mixins).
    ExecutableElement lookUpImpl(InterfaceTypeImpl type,
        {bool acceptAbstract: false,
        bool includeType: true,
        bool inMixin: false,
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

  @override
  MethodElement lookUpInheritedMethod(String name,
      {LibraryElement library, bool thisType: true}) {
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
        new HashSet<ClassElement>(), (InterfaceType t) => t.getMethod(name));
  }

  @override
  PropertyAccessorElement lookUpInheritedSetter(String name,
      {LibraryElement library, bool thisType: true}) {
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
        new HashSet<ClassElement>(), (t) => t.getSetter(name));
  }

  @override
  MethodElement lookUpMethod(String methodName, LibraryElement library) {
    MethodElement element = getMethod(methodName);
    if (element != null && element.isAccessibleIn(library)) {
      return element;
    }
    return lookUpMethodInSuperclass(methodName, library);
  }

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
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
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
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
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
  InterfaceTypeImpl pruned(List<FunctionTypeAliasElement> prune) {
    if (prune == null) {
      return this;
    } else {
      // There should never be a reason to prune a type that has already been
      // pruned, since pruning is only done when expanding a function type
      // alias, and function type aliases are always expanded by starting with
      // base types.
      assert(this.prunedTypedefs == null);
      InterfaceTypeImpl result = new InterfaceTypeImpl._(element, name, prune,
          nullabilitySuffix: nullabilitySuffix);
      result.typeArguments = typeArguments
          .map((DartType t) => (t as TypeImpl).pruned(prune))
          .toList();
      return result;
    }
  }

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant: true}) {
    // First check if this is actually an instance of Bottom
    if (this.isDartCoreNull) {
      if (isCovariant) {
        return this;
      } else {
        return typeProvider.objectType;
      }
    }

    // Otherwise, recurse over type arguments.
    var typeArguments = _transformOrShare(
        this.typeArguments,
        (t) => (t as TypeImpl)
            .replaceTopAndBottom(typeProvider, isCovariant: isCovariant));
    if (identical(typeArguments, this.typeArguments)) {
      return this;
    } else {
      return new InterfaceTypeImpl._(element, name, prunedTypedefs,
          nullabilitySuffix: nullabilitySuffix)
        ..typeArguments = typeArguments;
    }
  }

  @override
  InterfaceTypeImpl substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new ArgumentError(
          "argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    if (argumentTypes.isEmpty || typeArguments.isEmpty) {
      return this.pruned(prune);
    }

    List<DartType> newTypeArguments = TypeImpl.substitute(
        typeArguments, argumentTypes, parameterTypes, prune);

    InterfaceTypeImpl newType = new InterfaceTypeImpl(element,
        prunedTypedefs: prune, nullabilitySuffix: nullabilitySuffix);
    newType.typeArguments = newTypeArguments;
    return newType;
  }

  @deprecated
  @override
  InterfaceTypeImpl substitute4(List<DartType> argumentTypes) =>
      instantiate(argumentTypes);

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return InterfaceTypeImpl._withNullability(this,
        nullabilitySuffix: nullabilitySuffix);
  }

  /**
   * Return  either this type or a supertype of this type that is defined by the
   * [targetElement], or `null` if such a type does not exist. The set of
   * [visitedClasses] is used to prevent infinite recursion.
   */
  InterfaceType _asInstanceOf(
      ClassElement targetElement, Set<ClassElement> visitedClasses) {
    ClassElement thisElement = element;
    if (thisElement == targetElement) {
      return this;
    } else if (visitedClasses.add(thisElement)) {
      InterfaceType type;
      for (InterfaceType mixin in mixins) {
        type = (mixin as InterfaceTypeImpl)
            ._asInstanceOf(targetElement, visitedClasses);
        if (type != null) {
          return type;
        }
      }
      if (superclass != null) {
        type = (superclass as InterfaceTypeImpl)
            ._asInstanceOf(targetElement, visitedClasses);
        if (type != null) {
          return type;
        }
      }
      for (InterfaceType interface in interfaces) {
        type = (interface as InterfaceTypeImpl)
            ._asInstanceOf(targetElement, visitedClasses);
        if (type != null) {
          return type;
        }
      }
    }
    return null;
  }

  /**
   * Flush cache members if the version of [element] for which members are
   * cached and the current version of the [element].
   */
  void _flushCachedMembersIfStale() {
    ClassElement element = this.element;
    if (element is ClassElementImpl) {
      int currentVersion = element.version;
      if (_versionOfCachedMembers != currentVersion) {
        _constructors = null;
        _accessors = null;
        _methods = null;
      }
      _versionOfCachedMembers = currentVersion;
    }
  }

  List<InterfaceType> _instantiateSuperTypes(List<InterfaceType> defined) {
    if (defined.isEmpty) return defined;

    var typeParameters = element.typeParameters;
    if (typeParameters.isEmpty) return defined;

    var substitution = Substitution.fromInterfaceType(this);
    var result = List<InterfaceType>(defined.length);
    for (int i = 0; i < defined.length; i++) {
      result[i] = substitution.substituteType(defined[i]);
    }
    return result;
  }

  /**
   * Starting from this type, search its class hierarchy for types of the form
   * Future<R>, and return a list of the resulting R's.
   */
  List<DartType> _searchTypeHierarchyForFutureTypeParameters() {
    List<DartType> result = <DartType>[];
    HashSet<ClassElement> visitedClasses = new HashSet<ClassElement>();
    void recurse(InterfaceTypeImpl type) {
      if (type.isDartAsyncFuture && type.typeArguments.isNotEmpty) {
        result.add(type.typeArguments[0]);
      }
      if (visitedClasses.add(type.element)) {
        if (type.superclass != null) {
          recurse(type.superclass);
        }
        for (InterfaceType interface in type.interfaces) {
          recurse(interface);
        }
        visitedClasses.remove(type.element);
      }
    }

    recurse(this);
    return result;
  }

  /**
   * If there is a single type which is at least as specific as all of the
   * types in [types], return it.  Otherwise return `null`.
   */
  static DartType findMostSpecificType(
      List<DartType> types, TypeSystem typeSystem) {
    // The << relation ("more specific than") is a partial ordering on types,
    // so to find the most specific type of a set, we keep a bucket of the most
    // specific types seen so far such that no type in the bucket is more
    // specific than any other type in the bucket.
    List<DartType> bucket = <DartType>[];

    // Then we consider each type in turn.
    for (DartType type in types) {
      // If any existing type in the bucket is more specific than this type,
      // then we can ignore this type.
      if (bucket.any((DartType t) => typeSystem.isSubtypeOf(t, type))) {
        continue;
      }
      // Otherwise, we need to add this type to the bucket and remove any types
      // that are less specific than it.
      bool added = false;
      int i = 0;
      while (i < bucket.length) {
        if (typeSystem.isSubtypeOf(type, bucket[i])) {
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

  /**
   * Returns a "smart" version of the "least upper bound" of the given types.
   *
   * If these types have the same element and differ only in terms of the type
   * arguments, attempts to find a compatible set of type arguments.
   *
   * Otherwise, calls [DartType.getLeastUpperBound].
   */
  static InterfaceType getSmartLeastUpperBound(
      InterfaceType first, InterfaceType second) {
    // TODO(paulberry): this needs to be deprecated and replaced with a method
    // in [TypeSystem], since it relies on the deprecated functionality of
    // [DartType.getLeastUpperBound].
    if (first.element == second.element) {
      return _leastUpperBound(first, second);
    }
    AnalysisContext context = first.element.context;
    return context.typeSystem.getLeastUpperBound(first, second);
  }

  /**
   * Return the "least upper bound" of the given types under the assumption that
   * the types have the same element and differ only in terms of the type
   * arguments.
   *
   * The resulting type is composed by comparing the corresponding type
   * arguments, keeping those that are the same, and using 'dynamic' for those
   * that are different.
   */
  static InterfaceType _leastUpperBound(
      InterfaceType firstType, InterfaceType secondType) {
    ClassElement firstElement = firstType.element;
    ClassElement secondElement = secondType.element;
    if (firstElement != secondElement) {
      throw new ArgumentError('The same elements expected, but '
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
    List<DartType> lubArguments = new List<DartType>(argumentCount);
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
      NullabilitySuffix first =
          (firstType as InterfaceTypeImpl).nullabilitySuffix;
      NullabilitySuffix second =
          (secondType as InterfaceTypeImpl).nullabilitySuffix;
      if (first == NullabilitySuffix.question ||
          second == NullabilitySuffix.question) {
        return NullabilitySuffix.question;
      } else if (first == NullabilitySuffix.star ||
          second == NullabilitySuffix.star) {
        return NullabilitySuffix.star;
      }
      return NullabilitySuffix.none;
    }

    InterfaceTypeImpl lub = new InterfaceTypeImpl(firstElement,
        nullabilitySuffix: computeNullability());
    lub.typeArguments = lubArguments;
    return lub;
  }

  /**
   * Look up the getter with the given [name] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the getter that was found, or `null` if
   * there is no getter with the given name. The flag [includeTargetType] should
   * be `true` if the search should include the target type. The
   * [visitedInterfaces] is a set containing all of the interfaces that have
   * been examined, used to prevent infinite recursion and to optimize the
   * search.
   */
  static ExecutableElement _lookUpMemberInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      LibraryElement library,
      HashSet<ClassElement> visitedInterfaces,
      ExecutableElement getMember(InterfaceType type)) {
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

/**
 * The abstract class `TypeImpl` implements the behavior common to objects
 * representing the declared type of elements in the element model.
 */
abstract class TypeImpl implements DartType {
  /**
   * The element representing the declaration of this type, or `null` if the
   * type has not, or cannot, be associated with an element.
   */
  final Element _element;

  /**
   * The name of this type, or `null` if the type does not have a name.
   */
  final String name;

  /**
   * Initialize a newly created type to be declared by the given [element] and
   * to have the given [name].
   */
  TypeImpl(this._element, this.name);

  @override
  String get displayName => name;

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
  bool get isObject => false;

  @override
  bool get isVoid => false;

  /**
   * Return the nullability suffix of this type.
   */
  NullabilitySuffix get nullabilitySuffix;

  /**
   * Append a textual representation of this type to the given [buffer]. The set
   * of [visitedTypes] is used to prevent infinite recursion.
   */
  void appendTo(StringBuffer buffer, Set<TypeImpl> visitedTypes,
      {bool withNullability = false}) {
    if (visitedTypes.add(this)) {
      if (name == null) {
        buffer.write("<unnamed type>");
      } else {
        buffer.write(name);
      }
      visitedTypes.remove(this);
    } else {
      buffer.write('<recursive>');
    }
    if (withNullability) {
      _appendNullability(buffer);
    }
  }

  @override
  DartType flattenFutures(TypeSystem typeSystem) => this;

  /**
   * Return `true` if this type is assignable to the given [type] (written in
   * the spec as "T <=> S", where T=[this] and S=[type]).
   *
   * The sets [thisExpansions] and [typeExpansions], if given, are the sets of
   * function type aliases that have been expanded so far in the process of
   * reaching [this] and [type], respectively.  These are used to avoid
   * infinite regress when analyzing invalid code; since the language spec
   * forbids a typedef from referring to itself directly or indirectly, we can
   * use these as sets of function type aliases that don't need to be expanded.
   */
  @override
  bool isAssignableTo(DartType type) {
    // An interface type T may be assigned to a type S, written T <=> S, iff
    // either T <: S or S <: T.
    return isSubtypeOf(type) || type.isSubtypeOf(this);
  }

  @override
  bool isEquivalentTo(DartType other) => this == other;

  /**
   * Return `true` if this type is more specific than the given [type] (written
   * in the spec as "T << S", where T=[this] and S=[type]).
   *
   * If [withDynamic] is `true`, then "dynamic" should be considered as a
   * subtype of any type (as though "dynamic" had been replaced with bottom).
   *
   * The set [visitedElements], if given, is the set of classes and type
   * parameters that have been visited so far while examining the class
   * hierarchy of [this].  This is used to avoid infinite regress when
   * analyzing invalid code; since the language spec forbids loops in the class
   * hierarchy, we can use this as a set of classes that don't need to be
   * examined when walking the class hierarchy.
   */
  @override
  bool isMoreSpecificThan(DartType type,
      [bool withDynamic = false, Set<Element> visitedElements]);

  /**
   * Return `true` if this type is a subtype of the given [type] (written in
   * the spec as "T <: S", where T=[this] and S=[type]).
   *
   * The sets [thisExpansions] and [typeExpansions], if given, are the sets of
   * function type aliases that have been expanded so far in the process of
   * reaching [this] and [type], respectively.  These are used to avoid
   * infinite regress when analyzing invalid code; since the language spec
   * forbids a typedef from referring to itself directly or indirectly, we can
   * use these as sets of function type aliases that don't need to be expanded.
   */
  @override
  bool isSubtypeOf(DartType type) {
    // For non-function types, T <: S iff [_|_/dynamic]T << S.
    return isMoreSpecificThan(type, true);
  }

  @override
  bool isSupertypeOf(DartType type) => type.isSubtypeOf(this);

  /**
   * Create a new [TypeImpl] that is identical to [this] except that when
   * visiting type parameters, function parameter types, and function return
   * types, function types listed in [prune] will not be expanded.  This is
   * used to avoid creating infinite types in the presence of circular
   * typedefs.
   *
   * If [prune] is null, then [this] is returned unchanged.
   *
   * Only legal to call on a [TypeImpl] that is not already subject to pruning.
   */
  TypeImpl pruned(List<FunctionTypeAliasElement> prune);

  /// Replaces all covariant occurrences of `dynamic`, `Object`, and `void` with
  /// `Null` and all contravariant occurrences of `Null` with `Object`.
  ///
  /// The boolean `isCovariant` indicates whether this type is in covariant or
  /// contravariant position.
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true});

  @override
  DartType resolveToBound(DartType objectType) => this;

  /**
   * Return the type resulting from substituting the given [argumentTypes] for
   * the given [parameterTypes] in this type.
   *
   * In all classes derived from [TypeImpl], a new optional argument
   * [prune] is added.  If specified, it is a list of function typdefs
   * which should not be expanded.  This is used to avoid creating infinite
   * types in response to self-referential typedefs.
   */
  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]);

  @override
  String toString({bool withNullability = false}) {
    StringBuffer buffer = new StringBuffer();
    appendTo(buffer, new Set.identity(), withNullability: withNullability);
    return buffer.toString();
  }

  /**
   * Return the same type, but with the given [nullabilitySuffix].
   *
   * If the nullability of `this` already matches [nullabilitySuffix], `this`
   * is returned.
   *
   * Note: this method just does low-level manipulations of the underlying type,
   * so it is what you want if you are constructing a fresh type and want it to
   * have the correct nullability suffix, but it is generally *not* what you
   * want if you're manipulating existing types.  For manipulating existing
   * types, please use the methods in [TypeSystem].
   */
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix);

  void _appendNullability(StringBuffer buffer) {
    if (isDynamic || isVoid) {
      // These types don't have nullability variations, so don't append
      // anything.
      return;
    }
    switch (nullabilitySuffix) {
      case NullabilitySuffix.question:
        buffer.write('?');
        break;
      case NullabilitySuffix.star:
        buffer.write('*');
        break;
      case NullabilitySuffix.none:
        break;
    }
  }

  /**
   * Return `true` if corresponding elements of the [first] and [second] lists
   * of type arguments are all equal.
   */
  static bool equalArrays(List<DartType> first, List<DartType> second) {
    if (first.length != second.length) {
      return false;
    }
    for (int i = 0; i < first.length; i++) {
      if (first[i] == null) {
        AnalysisEngine.instance.logger
            .logInformation('Found null type argument in TypeImpl.equalArrays');
        return second[i] == null;
      } else if (second[i] == null) {
        AnalysisEngine.instance.logger
            .logInformation('Found null type argument in TypeImpl.equalArrays');
        return false;
      }
      if (first[i] != second[i]) {
        return false;
      }
    }
    return true;
  }

  /**
   * Return a list containing the results of using the given [argumentTypes] and
   * [parameterTypes] to perform a substitution on all of the given [types].
   *
   * If [prune] is specified, it is a list of function typdefs which should not
   * be expanded.  This is used to avoid creating infinite types in response to
   * self-referential typedefs.
   */
  static List<DartType> substitute(List<DartType> types,
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = types.length;
    if (length == 0) {
      return types;
    }
    List<DartType> newTypes = new List<DartType>(length);
    for (int i = 0; i < length; i++) {
      newTypes[i] = (types[i] as TypeImpl)
          .substitute2(argumentTypes, parameterTypes, prune);
    }
    return newTypes;
  }
}

/**
 * A concrete implementation of a [TypeParameterType].
 */
class TypeParameterTypeImpl extends TypeImpl implements TypeParameterType {
  @override
  final NullabilitySuffix nullabilitySuffix;

  /**
   * Initialize a newly created type parameter type to be declared by the given
   * [element] and to have the given name.
   */
  TypeParameterTypeImpl(TypeParameterElement element,
      {this.nullabilitySuffix = NullabilitySuffix.star})
      : super(element, element.name);

  @override
  DartType get bound => element.bound ?? DynamicTypeImpl.instance;

  @override
  ElementLocation get definition => element.location;

  @override
  TypeParameterElement get element => super.element as TypeParameterElement;

  @override
  int get hashCode => element.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) {
      return true;
    }
    return other is TypeParameterTypeImpl && other.element == element;
  }

  @override
  bool isMoreSpecificThan(DartType s,
      [bool withDynamic = false, Set<Element> visitedElements]) {
    //
    // A type T is more specific than a type S, written T << S,
    // if one of the following conditions is met:
    //
    // Reflexivity: T is S.
    //
    if (this == s) {
      return true;
    }
    // S is dynamic.
    //
    if (s.isDynamic) {
      return true;
    }
    //
    // T is a type parameter and S is the upper bound of T.
    //
    TypeImpl bound = element.bound;
    if (s == bound) {
      return true;
    }
    //
    // T is a type parameter and S is Object.
    //
    if (s.isObject) {
      return true;
    }
    // We need upper bound to continue.
    if (bound == null) {
      return false;
    }
    //
    // Transitivity: T << U and U << S.
    //
    // First check for infinite loops
    if (element == null) {
      return false;
    }
    if (visitedElements == null) {
      visitedElements = new HashSet<Element>();
    } else if (visitedElements.contains(element)) {
      return false;
    }
    visitedElements.add(element);
    try {
      return bound.isMoreSpecificThan(s, withDynamic, visitedElements);
    } finally {
      visitedElements.remove(element);
    }
  }

  @override
  bool isSubtypeOf(DartType type) => isMoreSpecificThan(type, true);

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    return this;
  }

  @override
  DartType resolveToBound(DartType objectType) {
    if (element.bound == null) {
      return objectType;
    }

    NullabilitySuffix newNullabilitySuffix;
    if (nullabilitySuffix == NullabilitySuffix.question ||
        (element.bound as TypeImpl).nullabilitySuffix ==
            NullabilitySuffix.question) {
      newNullabilitySuffix = NullabilitySuffix.question;
    } else if (nullabilitySuffix == NullabilitySuffix.star ||
        (element.bound as TypeImpl).nullabilitySuffix ==
            NullabilitySuffix.star) {
      newNullabilitySuffix = NullabilitySuffix.star;
    } else {
      newNullabilitySuffix = NullabilitySuffix.none;
    }

    return (element.bound.resolveToBound(objectType) as TypeImpl)
        .withNullability(newNullabilitySuffix);
  }

  @override
  DartType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    int length = parameterTypes.length;
    for (int i = 0; i < length; i++) {
      var parameterType = parameterTypes[i];
      if (parameterType is TypeParameterTypeImpl && parameterType == this) {
        TypeImpl argumentType = argumentTypes[i];

        // TODO(scheglov) It should not happen, but sometimes arguments are null.
        if (argumentType == null) {
          return argumentType;
        }

        // TODO(scheglov) Proposed substitution rules for nullability.
        NullabilitySuffix resultNullability;
        NullabilitySuffix parameterNullability =
            parameterType.nullabilitySuffix;
        NullabilitySuffix argumentNullability = argumentType.nullabilitySuffix;
        if (parameterNullability == NullabilitySuffix.none) {
          if (argumentNullability == NullabilitySuffix.question ||
              nullabilitySuffix == NullabilitySuffix.question) {
            resultNullability = NullabilitySuffix.question;
          } else if (argumentNullability == NullabilitySuffix.star ||
              nullabilitySuffix == NullabilitySuffix.star) {
            resultNullability = NullabilitySuffix.star;
          } else {
            resultNullability = NullabilitySuffix.none;
          }
        } else if (parameterNullability == NullabilitySuffix.star) {
          if (argumentNullability == NullabilitySuffix.question ||
              nullabilitySuffix == NullabilitySuffix.question) {
            resultNullability = NullabilitySuffix.question;
          } else {
            resultNullability = argumentNullability;
          }
        } else {
          // We should never be substituting for `T?`.
          throw new StateError('Tried to substitute for T?');
        }

        return argumentType.withNullability(resultNullability);
      }
    }
    return this;
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return TypeParameterTypeImpl(element, nullabilitySuffix: nullabilitySuffix);
  }

  /**
   * Return a list containing the type parameter types defined by the given
   * array of type parameter elements ([typeParameters]).
   */
  static List<TypeParameterType> getTypes(
      List<TypeParameterElement> typeParameters) {
    int count = typeParameters.length;
    if (count == 0) {
      return const <TypeParameterType>[];
    }
    List<TypeParameterType> types = new List<TypeParameterType>(count);
    for (int i = 0; i < count; i++) {
      types[i] = typeParameters[i].type;
    }
    return types;
  }
}

/**
 * The type `void`.
 */
abstract class VoidType implements DartType {
  @override
  VoidType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes);
}

/**
 * A concrete implementation of a [VoidType].
 */
class VoidTypeImpl extends TypeImpl implements VoidType {
  /**
   * The unique instance of this class, with indeterminate nullability.
   */
  static final VoidTypeImpl instance = new VoidTypeImpl._();

  /**
   * Prevent the creation of instances of this class.
   */
  VoidTypeImpl._() : super(null, Keyword.VOID.lexeme);

  @override
  int get hashCode => 2;

  @override
  bool get isVoid => true;

  @override
  NullabilitySuffix get nullabilitySuffix => NullabilitySuffix.none;

  @override
  bool operator ==(Object object) => identical(object, this);

  @override
  bool isMoreSpecificThan(DartType type,
          [bool withDynamic = false, Set<Element> visitedElements]) =>
      isSubtypeOf(type);

  @override
  bool isSubtypeOf(DartType type) {
    // The only subtype relations that pertain to void are therefore:
    // void <: void (by reflexivity)
    // bottom <: void (as bottom is a subtype of all types).
    // void <: dynamic (as dynamic is a supertype of all types)
    return identical(type, this) || type.isDynamic;
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  DartType replaceTopAndBottom(TypeProvider typeProvider,
      {bool isCovariant = true}) {
    if (isCovariant) {
      return typeProvider.nullType;
    } else {
      return this;
    }
  }

  @override
  VoidTypeImpl substitute2(
          List<DartType> argumentTypes, List<DartType> parameterTypes,
          [List<FunctionTypeAliasElement> prune]) =>
      this;

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    // The void type is always nullable.
    return this;
  }
}

/**
 * A [FunctionTypeImpl] that is lazily built from a [FunctionTypedElement] in
 * the element model.
 */
class _FunctionTypeImplLazy extends FunctionTypeImpl {
  /**
   * The list of [typeArguments].
   */
  List<DartType> _typeArguments;

  /**
   * The list of [typeParameters], if it has been computed already.  Otherwise
   * `null`.
   */
  List<TypeParameterElement> _typeParameters;

  /**
   * The return type of the function, or `null` if the return type should be
   * accessed through the element.
   */
  final DartType _returnType;

  /**
   * The parameters to the function, or `null` if the parameters should be
   * accessed through the element.
   */
  final List<ParameterElement> _parameters;

  /**
   * True if this type is the result of instantiating type parameters (and thus
   * any type parameters bound by the typedef should be considered part of
   * [typeParameters] rather than [typeFormals]).
   */
  final bool _isInstantiated;

  @override
  final List<FunctionTypeAliasElement> prunedTypedefs;

  /**
   * Private constructor.
   */
  _FunctionTypeImplLazy._(
      FunctionTypedElement element,
      String name,
      this.prunedTypedefs,
      this._typeArguments,
      this._returnType,
      this._parameters,
      this._isInstantiated,
      {NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star})
      : _typeParameters = null,
        super._(element, name, nullabilitySuffix);

  /**
   * Return the base parameter elements of this function element.
   */
  List<ParameterElement> get baseParameters =>
      _parameters ?? element.parameters;

  /**
   * Return the return type defined by this function's element.
   */
  DartType get baseReturnType => _returnType ?? element.returnType;

  @override
  bool get isInstantiated => _isInstantiated;

  @override
  List<FunctionTypeAliasElement> get newPrune {
    Element element = this.element;
    if (element is GenericFunctionTypeElement) {
      element = (element as GenericFunctionTypeElement).enclosingElement;
    }
    if (element is FunctionTypeAliasElement && !element.isSynthetic) {
      // This typedef should be pruned, along with anything that was previously
      // pruned.
      if (prunedTypedefs == null) {
        return <FunctionTypeAliasElement>[element];
      } else {
        return new List<FunctionTypeAliasElement>.from(prunedTypedefs)
          ..add(element);
      }
    } else {
      // This is not a typedef, so nothing additional needs to be pruned.
      return prunedTypedefs;
    }
  }

  @override
  List<String> get normalParameterNames {
    return baseParameters
        .where((parameter) => parameter.isRequiredPositional)
        .map((parameter) => parameter.name)
        .toList();
  }

  @override
  List<String> get optionalParameterNames {
    return baseParameters
        .where((parameter) => parameter.isOptionalPositional)
        .map((parameter) => parameter.name)
        .toList();
  }

  @override
  List<ParameterElement> get parameters {
    var substitution = Substitution.fromPairs(typeParameters, typeArguments);

    List<ParameterElement> baseParameters = this.baseParameters;
    // no parameters, quick return
    int parameterCount = baseParameters.length;
    if (parameterCount == 0) {
      return baseParameters;
    }

    // create specialized parameters
    var specializedParams = new List<ParameterElement>(parameterCount);

    var parameterTypes = TypeParameterTypeImpl.getTypes(typeParameters);
    for (int i = 0; i < parameterCount; i++) {
      var parameter = baseParameters[i];
      if (parameter?.type == null) {
        specializedParams[i] = parameter;
        continue;
      }

      // Check if parameter type depends on defining type type arguments, or
      // if it needs to be pruned.

      if (parameter is FieldFormalParameterElement) {
        // TODO(jmesserly): this seems like it won't handle pruning correctly.
        specializedParams[i] =
            new FieldFormalParameterMember(parameter, substitution);
        continue;
      }
      var baseType = parameter.type as TypeImpl;
      TypeImpl type;
      if (typeArguments.isEmpty ||
          typeArguments.length != typeParameters.length) {
        type = baseType.pruned(newPrune);
      } else {
        type = baseType.substitute2(typeArguments, parameterTypes, newPrune);
      }

      specializedParams[i] = identical(type, baseType)
          ? parameter
          : new ParameterMember(parameter, substitution, type);
    }
    return specializedParams;
  }

  @override
  DartType get returnType {
    DartType baseReturnType = this.baseReturnType;
    if (baseReturnType == null) {
      // TODO(brianwilkerson) This is a patch. The return type should never be
      // null and we need to understand why it is and fix it.
      return DynamicTypeImpl.instance;
    }
    // If there are no arguments to substitute, or if the arguments size doesn't
    // match the parameter size, return the base return type.
    if (typeArguments.isEmpty ||
        typeArguments.length != typeParameters.length) {
      return (baseReturnType as TypeImpl).pruned(newPrune);
    }
    return (baseReturnType as TypeImpl).substitute2(typeArguments,
        TypeParameterTypeImpl.getTypes(typeParameters), newPrune);
  }

  /**
   * A list containing the actual types of the type arguments.
   */
  List<DartType> get typeArguments {
    if (_typeArguments == null) {
      // TODO(jmesserly): reuse TypeParameterTypeImpl.getTypes once we can
      // make it generic, which will allow it to return List<DartType> instead
      // of List<TypeParameterType>.
      if (typeParameters.isEmpty) {
        _typeArguments = const <DartType>[];
      } else {
        _typeArguments = new List<DartType>.from(
            typeParameters.map((t) => t.type),
            growable: false);
      }
    }
    return _typeArguments;
  }

  @override
  List<TypeParameterElement> get typeFormals {
    if (_isInstantiated || element == null) {
      return const <TypeParameterElement>[];
    }
    List<TypeParameterElement> baseTypeFormals = element.typeParameters;
    int formalCount = baseTypeFormals.length;
    if (formalCount == 0) {
      return const <TypeParameterElement>[];
    }

    // Create type formals with specialized bounds.
    // For example `<U extends T>` where T comes from an outer scope.
    return TypeParameterMember.from(baseTypeFormals, this);
  }

  @override
  List<TypeParameterElement> get typeParameters {
    if (_typeParameters == null) {
      // Combine the generic type variables from all enclosing contexts, except
      // for this generic function's type variables. Those variables are
      // tracked in [boundTypeParameters].
      _typeParameters = <TypeParameterElement>[];

      Element e = element;
      while (e != null) {
        // If a static method, skip the enclosing class type parameters.
        if (e is MethodElement && e.isStatic) {
          e = e.enclosingElement;
        }
        e = e.enclosingElement;
        if (e is TypeParameterizedElement) {
          _typeParameters.addAll(e.typeParameters);
        }
      }

      if (_isInstantiated) {
        // Once the type has been instantiated, type parameters defined at the
        // site of the declaration of the method are no longer considered part
        // [boundTypeParameters]; they are part of [typeParameters].
        List<TypeParameterElement> parametersToAdd = element?.typeParameters;
        if (parametersToAdd != null) {
          _typeParameters.addAll(parametersToAdd);
        }
      }
    }
    return _typeParameters;
  }

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes) {
    if (argumentTypes.length != typeFormals.length) {
      throw new ArgumentError(
          "argumentTypes.length (${argumentTypes.length}) != "
          "typeFormals.length (${typeFormals.length})");
    }
    if (argumentTypes.isEmpty) {
      return this;
    }

    // Given:
    //     {U/T} <S> T -> S
    // Where {U/T} represents the typeArguments (U) and typeParameters (T) list,
    // and <S> represents the typeFormals.
    //
    // Now instantiate([V]), and the result should be:
    //     {U/T, V/S} T -> S.
    List<DartType> newTypeArgs = <DartType>[];
    newTypeArgs.addAll(typeArguments);
    newTypeArgs.addAll(argumentTypes);

    return new _FunctionTypeImplLazy._(element, name, prunedTypedefs,
        newTypeArgs, _returnType, _parameters, true,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  FunctionTypeImpl pruned(List<FunctionTypeAliasElement> prune) {
    if (prune == null) {
      return this;
    } else if (prune.contains(element) ||
        prune.contains(element.enclosingElement)) {
      // Circularity found.  Prune the type declaration.
      return new CircularFunctionTypeImpl();
    } else {
      // There should never be a reason to prune a type that has already been
      // pruned, since pruning is only done when expanding a function type
      // alias, and function type aliases are always expanded by starting with
      // base types.
      assert(this.prunedTypedefs == null);
      List<DartType> typeArgs = typeArguments
          .map((DartType t) => (t as TypeImpl).pruned(prune))
          .toList(growable: false);
      return new _FunctionTypeImplLazy._(element, name, prune, typeArgs,
          _returnType, _parameters, _isInstantiated,
          nullabilitySuffix: nullabilitySuffix);
    }
  }

  @override
  FunctionType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new ArgumentError(
          "argumentTypes.length (${argumentTypes.length}) != parameterTypes.length (${parameterTypes.length})");
    }
    Element element = this.element;
    Element forCircularity = this.element;
    if (element is GenericFunctionTypeElement &&
        element.enclosingElement is FunctionTypeAliasElement) {
      forCircularity = element.enclosingElement;
    }
    if (prune != null && prune.contains(forCircularity)) {
      // Circularity found.  Prune the type declaration.
      return new CircularFunctionTypeImpl();
    }
    if (argumentTypes.isEmpty) {
      return this.pruned(prune);
    }
    List<DartType> typeArgs =
        TypeImpl.substitute(typeArguments, argumentTypes, parameterTypes);
    return new _FunctionTypeImplLazy._(element, name, prune, typeArgs,
        _returnType, _parameters, _isInstantiated,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return _FunctionTypeImplLazy._(element, name, prunedTypedefs,
        _typeArguments, _returnType, _parameters, _isInstantiated,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  void _forEachParameterType(
      ParameterKind kind, callback(String name, DartType type)) {
    List<ParameterElement> parameters = baseParameters;
    if (parameters.isEmpty) {
      return;
    }

    List<DartType> typeParameters =
        TypeParameterTypeImpl.getTypes(this.typeParameters);
    int length = parameters.length;
    for (int i = 0; i < length; i++) {
      ParameterElement parameter = parameters[i];
      // ignore: deprecated_member_use_from_same_package
      if (parameter.parameterKind == kind) {
        TypeImpl type = parameter.type ?? DynamicTypeImpl.instance;
        if (typeArguments.isNotEmpty &&
            typeArguments.length == typeParameters.length) {
          type = type.substitute2(typeArguments, typeParameters, newPrune);
        } else {
          type = type.pruned(newPrune);
        }

        callback(parameter.name, type);
      }
    }
  }
}

/// A [FunctionTypeImpl] that is not associated with any element in the element
/// model.
///
/// In contrast to [_FunctionTypeImplLazy], all of the properties of a
/// [_FunctionTypeImplStrict] are known at construction time.
class _FunctionTypeImplStrict extends FunctionTypeImpl {
  @override
  final DartType returnType;

  @override
  final List<TypeParameterElement> typeFormals;

  @override
  final List<ParameterElement> parameters;

  @override
  final List<DartType> typeArguments;

  _FunctionTypeImplStrict._(this.returnType, this.typeFormals, this.parameters,
      {Element element,
      List<DartType> typeArguments,
      NullabilitySuffix nullabilitySuffix = NullabilitySuffix.star})
      : typeArguments = typeArguments ?? const <DartType>[],
        super._(element, null, nullabilitySuffix);

  @override
  List<TypeParameterElement> get boundTypeParameters => typeFormals;

  @override
  FunctionTypedElement get element {
    var element = super.element;
    if (element is GenericTypeAliasElement) {
      return element.function;
    }
    return element;
  }

  @override
  bool get isInstantiated => throw new UnimplementedError('TODO(paulberry)');

  @override
  List<FunctionTypeAliasElement> get newPrune => const [];

  @override
  List<String> get normalParameterNames => parameters
      .where((p) => p.isRequiredPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<String> get optionalParameterNames => parameters
      .where((p) => p.isOptionalPositional)
      .map((p) => p.name)
      .toList();

  @override
  List<FunctionTypeAliasElement> get prunedTypedefs => const [];

  @override
  List<TypeParameterElement> get typeParameters => const [] /*TODO(paulberry)*/;

  @override
  FunctionTypeImpl instantiate(List<DartType> argumentTypes) {
    if (argumentTypes.length != typeFormals.length) {
      throw new ArgumentError(
          "argumentTypes.length (${argumentTypes.length}) != "
          "typeFormals.length (${typeFormals.length})");
    }
    if (argumentTypes.isEmpty) {
      return this;
    }

    var substitution = Substitution.fromPairs(typeFormals, argumentTypes);

    ParameterElement transformParameter(ParameterElement p) {
      var type = p.type;
      var newType = substitution.substituteType(type);
      if (identical(newType, type)) return p;
      return new ParameterElementImpl.synthetic(
          p.name,
          newType,
          // ignore: deprecated_member_use_from_same_package
          p.parameterKind)
        ..isExplicitlyCovariant = p.isCovariant;
    }

    return new _FunctionTypeImplStrict._(
        substitution.substituteType(returnType),
        const [],
        _transformOrShare(parameters, transformParameter),
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  TypeImpl pruned(List<FunctionTypeAliasElement> prune) => this;

  @override
  FunctionType substitute2(
      List<DartType> argumentTypes, List<DartType> parameterTypes,
      [List<FunctionTypeAliasElement> prune]) {
    if (argumentTypes.length != parameterTypes.length) {
      throw new ArgumentError(
          "argumentTypes.length (${argumentTypes.length}) != "
          "parameterTypes.length (${parameterTypes.length})");
    }

    var substitution = Substitution.fromPairs(
      parameterTypes.map<TypeParameterElement>((t) => t.element).toList(),
      argumentTypes,
    );
    return substitution.substituteType(this);
  }

  @override
  TypeImpl withNullability(NullabilitySuffix nullabilitySuffix) {
    if (this.nullabilitySuffix == nullabilitySuffix) return this;
    return _FunctionTypeImplStrict._(returnType, typeFormals, parameters,
        element: element,
        typeArguments: typeArguments,
        nullabilitySuffix: nullabilitySuffix);
  }

  @override
  void _forEachParameterType(
      ParameterKind kind, Function(String name, DartType type) callback) {
    for (var parameter in parameters) {
      // ignore: deprecated_member_use_from_same_package
      if (parameter.parameterKind == kind) {
        callback(parameter.name, parameter.type);
      }
    }
  }
}
