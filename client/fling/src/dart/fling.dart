// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fling {
  static void goForth() native;
  static void refresh() native;
  static String getInstallPath() native;
}


typedef void HttpRequestHandler(HttpRequest req, HttpResponse res);


class HttpResponse {
  HttpResponse._internal() {}
  void finish() native;
  void flush() native;
  void setHeader(String name, String value) native;
  void setStatusCode(int code) native;
  void write(String data) native;
  static HttpResponse _create() native {
    return new HttpResponse._internal();
  }
}


class HttpRequest {
  HttpRequest._internal() {}
  static HttpRequest _create() native {
    return new HttpRequest._internal();
  }
  String get body() native;
  bool get isKeepAlive() native;
  String get method() native;
  String get requestedPath() native;
  String get version() native;
  String get prefix() native;
}


class HttpServer {
  HttpServer() {
    _init();
  }
  void handle(String path, HttpRequestHandler handler) native;
  void listen(int port) native;
  void _init() native;
}


class ClientApp {
  ClientApp(String path, List<String> staticApps = null) {
    _init(path, staticApps);
  }

  static HttpRequestHandler create(String path, List<String> staticApps = null) {
    return new ClientApp(path, staticApps).handler;
  }

  HttpRequestHandler get handler() {
    return ((HttpRequest req, HttpResponse res) { return _handle(req, res); });
  }

  void _handle(HttpRequest req, HttpResponse res) native;
  void _init(String path, List<String> staticApps) native;
}
