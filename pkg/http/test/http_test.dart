// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_test;

import 'dart:io';

import '../../unittest/lib/unittest.dart';
import '../lib/http.dart' as http;
import 'utils.dart';

main() {
  group('http.', () {
    setUp(startServer);
    tearDown(stopServer);

    test('head', () {
      expect(http.head(serverUrl).transform((response) {
        expect(response.statusCode, equals(200));
        expect(response.body, equals(''));
      }), completes);
    });

    test('get', () {
      expect(http.get(serverUrl, headers: {
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
      expect(http.post(serverUrl, headers: {
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
      expect(http.post(serverUrl, headers: {
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
      expect(http.put(serverUrl, headers: {
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
      expect(http.put(serverUrl, headers: {
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
      expect(http.delete(serverUrl, headers: {
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
      expect(http.read(serverUrl, headers: {
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
      expect(http.read(serverUrl.resolve('/error')), throwsHttpException);
    });

    test('readBytes', () {
      var future = http.readBytes(serverUrl, headers: {
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
      expect(http.readBytes(serverUrl.resolve('/error')), throwsHttpException);
    });
  });
}
