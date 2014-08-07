library http_base.http_base_io_test;

import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http_base/http_base_io.dart';
import 'package:unittest/unittest.dart';

main() {
  test('io-client', () {
    HttpServer.bind('127.0.0.1', 0).then(expectAsync((HttpServer server) {
      server.first.then(expectAsync((request) {
        expect(request.method, equals('POST'));
        expect(request.headers.value('foo'), equals('bar'));

        return request.fold([], (buf, data) => buf..addAll(data)).then((data) {
          request
              ..response.statusCode = 201
              ..response.headers.set('foo', ['foo', 'bar'])
              ..response.add(data)
              ..response.close();
        });
      })).whenComplete(() => server.close());

      var client = new Client();
      var uri = Uri.parse('http://127.0.0.1:${server.port}/');
      var headers = new HeadersImpl({'foo' : 'bar'});
      var body = (new StreamController()
          ..add(UTF8.encode('my-data'))
          ..close()).stream;

      var request = new RequestImpl('POST', uri, headers: headers, body: body);
      client(request).then(expectAsync((response) {
        expect(response.statusCode, equals(201));
        // NOTE: dart:io joins multiple values with ", ".
        expect(response.headers['foo'], equals('foo, bar'));
        expect(response.headers.getMultiple('foo').toList(),
               equals(['foo','bar']));

        response.read()
            .transform(UTF8.decoder).join('').then(expectAsync((data) {
          expect(data, equals('my-data'));
        }));
      }));
    }));
  });
}
