// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'uri_ipv4_test.dart' as ipv4 show passSamples, failSamples;

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
  Expect.equals(
    'http://[fedc:ba98:7654:3210:fedc:ba98:7654:3210]/index.html',
    uri.toString(),
  );

  path = 'https://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fedc:ba98:7654:3210:fedc:ba98:7654:3210', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals(
    'https://[fedc:ba98:7654:3210:fedc:ba98:7654:3210]/index.html',
    uri.toString(),
  );

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

  // Checks for ZoneID in RFC 6874
  path = 'https://[fe80::a%en1]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fe80::a%25en1', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[fe80::a%25en1]/index.html', uri.toString());

  path = 'https://[fe80::a%25eE1]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fe80::a%25eE1', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[fe80::a%25eE1]/index.html', uri.toString());

  // Recognize bare '%' and transform into '%25'
  path = 'https://[fe80::a%1]:443/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fe80::a%251', uri.host);
  Expect.equals(443, uri.port);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[fe80::a%251]/index.html', uri.toString());

  path = 'https://[ff02::5678%pvc1.3]/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('ff02::5678%25pvc1.3', uri.host);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[ff02::5678%25pvc1.3]/index.html', uri.toString());

  // ZoneID contains percent encoded
  path = 'https://[ff02::1%%321]/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('ff02::1%2521', uri.host);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[ff02::1%2521]/index.html', uri.toString());

  path = 'https://[ff02::1%321]/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('ff02::1%25321', uri.host);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[ff02::1%25321]/index.html', uri.toString());

  // Lower cases
  path = 'https://[ff02::1%1%41]/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('ff02::1%251a', uri.host);
  Expect.equals('/index.html', uri.path);
  Expect.equals('https://[ff02::1%251a]/index.html', uri.toString());

  path = 'https://[fe80::8eae:4c4d:fee9:8434%rename3]/index.html';
  uri = Uri.parse(path);
  Expect.equals('https', uri.scheme);
  Expect.equals('fe80::8eae:4c4d:fee9:8434%25rename3', uri.host);
  Expect.equals('/index.html', uri.path);
  Expect.equals(
    'https://[fe80::8eae:4c4d:fee9:8434%25rename3]/index.html',
    uri.toString(),
  );

  // Test constructors with host name
  uri = Uri(scheme: 'https', host: '[ff02::5678%pvc1.3]');
  uri = Uri(scheme: 'https', host: '[fe80::a%1]');
  uri = Uri(scheme: 'https', host: '[fe80::a%25eE1]');
  uri = Uri(scheme: 'https', host: '[fe80::a%en1]');
}

void testParseIPv6Address() {
  for (var i = 0; i < passSamples.length; i++) {
    var sample = passSamples[i];
    passIPv6(sample.host, sample.out);
  }

  for (var i = 0; i < failSamples.length; i++) {
    var sample = failSamples[i];
    failIPv6(sample);
  }

  for (var i = 0; i < ipv4.passSamples.length; i++) {
    var sample = ipv4.passSamples[i];
    var host = sample.host;
    passIPv4inIPv6(host, sample.out);

    // Invalid positions of valid IPv4.
    // IPv4 alone.
    failIPv6(host);
    // IPv4 first.
    failIPv6('$host:3:4:5:6:7:8');
    failIPv6('$host::8');
    // IPv4 in the middle.
    failIPv6('1:2:3:$host:6:7:8:');
    failIPv6('::3:$host:6:7:8:');
    failIPv6('1:2:3:$host:6::');
    // Too long with IPv4.
    failIPv6('1:2:3:4:5:6:7::$host');
    failIPv6('::1:2:3:4:5:6:$host');
    failIPv6('1:2:3:4::5:6:$host');
    failIPv6('1:2:3:4:5:6::$host');
    // Too short with IPv4 and no wildcard.
    failIPv6('1:2:3:4:5:$host');
    failIPv6('1:$host');
    // Too short or long with IPv4, longer parts.
    failIPv6('2010:836B:4179:0000:$host');
    failIPv6('2010:836B:4179:0000:0000:$host');
    failIPv6('2010:836B:4179:0000:0000:0000::$host');
    failIPv6('2010:836B:4179:0000:0000:0000:0000:$host');
  }

  for (var i = 0; i < ipv4.failSamples.length; i++) {
    var sample = ipv4.failSamples[i];
    // Avoid anything that would be valid as non-IPv4 after a `::`.
    // Heuristically that's "nothing" or hex digits.
    if (sample.isEmpty ||
        (sample.trim() == sample && int.tryParse(sample, radix: 16) != null)) {
      continue;
    }
    failIPv4inIPv6(sample);
  }
}

void failIPv6(String host) {
  void failWrap(String prefix, String suffix) {
    var wrapped = "$prefix$host$suffix";
    var start = prefix.length;
    var end = start + host.length;
    Expect.throwsFormatException(
      () => Uri.parseIPv6Address(wrapped, start, end),
      wrapped,
    );
  }

  failWrap('', '');
  failWrap('xyz', '');
  failWrap('', 'xyz');
  failWrap('0', '0');
  failWrap(':', ':');
  failWrap('::', '::');
  failWrap('0:', ':0');
  failWrap('', '.0');
  failWrap('', '.0.0.0.0');
}

void passIPv4inIPv6(String ipv4Host, List<int> ipv4Bytes) {
  // No wildcard.
  passIPv6('1234:5678:9abc:def0:8765:4321:$ipv4Host', [
    0x12,
    0x34,
    0x56,
    0x78,
    0x9a,
    0xbc,
    0xde,
    0xf0,
    0x87,
    0x65,
    0x43,
    0x21,
    ...ipv4Bytes,
  ]);
  // Wildcards.
  passIPv6('::$ipv4Host', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...ipv4Bytes]);
  passIPv6('0::$ipv4Host', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...ipv4Bytes]);
  passIPv6('::0:$ipv4Host', [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, ...ipv4Bytes]);
  passIPv6('0000::FFFF:$ipv4Host', [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0xFF,
    0xFF,
    ...ipv4Bytes,
  ]);
}

void failIPv4inIPv6(String ipv4Host) {
  failIPv6('::$ipv4Host');
  failIPv6('0::$ipv4Host');
  failIPv6('::0:$ipv4Host');
  failIPv6('::FFFF:$ipv4Host');
  failIPv6('1234:5678:9abc:def0:8765:4321:$ipv4Host');
}

const ____ = 0; // Used to represent wildcard fills below.
/// Samples containing IPv4 are generated from [ipv4.passSamples].
const List<({String host, List<int> out})> passSamples = [
  // Upper and lower case both allowed.
  (
    host: 'abcd:efAB:CDEF:aBcD:eFAb:CdEf:aAaA:bBbB',
    out: [
      0xab, 0xcd, 0xef, 0xab, 0xcd, 0xef, 0xab, 0xcd, //
      0xef, 0xab, 0xcd, 0xef, 0xaa, 0xaa, 0xbb, 0xbb,
    ],
  ),
  // 1-4 digits allowed, leading zeros allowed.
  (
    host: 'a:bc:def:1234:0a:00b:000c:0de',
    out: [
      0x00, 0x0a, 0x00, 0xbc, 0x0d, 0xef, 0x12, 0x34, //
      0x00, 0x0a, 0x00, 0x0b, 0x00, 0x0c, 0x00, 0xde,
    ],
  ),
  //
  // Wildcard positions and sizes.
  // No wildcard.
  (
    host: '1223:3445:5667:7889:9aab:bccd:deef:f001',
    out: [
      0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, //
      0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01,
    ],
  ),
  // At start.
  (
    host: '::3445:5667:7889:9aab:bccd:deef:f001',
    out: [
      ____, ____, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, //
      0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01,
    ],
  ),
  (
    host: '::f001',
    out: [
      ____, ____, ____, ____, ____, ____, ____, ____, //
      ____, ____, ____, ____, ____, ____, 0xf0, 0x01,
    ],
  ),
  // In middle
  (
    host: '1223:3445:5667:7889::bccd:deef:f001',
    out: [
      0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, //
      ____, ____, 0xbc, 0xcd, 0xde, 0xef, 0xf0, 0x01,
    ],
  ),
  (
    host: '1223::f001',
    out: [
      0x12, 0x23, ____, ____, ____, ____, ____, ____, //
      ____, ____, ____, ____, ____, ____, 0xf0, 0x01,
    ],
  ),
  // At end
  (
    host: '1223:3445:5667:7889:9aab:bccd:deef::',
    out: [
      0x12, 0x23, 0x34, 0x45, 0x56, 0x67, 0x78, 0x89, //
      0x9a, 0xab, 0xbc, 0xcd, 0xde, 0xef, ____, ____,
    ],
  ),
  (
    host: '1223::',
    out: [
      0x12, 0x23, ____, ____, ____, ____, ____, ____, //
      ____, ____, ____, ____, ____, ____, ____, ____,
    ],
  ),
  // All.
  (
    host: '::',
    out: [
      ____, ____, ____, ____, ____, ____, ____, ____, //
      ____, ____, ____, ____, ____, ____, ____, ____,
    ],
  ),
];

const List<String> failSamples = [
  '', // No part
  ':', // Empty leading part, at end.
  ':0::', // Leading `:`.
  '0::0:', // trailing colon.
  // More than two `:`s
  ':::',
  '0:::0',
  // More than one wildcard.
  '::0::',
  '0::0::0',
  // More than four digits in a part.
  '00000::0',
  '0::00000',
  '0.0.0.0.00000.0.0.0',
  // Negative
  '-1::0',
  '0::-1',
  '0:0:0:-1:0:0:0:0',
  '-AAA::0',
  // Too long without wildcard.
  '1:2:3:4:5:6:7:8:9',
  // Too long with wildcard.
  '::1:2:3:4:5:6:7:8',
  '1:2:3:4::5:6:7:8',
  '1:2:3:4:5:6:7:8::',
];

void testPropagateIPv6() {
  // A regression test for https://dartbug.com/55085

  // A "Normal" URI. Simple URIs cannot have IPv6 addresses.
  var ipv6Uri = Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q#f");

  // A non-IPv6 URI.
  var plainUri = Uri.parse("s2://u2:p2@host:2/p3/p4?q2#f2");

  void expectSame(Uri expected, Uri actual) {
    Expect.equals(expected, actual, "URI equality");
    Expect.equals(
      expected.toString(),
      actual.toString(),
      "URI.toString() equality",
    );
  }

  Expect.equals("s://u:p@[::127.0.0.1]:1/p1/p2?q#f", ipv6Uri.toString());
  Expect.equals("::127.0.0.1", ipv6Uri.host);
  Expect.equals("u:p", ipv6Uri.userInfo);
  Expect.equals(1, ipv6Uri.port);

  // Using resolve to change parts of an IPv6 URI.
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q#f2"),
    ipv6Uri.resolve("#f2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q2#f2"),
    ipv6Uri.resolve("?q2#f2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p3?q2#f2"),
    ipv6Uri.resolve("p3?q2#f2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p3/p4?q2#f2"),
    ipv6Uri.resolve("/p3/p4?q2#f2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p3/p4?q2#f2"),
    ipv6Uri.resolve("/p3/p4?q2#f2"),
  );
  expectSame(
    Uri.parse("s://u2:p2@192.168.0.1:2/p3/p4?q2#f2"),
    ipv6Uri.resolve("//u2:p2@192.168.0.1:2/p3/p4?q2#f2"),
  );
  expectSame(
    Uri.parse("s2://u2:p2@192.168.0.1:2/p3/p4?q2#f2"),
    ipv6Uri.resolve("s2://u2:p2@192.168.0.1:2/p3/p4?q2#f2"),
  );

  // Using resolve to change parts to an IPv6 URI.
  expectSame(
    Uri.parse("s2://u:p@[::127.0.0.1]:1/p1/p2?q#f"),
    plainUri.resolve("//u:p@[::127.0.0.1]:1/p1/p2?q#f"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q#f"),
    plainUri.resolveUri(ipv6Uri),
  );

  // Using replace to change non-host parts of an IPv6 URI.
  expectSame(
    Uri.parse("s2://u:p@[::127.0.0.1]:1/p1/p2?q#f"),
    ipv6Uri.replace(scheme: "s2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:2/p1/p2?q#f"),
    ipv6Uri.replace(port: 2),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p3/p4?q#f"),
    ipv6Uri.replace(path: "p3/p4"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1?q#f"),
    ipv6Uri.replace(path: ""),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q2#f"),
    ipv6Uri.replace(query: "q2"),
  );
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q#f2"),
    ipv6Uri.replace(fragment: "f2"),
  );
  // Replacing the host to or from an IPv6 address.
  expectSame(
    Uri.parse("s://u:p@host:1/p1/p2?q#f"),
    ipv6Uri.replace(host: "host"),
  );
  expectSame(
    Uri.parse("s2://u2:p2@[::127.0.0.1]:2/p3/p4?q2#f2"),
    plainUri.replace(host: "[::127.0.0.1]"),
  );
  expectSame(
    Uri.parse("s2://u2:p2@[::127.0.0.1]:2/p3/p4?q2#f2"),
    plainUri.replace(host: "::127.0.0.1"),
  );

  // Removing fragment.
  expectSame(
    Uri.parse("s://u:p@[::127.0.0.1]:1/p1/p2?q"),
    ipv6Uri.removeFragment(),
  );
}

void main() {
  testValidIpv6Uri();
  testParseIPv6Address();
  testPropagateIPv6();
}

void passIPv6(String host, List<int> expected) {
  _passIPv6(expected, host, 0, host.length);
  _passIPv6(expected, '0${host}0', 1, host.length + 1);
  _passIPv6(expected, ':${host}:', 1, host.length + 1);
  _passIPv6(expected, '${host}.0', 0, host.length);
  _passIPv6(expected, '0x${host}x0', 2, host.length + 2);
}

void _passIPv6(List<int> expected, String input, int start, int end) {
  try {
    Expect.listEquals(expected, Uri.parseIPv6Address(input, start, end), input);
  } on Object {
    print("Failed: $input[$start..$end]");
    rethrow;
  }
}
