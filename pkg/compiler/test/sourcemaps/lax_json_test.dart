// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'helpers/lax_json.dart';

void main() {
  // Primitives.
  Expect.isTrue(decode('true'));
  Expect.isTrue(decode(' true'));
  Expect.isTrue(decode('true '));
  Expect.isTrue(decode('true// '));
  Expect.isTrue(decode('// \ntrue'));
  Expect.isTrue(decode('\ttrue\r'));
  Expect.isTrue(decode('\t\ntrue\r\n'));
  Expect.isTrue(decode('true/* */'));
  Expect.isTrue(decode('/* */true'));
  Expect.isTrue(decode('/* false */true '));

  Expect.isFalse(decode('false'));
  Expect.isNull(decode('null'));

  // Strings.
  Expect.equals(decode('"foo"'), "foo");
  Expect.equals(decode('"foo bar baz"'), "foo bar baz");
  Expect.equals(decode(r'"\""'), r'"');
  Expect.equals(decode(r'"\\"'), r'\');
  Expect.equals(decode(r'"\/"'), '/');
  Expect.equals(decode(r'"\b"'), '\b');
  Expect.equals(decode(r'"\f"'), '\f');
  Expect.equals(decode(r'"\r"'), '\r');
  Expect.equals(decode(r'"\n"'), '\n');
  Expect.equals(decode(r'"\t"'), '\t');
  Expect.equals(decode(r'"\t\"\\\/\f\nfoo\r\t"'), '\t\"\\/\f\nfoo\r\t');

  // Lists.
  Expect.listEquals(decode('[]'), []);
  Expect.listEquals(decode('[\n]'), []);
  Expect.listEquals(decode('["foo"]'), ['foo']);
  Expect.listEquals(decode('["foo",]'), ['foo']);
  Expect.listEquals(decode('["foo", "bar", true, \nnull\n,false,]'),
      ['foo', 'bar', true, null, false]);

  // Maps.
  Expect.mapEquals(decode('{}'), {});
  Expect.mapEquals(decode('{\n}'), {});
  Expect.mapEquals(decode('{"foo":"bar"}'), {'foo': 'bar'});
  Expect.mapEquals(decode('{"foo":"bar",}'), {'foo': 'bar'});
  Expect.mapEquals(
      decode('{"foo":true, "bar": false, "baz": true, '
          '"boz": \nnull\n,"qux": false,}'),
      {'foo': true, 'bar': false, 'baz': true, 'boz': null, 'qux': false});
}
