// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'exceptions.dart';

/// A base class for (spec-generated) classes that represent the `body` of a an
/// event.
abstract class EventBody {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}

/// A generic event body class that just supplies an object directly.
///
/// Used to support custom events sent by the debug adapter such as 'dart.log'.
///
/// The supplied [body] must be convertible to JSON.
class RawEventBody extends EventBody {
  final Object body;

  RawEventBody(this.body)
      : assert(() {
          try {
            jsonEncode(body);
            return true;
          } catch (e) {
            return false;
          }
        }(), 'body should be JSON encodable');

  Object toJson() => body;
}

/// A generic arguments class that just supplies the arguments map directly.
///
/// Used to support custom requests that may be provided by other implementing
/// adapters that are not known at compile time by DDS/base DAP.
class RawRequestArguments extends RequestArguments {
  final Map<String, Object?> args;

  RawRequestArguments.fromMap(this.args);

  static RawRequestArguments fromJson(Map<String, Object?> obj) =>
      RawRequestArguments.fromMap(obj);
}

/// A base class for (spec-generated) classes that represent the `arguments` of
/// a request.
abstract class RequestArguments {
  static bool canParse(Object? obj) => obj is Map<String, Object?>?;
}

/// A helper for reading arguments for DAP requests from the client.
class DebugAdapterArgumentReader {
  final String request;

  DebugAdapterArgumentReader(this.request);

  /// Reads a value of type [T] from [field] in [obj].
  T read<T>(
    Map<String, Object?> obj,
    String field,
  ) {
    final value = obj[field];
    if (value is! T) {
      throw DebugAdapterInvalidArgumentException(
        requestName: request,
        argumentName: field,
        expectedType: T,
        actualType: value.runtimeType,
        actualValue: value,
      );
    }
    return obj[field] as T;
  }

  /// Reads a List of values of type [T] from [field] in [obj].
  List<T> readList<T>(
    Map<String, Object?> obj,
    String field,
  ) {
    final value = obj[field];
    if (value is! List || !value.every((element) => element is T)) {
      throw DebugAdapterInvalidArgumentException(
        requestName: request,
        argumentName: field,
        expectedType: List<T>,
        actualType: value.runtimeType,
        actualValue: value,
      );
    }
    return (obj[field] as List<Object?>).cast<T>();
  }

  /// Reads an optional List of values of type [T] from [field] in [obj].
  List<T>? readOptionalList<T>(
    Map<String, Object?> obj,
    String field,
  ) {
    return obj.containsKey(field) ? readList<T>(obj, field) : null;
  }

  /// Reads an optional Map of types [K],[V] from [field] in [obj].
  Map<K, V>? readOptionalMap<K, V>(
    Map<String, Object?> obj,
    String field,
  ) {
    return obj.containsKey(field) ? readMap<K, V>(obj, field) : null;
  }

  /// Reads a Map of types [K],[V] from [field] in [obj].
  Map<K, V> readMap<K, V>(
    Map<String, Object?> obj,
    String field,
  ) {
    final value = obj[field];
    if (value is! Map ||
        !value.entries.every((entry) => entry.key is K && entry.value is V)) {
      throw DebugAdapterInvalidArgumentException(
        requestName: request,
        argumentName: field,
        expectedType: Map<K, V>,
        actualType: value.runtimeType,
        actualValue: value,
      );
    }
    return (obj[field] as Map<Object?, Object?>).cast<K, V>();
  }
}
