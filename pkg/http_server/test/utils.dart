// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import "package:unittest/unittest.dart";

import 'package:http_server/http_server.dart';

void testVirtualDir(String name, Future func(Directory dir)) {
  test(name, () {
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
  return _withServer((server) {

      virtualDir.serve(server);
      return getStatusCode(server.port, path, host: host, secure: secure,
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
  Uri uri;
  if (rawPath) {
    uri = new Uri(scheme: secure ? 'https' : 'http',
                  host: 'localhost',
                  port: port,
                  path: path);
  } else {
    uri = (secure ?
        new Uri.https('localhost:$port', path) :
        new Uri.http('localhost:$port', path));
  }

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
  return _withServer((server) {
      virDir.serve(server);

      return new HttpClient()
          .get('localhost', server.port, path)
          .then((request) => request.close())
          .then((response) => response.drain().then((_) => response.headers));
    });
}

Future<String> getAsString(VirtualDirectory virtualDir, String path) {
  return _withServer((server) {
      virtualDir.serve(server);

      return new HttpClient()
          .get('localhost', server.port, path)
          .then((request) => request.close())
          .then((response) => UTF8.decodeStream(response));
    });
}

Future _withServer(Future func(HttpServer server)) {
  HttpServer server;
  return HttpServer.bind('localhost', 0)
      .then((value) {
        server = value;
        return func(server);
      })
      .whenComplete(() => server.close());
}


const CERTIFICATE = "localhost_cert";


void setupSecure() {
  String certificateDatabase = Platform.script.resolve('pkcert').toFilePath();
  SecureSocket.initialize(database: certificateDatabase,
                          password: 'dartdart');
}
