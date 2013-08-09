// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client_test;

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  tearDown(stopServer);

  test('#send a StreamedRequest', () {
    expect(startServer().then((_) {
      var client = new http.Client();
      var request = new http.StreamedRequest("POST", serverUrl);
      request.headers[HttpHeaders.CONTENT_TYPE] =
        'application/json; charset=utf-8';
      request.headers[HttpHeaders.USER_AGENT] = 'Dart';

      expect(client.send(request).then((response) {
        expect(response.request, equals(request));
        expect(response.statusCode, equals(200));
        expect(response.headers['single'], equals('value'));
        // dart:io internally normalizes outgoing headers so that they never
        // have multiple headers with the same name, so there's no way to test
        // whether we handle that case correctly.

        return response.stream.bytesToString();
      }).whenComplete(client.close), completion(parse(equals({
        'method': 'POST',
        'path': '/',
        'headers': {
          'content-type': ['application/json; charset=utf-8'],
          'accept-encoding': ['gzip'],
          'user-agent': ['Dart'],
          'transfer-encoding': ['chunked']
        },
        'body': '{"hello": "world"}'
      }))));

      request.sink.add('{"hello": "world"}'.codeUnits);
      request.sink.close();
    }), completes);
  });

  test('#send with an invalid URL', () {
    expect(startServer().then((_) {
      var client = new http.Client();
      var url = Uri.parse('http://http.invalid');
      var request = new http.StreamedRequest("POST", url);
      request.headers[HttpHeaders.CONTENT_TYPE] =
          'application/json; charset=utf-8';

      expect(client.send(request), throwsSocketException);

      request.sink.add('{"hello": "world"}'.codeUnits);
      request.sink.close();
    }), completes);
  });
}
