// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_test;

import 'dart:io';

import 'package:unittest/unittest.dart';
import 'package:http/http.dart' as http;
import 'utils.dart';

main() {
  group('http.', () {
    setUp(startServer);
    tearDown(stopServer);

    test('head', () {
      expect(http.head(serverUrl).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, equals(''));
      }), completes);
    });

    test('get', () {
      expect(http.get(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'GET',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          },
        })));
      }), completes);
    });

    test('post', () {
      expect(http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }, fields: {
        'some-field': 'value',
        'other-field': 'other value'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'POST',
          'path': '/',
          'headers': {
            'content-type': [
              'application/x-www-form-urlencoded; charset=UTF-8'
            ],
            'content-length': ['40'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          },
          'body': 'some-field=value&other-field=other+value'
        })));
      }), completes);
    });

    test('post without fields', () {
      expect(http.post(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'POST',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'content-type': ['text/plain'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          }
        })));
      }), completes);
    });

    test('put', () {
      expect(http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }, fields: {
        'some-field': 'value',
        'other-field': 'other value'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'PUT',
          'path': '/',
          'headers': {
            'content-type': [
              'application/x-www-form-urlencoded; charset=UTF-8'
            ],
            'content-length': ['40'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          },
          'body': 'some-field=value&other-field=other+value'
        })));
      }), completes);
    });

    test('put without fields', () {
      expect(http.put(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value',
        'Content-Type': 'text/plain'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'PUT',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'content-type': ['text/plain'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          }
        })));
      }), completes);
    });

    test('delete', () {
      expect(http.delete(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }).then((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, parse(equals({
          'method': 'DELETE',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          }
        })));
      }), completes);
    });

    test('read', () {
      expect(http.read(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }).then((val) => val), completion(parse(equals({
        'method': 'GET',
        'path': '/',
        'headers': {
          'content-length': ['0'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        },
      }))));
    });

    test('read throws an error for a 4** status code', () {
      expect(http.read(serverUrl.resolve('/error')), throwsHttpException);
    });

    test('readBytes', () {
      var future = http.readBytes(serverUrl, headers: {
        'X-Random-Header': 'Value',
        'X-Other-Header': 'Other Value'
      }).then((bytes) => new String.fromCharCodes(bytes));

      expect(future, completion(parse(equals({
        'method': 'GET',
        'path': '/',
        'headers': {
          'content-length': ['0'],
          'x-random-header': ['Value'],
          'x-other-header': ['Other Value']
        },
      }))));
    });

    test('readBytes throws an error for a 4** status code', () {
      expect(http.readBytes(serverUrl.resolve('/error')), throwsHttpException);
    });
  });
}
