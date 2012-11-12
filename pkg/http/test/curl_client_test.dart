// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library curl_client_test;

import 'dart:io';
import 'dart:isolate';
import 'dart:uri';

import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import '../lib/src/utils.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);

  test('head', () {
    expect(new http.CurlClient().head(serverUrl).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, equals(''));
    }), completes);
  });

  test('get', () {
    expect(new http.CurlClient().get(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'GET',
        'path': '/',
        'headers': {
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        },
      })));
    }), completes);
  });

  test('post', () {
    expect(new http.CurlClient().post(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }, fields: {
      'some-field': 'value',
      'other-field': 'other value'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'POST',
        'path': '/',
        'headers': {
          'content-type': [
            'application/x-www-form-urlencoded; charset=UTF-8'
          ],
          'content-length': ['42'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        },
        'body': 'some-field=value&other-field=other%20value'
      })));
    }), completes);
  });

  test('post without fields', () {
    expect(new http.CurlClient().post(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value',
      'Content-Type': 'text/plain'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'POST',
        'path': '/',
        'headers': {
          'content-type': ['text/plain'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        }
      })));
    }), completes);
  });

  test('put', () {
    expect(new http.CurlClient().put(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }, fields: {
      'some-field': 'value',
      'other-field': 'other value'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'PUT',
        'path': '/',
        'headers': {
          'content-type': [
            'application/x-www-form-urlencoded; charset=UTF-8'
          ],
          'content-length': ['42'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        },
        'body': 'some-field=value&other-field=other%20value'
      })));
    }), completes);
  });

  test('put without fields', () {
    expect(new http.CurlClient().put(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value',
      'Content-Type': 'text/plain'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'PUT',
        'path': '/',
        'headers': {
          'content-type': ['text/plain'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        }
      })));
    }), completes);
  });

  test('delete', () {
    expect(new http.CurlClient().delete(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'DELETE',
        'path': '/',
        'headers': {
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        }
      })));
    }), completes);
  });

  test('read', () {
    expect(new http.CurlClient().read(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }), completion(parse(equals({
      'method': 'GET',
      'path': '/',
      'headers': {
        'x-random-header': ['Value'],
        'x-other-header': ['Other Value']
      },
    }))));
  });

  test('read throws an error for a 4** status code', () {
    expect(new http.CurlClient().read(serverUrl.resolve('/error')),
        throwsHttpException);
  });

  test('readBytes', () {
    var future = new http.CurlClient().readBytes(serverUrl, headers: {
      'X-Random-Header': 'Value',
      'X-Other-Header': 'Other Value'
    }).transform((bytes) => new String.fromCharCodes(bytes));

    expect(future, completion(parse(equals({
      'method': 'GET',
      'path': '/',
      'headers': {
        'x-random-header': ['Value'],
        'x-other-header': ['Other Value']
      },
    }))));
  });

  test('readBytes throws an error for a 4** status code', () {
    expect(new http.CurlClient().readBytes(serverUrl.resolve('/error')),
        throwsHttpException);
  });

  test('#send a StreamedRequest', () {
    var client = new http.CurlClient();
    var request = new http.StreamedRequest("POST", serverUrl);
    request.headers[HttpHeaders.CONTENT_TYPE] =
      'application/json; charset=utf-8';

    var future = client.send(request).chain((response) {
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

  test('with one redirect', () {
    var url = serverUrl.resolve('/redirect');
    expect(new http.CurlClient().get(url).transform((response) {
      expect(response.statusCode, equals(200));
      expect(response.body, parse(equals({
        'method': 'GET',
        'path': '/',
        'headers': {}
      })));
    }), completes);
  });

  test('with too many redirects', () {
    expect(new http.CurlClient().get(serverUrl.resolve('/loop?1')),
        throwsRedirectLimitExceededException);
  });

  test('with a generic failure', () {
    expect(new http.CurlClient().get('url fail'),
        throwsHttpException);
  });

  test('with one redirect via HEAD', () {
    var url = serverUrl.resolve('/redirect');
    expect(new http.CurlClient().head(url).transform((response) {
      expect(response.statusCode, equals(200));
    }), completes);
  });

  test('with too many redirects via HEAD', () {
    expect(new http.CurlClient().head(serverUrl.resolve('/loop?1')),
        throwsRedirectLimitExceededException);
  });

  test('with a generic failure via HEAD', () {
    expect(new http.CurlClient().head('url fail'),
        throwsHttpException);
  });

  test('without following redirects', () {
    var request = new http.Request('GET', serverUrl.resolve('/redirect'));
    request.followRedirects = false;
    expect(new http.CurlClient().send(request).chain(http.Response.fromStream)
        .transform((response) {
      expect(response.statusCode, equals(302));
      expect(response.isRedirect, true);
    }), completes);
  });
}
