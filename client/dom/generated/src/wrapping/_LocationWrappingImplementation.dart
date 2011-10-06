// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _LocationWrappingImplementation extends DOMWrapperBase implements Location {
  _LocationWrappingImplementation() : super() {}

  static create__LocationWrappingImplementation() native {
    return new _LocationWrappingImplementation();
  }

  String get hash() { return _get__Location_hash(this); }
  static String _get__Location_hash(var _this) native;

  void set hash(String value) { _set__Location_hash(this, value); }
  static void _set__Location_hash(var _this, String value) native;

  String get host() { return _get__Location_host(this); }
  static String _get__Location_host(var _this) native;

  void set host(String value) { _set__Location_host(this, value); }
  static void _set__Location_host(var _this, String value) native;

  String get hostname() { return _get__Location_hostname(this); }
  static String _get__Location_hostname(var _this) native;

  void set hostname(String value) { _set__Location_hostname(this, value); }
  static void _set__Location_hostname(var _this, String value) native;

  String get href() { return _get__Location_href(this); }
  static String _get__Location_href(var _this) native;

  void set href(String value) { _set__Location_href(this, value); }
  static void _set__Location_href(var _this, String value) native;

  String get origin() { return _get__Location_origin(this); }
  static String _get__Location_origin(var _this) native;

  String get pathname() { return _get__Location_pathname(this); }
  static String _get__Location_pathname(var _this) native;

  void set pathname(String value) { _set__Location_pathname(this, value); }
  static void _set__Location_pathname(var _this, String value) native;

  String get port() { return _get__Location_port(this); }
  static String _get__Location_port(var _this) native;

  void set port(String value) { _set__Location_port(this, value); }
  static void _set__Location_port(var _this, String value) native;

  String get protocol() { return _get__Location_protocol(this); }
  static String _get__Location_protocol(var _this) native;

  void set protocol(String value) { _set__Location_protocol(this, value); }
  static void _set__Location_protocol(var _this, String value) native;

  String get search() { return _get__Location_search(this); }
  static String _get__Location_search(var _this) native;

  void set search(String value) { _set__Location_search(this, value); }
  static void _set__Location_search(var _this, String value) native;

  void assign(String url) {
    _assign(this, url);
    return;
  }
  static void _assign(receiver, url) native;

  String getParameter(String name) {
    return _getParameter(this, name);
  }
  static String _getParameter(receiver, name) native;

  void reload() {
    _reload(this);
    return;
  }
  static void _reload(receiver) native;

  void replace(String url) {
    _replace(this, url);
    return;
  }
  static void _replace(receiver, url) native;

  String get typeName() { return "Location"; }
}
