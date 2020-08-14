// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/json_parsing.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonRpcVersion = '2.0';

const NullJsonHandler = LspJsonHandler<Null>(_alwaysTrue, _alwaysNull);

ErrorOr<R> cancelled<R>([R t]) =>
    error(ErrorCodes.RequestCancelled, 'Request was cancelled', null);

ErrorOr<R> error<R>(ErrorCodes code, String message, [String data]) =>
    ErrorOr<R>.error(ResponseError(code: code, message: message, data: data));

ErrorOr<R> failure<R>(ErrorOr<dynamic> error) => ErrorOr<R>.error(error.error);

/// Returns if two objects are equal, recursively checking items in
/// Maps/Lists.
bool lspEquals(dynamic obj1, dynamic obj2) {
  if (obj1 is List && obj2 is List) {
    return listEqual(obj1, obj2, lspEquals);
  } else if (obj1 is Map && obj2 is Map) {
    return mapEqual(obj1, obj2, lspEquals);
  } else {
    return obj1.runtimeType == obj2.runtimeType && obj1 == obj2;
  }
}

/// Returns an objects hash code, recursively combining hashes for items in
/// Maps/Lists.
int lspHashCode(dynamic obj) {
  var hash = 0;
  if (obj is List) {
    for (var element in obj) {
      hash = JenkinsSmiHash.combine(hash, lspHashCode(element));
    }
  } else if (obj is Map) {
    for (var key in obj.keys) {
      hash = JenkinsSmiHash.combine(hash, lspHashCode(key));
      hash = JenkinsSmiHash.combine(hash, lspHashCode(obj[key]));
    }
  } else {
    hash = obj.hashCode;
  }
  return JenkinsSmiHash.finish(hash);
}

Object specToJson(Object obj) {
  if (obj is ToJsonable) {
    return obj.toJson();
  } else {
    return obj;
  }
}

ErrorOr<R> success<R>([R t]) => ErrorOr<R>.success(t);

Null _alwaysNull(_, [__]) => null;

bool _alwaysTrue(_, [__]) => true;

class Either2<T1, T2> {
  final int _which;
  final T1 _t1;
  final T2 _t2;

  Either2.t1(this._t1)
      : _t2 = null,
        _which = 1;
  Either2.t2(this._t2)
      : _t1 = null,
        _which = 2;

  @override
  int get hashCode => map(lspHashCode, lspHashCode);

  @override
  bool operator ==(o) =>
      o is Either2<T1, T2> && lspEquals(o._t1, _t1) && lspEquals(o._t2, _t2);

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    return _which == 1 ? f1(_t1) : f2(_t2);
  }

  Object toJson() => map(specToJson, specToJson);

  @override
  String toString() => map((t) => t.toString(), (t) => t.toString());

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) => map((t) => t == o, (t) => t == o);
}

class Either3<T1, T2, T3> {
  final int _which;
  final T1 _t1;
  final T2 _t2;
  final T3 _t3;

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
  bool operator ==(o) =>
      o is Either3<T1, T2, T3> &&
      lspEquals(o._t1, _t1) &&
      lspEquals(o._t2, _t2) &&
      lspEquals(o._t3, _t3);

  T map<T>(T Function(T1) f1, T Function(T2) f2, T Function(T3) f3) {
    switch (_which) {
      case 1:
        return f1(_t1);
      case 2:
        return f2(_t2);
      case 3:
        return f3(_t3);
      default:
        throw 'Invalid state.';
    }
  }

  Object toJson() => map(specToJson, specToJson, specToJson);

  @override
  String toString() => map(
        (t) => t.toString(),
        (t) => t.toString(),
        (t) => t.toString(),
      );

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) => map((t) => t == o, (t) => t == o, (t) => t == o);
}

class Either4<T1, T2, T3, T4> {
  final int _which;
  final T1 _t1;
  final T2 _t2;
  final T3 _t3;
  final T4 _t4;

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
  bool operator ==(o) =>
      o is Either4<T1, T2, T3, T4> &&
      lspEquals(o._t1, _t1) &&
      lspEquals(o._t2, _t2) &&
      lspEquals(o._t3, _t3) &&
      lspEquals(o._t4, _t4);

  T map<T>(T Function(T1) f1, T Function(T2) f2, T Function(T3) f3,
      T Function(T4) f4) {
    switch (_which) {
      case 1:
        return f1(_t1);
      case 2:
        return f2(_t2);
      case 3:
        return f3(_t3);
      case 4:
        return f4(_t4);
      default:
        throw 'Invalid state.';
    }
  }

  Object toJson() => map(specToJson, specToJson, specToJson, specToJson);

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

class ErrorOr<T> extends Either2<ResponseError, T> {
  ErrorOr.error(ResponseError error) : super.t1(error);
  ErrorOr.success([T result]) : super.t2(result);

  /// Returns the error or throws if object is not an error. Check [isError]
  /// before accessing [error].
  ResponseError get error {
    return _which == 1 ? _t1 : (throw 'Value is not an error');
  }

  /// Returns true if this object is an error, false if it is a result. Prefer
  /// [mapResult] instead of checking this flag if [errors] will simply be
  /// propagated as-is.
  bool get isError => _which == 1;

  /// Returns the result or throws if this object is an error. Check [isError]
  /// before accessing [result]. It is valid for this to return null is the
  /// object does not represent an error but the resulting value was null.
  T get result {
    return _which == 2 ? _t2 : (throw 'Value is not a result');
  }

  /// If this object is a result, maps [result] through [f], otherwise returns
  /// a new error object representing [error].
  FutureOr<ErrorOr<N>> mapResult<N>(FutureOr<ErrorOr<N>> Function(T) f) {
    return isError
        // Re-wrap the error using our new type arg
        ? ErrorOr<N>.error(error)
        // Otherwise call the map function
        : f(result);
  }
}

/// A base class containing the fields common to RequestMessage and
/// NotificationMessage to simplify handling.
abstract class IncomingMessage {
  Method get method;
  dynamic get params;
}

/// A helper to allow handlers to declare both a JSON validation function and
/// parse function.
class LspJsonHandler<T> {
  final bool Function(Map<String, Object>, LspJsonReporter reporter)
      validateParams;
  final T Function(Map<String, Object>) convertParams;

  const LspJsonHandler(this.validateParams, this.convertParams);
}

abstract class ToJsonable {
  Object toJson();
}
