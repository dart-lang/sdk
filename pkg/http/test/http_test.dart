// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http_test;

import 'package:http/http.dart' as http;
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  group('http.', () {
    tearDown(stopServer);

    test('head', () {
      expect(startServer().then((_) {
        expect(http.head(serverUrl).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, equals(''));
        }), completes);
      }), completes);
    });

    test('get', () {
      expect(startServer().then((_) {
        expect(http.get(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'GET',
            'path': '/',
            'headers': {
              'content-length': ['0'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
          })));
        }), completes);
      }), completes);
    });

    test('post', () {
      expect(startServer().then((_) {
        expect(http.post(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'Content-Type': 'text/plain',
          'User-Agent': 'Dart'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
        }), completes);
      }), completes);
    });

    test('post with string', () {
      expect(startServer().then((_) {
        expect(http.post(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: 'request body').then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
        }), completes);
      }), completes);
    });

    test('post with bytes', () {
      expect(startServer().then((_) {
        expect(http.post(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: [104, 101, 108, 108, 111]).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
        }), completes);
      }), completes);
    });

    test('post with fields', () {
      expect(startServer().then((_) {
        expect(http.post(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: {
          'some-field': 'value',
          'other-field': 'other value'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'POST',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
        }), completes);
      }), completes);
    });

    test('put', () {
      expect(startServer().then((_) {
        expect(http.put(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'Content-Type': 'text/plain',
          'User-Agent': 'Dart'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'accept-encoding': ['gzip'],
              'content-length': ['0'],
              'content-type': ['text/plain'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
        }), completes);
      }), completes);
    });

    test('put with string', () {
      expect(startServer().then((_) {
        expect(http.put(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: 'request body').then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': ['text/plain; charset=utf-8'],
              'content-length': ['12'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'request body'
          })));
        }), completes);
      }), completes);
    });

    test('put with bytes', () {
      expect(startServer().then((_) {
        expect(http.put(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: [104, 101, 108, 108, 111]).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-length': ['5'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': [104, 101, 108, 108, 111]
          })));
        }), completes);
      }), completes);
    });

    test('put with fields', () {
      expect(startServer().then((_) {
        expect(http.put(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }, body: {
          'some-field': 'value',
          'other-field': 'other value'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'PUT',
            'path': '/',
            'headers': {
              'content-type': [
                'application/x-www-form-urlencoded; charset=utf-8'
              ],
              'content-length': ['40'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            },
            'body': 'some-field=value&other-field=other+value'
          })));
        }), completes);
      }), completes);
    });

    test('delete', () {
      expect(startServer().then((_) {
        expect(http.delete(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }).then((response) {
          expect(response.statusCode, equals(200));
          expect(response.body, parse(equals({
            'method': 'DELETE',
            'path': '/',
            'headers': {
              'content-length': ['0'],
              'accept-encoding': ['gzip'],
              'user-agent': ['Dart'],
              'x-random-header': ['Value'],
              'x-other-header': ['Other Value']
            }
          })));
        }), completes);
      }), completes);
    });

    test('read', () {
      expect(startServer().then((_) {
        expect(http.read(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }).then((val) => val), completion(parse(equals({
          'method': 'GET',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'accept-encoding': ['gzip'],
            'user-agent': ['Dart'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          },
        }))));
      }), completes);
    });

    test('read throws an error for a 4** status code', () {
      expect(startServer().then((_) {
        expect(http.read(serverUrl.resolve('/error')), throwsHttpException);
      }), completes);
    });

    test('readBytes', () {
      expect(startServer().then((_) {
        var future = http.readBytes(serverUrl, headers: {
          'X-Random-Header': 'Value',
          'X-Other-Header': 'Other Value',
          'User-Agent': 'Dart'
        }).then((bytes) => new String.fromCharCodes(bytes));

        expect(future, completion(parse(equals({
          'method': 'GET',
          'path': '/',
          'headers': {
            'content-length': ['0'],
            'accept-encoding': ['gzip'],
            'user-agent': ['Dart'],
            'x-random-header': ['Value'],
            'x-other-header': ['Other Value']
          },
        }))));
      }), completes);
    });

    test('readBytes throws an error for a 4** status code', () {
      expect(startServer().then((_) {
        expect(http.readBytes(serverUrl.resolve('/error')), throwsHttpException);
      }), completes);
    });
  });
}
