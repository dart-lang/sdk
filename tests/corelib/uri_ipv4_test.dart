// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  testParseIPv4Address();
}

void testParseIPv4Address() {
  for (var i = 0; i < passSamples.length; i++) {
    var sample = passSamples[i];
    passIPv4(sample.host, sample.out);
  }

  for (var i = 0; i < failSamples.length; i++) {
    var sample = failSamples[i];
    failIPv4(sample);
  }
}

// Test the address in different contexts. They should not matter.
void passIPv4(String host, List<int> out) {
  void passWrap(String prefix, String suffix) {
    var wrapped = "$prefix$host$suffix";
    Expect.listEquals(
      out,
      Uri.parseIPv4Address(wrapped, prefix.length, host.length + prefix.length),
      wrapped,
    );
  }

  passWrap('', '');
  passWrap('0', '0');
  passWrap('.', '.');
  passWrap(':', ':');
  passWrap('0x', 'x1');
}

// Test the address in different contexts. They should not matter.
void failIPv4(String host) {
  void failWrap(String prefix, String suffix) {
    var wrapped = "$prefix$host$suffix";
    Expect.throwsFormatException(
      () => Uri.parseIPv4Address(
        wrapped,
        prefix.length,
        host.length + prefix.length,
      ),
      wrapped,
    );
  }

  // Doesn't matter what is around the parsed area.
  failWrap('', '');
  failWrap('0', '0');
  failWrap('.', '.');
  failWrap('0x', 'x0');
  failWrap(':', ':');
}

const List<({String host, List<int> out})> passSamples = [
  (host: '0.0.0.0', out: [0, 0, 0, 0]),
  (host: '10.10.10.10', out: [10, 10, 10, 10]),
  (host: '127.0.0.1', out: [127, 0, 0, 1]),
  (host: '128.0.0.1', out: [128, 0, 0, 1]),
  (host: '255.255.255.255', out: [255, 255, 255, 255]),
];

const List<String> failSamples = [
  // No leading, trailing or embedded space.
  ' 127.0.0.11',
  '127.0.0.11 ',
  '127. 0.0.11',
  // No negative values (minuses are invalid characters anyway.)
  '-127.0.0.0',
  '127.-1.0.0',
  '127.0.-1.0',
  '127.0.0.-1',
  // No values above 255.
  '256.255.255.255',
  '255.256.255.255',
  '255.255.256.255',
  '255.255.255.256',
  '260.255.255.255',
  '255.260.255.255',
  '255.255.260.255',
  '255.255.255.260',
  '300.255.255.255',
  '255.300.255.255',
  '255.255.300.255',
  '255.255.255.300',
  // Not even if trailing (don't stop after three digits).
  '192.168.100.1000',
  '192.168.100.1009',
  // Exactly four non-empty parts.
  '0.0.0.0.0',
  '0.0.0.0.',
  '10.10.10.10.',
  '10.10.10.10.10',
  '0.0.0.0.0',
  '0.0.0',
  '.0.0.0',
  '0.0.0.',
  '0.0..0',
  '0..0',
  '0.0',
  '0', // Omitted in IPv4-in-IPv6 tests.
  '', // Omitted in IPv4-in-IPv6 tests.
  // No hex.
  'a.0.0.0',
  '0x0.0.0.0',
  '0.0x0.0.0',
  '0.0.0x0.0',
  '0.0.0.0x0',
  // No leading zeros.
  '00.0.0.0',
  '09.0.0.0',
  '0.00.0.0',
  '0.09.0.0',
  '0.0.00.0',
  '0.0.09.0',
  '0.0.0.00',
  '0.0.0.09',
  // No other characters allowed instead of `.`.
  '0,0.0.0',
  '0.0,0.0',
  '0.0.0,0',
  '0:0.0.0',
  '0.0:0.0',
  '0.0.0:0',
  '0 0.0.0',
  '0.0 0.0',
  '0.0.0 0',
];
