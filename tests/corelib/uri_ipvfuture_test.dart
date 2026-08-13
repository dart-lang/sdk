// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void testValidIPvFutureUri() {
  void test(String address) {
    var bracketedAddress = '[$address]';
    var path = 'https://me:you@$bracketedAddress:1234/path?query=5#now';
    var uri = Uri.parse(path);
    var uriString = uri.toString();
    Expect.equals(path, uriString);
    Expect.isTrue(uri.hasAuthority);
    Expect.equals('https', uri.scheme, ".scheme of $uriString");
    Expect.equals('me:you', uri.userInfo, ".userInfo of $uriString");
    Expect.equals(bracketedAddress, uri.host, ".host of $uriString");
    Expect.equals(1234, uri.port, ".port of $uriString");
    Expect.equals('/path', uri.path, ".path of $uriString");
    Expect.equals('query=5', uri.query, ".query of $uriString");
    Expect.equals('now', uri.fragment, ".fragment of $uriString");

    uri = Uri(scheme: 'https', host: bracketedAddress, path: '/path');
    Expect.isTrue(uri.hasAuthority);
    Expect.equals('https://$bracketedAddress/path', uri.toString());
    Expect.equals(bracketedAddress, uri.host);

    uri = Uri.https(bracketedAddress, '/path');
    Expect.isTrue(uri.hasAuthority);
    Expect.equals('https://$bracketedAddress/path', uri.toString());
    Expect.equals(bracketedAddress, uri.host);

    uri = Uri.parse('https://example.com/path');
    uri = uri.replace(host: bracketedAddress);
    Expect.isTrue(uri.hasAuthority);
    Expect.equals('https://$bracketedAddress/path', uri.toString());
    Expect.equals(bracketedAddress, uri.host);
  }

  test('v0.0'); // Minimal valid
  test('vDEADBEEF.CAKE:EAT'); // More characters.
  // All allowed characters in each position
  // (skipping the middle ones of 0-9, a-z and A-Z).
  test(r"v0123456789abcdefABCDEF.!$&'()*+,-.09:;=AZ_az~");
}

void testInvalidIPvFutureUri() {
  void fail(String host) {
    Expect.throwsFormatException(() => Uri.parse('http://[$host]/'), '[$host]');
    Expect.throwsFormatException(
      () => Uri(scheme: 'http', host: '[$host]'),
      '[$host]',
    );
  }

  // No leading whitespace.
  fail(' v0.0'); // Also not valid IPv6.
  // Must start with lower-case 'v'.
  fail('V0.0'); // Also not valid IPv6.
  // Does not allow escapes, %56 is 'v'.
  fail('%560.0'); // Also not valid IPv6.
  // Hex digit must follow `v`.
  fail('v');
  fail('v:');
  fail('v:0');
  fail('v 0.0');
  fail('v.:');
  fail('vv0.:');
  fail('v%41.:'); // No escape.
  // Correct ranges for hex digits.
  fail('v/.:'); // / is before 0
  fail('v:.:'); // : is after 9
  fail('v@.:'); // @ is before A
  fail('vG.:'); // G is after F
  fail('v`.:'); // ` is before a
  fail('vg.:'); // g is after f

  // Dot must follow hex-digits.
  fail('v0');
  fail('v0:');
  fail('v0%2E:'); // No escape.
  // Correct ranges for second hex digit.
  fail('v0/.:'); // / is before 0
  fail('v0:.:'); // : is after 9
  fail('v0@.:'); // @ is before A
  fail('v0G.:'); // G is after F
  fail('v0`.:'); // ` is before a
  fail('v0g.:'); // g is after f

  // Valid character must follow dot.
  // Unreserved, sub-delimiters and colon are valid.
  fail('vA.');
  fail('vA.%41'); // No escapes, no zones
  // No trailing garbage.
  fail('v0.0 ');
  fail('v0.0/');
  // No zones.
  fail('v0.0%41');
  fail('v0.0%25x');
}

void main() {
  testValidIPvFutureUri();
  testInvalidIPvFutureUri();
}
