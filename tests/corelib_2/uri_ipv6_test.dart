// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void testValidIpv6Uri() {
  var path = 'http://[::1]:1234/path?query=5#now';
  var uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('::1', uri.host);
  Expect.equals(1234, uri.port);
  Expect.equals('/path', uri.path);
  Expect.equals('query=5', uri.query);
  Expect.equals('now', uri.fragment);
  Expect.equals(path, uri.toString());

  path = 'http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:8080/index.html';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('fedc:ba98:7654:3210:fedc:ba98:7654:3210', uri.host);
  Expect.equals(8080, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals(path.toLowerCase(), uri.toString());

  path = 'http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/index.html';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('fedc:ba98:7654:3210:fedc:ba98:7654:3210', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('http://[fedc:ba98:7654:3210:fedc:ba98:7654:3210]/index.html',
      uri.toString());

  path = 'https://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fedc:ba98:7654:3210:fedc:ba98:7654:3210', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[fedc:ba98:7654:3210:fedc:ba98:7654:3210]/index.html',
      uri.toString());

  path = 'http://[1080:0:0:0:8:800:200C:417A]/index.html';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('1080:0:0:0:8:800:200c:417a', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals(path.toLowerCase(), uri.toString());

  path = 'http://[3ffe:2a00:100:7031::1]';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('3ffe:2a00:100:7031::1', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('', uri.path);
  Expect.equals(path, uri.toString());

  path = 'http://[1080::8:800:200C:417A]/foo';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('1080::8:800:200c:417a', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('/foo', uri.path);
  Expect.equals(path.toLowerCase(), uri.toString());

  path = 'http://[::192.9.5.5]/ipng';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('::192.9.5.5', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('/ipng', uri.path);
  Expect.equals(path, uri.toString());

  path = 'http://[::FFFF:129.144.52.38]:8080/index.html';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('::ffff:129.144.52.38', uri.host);
  Expect.equals(8080, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals(path.toLowerCase(), uri.toString());

  path = 'http://[::FFFF:129.144.52.38]:80/index.html';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('::ffff:129.144.52.38', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('http://[::ffff:129.144.52.38]/index.html', uri.toString());

  path = 'https://[::FFFF:129.144.52.38]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('::ffff:129.144.52.38', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[::ffff:129.144.52.38]/index.html', uri.toString());

  path = 'http://[2010:836B:4179::836B:4179]';
  uri = Uri.parse(path);
  Expect.equals('http', uri.scheme);
  Expect.equals('2010:836b:4179::836b:4179', uri.host);
  Expect.equals(80, uri.port);
  Expect.equals('', uri.path);
  Expect.equals(path.toLowerCase(), uri.toString());
}

void testParseIPv6Address() {
  void pass(String host, List<int> expected) {
    Expect.listEquals(expected, Uri.parseIPv6Address(host));
  }

  void fail(String host) {
    Expect.throwsFormatException(() => Uri.parseIPv6Address(host));
  }

  pass('::127.0.0.1', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 127, 0, 0, 1]);
  pass('0::127.0.0.1', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 127, 0, 0, 1]);
  pass('::', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  pass('0::', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
  fail(':0::127.0.0.1');
  fail('0:::');
  fail(':::');
  fail('::0:');
  fail('::0::');
  fail('::0::0');
  fail('00000::0');
  fail('-1::0');
  fail('-AAA::0');
  fail('0::127.0.0.1:0');
  fail('0::127.0.0');
  pass('0::1111', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 17]);
  pass('2010:836B:4179::836B:4179',
      [32, 16, 131, 107, 65, 121, 0, 0, 0, 0, 0, 0, 131, 107, 65, 121]);
  fail('2010:836B:4179:0000:127.0.0.1');
  fail('2010:836B:4179:0000:0000:127.0.0.1');
  fail('2010:836B:4179:0000:0000:0000::127.0.0.1');
  fail('2010:836B:4179:0000:0000:0000:0000:127.0.0.1');
  pass('2010:836B:4179:0000:0000:0000:127.0.0.1',
      [32, 16, 131, 107, 65, 121, 0, 0, 0, 0, 0, 0, 127, 0, 0, 1]);
}

void main() {
  testValidIpv6Uri();
  testParseIPv6Address();
}
