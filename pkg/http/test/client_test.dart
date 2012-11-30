// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client_test;

import 'dart:io';

import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import '../lib/src/utils.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);

  test('#send a StreamedRequest', () {
    var client = new http.Client();
    var request = new http.StreamedRequest("POST", serverUrl);
    request.headers[HttpHeaders.CONTENT_TYPE] =
      'application/json; charset=utf-8';

    var future = client.send(request).chain((response) {
      expect(response.request, equals(request));
      expect(response.statusCode, equals(200));
      return consumeInputStream(response.stream);
    }).transform((bytes) => new String.fromCharCodes(bytes));
    future.onComplete((_) => client.close());

    expect(future, completion(parse(equals({
      'method': 'POST',
      'path': '/',
      'headers': {
        'content-type': ['application/json; charset=utf-8'],
        'transfer-encoding': ['chunked']
      },
      'body': '{"hello": "world"}'
    }))));

    request.stream.writeString('{"hello": "world"}');
    request.stream.close();
  });
}
