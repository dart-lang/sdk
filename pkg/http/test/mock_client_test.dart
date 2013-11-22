// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock_client_test;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/src/utils.dart';
import 'package:http/testing.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test('handles a request', () {
    var client = new MockClient((request) {
      return new Future.value(new http.Response(
          JSON.encode(request.bodyFields), 200,
          request: request, headers: {'content-type': 'application/json'}));
    });

    expect(client.post("http://example.com/foo", body: {
      'field1': 'value1',
      'field2': 'value2'
    }).then((response) => response.body), completion(parse(equals({
      'field1': 'value1',
      'field2': 'value2'
    }))));
  });

  test('handles a streamed request', () {
    var client = new MockClient.streaming((request, bodyStream) {
      return bodyStream.bytesToString().then((bodyString) {
        var controller = new StreamController<List<int>>(sync: true);
        async.then((_) {
          controller.add('Request body was "$bodyString"'.codeUnits);
          controller.close();
        });

        return new http.StreamedResponse(controller.stream, 200, -1);
      });
    });

    var uri = Uri.parse("http://example.com/foo");
    var request = new http.Request("POST", uri);
    request.body = "hello, world";
    var future = client.send(request)
        .then(http.Response.fromStream)
        .then((response) => response.body);
    expect(future, completion(equals('Request body was "hello, world"')));
  });

  test('handles a request with no body', () {
    var client = new MockClient((request) {
      return new Future.value(new http.Response('you did it', 200));
    });

    expect(client.read("http://example.com/foo"),
        completion(equals('you did it')));
  });
}
