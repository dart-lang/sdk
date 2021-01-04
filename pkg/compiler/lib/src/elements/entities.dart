// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entities;

import 'package:front_end/src/api_unstable/dart2js.dart' show AsyncModifier;

import '../common.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../util/util.dart';
import 'names.dart';
import 'types.dart';

/// Abstract interface for entities.
///
/// Implement this directly if the entity is not a Dart language entity.
/// Entities defined within the Dart language should implement [Element].
///
/// For instance, the JavaScript backend need to create synthetic variables for
/// calling intercepted classes and such variables do not correspond to an
/// entity in the Dart source code nor in the terminology of the Dart language
/// and should therefore implement [Entity] directly.
abstract class Entity implements Spannable {
  String get name;
}

/// Stripped down super interface for library like entities.
///
/// Currently only [LibraryElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class LibraryEntity extends Entity {
  /// Return the canonical uri that identifies this library.
  Uri get canonicalUri;

  /// Returns whether or not this library has opted into null safety.
  bool get isNonNullableByDefault;
}

/// Stripped down super interface for import entities.
///
/// The [name] property corresponds to the prefix name, if any.
class ImportEntity {
  final String name;

  /// The canonical URI of the library where this import occurs
  /// (where the import is declared).
  final Uri enclosingLibraryUri;

  /// Whether the import is a deferred import.
  final bool isDeferred;

  /// The target import URI.
  final Uri uri;

  ImportEntity(this.isDeferred, this.name, this.uri, this.enclosingLibraryUri);

  @override
  String toString() => 'import($name:${isDeferred ? ' deferred' : ''})';
}

/// Stripped down super interface for class like entities.
///
/// Currently only [ClassElement] but later also kernel based Dart classes
/// and/or Dart-in-JS classes.
abstract class ClassEntity extends Entity {
  /// If this is a normal class, the enclosing library for this class. If this
  /// is a closure class, the enclosing class of the closure for which it was
  /// created.
  LibraryEntity get library;

  /// Whether this is a synthesized class for a closurized method or local
  /// function.
  bool get isClosure;

  /// Whether this is an abstract class.
  bool get isAbstract;
}

abstract class TypeVariableEntity extends Entity {
  /// The class or generic method that declared this type variable.
  Entity get typeDeclaration;

  /// The index of this type variable in the type variables of its
  /// [typeDeclaration].
  int get index;
}

/// Stripped down super interface for member like entities, that is,
/// constructors, methods, fields etc.
///
/// Currently only [MemberElement] but later also kernel based Dart members
/// and/or Dart-in-JS properties.
abstract class MemberEntity extends Entity {
  /// The [Name] of member which takes privacy and getter/setter naming into
  /// account.
  Name get memberName;

  /// Whether this is a member of a library.
  bool get isTopLevel;

  /// Whether this is a static member of a class.
  bool get isStatic;

  /// Whether this is an instance member of a class.
  bool get isInstanceMember;

  /// Whether this is a constructor.
  bool get isConstructor;

  /// Whether this is a field.
  bool get isField;

  /// Whether this is a normal method (neither constructor, getter or setter)
  /// or operator method.
  bool get isFunction;

  /// Whether this is a getter.
  bool get isGetter;

  /// Whether this is a setter.
  bool get isSetter;

  /// Whether this member is assignable, i.e. a non-final, non-const field.
  bool get isAssignable;

  /// Whether this member is constant, i.e. a constant field or constructor.
  bool get isConst;

  /// Whether this member is abstract, i.e. an abstract method, getter or
  /// setter.
  bool get isAbstract;

  /// The enclosing class if this is a constructor, instance member or
  /// static member of a class.
  ClassEntity get enclosingClass;

  /// The enclosing library if this is a library member, otherwise the
  /// enclosing library of the [enclosingClass].
  LibraryEntity get library;
}

/// Stripped down super interface for field like entities.
///
/// Currently only [FieldElement] but later also kernel based Dart fields
/// and/or Dart-in-JS field-like properties.
abstract class FieldEntity extends MemberEntity {}

/// Stripped down super interface for function like entities.
///
/// Currently only [MethodElement] but later also kernel based Dart constructors
/// and methods and/or Dart-in-JS function-like properties.
abstract class FunctionEntity extends MemberEntity {
  /// Whether this function is external, i.e. the body is not defined in terms
  /// of Dart code.
  bool get isExternal;

  /// The structure of the function parameters.
  ParameterStructure get parameterStructure;

  /// The synchronous/asynchronous marker on this function.
  AsyncMarker get asyncMarker;
}

/// Enum for the synchronous/asynchronous function body modifiers.
class AsyncMarker {
  /// The default function body marker.
  static const AsyncMarker SYNC = const AsyncMarker._(AsyncModifier.Sync);

  /// The `sync*` function body marker.
  static const AsyncMarker SYNC_STAR =
      const AsyncMarker._(AsyncModifier.SyncStar, isYielding: true);

  /// The `async` function body marker.
  static const AsyncMarker ASYNC =
      const AsyncMarker._(AsyncModifier.Async, isAsync: true);

  /// The `async*` function body marker.
  static const AsyncMarker ASYNC_STAR = const AsyncMarker._(
      AsyncModifier.AsyncStar,
      isAsync: true,
      isYielding: true);

  /// Is `true` if this marker defines the function body to have an
  /// asynchronous result, that is, either a [Future] or a [Stream].
  final bool isAsync;

  /// Is `true` if this marker defines the function body to have a plural
  /// result, that is, either an [Iterable] or a [Stream].
  final bool isYielding;

  final AsyncModifier asyncParserState;

  const AsyncMarker._(this.asyncParserState,
      {this.isAsync: false, this.isYielding: false});

  @override
  String toString() {
    return '${isAsync ? 'async' : 'sync'}${isYielding ? '*' : ''}';
  }

  /// Canonical list of marker values.
  ///
  /// Added to make [AsyncMarker] enum-like.
  static const List<AsyncMarker> values = const <AsyncMarker>[
    SYNC,
    SYNC_STAR,
    ASYNC,
    ASYNC_STAR
  ];

  /// Index to this marker within [values].
  ///
  /// Added to make [AsyncMarker] enum-like.
  int get index => values.indexOf(this);
}

/// Values for variance annotations.
/// This needs to be kept in sync with values of `Variance` in `dart:_rti`.
enum Variance { legacyCovariant, covariant, contravariant, invariant }

/// Stripped down super interface for constructor like entities.
///
/// Currently only [ConstructorElement] but later also kernel based Dart
/// constructors and/or Dart-in-JS constructor-like properties.
// TODO(johnniwinther): Remove factory constructors from the set of
// constructors.
abstract class ConstructorEntity extends FunctionEntity {
  /// Whether this is a generative constructor, possibly redirecting.
  bool get isGenerativeConstructor;

  /// Whether this is a factory constructor, possibly redirecting.
  bool get isFactoryConstructor;

  /// Whether this is a `fromEnvironment` const constructor in `int`, `bool` or
  /// `String`.
  bool get isFromEnvironmentConstructor;
}

/// The constructor body for a [ConstructorEntity].
///
/// This is used only in the backend to split encoding of a Dart constructor
/// into two JavaScript functions; the constructor and the constructor body.
// TODO(johnniwinther): Remove this when modelx is removed. Constructor bodies
// should then be created directly with the J-model.
abstract class ConstructorBodyEntity extends FunctionEntity {
  /// The constructor for which this constructor body was created.
  ConstructorEntity get constructor;
}

/// An entity that defines a local entity (memory slot) in generated code.
///
/// Parameters, local variables and local functions (can) define local entity
/// and thus implement [Local] through [LocalElement]. For non-element locals,
/// like `this` and boxes, specialized [Local] classes are created.
///
/// Type variables can introduce locals in factories and constructors
/// but since one type variable can introduce different locals in different
/// factories and constructors it is not itself a [Local] but instead
/// a non-element [Local] is created through a specialized class.
abstract class Local extends Entity {}

/// The structure of function parameters.
class ParameterStructure {
  /// Tag used for identifying serialized [ParameterStructure] objects in a
  /// debugging data stream.
  static const String tag = 'parameter-structure';

  /// The number of required positional parameters.
  final int requiredPositionalParameters;

  /// The number of positional parameters.
  final int positionalParameters;

  /// All named parameters sorted alphabetically.
  final List<String> namedParameters;

  /// The required named parameters.
  final Set<String> requiredNamedParameters;

  /// The number of type parameters.
  final int typeParameters;

  static const ParameterStructure getter =
      ParameterStructure._(0, 0, [], {}, 0);

  static const ParameterStructure setter =
      ParameterStructure._(1, 1, [], {}, 0);

  static const ParameterStructure zeroArguments =
      ParameterStructure._(0, 0, [], {}, 0);

  static const List<ParameterStructure> _simple = [
    ParameterStructure._(0, 0, [], {}, 0),
    ParameterStructure._(1, 1, [], {}, 0),
    ParameterStructure._(2, 2, [], {}, 0),
    ParameterStructure._(3, 3, [], {}, 0),
    ParameterStructure._(4, 4, [], {}, 0),
    ParameterStructure._(5, 5, [], {}, 0),
  ];

  const ParameterStructure._(
      this.requiredPositionalParameters,
      this.positionalParameters,
      this.namedParameters,
      this.requiredNamedParameters,
      this.typeParameters);

  factory ParameterStructure(
      int requiredPositionalParameters,
      int positionalParameters,
      List<String> namedParameters,
      Set<String> requiredNamedParameters,
      int typeParameters) {
    // This simple canonicalization reduces the number of ParameterStructure
    // objects by over 90%.
    if (requiredPositionalParameters == positionalParameters &&
        namedParameters.isEmpty &&
        requiredNamedParameters.isEmpty &&
        typeParameters == 0 &&
        positionalParameters < _simple.length) {
      return _simple[positionalParameters];
    }

    // Force sharing of empty collections.
    if (namedParameters.isEmpty) namedParameters = const [];
    if (requiredNamedParameters.isEmpty) requiredNamedParameters = const {};

    return ParameterStructure._(
      requiredPositionalParameters,
      positionalParameters,
      namedParameters,
      requiredNamedParameters,
      typeParameters,
    );
  }

  factory ParameterStructure.fromType(FunctionType type) {
    return ParameterStructure(
        type.parameterTypes.length,
        type.parameterTypes.length + type.optionalParameterTypes.length,
        type.namedParameters,
        type.requiredNamedParameters,
        type.typeVariables.length);
  }

  /// Deserializes a [ParameterStructure] object from [source].
  factory ParameterStructure.readFromDataSource(DataSource source) {
    source.begin(tag);
    int requiredPositionalParameters = source.readInt();
    int positionalParameters = source.readInt();
    List<String> namedParameters = source.readStrings();
    Set<String> requiredNamedParameters =
        source.readStrings(emptyAsNull: true)?.toSet() ?? const <String>{};
    int typeParameters = source.readInt();
    source.end(tag);
    return ParameterStructure(
        requiredPositionalParameters,
        positionalParameters,
        namedParameters,
        requiredNamedParameters,
        typeParameters);
  }

  /// Serializes this [ParameterStructure] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeInt(requiredPositionalParameters);
    sink.writeInt(positionalParameters);
    sink.writeStrings(namedParameters);
    sink.writeStrings(requiredNamedParameters);
    sink.writeInt(typeParameters);
    sink.end(tag);
  }

  /// The number of optional parameters (positional or named).
  int get optionalParameters =>
      (positionalParameters - requiredPositionalParameters) +
      (namedParameters.length - requiredNamedParameters.length);

  /// The total number of parameters (required or optional).
  int get totalParameters => positionalParameters + namedParameters.length;

  /// Returns the [CallStructure] corresponding to a call site passing all
  /// parameters both required and optional.
  CallStructure get callStructure {
    return CallStructure(totalParameters, namedParameters, typeParameters);
  }

  @override
  int get hashCode => Hashing.listHash(
      namedParameters,
      Hashing.setHash(
          requiredNamedParameters,
          Hashing.objectHash(
              positionalParameters,
              Hashing.objectHash(requiredPositionalParameters,
                  Hashing.objectHash(typeParameters)))));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ParameterStructure) return false;
    if (requiredPositionalParameters != other.requiredPositionalParameters ||
        positionalParameters != other.positionalParameters ||
        typeParameters != other.typeParameters ||
        namedParameters.length != other.namedParameters.length ||
        requiredNamedParameters.length !=
            other.requiredNamedParameters.length) {
      return false;
    }
    for (int i = 0; i < namedParameters.length; i++) {
      if (namedParameters[i] != other.namedParameters[i]) {
        return false;
      }
    }
    for (String name in requiredNamedParameters) {
      if (!other.requiredNamedParameters.contains(name)) return false;
    }
    return true;
  }

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = StringBuffer();
    if (typeParameters != 0) {
      sb.write('<');
      sb.write(typeParameters);
      sb.write('>');
    }
    sb.write('(');
    sb.write(positionalParameters);
    for (var name in namedParameters) {
      sb.write(',');
      if (requiredNamedParameters.contains(name)) sb.write('req ');
      sb.write(name);
    }
    sb.write(')');
    return sb.toString();
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('ParameterStructure(');
    sb.write('requiredPositionalParameters=$requiredPositionalParameters,');
    sb.write('positionalParameters=$positionalParameters,');
    sb.write('namedParameters={${namedParameters.join(',')}},');
    sb.write('requiredNamedParameters={${requiredNamedParameters.join(',')}},');
    sb.write('typeParameters=$typeParameters)');
    return sb.toString();
  }

  int get size => totalParameters + typeParameters;
}
