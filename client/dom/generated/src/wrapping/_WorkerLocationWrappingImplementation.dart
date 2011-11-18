// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WorkerLocationWrappingImplementation extends DOMWrapperBase implements WorkerLocation {
  _WorkerLocationWrappingImplementation() : super() {}

  static create__WorkerLocationWrappingImplementation() native {
    return new _WorkerLocationWrappingImplementation();
  }

  String get hash() { return _get_hash(this); }
  static String _get_hash(var _this) native;

  String get host() { return _get_host(this); }
  static String _get_host(var _this) native;

  String get hostname() { return _get_hostname(this); }
  static String _get_hostname(var _this) native;

  String get href() { return _get_href(this); }
  static String _get_href(var _this) native;

  String get pathname() { return _get_pathname(this); }
  static String _get_pathname(var _this) native;

  String get port() { return _get_port(this); }
  static String _get_port(var _this) native;

  String get protocol() { return _get_protocol(this); }
  static String _get_protocol(var _this) native;

  String get search() { return _get_search(this); }
  static String _get_search(var _this) native;

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "WorkerLocation"; }
}
