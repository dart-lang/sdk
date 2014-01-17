// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import "package:unittest/unittest.dart";

import 'package:http_server/http_server.dart';

import 'http_mock.dart';

/**
 *  Used to flag a given test case as being a mock or not.
 */
final _isMockTestExpando = new Expando<bool>('isMockTest');

void testVirtualDir(String name, Future func(Directory dir)) {
  _testVirtualDir(name, false, func);
  _testVirtualDir(name, true, func);
}

void _testVirtualDir(String name, bool useMocks, Future func(Directory dir)) {
  if(useMocks) {
    name = '$name, with mocks';
  }

  test(name, () {
    // see subsequent access to this expando below
    _isMockTestExpando[currentTestCase] = useMocks;

    var dir = Directory.systemTemp.createTempSync('http_server_virtual_');

    return func(dir)
        .whenComplete(() {
          return dir.delete(recursive: true);
        });
  });
}

Future<int> getStatusCodeForVirtDir(VirtualDirectory virtualDir,
                           String path,
                          {String host,
                           bool secure: false,
                           DateTime ifModifiedSince,
                           bool rawPath: false,
                           bool followRedirects: true}) {

  // if this is a mock test, then run the mock code path
  if(_isMockTestExpando[currentTestCase]) {
    var uri = _getUri(0, path, secure: secure, rawPath: rawPath);

    var request = new MockHttpRequest(uri, followRedirects: followRedirects,
        ifModifiedSince: ifModifiedSince);

    return _withMockRequest(virtualDir, request)
        .then((response) {
          return response.statusCode;
        });
  };

  assert(_isMockTestExpando[currentTestCase] == false);

  return _withServer(virtualDir, (port) {
    return getStatusCode(port, path, host: host, secure: secure,
          ifModifiedSince: ifModifiedSince, rawPath: rawPath,
          followRedirects: followRedirects);
  });
}

Future<int> getStatusCode(int port,
                          String path,
                          {String host,
                           bool secure: false,
                           DateTime ifModifiedSince,
                           bool rawPath: false,
                           bool followRedirects: true}) {
  var uri = _getUri(port, path, secure: secure, rawPath: rawPath);

  return new HttpClient().getUrl(uri)
      .then((request) {
        if (!followRedirects) request.followRedirects = false;
        if (host != null) request.headers.host = host;
        if (ifModifiedSince != null) {
          request.headers.ifModifiedSince = ifModifiedSince;
        }
        return request.close();
      })
      .then((response) => response.drain().then(
          (_) => response.statusCode));
}

Future<HttpHeaders> getHeaders(VirtualDirectory virDir, String path) {

  // if this is a mock test, then run the mock code path
  if(_isMockTestExpando[currentTestCase]) {
    var uri = _getUri(0, path);

    var request = new MockHttpRequest(uri);

    return _withMockRequest(virDir, request)
        .then((response) {
          return response.headers;
        });
  }

  assert(_isMockTestExpando[currentTestCase] == false);

  return _withServer(virDir, (port) {
      return _getHeaders(port, path);
    });
}

Future<String> getAsString(VirtualDirectory virtualDir, String path) {

  // if this is a mock test, then run the mock code path
  if(_isMockTestExpando[currentTestCase]) {
    var uri = _getUri(0, path);

    var request = new MockHttpRequest(uri);

    return _withMockRequest(virtualDir, request)
        .then((response) {
          return response.mockContent;
        });
  };

  assert(_isMockTestExpando[currentTestCase] == false);

  return _withServer(virtualDir, (int port) {
      return _getAsString(port, path);
    });
}

Future<MockHttpResponse> _withMockRequest(VirtualDirectory virDir,
    MockHttpRequest request) {
    return virDir.serveRequest(request).then((value) {
      expect(value, isNull);
      expect(request.response.mockDone, isTrue);
      return request.response;
    })
    .then((HttpResponse response) {
      if(response.statusCode == HttpStatus.MOVED_PERMANENTLY ||
          response.statusCode == HttpStatus.MOVED_TEMPORARILY) {
        if(request.followRedirects == true) {
          var uri = Uri.parse(response.headers.value(HttpHeaders.LOCATION));
          var newMock = new MockHttpRequest(uri, followRedirects: true);

          return _withMockRequest(virDir, newMock);
        }
      }
      return response;
    });
}

Future _withServer(VirtualDirectory virDir, Future func(int port)) {
  HttpServer server;
  return HttpServer.bind('localhost', 0)
      .then((value) {
        server = value;
        virDir.serve(server);
        return func(server.port);
      })
      .whenComplete(() => server.close());
}

Future<HttpHeaders> _getHeaders(int port, String path) =>
    new HttpClient()
      .get('localhost', port, path)
      .then((request) => request.close())
      .then((response) => response.drain().then(
          (_) => response.headers));

Future<String> _getAsString(int port, String path) =>
    new HttpClient()
      .get('localhost', port, path)
      .then((request) => request.close())
      .then((response) => UTF8.decodeStream(response));

Uri _getUri(int port,
            String path,
           {bool secure: false,
            bool rawPath: false}) {
  if (rawPath) {
    return new Uri(scheme: secure ? 'https' : 'http',
                  host: 'localhost',
                  port: port,
                  path: path);
  } else {
    return (secure ?
        new Uri.https('localhost:$port', path) :
        new Uri.http('localhost:$port', path));
  }
}

const CERTIFICATE = "localhost_cert";


void setupSecure() {
  String certificateDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart');
}
