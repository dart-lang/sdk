// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import("dart:utf");
#source("../../../runtime/bin/input_stream.dart");
#source("../../../runtime/bin/output_stream.dart");
#source("../../../runtime/bin/chunked_stream.dart");
#source("../../../runtime/bin/string_stream.dart");
#source("../../../runtime/bin/stream_util.dart");
#source("../../../runtime/bin/http.dart");
#source("../../../runtime/bin/http_impl.dart");
#source("../../../runtime/bin/http_parser.dart");
#source("../../../runtime/bin/http_utils.dart");

void testParseEncodedString() {
  String encodedString = 'foo+bar%20foobar%25%26';
  Expect.equals(_HttpUtils.decodeUrlEncodedString(encodedString),
                'foo bar foobar%&');
}

void testParseQueryString() {
  // The query string includes escaped "?"s, "&"s, "%"s and "="s.
  // These should not affect the splitting of the string.
  String queryString =
      '%3F=%3D&foo=bar&%26=%25&sqrt2=%E2%88%9A2&name=Franti%C5%A1ek';
  Map<String, String> map = _HttpUtils.splitQueryString(queryString);
  for (String key in map.keys) {
    Expect.equals(map[key], { '&'     : '%',
                              'foo'   : 'bar',
                              '?'     : '=',
                              'sqrt2' : '\u221A2',
                              'name'  : 'Franti\u0161ek'}[key]);
  }
  Expect.setEquals(map.keys, ['&', '?', 'foo', 'sqrt2', 'name']);
}

void main() {
  testParseEncodedString();
  testParseQueryString();
}
