// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _LocationWrappingImplementation extends DOMWrapperBase implements Location {
  _LocationWrappingImplementation() : super() {}

  static create__LocationWrappingImplementation() native {
    return new _LocationWrappingImplementation();
  }

  String get hash() { return _get_hash(this); }
  static String _get_hash(var _this) native;

  void set hash(String value) { _set_hash(this, value); }
  static void _set_hash(var _this, String value) native;

  String get host() { return _get_host(this); }
  static String _get_host(var _this) native;

  void set host(String value) { _set_host(this, value); }
  static void _set_host(var _this, String value) native;

  String get hostname() { return _get_hostname(this); }
  static String _get_hostname(var _this) native;

  void set hostname(String value) { _set_hostname(this, value); }
  static void _set_hostname(var _this, String value) native;

  String get href() { return _get_href(this); }
  static String _get_href(var _this) native;

  void set href(String value) { _set_href(this, value); }
  static void _set_href(var _this, String value) native;

  String get origin() { return _get_origin(this); }
  static String _get_origin(var _this) native;

  String get pathname() { return _get_pathname(this); }
  static String _get_pathname(var _this) native;

  void set pathname(String value) { _set_pathname(this, value); }
  static void _set_pathname(var _this, String value) native;

  String get port() { return _get_port(this); }
  static String _get_port(var _this) native;

  void set port(String value) { _set_port(this, value); }
  static void _set_port(var _this, String value) native;

  String get protocol() { return _get_protocol(this); }
  static String _get_protocol(var _this) native;

  void set protocol(String value) { _set_protocol(this, value); }
  static void _set_protocol(var _this, String value) native;

  String get search() { return _get_search(this); }
  static String _get_search(var _this) native;

  void set search(String value) { _set_search(this, value); }
  static void _set_search(var _this, String value) native;

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

  String toString() {
    return _toString(this);
  }
  static String _toString(receiver) native;

  String get typeName() { return "Location"; }
}
