// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';
import 'dart:io';


Future<int> getStatusCode(int port,
                          String path,
                          {String host,
                           bool secure: false,
                           DateTime ifModifiedSince,
                           bool rawPath: false}) {
  var uri;
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
        if (host != null) request.headers.host = host;
        if (ifModifiedSince != null) {
          request.headers.ifModifiedSince = ifModifiedSince;
        }
        return request.close();
      })
      .then((response) => response.drain().then(
          (_) => response.statusCode));
}


Future<HttpHeaders> getHeaders(int port, String path) {
  return new HttpClient().get('localhost', port, path)
      .then((request) => request.close())
      .then((response) => response.drain().then(
          (_) => response.headers));
}


Future<String> getAsString(int port, String path) {
  return new HttpClient().get('localhost', port, path)
      .then((request) => request.close())
      .then((response) => StringDecoder.decode(response));
}


const CERTIFICATE = "localhost_cert";


setupSecure() {
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart');
}
