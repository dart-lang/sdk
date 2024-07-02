// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart';

const jsonRpcVersion = '2.0';

const nullJsonHandler = LspJsonHandler<void>(_alwaysTrue, _alwaysNull);

/// Returns if two objects are equal, recursively checking items in
/// Maps/Lists.
bool lspEquals(dynamic obj1, dynamic obj2) {
  return const DeepCollectionEquality().equals(obj1, obj2);
}

/// Returns an objects hash code, recursively combining hashes for items in
/// Maps/Lists.
int lspHashCode(dynamic obj) {
  return const DeepCollectionEquality().hash(obj);
}

Object? specToJson(Object? obj) {
  if (obj is ToJsonable) {
    return obj.toJson();
  } else {
    return obj;
  }
}

void _alwaysNull(_, [__]) {}

bool _alwaysTrue(_, [__]) => true;

typedef DocumentChanges
    = List<Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>;

class Either2<T1, T2> implements ToJsonable {
  final int _which;
  final T1? _t1;
  final T2? _t2;

  const Either2.t1(T1 this._t1)
      : _t2 = null,
        _which = 1;

  const Either2.t2(T2 this._t2)
      : _t1 = null,
        _which = 2;

  @override
  int get hashCode => map(lspHashCode, lspHashCode);

  @override
  bool operator ==(other) =>
      other is Either2<T1, T2> &&
      lspEquals(other._t1, _t1) &&
      lspEquals(other._t2, _t2);

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    return _which == 1 ? f1(_t1 as T1) : f2(_t2 as T2);
  }

  @override
  Object? toJson() => map(specToJson, specToJson);

  @override
  String toString() => map((t) => t.toString(), (t) => t.toString());

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) => map((t) => t == o, (t) => t == o);
}

class Either3<T1, T2, T3> implements ToJsonable {
  final int _which;
  final T1? _t1;
  final T2? _t2;
  final T3? _t3;

  Either3.t1(this._t1)
      : _t2 = null,
        _t3 = null,
        _which = 1;

  Either3.t2(this._t2)
      : _t1 = null,
        _t3 = null,
        _which = 2;

  Either3.t3(this._t3)
      : _t1 = null,
        _t2 = null,
        _which = 3;

  @override
  int get hashCode => map(lspHashCode, lspHashCode, lspHashCode);

  @override
  bool operator ==(other) =>
      other is Either3<T1, T2, T3> &&
      lspEquals(other._t1, _t1) &&
      lspEquals(other._t2, _t2) &&
      lspEquals(other._t3, _t3);

  T map<T>(T Function(T1) f1, T Function(T2) f2, T Function(T3) f3) {
    return switch (_which) {
      1 => f1(_t1 as T1),
      2 => f2(_t2 as T2),
      3 => f3(_t3 as T3),
      _ => throw 'Invalid state.'
    };
  }

  @override
  Object? toJson() => map(specToJson, specToJson, specToJson);

  @override
  String toString() => map(
        (t) => t.toString(),
        (t) => t.toString(),
        (t) => t.toString(),
      );

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) => map((t) => t == o, (t) => t == o, (t) => t == o);
}

class Either4<T1, T2, T3, T4> implements ToJsonable {
  final int _which;
  final T1? _t1;
  final T2? _t2;
  final T3? _t3;
  final T4? _t4;

  Either4.t1(this._t1)
      : _t2 = null,
        _t3 = null,
        _t4 = null,
        _which = 1;

  Either4.t2(this._t2)
      : _t1 = null,
        _t3 = null,
        _t4 = null,
        _which = 2;

  Either4.t3(this._t3)
      : _t1 = null,
        _t2 = null,
        _t4 = null,
        _which = 3;

  Either4.t4(this._t4)
      : _t1 = null,
        _t2 = null,
        _t3 = null,
        _which = 4;

  @override
  int get hashCode => map(lspHashCode, lspHashCode, lspHashCode, lspHashCode);

  @override
  bool operator ==(other) =>
      other is Either4<T1, T2, T3, T4> &&
      lspEquals(other._t1, _t1) &&
      lspEquals(other._t2, _t2) &&
      lspEquals(other._t3, _t3) &&
      lspEquals(other._t4, _t4);

  T map<T>(T Function(T1) f1, T Function(T2) f2, T Function(T3) f3,
      T Function(T4) f4) {
    return switch (_which) {
      1 => f1(_t1 as T1),
      2 => f2(_t2 as T2),
      3 => f3(_t3 as T3),
      4 => f4(_t4 as T4),
      _ => throw 'Invalid state.'
    };
  }

  @override
  Object? toJson() => map(specToJson, specToJson, specToJson, specToJson);

  @override
  String toString() => map(
        (t) => t.toString(),
        (t) => t.toString(),
        (t) => t.toString(),
        (t) => t.toString(),
      );

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) =>
      map((t) => t == o, (t) => t == o, (t) => t == o, (t) => t == o);
}

/// A helper to allow handlers to declare both a JSON validation function and
/// parse function.
class LspJsonHandler<T> {
  final bool Function(Map<String, Object?>?, LspJsonReporter reporter)
      validateParams;
  final T Function(Map<String, Object?>) convertParams;

  const LspJsonHandler(this.validateParams, this.convertParams);
}

abstract class ToJsonable {
  Object? toJson();
}

extension IncomingMessageExtension on IncomingMessage {
  /// Returns the amount of time (in milliseconds) since the client sent this
  /// request or `null` if the client did not provide [clientRequestTime].
  int? get timeSinceRequest {
    var clientRequestTime = this.clientRequestTime;
    return clientRequestTime != null
        ? DateTime.now().millisecondsSinceEpoch - clientRequestTime
        : null;
  }
}
