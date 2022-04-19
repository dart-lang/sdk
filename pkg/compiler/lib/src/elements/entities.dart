// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.10

library entities;

import '../serialization/serialization.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../util/util.dart';
import 'types.dart';

import 'entities_migrated.dart';
export 'entities_migrated.dart';

abstract class TypeVariableEntity extends Entity {
  /// The class or generic method that declared this type variable.
  Entity get typeDeclaration;

  /// The index of this type variable in the type variables of its
  /// [typeDeclaration].
  int get index;
}

/// Stripped down super interface for function like entities.
///
/// Currently only [MethodElement] but later also kernel based Dart constructors
/// and methods and/or Dart-in-JS function-like properties.
abstract class FunctionEntity extends MemberEntity {
  /// Whether this function is external, i.e. the body is not defined in terms
  /// of Dart code.
  bool /*!*/ get isExternal;

  /// The structure of the function parameters.
  ParameterStructure get parameterStructure;

  /// The synchronous/asynchronous marker on this function.
  AsyncMarker get asyncMarker;
}

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

  static const ParameterStructure oneArgument =
      ParameterStructure._(1, 1, [], {}, 0);

  static const ParameterStructure twoArguments =
      ParameterStructure._(2, 2, [], {}, 0);

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
      List<String /*!*/ > namedParameters,
      Set<String /*!*/ > requiredNamedParameters,
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
  factory ParameterStructure.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    int requiredPositionalParameters = source.readInt();
    int positionalParameters = source.readInt();
    List<String> namedParameters = source.readStrings() /*!*/;
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
  void writeToDataSink(DataSinkWriter sink) {
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
