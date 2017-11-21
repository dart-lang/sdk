// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';
import 'helpers/lax_json.dart';

void main() {
  test('primitives', () {
    expect(decode('true'), equals(true));
    expect(decode(' true'), equals(true));
    expect(decode('true '), equals(true));
    expect(decode('true// '), equals(true));
    expect(decode('// \ntrue'), equals(true));
    expect(decode('\ttrue\r'), equals(true));
    expect(decode('\t\ntrue\r\n'), equals(true));
    expect(decode('true/* */'), equals(true));
    expect(decode('/* */true'), equals(true));
    expect(decode('/* false */true '), equals(true));

    expect(decode('false'), equals(false));
    expect(decode('null'), equals(null));
  });

  test('string', () {
    expect(decode('"foo"'), equals("foo"));
    expect(decode('"foo bar baz"'), equals("foo bar baz"));
    expect(decode(r'"\""'), equals(r'"'));
    expect(decode(r'"\\"'), equals(r'\'));
    expect(decode(r'"\/"'), equals('/'));
    expect(decode(r'"\b"'), equals('\b'));
    expect(decode(r'"\f"'), equals('\f'));
    expect(decode(r'"\r"'), equals('\r'));
    expect(decode(r'"\n"'), equals('\n'));
    expect(decode(r'"\t"'), equals('\t'));
    expect(decode(r'"\t\"\\\/\f\nfoo\r\t"'), equals('\t\"\\/\f\nfoo\r\t'));
  });

  test('list', () {
    expect(decode('[]'), equals([]));
    expect(decode('[\n]'), equals([]));
    expect(decode('["foo"]'), equals(['foo']));
    expect(decode('["foo",]'), equals(['foo']));
    expect(decode('["foo", "bar", true, \nnull\n,false,]'),
        equals(['foo', 'bar', true, null, false]));
  });

  test('map', () {
    expect(decode('{}'), equals({}));
    expect(decode('{\n}'), equals({}));
    expect(decode('{"foo":"bar"}'), equals({'foo': 'bar'}));
    expect(decode('{"foo":"bar",}'), equals({'foo': 'bar'}));
    expect(
        decode('{"foo":true, "bar": false, "baz": true, '
            '"boz": \nnull\n,"qux": false,}'),
        equals({
          'foo': true,
          'bar': false,
          'baz': true,
          'boz': null,
          'qux': false
        }));
  });
}
