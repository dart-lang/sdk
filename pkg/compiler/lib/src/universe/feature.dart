// TODO(sigmund): rename universe => world
/// Describes individual features that may be seen in a program. Most features
/// can be described only by name using the [Feature] enum, some features are
/// expressed including details on how they are used. For example, whether a
/// list literal was constant or empty.
///
/// The use of these features is typically discovered in an early phase of the
/// compilation pipeline, for example during resolution.
library compiler.universe.feature;

import '../elements/types.dart';
import '../ir/runtime_type_analysis.dart';
import '../serialization/serialization.dart';
import '../util/util.dart';

/// A language feature that may be seen in the program.
// TODO(johnniwinther): Should mirror usage be part of this?
enum Feature {
  /// An assert statement with no message.
  ASSERT,

  /// An assert statement with a message.
  ASSERT_WITH_MESSAGE,

  /// A method with an `async` body modifier.
  ASYNC,

  /// An asynchronous for in statement like `await for (var e in i) {}`.
  ASYNC_FOR_IN,

  /// A method with an `async*` body modifier.
  ASYNC_STAR,

  /// A catch statement.
  CATCH_STATEMENT,

  /// A fall through in a switch case.
  FALL_THROUGH_ERROR,

  /// A field without an initializer.
  FIELD_WITHOUT_INITIALIZER,

  /// A field whose initialization is not a constant.
  LAZY_FIELD,

  /// A local variable without an initializer.
  LOCAL_WITHOUT_INITIALIZER,

  /// Access to `loadLibrary` on a deferred import.
  LOAD_LIBRARY,

  /// A catch clause with a variable for the stack trace.
  STACK_TRACE_IN_CATCH,

  /// String interpolation.
  STRING_INTERPOLATION,

  /// String juxtaposition.
  STRING_JUXTAPOSITION,

  /// An implicit call to `super.noSuchMethod`, like calling an unresolved
  /// super method.
  SUPER_NO_SUCH_METHOD,

  /// A redirection to the `Symbol` constructor.
  SYMBOL_CONSTRUCTOR,

  /// An synchronous for in statement, like `for (var e in i) {}`.
  SYNC_FOR_IN,

  /// A method with a `sync*` body modifier.
  SYNC_STAR,

  /// A throw expression.
  THROW_EXPRESSION,

  /// An implicit throw of a `NoSuchMethodError`, like calling an unresolved
  /// static method.
  THROW_NO_SUCH_METHOD,

  /// An implicit throw of a runtime error, like in a runtime type check.
  THROW_RUNTIME_ERROR,

  /// An implicit throw of a `UnsupportedError`, like calling `new
  /// bool.fromEnvironment`.
  THROW_UNSUPPORTED_ERROR,

  /// The need for a type variable bound check, like instantiation of a generic
  /// type whose type variable have non-trivial bounds.
  TYPE_VARIABLE_BOUNDS_CHECK,
}

/// Describes a use of a map literal in the program.
class MapLiteralUse {
  final InterfaceType type;
  final bool isConstant;
  final bool isEmpty;

  MapLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

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

  SetLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

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

  ListLiteralUse(this.type, {this.isConstant: false, this.isEmpty: false});

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
  final DartType argumentType;

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
    StringBuffer sb = new StringBuffer();
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
  String toString() => 'RuntimeTypeUse(kind=$kind,receiver=$receiverType'
      ',argument=$argumentType)';
}

/// A generic instantiation of an expression of type [functionType] with the
/// given [typeArguments].
class GenericInstantiation {
  static const String tag = 'generic-instantiation';

  /// The static type of the instantiated expression.
  final DartType functionType;

  /// The type arguments of the instantiation.
  final List<DartType> typeArguments;

  GenericInstantiation(this.functionType, this.typeArguments);

  factory GenericInstantiation.readFromDataSource(DataSource source) {
    source.begin(tag);
    DartType functionType = source.readDartType();
    List<DartType> typeArguments = source.readDartTypes();
    source.end(tag);
    return new GenericInstantiation(functionType, typeArguments);
  }

  void writeToDataSink(DataSink sink) {
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
    return functionType == other.functionType &&
        equalElements(typeArguments, other.typeArguments);
  }

  @override
  String toString() {
    return 'GenericInstantiation(functionType:$functionType,'
        'typeArguments:$typeArguments)';
  }
}
