// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http.test.io.request_test;

import 'package:http/http.dart' as http;
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test('.send', () {
    expect(startServer().then((_) {

      var request = new http.Request('POST', serverUrl);
      request.body = "hello";
      request.headers['User-Agent'] = 'Dart';

      expect(request.send().then((response) {
        expect(response.statusCode, equals(200));
        return response.stream.bytesToString();
      }).whenComplete(stopServer), completion(parse(equals({
        'method': 'POST',
        'path': '/',
        'headers': {
          'content-type': ['text/plain; charset=utf-8'],
          'accept-encoding': ['gzip'],
          'user-agent': ['Dart'],
          'content-length': ['5']
        },
        'body': 'hello'
      }))));
    }), completes);
  });

  test('#followRedirects', () {
    expect(startServer().then((_) {
      var request = new http.Request('POST', serverUrl.resolve('/redirect'))
          ..followRedirects = false;
      var future = request.send().then((response) {
        expect(response.statusCode, equals(302));
      });
      expect(future.catchError((_) {}).then((_) => stopServer()), completes);
      expect(future, completes);
    }), completes);
  });

  test('#maxRedirects', () {
    expect(startServer().then((_) {
      var request = new http.Request('POST', serverUrl.resolve('/loop?1'))
        ..maxRedirects = 2;
      var future = request.send().catchError((error) {
        expect(error, isRedirectLimitExceededException);
        expect(error.redirects.length, equals(2));
      });
      expect(future.catchError((_) {}).then((_) => stopServer()), completes);
      expect(future, completes);
    }), completes);
  });
}
