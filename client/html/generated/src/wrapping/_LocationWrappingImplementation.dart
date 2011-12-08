// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class LocationWrappingImplementation extends DOMWrapperBase implements Location {
  LocationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get hash() { return _ptr.hash; }

  void set hash(String value) { _ptr.hash = value; }

  String get host() { return _ptr.host; }

  void set host(String value) { _ptr.host = value; }

  String get hostname() { return _ptr.hostname; }

  void set hostname(String value) { _ptr.hostname = value; }

  String get href() { return _ptr.href; }

  void set href(String value) { _ptr.href = value; }

  String get origin() { return _ptr.origin; }

  String get pathname() { return _ptr.pathname; }

  void set pathname(String value) { _ptr.pathname = value; }

  String get port() { return _ptr.port; }

  void set port(String value) { _ptr.port = value; }

  String get protocol() { return _ptr.protocol; }

  void set protocol(String value) { _ptr.protocol = value; }

  String get search() { return _ptr.search; }

  void set search(String value) { _ptr.search = value; }

  void assign(String url) {
    _ptr.assign(url);
    return;
  }

  String getParameter(String name) {
    return _ptr.getParameter(name);
  }

  void reload() {
    _ptr.reload();
    return;
  }

  void replace(String url) {
    _ptr.replace(url);
    return;
  }

  String toString() {
    return _ptr.toString();
  }
}
