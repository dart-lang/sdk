// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Object id(Object obj) => obj;

Object specToJson(Object obj) {
  if (obj is ToJsonable) {
    return obj.toJson();
  } else {
    return obj;
  }
}

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
  get hashCode => map((t) => t.hashCode, (t) => t.hashCode);

  bool operator ==(o) => o is Either2<T1, T2> && o._t1 == _t1 && o._t2 == _t2;

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    return _which == 1 ? f1(_t1) : f2(_t2);
  }

  Object toJson() => map(specToJson, specToJson);

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
  get hashCode => map((t) => t.hashCode, (t) => t.hashCode, (t) => t.hashCode);

  bool operator ==(o) =>
      o is Either3<T1, T2, T3> && o._t1 == _t1 && o._t2 == _t2 && o._t3 == _t3;

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
  get hashCode => map((t) => t.hashCode, (t) => t.hashCode, (t) => t.hashCode,
      (t) => t.hashCode);

  bool operator ==(o) =>
      o is Either4<T1, T2, T3, T4> &&
      o._t1 == _t1 &&
      o._t2 == _t2 &&
      o._t3 == _t3 &&
      o._t4 == _t4;

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

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) =>
      map((t) => t == o, (t) => t == o, (t) => t == o, (t) => t == o);
}

class FileOperation {}

abstract class ToJsonable {
  Object toJson();
}

/// A base class containing the fields common to RequestMessage and
/// NotificationMessage to simplify handling.
abstract class IncomingMessage {
  String get method;
  Either2<List<dynamic>, dynamic> get params;
}

abstract class ServerErrorCodes {
  // JSON-RPC reserves -32000 to -32099 for implementation-defined server-errors.
  static const ServerAlreadyStarted = -32000;
  static const UnhandledError = -32001;
  static const ServerAlreadyInitialized = -32002;
}
