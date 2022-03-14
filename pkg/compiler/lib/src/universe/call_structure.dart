// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.call_structure;

import '../common/names.dart' show Names;
import '../elements/entities.dart' show ParameterStructure;
import '../serialization/serialization.dart';
import '../util/util.dart';
import 'selector.dart' show Selector;

/// The structure of the arguments at a call-site.
///
/// A call-site passes some number of arguments: some positional arguments
/// followed by some named arguments. There may also be type arguments.
///
/// A CallStructure is unmodifiable.

// TODO(johnniwinther): Should isGetter/isSetter be part of the call structure
// instead of the selector?
class CallStructure {
  /// Tag used for identifying serialized [CallStructure] objects in a debugging
  /// data stream.
  static const String tag = 'call-structure';

  static const CallStructure NO_ARGS = CallStructure._(0);
  static const CallStructure ONE_ARG = CallStructure._(1);
  static const CallStructure TWO_ARGS = CallStructure._(2);

  static const List<List<CallStructure>> _common = [
    [NO_ARGS, CallStructure._(0, 1), CallStructure._(0, 2)],
    [ONE_ARG, CallStructure._(1, 1), CallStructure._(1, 2)],
    [TWO_ARGS, CallStructure._(2, 1), CallStructure._(2, 2)],
    [CallStructure._(3), CallStructure._(3, 1), CallStructure._(3, 2)],
    [CallStructure._(4), CallStructure._(4, 1), CallStructure._(4, 2)],
    [CallStructure._(5), CallStructure._(5, 1), CallStructure._(5, 2)],
    [CallStructure._(6)],
    [CallStructure._(7)],
    [CallStructure._(8)],
    [CallStructure._(9)],
    [CallStructure._(10)],
  ];

  /// The number of type arguments of the call.
  final int typeArgumentCount;

  /// The numbers of arguments of the call. Includes named arguments.
  final int argumentCount;

  /// The number of named arguments of the call.
  int get namedArgumentCount => 0;

  /// The number of positional argument of the call.
  int get positionalArgumentCount => argumentCount;

  const CallStructure._(this.argumentCount, [this.typeArgumentCount = 0]);

  factory CallStructure.unnamed(int argumentCount,
      [int typeArgumentCount = 0]) {
    // This simple canonicalization of common call structures greatly reduces
    // the number of allocations of CallStructure objects.
    if (argumentCount < _common.length) {
      final row = _common[argumentCount];
      if (typeArgumentCount < row.length) {
        final result = row[typeArgumentCount];
        assert(result.argumentCount == argumentCount &&
            result.typeArgumentCount == typeArgumentCount);
        return result;
      }
    }
    return CallStructure._(argumentCount, typeArgumentCount);
  }

  factory CallStructure(int argumentCount,
      [List<String> namedArguments, int typeArgumentCount = 0]) {
    if (namedArguments == null || namedArguments.isEmpty) {
      return CallStructure.unnamed(argumentCount, typeArgumentCount);
    }
    return _NamedCallStructure(
        argumentCount, namedArguments, typeArgumentCount, null);
  }

  /// Deserializes a [CallStructure] object from [source].
  factory CallStructure.readFromDataSource(DataSource source) {
    source.begin(tag);
    int argumentCount = source.readInt();
    List<String> namedArguments = source.readStrings();
    int typeArgumentCount = source.readInt();
    source.end(tag);
    return CallStructure(argumentCount, namedArguments, typeArgumentCount);
  }

  /// Serializes this [CallStructure] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeInt(argumentCount);
    sink.writeStrings(namedArguments);
    sink.writeInt(typeArgumentCount);
    sink.end(tag);
  }

  /// Returns `true` if this call structure is normalized, that is, its named
  /// arguments are sorted.
  bool get isNormalized => true;

  /// Returns the normalized version of this call structure.
  ///
  /// A [CallStructure] is normalized if its named arguments are sorted.
  CallStructure toNormalized() => this;

  CallStructure withTypeArgumentCount(int typeArgumentCount) =>
      CallStructure(argumentCount, namedArguments, typeArgumentCount);

  /// `true` if this call has named arguments.
  bool get isNamed => false;

  /// `true` if this call has no named arguments.
  bool get isUnnamed => true;

  /// The names of the named arguments in call-site order.
  List<String> get namedArguments => const [];

  /// The names of the named arguments in canonicalized order.
  List<String> getOrderedNamedArguments() => const [];

  CallStructure get nonGeneric => typeArgumentCount == 0
      ? this
      : CallStructure(argumentCount, namedArguments);

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = StringBuffer();
    sb.write('(');
    sb.write(positionalArgumentCount);
    if (namedArgumentCount > 0) {
      sb.write(',');
      sb.write(getOrderedNamedArguments().join(','));
    }
    sb.write(')');
    return sb.toString();
  }

  /// A description of the argument structure.
  String structureToString() {
    StringBuffer sb = StringBuffer();
    sb.write('arity=$argumentCount');
    if (typeArgumentCount != 0) {
      sb.write(', types=$typeArgumentCount');
    }
    return sb.toString();
  }

  @override
  String toString() => 'CallStructure(${structureToString()})';

  Selector get callSelector => Selector.call(Names.call, this);

  bool match(CallStructure other) {
    if (identical(this, other)) return true;
    return this.argumentCount == other.argumentCount &&
        this.namedArgumentCount == other.namedArgumentCount &&
        this.typeArgumentCount == other.typeArgumentCount &&
        _sameNames(this.namedArguments, other.namedArguments);
  }

  // TODO(johnniwinther): Cache hash code?
  @override
  int get hashCode {
    return Hashing.listHash(
        namedArguments,
        Hashing.objectHash(argumentCount,
            Hashing.objectHash(typeArgumentCount, namedArguments.length)));
  }

  @override
  bool operator ==(other) {
    if (other is! CallStructure) return false;
    return match(other);
  }

  bool signatureApplies(ParameterStructure parameters) {
    int requiredParameterCount = parameters.requiredPositionalParameters;
    int optionalParameterCount = parameters.optionalParameters;
    int parameterCount = parameters.totalParameters;
    if (argumentCount > parameterCount) return false;
    if (positionalArgumentCount < requiredParameterCount) return false;
    if (typeArgumentCount != 0) {
      if (typeArgumentCount != parameters.typeParameters) return false;
    }

    if (parameters.namedParameters.isEmpty) {
      // We have already checked that the number of arguments are
      // not greater than the number of parameters. Therefore the
      // number of positional arguments are not greater than the
      // number of parameters.
      assert(positionalArgumentCount <= parameterCount);
      return namedArguments.isEmpty;
    } else {
      if (positionalArgumentCount > requiredParameterCount) return false;
      assert(positionalArgumentCount == requiredParameterCount);
      if (namedArgumentCount >
          optionalParameterCount + parameters.requiredNamedParameters.length)
        return false;

      int nameIndex = 0;
      List<String> namedParameters = parameters.namedParameters;
      int seenRequiredNamedParameters = 0;

      for (String name in getOrderedNamedArguments()) {
        bool found = false;
        // Note: we start at the existing index because arguments are sorted.
        while (nameIndex < namedParameters.length) {
          String parameterName = namedParameters[nameIndex];
          if (name == parameterName) {
            if (parameters.requiredNamedParameters.contains(name))
              seenRequiredNamedParameters++;
            found = true;
            break;
          }
          nameIndex++;
        }
        if (!found) return false;
      }
      return seenRequiredNamedParameters ==
          parameters.requiredNamedParameters.length;
    }
  }

  static bool _sameNames(List<String> first, List<String> second) {
    assert(first.length == second.length);
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}

/// Call structure with named arguments. This is an implementation detail of the
/// CallStructure interface.
class _NamedCallStructure extends CallStructure {
  @override
  final List<String> namedArguments;

  /// The list of ordered named arguments is computed lazily. Initially `null`.
  List<String> /*?*/ _orderedNamedArguments;

  _NamedCallStructure(int argumentCount, this.namedArguments,
      int typeArgumentCount, this._orderedNamedArguments)
      : assert(namedArguments.isNotEmpty),
        super._(argumentCount, typeArgumentCount);

  @override
  bool get isNamed => true;

  @override
  bool get isUnnamed => false;

  @override
  int get namedArgumentCount => namedArguments.length;

  @override
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  @override
  bool get isNormalized =>
      identical(namedArguments, getOrderedNamedArguments());

  @override
  CallStructure toNormalized() => isNormalized
      ? this
      : _NamedCallStructure(argumentCount, getOrderedNamedArguments(),
          typeArgumentCount, getOrderedNamedArguments());

  @override
  List<String> getOrderedNamedArguments() {
    return _orderedNamedArguments ??= _getOrderedNamedArguments();
  }

  List<String> _getOrderedNamedArguments() {
    List<String> ordered = List.of(namedArguments, growable: false);
    ordered.sort((String first, String second) => first.compareTo(second));
    // Use the same List if [namedArguments] is already ordered to indicate this
    // _NamedCallStructure is normalized.
    if (CallStructure._sameNames(ordered, namedArguments)) {
      return namedArguments;
    }
    return ordered;
  }

  @override
  String structureToString() {
    StringBuffer sb = StringBuffer();
    sb.write('arity=$argumentCount, named=[${namedArguments.join(', ')}]');
    if (typeArgumentCount != 0) {
      sb.write(', types=$typeArgumentCount');
    }
    return sb.toString();
  }
}
