// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.call_structure;

import '../common/names.dart' show Names;
import '../elements/entities.dart' show ParameterStructure;
import '../util/util.dart';
import 'selector.dart' show Selector;

/// The structure of the arguments at a call-site.
// TODO(johnniwinther): Should these be cached?
// TODO(johnniwinther): Should isGetter/isSetter be part of the call structure
// instead of the selector?
class CallStructure {
  static const CallStructure NO_ARGS = const CallStructure.unnamed(0);
  static const CallStructure ONE_ARG = const CallStructure.unnamed(1);
  static const CallStructure TWO_ARGS = const CallStructure.unnamed(2);
  static const CallStructure THREE_ARGS = const CallStructure.unnamed(3);

  /// The numbers of arguments of the call. Includes named arguments.
  final int argumentCount;

  /// The number of named arguments of the call.
  int get namedArgumentCount => 0;

  /// The number of positional argument of the call.
  int get positionalArgumentCount => argumentCount;

  const CallStructure.unnamed(this.argumentCount);

  factory CallStructure(int argumentCount, [List<String> namedArguments]) {
    if (namedArguments == null || namedArguments.isEmpty) {
      return new CallStructure.unnamed(argumentCount);
    }
    return new NamedCallStructure(argumentCount, namedArguments);
  }

  /// `true` if this call has named arguments.
  bool get isNamed => false;

  /// `true` if this call has no named arguments.
  bool get isUnnamed => true;

  /// The names of the named arguments in call-site order.
  List<String> get namedArguments => const <String>[];

  /// The names of the named arguments in canonicalized order.
  List<String> getOrderedNamedArguments() => const <String>[];

  /// A description of the argument structure.
  String structureToString() => 'arity=$argumentCount';

  String toString() => 'CallStructure(${structureToString()})';

  Selector get callSelector => new Selector.call(Names.call, this);

  bool match(CallStructure other) {
    if (identical(this, other)) return true;
    return this.argumentCount == other.argumentCount &&
        this.namedArgumentCount == other.namedArgumentCount &&
        sameNames(this.namedArguments, other.namedArguments);
  }

  // TODO(johnniwinther): Cache hash code?
  int get hashCode {
    return Hashing.listHash(namedArguments,
        Hashing.objectHash(argumentCount, namedArguments.length));
  }

  bool operator ==(other) {
    if (other is! CallStructure) return false;
    return match(other);
  }

  bool signatureApplies(ParameterStructure parameters) {
    int requiredParameterCount = parameters.requiredParameters;
    int optionalParameterCount = parameters.optionalParameters;
    int parameterCount = requiredParameterCount + optionalParameterCount;
    if (argumentCount > parameterCount) return false;
    if (positionalArgumentCount < requiredParameterCount) return false;

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
      if (namedArgumentCount > optionalParameterCount) return false;

      int nameIndex = 0;
      List<String> namedParameters = parameters.namedParameters;
      for (String name in getOrderedNamedArguments()) {
        bool found = false;
        // Note: we start at the existing index because arguments are sorted.
        while (nameIndex < namedParameters.length) {
          if (name == namedParameters[nameIndex]) {
            found = true;
            break;
          }
          nameIndex++;
        }
        if (!found) return false;
      }
      return true;
    }
  }

  static bool sameNames(List<String> first, List<String> second) {
    for (int i = 0; i < first.length; i++) {
      if (first[i] != second[i]) return false;
    }
    return true;
  }
}

///
class NamedCallStructure extends CallStructure {
  final List<String> namedArguments;
  final List<String> _orderedNamedArguments = <String>[];

  NamedCallStructure(int argumentCount, this.namedArguments)
      : super.unnamed(argumentCount) {
    assert(namedArguments.isNotEmpty);
  }

  @override
  bool get isNamed => true;

  @override
  bool get isUnnamed => false;

  @override
  int get namedArgumentCount => namedArguments.length;

  @override
  int get positionalArgumentCount => argumentCount - namedArgumentCount;

  @override
  List<String> getOrderedNamedArguments() {
    if (!_orderedNamedArguments.isEmpty) return _orderedNamedArguments;

    _orderedNamedArguments.addAll(namedArguments);
    _orderedNamedArguments.sort((String first, String second) {
      return first.compareTo(second);
    });
    return _orderedNamedArguments;
  }

  @override
  String structureToString() {
    return 'arity=$argumentCount, named=[${namedArguments.join(', ')}]';
  }
}
