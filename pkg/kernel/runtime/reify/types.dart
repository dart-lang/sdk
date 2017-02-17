// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Notation:
///
/// * `[[T]]` is the runtime representation of type `T` (that is, `T` reified).
library kernel.transformations.reify.runtime.types;

import 'declarations.dart' show Class;

export 'declarations.dart';

export 'interceptors.dart';

// The public interface of this library are static functions to access parts of
// reified type objects and the constructors on the ReifiedType subclasses.

bool isSubtypeOf(ReifiedType a, ReifiedType b) => a._isSubtypeOf(b);

bool isMoreSpecificThan(ReifiedType a, ReifiedType b) {
  return a._isMoreSpecificThan(b);
}

Kind getKind(ReifiedType type) => type._kind;

ReifiedType asInstanceOf(Interface type, Class declaration) {
  return type.asInstanceOf(declaration);
}

List<ReifiedType> getTypeArguments(Interface type) => type._typeArguments;

bool isDynamic(ReifiedType type) => type._isDynamic;

bool isFunction(ReifiedType type) => type._isFunction;

bool isInterface(ReifiedType type) => type._isInterface;

bool isIntersection(ReifiedType type) => type._isIntersection;

bool isVariable(ReifiedType type) => type._isVariable;

bool isVoid(ReifiedType type) => type._isVoid;

bool isObject(ReifiedType type) => false;

ReifiedType getSupertype(var type) => type._supertype;

Iterable<ReifiedType> getInterfaces(Interface type) => type._interfaces;

ReifiedType subst(ReifiedType type, List<ReifiedType> arguments,
    List<ReifiedType> parameters) {
  return type._subst(arguments, parameters);
}

// TODO(ahe): Do we need ReifiedNullType?

ReifiedType _intersection(ReifiedType a, ReifiedType b) {
  if (a == null) return b;
  if (b == null) return a;
  if (a == b) return a;
  return new Intersection(a, b);
}

enum Kind {
  Bottom,
  Dynamic,
  Function,
  Interface,
  Intersection,
  Variable,
  Void,
}

abstract class ReifiedType {
  // TODO(ahe): Should this be a getter to save memory? Which is faster?
  final Kind _kind;

  const ReifiedType(this._kind);

  bool get _isDynamic => _kind == Kind.Dynamic;

  bool get _isFunction => _kind == Kind.Function;

  bool get _isInterface => _kind == Kind.Interface;

  bool get _isIntersection => _kind == Kind.Intersection;

  bool get _isVariable => _kind == Kind.Variable;

  bool get _isVoid => _kind == Kind.Void;

  bool get _isObject => false;

  /// Returns true if [this] is more specific than [type].
  bool _isMoreSpecificThan(ReifiedType type);

  /// Performs the substitution `[arguments[i]/parameters[i]]this`.
  ///
  /// The notation is known from this lambda calculus rule:
  ///
  ///     (lambda x.e0)e1 -> [e1/x]e0.
  ///
  /// Invariant: There must be the same number of [arguments] and [parameters].
  ReifiedType _subst(List<ReifiedType> arguments, List<ReifiedType> parameters);

  /// Returns true if [this] is a subtype of [type].
  bool _isSubtypeOf(ReifiedType type) {
    return _subst(const <ReifiedType>[const Bottom()],
        const <ReifiedType>[const Dynamic()])._isMoreSpecificThan(type);
  }

  bool _isAssignableTo(ReifiedType type) {
    if (type._isDynamic) return true;
    return this._isSubtypeOf(type) || type._isSubtypeOf(this);
  }
}

/// Represents the type `dynamic`.
class Dynamic extends ReifiedType {
  const Dynamic() : super(Kind.Dynamic);

  bool _isMoreSpecificThan(ReifiedType type) => type._isDynamic;

  ReifiedType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    int index = 0;
    for (ReifiedType parameter in parameters) {
      if (parameter._isDynamic) return arguments[index];
      index++;
    }
    return this;
  }

  String toString() => "dynamic";
}

/// Represents the bottom type.
class Bottom extends ReifiedType {
  const Bottom() : super(Kind.Bottom);

  bool _isMoreSpecificThan(ReifiedType type) => true;

  ReifiedType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    return this;
  }

  String toString() => "<bottom>";
}

/// Represents the type `void`.
class Void extends ReifiedType {
  const Void() : super(Kind.Void);

  bool _isMoreSpecificThan(ReifiedType type) {
    // `void` isn't more specific than anything but itself.
    return type._isVoid;
  }

  bool _isSubtypeOf(ReifiedType type) {
    // `void` isn't the subtype of anything besides `dynamic` and itself.
    return type._isVoid || type._isDynamic;
  }

  ReifiedType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    return this;
  }

  String toString() => "void";
}

/// Represents an interface type. That is, the type of any class.
///
/// For example, the type
///
///     String
///
/// Would be represented as:
///
///    new Interface(stringDeclaration);
///
/// Where `stringDeclaration` is an instance of [Class] which contains
/// information about [String]'s supertype and implemented interfaces.
///
/// A parameterized type, for example:
///
///     Box<int>
///
/// Would be represented as:
///
///     new Interface(boxDeclaration,
///         [new Interface(intDeclaration)]);
///
/// Implementation notes and considerations:
///
/// * It's possible that we want to split this class in two to save memory: one
///   for non-generic classes and one for generic classes. Only the latter
///   would need [_typeArguments]. However, this must be weighed against the
///   additional polymorphism.
/// * Generally, we don't canonicalize types. However, simple types like `new
///   Interface(intDeclaration)` should be canonicalized to save
///   memory. Precisely how this canonicalization will happen is TBD, but it
///   may simply be by using compile-time constants.
class Interface extends ReifiedType implements Type {
  final Class _declaration;

  final List<ReifiedType> _typeArguments;

  const Interface(this._declaration,
      [this._typeArguments = const <ReifiedType>[]])
      : super(Kind.Interface);

  bool get _isObject => _declaration.supertype == null;

  Interface get _supertype {
    return _declaration.supertype
        ?._subst(_typeArguments, _declaration.variables);
  }

  Iterable<Interface> get _interfaces {
    return _declaration.interfaces.map((Interface type) {
      return type._subst(_typeArguments, _declaration.variables);
    });
  }

  FunctionType get _callableType {
    return _declaration.callableType
        ?._subst(_typeArguments, _declaration.variables);
  }

  bool _isMoreSpecificThan(ReifiedType type) {
    if (type._isDynamic) return true;
    // Intersection types can only occur as the result of calling
    // [asInstanceOf], they should never be passed in to this method.
    assert(!type._isIntersection);
    if (type._isFunction) {
      return _callableType?._isMoreSpecificThan(type) ?? false;
    }
    if (!type._isInterface) return false;
    if (this == type) return true;
    ReifiedType supertype = asInstanceOfType(type);
    if (supertype == null) {
      // Special case: A callable class is a subtype of [Function], regardless
      // if it implements [Function]. It isn't more specific than
      // [Function]. The type representing [Function] is the supertype of
      // `declaration.callableType`.
      return _declaration.callableType?._supertype?._isSubtypeOf(type) ?? false;
    }
    if (type == supertype) return true;
    switch (supertype._kind) {
      case Kind.Dynamic:
      case Kind.Variable:
        // Shouldn't happen. See switch in [asInstanceOf].
        throw "internal error: $supertype";

      case Kind.Interface:
        Interface s = supertype;
        Interface t = type;
        for (int i = 0; i < s._typeArguments.length; i++) {
          if (!s._typeArguments[i]._isMoreSpecificThan(t._typeArguments[i])) {
            return false;
          }
        }
        return true;

      case Kind.Intersection:
        return supertype._isMoreSpecificThan(type);

      default:
        throw "Internal error: unhandled kind '${type._kind}'";
    }
  }

  bool _isSubtypeOf(ReifiedType type) {
    if (type._isInterface) {
      Interface interface = type;
      if (interface._declaration != this._declaration) {
        // This addition to the specified rules allows us to handle cases like
        //     class D extends A<dynamic> {}
        //     new D() is A<A>
        // where directly going to `isMoreSpecific` would leave `dynamic` in the
        // result of `asInstanceOf(A)` instead of bottom.
        ReifiedType that = asInstanceOf(interface._declaration);
        if (that != null) {
          return that._isSubtypeOf(type);
        }
      }
    }
    return super._isSubtypeOf(type) ||
        (_callableType?._isSubtypeOf(type) ?? false);
  }

  /// Returns [this] translated to [type] if [type] is a supertype of
  /// [this]. Otherwise null.
  ///
  /// For example, given:
  ///
  ///     class Box<T> {}
  ///     class BeatBox extends Box<Beat> {}
  ///     class Beat {}
  ///
  /// We have:
  ///
  ///     [[BeatBox]].asInstanceOf([[Box]]) -> [[Box<Beat>]].
  ReifiedType asInstanceOf(Class other) {
    if (_declaration == other) return this;
    ReifiedType result = _declaration.supertype
        ?._subst(_typeArguments, _declaration.variables)
        ?.asInstanceOf(other);
    for (Interface interface in _declaration.interfaces) {
      result = _intersection(
          result,
          interface
              ._subst(_typeArguments, _declaration.variables)
              .asInstanceOf(other));
    }
    return result;
  }

  ReifiedType asInstanceOfType(Interface type) {
    return asInstanceOf(type._declaration);
  }

  Interface _subst(List<ReifiedType> arguments, List<ReifiedType> parameters) {
    List<ReifiedType> copy;
    int index = 0;
    for (ReifiedType typeArgument in _typeArguments) {
      ReifiedType substitution = typeArgument._subst(arguments, parameters);
      if (substitution != typeArgument) {
        if (copy == null) {
          copy = new List<ReifiedType>.from(_typeArguments);
        }
        copy[index] = substitution;
      }
      index++;
    }
    return copy == null ? this : new Interface(_declaration, copy);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(_declaration.name);
    if (_typeArguments.isNotEmpty) {
      sb.write("<");
      sb.writeAll(_typeArguments, ", ");
      sb.write(">");
    }
    return "$sb";
  }

  int get hashCode {
    int code = 23;
    code = (71 * code + _declaration.hashCode) & 0x3fffffff;
    for (ReifiedType typeArgument in _typeArguments) {
      code = (71 * code + typeArgument.hashCode) & 0x3fffffff;
    }
    return code;
  }

  bool operator ==(other) {
    if (other is Interface) {
      if (_declaration != other._declaration) return false;
      if (identical(_typeArguments, other._typeArguments)) return true;
      assert(_typeArguments.length == other._typeArguments.length);
      for (int i = 0; i < _typeArguments.length; i++) {
        if (_typeArguments[i] != other._typeArguments[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

/// Represents the intersection type of [typeA] and [typeB]. The intersection
/// type represents a type that is a subtype of both [typeA] and [typeB].
///
/// This type is produced when a class implements the same interface twice with
/// different type arguments. For example:
///
///     abstract class MyNumberList implements List<int>, List<double> {}
///
/// Can lead to this intersection type:
///
///     new Intersection([[List<int>]], [[List<double>]])
///
/// For example,
///
///     [[MyNumberList]].asInstanceOf([[List]]) ->
///         new Intersection([[List<int>]], [[List<double>]])
///
/// Note: sometimes, people confuse this with union types. However the union
/// type of `A` and `B` would be anything that is a subtype of either `A` or
/// `B`.
///
/// See [Intersection types]
/// (https://en.wikipedia.org/wiki/Type_system#Intersection_types).
class Intersection extends ReifiedType {
  final ReifiedType typeA;
  final ReifiedType typeB;

  const Intersection(this.typeA, this.typeB) : super(Kind.Intersection);

  bool _isMoreSpecificThan(ReifiedType type) {
    // In the above example, `MyNumberList` is a subtype of List<int> *or*
    // List<double>.
    return typeA._isMoreSpecificThan(type) || typeB._isMoreSpecificThan(type);
  }

  ReifiedType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    ReifiedType aSubstitution = typeA._subst(arguments, parameters);
    ReifiedType bSubstitution = typeB._subst(arguments, parameters);
    return (aSubstitution == typeA && bSubstitution == typeB)
        ? this
        : _intersection(aSubstitution, bSubstitution);
  }

  String toString() => "{ $typeA, $typeB }";
}

/// Represents a type variable aka type parameter.
///
/// For example, this class:
///
///     class Box<T> {}
///
/// Defines one type variable. In the type `Box<int>`, there are no type
/// variables.  However, `int` is a type argument to the the type
/// parameter/variable `T`.
class TypeVariable extends ReifiedType {
  final int _id;

  // TODO(ahe): Do we need to reify bounds?
  ReifiedType bound;

  TypeVariable(this._id) : super(Kind.Variable);

  bool _isMoreSpecificThan(ReifiedType type) {
    if (type == this || type._isDynamic || type._isObject) return true;
    // The bounds of a type variable may contain a cycle, such as:
    //
    //     class C<T extends S, S extends T> {}
    //
    // We use the [tortoise and hare algorithm]
    // (https://en.wikipedia.org/wiki/Cycle_detection#Tortoise_and_hare) to
    // handle cycles.
    ReifiedType tortoise = bound;
    if (tortoise == type) return true;
    ReifiedType hare = getBoundOrNull(bound);
    while (tortoise != hare) {
      tortoise = getBoundOrNull(tortoise);
      if (tortoise == type) return true;
      hare = getBoundOrNull(getBoundOrNull(hare));
    }
    // Here we know that `tortoise == hare`. Either they're both `null` or we
    // detected a cycle.
    if (tortoise != null) {
      // There was a cycle of type variables in the bounds, but it didn't
      // involve [type]. The variable [tortoise] visited all the type variables
      // in the cycle (at least once), and each time we compared it to [type].
      return false;
    }
    // There are no cycles and it's safe to recurse on [bound].
    return bound._isMoreSpecificThan(type);
  }

  ReifiedType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    int index = 0;
    for (ReifiedType parameter in parameters) {
      if (this == parameter) return arguments[index];
      index++;
    }
    return this;
  }

  String toString() => "#$_id";
}

/// Represents a function type.
class FunctionType extends ReifiedType {
  /// Normally, the [Interface] representing [Function]. But an
  /// implementation-specific subtype of [Function] may also be used.
  final ReifiedType _supertype;

  final ReifiedType _returnType;

  /// Encodes number of optional parameters and if the optional parameters are
  /// named.
  final int _data;

  /// Encodes the argument types. Positional parameters use one element, the
  /// type; named parameters use two, the name [String] and type. Named
  /// parameters must be sorted by name.
  final List _encodedParameters;

  static const FunctionTypeRelation subtypeRelation =
      const FunctionSubtypeRelation();

  static const FunctionTypeRelation moreSpecificRelation =
      const FunctionMoreSpecificRelation();

  const FunctionType(
      this._supertype, this._returnType, this._data, this._encodedParameters)
      : super(Kind.Function);

  bool get hasNamedParameters => (_data & 1) == 1;

  int get optionalParameters => _data >> 1;

  int get parameters {
    return hasNamedParameters
        ? _encodedParameters.length - optionalParameters
        : _encodedParameters.length;
  }

  int get requiredParameters {
    return hasNamedParameters
        ? _encodedParameters.length - optionalParameters * 2
        : _encodedParameters.length - optionalParameters;
  }

  bool _isSubtypeOf(ReifiedType type) => subtypeRelation.areRelated(this, type);

  bool _isMoreSpecificThan(ReifiedType type) {
    return moreSpecificRelation.areRelated(this, type);
  }

  FunctionType _subst(
      List<ReifiedType> arguments, List<ReifiedType> parameters) {
    List substitutedParameters;
    int positionalParameters =
        hasNamedParameters ? requiredParameters : this.parameters;
    for (int i = 0; i < _encodedParameters.length; i++) {
      if (i >= positionalParameters) {
        // Skip the name of a named parameter.
        i++;
      }
      ReifiedType type = _encodedParameters[i];
      ReifiedType substitution = type._subst(arguments, parameters);
      if (substitution != type) {
        if (substitutedParameters == null) {
          substitutedParameters = new List.from(_encodedParameters);
        }
        substitutedParameters[i] = substitution;
      }
    }
    ReifiedType substitutedReturnType =
        _returnType._subst(arguments, parameters);
    if (substitutedParameters == null) {
      if (_returnType == substitutedReturnType) return this;
      substitutedParameters = _encodedParameters;
    }
    return new FunctionType(
        _supertype, substitutedReturnType, _data, substitutedParameters);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("(");
    bool first = true;
    for (int i = 0; i < requiredParameters; i++) {
      if (!first) {
        sb.write(", ");
      }
      sb.write(_encodedParameters[i]);
      first = false;
    }
    if (requiredParameters != parameters) {
      if (!first) {
        sb.write(", ");
      }
      if (hasNamedParameters) {
        sb.write("{");
        first = true;
        for (int i = requiredParameters;
            i < _encodedParameters.length;
            i += 2) {
          if (!first) {
            sb.write(", ");
          }
          sb.write(_encodedParameters[i + 1]);
          sb.write(" ");
          sb.write(_encodedParameters[i]);
          first = false;
        }
        sb.write("}");
      } else {
        sb.write("[");
        first = true;
        for (int i = requiredParameters; i < _encodedParameters.length; i++) {
          if (!first) {
            sb.write(", ");
          }
          sb.write(_encodedParameters[i]);
          first = false;
        }
        sb.write("]");
      }
    }
    sb.write(") -> ");
    sb.write(_returnType);
    return "$sb";
  }
}

abstract class FunctionTypeRelation {
  const FunctionTypeRelation();

  bool areRelated(FunctionType self, ReifiedType type, {bool isMoreSpecific}) {
    if (!type._isFunction) {
      return arePartsRelated(self._supertype, type);
    }
    FunctionType other = type;
    if (!other._returnType._isVoid) {
      if (!arePartsRelated(self._returnType, other._returnType)) return false;
    }
    int positionalParameters =
        self.hasNamedParameters ? self.requiredParameters : self.parameters;
    int otherPositionalParameters =
        other.hasNamedParameters ? other.requiredParameters : other.parameters;
    if (self.requiredParameters > other.requiredParameters) return false;
    if (positionalParameters < otherPositionalParameters) return false;

    for (int i = 0; i < otherPositionalParameters; i++) {
      if (!arePartsRelated(
          self._encodedParameters[i], other._encodedParameters[i])) {
        return false;
      }
    }

    if (!other.hasNamedParameters) true;

    int j = positionalParameters;
    for (int i = otherPositionalParameters;
        i < other._encodedParameters.length;
        i += 2) {
      String name = other._encodedParameters[i];
      for (; j < self._encodedParameters.length; j += 2) {
        if (self._encodedParameters[j] == name) break;
      }
      if (j == self._encodedParameters.length) return false;
      if (!arePartsRelated(
          self._encodedParameters[j + 1], other._encodedParameters[i + 1])) {
        return false;
      }
    }

    return true;
  }

  bool arePartsRelated(ReifiedType a, ReifiedType b);
}

class FunctionSubtypeRelation extends FunctionTypeRelation {
  const FunctionSubtypeRelation();

  bool arePartsRelated(ReifiedType a, ReifiedType b) => a._isAssignableTo(b);
}

class FunctionMoreSpecificRelation extends FunctionTypeRelation {
  const FunctionMoreSpecificRelation();

  bool arePartsRelated(ReifiedType a, ReifiedType b) =>
      a._isMoreSpecificThan(b);
}

/// If [type] is a type variable, return its bound. Otherwise `null`.
ReifiedType getBoundOrNull(ReifiedType type) {
  if (type == null) return null;
  if (!type._isVariable) return null;
  TypeVariable tv = type;
  return tv.bound;
}
