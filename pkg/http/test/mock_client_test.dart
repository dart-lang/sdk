// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_client_test;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

// TODO(nweiz): make these "package:" imports.
import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import '../lib/testing.dart';
import '../lib/src/utils.dart';
import 'utils.dart';

void main() {
  test('handles a request', () {
    var client = new MockClient((request) {
      return new Future.immediate(new http.Response(
          JSON.stringify(request.bodyFields), 200,
          headers: {'content-type': 'application/json'}));
    });

    expect(client.post("http://example.com/foo", fields: {
      'field1': 'value1',
      'field2': 'value2'
    }).transform((response) => response.body), completion(parse(equals({
      'field1': 'value1',
      'field2': 'value2'
    }))));
  });

  test('handles a streamed request', () {
    var client = new MockClient.streaming((request, bodyStream) {
      return consumeInputStream(bodyStream).transform((body) {
        var stream = new ListInputStream();
        async.then((_) {
          var bodyString = new String.fromCharCodes(body);
          stream.write('Request body was "$bodyString"'.charCodes);
          stream.markEndOfStream();
        });

        return new http.StreamedResponse(stream, 200, -1);
      });
    });

    var uri = new Uri.fromString("http://example.com/foo");
    var request = new http.Request("POST", uri);
    request.body = "hello, world";
    var future = client.send(request)
        .chain(http.Response.fromStream)
        .transform((response) => response.body);
    expect(future, completion(equals('Request body was "hello, world"')));
  });
}
