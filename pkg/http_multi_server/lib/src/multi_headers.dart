// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_multi_server.multi_headers;

import 'dart:io';

/// A class that delegates header access and setting to many [HttpHeaders]
/// instances.
class MultiHeaders implements HttpHeaders {
  /// The wrapped headers.
  final Set<HttpHeaders> _headers;

  bool get chunkedTransferEncoding => _headers.first.chunkedTransferEncoding;
  set chunkedTransferEncoding(bool value) {
    for (var headers in _headers) {
      headers.chunkedTransferEncoding = value;
    }
  }

  int get contentLength => _headers.first.contentLength;
  set contentLength(int value) {
    for (var headers in _headers) {
      headers.contentLength = value;
    }
  }

  ContentType get contentType => _headers.first.contentType;
  set contentType(ContentType value) {
    for (var headers in _headers) {
      headers.contentType = value;
    }
  }

  DateTime get date => _headers.first.date;
  set date(DateTime value) {
    for (var headers in _headers) {
      headers.date = value;
    }
  }

  DateTime get expires => _headers.first.expires;
  set expires(DateTime value) {
    for (var headers in _headers) {
      headers.expires = value;
    }
  }

  String get host => _headers.first.host;
  set host(String value) {
    for (var headers in _headers) {
      headers.host = value;
    }
  }

  DateTime get ifModifiedSince => _headers.first.ifModifiedSince;
  set ifModifiedSince(DateTime value) {
    for (var headers in _headers) {
      headers.ifModifiedSince = value;
    }
  }

  bool get persistentConnection => _headers.first.persistentConnection;
  set persistentConnection(bool value) {
    for (var headers in _headers) {
      headers.persistentConnection = value;
    }
  }

  int get port => _headers.first.port;
  set port(int value) {
    for (var headers in _headers) {
      headers.port = value;
    }
  }

  MultiHeaders(Iterable<HttpHeaders> headers)
      : _headers = headers.toSet();

  void add(String name, Object value) {
    for (var headers in _headers) {
      headers.add(name, value);
    }
  }

  void forEach(void f(String name, List<String> values)) =>
      _headers.first.forEach(f);

  void noFolding(String name) {
    for (var headers in _headers) {
      headers.noFolding(name);
    }
  }

  void remove(String name, Object value) {
    for (var headers in _headers) {
      headers.remove(name, value);
    }
  }

  void removeAll(String name) {
    for (var headers in _headers) {
      headers.removeAll(name);
    }
  }

  void set(String name, Object value) {
    for (var headers in _headers) {
      headers.set(name, value);
    }
  }

  String value(String name) => _headers.first.value(name);

  List<String> operator[](String name) => _headers.first[name];

  void clear() {
    for (var headers in _headers) {
      headers.clear();
    }
  }
}
