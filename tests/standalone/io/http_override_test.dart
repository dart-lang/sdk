// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

class MyHttpClient1 implements HttpClient {
  String userAgent = "MyHttpClient1";

  MyHttpClient1(SecurityContext context);

  Duration idleTimeout;
  int maxConnectionsPerHost;
  bool autoUncompress;

  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      null;
  Future<HttpClientRequest> openUrl(String method, Uri url) => null;
  Future<HttpClientRequest> get(String host, int port, String path) => null;
  Future<HttpClientRequest> getUrl(Uri url) => null;
  Future<HttpClientRequest> post(String host, int port, String path) => null;
  Future<HttpClientRequest> postUrl(Uri url) => null;
  Future<HttpClientRequest> put(String host, int port, String path) => null;
  Future<HttpClientRequest> putUrl(Uri url) => null;
  Future<HttpClientRequest> delete(String host, int port, String path) => null;
  Future<HttpClientRequest> deleteUrl(Uri url) => null;
  Future<HttpClientRequest> patch(String host, int port, String path) => null;
  Future<HttpClientRequest> patchUrl(Uri url) => null;
  Future<HttpClientRequest> head(String host, int port, String path) => null;
  Future<HttpClientRequest> headUrl(Uri url) => null;
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)) {}
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  set findProxy(String f(Uri url)) {}
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)) {}
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)) {}
  void close({bool force: false}) {}
}

class MyHttpClient2 implements HttpClient {
  String userAgent = "MyHttpClient2";

  MyHttpClient2(SecurityContext context);

  Duration idleTimeout;
  int maxConnectionsPerHost;
  bool autoUncompress;

  Future<HttpClientRequest> open(
          String method, String host, int port, String path) =>
      null;
  Future<HttpClientRequest> openUrl(String method, Uri url) => null;
  Future<HttpClientRequest> get(String host, int port, String path) => null;
  Future<HttpClientRequest> getUrl(Uri url) => null;
  Future<HttpClientRequest> post(String host, int port, String path) => null;
  Future<HttpClientRequest> postUrl(Uri url) => null;
  Future<HttpClientRequest> put(String host, int port, String path) => null;
  Future<HttpClientRequest> putUrl(Uri url) => null;
  Future<HttpClientRequest> delete(String host, int port, String path) => null;
  Future<HttpClientRequest> deleteUrl(Uri url) => null;
  Future<HttpClientRequest> patch(String host, int port, String path) => null;
  Future<HttpClientRequest> patchUrl(Uri url) => null;
  Future<HttpClientRequest> head(String host, int port, String path) => null;
  Future<HttpClientRequest> headUrl(Uri url) => null;
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)) {}
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  set findProxy(String f(Uri url)) {}
  set authenticateProxy(
      Future<bool> f(String host, int port, String scheme, String realm)) {}
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  set badCertificateCallback(
      bool callback(X509Certificate cert, String host, int port)) {}
  void close({bool force: false}) {}
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return new MyHttpClient1(context);
  }
}

HttpClient myCreateHttp1Client(SecurityContext context) {
  return new MyHttpClient1(context);
}

HttpClient myCreateHttp2Client(SecurityContext context) {
  return new MyHttpClient2(context);
}

String myFindProxyFromEnvironment(Uri url, Map<String, String> environment) {
  return "proxy";
}

withHttpOverridesTest() {
  HttpOverrides.runZoned(() {
    var httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
  }, createHttpClient: myCreateHttp1Client);
  var httpClient = new HttpClient();
  Expect.isTrue(httpClient is HttpClient);
  Expect.isTrue(httpClient is! MyHttpClient1);
}

nestedWithHttpOverridesTest() {
  HttpOverrides.runZoned(() {
    var httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
    HttpOverrides.runZoned(() {
      var httpClient = new HttpClient();
      Expect.isNotNull(httpClient);
      Expect.isTrue(httpClient is MyHttpClient2);
      Expect.equals((new MyHttpClient2(null)).userAgent, httpClient.userAgent);
    }, createHttpClient: myCreateHttp2Client);
    httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
  }, createHttpClient: myCreateHttp1Client);
  var httpClient = new HttpClient();
  Expect.isTrue(httpClient is HttpClient);
  Expect.isTrue(httpClient is! MyHttpClient1);
  Expect.isTrue(httpClient is! MyHttpClient2);
}

nestedDifferentOverridesTest() {
  HttpOverrides.runZoned(() {
    var httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
    HttpOverrides.runZoned(() {
      var httpClient = new HttpClient();
      Expect.isNotNull(httpClient);
      Expect.isTrue(httpClient is MyHttpClient1);
      Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
      Expect.equals(myFindProxyFromEnvironment(null, null),
          HttpClient.findProxyFromEnvironment(null));
    }, findProxyFromEnvironment: myFindProxyFromEnvironment);
    httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
  }, createHttpClient: myCreateHttp1Client);
  var httpClient = new HttpClient();
  Expect.isTrue(httpClient is HttpClient);
  Expect.isTrue(httpClient is! MyHttpClient1);
  Expect.isTrue(httpClient is! MyHttpClient2);
}

zonedWithHttpOverridesTest() {
  HttpOverrides.runWithHttpOverrides(() {
    var httpClient = new HttpClient();
    Expect.isNotNull(httpClient);
    Expect.isTrue(httpClient is MyHttpClient1);
    Expect.equals((new MyHttpClient1(null)).userAgent, httpClient.userAgent);
  }, new MyHttpOverrides());
}

main() {
  withHttpOverridesTest();
  nestedWithHttpOverridesTest();
  nestedDifferentOverridesTest();
  zonedWithHttpOverridesTest();
}
