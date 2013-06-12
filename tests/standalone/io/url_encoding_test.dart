// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:utf";

part '../../../sdk/lib/io/common.dart';
part '../../../sdk/lib/io/io_sink.dart';
part "../../../sdk/lib/io/http.dart";
part "../../../sdk/lib/io/http_impl.dart";
part "../../../sdk/lib/io/http_parser.dart";
part "../../../sdk/lib/io/http_utils.dart";
part "../../../sdk/lib/io/socket.dart";
part "../../../sdk/lib/io/string_transformer.dart";

void testParseEncodedString() {
  String encodedString = 'foo+bar%20foobar%25%26';
  Expect.equals(_HttpUtils.decodeUrlEncodedString(encodedString),
                'foo bar foobar%&');
  encodedString = 'A+%2B+B';
  Expect.equals(_HttpUtils.decodeUrlEncodedString(encodedString),
                'A + B');
}

void testParseQueryString() {
  test(String queryString, Map<String, String> expected) {
    Map<String, String> map = _HttpUtils.splitQueryString(queryString);
    for (String key in map.keys) {
      Expect.equals(expected[key], map[key]);
    }
    Expect.setEquals(expected.keys.toSet(), map.keys.toSet());
  }

  // The query string includes escaped "?"s, "&"s, "%"s and "="s.
  // These should not affect the splitting of the string.
  test('%3F=%3D&foo=bar&%26=%25&sqrt2=%E2%88%9A2&name=Franti%C5%A1ek',
       { '&'     : '%',
         'foo'   : 'bar',
         '?'     : '=',
         'sqrt2' : '\u221A2',
         'name'  : 'Franti\u0161ek'});

  // Same query string with ; as separator.
  test('%3F=%3D;foo=bar;%26=%25;sqrt2=%E2%88%9A2;name=Franti%C5%A1ek',
       { '&'     : '%',
         'foo'   : 'bar',
         '?'     : '=',
         'sqrt2' : '\u221A2',
         'name'  : 'Franti\u0161ek'});

  // Same query string with alternating ; and & separators.
  test('%3F=%3D&foo=bar;%26=%25&sqrt2=%E2%88%9A2;name=Franti%C5%A1ek',
       { '&'     : '%',
         'foo'   : 'bar',
         '?'     : '=',
         'sqrt2' : '\u221A2',
         'name'  : 'Franti\u0161ek'});
  test('%3F=%3D;foo=bar&%26=%25;sqrt2=%E2%88%9A2&name=Franti%C5%A1ek',
       { '&'     : '%',
         'foo'   : 'bar',
         '?'     : '=',
         'sqrt2' : '\u221A2',
         'name'  : 'Franti\u0161ek'});

  // Corner case tests.
  test('', { });
  test('&', { });
  test(';', { });
  test('&;', { });
  test(';&', { });
  test('&&&&', { });
  test(';;;;', { });
  test('a', { 'a' : '' });
  test('&a&', { 'a' : '' });
  test(';a;', { 'a' : '' });
  test('a=', { 'a' : '' });
  test('a=&', { 'a' : '' });
  test('a=;', { 'a' : '' });
  test('a=&b', { 'a' : '', 'b' : '' });
  test('a=;b', { 'a' : '', 'b' : '' });
  test('a=&b', { 'a' : '', 'b' : '' });
  test('a=&b=', { 'a' : '', 'b' : '' });

  // These are not really a legal query string.
  test('=', { });
  test('=x', { });
  test('a==&b===', { 'a' : '=', 'b' : '==' });
}

void main() {
  testParseEncodedString();
  testParseQueryString();
}
