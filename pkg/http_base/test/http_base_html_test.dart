library http_base.http_base_html_test;

import 'dart:html';
import 'dart:async';
import 'dart:convert';

import 'package:http_base/http_base_html.dart';
import 'package:unittest/unittest.dart';

main() {
  test('http-client', () {
    var uri = Uri.parse(window.location.href).resolve('/echo');

    var client = new Client();
    var body = (new StreamController()
        ..add(UTF8.encode('my-data'))
        ..close()).stream;
    var request = new RequestImpl('POST', uri, body: body);
    client(request).then(expectAsync((response) {
      expect(response.statusCode, equals(200));
      response.read()
          .transform(UTF8.decoder).join('').then(expectAsync((data) {
        expect(data, equals('my-data'));
      }));
    }));
  });
}
