// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(sigmund): rename universe => world
/// Describes individual features that may be seen in a program. Most features
/// can be described only by name using the [Feature] enum, some features are
/// expressed including details on how they are used. For example, whether a
/// list literal was constant or empty.
///
/// The use of these features is typically discovered in an early phase of the
/// compilation pipeline, for example during resolution.
library;

import '../elements/types.dart';
import '../ir/runtime_type_analysis.dart';
import '../serialization/serialization.dart';
import '../util/util.dart';

/// A language feature that may be seen in the program.
// TODO(johnniwinther): Should mirror usage be part of this?
enum Feature {
  /// An assert statement with no message.
  assert_,

  /// An assert statement with a message.
  assertWithMessage,

  /// A method with an `async` body modifier.
  async,

  /// An asynchronous for in statement like `await for (var e in i) {}`.
  asyncForIn,

  /// A method with an `async*` body modifier.
  asyncStar,

  /// A catch statement.
  catchStatement,

  /// A fall through in a switch case.
  fallThroughError,

  /// A field without an initializer.
  fieldWithoutInitializer,

  /// A field whose initialization is not a constant.
  lazyField,

  /// A local variable without an initializer.
  localWithoutInitializer,

  /// Access to `loadLibrary` on a deferred import.
  loadLibrary,

  /// A catch clause with a variable for the stack trace.
  stackTraceInCatch,

  /// String interpolation.
  stringInterpolation,

  /// String juxtaposition.
  stringJuxtaposition,

  /// An implicit call to `super.noSuchMethod`, like calling an unresolved
  /// super method.
  superNoSuchMethod,

  /// An synchronous for in statement, like `for (var e in i) {}`.
  syncForIn,

  /// A method with a `sync*` body modifier.
  syncStar,

  /// A throw expression.
  throwExpression,

  /// An implicit throw of a `NoSuchMethodError`, like calling an unresolved
  /// static method.
  throwNoSuchMethod,

  /// An implicit throw of a runtime error, like in a runtime type check.
  throwRuntimeError,

  /// An implicit throw of a `UnsupportedError`, like calling `new
  /// bool.fromEnvironment`.
  throwUnsupportedError,

  /// The need for a type variable bound check, like instantiation of a generic
  /// type whose type variable have non-trivial bounds.
  typeVariableBoundsCheck,
}

/// Describes a use of a map literal in the program.
class MapLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  MapLiteralUse(this.type, {this.isConstant = false, this.isEmpty = false});

  @override
  int get hashCode {
    return type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! MapLiteralUse) return false;
    return type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }

  @override
  String toString() {
    return 'MapLiteralUse($type,isConstant:$isConstant,isEmpty:$isEmpty)';
  }
}

/// Describes a use of a set literal in the program.
class SetLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  SetLiteralUse(this.type, {this.isConstant = false, this.isEmpty = false});

  @override
  int get hashCode =>
      type.hashCode * 13 + isConstant.hashCode * 17 + isEmpty.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SetLiteralUse) return false;
    return type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }

  @override
  String toString() =>
      'SetLiteralUse($type,isConstant:$isConstant,isEmpty:$isEmpty)';
}

/// Describes the use of a list literal in the program.
class ListLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  ListLiteralUse(this.type, {this.isConstant = false, this.isEmpty = false});

  @override
  int get hashCode {
    return type.hashCode * 13 +
        isConstant.hashCode * 17 +
        isEmpty.hashCode * 19;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ListLiteralUse) return false;
    return type == other.type &&
        isConstant == other.isConstant &&
        isEmpty == other.isEmpty;
  }

  @override
  String toString() {
    return 'ListLiteralUse($type,isConstant:$isConstant,isEmpty:$isEmpty)';
  }
}

/// A use of `Object.runtimeType`.
class RuntimeTypeUse {
  /// The use kind of `Object.runtimeType`.
  final RuntimeTypeUseKind kind;

  /// The static type of the receiver.
  final DartType receiverType;

  /// The static type of the argument if [kind] is `RuntimeTypeUseKind.equals`.
  final DartType? argumentType;

  RuntimeTypeUse(this.kind, this.receiverType, this.argumentType);

  @override
  int get hashCode =>
      kind.hashCode * 13 +
      receiverType.hashCode * 17 +
      argumentType.hashCode * 19;

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! RuntimeTypeUse) return false;
    return kind == other.kind &&
        receiverType == other.receiverType &&
        argumentType == other.argumentType;
  }

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = StringBuffer();
    switch (kind) {
      case RuntimeTypeUseKind.string:
        sb.write('string:');
        sb.write(receiverType);
        break;
      case RuntimeTypeUseKind.equals:
        sb.write('equals:');
        sb.write(receiverType);
        sb.write('==');
        sb.write(argumentType);
        break;
      case RuntimeTypeUseKind.unknown:
        sb.write('unknown:');
        sb.write(receiverType);
        break;
    }
    return sb.toString();
  }

  @override
  String toString() =>
      'RuntimeTypeUse(kind=$kind,receiver=$receiverType'
      ',argument=$argumentType)';
}

/// A generic instantiation of an expression of type [functionType] with the
/// given [typeArguments].
class GenericInstantiation {
  static const String tag = 'generic-instantiation';

  /// The static type of the instantiated expression.
  final FunctionType functionType;

  /// The type arguments of the instantiation.
  final List<DartType> typeArguments;

  GenericInstantiation(this.functionType, this.typeArguments);

  factory GenericInstantiation.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final functionType = source.readDartType() as FunctionType;
    List<DartType> typeArguments = source.readDartTypes();
    source.end(tag);
    return GenericInstantiation(functionType, typeArguments);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDartType(functionType);
    sink.writeDartTypes(typeArguments);
    sink.end(tag);
  }

  /// Short textual representation use for testing.
  String get shortText => '<${typeArguments.join(',')}>';

  @override
  int get hashCode =>
      Hashing.listHash(typeArguments, Hashing.objectHash(functionType));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! GenericInstantiation) return false;
    if (functionType == other.functionType &&
        equalElements(typeArguments, other.typeArguments)) {
      assert(
        hashCode == other.hashCode,
        '\nthis:  $hashCode  $this'
        '\nthis:  ${other.hashCode}  $other',
      );
      return true;
    } else {
      return false;
    }
  }

  @override
  String toString() {
    return 'GenericInstantiation('
        'functionType:$functionType,'
        'typeArguments:$typeArguments'
        ')';
  }
}
