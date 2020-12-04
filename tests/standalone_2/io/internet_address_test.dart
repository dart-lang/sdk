// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import "package:expect/expect.dart";

void testDefaultAddresses() {
  var loopback4 = InternetAddress.loopbackIPv4;
  Expect.isNotNull(loopback4);
  Expect.equals(InternetAddressType.IPv4, loopback4.type);
  Expect.equals("127.0.0.1", loopback4.host);
  Expect.equals("127.0.0.1", loopback4.address);
  Expect.listEquals([127, 0, 0, 1], loopback4.rawAddress);

  var loopback6 = InternetAddress.loopbackIPv6;
  Expect.isNotNull(loopback6);
  Expect.equals(InternetAddressType.IPv6, loopback6.type);
  Expect.equals("::1", loopback6.host);
  Expect.equals("::1", loopback6.address);
  Expect.listEquals(
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1], loopback6.rawAddress);

  var any4 = InternetAddress.anyIPv4;
  Expect.isNotNull(any4);
  Expect.equals(InternetAddressType.IPv4, any4.type);
  Expect.equals("0.0.0.0", any4.host);
  Expect.equals("0.0.0.0", any4.address);

  var any6 = InternetAddress.anyIPv6;
  Expect.isNotNull(any6);
  Expect.equals(InternetAddressType.IPv6, any6.type);
  Expect.equals("::", any6.host);
  Expect.equals("::", any6.address);
}

void testConstructor() {
  var loopback4 = new InternetAddress("127.0.0.1");
  Expect.equals(InternetAddressType.IPv4, loopback4.type);
  Expect.equals("127.0.0.1", loopback4.host);
  Expect.equals("127.0.0.1", loopback4.address);
  Expect.isFalse(loopback4.isMulticast);

  var loopback6 = new InternetAddress("::1");
  Expect.equals(InternetAddressType.IPv6, loopback6.type);
  Expect.equals("::1", loopback6.host);
  Expect.equals("::1", loopback6.address);
  Expect.isFalse(loopback6.isMulticast);

  var ip4 = new InternetAddress("10.20.30.40");
  Expect.equals(InternetAddressType.IPv4, ip4.type);
  Expect.equals("10.20.30.40", ip4.host);
  Expect.equals("10.20.30.40", ip4.address);
  Expect.isFalse(ip4.isMulticast);

  var ip6 = new InternetAddress("10:20::30:40");
  Expect.equals(InternetAddressType.IPv6, ip6.type);
  Expect.equals("10:20::30:40", ip6.host);
  Expect.equals("10:20::30:40", ip6.address);
  Expect.isFalse(ip6.isMulticast);

  var multicast4 = new InternetAddress("224.1.2.3");
  Expect.equals(InternetAddressType.IPv4, multicast4.type);
  Expect.isTrue(multicast4.isMulticast);

  var multicast6 = new InternetAddress("FF00::1:2:3");
  Expect.equals(InternetAddressType.IPv6, multicast6.type);
  Expect.isTrue(multicast6.isMulticast);

  Expect.throwsArgumentError(() => new InternetAddress("1.2.3"));
  Expect.throwsArgumentError(() => new InternetAddress("::FFFF::1"));
}

void testTryParse() {
  var loopback4 = InternetAddress.tryParse("127.0.0.1");
  Expect.equals(InternetAddressType.IPv4, loopback4.type);
  Expect.equals("127.0.0.1", loopback4.host);
  Expect.equals("127.0.0.1", loopback4.address);
  Expect.isFalse(loopback4.isMulticast);

  var loopback6 = InternetAddress.tryParse("::1");
  Expect.equals(InternetAddressType.IPv6, loopback6.type);
  Expect.equals("::1", loopback6.host);
  Expect.equals("::1", loopback6.address);
  Expect.isFalse(loopback6.isMulticast);

  var ip4 = InternetAddress.tryParse("10.20.30.40");
  Expect.equals(InternetAddressType.IPv4, ip4.type);
  Expect.equals("10.20.30.40", ip4.host);
  Expect.equals("10.20.30.40", ip4.address);
  Expect.isFalse(ip4.isMulticast);

  var ip6 = InternetAddress.tryParse("10:20::30:40");
  Expect.equals(InternetAddressType.IPv6, ip6.type);
  Expect.equals("10:20::30:40", ip6.host);
  Expect.equals("10:20::30:40", ip6.address);
  Expect.isFalse(ip6.isMulticast);

  var multicast4 = InternetAddress.tryParse("224.1.2.3");
  Expect.equals(InternetAddressType.IPv4, multicast4.type);
  Expect.isTrue(multicast4.isMulticast);

  var multicast6 = InternetAddress.tryParse("FF00::1:2:3");
  Expect.equals(InternetAddressType.IPv6, multicast6.type);
  Expect.isTrue(multicast6.isMulticast);

  var lowercase = InternetAddress.tryParse("ff00::1:2:3");
  Expect.equals(InternetAddressType.IPv6, lowercase.type);
  Expect.equals("ff00::1:2:3", lowercase.host);
  Expect.equals("ff00::1:2:3", lowercase.address);

  Expect.isNull(InternetAddress.tryParse("1.2.3"));
  Expect.isNull(InternetAddress.tryParse("1.2.3.4.5"));
  Expect.isNull(InternetAddress.tryParse("192.168.256.0"));
  Expect.isNull(InternetAddress.tryParse("192.168.999.0"));
  Expect.isNull(InternetAddress.tryParse("1.-2.3.4"));
  Expect.isNull(InternetAddress.tryParse(""));
  Expect.isNull(InternetAddress.tryParse("FFFG::0"));
  Expect.isNull(InternetAddress.tryParse("FFF@::0"));
  Expect.isNull(InternetAddress.tryParse("::FFFF::1"));
}

void testEquality() {
  Expect.equals(
      new InternetAddress("127.0.0.1"), new InternetAddress("127.0.0.1"));
  Expect.equals(new InternetAddress("127.0.0.1"), InternetAddress.loopbackIPv4);
  Expect.equals(new InternetAddress("::1"), new InternetAddress("::1"));
  Expect.equals(new InternetAddress("::1"), InternetAddress.loopbackIPv6);
  Expect.equals(new InternetAddress("1:2:3:4:5:6:7:8"),
      new InternetAddress("1:2:3:4:5:6:7:8"));
  Expect.equals(
      new InternetAddress("1::2"), new InternetAddress("1:0:0:0:0:0:0:2"));
  Expect.equals(new InternetAddress("::FFFF:0:0:16.32.48.64"),
      new InternetAddress("::FFFF:0:0:1020:3040"));

  var set = new Set();
  set.add(new InternetAddress("127.0.0.1"));
  set.add(new InternetAddress("::1"));
  set.add(new InternetAddress("1:2:3:4:5:6:7:8"));
  Expect.isTrue(set.contains(new InternetAddress("127.0.0.1")));
  Expect.isTrue(set.contains(InternetAddress.loopbackIPv4));
  Expect.isFalse(set.contains(new InternetAddress("127.0.0.2")));
  Expect.isTrue(set.contains(new InternetAddress("::1")));
  Expect.isTrue(set.contains(InternetAddress.loopbackIPv6));
  Expect.isFalse(set.contains(new InternetAddress("::2")));
  Expect.isTrue(set.contains(new InternetAddress("1:2:3:4:5:6:7:8")));
  Expect.isFalse(set.contains(new InternetAddress("1:2:3:4:5:6:7:9")));
  Expect.isFalse(set.contains(new InternetAddress("0:2:3:4:5:6:7:8")));
}

void testLookup() {
  InternetAddress.lookup("127.0.0.1").then((addresses) {
    Expect.equals(1, addresses.length);
    Expect.equals("127.0.0.1", addresses[0].address);
  });

  InternetAddress.lookup("::1").then((addresses) {
    Expect.equals(1, addresses.length);
    Expect.equals("::1", addresses[0].address);
  });
}

void testReverseLookup() {
  InternetAddress.lookup('localhost').then((addrs) {
    addrs.first.reverse().then((addr) {
      Expect.isNotNull(addr.host);
      Expect.isNotNull(addr.rawAddress);
    });
  });

  InternetAddress.lookup('127.0.0.1').then((addrs) {
    Expect.equals('127.0.0.1', addrs.first.host);
    Expect.listEquals([127, 0, 0, 1], addrs.first.rawAddress);
    addrs.first.reverse().then((addr) {
      Expect.isNotNull(addr.host);
      Expect.notEquals('127.0.0.1', addr.host);
      Expect.listEquals([127, 0, 0, 1], addr.rawAddress);
    });
  });
}

void testRawAddress() {
  Uint8List addr = Uint8List.fromList([127, 0, 0, 1]);
  var address = InternetAddress.fromRawAddress(addr);
  Expect.equals('127.0.0.1', address.address);
  Expect.equals(address.address, address.host);
  Expect.equals(InternetAddressType.IPv4, address.type);
}

void testRawAddressIPv6() {
  Uint8List addr =
      Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1]);
  var address = InternetAddress.fromRawAddress(addr);
  Expect.equals('::1', address.address);
  Expect.equals(address.address, address.host);
  Expect.equals(InternetAddressType.IPv6, address.type);
}

void testRawPath() {
  var name = 'test_raw_path';
  var address = InternetAddress.fromRawAddress(utf8.encode(name),
      type: InternetAddressType.unix);
  Expect.equals(name, address.address);
  Expect.equals(address.address, address.host);
  Expect.equals(InternetAddressType.unix, address.type);
}

void testInvalidScopedId() {
  // macOS will not throw an error.
  try {
    InternetAddress('::1%invalid');
  } catch (e) {
    Expect.type<ArgumentError>(e);
    Expect.isTrue(e.toString().contains('scope ID'));
  }
}

void main() {
  testDefaultAddresses();
  testConstructor();
  testTryParse();
  testEquality();
  testLookup();
  testReverseLookup();
  testRawAddress();
  testRawAddressIPv6();
  testRawPath();
  testInvalidScopedId();
}
